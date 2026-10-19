-- Reuse game models for UI portraits; no separate art catalog to keep in sync.
local Factory = require(script.Parent.CreatureFactory)
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local Catalog = {}
function Catalog.Build()
	local storage = game:GetService("ReplicatedStorage")
	local old = storage:FindFirstChild("HACCreaturePreviews")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "HACCreaturePreviews"
	for _, species in ipairs(C.OrderedIds(C.Species)) do
		local variants = { "Normal" }
		for _, id in ipairs(C.OrderedIds(C.Mutations)) do
			table.insert(variants, id)
		end
		for _, variant in ipairs(variants) do
			local item = {
				id = "preview",
				species = species,
				rarity = C.Species[species].Rarity,
				size = 1,
				mutations = variant == "Normal" and {} or { variant },
			}
			local model = Factory.Build(folder, Vector3.zero, item, true)
			model.Name = C.VariantKey(item)
		end
	end
	folder.Parent = storage
	return folder
end
return Catalog
