class_name UpdateDialog
extends CustomAcceptDialog

@onready var title: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var ok_button: Button = %OkButton
@onready var close_button: Button = %CloseButton
@onready var http_request: HTTPRequest = %HTTPRequest

var asking_permission := false

const CHECK_UPDATE_INTERVAL = 3600 # seconds


func _ready() -> void:
	super()
	
	if not OS.has_feature("standalone") or OS.get_name() == "Web":
		return
	
	if Options.last_update_check == -1:
		Options.last_update_check = int(Time.get_unix_time_from_system())
		Options.save()
		ask_permission()
		return
	
	if Options.check_updates and Time.get_unix_time_from_system() - Options.last_update_check > CHECK_UPDATE_INTERVAL:
		Options.last_update_check = int(Time.get_unix_time_from_system())
		Options.save()
		http_request.request("https://api.github.com/repos/pattlebass/Music-DJ/releases/latest")


func ask_permission() -> void:
	asking_permission = true
	title.text = "DIALOG_UPDATE_TITLE_ASK"
	body_label.text = tr(&"DIALOG_UPDATE_BODY_ASK") % "https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement"
	ok_button.text = "DIALOG_UPDATE_BTN_ACCEPT"
	close_button.text = "DIALOG_UPDATE_BTN_DENY"
	popup_centered.call_deferred()


func _on_HTTP_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Received response code %s from Github" % response_code)
	 
	var json_result = JSON.parse_string(body.get_string_from_utf8())
	
	if not json_result:
		return
	
	if ProjectSettings.get_setting("application/config/version") != json_result.tag_name:
		body_label.text = tr(&"DIALOG_UPDATE_BODY") % json_result.tag_name
		popup_centered()


func _on_ok_button_pressed() -> void:
	if asking_permission:
		Options.check_updates = true
		Options.save()
	else:
		OS.shell_open("https://www.github.com/pattlebass/Music-DJ/releases/latest")
	popup_hide()


func _on_close_button_pressed() -> void:
	if asking_permission:
		Options.check_updates = false
		Options.save()
	popup_hide()


func _on_body_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)
