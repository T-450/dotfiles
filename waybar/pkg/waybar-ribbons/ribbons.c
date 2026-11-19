// waybar-ribbons: a waybar CFFI module (ABI 2) that draws one audio channel as a twisted
// wireframe ribbon, after SGI CAD viewports. MIT license.
//
// Config (waybar config.jsonc): "module_path": "/usr/lib/waybar-ribbons/ribbons.so",
// "channel": "left" | "right" (left is drawn mirrored, lows toward the player in the middle),
// "expand": true (waybar's own key: fill the bar up to the centre modules).
//
// Data: each instance runs its own cava (raw binary 16-bit, mono, that channel) and reads the
// newest frame from its stdout. cava's capture node is passive (active = 0), so it never keeps
// the sink awake on its own; cava dies with waybar (PR_SET_PDEATHSIG) and keeps its first-run
// files under $XDG_RUNTIME_DIR/waybar-ribbons, not in ~/.config/cava. A frame that equals the one
// drawn is not drawn again, so silence (cava's sleep_timer) costs nothing. If cava exits, the ribbon goes flat and cava is started
// again after 1s, backing off to 30s while it keeps failing.
// Colors: @clut0..@clut15, @grid and @text from the GTK style context (waybar's colors.css,
// rendered by theme), read at start and on a GTK style change; `theme set` recolors them through
// waybar/reload.sh, whose SIGUSR2 makes waybar re-create its modules.
// Shader: ribbons.frag, embedded at build time; the #version line is chosen at runtime because
// GTK may hand out desktop GL even when GLES is asked for.
#include "waybar_cffi_module.h"
#include <epoxy/gl.h>
#include <glib-unix.h>
#include <errno.h>
#include <math.h>
#include <signal.h>
#include <sys/prctl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

const size_t wbcffi_version = 2;

enum { BARS = 48, FRAME = BARS * 2, NCOLORS = 18 };
static const char *const COLORS[NCOLORS] = {
	"clut0", "clut1", "clut2", "clut3", "clut4", "clut5", "clut6", "clut7",
	"clut8", "clut9", "clut10", "clut11", "clut12", "clut13", "clut14", "clut15",
	"grid", "text",
};
static const char FRAG[] = {
#embed "ribbons.frag"
	, 0
};
static const char VERT[] =
	"void main() {\n"
	"	vec2 p = vec2(float((gl_VertexID << 1) & 2), float(gl_VertexID & 2));\n"
	"	gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);\n"
	"}\n";
static const float SPEED = 1.3f;   // twist phase, radians per second of music

typedef struct {
	GtkWidget *area;               // NULL once GTK has finalized it
	char channel[6];               // "left" | "right"
	GLuint prog, vao, tex;
	GLint u_spec, u_width, u_scale, u_fbh, u_phase, u_mirror, u_clut, u_grid, u_spark;
	float colors[NCOLORS * 4];
	gboolean warned[NCOLORS];
	guint16 newest[BARS], drawn[BARS];
	guint8 buf[FRAME];
	size_t have;
	float phase;
	gint64 last;                   // when the last frame was drawn
	char *conf;                    // cava's config, in $XDG_RUNTIME_DIR/waybar-ribbons/
	GPid pid;
	int fd;
	guint io, child, retry;
	guint backoff;                 // ms until the next start after a failure
} Ribbons;

static void start_cava(Ribbons *r);

// ---------------------------------------------------------------- colors

static void read_colors(Ribbons *r) {
	GtkStyleContext *ctx = gtk_widget_get_style_context(r->area);
	for (int i = 0; i < NCOLORS; i++) {
		GdkRGBA c = {0};
		if (!gtk_style_context_lookup_color(ctx, COLORS[i], &c) && !r->warned[i]) {
			fprintf(stderr, "waybar-ribbons: no @%s in the style; that color is not drawn\n", COLORS[i]);
			r->warned[i] = TRUE;
		}
		float *f = &r->colors[i * 4];
		f[0] = c.red, f[1] = c.green, f[2] = c.blue, f[3] = c.alpha;
	}
}

static void on_style_updated(GtkWidget *w, Ribbons *r) {
	// before realize the widget may not be anchored yet; on_realize reads the colors then
	if (!gtk_widget_get_realized(w)) return;
	read_colors(r);
	gtk_gl_area_queue_render(GTK_GL_AREA(r->area));
}

// ---------------------------------------------------------------- cava

