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
	"quality",
	"item_level"
]

var m_strictness : int = 0
var m_global_label_overrides : Dictionary[StringName, Variant] = {}
var m_string_collections : Dictionary[StringName, PackedStringArray] = {}
var m_macros : Dictionary[StringName, String] = {}
var m_conditions : Dictionary[StringName, bool] = {}
var m_formatted_labels : Dictionary[StringName, PackedStringArray] = {}
var m_formatted_icons : Dictionary[StringName, String] = {}
var m_constructed_filter : Array[PackedStringArray] = []

# These are set while parsing so we can split up the parsing into multiple private functions. See these as read-only.
var m_group_entry : Dictionary = {}
var m_rule : Dictionary = {}

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

	for macro_key : StringName in layout.get("macros", {}).keys():
		m_macros[macro_key] = layout.get("macros", {})[macro_key]

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
		m_formatted_icons[icon_key] = _construct_icon_line(layout.get("icons")[icon_key])

	m_constructed_filter = _construct_filter(layout["layout"])

func _construct_label(style : Dictionary) -> PackedStringArray:
	var label_strings : PackedStringArray = []

	if m_global_label_overrides.has("border"):
		label_strings.append("\tSetBorderColor %s" % _layout_to_filter_colour(m_global_label_overrides["border"]))
	if style.has("border"):
		label_strings.append("\tSetBorderColor %s" % _layout_to_filter_colour(style["border"]))

	if m_global_label_overrides.has("text"):
		label_strings.append("\tSetTextColor %s" % _layout_to_filter_colour(m_global_label_overrides["text"]))
	if style.has("text"):
		label_strings.append("\tSetTextColor %s" % _layout_to_filter_colour(style["text"]))

	if m_global_label_overrides.has("background"):
		label_strings.append("\tSetBackgroundColor %s" % _layout_to_filter_colour(m_global_label_overrides["background"]))
	if style.has("background"):
		label_strings.append("\tSetBackgroundColor %s" % _layout_to_filter_colour(style["background"]))

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
			m_rule = rule
			var group : Array = []

			if rule.has("group"):
				group = rule["group"]
			else:
				group.append(rule)

			for group_entry : Dictionary in group:
				m_group_entry = group_entry

				# Check if the conditions enabled or disabled this group entry.
				if _is_rule_enabled() == false:
					continue

				var generated_rule : PackedStringArray = []

				if _rule_has_key("comment"):
					generated_rule.append_array(_parse_comment(_get_rule_value("comment")))

				# ===========================
				# Show is default, Hide if the user has specified it as true.
				# ===========================
				var hidden_rule : bool = false
				if _rule_has_key("hide") && _get_rule_value("hide") == true:
					hidden_rule = true
					generated_rule.append("Hide")
				else:
					generated_rule.append("Show")

				# ===========================
				# Base Type
				# ===========================
				if _rule_has_key("base_type"):
					generated_rule.append(_construct_line("base_type", _get_rule_value("base_type"), false))
				elif _rule_has_key("exact_base_type"):
					generated_rule.append(_construct_line("base_type", _get_rule_value("exact_base_type"), true))

				# ===========================
				# Checks item class
				# ===========================
				if _rule_has_key("class"):
					generated_rule.append(_construct_line("class", _get_rule_value("class"), false))
				elif _rule_has_key("exact_class"):
					generated_rule.append(_construct_line("class", _get_rule_value("exact_class"), true))

				# ===========================
				# Rarity
				# ===========================
				if _rule_has_key("rarity"):
					if typeof(_get_rule_value("rarity")) == TYPE_ARRAY:
						var rarities : PackedStringArray = [
							"\tRarity =="
						]

						for rarity : String in _get_rule_value("rarity"):
							rarities.append("\"%s\"" % rarity.to_pascal_case())

						generated_rule.append(" ".join(rarities))
					else:
						generated_rule.append("\tRarity == %s" % _get_rule_value("rarity").to_pascal_case())


				# ===========================
				# Socket Group
				# ===========================
				if _rule_has_key("socket_group"):
					var socket_group : String = _get_rule_value("socket_group")
					generated_rule.append("\tSocketGroup == \"%s\"" % socket_group)

				# ===========================
				# Influence checking
				# ===========================
				if _rule_has_key("influence"):
					if typeof(_get_rule_value("influence")) == TYPE_ARRAY:
						var rarities : PackedStringArray = [
							"\tHasInfluence"
						]

						for influence : String in _get_rule_value("influence"):
							rarities.append("\"%s\"" % influence.to_pascal_case())

						generated_rule.append(" ".join(rarities))
					else:
						generated_rule.append("\tHasInfluence %s" % _get_rule_value("influence").to_pascal_case())

				for boolean_value : String in BOOLEAN_VALUES:
					if _rule_has_key(boolean_value):
						var is_set : bool = _get_rule_value(boolean_value)
						var filter_name : String = _layout_to_filter_name(boolean_value)

						if is_set:
							generated_rule.append("\t%s True" % filter_name)
						else:
							generated_rule.append("\t%s False" % filter_name)

				for integer_value : String in INTEGER_VALUES:
					if _rule_has_key(integer_value):
						var integer_value_variant : Variant = _get_rule_value(integer_value)
						var filter_name : String = _layout_to_filter_name(integer_value)

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
				if _rule_has_key("has_mod"):
					generated_rule.append(_construct_line("has_mod", _get_rule_value("has_mod"), false))
				elif _rule_has_key("exact_has_mod"):
					generated_rule.append(_construct_line("has_mod", _get_rule_value("exact_has_mod"), true))

				# ===========================
				# Label
				# ===========================
				if _rule_has_key("label"):
					if typeof(_get_rule_value("label")) == TYPE_STRING:
						generated_rule.append_array(m_formatted_labels[_get_rule_value("label")])
					else:
						generated_rule.append_array(_construct_label(_get_rule_value("label")))
				elif hidden_rule == false && m_global_label_overrides.is_empty() == false:
					generated_rule.append_array(_construct_label({}))

				# ===========================
				# Icon
				# ===========================
				if _rule_has_key("icon"):
					generated_rule.append(_construct_icon_line(_get_rule_value("icon")))

				# ===========================
				# Effect
				# ===========================
				if _rule_has_key("effect"):
					generated_rule.append("\tPlayEffect %s" % _get_rule_value("effect").to_pascal_case())

				if generated_rule.size() > 1:
					generated_rule.append("")
					filter_category.append_array(generated_rule)

		filter.append(filter_category)

	return filter

