-- Temporary edit-time visual preview. Sample profile never touches persistence.
local cache={}
local function fresh(module)
 if cache[module] then return cache[module] end
 local fn=assert(loadstring(module.Source,module:GetFullName()))
 local env=setmetatable({script=module},{__index=getfenv()})
 env.require=function(target) return typeof(target)=="Instance" and fresh(target) or require(target) end
 setfenv(fn,env);local value=fn();cache[module]=value;return value
end
local Client=game.StarterPlayer.StarterPlayerScripts.HACClient
local Kit=fresh(Client.MenuKit)
local UI=fresh(Client.CollectionUI)
local C=fresh(game.ReplicatedStorage.HACShared.GameplayConfig)
local Data=fresh(game.ServerScriptService.HACServer.ProfileData)
local core=game:GetService("CoreGui")
local old=core:FindFirstChild("HACMenuPreview");if old then old:Destroy() end
local gui=Instance.new("ScreenGui")
gui.Name="HACMenuPreview";gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.IgnoreGuiInset=true;gui.DisplayOrder=100
gui.Parent=core
local window=Kit.Window(gui,function() gui:Destroy() end)
local ui=setmetatable(window,UI)
local p=Data.New()
p.gold=320
Data.Capture(p,{id="preview1",species="Lumito",rarity="Comum",size=1,mutations={},location="bag"})
Data.Capture(p,{id="preview2",species="Lumito",rarity="Comum",size=1.2,mutations={"Dourado"},location="bag",favorite=true})
p.creatures.preview1.location="base";p.creatures.preview1.slot=1
ui.player={};ui.hud={Notice=function() end};ui.remote={FireServer=function() end}
ui.data={profile=p,rotation=C.Rotation(os.time())}
ui.tab="Loja"
local theme=Kit.Theme.Page(ui.tab)
local screen=workspace.CurrentCamera.ViewportSize
ui.root.Size=UDim2.fromOffset(math.min(theme.Width,screen.X-32),math.min(theme.Height,screen.Y-32))
ui.root.Visible=true
ui:Render()
ui.footer.Text="EDIT PREVIEW · SAMPLE DATA"
task.wait(0.2)
return {screen=tostring(screen),size=tostring(ui.root.AbsoluteSize),catalog=game.ReplicatedStorage:FindFirstChild("HACCreaturePreviews")~=nil}