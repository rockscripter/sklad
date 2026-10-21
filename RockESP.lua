-- RockESP 1.0.0 | Standalone client-side ESP extracted from Rock Hub's native ESP.
-- Roblox instances only: no Drawing API, UI library or external dependencies.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local UIS=game:GetService("UserInputService")
local RockESP={Version="1.0.0"}
local ESP={}
ESP.__index=ESP
local RGB=Color3.fromRGB
local defaults={
	Enabled=false, Roles=true, MaxDistance=1500, ColorMode="White", Color=RGB(255,255,255),
	Chams=true, Box=true, BoxStyle="Corners", Names=true, Distance=true, HealthBar=true,
	Tracers=false, TracerFrom="Bottom", ChamsFill=30, TextSize=12, Thickness=1,
	RoleColors={Murderer=RGB(255,58,58),Sheriff=RGB(64,150,255),Hero=RGB(64,150,255)},
	RoleLabels=true, RoleInterval=0.25, RemoteInterval=1,
	BoxFill=true, BoxFillOpacity=0.18, ChamsOutlineOpacity=0.9,
	DepthMode="AlwaysOnTop", TeamCheck=false, TeamColor=false, VisibleOnly=false,
	ShowLocalPlayer=false, ShowDead=false, OffscreenChams=false, DisplayNames=true,
	TextOutline=true, TextOutlineOpacity=0.55, OutlineColor=RGB(0,0,0),
	InfoColor=RGB(188,188,188), HealthLowColor=Color3.fromHSV(0,0.8,1),
	HealthHighColor=Color3.fromHSV(0.33,0.8,1), HealthColorMode="HSV",
	RainbowSpeed=0.15, RainbowSaturation=0.55, RainbowPerPlayer=true,
	FadeSpeed=10, HealthSmoothing=8, TracerOpacity=0.75, TracerTarget="Bottom",
	BoxHeight=6.4, BoxWidthRatio=0.6, BoxYOffset=-0.2, CornerWidth=0.28, CornerHeight=0.2,
	UseBoundingBox=false, DistanceSuffix=" studs", DistanceScale=1, UpdateRate=0,
}
local function copy(t)
	if type(t)~="table" then return t end
	local out={} for k,v in pairs(t) do out[k]=copy(v) end return out
end
RockESP.Defaults=copy(defaults)
local ranges={
	MaxDistance={1,1000000},ChamsFill={0,100},TextSize={8,48},Thickness={1,8},
	RoleInterval={0.05,60},RemoteInterval={0.25,120},BoxFillOpacity={0,1},ChamsOutlineOpacity={0,1},
	TextOutlineOpacity={0,1},RainbowSpeed={0,10},RainbowSaturation={0,1},FadeSpeed={0,100},
	HealthSmoothing={0,100},TracerOpacity={0,1},BoxHeight={0.1,1000},BoxWidthRatio={0.05,10},
	BoxYOffset={-1000,1000},CornerWidth={0.01,0.5},CornerHeight={0.01,0.5},
	DistanceScale={0.0001,100000},UpdateRate={0,240},
}
local enums={ColorMode={"White","Custom","Health","Rainbow","Team"},BoxStyle={"Corners","Full"},
	TracerFrom={"Bottom","Center","Top","Mouse"},TracerTarget={"Bottom","Center","Top"},
	DepthMode={"AlwaysOnTop","Occluded"},HealthColorMode={"HSV","Lerp"}}
local function validate(key,value)
	local base=defaults[key]
	assert(base~=nil,"Unknown ESP setting: " .. tostring(key))
	if ranges[key] then
		local range=ranges[key]
		assert(type(value)=="number" and value==value and value>=range[1] and value<=range[2],key .. " out of range")
	elseif enums[key] then assert(table.find(enums[key],value),"Invalid " .. key)
	elseif key=="RoleColors" then
		assert(type(value)=="table","RoleColors must be a table")
		for role,color in pairs(value) do assert(type(role)=="string" and typeof(color)=="Color3","Invalid role color") end
	elseif typeof(base)=="Color3" then assert(typeof(value)=="Color3",key .. " expects Color3")
	else assert(type(value)==type(base),key .. " has incorrect type") end
	return copy(value)
