extends Node2D
class_name Main

@export
var m_start_button : Button = null

@export
var m_filter_label : RichTextLabel = null

@export
var m_config_button : Button = null

@export
var m_config_line_edit : LineEdit = null

@export
var m_select_output_button : Button = null

@export
var m_select_output_line_edit : LineEdit = null

@export
var m_file_dialog : FileDialog = null

@export
var m_output_rich_text_label : RichTextLabel = null

var m_filter_config_path : String = ""
var m_output_dir : String = ""

func _ready() -> void:
	if _load_user_config():
		_print_message("Loading previous settings...")
		_print_config_outline()
		_check_if_poe_directory()

	# TODO: This only works as long as we have only one file to select, if we need to open different files we need to know
	# what kind of file we were trying to open or have multiple file dialogs in the scene.
	m_file_dialog.file_selected.connect(
		func(path : String) -> void:
			m_filter_config_path = path
			m_config_line_edit.text = path
			_print_message("Opening config file at '%s'" % path)
			_save_user_config()
			_print_config_outline()
	)

	# TODO: This only works as long as we have only one directory to select, if we need to open different directories we need to know
	# what directory we were trying to open or have multiple file dialogs in the scene.
	m_file_dialog.dir_selected.connect(
		func(path : String) -> void:
			m_output_dir = path
			m_select_output_line_edit.text = path
			_print_message("Selected '%s' as the output directory." % path)
			_save_user_config()
			_check_if_poe_directory()
	)

	m_start_button.pressed.connect(_generate_filter)

	m_config_button.pressed.connect(
		func() -> void:
			m_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

			# Try to extract the current file's directory and set it to the file dialog so it opens up in the last place we selected a file at.
			if m_filter_config_path.is_empty() == false:
				var last_slash : int = m_filter_config_path.rfind("/")
				var last_backslash : int = m_filter_config_path.rfind("\\")

				if last_slash > -1 && last_backslash > -1:
					# File path contains both a forward and back slash so we get the lowest which *should* be the rightmost one.
					m_file_dialog.current_dir = m_filter_config_path.left(min(last_slash, last_backslash) + 1)
				elif last_slash != -1 || last_backslash != -1:
					# Using max here since one of them should be not -1.
					m_file_dialog.current_dir = m_filter_config_path.left(max(last_slash, last_backslash) + 1)
			
			m_file_dialog.popup()
	)

	m_select_output_button.pressed.connect(
		func() -> void:
			m_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			m_file_dialog.current_dir = m_output_dir
			m_file_dialog.popup()
	)

# Saves the user config to the user:// directory.
# Windows: %APPDATA%\Godot\app_userdata\atashi-filter-generator
# Mac: ~/Library/Application Support/Godot/app_userdata/atashi-filter-generator
# Linux: ~/.local/share/godot/app_userdata/atashi-filter-generator
func _save_user_config() -> void:
	var fa_user_config : FileAccess = FileAccess.open("user://config.json", FileAccess.ModeFlags.WRITE_READ)
	var user_config : Dictionary = {
		"config_path": m_filter_config_path,
		"output_path": m_output_dir
	}

	fa_user_config.store_string(JSON.stringify(user_config))

# Returns true if there was a file to load, so false it not an error or anything.
func _load_user_config() -> bool:
	if FileAccess.file_exists("user://config.json") == false:
		return false

	var user_config_file : FileAccess = FileAccess.open("user://config.json", FileAccess.ModeFlags.READ)
	var user_config : Dictionary = JSON.parse_string(user_config_file.get_as_text())

	m_filter_config_path = user_config.get("config_path", "./")
	m_config_line_edit.text = m_filter_config_path
	m_output_dir = user_config.get("output_path", "./")
	m_select_output_line_edit.text = m_output_dir

	return true

func _check_if_poe_directory() -> void:
	# TODO: Check Mac directory, it should be fine on Linux since they use Proton which just emula- *ehum* translates the Windows directory 
	# and it should therefore match the path (untested).
	if m_output_dir.contains("My Games/Path of Exile") || m_output_dir.contains("My Games\\Path of Exile"):
		_print_error("[color=red]It seems like you selected the Path of Exile directory as output directory. Make sure that your existing filters are backed up since this WILL overwrite them.[/color]")

func _print_config_outline() -> void:
	if FileAccess.file_exists(m_filter_config_path) == false:
		_print_error("No config file was found at '%s'" % m_filter_config_path)
		return
	
	var fa_filter_config : FileAccess = FileAccess.open(m_filter_config_path, FileAccess.ModeFlags.READ)
	var filter_configurations : Dictionary = JSON.parse_string(fa_filter_config.get_as_text())

	if filter_configurations.get("filters", []).size() == 0:
		_print_message("Found no filter configurations!")
	else:
		_print_message("Found %d filter configurations" % filter_configurations["filters"].size())

		for configuration : Dictionary in filter_configurations["filters"]:
			_print_message("\t%s" % configuration["name"])

