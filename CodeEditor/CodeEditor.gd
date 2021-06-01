tool
extends TextEdit

const ErrorOverlay := preload("ErrorOverlay.tscn")

export var class_color := Color(0.6, 0.6, 1.0)
export var member_color := Color(0.6, 1.0, 0.6)
export var keyword_color := Color(1.0, 0.6, 0.6)
export var quotes_color := Color(1.0, 1.0, 0.6)
export (String, FILE, "*.json") var keyword_data_path := "res://slide/widgets/text_edit/keywords.json"

## Stores errors
var errors := [] setget set_errors

var _vscrollbar: VScrollBar
## Keeps track of overlays to free them without risking destroying other TextEdit child nodes.
var _overlays := []

var _font_size: float = get_theme().default_font.size
var _line_spacing := 4.0
var _row_height := _font_size + _line_spacing
# The horizontal 30 px corresponds to the left gutter with line numbers. Found in the source code.
var _stylebox: StyleBox = theme.get_stylebox("normal", "TextEdit")
var _offset := Vector2(
	30.0 + _stylebox.content_margin_left,
	_stylebox.content_margin_bottom
)


func _ready() -> void:
	_enhance_syntax_highlighting()
	for child in get_children():
		if child is VScrollBar:
			_vscrollbar = child
			break
	_vscrollbar.connect("scrolling", self, "update_overlays")
	set_errors(
		[
			{
				message = "Wrong function",
				range = {start = {character = 0, line = 4}, end = {character = 7, line = 4}}
			}
		]
	)


func update_overlays() -> void:
	for overlay in _overlays:
		overlay.queue_free()
	_overlays.clear()

	for error in errors:
		var overlay = ErrorOverlay.instance()
		_overlays.append(overlay)
		add_child(overlay)

		var region := calculate_error_region(error.range)
		overlay.setup(error.message, region)


func calculate_error_region(error_range: Dictionary) -> Rect2:
	var start := (
		Vector2(
			error_range.start.character * _font_size,
			error_range.start.line * _row_height - _line_spacing
		)
		+ _offset
	)
	var size := (
		Vector2(error_range.end.character * _font_size, (error_range.end.line + 1) * _row_height)
		- start
		+ _offset
	)
	return Rect2(start, size)


func set_errors(value: Array) -> void:
	errors = value
	update_overlays()


func _enhance_syntax_highlighting() -> void:
	add_color_region('"', '"', quotes_color)
	add_color_region("'", "'", quotes_color)
	for c in ClassDB.get_class_list():
		add_keyword_color(c, class_color)
		for m in ClassDB.class_get_property_list(c):
			for key in m:
				add_keyword_color(key, member_color)

	var file := File.new()
	file.open(keyword_data_path, file.READ)
	var keywords: Dictionary = parse_json(file.get_as_text())
	file.close()
	for k in keywords["list"]:
		add_keyword_color(k, keyword_color)
