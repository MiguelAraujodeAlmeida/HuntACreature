-- Ajustes exclusivos do item 5 e do minigame (item 2).
local Config = {}

Config.ToolName = "Training Lasso"
Config.Lassos = {
	["Training Lasso"] = {
		ChargeSeconds = 1.4,
		MinimumRange = 18,
		MaximumRange = 73,
		ProjectileSpeed = 100,
		ReturnSpeed = 145,
		CooldownSeconds = 0.12,
	},
}
Config.MinimumChargeSeconds = 0.12
Config.AimLimit = 1000
Config.MaximumCameraDistance = 512
Config.CameraTolerance = 16
Config.MaximumChargeSeconds = 30
Config.LoopRadius = 1.1 -- Mesmo raio usado pela arte e pelo contato do projétil.

Config.CaptureTimeLimit = 22
Config.StateInterval = 0.05
Config.ZoneFriction = 7.5
Config.ZoneMaxSpeed = 0.93
Config.ZoneRadius = 0.16
Config.NormalGain = 0.18 -- Uma boa disputa dura varios ciclos, sem captura instantanea.
Config.StrengthRadiusBonus = 0.09
Config.StrengthHalfBonus = 30
Config.MissDecay = 0.075
Config.RhythmSeconds = 3.6
Config.ResistStart = 1.25
Config.OpeningStart = 2.35
Config.ResistSpeed = 1.28
Config.OpeningSpeed = 0.62
Config.ResistGain = 0.78
Config.OpeningGain = 1.32
Config.GoalStep = 0.25

return Config
