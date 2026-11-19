// waybar-ribbons: one fragment pass draws a twisted wireframe ribbon from a spectrum. Every strand
// is y = f(x), so each pixel measures its distance to the 9 strands analytically: no geometry,
// per frame only the spectrum goes to the GPU. ribbons.c prepends the #version line (GLSL 330
// core or 300 es, whichever context GTK hands out) and embeds this file at build time.
uniform sampler2D spec;     // N x 1 spectrum, 0..1, R32F (read with texelFetch: not filterable on ES)
uniform float width;        // region width in bar px
uniform float scale;        // framebuffer px per bar px
uniform float fbh;          // framebuffer height
uniform float phase;        // twist phase, advanced only while the spectrum changes
uniform float mirror;       // 1: lows at the right end (the left channel, lows toward the player)
uniform vec4 clut[16];      // the palette's CLUT (colors.css @clut0..15); alpha 0 = missing
uniform vec4 grid;          // the floor (@grid)
uniform vec4 spark;         // the specular edge (@text)
out vec4 frag;

const float H = 30.0, D = 40.0, TWIST = 360.0, SPINE = 540.0;
const int STRANDS = 9;

// cosine interpolation between bars
float amp(float u) {
	int n = textureSize(spec, 0).x;
	float f = u * float(n - 1);
	int i = int(floor(f));
	float t = (1.0 - cos((f - float(i)) * 3.14159265)) * 0.5;
	return mix(texelFetch(spec, ivec2(i, 0), 0).r, texelFetch(spec, ivec2(min(i + 1, n - 1), 0), 0).r, t);
}

// strand j's y and normalized depth at bar-x x; a = the energy there
vec2 strand(float x, int j, out float a) {
	float u = clamp(x / width, 0.0, 1.0);
	if (mirror > 0.5) u = 1.0 - u;
	a = amp(u);
	float env = clamp(min(u / 0.05, (1.0 - u) / 0.03), 0.0, 1.0);
	float hw = (0.6 + 6.0 * a) * env + 0.4;
	float th = 6.2831853 * u * width / TWIST + phase;
	float yc = H * 0.5 - 0.5 + 2.2 * sin(6.2831853 * u * width / SPINE + phase * 0.6);
	float s = -1.0 + 2.0 * float(j) / float(STRANDS - 1);
	float z = s * hw * sin(th);
	return vec2(yc - s * hw * cos(th) * D / (D - z), z / hw);
}

vec3 lut(float a) {
	vec4 c = clut[int(clamp(a * 16.0, 0.0, 15.0))];
	return c.rgb * c.a;
}

void main() {
	vec2 p = vec2(gl_FragCoord.x, fbh - gl_FragCoord.y) / scale;
	float x = p.x, y = p.y;
	vec3 col = vec3(0.0);

	// the floor: two dotted rows receding to the player (1px dots every 4px), the far row only
	// over the 78% nearest the player
	float dot1 = step(fract(x / 4.0) * 4.0, 1.0);
	float su = x / width, near = mirror > 0.5 ? step(0.22, su) : step(su, 0.78);
	col += grid.rgb * grid.a * dot1 * (step(27.0, y) * step(y, 28.0) * 0.55 + step(25.0, y) * step(y, 26.0) * 0.28 * near);

	// every strand at this x has the same energy, so the same CLUT color: sum their intensity, and
	// where that color times the sum passes 1, scale it down by its brightest channel. Clipped
	// channel by channel, the 9 strands where they bunch (silence, the tapered ends) bleach a light
	// palette's blue to white; scaled, they keep the hue, and a face-on edge still burns brighter
	// than its CLUT color wherever that fits.
	float a, a2, k = 0.0, top = 1e9, bot = -1e9, front = -2.0, fy = 0.0;
	for (int j = 0; j < STRANDS; j++) {
		vec2 s0 = strand(x, j, a), s1 = strand(x + 1.0, j, a2);
		float slope = s1.x - s0.x;
		float d = abs(y - s0.x) / sqrt(1.0 + slope * slope);
		float zn = s0.y;
		bool edge = j == 0 || j == STRANDS - 1;
		float depth = pow(mix(0.08, 1.0, (zn + 1.0) * 0.5), 1.5) * (edge ? 1.0 : 0.35);
		float core = 1.0 - smoothstep(0.2, 0.9, d);
		float glow = edge ? 0.28 * exp(-d * d / (2.0 * 1.6 * 1.6)) : 0.0;
		if (zn < -0.05) { core *= step(0.5, fract(x / 3.0)); depth *= 0.5; }   // stippled far side
		k += (core + glow) * min(depth, 1.0);
		top = min(top, s0.x); bot = max(bot, s0.x);
		if (zn > front) { front = zn; fy = d; }
	}
	if (y > top && y < bot) {
		k += 0.10;                                                  // translucent surface
		if (fract(x / 15.0) * 15.0 < 1.0) k += 0.30;                // rungs
	}
	vec3 rib = lut(a) * k;
	col += rib / max(1.0, max(rib.r, max(rib.g, rib.b)));
	if (front > 0.6 && a > 0.15)                                    // specular on the face-on front edge
		col += spark.rgb * spark.a * 0.5 * (front - 0.6) / 0.4 * (1.0 - smoothstep(0.2, 0.9, fy));
	col = min(col, 1.0);
	// premultiplied: the bar's own background and rule show through where nothing is drawn
	frag = vec4(col, max(col.r, max(col.g, col.b)));
}
