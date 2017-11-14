--[[

	Autobahn

	Copyright (C) 2017 Joachim Stolberg
	LGPLv2.1+
	See LICENSE.txt for more information

	History:
	2017-11-11  v0.01  first version

]]--

local Facedir2Dir = {[0] = 
	{x=0,  y=0,  z=1},
	{x=1,  y=0,  z=0},
	{x=0,  y=0,  z=-1},
	{x=-1, y=0,  z=0},
}

-- give/take player the necessary privs/physics
local function run_privs(player, enable)
	local pos = player:getpos()
	local privs = minetest.get_player_privs(player:get_player_name())
	local physics = player:get_physics_override()
	local res = false
	if privs then
		if player:get_attribute("autobahn_active") == nil and enable then
			player:set_attribute("store_fast", minetest.serialize(privs["fast"]))
			player:set_attribute("store_speed", minetest.serialize(physics.speed))
			player:set_attribute("autobahn_active", "true")
			privs["fast"] = true
			physics.speed = 3
			minetest.sound_play("motor", {
					pos = pos,
					gain = 0.5,
					max_hear_distance = 5,
				})
			res = true
		else
			privs["fast"] = minetest.deserialize(player:get_attribute("store_fast"))
			physics.speed = minetest.deserialize(player:get_attribute("store_speed"))
			player:set_attribute("autobahn_active", nil)
		end
		player:set_physics_override(physics)
		minetest.set_player_privs(player:get_player_name(), privs)
	end
	return res
end

local function control_player(player)
	if player then
		local pos = player:getpos()
		if pos then
			--pos.y = math.floor(pos.y)
			local node = minetest.get_node(pos)
			if string.sub(node.name,1,13) == "autobahn:node" then
				minetest.after(0.5, control_player, player)
			else
				pos.y = pos.y - 1
				node = minetest.get_node(pos)
				if string.sub(node.name,1,13) == "autobahn:node" then
					minetest.after(0.5, control_player, player)
				else
					run_privs(player, false)
				end
			end
		end
	end
end	


local NodeTbl1 = {
	["autobahn:node1"] = true,
	["autobahn:node2"] = true,
	["autobahn:node3"] = true,
	["autobahn:node4"] = true,
}
local NodeTbl2 = {
	["autobahn:node11"] = true,
	["autobahn:node21"] = true,
	["autobahn:node31"] = true,
	["autobahn:node41"] = true,
}

--  1)   _o_
--       /\  [?]        ==> 1
--     [T][T][S][S][S]      T..tar
--     [S][S][S][S][S]      S..sand
--
--
--  2)   _o_
--       /\  [1][?]     ==> 2
--     [T][T][S][S][S]
--     [S][S][S][S][S]
--
--
--  3)   _o_
--       /\  [?]        ==> 1
--     [S][S][S][T][T]
--     [S][S][S][S][S]
--
--
--  4)   _o_
--       /\  [?][1]     ==> 2
--     [S][S][S][T][T]
--     [S][S][S][S][S]

local function update_node(pos)
	local node = minetest.get_node(pos)
	local nnode
	local npos
	-- check case 1
	facedir = (2 + node.param2) % 4
	npos = vector.add(pos, Facedir2Dir[facedir])
	npos.y = npos.y - 1
	nnode = minetest.get_node(npos)
	if NodeTbl1[nnode.name] then
		node.name = node.name .. "1"
		minetest.swap_node(pos, node)
		return
	end
	-- check case 2
	npos.y = npos.y + 1
	nnode = minetest.get_node(npos)
	if NodeTbl2[nnode.name] then
		node.name = string.sub(node.name,1,-1) .. "2"
		minetest.swap_node(pos, node)
		return
	end
	-- check case 3
	facedir = (0 + node.param2) % 4
	npos = vector.add(pos, Facedir2Dir[facedir])
	npos.y = npos.y - 1
	nnode = minetest.get_node(npos)
	if NodeTbl1[nnode.name] then
		node.name = node.name .. "1"
		node.param2 = 3
		minetest.swap_node(pos, node)
		return
	end
	-- check case 4
	npos.y = npos.y + 1
	nnode = minetest.get_node(npos)
	if NodeTbl2[nnode.name] then
		node.name = string.sub(node.name,1,-1) .. "2"
		node.param2 = 3
		minetest.swap_node(pos, node)
		return
	end
end		


