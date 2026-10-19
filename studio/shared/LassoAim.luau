-- Geometria compartilhada. Não decide captura; cliente e servidor usam o mesmo alcance.
local Aim = {}
function Aim.Range(lasso, power)
	return lasso.MinimumRange + (lasso.MaximumRange - lasso.MinimumRange) * math.clamp(power, 0, 1)
end
function Aim.Origin(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and root.Position + Vector3.new(0, 1.3, 0)
end
function Aim.Params(excluded)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	return params
end
function Aim.Creature(instance, wildFolder)
	local current = instance
	while current and current.Parent ~= wildFolder do
		current = current.Parent
	end
	return current and current:IsA("Model") and current or nil
end
function Aim.Resolve(origin, ray, range, params, rayLength)
	local cameraHit = workspace:Raycast(ray.origin, ray.direction.Unit * rayLength, params)
	local point = cameraHit and cameraHit.Position or ray.origin + ray.direction.Unit * rayLength
	local delta = point - origin
	local direction = delta.Magnitude > 0.01 and delta.Unit or ray.direction.Unit
	local distance = math.min(delta.Magnitude, range)
	if distance < 0.05 then
		distance = 0.05
	end
	-- Um obstáculo entre a mão e o ponto mirado interrompe o percurso.
	local hit = workspace:Raycast(origin, direction * distance, params)
	return {
		origin = origin,
		direction = direction,
		distance = hit and (hit.Position - origin).Magnitude or distance,
		endpoint = hit and hit.Position or origin + direction * distance,
		hit = hit,
		cameraHit = cameraHit,
		withinRange = delta.Magnitude <= range + 0.01,
	}
end
return Aim

