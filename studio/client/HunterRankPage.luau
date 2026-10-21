-- Hunter Rank é uma licença em andamento: mostrar só o marco atual e a próxima recompensa real.
local Rank = require(game.ReplicatedStorage.HACShared.HunterProgression)
local C = require(game.ReplicatedStorage.HACShared.GameplayConfig)
local W = require(script.Parent.HUDWidgets)
local Kit = require(script.Parent.MenuKit)
local ToolArt = require(script.Parent.ToolPortrait)
local Page = {}

local function perk(parent, name, icon, value, caption, position, size)
	local card = Kit.Surface(parent, name, size, position, Kit.Theme.Ink)
	local art = W.icon(card, "Icon", icon, UDim2.fromOffset(38, 38), UDim2.fromOffset(5, 5))
	art.ZIndex = card.ZIndex + 2
	Kit.Label(card, "Value", value, UDim2.new(1, -48, 0, 26), UDim2.fromOffset(43, 2),
		21, Kit.Theme.White, Enum.TextXAlignment.Left)
	Kit.Label(card, "Caption", caption, UDim2.new(1, -48, 0, 19), UDim2.fromOffset(43, 27),
		13, Kit.Theme.Muted, Enum.TextXAlignment.Left)
	return card
end

function Page.Render(ui)
	ui.pageTitle = "Hunter Rank"
	local xp = ui.data.profile.xp
	local level, nextLevel = Rank.Progress(xp)
	local compact = ui.contentWidth < 430

	local hero = Kit.Surface(ui.scroll, "HunterLicense", UDim2.new(1, -2, 0, compact and 182 or 190),
		UDim2.new(), Kit.Theme.Body)
	hero.LayoutOrder = 1
	local iconSize = compact and 70 or 112
	local crest = W.icon(hero, "Crest", W.Style.Icons.HunterRank,
		UDim2.fromOffset(iconSize, iconSize), UDim2.fromOffset(12, 13))
	crest.ZIndex = hero.ZIndex + 2
	local left = iconSize + 22
	Kit.Label(hero, "Current", "HUNTER RANK", UDim2.new(1, -left - 12, 0, 24),
		UDim2.fromOffset(left, 15), 16, W.Style.UI.Purple, Enum.TextXAlignment.Left)
	Kit.Label(hero, "Level", tostring(level), UDim2.new(1, -left - 12, 0, compact and 57 or 74),
		UDim2.fromOffset(left, 35), compact and 50 or 66, Kit.Theme.White, Enum.TextXAlignment.Left)
	Kit.Label(hero, "CurrentBonus", string.format("+%d%% gold  ·  +%d%% training",
		(level - 1) * Rank.GoldBonusPerRank * 100,
		(level - 1) * Rank.TrainingBonusPerRank * 100),
		UDim2.new(1, -24, 0, 23), UDim2.fromOffset(12, compact and 103 or 112),
		compact and 13 or 16, Kit.Theme.Muted, Enum.TextXAlignment.Left)
	local progressText = Kit.Label(hero, "ProgressText", "", UDim2.new(1, -24, 0, 23),
		UDim2.fromOffset(12, compact and 126 or 137), compact and 15 or 17,
		Kit.Theme.White, Enum.TextXAlignment.Left)
	local track, fill = W.bar(hero, "Progress", UDim2.new(1, -24, 0, 17),
		UDim2.fromOffset(12, compact and 151 or 164), W.Style.UI.Purple)
	track.ZIndex = hero.ZIndex + 2
	local function refresh()
		local currentLevel, following, alpha = Rank.Progress(ui.data.profile.xp)
		progressText.Text = following and string.format("%d%% TO RANK %d", math.floor(alpha * 100), following)
			or ("RANK " .. currentLevel .. " · JOURNEY CONTINUES")
		fill.Size = UDim2.fromScale(alpha, 1)
	end
	table.insert(ui.valueRefreshers, refresh)
	refresh()

	if nextLevel then
		local rewards = Kit.Surface(ui.scroll, "NextRewards", UDim2.new(1, -2, 0, compact and 226 or 137),
			UDim2.new(), Kit.Theme.Surface)
		rewards.LayoutOrder = 2
		Kit.Label(rewards, "Title", "NEXT · RANK " .. nextLevel,
			UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 5), compact and 23 or 26,
			Kit.Theme.White, Enum.TextXAlignment.Left)
		local bonus = {
			{ "Gold", W.Style.Icons.Coin, "+5%", "Base gold" },
			{ "Training", W.Style.Icons.Strength, "+3%", "Training gain" },
			{ "Research", W.Style.Icons.XP, "+1", "Research / 10s" },
		}
		for i, item in ipairs(bonus) do
			perk(rewards, item[1], item[2], item[3], item[4],
				compact and UDim2.fromOffset(10, 39 + (i - 1) * 60)
					or UDim2.new((i - 1) / 3, 8, 0, 50),
				compact and UDim2.new(1, -20, 0, 52) or UDim2.new(1 / 3, -14, 0, 65))
		end

		local gear = Rank.GearAt(nextLevel)
		if #gear > 0 then
			local gearPanel = Kit.Surface(ui.scroll, "GearUnlocks", UDim2.new(1, -2, 0, 174),
				UDim2.new(), Kit.Theme.Body)
			gearPanel.LayoutOrder = 3
			Kit.Label(gearPanel, "Title", "GEAR AT RANK " .. nextLevel,
				UDim2.new(1, -24, 0, 35), UDim2.fromOffset(12, 4), 22,
				Kit.Theme.White, Enum.TextXAlignment.Left)
			local count = math.min(#gear, compact and 2 or 3)
			for i = 1, count do
				local id = gear[i]
				local card = Kit.Surface(gearPanel, id, UDim2.new(1 / count, -12, 0, 122),
					UDim2.new((i - 1) / count, 8, 0, 40), Kit.Theme.Ink)
				ToolArt.new(card, id, UDim2.new(1, -8, 1, -35), UDim2.fromOffset(4, 2), true)
				Kit.Label(card, "Name", C.Items[id].Name, UDim2.new(1, -8, 0, 29),
					UDim2.new(0, 4, 1, -31), 15)
			end
		end
	end

	local missions = Kit.Surface(ui.scroll, "Missions", UDim2.new(1, -2, 0, 78),
		UDim2.new(), Kit.Theme.Body)
	missions.LayoutOrder = 4
	Kit.Label(missions, "Title", "HUNTER MISSIONS", UDim2.new(1, -24, 0, 37),
		UDim2.fromOffset(12, 5), 22, Kit.Theme.White, Enum.TextXAlignment.Left)
	Kit.Label(missions, "State", "COMING SOON", UDim2.new(1, -24, 0, 25),
		UDim2.fromOffset(12, 43), 15, W.Style.UI.Purple, Enum.TextXAlignment.Left)
end

return Page
