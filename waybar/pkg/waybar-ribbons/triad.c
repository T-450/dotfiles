// waybar-triad: a waybar CFFI module (ABI 2) that draws a live 3D-rotating SGI CAD XYZ axis
// triad in Cairo on the bottom bar's left corner; clicking opens mango-keys (super+/). MIT license.
//
// Motion: sleek periodic SGI CAD gimbal loop — a 2.4s quintic-eased 360° 3D orbital sweep with a
// subtle reticle pulse, locking back onto the isometric home orientation for a 5.0s zero-CPU dwell
// (0 redraws while locked). Hovering wakes it immediately into a smooth continuous 3D orbit with
// Viewport cyan hover plate; leaving eases cleanly back to the isometric home lock.
// Colors: @orange (X), @green (Y), @cyan (Z, reticle, hover), @text (origin), @bar (origin halo)
// read from the GTK style context (waybar's colors.css) on realize and style updates.
#include "waybar_cffi_module.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

const size_t wbcffi_version = 2;

enum { C_ORANGE, C_GREEN, C_CYAN, C_TEXT, C_BAR, NCOLORS };
static const char *const COLOR_NAMES[NCOLORS] = { "orange", "green", "cyan", "text", "bar" };

static const double HOME_YAW = 0.62;
static const double HOME_PITCH = 0.44;
static const double SWEEP_DUR = 2.4;   // seconds for one full 360° eased sweep
static const guint DWELL_MS = 5000;    // calm isometric lock between sweeps (0% CPU)

static const char *const TOOLTIP =
	"<span font_desc='Terminess Nerd Font 12px' letter_spacing='1024' fgalpha='60%'>AXES</span>"
	"  Keybindings  "
	"<span font_desc='Terminess Nerd Font 12px' letter_spacing='1024' fgalpha='80%'>SUPER /</span>\n"
	"<span font_desc='Terminess Nerd Font 12px' letter_spacing='0' fgalpha='60%'>Click opens cheatsheet</span>";

typedef enum { MODE_DWELL, MODE_SWEEP, MODE_HOVER, MODE_RETURN } TriadMode;

typedef struct {
	GtkWidget *box;
	GtkWidget *area;
	GdkRGBA colors[NCOLORS];
	gboolean warned[NCOLORS];
	TriadMode mode;
	double yaw, pitch, roll;
	double sweep_t;      // 0..1 progress in MODE_SWEEP / MODE_RETURN
	double ret_start_y, ret_target_y, ret_start_p, ret_start_r;
	double pulse;        // 0..1 reticle energy shimmer during sweep
	double hover_t;      // 0..1 eased hover state (150ms)
	gboolean hovered;
	gint64 last_us;
	guint tick_id;
	guint dwell_id;
} Triad;

typedef struct {
	int kind; // 0=X, 1=Y, 2=Z, 3=origin
	double x, y, z;
} DrawItem;

static gboolean on_tick(gpointer data);
static gboolean on_dwell_end(gpointer data);