func _is_rule_enabled() -> bool:
	# Rules without a condition are always added.
	var is_enabled : bool = false

	if _rule_has_key("any_condition"):
		# Any true condition is enough.
		var conditions : Dictionary = _get_rule_value("any_condition")
		for condition : String in conditions.keys():
			if m_conditions.get(condition, false) == conditions[condition]:
				is_enabled = true
				break
	elif _rule_has_key("all_conditions"):
		# We need each condition to match. Set enabled to true and then toggle it to false if any condition fails.
		var conditions : Dictionary = _get_rule_value("all_conditions")
		for condition : String in conditions.keys():
			if m_conditions.get(condition, false) != conditions[condition]:
				return false
	else:
		is_enabled = true

	if is_enabled == false:
		return false

	if _rule_has_key("strictness"):
		var strictness_variant : Variant = _get_rule_value("strictness")

		# If strictness is just a number, it is interpreted as equals.
		if typeof(strictness_variant) == TYPE_INT:
			var strictness : int = strictness_variant

			if strictness != m_strictness:
				is_enabled = false
		elif typeof(strictness_variant) == TYPE_FLOAT:
			# We often have floats in a JSON since JSON uses floats for everything. But we know these values should be integers.
			var strictness : int = roundi(strictness_variant)

			if strictness != m_strictness:
				is_enabled = false
		elif typeof(strictness_variant) == TYPE_STRING:
			# At this point we hope that it's a maths expression like "strictness": ">= 1"
			var strictness_expression : String = strictness_variant
			var split_expression : PackedStringArray = strictness_expression.dedent().split(" ")
			var operator : String = split_expression[0]
			var value : int = int(split_expression[1])

			if operator == "==":
				is_enabled = m_strictness == value
			elif operator == "!=":
				is_enabled = m_strictness != value
			elif operator == "<=":
				is_enabled = m_strictness <= value
			elif operator == ">=":
				is_enabled = m_strictness >= value
			elif operator == ">":
				is_enabled = m_strictness > value
			elif operator == "<":
				is_enabled = m_strictness < value

	return is_enabled

func _rule_has_key(key : String) -> bool:
	return m_group_entry.has(key) || m_rule.has(key)

func _get_rule_value(key : String) -> Variant:
	if m_group_entry.has(key):
		return m_group_entry[key]
	elif m_rule.has(key):
		return m_rule[key]

	return null

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

func _construct_icon_line(icon : Variant) -> String:
	if typeof(icon) == TYPE_STRING:
		return m_formatted_icons[icon]
	else:
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

func _construct_line(layout_key : String, layout_value : Variant, exact : bool) -> String:
	var filter_key : String = _layout_to_filter_name(layout_key)

	if typeof(layout_value) == TYPE_ARRAY:
		var filter_string : PackedStringArray = []

		for type : String in layout_value:
			filter_string.append("\"%s\"" % type)

		if exact:
			return "\t%s == %s" % [
				filter_key,
				" ".join(filter_string)
			]
		else:
			return "\t%s %s" % [
				filter_key,
				" ".join(filter_string)
			]
	elif typeof(layout_value) == TYPE_STRING:
		var line_start : String = ""

		if exact:
			line_start = "\t%s ==" % filter_key
		else:
			line_start = "\t%s" % filter_key

		if layout_value.begins_with("_"):
			if m_string_collections.has(layout_value):
				return "%s %s" % [ line_start, " ".join(m_string_collections[layout_value]) ]
			else:
				return "%s %s" % [ line_start, m_macros[layout_value] ]
		else:
			return "%s \"%s\"" % [ line_start, layout_value ]

	return ""

func _layout_to_filter_colour(schema_colour : String) -> String:
	var colour : Color = _parse_colour(schema_colour)

	return "%d %d %d %d" % [
		colour.r * 255,
		colour.g * 255,
		colour.b * 255,
		colour.a * 255
	]

func _layout_to_filter_name(in_name : String) -> String:
	match in_name:
		"base_type":
			return "BaseType"
		"class":
			return "Class"
		"has_mod":
			return "HasExplicitMod"
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
		"item_level":
			return "ItemLevel"
		_:
			return in_name