local function register_node(name, tiles, drawtype, mesh, box, drop)
	minetest.register_node("autobahn:"..name, {
		description = "Autobahn",
		tiles = tiles,
		drawtype = drawtype,
		mesh = mesh,
		selection_box = box,
		collision_box = box,
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		sounds = default.node_sound_stone_defaults(),
		is_ground_content = false,
		groups = {cracky=2, crumbly=2, not_in_creative_inventory=(mesh==nil) and 0 or 1},
		drop = "autobahn:"..drop,

		after_place_node = function(pos, placer, itemstack, pointed_thing)
			update_node(pos)
		end,
		
		on_rightclick = function(pos, node, clicker)
			if run_privs(clicker, true) then
				minetest.after(0.5, control_player, clicker)
			end
		end,
	})
end

local sb1 = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0.5, -0.375, 0.5},
		{-0.5, -0.375, -0.25, 0.5, -0.25,  0.5},
		{-0.5, -0.25,  0,    0.5, -0.125, 0.5},
		{-0.5, -0.125, 0.25, 0.5,  0,     0.5},
	}
}
local sb2 = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5,   -0.5,  0.5, 0.125, 0.5},
		{-0.5, 0.125, -0.25, 0.5, 0.25,  0.5},
		{-0.5, 0.25,  0,    0.5, 0.375, 0.5},
		{-0.5, 0.375, 0.25, 0.5,  0.5,     0.5},
	}
}

local Nodes = {
	{name="node1", tiles={"autobahn1.png"}, drawtype="normal", mesh=nil, box=nil, drop="node1"},
	{name="node2", tiles={"autobahn2.png","autobahn1.png"}, drawtype="normal", mesh=nil, box=nil, drop="node2"},
	{name="node3", tiles={"autobahn3.png","autobahn1.png"}, drawtype="normal", mesh=nil, box=nil, drop="node3"},
	{name="node4", tiles={"autobahn2.png^[transformR180]","autobahn1.png"}, drawtype="normal", mesh=nil, box=nil, drop="node4"},
	{name="node5", tiles={"autobahn4.png^[transformR90]","autobahn1.png"}, drawtype="normal", mesh=nil, box=nil, drop="node5"},
	
	{name="node11", tiles={"autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp1.obj", box=sb1, drop="node1"},
	{name="node21", tiles={"autobahn2.png","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp1.obj", box=sb1, drop="node2"},
	{name="node31", tiles={"autobahn3.png","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp1.obj", box=sb1, drop="node3"},
	{name="node41", tiles={"autobahn2.png^[transformR180]","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp1.obj", box=sb1, drop="node4"},
	
	{name="node12", tiles={"autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp2.obj", box=sb2, drop="node1"},
	{name="node22", tiles={"autobahn2.png","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp2.obj", box=sb2, drop="node2"},
	{name="node32", tiles={"autobahn3.png","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp2.obj", box=sb2, drop="node3"},
	{name="node42", tiles={"autobahn2.png^[transformR180]","autobahn1.png"}, drawtype="mesh", mesh="autobahn_ramp2.obj", box=sb2, drop="node4"},
}

for _,item in ipairs(Nodes) do
	register_node(item.name, item.tiles, item.drawtype, item.mesh, item.box, item.drop)
end


minetest.register_craftitem("autobahn:stripes", {
	description = "Autobahn Stripe",
	inventory_image = 'autobahn_stripes.png',
})


minetest.register_craft({
	output = "autobahn:node1 4",
	recipe = {
		{"building_blocks:Tar", "building_blocks:Tar"},
		{"default:cobble", "default:cobble"},
	}
})

minetest.register_craft({
	output = "autobahn:stripes 8",
	recipe = {
		{"dye:white"},
	}
})


minetest.register_craft({
	output = "autobahn:node2",
	recipe = {
		{"", "", "autobahn:stripes"},
		{"", "autobahn:node1", ""},
	}
})

minetest.register_craft({
	output = "autobahn:node3",
	recipe = {
		{"", "autobahn:stripes", ""},
		{"", "autobahn:node1", ""},
	}
})

minetest.register_craft({
	output = "autobahn:node4",
	recipe = {
		{"autobahn:stripes", "", ""},
		{"", "autobahn:node1", ""},
	}
})

minetest.register_craft({
	output = "autobahn:node5",
	recipe = {
		{"", "", ""},
		{"autobahn:stripes", "autobahn:node1", ""},
	}
})

-- switch back to normal player privs
minetest.register_on_leaveplayer(function(player, timed_out)
	run_privs(player, false)
end)

