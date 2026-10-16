-- Ajustes exclusivos do item 5 e do minigame (item 2).
local Config = {}

Config.ToolName = "Laço de treino"
Config.Lassos = {
	["Laço de treino"] = {
		ChargeSeconds = 1.4,
		MinimumRange = 18,
		MaximumRange = 73,
		ProjectileSpeed = 90,
		CooldownSeconds = 0.65,
	},
}
Config.MinimumChargeSeconds = 0.12
Config.AimLimit = 140
Config.MaximumCameraDistance = 40
Config.MovingTargetTolerance = 2

Config.CaptureTimeLimit = 28
Config.StateInterval = 0.05
Config.ZoneFriction = 7.5
Config.ZoneMaxSpeed = 0.93
Config.ZoneRadius = 0.16
Config.NormalGain = 0.24
Config.GoldenGain = 0.20
Config.MissDecay = 0.07

return Config
