extends Node
class_name Generator

const BOOLEAN_VALUES : Array[String] = [
	"corrupted",
	"synthesised",
	"identified",
	"fractured",
	"transfigured"
]

const INTEGER_VALUES : Array[String] = [
	"memory_strands",
	"map_tier",
	"sockets",
	"linked_sockets",
	"delirium_cluster_size",
	"stack_size",
	"area_level",
	"gem_level",
	"quality"
]

var m_strictness : int = 0
var m_global_label_overrides : Dictionary[StringName, Variant] = {}
var m_string_collections : Dictionary[StringName, PackedStringArray] = {}
var m_macros : Dictionary[StringName, String] = {}
var m_conditions : Dictionary[StringName, bool] = {}
var m_formatted_labels : Dictionary[StringName, PackedStringArray] = {}
var m_formatted_icons : Dictionary[StringName, PackedStringArray] = {}
var m_constructed_filter : Array[PackedStringArray] = []

func get_constructed_filter() -> Array[PackedStringArray]:
	return m_constructed_filter

func generate_filter(layout : Dictionary) -> void:
	if m_constructed_filter.is_empty() == false:
		return

	m_strictness = layout.get("strictness", 0)

	for condition : StringName in layout.get("conditions", {}).keys():
		m_conditions[condition] = layout.get("conditions", {})[condition]

	for label_override_key : StringName in layout.get("global_label_overrides", {}).keys():
		m_global_label_overrides[label_override_key] = layout.get("global_label_overrides", {})[label_override_key]

	for macro : Dictionary in layout.get("macros"):
		var id : StringName = macro["id"]
		var text : String = macro["text"]

		if id.begins_with("_") == false:
			printerr("'%s' is not a valid macro ID, they must all start with an underscore!" % id)
			continue

		m_macros[id] = text

	for string_collection_key : StringName in layout.get("string_collections", {}).keys():
		var string_collection : PackedStringArray = []

		for base_type : String in layout["string_collections"][string_collection_key]:
			string_collection.append("\"%s\"" % base_type)

		if m_string_collections.has(string_collection_key):
			printerr("String Collections already contains '%s'" % string_collection_key)
		else:
			m_string_collections[string_collection_key] = string_collection

	for label_key : StringName in layout.get("labels", {}).keys():
		var generated_label : PackedStringArray = _construct_label(layout.get("labels")[label_key])
		m_formatted_labels[label_key] = generated_label

	for icon_key : StringName in layout.get("icons", {}).keys():
		var generated_icon : PackedStringArray = _construct_label(layout.get("icons")[icon_key])
		m_formatted_icons[icon_key] = generated_icon

	m_constructed_filter = _construct_filter(layout["filter"])

func _construct_label(style : Dictionary) -> PackedStringArray:
	var label_strings : PackedStringArray = []

	if style.has("border"):
		label_strings.append("\tSetBorderColor %s" % _schema_to_filter_colour(style["border"]))

	if style.has("text"):
		label_strings.append("\tSetTextColor %s" % _schema_to_filter_colour(style["text"]))

	if style.has("background"):
		label_strings.append("\tSetBackgroundColor %s" % _schema_to_filter_colour(style["background"]))

	if m_global_label_overrides.has("font_size"):
		label_strings.append("\tSetFontSize %d" % m_global_label_overrides["font_size"])
	elif style.has("font_size"):
		label_strings.append("\tSetFontSize %d" % style["font_size"])

	return label_strings

