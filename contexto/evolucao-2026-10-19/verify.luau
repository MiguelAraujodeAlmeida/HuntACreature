-- Isolated Edit checks. Does not start Play or touch DataStores.
local cache = {}
local function fresh(module)
 if cache[module] then return cache[module] end
 local fn, err = loadstring(module.Source, module:GetFullName())
 assert(fn, err)
 local env = setmetatable({script=module}, {__index=getfenv()})
 env.require = function(target) return typeof(target)=="Instance" and fresh(target) or require(target) end
 setfenv(fn,env)
 local result=fn();cache[module]=result;return result
end
local S=game.ServerScriptService.HACServer
local Client=game.StarterPlayer.StarterPlayerScripts.HACClient
local C=fresh(game.ReplicatedStorage.HACShared.GameplayConfig)
local Data=fresh(S.ProfileData)
local results={}
local function check(name,condition) assert(condition,name);table.insert(results,name) end
local sandbox=Instance.new("Folder");sandbox.Name="HACEvolutionVerification";sandbox.Parent=game.ServerStorage
local ok,err=xpcall(function()
 local p=Data.New()
 local item={id="test1",species="Lumito",rarity="Comum",size=1,mutations={},location="bag"}
 check("Lumito captures at strength 0",Data.Capture(p,item))
 check("Normal variant recorded",p.variantDiscoveries["Lumito:Normal"]==true)
 check("Favorite accepts boolean",Data.Action(p,"SetFavorite",{id="test1",value=true}))
 local originalGold=p.gold
 check("Favorite blocks server sale",Data.Action(p,"Sell",{id="test1"})==false and p.creatures.test1~=nil and p.gold==originalGold)
 check("Favorite rejects nonboolean",Data.Action(p,"SetFavorite",{id="test1",value="false"})==false)
 check("Favorite survives equip",Data.Action(p,"Equip",{id="test1"}) and p.creatures.test1.favorite)
 check("Unequip still works",Data.Action(p,"Unequip",{id="test1"}))
 check("Can unfavorite",Data.Action(p,"SetFavorite",{id="test1",value=false}))
 check("Unfavorited sale succeeds",Data.Action(p,"Sell",{id="test1"}) and p.gold==12 and p.creatures.test1==nil)
 check("Discovery survives sale",p.discoveries.Lumito and p.variantDiscoveries["Lumito:Normal"])
 check("Settings accepts boolean",Data.Action(p,"SetSetting",{id="Sound",value=false}) and p.settings.Sound==false)
 check("Settings rejects unknown key",Data.Action(p,"SetSetting",{id="admin",value=true})==false)
 check("Settings rejects invalid value",Data.Action(p,"SetSetting",{id="Sound",value=0})==false)
 local old=Data.Copy(p);old.settings=nil;old.variantDiscoveries=nil;old.creatures.test1=Data.Copy(item);old.creatures.test1.mutations={"Dourado"}
 Data.Validate(old)
 check("Old save migrated without losing gold",old.gold==12 and old.settings.Sound and old.variantDiscoveries["Lumito:Dourado"])
 check("Does not invent sold variant history",old.variantDiscoveries["Lumito:Normal"]==nil)
 C.Species.Test={MinimumStrength=5}
 local test=Data.Copy(item);test.species="Test";test.id="restricted"
 check("Capture rejects insufficient strength",Data.Capture(p,test)==false and p.creatures.restricted==nil)
 p.strength=5
 check("Capture accepts exact strength boundary",Data.Capture(p,test))
 C.Species.Test=nil;p.creatures.restricted=nil
 -- Build the authorized portrait catalog. Models stay in ReplicatedStorage.
 check("Portrait catalog has Normal and Gold",#fresh(S.CatalogPresentation).Build():GetChildren()==2)
 -- Base movement uses an isolated clone with deterministic random choices.
 local base=workspace.HuntACreature.Hub.Bases.Base1:Clone();base.Parent=sandbox
 base.CriaturasInstaladas:ClearAllChildren()
 local roam=setmetatable({agents={},random=Random.new(1948)},fresh(S.BaseRoamingService))
 local owned=Data.New();owned.upgrades.Base=3
 for i=1,6 do local v=Data.Copy(item);v.id="r"..i;v.slot=i;v.location="base";owned.creatures[v.id]=v end
 roam:Sync(base,owned);roam:Sync(base,owned)
 check("Six equipped creatures spawn freely",#base.CriaturasInstaladas:GetChildren()==6)
 local positions={}
 for model,a in pairs(roam.agents) do positions[model]=a.position end
 roam:Sync(base,owned)
 for model,a in pairs(roam.agents) do assert(a.position==positions[model],"Income sync moved creature") end
 check("Profile sync does not reset movement",true)
 for _=1,60 do roam:Step(0.05) end
 local moved=false
 for model,a in pairs(roam.agents) do
  moved=moved or (a.position-positions[model]).Magnitude>0.1
  local localPoint=base.Plataforma.CFrame:PointToObjectSpace(a.position)
  assert(math.abs(localPoint.X)<9 and math.abs(localPoint.Z)<8.5,"Escaped base")
  for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then assert(not part.CanCollide and not part.CanQuery and not part.CanTouch,"Physical interference") end end
 end
 check("Creatures move inside bounds without physical collisions",moved)
 owned.creatures.r1.location="bag";owned.creatures.r1.slot=nil;roam:Sync(base,owned)
 check("Unequip removes roaming visual",#base.CriaturasInstaladas:GetChildren()==5)
 -- Build each menu using real UI constructors, without bootstrapping a player.
 local UI=fresh(Client.CollectionUI)
 local gui=Instance.new("ScreenGui");gui.Parent=sandbox
 local root=Instance.new("Frame");root.Size=UDim2.fromOffset(650,530);root.Parent=gui
 local scroll=Instance.new("ScrollingFrame");scroll.Parent=root
 local header=Instance.new("TextLabel");header.Parent=root
 local ui=setmetatable({root=root,scroll=scroll,header=header,player={},hud={Notice=function() end},data={profile=old,rotation=C.Rotation(os.time())}},UI)
 for _,tab in ipairs({"Criaturas","Venda","Index","Loja","Settings"}) do ui.tab=tab;ui:Render();check("Menu builds: "..tab,#scroll:GetChildren()>0) end
 ui.tab="Loja";ui.shopCategory="Lassos";ui:Render();check("Lassos tab builds",#scroll:GetChildren()>0)
 ui.tab="Index";ui.indexVariant="Dourado";ui:Render()
 check("Index uses model portraits",scroll:FindFirstChildWhichIsA("ViewportFrame",true)~=nil)
 -- Preferences tested only against isolated roots, including deferred events.
 local prefRoot=Instance.new("Folder");prefRoot.Parent=sandbox
 local bases=Instance.new("Folder");bases.Name="Bases";bases.Parent=prefRoot
 local installed=Instance.new("Folder");installed.Name="CriaturasInstaladas";installed.Parent=bases
 local part=Instance.new("Part");part.LocalTransparencyModifier=0.2;part.Parent=installed
 local sound=Instance.new("Sound");sound.Volume=0.6;sound.Parent=prefRoot
 local preferences=fresh(Client.LocalPreferences).new(gui,{prefRoot})
 preferences:Apply({Sound=false,BaseCreatures=false})
 task.wait()
 check("Preferences hide base model and mute sound",part.LocalTransparencyModifier==1 and sound.Volume==0)
 local newcomer=Instance.new("Part");newcomer.Parent=installed
 task.wait()
 check("Hidden preference applies to new creatures",newcomer.LocalTransparencyModifier==1)
 sound.Volume=0.4;task.wait()
 check("Muted sounds cannot restore volume themselves",sound.Volume==0)
 preferences:Apply({Sound=true,BaseCreatures=true});task.wait()
 check("Preferences restore visibility and desired volume",math.abs(part.LocalTransparencyModifier-0.2)<0.001 and math.abs(sound.Volume-0.4)<0.001)
 gui:Destroy()
end,debug.traceback)
sandbox:Destroy()
return game.HttpService:JSONEncode({passed=results,count=#results,error=not ok and tostring(err) or nil})
