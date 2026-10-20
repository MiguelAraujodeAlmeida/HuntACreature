-- Mix local: sinais por ação, pré-carregamento, teto de vozes e cancelamento.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Config = require(game.ReplicatedStorage.HACShared.AudioConfig)
local Audio = { templates = {}, voices = {}, last = {}, generation = 0 }

function Audio.Init()
	if Audio.root then return end
	local root = Instance.new("Folder")
	root.Name = "HACAudio"
	root.Parent = SoundService
	Audio.root = root
	local group = Instance.new("SoundGroup")
	group.Name = "HAC_Efeitos"
	group.Volume = Audio.muted and 0 or Config.MasterVolume
	group.Parent = root
	Audio.group = group
	for _, cue in pairs(Config.Cues) do
		if not Audio.templates[cue.id] then
			local sound = Instance.new("Sound")
			sound.Name = cue.id
			sound.SoundId = "rbxassetid://" .. cue.id
			sound.SoundGroup = group
			sound.Volume = 0
			sound.Parent = root
			Audio.templates[cue.id] = sound
		end
	end
	task.spawn(function()
		local list = {}
		for _, sound in pairs(Audio.templates) do table.insert(list, sound) end
		pcall(function()
			ContentProvider:PreloadAsync(list, function(id, status)
				if status ~= Enum.AssetFetchStatus.Success then
					warn("[HAC Audio] Asset indisponível: " .. id .. " (" .. status.Name .. ")")
				end
			end)
		end)
	end)
end

function Audio.Play(name, pitchMultiplier)
	local cue = Config.Cues[name]
	if not cue or not Audio.root or Audio.muted then return end
	local now = os.clock()
	if now - (Audio.last[name] or -math.huge) < cue.cooldown then return end
	Audio.last[name] = now
	for i = #Audio.voices, 1, -1 do
		if not Audio.voices[i].Parent then table.remove(Audio.voices, i) end
	end
	if #Audio.voices >= Config.MaxVoices then table.remove(Audio.voices, 1):Destroy() end
	local sound = Audio.templates[cue.id]:Clone()
	sound.Name = name
	sound.Volume = cue.volume
	sound.PlaybackSpeed = cue.pitch * (pitchMultiplier or 1)
	sound.Parent = Audio.root
	table.insert(Audio.voices, sound)
	sound:Play()
	sound.Ended:Once(function() sound:Destroy() end)
	task.delay(5, function() if sound.Parent then sound:Destroy() end end)
	return sound
end

function Audio.Charge(power)
	if power >= 1 then
		if not Audio.full then
			Audio.full = true
			Audio.StopCharge()
			Audio.full = true
			Audio.Play("Charged")
		end
	elseif not Audio.full then
		if not Audio.charging then
			Audio.charging = true
			Audio.chargeVoice = Audio.Play("Charge")
		end
		if Audio.chargeVoice and Audio.chargeVoice.Parent then
			Audio.chargeVoice.PlaybackSpeed = Config.Cues.Charge.pitch * (1 + power * 0.45)
		end
	end
end

function Audio.StopCharge()
	Audio.charging = false
	Audio.full = false
	for _, voice in ipairs(Audio.voices) do
		if voice.Parent and voice.Name == "Charge" then voice:Destroy() end
	end
	Audio.chargeVoice = nil
end

function Audio.Reward(golden, discovery)
	Audio.Play(golden and "Rare" or "Win")
	if golden or discovery then
		local generation = Audio.generation
		for i = 1, discovery and 4 or 3 do
			task.delay(0.35 + i * 0.13, function()
				if generation == Audio.generation then Audio.Play("Sparkle", 1 + i * 0.12) end
			end)
		end
	end
end

function Audio.SetMuted(muted)
	Audio.muted = muted
	if Audio.group then Audio.group.Volume = muted and 0 or Config.MasterVolume end
end

function Audio.Destroy()
	Audio.generation += 1
	Audio.StopCharge()
	if Audio.root then Audio.root:Destroy() end
	Audio.root, Audio.group = nil, nil
	Audio.templates, Audio.voices, Audio.last = {}, {}, {}
end
return Audio