end
local function make(class,props,parent)
	local o=Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel=0 end
	for k,v in pairs(props or {}) do o[k]=v end
	o.Parent=parent return o
end
local function line(parent)
	local f=make("Frame",{},parent)
	make("UIStroke",{Color=RGB(0,0,0),Transparency=0.5,Thickness=1},f)
	return f
end
local function text(parent,anchor)
	return make("TextLabel",{Font=Enum.Font.GothamBold,TextSize=12,BackgroundTransparency=1,
		TextStrokeColor3=RGB(0,0,0),TextStrokeTransparency=0.45,AnchorPoint=Vector2.new(0.5,anchor),
		Size=UDim2.fromOffset(260,18),Text=""},parent)
end
local function placeLine(obj,a,b,thickness)
	local d=b-a
	obj.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
	obj.Size=UDim2.fromOffset(d.Magnitude,thickness)
	obj.Rotation=math.deg(math.atan2(d.Y,d.X))
end
function ESP:_connect(signal,fn)
	local c=signal:Connect(function(...) if not self.Destroyed then fn(...) end end)
	table.insert(self._connections,c) return c
end
function ESP:GetSettings() return copy(self.Settings) end
function ESP:Get(key) return copy(self.Settings[key]) end
function ESP:Configure(patch)
	assert(not self.Destroyed,"ESP is destroyed")
	assert(type(patch)=="table","Configure expects a table")
	local checked={}
	for k,v in pairs(patch) do checked[k]=validate(k,v) end
	for k,v in pairs(checked) do self.Settings[k]=v end
	self.Gui.Enabled=self.Settings.Enabled
	for _,e in pairs(self.Entries) do
		e.RoleAt=nil
		if not self.Settings.Enabled then self:_hide(e) end
	end
	return self
end
function ESP:Set(key,value) return self:Configure({[key]=value}) end
function ESP:SetEnabled(enabled) return self:Set("Enabled",enabled) end
function ESP:Enable() return self:SetEnabled(true) end
function ESP:Disable() return self:SetEnabled(false) end
function ESP:Toggle() return self:SetEnabled(not self.Settings.Enabled) end
function ESP:Reset() return self:Configure(copy(defaults)) end
function ESP:_hide(e)
	e.Alpha=0 e.Root.Visible=false e.Highlight.Enabled=false
