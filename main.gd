extends Node2D
class_name Main

@export
var m_start_button : Button = null

@export
var m_filter_config_path : String = ""

@export
var m_filter_label : RichTextLabel = null

func _ready() -> void:
	m_start_button.pressed.connect(_generate_filter)

func _generate_filter() -> void:
	m_filter_label.text = ""

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

			#for line : String in category:
			#	print(line)

		var fa_filter : FileAccess = FileAccess.open("user://%s.filter" % filter["name"], FileAccess.ModeFlags.WRITE_READ)
		fa_filter.store_string("\n".join(final_filter))
		print("Saved user://%s.filter" % filter["name"])

		# For now we just throw away the node after it's done, but we could potentially save it to do
		generator.queue_free()
		remove_child(generator)