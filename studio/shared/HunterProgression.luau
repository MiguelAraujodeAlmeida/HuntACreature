-- Curva prototipável: XP total acumulado, sem rebirth nem bloqueio de ilhas.
local Rank = {}
local C = require(script.Parent.GameplayConfig)
Rank.Thresholds = { 0, 100, 700, 5000, 40000, 400000, 5000000, 80000000, 1500000000, 30000000000 }
Rank.GoldBonusPerRank = 0.05
Rank.TrainingBonusPerRank = 0.03
Rank.PassiveSeconds = 10
Rank.PassiveXPPerCreature = 1
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
	return (species.CaptureXP or Rank.CaptureXP)
		+ (firstSpecies and (species.FirstSpeciesXP or Rank.FirstSpeciesXP) or 0)
		+ (firstVariant and not firstSpecies and (species.FirstVariantXP or Rank.FirstVariantXP) or 0)
end

function Rank.PassiveReward(active, xp)
	if active <= 0 then
		return 0
	end
	return active * Rank.PassiveXPPerCreature + Rank.PassiveXPPerRank * (Rank.Level(xp) - 1)
end

assert(#Rank.Thresholds == 10, "Hunter Rank must have ten tiers")
for i = 2, #Rank.Thresholds do
	assert(Rank.Thresholds[i] > Rank.Thresholds[i - 1], "Hunter Rank thresholds must increase")
end
return Rank
