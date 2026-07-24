extends SceneTree

const OUT_DIR := "res://docs/screenshots/debug_clean"
const FloorPlatePlain := preload("res://assets/art/training_hub_v2/tiles/floor_plate_plain_01.png")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	root.size = Vector2i(800, 600)

	var background := ColorRect.new()
	background.color = Color("#07111b")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var holder := Node2D.new()
	holder.name = "Holder"
	root.add_child(holder)
	holder.scale = Vector2(2.0105, 1.404)  # matches a real observed non-uniform room_scale

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	var source := TileSetAtlasSource.new()
	source.texture = FloorPlatePlain
	source.texture_region_size = Vector2i(256, 256)
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
	var image := root.get_texture().get_image()
	image.save_png("%s/floor_unscaled.png" % OUT_DIR)
	print("saved")
	quit()
