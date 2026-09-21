extends TileMapLayer

# TileMapLayer owns its own generated four-colour atlas and cells.
func _ready() -> void:
	var image := Image.create(128, 32, false, Image.FORMAT_RGBA8)
	var colors := [Color("263b69"), Color("2b4778"), Color("314f82"), Color("38598c")]
	for tile_x in 4:
		for x in range(tile_x * 32, tile_x * 32 + 32):
			for y in range(32): image.set_pixel(x, y, colors[tile_x])
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(32, 32)
	for tile_x in 4: source.create_tile(Vector2i(tile_x, 0))
	var set := TileSet.new()
	set.tile_size = Vector2i(32, 32)
	set.add_source(source, 0)
	tile_set = set
	for x in range(-80, 211):
		for y in range(-20, 43): set_cell(Vector2i(x, y), 0, Vector2i(posmod(x + y * 2, 4), 0))
