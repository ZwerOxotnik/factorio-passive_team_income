---@class PTI : module
local M = {}


--#region Constants
local call = remote.call
--#endregion


--#region Settings
local update_tick = settings.global["PTI_update_tick"].value
local income = settings.global["PTI_income"].value
local is_for_online_teams = settings.global["PTI_is_for_online_teams"].value
--#endregion


--#region Functions of events

local function add_money()
	if is_for_online_teams then
		for _, force in pairs(game.forces) do
			if #force.connected_players > 0 then
				local force_index = force.index
				local money = call("EasyAPI", "get_force_money", force_index)
				if money then
					call("EasyAPI", "set_force_money_by_index", force_index, money + income)
				end
			end
		end
	else
		for force_index, money in pairs(call("EasyAPI", "get_forces_money")) do
			call("EasyAPI", "set_force_money_by_index", force_index, money + income)
		end
	end
end

local mod_settings = {
	["PTI_is_for_online_teams"] = function(value) is_for_online_teams = value end,
	["PTI_income"] = function(value) income = value end,
	["PTI_update_tick"] = function(value)
		script.on_nth_tick(update_tick, nil)
		M.on_nth_tick[update_tick] = nil
		update_tick = value
		if update_tick > 0 then
			M.on_nth_tick[value] = add_money
			script.on_nth_tick(value, add_money)
		end
	end
}
local function on_runtime_mod_setting_changed(event)
	local f = mod_settings[event.setting]
	if f then f(settings.global[event.setting].value) end
end

--#endregion


--#region Pre-game stage

local function add_remote_interface()
	-- https://lua-api.factorio.com/latest/LuaRemote.html
	remote.remove_interface("passive_team_income") -- For safety
	remote.add_interface("passive_team_income", {})
end

M.add_remote_interface = add_remote_interface

--#endregion


M.events = {
	[defines.events.on_runtime_mod_setting_changed] = on_runtime_mod_setting_changed
}

M.on_nth_tick = {}
if update_tick > 0 then
	M.on_nth_tick[update_tick] = add_money
end

return M
