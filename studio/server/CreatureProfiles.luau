-- Parâmetros iniciais para playtest. Raridade/variante não implica uma IA diferente.
return {
	Lumito = {
		Behavior = "Lumito",
		WalkSpeed = 3.5,
		PanicSpeed = 14,
		TiredSpeed = 1.8,
		PanicSeconds = 5,
		RecoverySeconds = 7,
		ViewDistance = 28,
		ViewAngle = 110, -- cone total, à frente dos olhos
		ThinkInterval = 0.25,
		WanderRadius = 18,
		PauseMin = 1,
		PauseMax = 3,
		LongPauseChance = 0.25,
		LongPauseMin = 3.5,
		LongPauseMax = 6,
		WalkBurstMin = 1.2,
		WalkBurstMax = 4.5,
		ResumeSameGoalChance = 0.45,
		WalkSpeedMinFactor = 0.8,
		WalkSpeedMaxFactor = 1.1,
		BodyRadius = 1.85,
		RootHeight = 1.68,
		EdgeMargin = 0.6,
		MaxStepHeight = 0.35,
	},
}