func _construct_filter(categories : Array) -> Array[PackedStringArray]:
	var filter : Array[PackedStringArray] = []

	for category : Dictionary in categories:
		if category.has("category") == false || category.has("rules") == false:
			continue

		var filter_category : PackedStringArray = [
			"",
			"# ===========================",
			"# %s" % category["category"],
		]

		if category.has("comment"):
			filter_category.append_array(_parse_comment(category["comment"]))

		filter_category.append("# ===========================\n")

		for rule : Dictionary in category["rules"]:
			var group : Array = []

			if rule.has("group"):
				group = rule["group"]
			else:
				group.append(rule)

			for group_entry : Dictionary in group:
				var has_key : Callable = func(key : String) -> bool:
					if group_entry.has(key):
						return true
					elif rule.has(key):
						return true

					return false

				var get_value : Callable = func(key : String) -> Variant:
					if group_entry.has(key):
						return group_entry[key]
					elif rule.has(key):
						return rule[key]

					return null

				# Rules without a condition are always added.
				if has_key.call("any_condition"):
					var is_enabled : bool = false

					# Any true condition is enough.
					var conditions : Dictionary = get_value.call("any_condition")
					for condition : String in conditions.keys():
						if m_conditions.get(condition, false) == conditions[condition]:
							is_enabled = true
							break

					if is_enabled == false:
						continue

				if has_key.call("all_conditions"):
					var is_enabled : bool = true

					# We need each condition to match.
					var conditions : Dictionary = get_value.call("all_conditions")
					for condition : String in conditions.keys():
						if m_conditions.get(condition, false) != conditions[condition]:
							is_enabled = false
							break

					if is_enabled == false:
						continue

				var generated_rule : PackedStringArray = []

				if has_key.call("comment"):
					generated_rule.append_array(_parse_comment(get_value.call("comment")))

				# ===========================
				# Show is default, Hide if the user has specified it as true.
				# ===========================
				var hidden_rule : bool = false
				if has_key.call("hide") && get_value.call("hide") == true:
					hidden_rule = true
					generated_rule.append("Hide")
				else:
					generated_rule.append("Show")

				# ===========================
				# Base Type
				# ===========================
				if has_key.call("base_type"):
					generated_rule.append(_construct_base_type_line(get_value.call("base_type"), false))
				elif has_key.call("exact_base_type"):
					generated_rule.append(_construct_base_type_line(get_value.call("exact_base_type"), true))

				# ===========================
				# Checks item class
				# ===========================
				if has_key.call("class"):
					generated_rule.append(_construct_class_line(get_value.call("class"), false))
				elif has_key.call("exact_class"):
					generated_rule.append(_construct_class_line(get_value.call("exact_class"), true))

				# ===========================
				# Area Level
				# ===========================
				if has_key.call("until_level"):
					generated_rule.append("\tAreaLevel < %d" % get_value.call("until_level"))
				elif has_key.call("after_level"):
					generated_rule.append("\tAreaLevel > %d" % get_value.call("after_level"))

				# ===========================
				# Rarity
				# ===========================
				if has_key.call("rarity"):
					if typeof(get_value.call("rarity")) == TYPE_ARRAY:
						var rarities : PackedStringArray = [
							"\tRarity =="
						]

						for rarity : String in get_value.call("rarity"):
							rarities.append("\"%s\"" % rarity.to_pascal_case())

						generated_rule.append(" ".join(rarities))
					else:
						generated_rule.append("\tRarity == %s" % get_value.call("rarity").to_pascal_case())


				# ===========================
				# Socket Group
				# ===========================
				if has_key.call("socket_group"):
					var socket_group : String = get_value.call("socket_group")
					generated_rule.append("\tSocketGroup == \"%s\"" % socket_group)

				# ===========================
				# Influence checking
				# ===========================
				if has_key.call("influence"):
					if typeof(get_value.call("influence")) == TYPE_ARRAY:
						var rarities : PackedStringArray = [
							"\tHasInfluence"
						]

						for influence : String in get_value.call("influence"):
							rarities.append("\"%s\"" % influence.to_pascal_case())

						generated_rule.append(" ".join(rarities))
					else:
						generated_rule.append("\tHasInfluence %s" % get_value.call("influence").to_pascal_case())

				for boolean_value : String in BOOLEAN_VALUES:
					if has_key.call(boolean_value):
						var is_set : bool = get_value.call(boolean_value)
						var filter_name : String = _schema_to_filter_name(boolean_value)

						if is_set:
							generated_rule.append("\t%s True" % filter_name)
						else:
							generated_rule.append("\t%s False" % filter_name)

				for integer_value : String in INTEGER_VALUES:
					if has_key.call(integer_value):
						var integer_value_variant : Variant = get_value.call(integer_value)
						var filter_name : String = _schema_to_filter_name(integer_value)

						if typeof(integer_value_variant) == TYPE_INT:
							var value : int = integer_value_variant
							generated_rule.append("\t%s == %d" % [ filter_name, value ])
						elif typeof(integer_value_variant) == TYPE_FLOAT:
							# We often have floats in a JSON since JSON uses floats for everything. But we know these values should be integers.
							var value : int = roundi(integer_value_variant)
							generated_rule.append("\t%s == %d" % [ filter_name, roundi(value) ])
						else:
							generated_rule.append("\t%s %s" % [ filter_name, integer_value_variant ])

				# ===========================
				# Mod check
				# ===========================
				if has_key.call("has_mod"):
					generated_rule.append(_construct_has_mod_line(get_value.call("has_mod"), false))
				elif has_key.call("exact_has_mod"):
					generated_rule.append(_construct_has_mod_line(get_value.call("exact_has_mod"), true))

				# ===========================
				# Label
				# ===========================
				if has_key.call("label"):
					if typeof(get_value.call("label")) == TYPE_STRING:
						generated_rule.append_array(m_formatted_labels[get_value.call("label")])
					else:
						generated_rule.append_array(_construct_label(get_value.call("label")))
				elif hidden_rule == false && m_global_label_overrides.is_empty() == false:
					generated_rule.append_array(_construct_label({}))

				# ===========================
				# Icon
				# ===========================
				if has_key.call("icon"):
					generated_rule.append(_construct_icon_line(get_value.call("icon")))

				# ===========================
				# Effect
				# ===========================
				if has_key.call("effect"):
					generated_rule.append("\tPlayEffect %s" % get_value.call("effect").to_pascal_case())

				if generated_rule.size() > 1:
					generated_rule.append("")
					filter_category.append_array(generated_rule)

		filter.append(filter_category)

	return filter

