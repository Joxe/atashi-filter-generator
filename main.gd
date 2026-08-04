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
	if FileAccess.file_exists("user://config.json"):
		var fa_user_config : FileAccess = FileAccess.open("user://config.json", FileAccess.ModeFlags.READ)
		var user_config : Dictionary = JSON.parse_string(fa_user_config.get_as_text())

		m_filter_config_path = user_config.get("config_path", "./")
		m_config_line_edit.text = m_filter_config_path
		m_output_dir = user_config.get("output_path", "./")
		m_select_output_line_edit.text = m_output_dir
		_print_config_outline()

		if m_output_dir.contains("My Games/Path of Exile"):
			m_output_rich_text_label.append_text("\n[color=red]It seems like you selected the Path of Exile directory as output directory. Make sure that your existing filters are backed up since this WILL overwrite them.[/color]")
	else:
		_save_user_config()

	m_file_dialog.file_selected.connect(
		func(path : String) -> void:
			m_filter_config_path = path
			m_config_line_edit.text = path
			m_output_rich_text_label.append_text("\nOpening config file at '%s'" % path)
			_save_user_config()
			_print_config_outline()
	)

	m_file_dialog.dir_selected.connect(
		func(path : String) -> void:
			m_output_dir = path
			m_select_output_line_edit.text = path
			m_output_rich_text_label.append_text("\nSelected '%s' as the output directory." % path)
			_save_user_config()

			if path.contains("My Games/Path of Exile"):
				m_output_rich_text_label.append_text("\n[color=red]It seems like you selected the Path of Exile directory as output directory. Make sure that your existing filters are backed up since this WILL overwrite them.[/color]")
	)

	m_start_button.pressed.connect(_generate_filter)
	m_config_button.pressed.connect(
		func() -> void:
			m_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE

			if m_filter_config_path.is_empty() == false:
				var last_slash : int = m_filter_config_path.rfind("/")
				var last_backslash : int = m_filter_config_path.rfind("\\")

				if last_slash != -1 || last_backslash != -1:
					# Using max here since one of them should be not -1, if they are both positive, glhf
					m_file_dialog.current_dir = m_filter_config_path.left(max(last_slash, last_backslash) + 1)
			
			m_file_dialog.popup()
	)
	m_select_output_button.pressed.connect(
		func() -> void:
			m_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
			m_file_dialog.current_dir = m_output_dir
			m_file_dialog.popup()
	)

func _save_user_config() -> void:
	var fa_user_config : FileAccess = FileAccess.open("user://config.json", FileAccess.ModeFlags.WRITE_READ)
	var user_config : Dictionary = {
		"config_path": m_filter_config_path,
		"output_path": m_output_dir
	}

	fa_user_config.store_string(JSON.stringify(user_config))

func _print_config_outline() -> void:
	if FileAccess.file_exists(m_filter_config_path) == false:
		printerr("No config file was found at '%s'" % m_filter_config_path)
	
	var fa_filter_config : FileAccess = FileAccess.open(m_filter_config_path, FileAccess.ModeFlags.READ)
	var filter_configurations : Dictionary = JSON.parse_string(fa_filter_config.get_as_text())

	if filter_configurations.get("filters", []).size() == 0:
		m_output_rich_text_label.append_text("\nFound no filter configurations!")
	else:
		m_output_rich_text_label.append_text("\nFound %d filter configurations" % filter_configurations["filters"].size())

		for configuration : Dictionary in filter_configurations["filters"]:
			m_output_rich_text_label.append_text("\n\t%s" % configuration["name"])

func _generate_filter() -> void:
	if FileAccess.file_exists(m_filter_config_path) == false:
		printerr("No config file was found at '%s'" % m_filter_config_path)
	
	var fa_filter_config : FileAccess = FileAccess.open(m_filter_config_path, FileAccess.ModeFlags.READ)
	var filter_configurations : Dictionary = JSON.parse_string(fa_filter_config.get_as_text())

	var base_config : Dictionary = filter_configurations["global_config"]
	var filters : Array = filter_configurations["filters"]

	for filter : Dictionary in filters:
		# Create the Filter specific config by duplicating the base and then merging the specific into it.
		# We have to do this for each filter for them to be unique.
		var combined_config : Dictionary = base_config.duplicate_deep()
		var filter_specific_config : Dictionary = filter.get("config", {})

		combined_config.merge(filter_specific_config)
		if base_config.has("conditions") && filter_specific_config.has("conditions"):
			combined_config["conditions"].merge(filter_specific_config["conditions"])

		# Load the layout and string collections and make them into Dictionaries
		var fa_layout : FileAccess = FileAccess.open(combined_config["layout"], FileAccess.ModeFlags.READ)
		var fa_string_collections : FileAccess = FileAccess.open(combined_config["string_collections"], FileAccess.ModeFlags.READ)

		var layout : Dictionary = JSON.parse_string(fa_layout.get_as_text())
		var string_collections : Dictionary = JSON.parse_string(fa_string_collections.get_as_text())

		# The string collections will be assigned to the filter, overriding whatever's there.
		for str_coll : String in string_collections.keys():
			layout["string_collections"][str_coll] = string_collections[str_coll]

		# Finally, copy over the config to the layout.
		# TODO: Hard coding the array is ok with 2 elements, but redo if it expands.
		for config : String in [ "conditions", "global_label_overrides" ]:
			for config_key : String in combined_config[config].keys():
				layout[config][config_key] = combined_config[config][config_key]

		var generator : Generator = Generator.new()
		add_child(generator)
		generator.generate_filter(layout)
		var generated_filter_categories : Array[PackedStringArray] = generator.get_constructed_filter()

		var final_filter : PackedStringArray = []

		for category : PackedStringArray in generated_filter_categories:
			final_filter.append_array(category)

		if layout.get("conditions", {}).get("ruthless", false):
			var file_path : String = "%s/%s.ruthlessfilter" % [ m_output_dir, filter["name"] ]
			var fa_filter : FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.WRITE_READ)
			fa_filter.store_string("\n".join(final_filter))
			m_output_rich_text_label.append_text("\nWrote '%s' to\n\t%s" % [ filter["name"], file_path ])
		else:
			var file_path : String = "%s/%s.filter" % [ m_output_dir, filter["name"] ]
			var fa_filter : FileAccess = FileAccess.open(file_path, FileAccess.ModeFlags.WRITE_READ)
			fa_filter.store_string("\n".join(final_filter))
			m_output_rich_text_label.append_text("\nWrote '%s' to\n\t%s" % [ filter["name"], file_path ])

		# For now we just throw away the node after it's done, but we could potentially save it to do other things
		generator.queue_free()
		remove_child(generator)
