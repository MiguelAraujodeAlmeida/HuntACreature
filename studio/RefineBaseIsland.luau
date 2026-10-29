-- Edit-only art pass. No gameplay migration, water, buildings or signs.
assert(not game:GetService('RunService'):IsRunning(), 'Edit only')
local r = assert(workspace:FindFirstChild('HAC_IlhaBase'))
local ss = game:GetService('ServerStorage')
local lighting = game:GetService('Lighting')
if not ss:FindFirstChild('HACIslandBeforeArtV03') then
    local backup = r:Clone()
    backup.Name = 'HACIslandBeforeArtV03'
    backup:SetAttribute('PreviousSpecular', lighting.EnvironmentSpecularScale)
    backup.Parent = ss
end
local preview = r:FindFirstChild('PreviewV02')
if preview then preview:Destroy() end
if r:GetAttribute('HACArtRevision') == '03' then return 'Art 03 already applied' end

-- A material palette, not a single decal repeated over unrelated surfaces.
local palette = {
    foliage = Color3.fromRGB(91, 155, 95), grass = Color3.fromRGB(133, 177, 103),
    sand = Color3.fromRGB(217, 195, 150), soil = Color3.fromRGB(164, 126, 92),
    stone = Color3.fromRGB(137, 148, 151), wood = Color3.fromRGB(145, 110, 78),
    path = Color3.fromRGB(213, 203, 173),
}
local function make(parent, name, size, cf, color, shape)
    local p = Instance.new('Part')
    p.Name, p.Size, p.CFrame = name, size, cf
    p.Anchored, p.CanTouch = true, false
    p.Material, p.Color, p.Reflectance = Enum.Material.SmoothPlastic, color, 0
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end
local removedTextures, labels = 0, 0
for _,p in r:GetDescendants() do
    if p:IsA('Texture') then p:Destroy() removedTextures += 1
    elseif p:IsA('BillboardGui') then p:Destroy() labels += 1
    elseif p:IsA('Light') then p.Enabled = false
    elseif p:IsA('BasePart') then
        p.Reflectance = 0
        if p.Material == Enum.Material.Neon then p.Material = Enum.Material.SmoothPlastic end
    end
end
for _,p in r.Terreno:GetChildren() do
    if p:IsA('BasePart') then
        if p.Name:find('Grama') then p.Color = palette.grass; p.Material = Enum.Material.SmoothPlastic
        elseif p.Name:find('Areia') or p.Name:find('Praia') then p.Color = palette.sand; p.Material = Enum.Material.Sand
        elseif p.Name:find('Barranco') then p.Color = palette.soil; p.Material = Enum.Material.Sand
        else p.Color = palette.stone; p.Material = Enum.Material.Slate end
    end
end
for _,p in r.Caminhos:GetChildren() do
    if p:IsA('BasePart') then p.Color = palette.path; p.Material = Enum.Material.Concrete end
end
for _,p in r.Porto:GetDescendants() do
    if p:IsA('BasePart') then p.Color = palette.wood; p.Material = Enum.Material.Wood end
end
-- Reservation geometry remains available in Explorer, without in-world visual noise.
for _,p in r.Lotes:GetDescendants() do
    if p:IsA('BasePart') then p.Transparency = 1; p.CanCollide = false end
end

local models = r.Vegetacao:GetChildren()
table.sort(models, function(a,b)
    local pa,pb = a:GetPivot().Position,b:GetPivot().Position
    return pa.X == pb.X and pa.Z < pb.Z or pa.X < pb.X
end)
local trees, bushes, flowers = 0,0,0
for _,m in models do
    if m.Name == 'Flores' then
        flowers += 1
        if flowers % 4 ~= 0 then m:Destroy() end
    elseif m.Name == 'Arbusto' then
        bushes += 1
        if bushes % 3 ~= 0 then m:Destroy()
        else
            for _,p in m:GetChildren() do
                if p:IsA('Part') then p.Shape = Enum.PartType.Ball; p.Color = palette.foliage; p.Size *= Vector3.new(1,0.72,1) end
            end
        end
    elseif m.Name == 'Arvore' then
        trees += 1
        local trunk = m:FindFirstChild('Tronco')
        if trunk then
            local center = trunk.Position
            local bottom = center.Y - trunk.Size.Y/2
            local scale = trunk.Size.X/3
            if trees % 4 == 0 then m:Destroy()
            else
                m:ClearAllChildren()
                local h = (trees % 3 == 0 and 9 or 7) * scale
                make(m,'Trunk',Vector3.new(1.8*scale,h,1.8*scale),CFrame.new(center.X,bottom+h/2,center.Z),palette.wood)
                local tint = palette.foliage:Lerp(Color3.fromRGB(138,178,99), (trees%3)*0.18)
                if trees % 3 == 0 then
                    -- Broad two-tier crown with no intersecting layers.
                    make(m,'LowerCrown',Vector3.new(10,4,8)*scale,CFrame.new(center.X,bottom+h+2*scale,center.Z),tint)
                    make(m,'UpperCrown',Vector3.new(7,3,6)*scale,CFrame.new(center.X,bottom+h+5.5*scale,center.Z),tint:Lerp(palette.grass,0.2))
                else
                    -- Rounded toy crown provides a different silhouette without decal detail.
                    make(m,'Crown',Vector3.new(10,trees%2==0 and 10 or 7,8)*scale,CFrame.new(center.X,bottom+h+2.8*scale,center.Z),tint,Enum.PartType.Ball)
                end
            end
        end
    elseif m.Name == 'Rocha' then
        for _,p in m:GetChildren() do if p:IsA('BasePart') then p.Color = palette.stone; p.Material = Enum.Material.Slate end end
    end
