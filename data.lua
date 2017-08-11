
-- data.radar.max_distance_of_sector_revealed = 14
-- 7x7 chunks, 224x224 tiles

do
	local data = _G.data
	data:extend({{
		type = "virtual-signal",
		name = "signal-radar-reporter-friendlies",
		icon = "__folk-radar__/graphics/signals/radar-reporter-signal-friend.png",
		subgroup = "virtual-signal-number",
		order = "radar-friendlies"
	}, {
		type = "virtual-signal",
		name = "signal-radar-reporter-enemies",
		icon = "__folk-radar__/graphics/signals/radar-reporter-signal-enemy.png",
		subgroup = "virtual-signal-number",
		order = "radar-enemies"
	}})

	local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
	entity.name = "radar-reporter"
	entity.minable.result = "radar-reporter"
	entity.icon = "__folk-radar__/graphics/icons/radar-reporter.png"
	entity.sprites = {
		north = {
			filename = "__folk-radar__/graphics/entities/radar-reporter-entities.png",
			x = 166,
			y = 3,
			width = 62,
			height = 54, -- 50
			frame_count = 1,
			shift = { 0.140625, 0.140625 },
		},
		east = {
			filename = "__folk-radar__/graphics/entities/radar-reporter-entities.png",
			x = 14, -- 10
			y = 3,
			width = 54,
			height = 54,
			frame_count = 1,
			shift = { 0.140625, 0.140625 },
		},
		south = {
			filename = "__folk-radar__/graphics/entities/radar-reporter-entities.png",
			x = 236,
			y = 6,
			width = 82, -- 66/76
			height = 44,
			frame_count = 1,
			shift = { 0.140625, 0.140625 },
		},
		west = {
			filename = "__folk-radar__/graphics/entities/radar-reporter-entities.png",
			x = 94,
			y = 0,
			width = 54,
			height = 58, -- 48/54
			frame_count = 1,
			shift = { 0.140625, 0.140625 },
		}
	}

	local item = table.deepcopy(data.raw.item["constant-combinator"])
	item.name = "radar-reporter"
	item.icon = "__folk-radar__/graphics/icons/radar-reporter.png"
	item.place_result = "radar-reporter"
	item.order = "b[combinators]-c[radar-reporter]"

	local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
	recipe.name = "radar-reporter"
	recipe.ingredients = {
		{ "advanced-circuit",       4 },
		{ "arithmetic-combinator",  2  },
		{ "night-vision-equipment", 1  },
	}
	recipe.result = "radar-reporter"

	local tech = {
		type = "technology",
		name = "radar-reporter",
		icon = "__folk-radar__/graphics/technology/radar-reporter-tech.png",
		prerequisites = { "night-vision-equipment", "advanced-electronics", "military", "optics", "circuit-network" },
		effects = { {
			type = "unlock-recipe",
			recipe = "radar-reporter"
		} },
		unit = {
			count = 125,
			ingredients = {
				{"science-pack-1", 1},
				{"science-pack-2", 1},
				{"science-pack-3", 1}
			},
			time = 30
		},
		icon_size = 128,
		order = "a-h-b"
	}

	data:extend({entity, item, recipe, tech})

	-- data:extend{
	-- 	{
	-- 		type = "item",
	-- 		name = "reporting-radar",
	-- 		icon = "__base__/graphics/icons/radar.png",
	-- 		flags = {"goes-to-quickbar"},
	-- 		subgroup = "defensive-structure",
	-- 		order = "d[radar]-b[radar]",
	-- 		place_result="reporting-radar",
	-- 		stack_size = 50,
	-- 	},
	-- 	{
	-- 		type = "recipe",
	-- 		name = "reporting-radar",
	-- 		enabled = "true",
	-- 		ingredients = {
	-- 			{"radar", 1},
	-- 			{"advanced-circuit", 10},
	-- 			{"arithmetic-combinator", 2},
	-- 			{"night-vision-equipment", 1},
	-- 		},
	-- 		result="reporting-radar",
	-- 	},
	-- }
end
