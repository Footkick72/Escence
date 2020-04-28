extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

signal save_curve_changes
signal back_button
signal home_button

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func show():
	$CurveEditor.show()
	$Background.show()
	$BackButton.show()
	$HomeButton.show()

func hide():
	$CurveEditor.hide()
	$Background.hide()
	$BackButton.hide()
	$HomeButton.hide()

func _on_BackButton_button_up():
	emit_signal("back_button")

func _on_ColorPicker_color_changed(_color):
	emit_signal("save_curve_changes")

func _on_HomeButton_button_up():
	emit_signal("home_button")
