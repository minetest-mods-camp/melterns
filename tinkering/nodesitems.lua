
-- Common nodebox
tinkering.bench = {
	type = "fixed",
	fixed = {
		{-0.5000, 0.3125, -0.5000, 0.5000, 0.5000, 0.5000},
		{-0.5000, -0.5000, -0.5000, -0.3125, 0.3125, -0.3125},
		{0.3125, -0.5000, -0.5000, 0.5000, 0.3125, -0.3125},
		{-0.5000, -0.5000, 0.3125, -0.3125, 0.3125, 0.5000},
		{0.3125, -0.5000, 0.3125, 0.5000, 0.3125, 0.5000}
	}
}

-- Tool Station
dofile(tinkering.modpath.."/nodes/tool_station.lua")

-- Part Builder
dofile(tinkering.modpath.."/nodes/part_builder.lua")
