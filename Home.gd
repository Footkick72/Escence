extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	var i = 0
	var save = File.new()
	while save.file_exists("user://drawing %s.save" % i):
		var image = Image.new()
		image.load("user://drawing %s preview.png" % (i))
		var texture = ImageTexture.new()
		texture.create_from_image(image, 0)
		$ItemList.add_icon_item(texture)
		i += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_ItemList_item_activated(index):
	$DrawingEditor.set_id(index)
	$DrawingEditor.load_drawing()
	$DrawingEditor.show()

func _on_AddDrawingButton_button_up():
	_on_ItemList_item_activated($ItemList.get_item_count())

func _on_DrawingEditor_to_home():
	var image = Image.new()
	image.load("user://drawing %s preview.png" % ($DrawingEditor.get_id()))
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	if $DrawingEditor.get_id() >= $ItemList.get_item_count():
		$ItemList.add_icon_item(texture)
	else:
		$ItemList.set_item_icon($DrawingEditor.get_id(), texture)

func _on_DeleteSelectedButton_button_up():
	$DeleteDrawingConfirmationDialog.popup()

func _on_DeleteDrawingConfirmationDialog_confirmed():
	var i = $ItemList.get_selected_items()[0]
	$ItemList.remove_item(i)
	var dir = Directory.new()
	dir.remove("user://drawing %s.save" % i)
	dir.remove("user://drawing %s preview.png" % i)
	for j in range(i, $ItemList.get_item_count() + 1):
		dir.rename("user://drawing %s.save" % (j+1), "user://drawing %s.save" % j)
