extends PopupDialog

onready var main = get_parent()
onready var progress_bar = get_node("VBoxContainer/HBoxContainer2/VBoxContainer/ProgressBar")

var path_text = ""
var after_saving = "stay"


func _ready():
	theme = load("res://assets/themes/%s/theme.tres" % GlobalVariables.options.theme)


func _on_ProgressDialog_about_to_show():
	set_process(true)
	$VBoxContainer/HBoxContainer/OpenButton.disabled = true
	$VBoxContainer/Label.text = "Saving..."
	$VBoxContainer/Label2.text = ProjectSettings.globalize_path(path_text)
	progress_bar.visible = true
	if OS.get_name() == "Android":
		$VBoxContainer/HBoxContainer/OpenButton.visible = false
		$VBoxContainer/HBoxContainer/DownloadButton.visible = false
		after_saving = "close"
	elif OS.get_name() == "HTML5":
		$VBoxContainer/HBoxContainer/OpenButton.visible = false
		$VBoxContainer/HBoxContainer/DownloadButton.visible = true
		after_saving = "stay"
		$VBoxContainer/Label2.text = "You can find it in the project list or you can download it."
	$AnimationPlayer.play("fade_in")


func _on_ProgressDialog_popup_hide():
	visible = true
	# Animation
	$AnimationPlayer.play_backwards("fade_in")
	yield(get_tree().create_timer(0.1), "timeout")
	
	progress_bar.value = 0
	
	visible = false


func _on_CancelButton_pressed():
	hide()
	main.get_node("SaveDialog").is_cancelled = true


func _process(delta):
	if progress_bar.value >= progress_bar.max_value:
		$VBoxContainer/HBoxContainer/OpenButton.disabled = false
		$VBoxContainer/Label.text = "Saved"
		progress_bar.visible = false
		
		if after_saving == "close":
			hide()
		else:
			pass
		
		set_process(false)
	else:
		progress_bar.value += delta


func _on_OpenButton_pressed():
	if OS.get_name() == "Android":
		OS.alert(ProjectSettings.globalize_path(main.user_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(main.user_dir))


func _on_DownloadButton_pressed():
	var new_path = path_text.split("/")[-1]
	var file = File.new()
	file.open(main.user_dir+"Projects/"+new_path, File.READ)
	var file_data_string = var2str(file.get_var())
	file.close()
	main.get_node("SaveDialog").download_file(new_path+"t", file_data_string)
