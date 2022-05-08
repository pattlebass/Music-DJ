extends "res://scenes/DialogScript.gd"

onready var progress_bar = get_node("VBoxContainer/HBoxContainer2/VBoxContainer/ProgressBar")

var path_text = ""
var after_saving = "stay"


func about_to_show():
	progress_bar.value = 0
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
		if path_text.ends_with(".mdj"):
			$VBoxContainer/Label2.text = "You can find it in the project list or you can download it."
		else:
			$VBoxContainer/Label2.text = "Please keep this window focused. After it finishes click the download button"
		after_saving = "stay"
	.about_to_show()


func _on_CancelButton_pressed():
	hide()
	main.get_node("SaveDialog").is_cancelled = true


func _process(delta):
	if progress_bar.value >= progress_bar.max_value:
		$VBoxContainer/HBoxContainer/OpenButton.disabled = false
		$VBoxContainer/HBoxContainer/DownloadButton.disabled = false
		$VBoxContainer/Label.text = "Saved"
		progress_bar.visible = false
		
		if after_saving == "close":
			hide()

		if OS.get_name() == "HTML5" and path_text.ends_with(".wav"):
			_on_DownloadButton_pressed()
	
		set_process(false)
		
	else:
		progress_bar.value += delta


func _on_OpenButton_pressed():
	if OS.get_name() == "Android":
		OS.alert(ProjectSettings.globalize_path(Variables.user_dir), "Folder location")
	else:
		OS.shell_open(ProjectSettings.globalize_path(Variables.user_dir))


func _on_DownloadButton_pressed():
	var file_name = path_text.split("/")[-1]
	var path
	if file_name.ends_with(".mdj"):
		path = Variables.user_dir.plus_file("Projects/%s" % file_name)
	elif file_name.ends_with(".wav"):
		path = Variables.user_dir.plus_file("Exports/%s" % file_name)
	main.get_node("SaveDialog").download_file(path, file_name)
