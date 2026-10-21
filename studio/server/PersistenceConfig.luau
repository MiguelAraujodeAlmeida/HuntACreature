-- Explicit global reset boundary. Never derive this value from the current date/time.
-- Older generations remain recoverable; changing Generation resets every account.
local Config = { Generation = "20261021_hunter_rank_01" }

function Config.StoreName(isStudio)
	return (isStudio and "HAC_Profiles_Studio_" or "HAC_Profiles_") .. Config.Generation
end

return Config