end
local palmIndex, postIndex = 0,0
for _,m in r.Detalhes:GetChildren() do
    if m.Name == 'Palmeira' then
        palmIndex += 1
        if palmIndex%2==0 then m:Destroy()
        else
            local cf,size = m:GetBoundingBox()
            local base = cf.Position - Vector3.new(0,size.Y/2,0)
            local h = size.Y*0.72
            m:ClearAllChildren()
            make(m,'Trunk',Vector3.new(1.4,h,1.4),CFrame.new(base+Vector3.new(0,h/2,0)),palette.wood)
            for i=1,5 do
                local angle = i*math.pi*2/5
                local dir = Vector3.new(math.sin(angle),0,math.cos(angle))
                local p = Instance.new('WedgePart')
                p.Name='Frond'; p.Size=Vector3.new(2.3,1.2,6)
                p.CFrame=CFrame.lookAt(base+Vector3.new(0,h,0)+dir*3.2,base+Vector3.new(0,h,0)+dir*4.2)
                p.Anchored=true; p.CanCollide=false; p.CanTouch=false
                p.Color=palette.foliage; p.Material=Enum.Material.SmoothPlastic; p.Parent=m
            end
        end
    elseif m.Name == 'Poste' then
        postIndex += 1
        if postIndex%3~=0 then m:Destroy()
        else for _,p in m:GetDescendants() do if p:IsA('BasePart') then p.Color=p.Name=='Lanterna' and palette.sand or palette.wood end end end
    elseif m.Name == 'FlorCanteiro' then m:Destroy() end
end
-- Lighting is shared by the place; saved previous value in the backup.
lighting.EnvironmentSpecularScale = 0.15
r:SetAttribute('HACArtRevision','03')
-- Shared chamfered solid: cut corners once, clone by role; no exposed intersecting boxes.
local template = ss:FindFirstChild('HACBeveledCanopyTemplate')
if not template then
    local a = make(workspace,'TemporaryCanopy',Vector3.new(10,7,8),CFrame.new(0,500,0),palette.foliage)
    local cuts = {}
    for _,x in {-5,5} do for _,z in {-4,4} do
        table.insert(cuts,make(workspace,'TemporaryCut',Vector3.new(3,12,3),a.CFrame*CFrame.new(x,0,z)*CFrame.Angles(0,math.pi/4,0),palette.foliage))
    end end
    for _,y in {-3.5,3.5} do
        for _,x in {-5,5} do table.insert(cuts,make(workspace,'TemporaryCut',Vector3.new(3,3,20),a.CFrame*CFrame.new(x,y,0)*CFrame.Angles(0,0,math.pi/4),palette.foliage)) end
        for _,z in {-4,4} do table.insert(cuts,make(workspace,'TemporaryCut',Vector3.new(20,3,3),a.CFrame*CFrame.new(0,y,z)*CFrame.Angles(math.pi/4,0,0),palette.foliage)) end
    end
    local ok, result = pcall(function() return a:SubtractAsync(cuts) end)
    a:Destroy(); for _,p in cuts do p:Destroy() end
    assert(ok,result)
    template = result; template.Name='HACBeveledCanopyTemplate'; template.Parent=ss
end
local function faceted(parent,name,size,cf,color)
    local p=template:Clone(); p.Name=name; p.Size=size; p.CFrame=cf
    p.Color=color; p.UsePartColor=true; p.Material=Enum.Material.SmoothPlastic
    p.Anchored=true; p.CanTouch=false; p.Parent=parent
end
for _,m in r.Vegetacao:GetChildren() do
    if m.Name=='Arvore' then
        for _,p in m:GetChildren() do if p.Name:find('Crown') then
            faceted(m,p.Name,p.Size,p.CFrame,p.Color); p:Destroy()
        end end
    elseif m.Name=='Arbusto' then
        local cf,size=m:GetBoundingBox()
        local h=math.min(size.Y,3.5)
        m:ClearAllChildren()
        faceted(m,'Shrub',Vector3.new(size.X,h,size.Z),CFrame.new(cf.Position-Vector3.new(0,(size.Y-h)/2,0)),palette.foliage)
    elseif m.Name=='Rocha' then
        for _,p in m:GetChildren() do if p:IsA('BasePart') then
            faceted(m,p.Name,p.Size,p.CFrame,palette.stone); p:Destroy()
        end end
    end
end
return string.format('Art03 applied; textures removed=%d; labels removed=%d; no PreviewV02=%s',removedTextures,labels,tostring(r:FindFirstChild('PreviewV02')==nil))
