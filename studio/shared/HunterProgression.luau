-- Curva prototipável: XP total acumulado, sem rebirth nem bloqueio de ilhas.
local Rank = {}
local C = require(script.Parent.GameplayConfig)
Rank.Thresholds = { 0, 100, 700, 5000, 40000, 400000, 5000000, 80000000, 1500000000, 30000000000 }
Rank.GoldBonusPerRank = 0.05
Rank.TrainingBonusPerRank = 0.03
Rank.PassiveSeconds = 10
Rank.PassiveXPPerCreature = 1 -- Fallback de catálogo, não taxa universal.
Rank.PassiveXPPerRank = 1 -- Bônus global, apenas quando há criatura ativa na base.
Rank.CaptureXP = 25
Rank.FirstSpeciesXP = 75
Rank.FirstVariantXP = 35

function Rank.Level(xp)
	local level = 1
	for index = 2, #Rank.Thresholds do
		if xp < Rank.Thresholds[index] then
			break
		end
		level = index
	end
	return level
end

function Rank.Progress(xp)
	local level = Rank.Level(xp)
	local start = Rank.Thresholds[level]
	local finish = Rank.Thresholds[level + 1]
	return level, finish and level + 1 or nil,
		finish and math.clamp((xp - start) / (finish - start), 0, 1) or 1,
		finish and math.max(0, finish - xp) or nil
end

function Rank.GearAt(level)
	local result = {}
	for _, id in ipairs(C.ShopIds()) do
		if C.Items[id].RequiredHunterRank == level then
			table.insert(result, id)
		end
	end
	return result
end

function Rank.GoldMultiplier(xp)
	return 1 + (Rank.Level(xp) - 1) * Rank.GoldBonusPerRank
end

function Rank.CreditGold(profile, baseAmount)
	local payment = baseAmount * Rank.GoldMultiplier(profile.xp) + profile.goldCarry
	local whole = math.floor(payment + 1e-9)
	profile.gold += whole
	profile.goldCarry = math.max(0, payment - whole)
	return whole
end

function Rank.TrainingMultiplier(xp)
	return 1 + (Rank.Level(xp) - 1) * Rank.TrainingBonusPerRank
end

function Rank.CaptureReward(creature, firstSpecies, firstVariant)
	local species = C.Species[creature.species]
	local gold = table.find(creature.mutations or {}, "Dourado") ~= nil
	local sizeBonus = 1 + (math.clamp(creature.size or 1, 1, C.Size.Maximum) - 1) * 0.15
	local base = math.floor((species.CaptureXP or Rank.CaptureXP) * sizeBonus * (gold and 1.5 or 1) + 0.5)
	return base
		+ (firstSpecies and (species.FirstSpeciesXP or Rank.FirstSpeciesXP) or 0)
		+ (firstVariant and not firstSpecies and (species.FirstVariantXP or Rank.FirstVariantXP) or 0)
end

function Rank.ResearchValue(creature)
	local species = C.Species[creature.species]
	if not species then return 0 end
	local base = species.ResearchXP or Rank.PassiveXPPerCreature
	local gold = table.find(creature.mutations or {}, "Dourado") ~= nil
	return math.max(0, math.floor(base * (gold and (species.GoldResearchMultiplier or 2) or 1)))
end

function Rank.PassiveReward(research, xp)
	if research <= 0 then
		return 0
	end
	return research + Rank.PassiveXPPerRank * (Rank.Level(xp) - 1)
end

assert(#Rank.Thresholds == 10, "Hunter Rank must have ten tiers")
for i = 2, #Rank.Thresholds do
	assert(Rank.Thresholds[i] > Rank.Thresholds[i - 1], "Hunter Rank thresholds must increase")
end
return Rank
