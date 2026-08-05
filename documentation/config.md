# Config File

The config file contains both an overall configuration for all your filters as well as the filters you want to create. The very minimal config would look like the following:
```json
{
	"filters": [
		{
			"name": "My Filter"
		}
	],
	"global_config": {
		"layout": "./filter_layout.json"
	}
}
```
This would create one filter named `My Filter.filter` using the layout `filter_layout.json`. But the you can easily expand the configuration to create multiple filters with different configurations. A very common would probably be to re-use the same layout to create both a trade and SSF filter. You can achieve this to add another filter and add a filter-specific config to one of them.
```json
{
	"filters": [
		{
			"name": "My Filter"
		},
		{
			"name": "My SSF Filter",
			"config": {
				"conditions": {
					"ssf": true
				}
			}
		}
	],
	"global_config": {
		"layout": "./filter_layout.json"
	}
}
```
Now two filters are created, `My Filter.filter` and `My SSF Filter.filter`, with the latter that has the condition "ssf" set to true. Your layout can then toggle specific rules based on that condition, the details will be in the [layout documentation](layout.md). Conditions can also be set in your global config, which I personally use to toggle specific patch content.
```json
{
	"filters": [
		{
			"name": "My Filter"
		},
		{
			"name": "My SSF Filter",
			"config": {
				"conditions": {
					"ssf": true
				}
			}
		}
	],
	"global_config": {
		"conditions": {
			"patch_3.29": true
		},
		"layout": "./filter_layout.json"
	}
}
```

A layout usually has a `string_collections` so we can insert big lists of strings into the filter without necessarily cluttering the layout, this `string_collections` can be set on both a global and per-filter level.
```json
{
	"filters": [
		{
			"name": "My Filter"
		},
		{
			"name": "My SSF Filter",
			"config": {
				"conditions": {
					"ssf": true
				}
			}
		}
	],
	"global_config": {
		"conditions": {
			"patch_3.29": true
		},
		"string_collections": "./string_collections.json",
		"layout": "./filter_layout.json"
	}
}
```
And the `string_collections` itself is a very simple file that will look something like this:
```json
{
	"_all_item_classes": [
		"Body Armours",
		"Boots",
		"Bows",
		"..."
	],
	"_all_jewels": [
		"Cobalt Jewel",
		"Crimson Jewel",
		"Viridian Jewel",
		"..."
	]
}
```
Each element key needs to start with an underscore to work with the generator, but string collections help you keep your layouts a bit cleaner. I personally use them to sort item by tiers so you could also have different string tables if you want different tiering for different filters.

If you are a freak like me and don't want different sizes on the labels in game there is also a `global_label_overrides` member that lets you override whatever the label settings are.
```json
{
	"filters": [
		{
			"name": "My Filter"
		},
		{
			"name": "My SSF Filter",
			"config": {
				"conditions": {
					"ssf": true
				}
			}
		}
	],
	"global_config": {
		"conditions": {
			"patch_3.29": true
		},
		"global_label_overrides": {
			"font_size": 28
		},
		"string_collections": "./string_collections.json",
		"layout": "./filter_layout.json"
	}
}
```
It does support the other label settings like `background`, `border` and `text` if you want a uniform colour, but I feel like that is unlikely.
