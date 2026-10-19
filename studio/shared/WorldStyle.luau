-- Amostras reversíveis de materiais. Nenhuma reconstrução do mapa.
local WorldStyle = {}
WorldStyle.Materials = {
	HAC_Studs = { image = "rbxassetid://133050717017276", tile = 4 },
	HAC_Leaves = { image = "rbxassetid://133050717017276", tile = 3.5 },
	HAC_ToyWood = { image = "rbxassetid://97810845356536", tile = 4 },
	HAC_Tiles = { image = "rbxassetid://103826263412719", tile = 12 },
}
WorldStyle.Surfaces = {
	Gramado = { material = "HAC_Studs", color = Color3.fromRGB(131, 245, 68) },
	Terra = { material = "HAC_Studs", color = Color3.fromRGB(238, 171, 91) },
	Copa = { material = "HAC_Leaves", color = Color3.fromRGB(59, 214, 83) },
	Tronco = { material = "HAC_ToyWood", color = Color3.fromRGB(233, 159, 77) },
	PostePonte = { material = "HAC_ToyWood", color = Color3.fromRGB(233, 159, 77) },
	Ponte = { material = "HAC_ToyWood", color = Color3.fromRGB(246, 192, 109) },
	Caminho = { material = "HAC_Tiles", color = Color3.fromRGB(255, 238, 170) },
	Rocha = { material = "HAC_Studs", color = Color3.fromRGB(157, 131, 248) },
}
function WorldStyle.Apply(world)
	local count = 0
	for _, part in ipairs(world:GetDescendants()) do
		local spec = part:IsA("BasePart") and WorldStyle.Surfaces[part.Name]
		if spec then
			if not part:GetAttribute("HACOriginalMaterial") then
				part:SetAttribute("HACOriginalMaterial", part.Material.Name)
				part:SetAttribute("HACOriginalVariant", part.MaterialVariant)
				part:SetAttribute("HACOriginalColor", part.Color)
				part:SetAttribute("HACOriginalTopSurface", part.TopSurface.Name)
			end
			part.Material = Enum.Material.SmoothPlastic
			part.MaterialVariant = ""
			part.Color = spec.color
			part.TopSurface = Enum.SurfaceType.Smooth
			local textureSpec = WorldStyle.Materials[spec.material]
			local faces = (part.Name == "Gramado" or part.Name == "Caminho") and { Enum.NormalId.Top }
				or Enum.NormalId:GetEnumItems()
			for _, face in ipairs(faces) do
				local name = "HAC_Texture_" .. face.Name
				local texture = part:FindFirstChild(name)
				if not texture then
					texture = Instance.new("Texture")
					texture.Name = name
					texture.Parent = part
				end
				texture.Face = face
				texture.Texture = textureSpec.image
				texture.StudsPerTileU = textureSpec.tile
				texture.StudsPerTileV = textureSpec.tile
				texture.Color3 = spec.color
				texture.Transparency = 0
			end
			count += 1
		end
	end
	return count
end
function WorldStyle.Restore(world)
	for _, part in ipairs(world:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("HACOriginalMaterial") then
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("Texture") and child.Name:match("^HAC_Texture_") then
					child:Destroy()
				end
			end
			part.Material = Enum.Material[part:GetAttribute("HACOriginalMaterial")]
			part.MaterialVariant = part:GetAttribute("HACOriginalVariant")
			part.Color = part:GetAttribute("HACOriginalColor")
			part.TopSurface = Enum.SurfaceType[part:GetAttribute("HACOriginalTopSurface")]
		end
	end
end
return WorldStyle

