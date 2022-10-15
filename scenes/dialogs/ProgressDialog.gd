extends CustomDialog

onready var progress_bar = get_node("VBoxContainer/HBoxContainer2/VBoxContainer/ProgressBar")
onready var title: Label = $VBoxContainer/Title
onready var body: Label = $VBoxContainer/Body
onready var open_button: Button = $VBoxContainer/HBoxContainer/OpenButton
onready var download_button: Button = $VBoxContainer/HBoxContainer/DownloadButton
onready var share_button: Button = $VBoxContainer/HBoxContainer/ShareButton

var path = ""
var after_saving = "stay"
var type_of_save := ""

# TODO: Refactor

func about_to_show() -> void:
	progress_bar.value = 0
	progress_bar.show()
	
	open_button.disabled = true
	share_button.disabled = true
	title.text = "DIALOG_PROGRESS_TITLE"
	body.text = ""
	
	set_process(true)
	
	if OS.get_name() == "Android":
#		share_button.show()
		open_button.hide()
		download_button.hide()
	elif OS.get_name() == "HTML5":
		share_button.hide()
		open_button.hide()
		download_button.show()
		after_saving = "stay"
		
		if type_of_save == "project":
			body.text = "DIALOG_PROGRESS_AFTER_PROJECT"
		else:
			body.text = "DIALOG_PROGRESS_KEEP_FOCUSED"
	
	$VBoxContainer.rect_size = rect_size
	
	.about_to_show()


func error(code: int) -> void:
	body.text = tr("DIALOG_PROGRESS_ERROR") % code
	progress_bar.hide()
	
	share_button.hide()
	open_button.hide()
	download_button.hide()
	
	set_process(false)


func _on_CancelButton_pressed() -> void:
	hide()
	main.get_node("SaveDialog").is_cancelled = true
	BoomBox.is_playing = false


func _process(delta) -> void:
	if progress_bar.value >= progress_bar.max_value:
#		share_button.disabled = false
		open_button.disabled = false
		download_button.disabled = false
		title.text = "DIALOG_PROGRESS_TITLE_DONE"
		
		progress_bar.hide()
		
		if after_saving == "close":
			hide()
	
		if type_of_save == "export":
			if OS.get_name() == "HTML5":
				yield(get_tree().create_timer(0.1), "timeout")
				_on_DownloadButton_pressed()
			else:
				body.text = tr("DIALOG_PROGRESS_AFTER_EXPORT") % ProjectSettings.globalize_path(path)
	
		set_process(false)
		
	else:
		progress_bar.value += delta


func _on_OpenButton_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(Variables.saves_dir))


func _on_DownloadButton_pressed() -> void:
	var file_name = path.get_file()
	Variables.download_file(path, file_name)


func _on_ShareButton_pressed() -> void:
	Variables.share_file(path, "", "", "", "audio/wav")
