for _, radar in next, _G.data.raw.radar do
	if type(radar.max_distance_of_sector_revealed) == "number" and radar.max_distance_of_sector_revealed > 0 then
		local range = {
			type = "item-with-tags",
			name = "zzz radar-reporter [" .. radar.name .. "]",
			order = tostring(radar.max_distance_of_sector_revealed),
			stack_size = 1,
			flags = {"goes-to-quickbar", "hidden"},
			icon = "__base__/graphics/icons/wooden-chest.png",
			icon_size = 32,
		}
		_G.data:extend({range})
	end
end