// all bars to zero: the flat ribbon of silence or of a missing cava
static void go_flat(Ribbons *r) {
	memset(r->newest, 0, sizeof r->newest);
	r->have = 0;
	if (r->area) gtk_gl_area_queue_render(GTK_GL_AREA(r->area));
}

static gboolean on_data(int fd, GIOCondition cond, gpointer data) {
	Ribbons *r = data;
	gboolean got = FALSE;
	for (;;) {
		ssize_t n = read(fd, r->buf + r->have, FRAME - r->have);
		if (n > 0) {
			r->have += n;
			if (r->have == FRAME) {
				memcpy(r->newest, r->buf, FRAME);   // native byte order, as cava writes it
				r->have = 0;
				got = TRUE;
			}
			continue;
		}
		if (n < 0 && errno == EINTR) continue;
		if (n < 0 && errno == EAGAIN) break;
		// EOF or an error: cava is gone; on_cava_exit restarts it
		close(fd);
		r->fd = -1;
		r->io = 0;
		return G_SOURCE_REMOVE;
	}
	(void)cond;
	if (got) {
		r->backoff = 1000;
		if (memcmp(r->newest, r->drawn, sizeof r->drawn) && r->area)
			gtk_gl_area_queue_render(GTK_GL_AREA(r->area));
	}
	return G_SOURCE_CONTINUE;
}

static gboolean on_retry(gpointer data) {
	Ribbons *r = data;
	r->retry = 0;
	start_cava(r);
	return G_SOURCE_REMOVE;
}

static void on_cava_exit(GPid pid, int status, gpointer data) {
	Ribbons *r = data;
	(void)status;
	g_spawn_close_pid(pid);
	r->child = 0;
	r->pid = 0;
	// the old pipe goes with it, before the next start reuses r->fd and r->io
	if (r->io) g_source_remove(r->io);
	if (r->fd >= 0) close(r->fd);
	r->io = 0;
	r->fd = -1;
	go_flat(r);
	r->retry = g_timeout_add(r->backoff, on_retry, r);
	r->backoff = MIN(r->backoff * 2, 30000);
}

static void write_conf(Ribbons *r) {
	char *dir = g_build_filename(g_get_user_runtime_dir(), "waybar-ribbons", NULL);
	g_mkdir_with_parents(dir, 0700);
	r->conf = g_strdup_printf("%s/%s.conf", dir, r->channel);
	g_free(dir);
	char *text = g_strdup_printf(
		"# written by waybar-ribbons for its %s ribbon; rewritten on every start\n"
		"[general]\nframerate = 30\nbars = %d\nsleep_timer = 1\n"
		"[input]\nmethod = pipewire\nsource = auto\nactive = 0\n"
		"[output]\nmethod = raw\nchannels = mono\nmono_option = %s\nraw_target = /dev/stdout\n"
		"data_format = binary\nbit_format = 16bit\n",
		r->channel, BARS, r->channel);
	GError *err = NULL;
	if (!g_file_set_contents(r->conf, text, -1, &err)) {
		fprintf(stderr, "waybar-ribbons: %s\n", err->message);
		g_error_free(err);
	}
	g_free(text);
}

// in the child, before exec: die with waybar (a SIGTERM to waybar runs no destructor), and take
// SIGPIPE back if waybar ignores it, so a cava writing into a closed pipe ends
static void child_setup(gpointer data) {
	(void)data;
	prctl(PR_SET_PDEATHSIG, SIGTERM);
	signal(SIGPIPE, SIG_DFL);
}

static void start_cava(Ribbons *r) {
	char *argv[] = {"cava", "-p", r->conf, NULL};
	char *home = g_path_get_dirname(r->conf);
	char **env = g_environ_setenv(g_get_environ(), "XDG_CONFIG_HOME", home, TRUE);
	g_free(home);
	GError *err = NULL;
	int out;
	gboolean ok = g_spawn_async_with_pipes(NULL, argv, env,
			G_SPAWN_SEARCH_PATH | G_SPAWN_DO_NOT_REAP_CHILD | G_SPAWN_STDIN_FROM_DEV_NULL,
			child_setup, NULL, &r->pid, NULL, &out, NULL, &err);
	g_strfreev(env);
	if (!ok) {
		fprintf(stderr, "waybar-ribbons: cava: %s\n", err->message);
		g_error_free(err);
		r->retry = g_timeout_add(r->backoff, on_retry, r);
		r->backoff = MIN(r->backoff * 2, 30000);
		return;
	}
	g_unix_set_fd_nonblocking(out, TRUE, NULL);
	r->fd = out;
	r->have = 0;
	r->io = g_unix_fd_add(out, G_IO_IN | G_IO_HUP | G_IO_ERR, on_data, r);
	r->child = g_child_watch_add(r->pid, on_cava_exit, r);
}

