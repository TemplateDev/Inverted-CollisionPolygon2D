@icon("res://addons/inverted_collisionpolygon2d/icon.png")
@tool
extends EditorPlugin

const plugin_button = preload("res://addons/inverted_collisionpolygon2d/plugin_button.tscn")
var tool_button

func _enter_tree():
	tool_button = plugin_button.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tool_button)
	add_tool_menu_item("Invert Polygon",invert_polygons)
	tool_button.get_node("Button").connect("pressed",invert_polygons)
	tool_button.hide()
	
	EditorInterface.get_selection().selection_changed.connect(update_button_state)
	
	ProjectSettings.set("Inverted CollisionPolygon2D/Configuration/Border Size", 100)
	ProjectSettings.set_initial_value("Inverted CollisionPolygon2D/Configuration/Border Size",100)
	ProjectSettings.set_as_basic("Inverted CollisionPolygon2D/Configuration/Border Size", true)
	var property_info = {
		"name": "Inverted CollisionPolygon2D/Configuration/Border Size",
		"type": TYPE_FLOAT,
		"hint": PROPERTY_HINT_RANGE,
		"hint_string": "1,1000,0.01,or_greater"
	}
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.save()
	
	var script = preload("res://addons/inverted_collisionpolygon2d/polygon2d_to_collision2d.gd")
	var icon = preload("res://addons/inverted_collisionpolygon2d/icon custom.png")
	add_custom_type("InvertedCollisionPolygon2D", "CollisionPolygon2D", script, icon)

func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, tool_button)
	tool_button.queue_free()
	remove_tool_menu_item("Invert Polygon")
	
	ProjectSettings.set("Inverted CollisionPolygon2D/Configuration/Border Size",null)
	remove_custom_type("InvertedCollisionPolygon2D")

func get_selection() -> Array:
	return EditorInterface.get_selection().get_selected_nodes()

func update_button_state():
	var selected_items = get_selection()
	if is_selected_collisionpolygons(selected_items) and len(selected_items) > 0:
		tool_button.show()
	else:
		tool_button.hide()

func is_selected_collisionpolygons(items: Array) -> bool:
	var successful := true
	for item in items:
		if not item is CollisionPolygon2D:
			successful = false
			break
	return successful

func invert_polygons():
	var selected_items: Array = get_selection()
	if not is_selected_collisionpolygons(selected_items):
		return
	for item: CollisionPolygon2D in selected_items:
		var PackedVector2 = get_inverted_polygon(item.polygon)
		item.polygon = PackedVector2
	tool_button.get_node("Button").button_pressed = false

func get_correction_point(points: PackedVector2Array) -> int:
	var correction_point := Vector2(0,INF)
	for point in points:
		if point.y <= correction_point.y:
			correction_point = point
	var index = points.find(correction_point)
	return index

func get_inverted_polygon(polygon: PackedVector2Array) -> PackedVector2Array:
	var inverted_vertices = PackedVector2Array()
	var border_size = ProjectSettings.get_setting("Inverted CollisionPolygon2D/Configuration/Border Size",100.0) as float
	
	# Get the most top point.
	var correction_point: int = get_correction_point(polygon)
	print(str(correction_point)," : ",polygon[correction_point])
	
	# Shift the entire polygon array indexes by the correction_point index!
		# Append elements from correction_point index to the end
	var shifted_polygon = []
	for i in range(correction_point, polygon.size()):
		shifted_polygon.append(polygon[i])
	
		# Append elements from start to correction_point index
	for i in range(correction_point):
		shifted_polygon.append(polygon[i])
	
	polygon = shifted_polygon
	
	# Get the bounding box.
	var min_point = Vector2.INF
	var max_point = -Vector2.INF
	for vertex in polygon:
		min_point.x = min(min_point.x, vertex.x)
		min_point.y = min(min_point.y, vertex.y)
		max_point.x = max(max_point.x, vertex.x)
		max_point.y = max(max_point.y, vertex.y)
	
	# Expand the bounding box.
	min_point -= Vector2(border_size, border_size)
	max_point += Vector2(border_size, border_size)
	
	# Add vertices.
	for vertex in polygon:
		inverted_vertices.append(Vector2(vertex.x, vertex.y))
	
	# Wrap the hole.
	inverted_vertices.append(inverted_vertices[0])
	
	# Add vertices for the border.
	inverted_vertices.append(Vector2(min_point.x, min_point.y))
	inverted_vertices.append(Vector2(min_point.x,max_point.y))
	inverted_vertices.append(Vector2(max_point.x,max_point.y))
	inverted_vertices.append(Vector2(max_point.x,min_point.y))
	inverted_vertices.append(Vector2(min_point.x, min_point.y))
	
	# Return the new inverted polygon!
	return inverted_vertices
