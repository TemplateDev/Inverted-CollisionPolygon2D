extends CollisionPolygon2D

@export_category("Polygon2D to Collision2D")
@export var polygon_2d: Polygon2D

var last_polygon: PackedVector2Array = []

func _ready():
	var inverted_polygon = get_inverted_polygon(polygon_2d.polygon)
	polygon = inverted_polygon
	last_polygon = polygon

func _process(_delta):
	if polygon_2d.polygon != last_polygon:
		last_polygon = polygon_2d.polygon
		var inverted_polygon = get_inverted_polygon(polygon_2d.polygon)
		polygon = inverted_polygon

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
