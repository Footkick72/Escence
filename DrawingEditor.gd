extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var Curve = load("res://Curve.tscn")

var curve
var curves = []
var drawing = false
var selected_curve
var in_menu = false
var moving_curve = false
var drawing_color = null
var is_shown = false
var id = null

signal to_menu
signal to_home

# Called when the node enters the scene tree for the first time.
func _ready():
	new_curve()
	$Menu.hide()
	hide()

func set_id(n):
	id = n

func get_id():
	return id

func _input(event):
	if not in_menu and is_shown:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if not curve:
					new_curve()
				moving_curve = false
				if event.pressed and not drawing:
						drawing = true
						selected_curve = null
						new_curve()
				else:
					drawing = false
					close_curve()
			elif event.button_index == BUTTON_RIGHT:
				if event.pressed:
					moving_curve = true
					selected_curve = get_closest_curve(event.position)
				else:
					moving_curve = false
		if event is InputEventPanGesture:
			if selected_curve:
				var dir = event.delta[1]
				selected_curve.change_res(dir)
		if event is InputEventMouseMotion:
			if drawing and not selected_curve:
					if len(curve.points) == 0 or curve.points[len(curve.points) - 1] != event.position:
						curve.add_point(event.position)
			elif selected_curve and moving_curve:
				selected_curve.move(event.relative)
		if event is InputEventKey:
			if event.scancode == KEY_ESCAPE:
				to_menu()
			if selected_curve:
				if event.pressed:
					if event.scancode == KEY_EQUAL:
						selected_curve.scale_by(1.02)
					if event.scancode == KEY_MINUS:
						selected_curve.scale_by(0.98)
					if event.scancode == KEY_BRACELEFT:
						selected_curve.rotate_by(-3)
					if event.scancode == KEY_BRACERIGHT:
						selected_curve.rotate_by(3)
					if event.scancode == KEY_BACKSPACE:
						remove_child(selected_curve)
						for i in range(len(curves)):
							if curves[i] == selected_curve:
								curves.remove(i)
								break
		

func clear():
	for c in curves:
		c.queue_free()
	curves = []
	selected_curve = null
	curve = null
	drawing = false
	in_menu = false
	moving_curve = false
	drawing_color = null
	is_shown = false
	#id = null

func show():
	$ColorRect.show()
	for c in curves:
		c.show()
	is_shown = true

func hide():
	$ColorRect.hide()
	for c in curves:
		c.hide()
	is_shown = false

func save_drawing():
	var save = File.new()
	save.open("user://drawing %s.save" % id, File.WRITE)
	for curve in curves:
		var save_dict = curve.save_data()
		save.store_line(to_json(save_dict))
	save.close()
	clear()

func save_preview():
	var image = take_screenshot()
	image.save_png("user://drawing %s preview.png" % id)

func load_drawing():
	var save = File.new()
	if not save.file_exists("user://drawing %s.save" % id):
		return # Error! We don't have a save to load.
	save.open("user://drawing %s.save" % id, File.READ)
	while save.get_position() < save.get_len():
		var node_data = parse_json(save.get_line())
		var c = Curve.instance()
		c.load_data(node_data)
		curves.append(c)
		add_child(c)
	save.close()

func get_closest_curve(pos):
	var d = INF
	var c = null
	for e in curves:
		var x = INF
		for p in e.points:
			x = min((p - pos).length(), x)
		if x < d and x < 20:
			d = x
			c = e
	return c

func close_curve():
	if not curve or len(curve.points) <= 1:
		return
	curve.close()
	curves.append(curve)
	selected_curve = curve

func new_curve():
	curve = Curve.instance()
	if drawing_color:
		curve.default_color = drawing_color
	add_child(curve)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func to_menu():
	save_preview()
	$Menu.show()
	if not curve.is_closed():
		close_curve()
	in_menu = true
	emit_signal("to_menu")

func _on_Menu_save_curve_changes():
	if selected_curve:
		selected_curve.default_color = $Menu/CurveEditor/ColorPicker.color
		drawing_color = $Menu/CurveEditor/ColorPicker.color

func _on_Menu_back_button():
	in_menu = false
	$Menu.hide()

func _on_Menu_home_button():
	in_menu = false
	$Menu.hide()
	hide()
	save_drawing()
	emit_signal("to_home")

func take_screenshot():
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	return image
