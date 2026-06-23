class_name UpdateDialog
extends CustomAcceptDialog

const CHECK_UPDATE_INTERVAL = 3600 # seconds

@onready var title2: Label = %Title
@onready var body_label: RichTextLabel = %Body
@onready var ok_button: Button = %OkButton
@onready var close_button: Button = %CloseButton
@onready var http_request: HTTPRequest = %HTTPRequest

var asking_permission := false
var version: String = ProjectSettings.get_setting("application/config/version")
var beta: bool = ProjectSettings.get_setting("application/config/beta")

func _ready() -> void:
	super()
	
	if OS.has_feature("editor") or OS.get_name() == "Web" or beta:
		return
	
	if not Options.check_updates_answered:
		ask_permission()
		return
	
	var time_since_last_check := int(Time.get_unix_time_from_system()) - Options.last_update_check
	if Options.check_updates and time_since_last_check > CHECK_UPDATE_INTERVAL:
		Options.last_update_check = int(Time.get_unix_time_from_system())
		Options.save()
		http_request.request("https://api.github.com/repos/pattlebass/Music-DJ/releases/latest")


func open() -> void:
	size.y = 0 # HACK
	super()
	size.y = 0 # HACK


func _process(delta: float) -> void:
	# Even uglier HACK
	size.y = 0


func ask_permission() -> void:
	asking_permission = true
	title2.text = "DIALOG_UPDATE_TITLE_ASK"
	body_label.text = tr(&"DIALOG_UPDATE_BODY_ASK") % "https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement"
	ok_button.text = "DIALOG_UPDATE_BTN_ACCEPT"
	close_button.text = "DIALOG_UPDATE_BTN_DENY"
	open.call_deferred()


func _on_HTTP_request_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("Received response code %s from Github" % response_code)
	 
	var json_result = JSON.parse_string(body.get_string_from_utf8())
	
	if not json_result:
		return
	
	if version != json_result.tag_name:
		body_label.text = tr(&"DIALOG_UPDATE_BODY") % json_result.tag_name
		open()


func _on_ok_button_pressed() -> void:
	if asking_permission:
		Options.check_updates = true
		Options.check_updates_answered = true
		Options.save()
	else:
		OS.shell_open("https://www.github.com/pattlebass/Music-DJ/releases/latest")
	close()


func _on_close_button_pressed() -> void:
	if asking_permission:
		Options.check_updates = false
		Options.check_updates_answered = true
		Options.save()
	close()


func _on_body_meta_clicked(meta: String) -> void:
	OS.shell_open(meta)
