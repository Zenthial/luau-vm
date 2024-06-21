local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local M = {}

function M.get_ignored()
	local ignored = CollectionService:GetTagged("ignore")
	table.insert(ignored, player.Character)
	return ignored
end

function M.add(thing: any)
	CollectionService:AddTag(thing, "ignore")
end

function M.remove(thing: any)
	CollectionService:AddTag(thing, "ignore")
end

function M.raycast_params()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = M.get_ignored()

	return params
end

return M
