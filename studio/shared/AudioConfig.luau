-- Primeira paleta sonora, sujeita ao playtest. Fontes em studio/AUDIO.md.
return {
	MasterVolume = 0.7,
	MaxVoices = 8,
	Cues = {
		Click = { id = "106623224876186", volume = 0.28, cooldown = 0.07, pitch = 1 },
		Open = { id = "106984966606682", volume = 0.22, cooldown = 0.12, pitch = 0.85 },
		Charge = { id = "80984744279155", volume = 0.09, cooldown = 0.45, pitch = 0.85 },
		Charged = { id = "130378474223829", volume = 0.17, cooldown = 0.2, pitch = 1.35 },
		Throw = { id = "80984744279155", volume = 0.24, cooldown = 0.15, pitch = 1.2 },
		Return = { id = "80984744279155", volume = 0.10, cooldown = 0.2, pitch = 1.6 },
		Hit = { id = "106984966606682", volume = 0.29, cooldown = 0.15, pitch = 0.9 },
		Progress = { id = "130378474223829", volume = 0.10, cooldown = 0.35, pitch = 1.05 },
		Income = { id = "130378474223829", volume = 0.04, cooldown = 10, pitch = 1.1 },
		Win = { id = "112485797063762", volume = 0.3, cooldown = 0.6, pitch = 1 },
		Rare = { id = "112485797063762", volume = 0.36, cooldown = 0.6, pitch = 1.12 },
		Sparkle = { id = "130378474223829", volume = 0.13, cooldown = 0.1, pitch = 1.3 },
	},
}