end
function ESP:Add(target,options)
	assert(not self.Destroyed,"ESP is destroyed")
	assert(typeof(target)=="Instance" and (target:IsA("Player") or target:IsA("Model")),"Target must be a Player or Model")
	if self.Entries[target] then return self.Entries[target] end
	options=options or {}
	if options.Color then assert(typeof(options.Color)=="Color3","Target Color expects Color3") end
	local e={Target=target,Options=copy(options),Alpha=0,HP=1,Hue=math.random()}
	e.Root=make("Frame",{Name="ESP_" .. target.Name,BackgroundTransparency=1,Size=UDim2.fromOffset(0,0),Visible=false},self.Gui)
	e.Fill=make("Frame",{},e.Root)
	e.FillGradient=make("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0.82)},e.Fill)
	e.Corners={}
	for i=1,8 do e.Corners[i]=line(e.Root) end
	e.Shadow=make("Frame",{BackgroundTransparency=1},e.Root)
	e.ShadowStroke=make("UIStroke",{Color=RGB(0,0,0),Transparency=0.5,Thickness=3},e.Shadow)
	e.Full=make("Frame",{BackgroundTransparency=1},e.Root)
	e.FullStroke=make("UIStroke",{Thickness=1},e.Full)
	e.Name=text(e.Root,1) e.Info=text(e.Root,0) e.Info.Font=Enum.Font.GothamMedium
	e.HealthBackground=make("Frame",{BackgroundColor3=RGB(0,0,0)},e.Root)
	e.HealthFill=make("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,1,1,-1)},e.HealthBackground)
	e.Tracer=line(e.Root) e.Tracer.AnchorPoint=Vector2.new(0.5,0.5)
	e.Highlight=make("Highlight",{Enabled=false,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},self.Chams)
	self.Entries[target]=e
	e.DestroyConnection=target.Destroying:Connect(function() self:Remove(target) end)
	return e
end
function ESP:Remove(target)
	local e=self.Entries[target]
	if not e then return self end
	self.Entries[target]=nil
	if e.DestroyConnection then e.DestroyConnection:Disconnect() end
	e.Root:Destroy() e.Highlight:Destroy()
	return self
end
function ESP:Clear()
	local targets={}
	for target in pairs(self.Entries) do table.insert(targets,target) end
	for _,target in ipairs(targets) do self:Remove(target) end
	return self
end
function ESP:SetTargetOptions(target,options)
	local e=assert(self.Entries[target],"Target not registered")
	if options.Color then assert(typeof(options.Color)=="Color3","Target Color expects Color3") end
	for k,v in pairs(options) do e.Options[k]=v end
	e.RoleAt=nil
	return self
end
function ESP:SetRoles(roles)
	assert(type(roles)=="table","Roles must be a table keyed by player name or UserId")
	local out={}
	for key,value in pairs(roles) do
		assert(type(key)=="string" or type(key)=="number","Invalid role key")
		if type(value)=="string" then out[key]=value
		elseif type(value)=="table" and type(value.Role)=="string" and not value.Dead and not value.Killed then out[key]=value.Role end
	end
	self._roles=out
	for _,e in pairs(self.Entries) do e.RoleAt=nil end
	return self
end
function ESP:_role(target,character,e)
	if e.Options.Role then return e.Options.Role end
	if self.RoleProvider then
		local ok,result=pcall(self.RoleProvider,target,character)
		if ok and type(result)=="string" then return result end
	end
	local backpack=target:IsA("Player") and target:FindFirstChildOfClass("Backpack")
	local function hasTool(name)
		local tool=character:FindFirstChild(name) or (backpack and backpack:FindFirstChild(name))
		return tool and tool:IsA("Tool")
	end
	if hasTool("Knife") then return "Murderer" end
	if hasTool("Gun") then return "Sheriff" end
	if target:IsA("Player") then return self._roles[target.UserId] or self._roles[tostring(target.UserId)] or self._roles[target.Name] end
	return self._roles[target.Name]
end
function ESP:_healthColor(hp)
	local s=self.Settings
	if s.HealthColorMode=="HSV" then return Color3.fromHSV(0.33*math.clamp(hp,0,1),0.8,1) end
	return s.HealthLowColor:Lerp(s.HealthHighColor,math.clamp(hp,0,1))
end
function ESP:_color(e,now)
	local s,target=self.Settings,e.Target
	if e.Options.Color then return e.Options.Color end
	if s.Roles and e.Role and s.RoleColors[e.Role] then return s.RoleColors[e.Role] end
	if (s.TeamColor or s.ColorMode=="Team") and target:IsA("Player") and target.Team then return target.TeamColor.Color end
	if s.ColorMode=="Health" then return self:_healthColor(e.HP) end
	if s.ColorMode=="Rainbow" then return Color3.fromHSV((now*s.RainbowSpeed+(s.RainbowPerPlayer and e.Hue or 0))%1,s.RainbowSaturation,1) end
	return s.ColorMode=="White" and RGB(255,255,255) or s.Color
end
function ESP:_bounds(camera,character,root)
	local s=self.Settings
	if s.UseBoundingBox then
		local cf,size=character:GetBoundingBox()
		local xmin,ymin,xmax,ymax=math.huge,math.huge,-math.huge,-math.huge
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local p=camera:WorldToViewportPoint(cf:PointToWorldSpace(size*Vector3.new(x,y,z)/2))
			if p.Z<=0 then return end
			xmin,ymin,xmax,ymax=math.min(xmin,p.X),math.min(ymin,p.Y),math.max(xmax,p.X),math.max(ymax,p.Y)
		end end end
		return xmin,ymin,math.max(2,xmax-xmin),math.max(6,ymax-ymin)
	end
	local center=root.Position+Vector3.new(0,s.BoxYOffset,0)
	local top=camera:WorldToViewportPoint(center+Vector3.new(0,s.BoxHeight/2,0))
	local bottom=camera:WorldToViewportPoint(center-Vector3.new(0,s.BoxHeight/2,0))
	if top.Z<=0 or bottom.Z<=0 then return end
	local h=math.max(math.abs(bottom.Y-top.Y),6)
	local w=h*s.BoxWidthRatio
	return (top.X+bottom.X)/2-w/2,math.min(top.Y,bottom.Y),w,h
end
function ESP:_renderEntry(e,camera,dt,now)
	local s=self.Settings
	local target=e.Target
	local isPlayer=target:IsA("Player")
	local char=target
	if isPlayer then char=target.Character end
	local root=char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart or char:FindFirstChildWhichIsA("BasePart"))
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	local valid=char~=nil and char:IsDescendantOf(workspace) and root~=nil and (not hum or s.ShowDead or hum.Health>0)
	if target==Players.LocalPlayer and not s.ShowLocalPlayer then valid=false end
	if e.Options.Enabled==false then valid=false end
	if s.TeamCheck and isPlayer and target~=Players.LocalPlayer and target.Team and target.Team==Players.LocalPlayer.Team then valid=false end
	if valid and self.Filter then
		local ok,result=pcall(self.Filter,target,char)
		valid=ok and result~=false
	end
	local dist=valid and (camera.CFrame.Position-root.Position).Magnitude or 0
	valid=valid and dist<=s.MaxDistance
	if valid and s.VisibleOnly then
		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		local excluded={char,camera}
		if Players.LocalPlayer.Character then table.insert(excluded,Players.LocalPlayer.Character) end
		params.FilterDescendantsInstances=excluded
		valid=workspace:Raycast(camera.CFrame.Position,root.Position-camera.CFrame.Position,params)==nil
	end
	local x,y,w,h
	if valid then x,y,w,h=self:_bounds(camera,char,root) end
	local view=camera.ViewportSize
	local render=x~=nil and x+w>0 and x<view.X and y+h>0 and y<view.Y
	local alphaK=s.FadeSpeed==0 and 1 or 1-math.exp(-dt*s.FadeSpeed)
	e.Alpha+=((render and 1 or 0)-e.Alpha)*alphaK
	if render then e.X,e.Y,e.W,e.H,e.Distance=x,y,w,h,dist end
	if valid and (not e.RoleAt or now-e.RoleAt>=s.RoleInterval) then
		e.RoleAt=now
		local role=s.Roles and self:_role(target,char,e) or nil
		if role~=e.Role then
			local old=e.Role e.Role=role
			if self.OnRoleChanged then
				task.spawn(function()
					if self.Destroyed then return end
					local ok,err=pcall(self.OnRoleChanged,target,role,old)
					if not ok then warn("[RockESP OnRoleChanged] " .. tostring(err)) end
				end)
			end
		end
	end
	local fraction=hum and hum.MaxHealth>0 and math.clamp(hum.Health/hum.MaxHealth,0,1) or (hum and 0 or 1)
	local hpK=s.HealthSmoothing==0 and 1 or 1-math.exp(-dt*s.HealthSmoothing)
	e.HP+=(fraction-e.HP)*hpK
	local color=self:_color(e,now)
	local a=e.Alpha
	e.Highlight.Enabled=s.Chams and valid and (render or s.OffscreenChams)
	if e.Highlight.Enabled then
		e.Highlight.Adornee=char e.Highlight.DepthMode=Enum.HighlightDepthMode[s.DepthMode]
		e.Highlight.FillColor=color e.Highlight.OutlineColor=color
		local ha=s.OffscreenChams and 1 or a
		e.Highlight.FillTransparency=1-s.ChamsFill/100*0.85*ha
		e.Highlight.OutlineTransparency=1-s.ChamsOutlineOpacity*ha
	end
	if a<0.02 or not e.X then e.Root.Visible=false return end
	e.Root.Visible=true
	x,y,w,h=e.X,e.Y,e.W,e.H
	local right,bottom=x+w,y+h
	local fade,th=1-a,s.Thickness
	e.Fill.Visible=s.Box and s.BoxFill
	e.Fill.Position=UDim2.fromOffset(x,y) e.Fill.Size=UDim2.fromOffset(w,h)
	e.Fill.BackgroundColor3=color e.Fill.BackgroundTransparency=fade
	e.FillGradient.Transparency=NumberSequence.new(1,1-s.BoxFillOpacity)
	local cw,ch=math.max(w*s.CornerWidth,4),math.max(h*s.CornerHeight,4)
	local rects={{x,y,cw,th},{x,y,th,ch},{right-cw,y,cw,th},{right-th,y,th,ch},
		{x,bottom-th,cw,th},{x,bottom-ch,th,ch},{right-cw,bottom-th,cw,th},{right-th,bottom-ch,th,ch}}
	for i,c in ipairs(e.Corners) do
		c.Visible=s.Box and s.BoxStyle=="Corners"
		if c.Visible then
			local r=rects[i]
			c.Position=UDim2.fromOffset(r[1],r[2]) c.Size=UDim2.fromOffset(r[3],r[4])
			c.BackgroundColor3=color c.BackgroundTransparency=fade
			local outline=c:FindFirstChildOfClass("UIStroke")
			outline.Color=s.OutlineColor outline.Transparency=1-0.5*a
		end
	end
	e.Full.Visible=s.Box and s.BoxStyle=="Full" e.Shadow.Visible=e.Full.Visible
	e.Full.Position=UDim2.fromOffset(x,y) e.Full.Size=UDim2.fromOffset(w,h)
	e.Shadow.Position=e.Full.Position e.Shadow.Size=e.Full.Size
	e.FullStroke.Color=color e.FullStroke.Thickness=th e.FullStroke.Transparency=fade
	e.ShadowStroke.Color=s.OutlineColor e.ShadowStroke.Thickness=th+2 e.ShadowStroke.Transparency=1-0.5*a
	e.Name.Visible=s.Names
	local name=e.Options.Name or (isPlayer and (s.DisplayNames and target.DisplayName or target.Name) or target.Name)
	e.Name.Text=name e.Name.Position=UDim2.fromOffset(x+w/2,y-3)
	e.Name.TextSize=s.TextSize e.Name.Size=UDim2.fromOffset(math.max(260,w),s.TextSize+4)
	e.Name.TextColor3=color e.Name.TextTransparency=fade
	local roleText=s.Roles and s.RoleLabels and e.Role and string.upper(e.Role) or ""
	local distText=s.Distance and (tostring(math.floor(e.Distance*s.DistanceScale+0.5)) .. s.DistanceSuffix) or ""
	e.Info.Visible=roleText~="" or distText~=""
	e.Info.Text=roleText .. (roleText~="" and distText~="" and "  ·  " or "") .. distText
	e.Info.Position=UDim2.fromOffset(x+w/2,bottom+3) e.Info.TextSize=s.TextSize-1
	e.Info.Size=UDim2.fromOffset(math.max(260,w),s.TextSize+4)
	e.Info.TextColor3=roleText~="" and color or s.InfoColor e.Info.TextTransparency=fade
	for _,label in ipairs({e.Name,e.Info}) do
		label.TextStrokeColor3=s.OutlineColor
		label.TextStrokeTransparency=s.TextOutline and 1-s.TextOutlineOpacity*a or 1
	end
	e.HealthBackground.Visible=s.HealthBar
	e.HealthBackground.Position=UDim2.fromOffset(x-6,y-1) e.HealthBackground.Size=UDim2.fromOffset(4,h+2)
	e.HealthBackground.BackgroundTransparency=1-0.65*a
	e.HealthFill.Size=UDim2.new(0,2,0,math.max(0,h*math.clamp(e.HP,0,1)))
	e.HealthFill.BackgroundColor3=self:_healthColor(e.HP) e.HealthFill.BackgroundTransparency=fade
	e.Tracer.Visible=s.Tracers
	if s.Tracers then
		local from=Vector2.new(view.X/2,view.Y-2)
		if s.TracerFrom=="Center" then from=view/2
		elseif s.TracerFrom=="Top" then from=Vector2.new(view.X/2,2)
		elseif s.TracerFrom=="Mouse" then from=UIS:GetMouseLocation() end
		local to=Vector2.new(x+w/2,s.TracerTarget=="Top" and y or s.TracerTarget=="Center" and y+h/2 or bottom)
		placeLine(e.Tracer,from,to,th)
		e.Tracer.BackgroundColor3=color e.Tracer.BackgroundTransparency=1-s.TracerOpacity*a
		local outline=e.Tracer:FindFirstChildOfClass("UIStroke")
		outline.Color=s.OutlineColor outline.Transparency=1-0.5*a
	end
end
function ESP:Destroy()
	if self.Destroyed then return end
	self.Destroyed=true
	for _,c in ipairs(self._connections) do c:Disconnect() end
	table.clear(self._connections)
	if self._remoteThread and self._remoteThread~=coroutine.running() then pcall(task.cancel,self._remoteThread) end
	self:Clear() self.Gui:Destroy()
end
function RockESP.new(options)
	options=options or {}
	local self=setmetatable({Settings=copy(defaults),Entries={},_connections={},_roles={},Destroyed=false},ESP)
	for k,v in pairs(options.Settings or {}) do self.Settings[k]=validate(k,v) end
	self.RoleProvider=options.RoleProvider self.Filter=options.Filter self.OnRoleChanged=options.OnRoleChanged
	self.Gui=make("ScreenGui",{Name=options.Name or "RockESP",IgnoreGuiInset=true,ResetOnSpawn=false,
		DisplayOrder=options.DisplayOrder or -2,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Enabled=self.Settings.Enabled},
		options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui"))
	self.Chams=make("Folder",{Name="Chams"},self.Gui)
	self:_connect(self.Gui.Destroying,function() self:Destroy() end)
	if options.AutoPlayers~=false then
		for _,p in ipairs(Players:GetPlayers()) do self:Add(p) end
		self:_connect(Players.PlayerAdded,function(p) self:Add(p) end)
		self:_connect(Players.PlayerRemoving,function(p) self:Remove(p) end)
	end
	local elapsed=0
	self:_connect(RunService.RenderStepped,function(dt)
		if not self.Settings.Enabled then return end
		elapsed+=dt
		if self.Settings.UpdateRate>0 and elapsed<1/self.Settings.UpdateRate then return end
		local delta=elapsed elapsed=0
		local camera=workspace.CurrentCamera
		if not camera then for _,e in pairs(self.Entries) do self:_hide(e) end return end
		local now=os.clock()
		for _,e in pairs(self.Entries) do self:_renderEntry(e,camera,delta,now) end
	end)
	if options.RoleRemote or options.RoleRemoteName then
		self._remoteThread=task.spawn(function()
			local remote=options.RoleRemote
			while not self.Destroyed do
				if self.Settings.Enabled and self.Settings.Roles then
					if not remote or not remote.Parent then remote=options.RoleRemoteName and ReplicatedStorage:FindFirstChild(options.RoleRemoteName,true) end
					if remote and remote:IsA("RemoteFunction") then
						local ok,data=pcall(remote.InvokeServer,remote)
						if not self.Destroyed and ok and type(data)=="table" then self:SetRoles(data) end
					end
				end
				task.wait(self.Settings.RemoteInterval)
			end
		end)
	end
	return self
end

local function encode(value)
	if typeof(value)=="Color3" then return {Type="Color3",Hex=value:ToHex()} end
	if type(value)~="table" then return value end
	local out={} for k,v in pairs(value) do out[k]=encode(v) end return out
end
local function decode(value)
	if type(value)~="table" then return value end
	if value.Type=="Color3" then
		assert(type(value.Hex)=="string" and value.Hex:match("^%x%x%x%x%x%x$"),"Invalid saved color")
		return Color3.fromHex(value.Hex)
	end
	local out={} for k,v in pairs(value) do out[k]=decode(v) end return out
end
function ESP:ExportConfig() return HttpService:JSONEncode({Version=1,Settings=encode(self.Settings)}) end
function ESP:ImportConfig(json)
	local ok,err=pcall(function()
		local data=HttpService:JSONDecode(json)
		assert(type(data)=="table" and data.Version==1 and type(data.Settings)=="table","Unsupported ESP config")
		self:Configure(decode(data.Settings))
	end)
	return ok,not ok and tostring(err) or nil
end
return RockESP
