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
Config.NormalGain = 0.29
Config.StrengthRadiusBonus = 0.09
Config.StrengthHalfBonus = 30
Config.MissDecay = 0.07

return Config
