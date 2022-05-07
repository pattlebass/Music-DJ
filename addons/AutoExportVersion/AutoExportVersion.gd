tool
extends EditorPlugin

## Path to the version script file (bruh).
const VERSION_SCRIPT_PATH = "res://version.gd"

## Change the code of this method to return a String that will identify your version.
## Two example ways of doing so are provided, just uncomment one of them.
## You can use the arguments to customize your version based on selected platform or something.
func _fetch_version(features: PoolStringArray, is_debug: bool, path: String, flags: int) -> String:
	### Git version
	# Version is number of commits. Requires git installed
	# and project inside git repository with at least 1 commit.
	
#	var output := []
#	OS.execute("git", PoolStringArray(["rev-list", "--count", "HEAD"]), true, output)
#	if output.empty() or output[0].empty():
#		push_error("Failed to fetch version. Make sure you have git installed and project is inside valid git directory.")
#	else:
#		return output[0].trim_suffix("\n")
	
	### Profile version
	# Extracts version from an export profile. Requires export_presets.cfg to exist. 
	# The version will be taken from the first profile that contains non-empty value
	# in one of the version_keys.
	
	var version_keys := ["file_version", "product_version", "version/name"]

	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") == OK:
		var version := ""
		for section in config.get_sections():
			if section.ends_with(".options"):
				for key in config.get_section_keys(section):
					for check_key in version_keys:
						if key.ends_with(check_key):
							version = str(config.get_value(section, key))

						if not version.empty():
							break
				if not version.empty():
					break
			if not version.empty():
				break

		if version.empty():
			push_error("Failed to fetch version. No valid version key found in export profiles.")
		else:
			return version
	else:
		push_error("Failed to fetch version. export_presets.cfg does not exist.")
	
	return ""

### Unimportant stuff here.

var exporter: AEVExporter

func _enter_tree() -> void:
	exporter = AEVExporter.new()
	exporter.plugin = self
	add_export_plugin(exporter)
	
	if not File.new().file_exists(VERSION_SCRIPT_PATH):
		exporter.store_version(_fetch_version(PoolStringArray(), true, "", 0))

func _exit_tree() -> void:
	remove_export_plugin(exporter)

class AEVExporter extends EditorExportPlugin:
	var plugin
	
	func _export_begin(features: PoolStringArray, is_debug: bool, path: String, flags: int):
		var version: String = plugin._fetch_version(features, is_debug, path, flags)
		if version.empty():
			push_error("Version string is empty. Make sure your _fetch_version() is configured properly.")
		
		store_version(version)

	func store_version(version: String):
		var script = GDScript.new()
		script.source_code = str("extends Reference\nconst VERSION = \"", version, "\"\n")
		if ResourceSaver.save(VERSION_SCRIPT_PATH, script) != OK:
			push_error("Failed to save version file. Make sure the path is valid.")
