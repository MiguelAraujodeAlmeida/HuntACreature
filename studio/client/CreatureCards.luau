-- One visual language for discovery, ownership and selling; no gameplay mutations.
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local Portrait = require(script.Parent.CreaturePortrait)
local Cards = {}
function Cards.Tile(parent, item, known, selected, key, callback, badge)
	local tint = known and Kit.Theme.Creature(item) or Color3.fromRGB(74, 91, 111)
	local tile = Kit.Surface(parent, "Creature_" .. key, UDim2.new(), UDim2.new(), tint:Lerp(Kit.Theme.Ink, 0.32))
	Kit.Label(tile, "Name", known and C.Name(item) or "???", UDim2.new(1, -12, 0, 32), UDim2.fromOffset(6, 5), 19)
	local portrait = Portrait.new(tile, item, known, UDim2.new(1, -10, 0, 120), UDim2.fromOffset(5, 29))
	if item.favorite then
		Kit.Label(tile, "Favorite", "★", UDim2.fromOffset(30, 30), UDim2.new(1, -34, 0, 32), 24, W.Style.UI.Gold)
	end
	Kit.Badge(
		tile,
		"Status",
		badge or (known and C.RarityNames[item.rarity] or "Undiscovered"),
		UDim2.new(1, -16, 0, 28),
		UDim2.new(0, 8, 1, -36),
		known and W.Style.UI.White or Kit.Theme.Muted
	)
	Kit.Selectable(tile, key, selected, callback, portrait)
	return tile
end
function Cards.Detail(parent, item, known, options)
	options = options or {}
	local tint = known and Kit.Theme.Creature(item) or Kit.Theme.Muted
	local panel = Kit.Surface(
		parent,
		"CreatureDetails",
		UDim2.new(1, -2, 0, options.index and 438 or 354),
		UDim2.new(),
		Kit.Theme.Body
	)
	local stage = Kit.Surface(
		panel,
		"PortraitStage",
		UDim2.new(1, -16, 0, 204),
		UDim2.fromOffset(8, 8),
		tint:Lerp(Kit.Theme.Ink, 0.58)
	)
	Portrait.new(stage, item, known, UDim2.new(1, -12, 1, -30), UDim2.fromOffset(6, 16))
	Kit.Badge(
		stage,
		"Rarity",
		known and (C.RarityNames[item.rarity] or "Common") or "UNDISCOVERED",
		UDim2.new(1, -24, 0, 26),
		UDim2.new(0, 12, 1, -34),
		tint
	)
	local name = Kit.Label(
		panel,
		"Name",
		known and C.Name(item) or "???",
		UDim2.new(1, -20, 0, 40),
		UDim2.fromOffset(10, 214),
		28
	)
	name.TextScaled = true
	local cap = Instance.new("UITextSizeConstraint")
	cap.MinTextSize, cap.MaxTextSize, cap.Parent = 16, 28, name
	Kit.Stat(panel, "Income", W.Style.Icons.Coin, known and C.Value(item, "Income") .. "/s" or "?", 0, 258)
	Kit.Stat(panel, "XP", W.Style.Icons.XP, known and C.Value(item, "XP") .. "/s" or "?", 0.5, 258)
	local status = options.status or ""
	Kit.Label(
		panel,
		"Status",
		status,
		UDim2.new(1, -24, 0, 30),
		UDim2.fromOffset(12, 314),
		16,
		options.statusColor or Kit.Theme.Muted
	)
	if options.index then
		Kit.Stat(
			panel,
			"Strength",
			W.Style.Icons.Strength,
			known and tostring(C.MinimumStrength(item.species)) .. " required" or "?",
			0,
			350,
			1
		)
		Kit.Label(
			panel,
			"Description",
			known and C.Species[item.species].Description or "A new discovery awaits.",
			UDim2.new(1, -24, 0, 32),
			UDim2.fromOffset(12, 401),
			13,
			Kit.Theme.Muted
		)
	end
	return panel
end
return Cards
