extends Node2D

const TILE_SIZE := 18
const KEY_ATLAS := Vector2i(7, 1)
const DOOR_TOP_ATLAS := Vector2i(10, 6)
const DOOR_BOTTOM_ATLAS := Vector2i(10, 7)

const KEY_SCENE := preload("res://scenes/prefabs/keys/key_gold.tscn")
const DOOR_SCENE := preload("res://scenes/prefabs/doors/door_locked.tscn")

func _ready() -> void:
	call_deferred("_build")

func _collect_layers(node: Node, out: Array) -> void:
	if node is TileMapLayer:
		out.append(node)
	for c in node.get_children():
		_collect_layers(c, out)

func _cell_world(l: TileMapLayer, cell: Vector2i) -> Vector2:
	return l.global_position + Vector2(cell * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)

func _build() -> void:
	var root: Node = get_tree().current_scene
	var layers: Array = []
	_collect_layers(root, layers)

	var key_cells: Array = []
	var door_cells: Array = []
	for layer in layers:
		var l := layer as TileMapLayer
		if l.tile_set == null:
			continue
		for cell in l.get_used_cells():
			var atlas := l.get_cell_atlas_coords(cell)
			if atlas == KEY_ATLAS:
				key_cells.append({"layer": l, "cell": cell, "pos": _cell_world(l, cell)})
			elif atlas == DOOR_TOP_ATLAS:
				var below := Vector2i(cell.x, cell.y + 1)
				var has_bottom := l.get_cell_source_id(below) != -1 and l.get_cell_atlas_coords(below) == DOOR_BOTTOM_ATLAS
				var top_p := _cell_world(l, cell)
				var bot_p := _cell_world(l, below) if has_bottom else top_p + Vector2(0.0, float(TILE_SIZE))
				var height := absf(bot_p.y - top_p.y) + float(TILE_SIZE)
				door_cells.append({
					"layer": l,
					"cells": [cell, below],
					"pos": Vector2(top_p.x, (top_p.y + bot_p.y) * 0.5),
					"height": height,
					"has_bottom": has_bottom,
				})

	var spawn_x := 0.0
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		spawn_x = (player as Node2D).global_position.x
	var near := func(a, b): return absf(a.pos.x - spawn_x) < absf(b.pos.x - spawn_x)
	key_cells.sort_custom(near)
	door_cells.sort_custom(near)

	var holder: Node = get_parent()
	if holder == null:
		holder = root
	var keys_root := Node2D.new()
	keys_root.name = "Keys"
	holder.add_child(keys_root)
	var doors_root := Node2D.new()
	doors_root.name = "Doors"
	holder.add_child(doors_root)

	var i := 1
	for k in key_cells:
		var n := KEY_SCENE.instantiate()
		n.name = "Key_%02d" % i
		n.key_id = i
		n.position = k.pos
		keys_root.add_child(n)
		print("[Spawner] 钥匙 %d -> 世界(%.0f, %.0f)" % [i, k.pos.x, k.pos.y])
		i += 1

	i = 1
	for d in door_cells:
		var node := DOOR_SCENE.instantiate()
		node.name = "Door_%02d" % i
		node.key_id = i
		node.position = d.pos
		doors_root.add_child(node)
		var shape := node.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if shape != null:
			var rect := RectangleShape2D.new()
			rect.size = Vector2(float(TILE_SIZE) + 8.0, d.height)
			shape.shape = rect
		var label := node.get_node_or_null("Prompt") as Label
		if label != null:
			label.position = Vector2(0.0, -d.height * 0.5 - 16.0)
		print("[Spawner] 门 %d -> 世界(%.0f, %.0f) 高 %.0f（下半格%s）需要钥匙 %d" % [
			i, d.pos.x, d.pos.y, d.height, "有" if d.has_bottom else "无", i])
		i += 1

	for item in key_cells:
		(item.layer as TileMapLayer).erase_cell(item.cell)
	for d in door_cells:
		for c in d.cells:
			(d.layer as TileMapLayer).erase_cell(c)
	print("[Spawner] 已替换 %d 格钥匙、%d 扇门（%d 格）" % [key_cells.size(), door_cells.size(), door_cells.size() * 2])