static void reap(GPid pid, int status, gpointer data) {
	(void)status, (void)data;
	g_spawn_close_pid(pid);
}

static void stop_cava(Ribbons *r) {
	if (r->retry) g_source_remove(r->retry);
	if (r->io) g_source_remove(r->io);
	if (r->fd >= 0) close(r->fd);
	if (r->child) {
		// the instance is going away: hand the exit to a watch that needs nothing from it
		g_source_remove(r->child);
		kill(r->pid, SIGTERM);
		g_child_watch_add(r->pid, reap, NULL);
	}
	r->retry = r->io = r->child = 0;
	r->fd = -1;
}

// ---------------------------------------------------------------- GL

static GLuint compile(GLenum type, const char *head, const char *body) {
	const char *src[] = {head, body};
	GLuint s = glCreateShader(type);
	glShaderSource(s, 2, src, NULL);
	glCompileShader(s);
	GLint ok;
	glGetShaderiv(s, GL_COMPILE_STATUS, &ok);
	if (!ok) {
		char log[2048];
		glGetShaderInfoLog(s, sizeof log, NULL, log);
		fprintf(stderr, "waybar-ribbons: shader: %s\n", log);
	}
	return s;
}

static void on_realize(GtkGLArea *area, Ribbons *r) {
	gtk_gl_area_make_current(area);
	if (gtk_gl_area_get_error(area)) {
		fprintf(stderr, "waybar-ribbons: GL: %s\n", gtk_gl_area_get_error(area)->message);
		return;
	}
	gboolean es = gdk_gl_context_get_use_es(gtk_gl_area_get_context(area));
	const char *head = es ? "#version 300 es\nprecision highp float;\nprecision highp sampler2D;\n"
	                      : "#version 330 core\n";
	GLuint vs = compile(GL_VERTEX_SHADER, head, VERT), fs = compile(GL_FRAGMENT_SHADER, head, FRAG);
	GLuint prog = glCreateProgram();
	glAttachShader(prog, vs);
	glAttachShader(prog, fs);
	glLinkProgram(prog);
	glDeleteShader(vs);
	glDeleteShader(fs);
	GLint ok;
	glGetProgramiv(prog, GL_LINK_STATUS, &ok);
	if (!ok) {
		char log[2048];
		glGetProgramInfoLog(prog, sizeof log, NULL, log);
		fprintf(stderr, "waybar-ribbons: link: %s\n", log);
		glDeleteProgram(prog);
		return;
	}
	r->prog = prog;
	r->u_spec = glGetUniformLocation(prog, "spec");
	r->u_width = glGetUniformLocation(prog, "width");
	r->u_scale = glGetUniformLocation(prog, "scale");
	r->u_fbh = glGetUniformLocation(prog, "fbh");
	r->u_phase = glGetUniformLocation(prog, "phase");
	r->u_mirror = glGetUniformLocation(prog, "mirror");
	r->u_clut = glGetUniformLocation(prog, "clut");
	r->u_grid = glGetUniformLocation(prog, "grid");
	r->u_spark = glGetUniformLocation(prog, "spark");
	glGenVertexArrays(1, &r->vao);
	glGenTextures(1, &r->tex);
	glBindTexture(GL_TEXTURE_2D, r->tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, BARS, 1, 0, GL_RED, GL_FLOAT, NULL);
	read_colors(r);
	r->last = g_get_monotonic_time();
}

static void on_unrealize(GtkGLArea *area, Ribbons *r) {
	gtk_gl_area_make_current(area);
	if (gtk_gl_area_get_error(area)) return;
	glDeleteTextures(1, &r->tex);
	glDeleteVertexArrays(1, &r->vao);
	glDeleteProgram(r->prog);
	r->prog = r->vao = r->tex = 0;
}

