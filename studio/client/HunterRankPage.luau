local Rank = require(game.ReplicatedStorage.HACShared.HunterProgression)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local Page = {}

local function number(value)
	local text = tostring(math.floor(value))
	return text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function Page.Render(ui)
	ui.pageTitle = "Hunter Rank"
	local xp = ui.data.profile.xp
	local level = Rank.Level(xp)
	local nextXP = Rank.Thresholds[level + 1]
	local hero = Kit.Surface(ui.scroll, "RankProgress", UDim2.new(1, -2, 0, 170), UDim2.new(), Kit.Theme.Body)
	hero.LayoutOrder = 1
	Kit.Label(hero, "Rank", "RANK " .. level .. " / " .. #Rank.Thresholds,
		UDim2.new(1, -24, 0, 40), UDim2.fromOffset(12, 10), 30, W.Style.UI.Purple)
	local progress = Kit.Label(hero, "Progress", "", UDim2.new(1, -24, 0, 32),
		UDim2.fromOffset(12, 52), 18, Kit.Theme.White, Enum.TextXAlignment.Left)
	local track, fill = W.bar(hero, "XPProgress", UDim2.new(1, -24, 0, 20),
		UDim2.fromOffset(12, 96), W.Style.UI.Purple)
	track.ZIndex = hero.ZIndex + 2
	local function refresh()
		local current = ui.data.profile.xp
		progress.Text = nextXP and (number(current) .. " / " .. number(nextXP) .. " XP")
			or (number(current) .. " XP · MAX RANK")
		fill.Size = UDim2.fromScale(nextXP and math.clamp(
			(current - Rank.Thresholds[level]) / (nextXP - Rank.Thresholds[level]), 0, 1) or 1, 1)
	end
	table.insert(ui.valueRefreshers, refresh)
	refresh()
	Kit.Label(hero, "Bonus", string.format("+%d%% gold  ·  +%d%% training strength",
		(level - 1) * Rank.GoldBonusPerRank * 100,
		(level - 1) * Rank.TrainingBonusPerRank * 100),
		UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 126), 17, Kit.Theme.Muted,
		Enum.TextXAlignment.Left)

	local sources = Kit.Surface(ui.scroll, "Sources", UDim2.new(1, -2, 0, 104), UDim2.new(), Kit.Theme.Surface)
	sources.LayoutOrder = 2
	Kit.Label(sources, "Title", "HUNT TO GROW", UDim2.new(1, -24, 0, 35),
		UDim2.fromOffset(12, 6), 22)
	Kit.Label(sources, "Hint", "Capture creatures and discover species or variants. Active base creatures add a little XP every 10 seconds.",
		UDim2.new(1, -24, 0, 56), UDim2.fromOffset(12, 39), 16, Kit.Theme.Muted,
		Enum.TextXAlignment.Left)

	local milestones = Kit.Surface(ui.scroll, "Milestones", UDim2.new(1, -2, 0, 376), UDim2.new(), Kit.Theme.Body)
	milestones.LayoutOrder = 3
	Kit.Label(milestones, "Title", "TEN RANKS · OPEN-ENDED GEAR", UDim2.new(1, -24, 0, 32),
		UDim2.fromOffset(12, 6), 20)
	for i, threshold in ipairs(Rank.Thresholds) do
		local label = i == 1 and "START" or number(threshold) .. " XP"
		Kit.Label(milestones, "Rank" .. i,
			string.format("%02d   %s", i, label), UDim2.new(1, -24, 0, 30),
			UDim2.fromOffset(12, 36 + (i - 1) * 33), 17,
			i <= level and W.Style.UI.Purple or Kit.Theme.Muted, Enum.TextXAlignment.Left)
	end
	local back = Kit.Action(ui.scroll, "BackToIndex", "Back to Index", function()
		ui:Open("Index")
	end, UDim2.new(1, -2, 0, 46))
	back.Root.LayoutOrder = 4
end

return Page
