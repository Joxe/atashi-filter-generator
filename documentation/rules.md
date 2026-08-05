# Rules

The rules are the last part of the layout that we need to learn about. These are the snippets of code that actually generates the final filter code that Path of Exile uses. If you have read the rest of the documentation you have already seen a bunch of rules but here's an example:

```json
{
	"conditions": {
		"ssf": true
	},
	"exact_base_type": "_cool_base_types",
	"icon": "big_star"
}
```

Which in the right conditions become the following Path of Exile filter rule:

```
Show
	BaseType == "Stygian Vise" "Vermillion Ring"
	MinimapIcon 0 Red Star
```

Layouts normally contains many rules which make up the final filter and right now each layout rule will make exactly one filter rule (unless a condition fails on the rule which means that it's not a part of the filter).

# Conditions

Conditions check if the rule should apply or not, if the condition check fails the rule is discarded and will not be a part of the filter. This is not the same as `hide` which insteads makes an item hidden in the filter. The actual conditions are user defined so you don't have to learn a bunch of them or anything like that. There is one exception which is `"ruthless": true/false"` which is a bit magic since that will also make the program save the filter as a `.ruthlessfilter` rather than `.filter`, but I might redo that in the future since I don't really like magic values.

Conditions will be defined in either the layout or the config and then your rules can check these conditions. If you check for a condition that does not exist, you will always get `false` back so when I write conditions I tend to write them as "double negative" (not sure what you'd call it). So for example, my conditions might be named `hide_flasks` since showing them is the default, so flasks will be shown if we don't find the condition.

## `any_condition`

Checks if *any* condition is true, otherwise the rule is discarded.
```json
{
	"any_condition": [
		"ssf": false,
		"hide_flasks": true
	]
}
```

## `all_conditions`

Checks if all conditions are true, and the rule will only apply if they all are.
```json
{
	"all_conditions": [
		"ssf": false,
		"hide_flasks": true
	]
}
```

# String Checks
Creates rules that matches strings, things like checking an item's base type, class or rarity. All of these can get their values from your `string_collections` by applying a string instead of an array. All of these corresponds to a [Path of Exile filter condition](https://www.poewiki.net/wiki/Guide:Item_filter_guide#Conditions) in some way.

The documentation is a bit frontloaded in `base_type` since the other checks works in a similar way. In short, if a string check has an `exact_` in front of it the generated filter will have a `==` in it.

## `base_type` and `exact_base_type`

Corresponds to the `BaseType` PoE condition. You can either specify an exact match with `exact_base_type` or fuzzy match with `base_type`. Just like normal filters, it's very important to use `exact_base_type` correctly since the non-exact can match on a lot of items that you don't expect. Base type can also be thought of as the name of the item.

```json
{
	"base_type": [
		"Vermillion Ring",
		"Prismatic Ring"
	]
},
{
	"exact_base_type": [
		"Vermillion Ring",
		"Prismatic Ring"
	]
},
{
	"base_type": "_rings"
},
{
	"exact_base_type": "_rings"
}
```

Generates the following filter (the `rings` string collection has some placeholder values).

```
Show
	BaseType "Vermillion Ring" "Prismatic Ring"

Show
	BaseType == "Vermillion Ring" "Prismatic Ring"

Show
	BaseType "Cerulean Ring" "Two-Stone Ring"

Show
	BaseType == "Cerulean Ring" "Two-Stone Ring"
```

## `class` and` exact_class`

Corresponds to the `Class` PoE condition. Just like other string checks it accepts both an array or a string collection name. Item classes can be found on the [PoE Wiki](https://www.poewiki.net/wiki/Item_class#Item_classes) but they generally add a few new ones every content patch.

```json
{
	"class": [
		"Fossils"
	]
},
{
	"exact_class": [
		"Stackable Currency"
	]
}
```
```
Show
	Class "Fossils"

Show
	Class == "Stackable Currency"
```

## `has_mod`

Corresponds to `HasExplicitMod` PoE condition. Allows you to create filters that perform explicit mod checking. Explicit mod checking does not have an exact variant since the PoE filters does not have it.

```json
{
	"has_mod": [
		"Tyrannical"
	]
}
```
```
Show
	HasExplicitMod "Tyrannical"
```

## `rarity`

Corresponds to `Rarity` PoE condition, but does not implement the operator at all as there are only 4 rarities and it would introduce a bunch of complexity to add it. The strings here are converted to PascalCase so they are technically case insensitive.

```json
{
	"rarity": [
		"normal",
		"magic",
		"rare",
		"unique"
	]
}
```
```
Show
	Rarity Normal Magic Rare Unique
```

## `socket_group`

Corresponds to the `SocketGroup` PoE condition and lets you create filter rules that check the socket colours of an item.
__Warning__: This is rather untested since I only use this for checking for RGB items, make sure this work with more complex setups.

```json
{
	"socket_group": "RGB"
}
```
```
Show
	SocketGroup "RGB"
```

## `influence`

Corresponds to the `HasInfluence` PoE condition and lets you create filter rules that check an item's influence.

```json
{
	"influence": [
		"Crusader",
		"Hunter",
		"Redeemer",
		"Warlord",
		"Shaper",
		"Elder"
	]
}
```
```
Show
	HasInfluence "Crusader" "Hunter" "Redeemer" "Warlord" "Shaper" "Elder"
```

# Boolean Checks

The boolean checks are much simpler and they all work the same way. So `"corrupted": true` will simply turn into `Corrupted True`, replace corrupted with the boolean check of your choice.

## `corrupted`

Corresponds to the `Corrupted` PoE condition.

## `synthesised`

Corresponds to the `SynthesisedItem` PoE condition.

## `identified`

Corresponds to the `Identified` PoE condition.

## `fractured`

Corresponds to the `FracturedItem` PoE condition.

## `transfigured`

Corresponds to the `TransfiguredGem` PoE condition and will therefore only really apply to gems.

# Integer Checks

The integer checks have two input methods, you can either write something like `"map_tier": 3` to generate `MapTier == 3` or instead of the integer you can give it `"map_tier": ">= 4"` and the generated filter will become `MapTier >= 4`. When using the string variant it's more or less up to you to write it correctly, no checking is done to figure out if it's a valid operand or something like that.

## `memory_strands`

Corresponds to the `MemoryStrands` PoE condition.

## `map_tier`

Corresponds to the `MapTier` PoE condition.

## `sockets`

Corresponds to the `Sockets` PoE condition.

## `linked_sockets`

Corresponds to the `LinkedSockets` PoE condition.

## `delirium_cluster_size`

Corresponds to the `EnchantmentPassiveNum` PoE condition.

## `stack_size`

Corresponds to the `StackSize` PoE condition.

## `area_level`

Corresponds to the `AreaLevel` PoE condition.

## `gem_level`

Corresponds to the `GemLevel` PoE condition.

## `quality`

Corresponds to the `Quality` PoE condition.

## `item_level`

Corresponds to the `ItemLevel` PoE condition.

# Visual Rules

Visual rules are not conditions for making an item show or not but they all modify the way an item looks in the game once it drops. One could argue that these should not be in rules and there should instead be something else, but since PoE does the same thing I felt like there was a precedent set (and it made it easier to implement).

All of these are optional and if all are left out the label and icon will just look like what PoE normally does.

## `hide`

Specify if the rule should become a `Show` or `Hide` in the filter, if omitted `Show` is the default. Normally you would only see this as `"hide": true` since writing `"hide": false` is the same as not writing it at all, but it might come in handy if you want to do groups.
```json
{
	"hide": true,
	"exact_base_type": [
		"Scroll of Wisdom"
	]
},
{
	"exact_base_type": [
		"Small Life Flask"
	]
}
```
```
Hide
	BaseType == "Scroll of Wisdom"

Show
	BaseType == "Small Life Flask"
```

## `label`

Modify the label to make items stand out from the rest. The label contains four options which can be seen in the example. `text`, `border`, `background` are all colours and accept both 24-bit hex values (#FFFFFFFF) and the normal PoE filter notation (255 255 255 255). `font_size` controls the size of the text and PoE accepts values between 18-45 with the default being 32. An omitted member of the label will just default that member to the PoE default colour.

```json
{
	"label": {
		"text": "255 0 0 255",
		"border": "255 0 0 255",
		"background": "255 255 255 255",
		"font_size": 40
	}
}
```
```
Show
	SetBorderColor 255 0 0 255
	SetTextColor 255 0 0 255
	SetBackgroundColor 255 255 255 255
	SetFontSize 40
```

## `icon`

Modify the auto-map icon with this. The icon options match 1:1 with PoE MinimapIcon but instead of doing 0, 1 and 2 for size it's `big`, `medium` and `small` respectively. Each string are turned into PascalCase before they go into the filter and there is no error checking that you actually supplied a valid icon (PoE does that for us). You can use lower case for all *but* the `UpsideDownHouse` since it contains multiple words.

```json
{
	"size": "big",
	"shape": "star",
	"colour": "red"
}
```
```
Show
	MinimapIcon 0 Red Star
```

## `effect`

Corresponds to `PlayEffect` in a PoE filter and simply selects which colour the item beam should have in game.

```json
{
	"effect": "red"
}
```
```
Show
	PlayEffect Red
```

# Miscellaneous (I actually did spell this right on the first try)
## `group`

`group` is a very complex way of writing rules so you can reuse code and make the filter shorter and faster to write. You can simply ignore it if you don't want to use it, that is fine.

`group` can be used to make a very brief inheritance concept possible within rules, for example you can have all flasks looking the same but still have them being hidden as you level up or group up various different rules into a group of rules that you want to look the same (or the other way around). Exactly what you can do with grouping is up to you, but we can take a look at an example from my layout and walk through it.

```json
{
	"group": [
		{
			"exact_base_type": "_awakened_gems"
		},
		{
			"exact_base_type": "_giga_support_gems"
		},
		{
			"exact_base_type": [
				"Empower Support",
				"Enlighten Support",
				"Enhance Support"
			]
		},
		{
			"gem_level": 21
		},
		{
			"quality": "> 0"
		},
		{
			"transfigured": true
		}
	],
	"exact_class": [
		"Skill Gems",
		"Support Gems"
	],
	"label": "valuable_gem"
}
```

What this set of rules does it gather all things that I deem is a valuable gem and applies the same label to all of them. Each entry in a group will become its own entry in the generated filter and each group rule will get the shared rules applied to them as well. In this case we can take a look at the output of the level 21 gems rule.

```
Show
	Class == "Skill Gems" "Support Gems"
	GemLevel == 21
	SetBorderColor 0 180 0 255
	SetTextColor 0 180 0 255
	SetFontSize 28
```

The `Class` and all the label settings are from the shared rule, and the `GemLevel == 21` is from the group entry. They are simply combined with the contents of the `group` overwriting the shared rules. The other entries of the group are of course also there so just below the level 21 gem rule we find the following:

```
Show
	Class == "Skill Gems" "Support Gems"
	Quality > 0
	SetBorderColor 0 180 0 255
	SetTextColor 0 180 0 255
	SetFontSize 28
```

And so on for the others in the group. Elements in a group are added __in the order they are written__ which means that if you have one group entry hiding a later group entry that will work. So make sure you write things in the order you want them to end up in the filter. Working with groups is a faster way of writing the layout than simply doing all the rules one-by-one but it does increase the complexity, take a look at my example layout if you want ideas, I use `group` in a few different ways.

Please note that groups *can not* be nested.

## `comment`

Each rule can have a comment and it will show up in front of the corresponding rule in the filter. Long comments are automatically kept within a specific character amount, split on words.

```json
{
	"comment": "Mhm, an orb",
	"exact_base_type": [
		"Divine Orb"
	]
}
```
```
# Mhm, an orb
Show
	BaseType == "Divine Orb"
```