static gboolean on_render(GtkGLArea *area, GdkGLContext *ctx, Ribbons *r) {
	(void)ctx;
	glClearColor(0, 0, 0, 0);
	glClear(GL_COLOR_BUFFER_BIT);
	if (!r->prog) return TRUE;
	gint64 now = g_get_monotonic_time();
	if (memcmp(r->newest, r->drawn, sizeof r->drawn)) {
		// the twist moves with the music only; a long pause does not jump it
		r->phase = fmodf(r->phase + MIN((now - r->last) / 1e6f, 0.1f) * SPEED, 6.2831853f * 60);
		memcpy(r->drawn, r->newest, sizeof r->drawn);
	}
	r->last = now;
	float level[BARS];
	for (int i = 0; i < BARS; i++) level[i] = r->drawn[i] / 65535.0f;

	GtkWidget *w = GTK_WIDGET(area);
	int sc = gtk_widget_get_scale_factor(w);
	glUseProgram(r->prog);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, r->tex);
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, BARS, 1, GL_RED, GL_FLOAT, level);
	glUniform1i(r->u_spec, 0);
	glUniform1f(r->u_width, gtk_widget_get_allocated_width(w));
	glUniform1f(r->u_scale, sc);
	glUniform1f(r->u_fbh, gtk_widget_get_allocated_height(w) * sc);
	glUniform1f(r->u_phase, r->phase);
	glUniform1f(r->u_mirror, !strcmp(r->channel, "left"));
	glUniform4fv(r->u_clut, 16, r->colors);
	glUniform4fv(r->u_grid, 1, &r->colors[16 * 4]);
	glUniform4fv(r->u_spark, 1, &r->colors[17 * 4]);
	glBindVertexArray(r->vao);
	glDrawArrays(GL_TRIANGLES, 0, 3);
	return TRUE;
}

// ---------------------------------------------------------------- waybar ABI

void *wbcffi_init(const wbcffi_init_info *info, const wbcffi_config_entry *cfg, size_t n) {
	Ribbons *r = g_new0(Ribbons, 1);
	r->fd = -1;
	r->backoff = 1000;
	g_strlcpy(r->channel, "right", sizeof r->channel);
	for (size_t i = 0; i < n; i++) {
		if (strcmp(cfg[i].key, "channel")) continue;
		// ABI 2 hands every value over as its JSON text: "\"left\"\n"
		char *v = g_strstrip(g_strdup(cfg[i].value));
		size_t len = strlen(v);
		if (len >= 2 && v[0] == '"' && v[len - 1] == '"') {
			v[len - 1] = 0;
			memmove(v, v + 1, len - 1);
		}
		if (!strcmp(v, "left") || !strcmp(v, "right")) g_strlcpy(r->channel, v, sizeof r->channel);
		else fprintf(stderr, "waybar-ribbons: channel %s is not left or right; using right\n", v);
		g_free(v);
	}

	r->area = gtk_gl_area_new();
	g_object_add_weak_pointer(G_OBJECT(r->area), (gpointer *)&r->area);
	gtk_gl_area_set_use_es(GTK_GL_AREA(r->area), TRUE);
	gtk_gl_area_set_required_version(GTK_GL_AREA(r->area), 3, 0);
	gtk_gl_area_set_has_alpha(GTK_GL_AREA(r->area), TRUE);
	// draw only when asked (a new frame, a style change); other redraws reuse the last image
	gtk_gl_area_set_auto_render(GTK_GL_AREA(r->area), FALSE);
	gtk_widget_set_hexpand(r->area, TRUE);
	g_signal_connect(r->area, "realize", G_CALLBACK(on_realize), r);
	g_signal_connect(r->area, "unrealize", G_CALLBACK(on_unrealize), r);
	g_signal_connect(r->area, "render", G_CALLBACK(on_render), r);
	g_signal_connect(r->area, "style-updated", G_CALLBACK(on_style_updated), r);
	gtk_container_add(info->get_root_widget(info->obj), r->area);
	gtk_widget_show(r->area);

	write_conf(r);
	start_cava(r);
	return r;
}

void wbcffi_deinit(void *instance) {
	Ribbons *r = instance;
	stop_cava(r);
	// waybar calls this before it destroys the module's widgets: destroy the area now, while
	// its handlers can still use r (unrealize frees the GL objects)
	if (r->area) {
		g_object_remove_weak_pointer(G_OBJECT(r->area), (gpointer *)&r->area);
		gtk_widget_destroy(r->area);
	}
	g_free(r->conf);
	g_free(r);
}

// waybar calls these unconditionally (update on its dispatcher, refresh on every RTMIN signal
// any module listens to), so they exist even with nothing to do
void wbcffi_update(void *instance) { (void)instance; }
void wbcffi_refresh(void *instance, int signal) { (void)instance, (void)signal; }
void wbcffi_doaction(void *instance, const char *name) { (void)instance, (void)name; }
