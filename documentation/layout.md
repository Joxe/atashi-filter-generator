# Layout File

## `strictness`

Not yet implemented, but the idea is that the config will set this so rules can react to it.
```json
{
	"strictness": 0,
}
```

## `global_label_overrides`

Overrides labels settings, mostly so you can set a specific font size or colour to every rule. Colours accept both hex notation and the classic PoE filter notation.

```json
{
	"global_label_overrides": {
		"font_size": 28,
		"border": "214 96 0 255",
		"text": "#000FF0FF",
		"background": "59 144 253 255"
	}
}
```

## `conditions`

Conditions are a cool way of toggling specific rules depending on what conditions that are set in the layout. You will most likely set these conditions from the [config file](config.md) but they are merged into the layout so you can have conditions in the layout if you want to.

```json
{
	"conditions": {
		"ssf": true
	}
}
```

This condition can then be checked in individual rules by using `any_condition` and `all_conditions`. In the following example this is used to hide Scroll of Wisdom in SSF but not in Ruthless SSF. There are neater ways of accomplishing this but this works as an example.

```json
{
	"conditions": {
		"ssf": true,
		"ruthless": true
	},
	"layout": [
		{
			"category": "Conditions Example",
			"rules": [
				{
					"exact_base_type": [
						"Scroll of Wisdom"
					],
					"any_condition": {
						"ssf": true,
						"ruthless": true
					}
				},
				{
					"hide": true,
					"exact_base_type": [
						"Scroll of Wisdom"
					],
					"all_conditions": {
						"ssf": true,
						"ruthless": false
					}
				}
			]
		}
	]
}
```

`any_condition` only needs one matching condition while `all_conditions` needs all conditions to match for the rule to be generated.

## `macros`

This feature is kinda bad as it is since I wrote it before string collections was a thing but it allows you to replace *certain values* with text in the macro. It's not very clear what *certain values* is because the code kind of ignores these. But most things right side of an equals sign can be macroed.

```json
{
	"macros": {
		"_text_i_hate_writing": "\"Stygian Vise\" \"Vermillion Ring\""
	},
	"layout": [
		{
			"category": "Conditions Example",
			"rules": [
				{
					"exact_base_type": "_text_i_hate_writing",
					"effect": "yellow"
				}
			]
		}
	]
}
```

## `string_collections`

This feature lets you define named lists of strings to be used inside your layout. This is mostly here to reduce clutter inside the layout so instead of writing every base item type you can have that assigned as `"_base_item_types"`. String collections are also set by the config so you can reuse them between different layouts. The example is the same as the macro example to show why this is a good idea to use instead of macros. The generator will make sure that the strings are properly formatted with their citation marks and listing multiple items, especially over multiple lines is much more readable.

```json
{
	"string_collections": {
		"_cool_base_types": [
			"Stygian Vise",
			"Vermillion Ring"
		]
	},
	"layout": [
		{
			"category": "Conditions Example",
			"rules": [
				{
					"exact_base_type": "_cool_base_types",
					"effect": "yellow"
				}
			]
		}
	]
}
```

## `labels`

The labels part lets you predefine labels with a name so you can refer to those rather than define each label in each rule. This both saves time when writing the layout and also opens up for recolouring all your labels easily. The example shows both the predefined label and a normal label definition.

```json
{
	"labels": {
		"tink": {
			"text": "255 0 0 255",
			"border": "255 0 0 255",
			"background": "255 255 255 255",
			"font_size": 40
		}
	},
	"layout": [
		{
			"category": "Labels Example",
			"rules": [
				{
					"exact_base_type": [
						"Divine Orb"
					],
					"label": "tink"
				},
				{
					"exact_base_type": [
						"Chaos Orb"
					],
					"label": {
						"text": "0 150 150 255",
						"border": "0 150 150 255",
					}
				}
			]
		}
	]
}
```

## `icons`

Just like labels you can have predefined icons that you can reuse in the rest of your filter.

```json
{
	"icons": {
		"big_red_star": {
			"shape": "star",
			"size": "large",
			"colour": "red"
		}
	},
	"layout": [
		{
			"category": "Icons Example",
			"rules": [
				{
					"exact_base_type": [
						"Divine Orb"
					],
					"icon": "big_red_star"
				},
				{
					"exact_base_type": [
						"Chaos Orb"
					],
					"icon": {
						"shape": "circle",
						"size": "small",
						"colour": "yellow"
					}
				}
			]
		}
	]
}
```

## `layout`

The actual layout of your filter is defined here. This is simply an array that contains a bunch of categories and each category contains rules and each rule creates a filter rule. Rules themselves are the thing you are going to write the most and they are documented in the [rules](./rules.md).

```json
{
	"layout": [
		{
			"comment": "A very insightful comment, I'm sure.",
			"category": "Example Category",
			"rules": [
				{
					"hide": true,
					"exact_class": [
						"Stackable Currency"
					]
				},
				{
					"exact_class": [
						"Maps"
					],
					"effect": "red"
				}
			]
		}
	]
}
```

This will generate a loot filter that looks like the following (I used the tool to generate this, actually):

```
# ===========================
# Example Category
# A very insightful comment, I'm sure.
# ===========================

Hide
	Class == "Stackable Currency"

Show
	Class == "Maps"
	PlayEffect Red
```

There is an expanded example below, but I suggest that you head over to the [rules documentation](./rules.md) to learn how to write these.

### Minimal Example

```json
{
	"strictness": 0,
	"global_label_overrides": {
		"font_size": 28
	},
	"conditions": {
		"ssf": true
	},
	"macros": {
		"_text_i_hate_writing": "\"Stygian Vise\" \"Vermillion Ring\""
	},
	"string_collections": {
		"_cool_base_types": [
			"Stygian Vise",
			"Vermillion Ring"
		]
	},
	"labels": {
		"tink": {
			"text": "255 0 0 255",
			"border": "255 0 0 255",
			"background": "255 255 255 255",
			"font_size": 40
		}
	},
	"icons": {
		"big_star": {
			"size": "big",
			"shape": "star",
			"colour": "red"
		}
	},
	"layout": [
		{
			"category": "Example",
			"comment": "You can write comments like this.",
			"rules": [
				{
					"conditions": {
						"ssf": true
					},
					"exact_base_type": "_cool_base_types",
					"icon": "big_star"
				},
				{
					"hide": true,
					"comment": "We can now identify at vendors.",
					"exact_base_type": [
						"Scroll of Wisdom"
					]
				},
				{
					"exact_base_type": [
						"Divine Orb"
					],
					"label": "tink"
				}
			]
		}
	]
}
```

This minimal example shows a lot of things but only really generates the following filter:

```
# ===========================
# Example
# You can write comments like this.
# ===========================

Show
	BaseType == "Stygian Vise" "Vermillion Ring"
	MinimapIcon 0 Red Star

# We can now identify at vendors.
Hide
	BaseType == "Scroll of Wisdom"

Show
	BaseType == "Divine Orb"
	SetBorderColor 255 0 0 255
	SetTextColor 255 0 0 255
	SetBackgroundColor 255 255 255 255
```