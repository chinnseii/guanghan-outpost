shader_type canvas_item;

// Character skin-tone shader (2026-07-17, see user/CHARACTER_SKIN_TONE_HANDOFF.md
// and docs/handoff/ACTIVE_TASKS.md PLAYER-VISUAL-01 Round 13). Applied as the
// CanvasItem material on player_visual.gd's Node2D, which draws the full
// character walk-cycle sheet via draw_texture_rect_region() -- TEXTURE/UV here
// are Godot's built-ins for that same draw call, so this samples the exact
// same frame region of the albedo sheet the node is already drawing.
//
// skin_mask_texture is a SEPARATE full texture sharing the same 6-col x 4-row
// UV grid (down/left/right/up rows, frames 00-05 columns) as the albedo sheet,
// but is NOT a sub-region draw itself -- sampling it at the built-in UV still
// lands on the matching frame because normalized UV is resolution-independent
// and both texture's frames occupy identical UV-space regions (see the
// handoff's own point 2: "两张贴图必须使用同一UV...SpriteSheet的6x4网格参数必须一致").
//
// Mask channel protocol: R=shadow, G=midtone, B=highlight, A=how much this
// pixel should shift toward the skin-tone color (0 = untouched, per the
// handoff's "A=0时不得改动原始SpriteSheet"). Only pixels the mask actually
// covers (face/ears/hands) are affected -- suit, hair, backpack, and outline
// are never touched since the mask has alpha=0 everywhere else.

uniform sampler2D skin_mask_texture: filter_nearest;
uniform vec4 skin_shadow_color: source_color = vec4(0.725, 0.478, 0.353, 1.0);
uniform vec4 skin_mid_color: source_color = vec4(0.914, 0.722, 0.569, 1.0);
uniform vec4 skin_highlight_color: source_color = vec4(0.973, 0.847, 0.714, 1.0);

void fragment() {
	vec4 albedo = texture(TEXTURE, UV);
	vec4 mask = texture(skin_mask_texture, UV);
	vec3 skin_color = mask.r * skin_shadow_color.rgb + mask.g * skin_mid_color.rgb + mask.b * skin_highlight_color.rgb;
	vec3 final_rgb = mix(albedo.rgb, skin_color, mask.a);
	COLOR = vec4(final_rgb, albedo.a);
}