func _parse_colour(colour_string : String) -> Color:
	if colour_string.begins_with("#"):
		return Color(colour_string)
	else:
		# Normal filter formatted colour like 123 95 85 255
		var split : PackedStringArray = colour_string.split(" ")

		if split.size() == 4:
			return Color.from_rgba8(
				split[0].to_int(),
				split[1].to_int(),
				split[2].to_int(),
				split[3].to_int()
			)

	return Color.PURPLE

func _parse_comment(comment : String) -> PackedStringArray:
	var return_value : PackedStringArray = []

	var split_comment : PackedStringArray = comment.split(" ")
	var char_count : int = 0
	var line : PackedStringArray = []

	for word : String in split_comment:
		if char_count == 0:
			line.append("#")

		char_count += word.length()
		line.append(word)

		if char_count >= 100:
			return_value.append(" ".join(line))
			char_count = 0
			line = []

	if char_count != 0:
		return_value.append(" ".join(line))

	return return_value

func _construct_icon_line(icon : Dictionary) -> String:
	var size : String = icon.get("size", "large")
	var shape : String = icon.get("shape", "circle")
	var colour : String = icon.get("colour", "purple")

	var size_int : int = 0

	match size:
		"large":
			size_int = 0
		"medium":
			size_int = 1
		"small":
			size_int = 2

	return "\tMinimapIcon %d %s %s" % [
		size_int,
		colour.to_pascal_case(),
		shape.to_pascal_case()
	]

func _construct_base_type_line(base_type : Variant, exact : bool) -> String:
	if typeof(base_type) == TYPE_ARRAY:
		var base_type_string : PackedStringArray = []

		for type : String in base_type:
			base_type_string.append("\"%s\"" % type)

		if exact:
			return "\tBaseType == %s" % " ".join(base_type_string)
		else:
			return "\tBaseType %s" % " ".join(base_type_string)
	elif typeof(base_type) == TYPE_STRING:
		var line_start : String = ""

		if exact:
			line_start = "\tBaseType =="
		else:
			line_start = "\tBaseType"

		if base_type.begins_with("_"):
			if m_string_collections.has(base_type):
				return "%s %s" % [ line_start, " ".join(m_string_collections[base_type]) ]
			else:
				return "%s %s" % [ line_start, m_macros[base_type] ]
		else:
			return "%s \"%s\"" % [ line_start, base_type ]

	return ""

func _construct_class_line(class_info : Variant, exact : bool) -> String:
	if typeof(class_info) == TYPE_ARRAY:
		var base_type_string : PackedStringArray = []

		for type : String in class_info:
			base_type_string.append("\"%s\"" % type)

		if exact:
			return "\tClass == %s" % " ".join(base_type_string)
		else:
			return "\tClass %s" % " ".join(base_type_string)
	elif typeof(class_info) == TYPE_STRING:
		var line_start : String = ""

		if exact:
			line_start = "\tClass =="
		else:
			line_start = "\tClass"

		if class_info.begins_with("_"):
			if m_string_collections.has(class_info):
				return "%s %s" % [ line_start, " ".join(m_string_collections[class_info]) ]
			else:
				return "%s %s" % [ line_start, m_macros[class_info] ]
		else:
			return "%s \"%s\"" % [ line_start, class_info ]

	return ""

func _construct_has_mod_line(mod_info : Variant, exact : bool) -> String:
	if typeof(mod_info) == TYPE_ARRAY:
		var base_type_string : PackedStringArray = []

		for type : String in mod_info:
			base_type_string.append("\"%s\"" % type)

		if exact:
			return "\tHasExplicitMod == %s" % " ".join(base_type_string)
		else:
			return "\tHasExplicitMod %s" % " ".join(base_type_string)
	elif typeof(mod_info) == TYPE_STRING:
		var line_start : String = ""

		if exact:
			line_start = "\tHasExplicitMod =="
		else:
			line_start = "\tHasExplicitMod"

		if mod_info.begins_with("_"):
			if m_string_collections.has(mod_info):
				return "%s %s" % [ line_start, " ".join(m_string_collections[mod_info]) ]
			else:
				return "%s %s" % [ line_start, m_macros[mod_info] ]
		else:
			return "%s \"%s\"" % [ line_start, mod_info ]

	return ""

func _schema_to_filter_colour(schema_colour : String) -> String:
	var colour : Color = _parse_colour(schema_colour)

	return "%d %d %d %d" % [
		colour.r * 255,
		colour.g * 255,
		colour.b * 255,
		colour.a * 255
	]

func _schema_to_filter_name(in_name : String) -> String:
	match in_name:
		"corrupted":
			return "Corrupted"
		"synthesised":
			return "SynthesisedItem"
		"memory_strands":
			return "MemoryStrands"
		"map_tier":
			return "MapTier"
		"sockets":
			return "Sockets"
		"linked_sockets":
			return "LinkedSockets"
		"delirium_cluster_size":
			return "EnchantmentPassiveNum"
		"stack_size":
			return "StackSize"
		"area_level":
			return "AreaLevel"
		"identified":
			return "Identified"
		"fractured":
			return "FracturedItem"
		"gem_level":
			return "GemLevel"
		"quality":
			return "Quality"
		"transfigured":
			return "TransfiguredGem"
		_:
			printerr("Could not translate schema name '%s'!" % in_name)
			return ""