## The general idea is to take each filter we have in the config, generate a Layout Dictionary for each of them and sending that
## off into the generator. The generator therefore gets a dictionary of their own to play with however they want.
func _generate_filter() -> void:
	_print_message("[color=green]Generating filters...[/color]")

	if FileAccess.file_exists(m_filter_config_path) == false:
		printerr("No config file was found at '%s'" % m_filter_config_path)
	
	var filter_config_file : FileAccess = FileAccess.open(m_filter_config_path, FileAccess.ModeFlags.READ)
	var filter_config : Dictionary = JSON.parse_string(filter_config_file.get_as_text())

	# The base config is the basis on which each filter merges their filter specific settings into.
	var base_config : Dictionary = filter_config.get("global_config", {})

	for filter : Dictionary in filter_config.get("filters", {}):
		# Create the Filter specific config by duplicating the base and then merging the specific into it.
		# We have to do this for each filter for the base config to be unique for each filter, otherwise the filters
		# would start interacting with each other.
		var combined_config : Dictionary = base_config.duplicate_deep()
		var filter_specific_config : Dictionary = filter.get("config", {})

		combined_config.merge(filter_specific_config, true)

		# Merge does not overwrite thing by default and for conditions we want to merge it on a per-element basis so we have
		# to do it manually if conditions exists in both the base config and the filter. The condition merge does overwrite.
		# TODO: We might need to do this for more dictionaries if they are added in the future, maybe a better system is possible?
		if base_config.has("conditions") && filter_specific_config.has("conditions"):
			combined_config["conditions"].merge(filter_specific_config["conditions"], true)

		# Load the layout and string collections and make them into Dictionaries
		if FileAccess.file_exists(combined_config["layout"]) == false:
			continue

		var layout_file : FileAccess = FileAccess.open(filter.get("layout", combined_config["layout"]), FileAccess.ModeFlags.READ)

		if FileAccess.file_exists(combined_config["string_collections"])== false:
			continue

		var string_collections_file : FileAccess = FileAccess.open(combined_config["string_collections"], FileAccess.ModeFlags.READ)

		var layout : Dictionary = JSON.parse_string(layout_file.get_as_text())
		var string_collections : Dictionary = JSON.parse_string(string_collections_file.get_as_text())

		# The string collections will be assigned to the filter, overriding whatever's there.
		if layout.has("string_collections") == false:
			layout["string_collections"] = {}
			
		if layout.has("config") == false:
			layout["config"] = {
				"conditions": {}
			}

		for str_coll : String in string_collections.keys():
			layout["string_collections"][str_coll] = string_collections[str_coll]

		# Finally, copy over the config to the layout.
		# TODO: Hard coding the array is ok with 2 elements, but redo if it expands.
		for config : String in [ "conditions", "global_label_overrides" ]:
			for config_key : String in combined_config[config].keys():
				if layout.has(config) == false:
					layout[config] = {}

				layout[config][config_key] = combined_config[config][config_key]

		# Using a node here for reasons unknown, might as well be a RefCounted but if we want graphical stuff in the
		# future a node might be useful? Doesn't really matter anyway.
		var generator : Generator = Generator.new()
		add_child(generator)
		generator.generate_filter(layout)

		# The generated filter is returned as a bunch of arrays, one for each category. Right now we don't do anything
		# with it but maybe we want to in the future. So now it's simply joining it into a single array so we can output
		# it into a file.
		var generated_filter_categories : Array[PackedStringArray] = generator.get_constructed_filter()
		var final_filter : PackedStringArray = []

		for category : PackedStringArray in generated_filter_categories:
			final_filter.append_array(category)

		var file_path : String = ""

		# Ruthless filters need their own file ending.
		if layout.get("conditions", {}).get("ruthless", false):
			file_path = "%s/%s.ruthlessfilter" % [ m_output_dir, filter["name"] ]
		else:
			file_path = "%s/%s.filter" % [ m_output_dir, filter["name"] ]
		
		# Open file, create if it doesn't exist, overwrite if it does.
		var filter_file : FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.WRITE_READ)
		filter_file.store_string("\n".join(final_filter))
		_print_message("Wrote '%s' to\n\t%s" % [ filter["name"], file_path ])

		# For now we just throw away the node after it's done, but we could potentially save it to do other things like 
		# rendering a preview or something.
		generator.queue_free()
		remove_child(generator)

## Output a message to the rich text label that the user sees.
func _print_message(message : String) -> void:
	if m_output_rich_text_label != null:
		m_output_rich_text_label.append_text("\n%s" % message)
	else:
		print(message)

## Output a red error message to the rich text label that the user sees.
func _print_error(message : String) -> void:
	if m_output_rich_text_label != null:
		m_output_rich_text_label.append_text("\n[color=red]%s[/color]" % message)
	else:
		printerr(message)
