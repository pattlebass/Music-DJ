class_name ProgressDialog
extends CustomDialog

@onready var progress_bar: ProgressBar = %ProgressBar
@onready var title: Label = %Title
@onready var body: Label = %Body
@onready var open_button: Button = %OpenButton
@onready var download_button: Button = %DownloadButton
@onready var share_button: Button = %ShareButton
@onready var cancel_button: Button = %CancelButton

var body_text := ""
var body_text_completed := ""
var title_text_completed := "DIALOG_PROGRESS_TITLE_DONE"

var progress := 0.0:
	set(val):
		if val == progress:
			return
		progress = val
		progress_bar.value = progress
		if progress >= 1:
			title.text = title_text_completed
			body.text = body_text_completed
			
			#share_button.disabled = false
			open_button.disabled = false
			download_button.disabled = false
			cancel_button.text = "BTN_CLOSE"
			
			progress_bar.hide()

signal canceled


func popup() -> void:
	progress_bar.value = 0
	progress_bar.show()
	
	open_button.disabled = true
	share_button.disabled = true
	
	title.text = "DIALOG_PROGRESS_TITLE"
	body.text = body_text
	cancel_button.text = "BTN_CANCEL"
	
	if OS.get_name() == "Android":
#		share_button.show()
		open_button.hide()
		download_button.hide()
	elif OS.get_name() == "Web":
		share_button.hide()
		open_button.hide()
		download_button.show()
	
	super()


func error(code: int) -> void:
	body.text = tr("DIALOG_PROGRESS_ERROR") % code
	progress_bar.hide()
	
	share_button.hide()
	open_button.hide()
	download_button.hide()


func _on_cancel_button_pressed() -> void:
	canceled.emit()
	hide()
