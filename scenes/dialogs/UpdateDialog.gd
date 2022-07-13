extends CustomDialog

var asking_permission := true

func _ready() -> void:
	if not OS.has_feature("standalone") or OS.get_name() == "HTML5":
		return
	
	if !OS.is_ok_left_and_cancel_right():
		$VBoxContainer/HBoxContainer.move_child(
			$VBoxContainer/HBoxContainer/CloseButton,
			0
		)
	
	if Variables.options.check_updates == null:
		$VBoxContainer/Title.text = "DIALOG_UPDATE_TITLE_ASK"
		$VBoxContainer/Body.bbcode_text = tr("DIALOG_UPDATE_BODY_ASK") % "https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement"
		$VBoxContainer/HBoxContainer/OkButton.text = "DIALOG_UPDATE_BTN_ACCEPT"
		$VBoxContainer/HBoxContainer/CloseButton.text = "DIALOG_UPDATE_BTN_DENY"
		call_deferred("popup_centered")
	elif OS.get_name() != "HTML5" and Variables.options.check_updates:
		asking_permission = false
		$HTTPRequest.request("https://api.github.com/repos/pattlebass/Music-DJ/releases/latest")


func _on_HTTPRequest_request_completed(_result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray) -> void:
	print("Received response code %s from Github" % response_code)
	
	var json_result = JSON.parse(body.get_string_from_utf8()).result
	
	if Variables.VERSION != json_result.tag_name:
		$VBoxContainer/Body.text = tr("DIALOG_UPDATE_BODY") % json_result.tag_name
		popup_centered()


func _on_OkButton_pressed() -> void:
	if asking_permission:
		Variables.options.check_updates = true
		Variables.save_options()
	else:
		OS.shell_open("https://www.github.com/pattlebass/Music-DJ/releases/latest")
	hide()


func _on_CloseButton_pressed():
	if asking_permission:
		Variables.options.check_updates = false
		Variables.save_options()
	hide()


func _on_Body_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func about_to_show() -> void:
	yield(get_tree(), "idle_frame")
	rect_size.y = $VBoxContainer.rect_size.y
	.about_to_show()


func popup_hide() -> void:
	if asking_permission and Variables.options.check_updates == null:
		Variables.options.check_updates = false
		Variables.save_options()
	.popup_hide()