static double smootherstep(double t) {
	if (t <= 0.0) return 0.0;
	if (t >= 1.0) return 1.0;
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

static void stop_timers(Triad *t) {
	if (t->tick_id) {
		g_source_remove(t->tick_id);
		t->tick_id = 0;
	}
	if (t->dwell_id) {
		g_source_remove(t->dwell_id);
		t->dwell_id = 0;
	}
}

static void start_tick(Triad *t) {
	if (t->dwell_id) {
		g_source_remove(t->dwell_id);
		t->dwell_id = 0;
	}
	t->last_us = g_get_monotonic_time();
	if (!t->tick_id) t->tick_id = g_timeout_add(33, on_tick, t);
}

static void enter_dwell(Triad *t) {
	stop_timers(t);
	t->mode = MODE_DWELL;
	t->yaw = HOME_YAW;
	t->pitch = HOME_PITCH;
	t->roll = 0.0;
	t->pulse = 0.0;
	t->hover_t = 0.0;
	if (t->area) gtk_widget_queue_draw(t->area);
	t->dwell_id = g_timeout_add(DWELL_MS, on_dwell_end, t);
}

static void start_sweep(Triad *t) {
	t->mode = MODE_SWEEP;
	t->sweep_t = 0.0;
	t->pulse = 0.0;
	start_tick(t);
}

static gboolean on_dwell_end(gpointer data) {
	Triad *t = data;
	t->dwell_id = 0;
	start_sweep(t);
	return G_SOURCE_REMOVE;
}

static void read_colors(Triad *t) {
	if (!t->area) return;
	GtkStyleContext *ctx = gtk_widget_get_style_context(t->area);
	for (int i = 0; i < NCOLORS; i++) {
		GdkRGBA c = {0};
		if (!gtk_style_context_lookup_color(ctx, COLOR_NAMES[i], &c) && !t->warned[i]) {
			fprintf(stderr, "waybar-triad: no @%s in style\n", COLOR_NAMES[i]);
			t->warned[i] = TRUE;
		}
		t->colors[i] = c;
	}
}

static void on_realize(GtkWidget *w, Triad *t) {
	(void)w;
	read_colors(t);
	if (t->area) gtk_widget_queue_draw(t->area);
}

static void on_style_updated(GtkWidget *w, Triad *t) {
	if (!gtk_widget_get_realized(w)) return;
	read_colors(t);
	gtk_widget_queue_draw(w);
}

static gboolean on_enter(GtkWidget *w, GdkEventCrossing *ev, Triad *t) {
	(void)w, (void)ev;
	t->hovered = TRUE;
	t->mode = MODE_HOVER;
	start_tick(t);
	return FALSE;
}

static gboolean on_leave(GtkWidget *w, GdkEventCrossing *ev, Triad *t) {
	(void)w, (void)ev;
	t->hovered = FALSE;
	if (t->mode == MODE_HOVER) {
		// Glide forward smoothly to the next isometric home angle
		double rel = fmod(t->yaw - HOME_YAW, 2.0 * M_PI);
		if (rel < 0.0) rel += 2.0 * M_PI;
		double rem = (rel < 0.05) ? 0.0 : (2.0 * M_PI - rel);
		t->ret_start_y = t->yaw;
		t->ret_target_y = t->yaw + (rem > M_PI ? -(rel) : rem);
		t->ret_start_p = t->pitch;
		t->ret_start_r = t->roll;
		t->sweep_t = 0.0;
		t->mode = MODE_RETURN;
		start_tick(t);
	}
	return FALSE;
}

static gboolean on_press(GtkWidget *w, GdkEventButton *ev, Triad *t) {
	(void)w, (void)t;
	if (ev->type != GDK_BUTTON_PRESS || ev->button != 1) return FALSE;
	char *cmd = g_build_filename(g_get_home_dir(), ".local", "bin", "mango-keys", NULL);
	char *argv[] = { cmd, NULL };
	g_spawn_async(NULL, argv, NULL, G_SPAWN_SEARCH_PATH, NULL, NULL, NULL, NULL);
	g_free(cmd);
	return TRUE;
}

static gboolean on_tick(gpointer data) {
	Triad *t = data;
	gint64 now = g_get_monotonic_time();
	double dt = t->last_us ? (double)(now - t->last_us) * 1e-6 : (1.0 / 30.0);
	if (dt < 0.0 || dt > 0.1) dt = 1.0 / 30.0;
	t->last_us = now;

	double target_h = t->hovered ? 1.0 : 0.0;
	double step_h = dt / 0.15;
	if (t->hover_t < target_h) t->hover_t = fmin(target_h, t->hover_t + step_h);
	else if (t->hover_t > target_h) t->hover_t = fmax(target_h, t->hover_t - step_h);

	if (t->mode == MODE_SWEEP) {
		t->sweep_t += dt / SWEEP_DUR;
		if (t->sweep_t >= 1.0) {
			enter_dwell(t);
			return G_SOURCE_REMOVE;
		}
		double u = smootherstep(t->sweep_t);
		t->yaw = HOME_YAW + 2.0 * M_PI * u;
		t->pitch = HOME_PITCH + 0.22 * sin(2.0 * M_PI * u);
		t->roll = 0.16 * sin(2.0 * M_PI * u);
		t->pulse = sin(M_PI * u);
	} else if (t->mode == MODE_HOVER) {
		t->yaw += 1.75 * dt;
		if (t->yaw > 4.0 * M_PI) t->yaw -= 4.0 * M_PI;
		t->pitch = HOME_PITCH + 0.18 * sin(t->yaw * 0.5);
		t->roll = 0.14 * cos(t->yaw * 0.5);
		t->pulse = t->hover_t;
	} else if (t->mode == MODE_RETURN) {
		t->sweep_t += dt / 0.55;
		if (t->sweep_t >= 1.0 && t->hover_t <= 0.001) {
			enter_dwell(t);
			return G_SOURCE_REMOVE;
		}
		double u = smootherstep(fmin(1.0, t->sweep_t));
		t->yaw = t->ret_start_y + (t->ret_target_y - t->ret_start_y) * u;
		t->pitch = t->ret_start_p + (HOME_PITCH - t->ret_start_p) * u;
		t->roll = t->ret_start_r * (1.0 - u);
		t->pulse = (1.0 - u) * 0.5;
	}

	if (t->area) gtk_widget_queue_draw(t->area);
	return G_SOURCE_CONTINUE;
}

static void rotate_vec(double x, double y, double z,
                       double cy, double sy, double cp, double sp, double cr, double sr,
                       double *ox, double *oy, double *oz) {
	double x1 = x * cy + z * sy;
	double y1 = y;
	double z1 = -x * sy + z * cy;
	double x2 = x1;
	double y2 = y1 * cp - z1 * sp;
	double z2 = y1 * sp + z1 * cp;
	*ox = x2 * cr - y2 * sr;
	*oy = x2 * sr + y2 * cr;
	*oz = z2;
}

static int cmp_depth(const void *a, const void *b) {
	double za = ((const DrawItem *)a)->z;
	double zb = ((const DrawItem *)b)->z;
	return (za > zb) - (za < zb);
}

static gboolean on_draw(GtkWidget *w, cairo_t *cr, Triad *t) {
	int width = gtk_widget_get_allocated_width(w);
	int height = gtk_widget_get_allocated_height(w);
	if (width < 2 || height < 2) return FALSE;

	const GdkRGBA *cyan = &t->colors[C_CYAN];
	const GdkRGBA *text = &t->colors[C_TEXT];
	const GdkRGBA *bar = &t->colors[C_BAR];

	// Viewport hover plate (14% cyan fill + 1px cyan bottom rule, leaving top ruler pristine)
	if (t->hover_t > 0.001) {
		cairo_set_source_rgba(cr, cyan->red, cyan->green, cyan->blue, 0.14 * t->hover_t);
		cairo_rectangle(cr, 0, 1, width, height - 1);
		cairo_fill(cr);
		cairo_set_source_rgba(cr, cyan->red, cyan->green, cyan->blue, t->hover_t);
		cairo_rectangle(cr, 0, height - 1, width, 1);
		cairo_fill(cr);
	}

	double cx = width * 0.5;
	double cy = height * 0.5 + 1.0; // optical center below bottom bar's top ruler ticks
	double radius = 12.0;
	double glow = fmax(t->hover_t, t->pulse * 0.75);

	// Precision gimbal reticle ring + 4 cardinal ticks
	double ring_r = radius + 1.5;
	cairo_set_line_width(cr, 1.0);
	cairo_set_source_rgba(cr, cyan->red, cyan->green, cyan->blue, 0.14 + 0.28 * glow);
	cairo_arc(cr, cx, cy, ring_r, 0, 2.0 * M_PI);
	cairo_stroke(cr);

	cairo_set_source_rgba(cr, cyan->red, cyan->green, cyan->blue, 0.30 + 0.48 * glow);
	for (int k = 0; k < 4; k++) {
		double a = k * (M_PI * 0.5);
		double ca = cos(a), sa = sin(a);
		cairo_move_to(cr, cx + ca * (ring_r - 1.5), cy + sa * (ring_r - 1.5));
		cairo_line_to(cr, cx + ca * (ring_r + 1.5), cy + sa * (ring_r + 1.5));
		cairo_stroke(cr);
	}

	double cyw = cos(t->yaw), syw = sin(t->yaw);
	double cp = cos(t->pitch), sp = sin(t->pitch);
	double crl = cos(t->roll), srl = sin(t->roll);

	static const double BASIS[3][3] = {
		{ 1.0, 0.0, 0.0 }, // X: orange
		{ 0.0, 1.0, 0.0 }, // Y: green (up)
		{ 0.0, 0.0, 1.0 }, // Z: cyan
	};
	DrawItem items[4];
	for (int i = 0; i < 3; i++) {
		items[i].kind = i;
		rotate_vec(BASIS[i][0], BASIS[i][1], BASIS[i][2],
		           cyw, syw, cp, sp, crl, srl,
		           &items[i].x, &items[i].y, &items[i].z);
	}
	items[3] = (DrawItem){ .kind = 3, .x = 0.0, .y = 0.0, .z = 0.0 };
	qsort(items, 4, sizeof items[0], cmp_depth);

	cairo_set_line_cap(cr, CAIRO_LINE_CAP_SQUARE);
	for (int i = 0; i < 4; i++) {
		const DrawItem *it = &items[i];
		if (it->kind == 3) {
			cairo_set_source_rgba(cr, bar->red, bar->green, bar->blue, 0.9);
			cairo_rectangle(cr, floor(cx) - 2.0, floor(cy) - 2.0, 5.0, 5.0);
			cairo_fill(cr);
			cairo_set_source_rgba(cr, text->red, text->green, text->blue, 1.0);
			cairo_rectangle(cr, floor(cx) - 1.0, floor(cy) - 1.0, 3.0, 3.0);
			cairo_fill(cr);
			continue;
		}

		const GdkRGBA *col = &t->colors[it->kind];
		double depth = (it->z + 1.0) * 0.5;
		double alpha = 0.40 + 0.60 * depth;
		double persp = 1.0 / (1.0 - 0.16 * it->z);
		double dx = it->x * radius * persp;
		double dy = -it->y * radius * persp;
		double tx = cx + dx;
		double ty = cy + dy;
		double len = hypot(dx, dy);

		cairo_set_source_rgba(cr, col->red, col->green, col->blue, alpha);
		if (len > 3.2) {
			double ux = dx / len, uy = dy / len;
			double hl = fmin(4.5, len * 0.44);
			double hw = hl * 0.54;
			cairo_set_line_width(cr, 1.6);
			cairo_move_to(cr, cx, cy);
			cairo_line_to(cr, tx - ux * (hl * 0.65), ty - uy * (hl * 0.65));
			cairo_stroke(cr);

			double bx = tx - ux * hl, by = ty - uy * hl;
			cairo_move_to(cr, tx, ty);
			cairo_line_to(cr, bx - uy * hw, by + ux * hw);
			cairo_line_to(cr, bx + uy * hw, by - ux * hw);
			cairo_close_path(cr);
			cairo_fill(cr);
		} else {
			cairo_arc(cr, tx, ty, 1.8 + 0.6 * depth, 0, 2.0 * M_PI);
			cairo_fill(cr);
		}
	}

	return FALSE;
}

// ---------------------------------------------------------------- waybar ABI

void *wbcffi_init(const wbcffi_init_info *info, const wbcffi_config_entry *cfg, size_t n) {
	(void)cfg, (void)n;
	Triad *t = g_new0(Triad, 1);
	t->yaw = HOME_YAW;
	t->pitch = HOME_PITCH;
	t->mode = MODE_DWELL;

	GtkContainer *root = info->get_root_widget(info->obj);
	gtk_widget_set_hexpand(GTK_WIDGET(root), FALSE);

	t->box = gtk_event_box_new();
	gtk_event_box_set_visible_window(GTK_EVENT_BOX(t->box), FALSE);
	gtk_widget_set_hexpand(t->box, FALSE);
	gtk_widget_set_halign(t->box, GTK_ALIGN_START);
	gtk_widget_set_size_request(t->box, 48, 36);
	gtk_widget_add_events(t->box, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_BUTTON_PRESS_MASK);
	gtk_widget_set_tooltip_markup(t->box, TOOLTIP);
	g_object_add_weak_pointer(G_OBJECT(t->box), (gpointer *)&t->box);

	t->area = gtk_drawing_area_new();
	gtk_widget_set_hexpand(t->area, FALSE);
	gtk_widget_set_size_request(t->area, 48, 36);
	g_object_add_weak_pointer(G_OBJECT(t->area), (gpointer *)&t->area);

	g_signal_connect(t->area, "realize", G_CALLBACK(on_realize), t);
	g_signal_connect(t->area, "draw", G_CALLBACK(on_draw), t);
	g_signal_connect(t->area, "style-updated", G_CALLBACK(on_style_updated), t);
	g_signal_connect(t->box, "enter-notify-event", G_CALLBACK(on_enter), t);
	g_signal_connect(t->box, "leave-notify-event", G_CALLBACK(on_leave), t);
	g_signal_connect(t->box, "button-press-event", G_CALLBACK(on_press), t);

	gtk_container_add(GTK_CONTAINER(t->box), t->area);
	gtk_container_add(root, t->box);
	gtk_widget_show_all(t->box);

	// Begin at calm isometric home lock so initial desktop settles cleanly, then sweep every 5s
	t->dwell_id = g_timeout_add(DWELL_MS, on_dwell_end, t);
	return t;
}

void wbcffi_deinit(void *instance) {
	Triad *t = instance;
	stop_timers(t);
	if (t->area) g_object_remove_weak_pointer(G_OBJECT(t->area), (gpointer *)&t->area);
	if (t->box) {
		g_object_remove_weak_pointer(G_OBJECT(t->box), (gpointer *)&t->box);
		gtk_widget_destroy(t->box);
	}
	g_free(t);
}

void wbcffi_update(void *instance) { (void)instance; }
void wbcffi_refresh(void *instance, int signal) { (void)instance, (void)signal; }
void wbcffi_doaction(void *instance, const char *name) { (void)instance, (void)name; }
