extends SceneTree

const OUT_DIR := "res://docs/screenshots/debug_clean"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(800, 600)

	var background := ColorRect.new()
	background.color = Color("#07111b")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	# Perfectly flat 256x256 image, single solid color, NO border, NO
	# internal structure whatsoever. If tile seams still appear, the
	# cause is rendering (mipmap/atlas padding), not texture content.
	var image := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	image.fill(Color("#1e2830"))
	var tex := ImageTexture.create_from_image(image)

	var holder := Node2D.new()
	holder.name = "Holder"
	root.add_child(holder)
	holder.scale = Vector2(2.0105, 1.404)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(256, 256)
	# Matches the real _build_floor() code: padding left at its true
	# default (true), region size (256) != tile_set.tile_size (64).
	source.create_tile(Vector2i.ZERO)
	var source_id := tile_set.add_source(source)

	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(layer)
	for gy in range(8):
		for gx in range(10):
			layer.set_cell(Vector2i(gx, gy), source_id, Vector2i.ZERO)

	await process_frame
	await process_frame
	await process_frame
	var result := root.get_texture().get_image()
	result.save_png("%s/synthetic_flat_padded.png" % OUT_DIR)
	print("saved")
	quit()
