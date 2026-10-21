-- RockUI 1.1.0 | Client-side Roblox / Luau UI library with built-in Rock Hub watermark
-- Standalone ModuleScript or loadstring-compatible source. No external assets required.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local RockUI = { Version = "1.1.0" }
local createEmbeddedWatermark
local Window, Container, Control = {}, {}, {}
Window.__index, Container.__index, Control.__index = Window, Container, Control
local RGB = Color3.fromRGB
RockUI.Themes = {
	Dark = {
		Background = RGB(14,14,14), Panel = RGB(20,20,20), Element = RGB(27,27,27),
		Hover = RGB(36,36,36), Stroke = RGB(42,42,42), Text = RGB(230,230,230),
		Dim = RGB(120,120,120), Muted = RGB(85,85,85), Accent = RGB(255,255,255),
		Card = RGB(35,35,35), Footer = RGB(16,16,16), Success = RGB(105,208,145),
		Warning = RGB(255,198,62), Danger = RGB(240,94,110),
	},
	Light = {
		Background = RGB(242,243,246), Panel = RGB(255,255,255), Element = RGB(232,234,239),
		Hover = RGB(220,224,232), Stroke = RGB(205,210,219), Text = RGB(28,31,39),
		Dim = RGB(100,107,120), Muted = RGB(143,149,160), Accent = RGB(46,85,180),
		Card = RGB(227,230,237), Footer = RGB(250,251,253), Success = RGB(33,140,80),
		Warning = RGB(169,112,0), Danger = RGB(200,47,64),
	},
}
local function clone(value)
	if type(value) ~= "table" then return value end
	local result = {}
	for k,v in pairs(value) do result[k] = clone(v) end
	return result
end
local function scope(parent)
	local s = { alive = true, items = {} }
	function s:Add(item)
		if not self.alive then
			if typeof(item) == "RBXScriptConnection" then item:Disconnect()
			elseif type(item) == "function" then item()
			elseif item.Destroy then item:Destroy() end
		else self.items[item] = true end
		return item
	end
	function s:Connect(signal, fn)
		return self:Add(signal:Connect(function(...) if self.alive then fn(...) end end))
	end
	function s:Destroy()
		if not self.alive then return end
		self.alive = false
		if parent then parent.items[self] = nil end
		local items = self.items
		self.items = {}
		for item in pairs(items) do
			pcall(function()
				if typeof(item) == "RBXScriptConnection" then item:Disconnect()
				elseif type(item) == "function" then item()
				else item:Destroy() end
			end)
		end
		table.clear(items)
	end
	if parent then parent:Add(s) end
	return s
end
local function new(class, props, parent)
	local obj = Instance.new(class)
	if obj:IsA("GuiObject") then obj.BorderSizePixel = 0 end
	if obj:IsA("GuiButton") then obj.AutoButtonColor = false end
	for k,v in pairs(props or {}) do obj[k] = v end
	obj.Parent = parent
	return obj
end
local function corner(obj, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, obj)
end
local function padding(obj, amount)
	return new("UIPadding", { PaddingLeft=UDim.new(0,amount), PaddingRight=UDim.new(0,amount),
		PaddingTop=UDim.new(0,amount), PaddingBottom=UDim.new(0,amount) }, obj)
end
local function list(obj, gap, horizontal)
	return new("UIListLayout", { Padding=UDim.new(0,gap or 6), SortOrder=Enum.SortOrder.LayoutOrder,
		FillDirection=horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical }, obj)
end
local function image(value)
	if type(value) == "number" or (type(value) == "string" and value:match("^%d+$")) then
		return "rbxassetid://" .. tostring(value)
	end
	return value or ""
end
local function lower(value)
	local out = {}
	for _,code in utf8.codes(string.lower(tostring(value))) do
		if code >= 0x410 and code <= 0x42F then code += 32 elseif code == 0x401 then code = 0x451 end
		table.insert(out, utf8.char(code))
	end
	return table.concat(out)
end
local function contains(text, query)
	text = lower(text)
	for word in lower(query):gmatch("%S+") do if not text:find(word,1,true) then return false end end
	return true
end
local function enumKey(value)
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then return value end
	if type(value) == "string" then return Enum.KeyCode[value] end
	return nil
end
local function call(fn, ...)
	if type(fn) ~= "function" then return end
	local args = table.pack(...)
	task.spawn(function()
		local ok,err = pcall(fn, table.unpack(args,1,args.n))
		if not ok then warn("[RockUI callback] " .. tostring(err)) end
	end)
end
function Window:_bind(obj, prop, token, owner)
	for old in pairs(self._bindings) do
		if old.object==obj and old.property==prop then self._bindings[old]=nil end
	end
	local record = { object=obj, property=prop, token=token }
	self._bindings[record] = true
	obj[prop] = type(token) == "function" and token(self.Theme) or self.Theme[token]
	local bindingScope = owner or self._scope
	bindingScope:Add(function() self._bindings[record] = nil end)
	return obj
end
function Window:_paint(obj, prop, token, owner)
	return self:_bind(obj,prop,token,owner)
end
function Window:_frame(parent, props, token, owner)
	local obj = new("Frame", props, parent)
	if token then self:_bind(obj,"BackgroundColor3",token,owner) end
	return obj
end
function Window:_text(parent, text, props, token, owner)
	local p = { Text=tostring(text or ""), Font=Enum.Font.Gotham, TextSize=12,
		BackgroundTransparency=1, TextXAlignment=Enum.TextXAlignment.Left,
		TextTruncate=Enum.TextTruncate.AtEnd, Size=UDim2.new(1,0,0,20) }
	for k,v in pairs(props or {}) do p[k] = v end
	local obj = new("TextLabel",p,parent)
	self:_bind(obj,"TextColor3",token or "Text",owner)
	return obj
end
function Window:_button(parent, text, props, owner)
	local p = { Text=text or "", Font=Enum.Font.GothamMedium, TextSize=12, TextTruncate=Enum.TextTruncate.AtEnd, Size=UDim2.fromOffset(90,28) }
	for k,v in pairs(props or {}) do p[k] = v end
	local obj = new("TextButton",p,parent)
	self:_bind(obj,"BackgroundColor3","Element",owner)
	self:_bind(obj,"TextColor3","Text",owner)
	corner(obj,self.Radius)
	local s = owner or self._scope
	s:Connect(obj.MouseEnter,function() if not obj:GetAttribute("RockUIStaticColor") then self:_tween(obj,{BackgroundColor3=self.Theme.Hover}) end end)
	s:Connect(obj.MouseLeave,function() if not obj:GetAttribute("RockUIStaticColor") then self:_tween(obj,{BackgroundColor3=self.Theme.Element}) end end)
	return obj
end
function Window:_stroke(obj, token, owner)
	local st = new("UIStroke",{Thickness=1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},obj)
	self:_bind(st,"Color",token or "Stroke",owner)
	return st
end
function Window:_input(parent, placeholder, props, owner)
	local p = { Text="", PlaceholderText=placeholder or "", ClearTextOnFocus=false,
		Font=Enum.Font.Gotham, TextSize=12, TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.new(1,0,0,28) }
	for k,v in pairs(props or {}) do p[k] = v end
	local box = new("TextBox",p,parent)
	self:_bind(box,"BackgroundColor3","Element",owner)
	self:_bind(box,"TextColor3","Text",owner)
	self:_bind(box,"PlaceholderColor3","Muted",owner)
	corner(box,self.Radius)
	local pad = padding(box,8)
	pad.PaddingTop, pad.PaddingBottom = UDim.new(), UDim.new()
	self:_stroke(box,"Stroke",owner)
	return box
end
function Window:_scroll(parent, props, owner)
	local p = { BackgroundTransparency=1, Size=UDim2.fromScale(1,1), CanvasSize=UDim2.new(),
		AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=3,
		ScrollingDirection=Enum.ScrollingDirection.Y, ElasticBehavior=Enum.ElasticBehavior.Never }
	for k,v in pairs(props or {}) do p[k] = v end
	local obj = new("ScrollingFrame",p,parent)
	self:_bind(obj,"ScrollBarImageColor3","Dim",owner)
	return obj
end
function Window:_tween(obj, props)
	if not self._scope.alive or not obj.Parent then return end
	if self.ReducedMotion then for k,v in pairs(props) do obj[k] = v end return end
	TweenService:Create(obj,TweenInfo.new(self.AnimationSpeed,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),props):Play()
end
function Window:SetTheme(theme)
	if type(theme) == "string" then theme = assert(RockUI.Themes[theme],"Unknown theme") end
	assert(type(theme) == "table","Theme must be a name or table")
	for k,v in pairs(theme) do
		assert(RockUI.Themes.Dark[k] and typeof(v)=="Color3","Invalid theme token: " .. tostring(k))
	end
	for k,v in pairs(theme) do self.Theme[k] = v end
	for b in pairs(self._bindings) do
		if b.object.Parent then
			b.object[b.property] = type(b.token)=="function" and b.token(self.Theme) or self.Theme[b.token]
		end
	end
	if self.Watermark and not self.Watermark.Destroyed then
		self.Watermark:_updateStatLabels()
		self.Watermark:_refreshMenuButton()
	end
	return self
end
function Window:GetTheme() return clone(self.Theme) end
function Window:SetVisible(visible)
	self.Visible = visible == true
	self.Root.Visible = self.Visible
	if not self.Visible then self:_closePopup() end
	if self.Watermark and not self.Watermark.Destroyed then self.Watermark:SetMenuOpen(self.Visible,true) end
	return self
end
function Window:Toggle() return self:SetVisible(not self.Visible) end
function Window:SetToggleKey(key)
	self.ToggleKey = assert(enumKey(key),"Invalid key")
	if self.Watermark and not self.Watermark.Destroyed then
		self.Watermark.ToggleKey = self.ToggleKey
		if self.Watermark._tipShown then self.Watermark:ShowTip(true) end
	end
	return self
end
function Window:SetWatermarkVisible(visible)
	if visible and (not self.Watermark or self.Watermark.Destroyed) then
		self.Watermark = createEmbeddedWatermark(self,{})
	end
	if self.Watermark and not self.Watermark.Destroyed then self.Watermark:SetVisible(visible) end
	return self
end
function Window:SetScale(scale)
	assert(type(scale)=="number" and scale>0,"Scale must be positive")
	self.Scale = scale
	self:_fit()
	return self
end
function Window:SetSize(size)
	assert(typeof(size)=="Vector2","Size must be Vector2")
	self.Size = Vector2.new(math.max(self.MinSize.X,size.X),math.max(self.MinSize.Y,size.Y))
	self.Root.Size = UDim2.fromOffset(self.Size.X,self.Size.Y)
	self:_fit()
	return self
end
function Window:_fit()
	local view = self.Gui.AbsoluteSize
	if view.X <= 0 or view.Y <= 0 then return end
	self.UIScale.Scale = math.min(self.Scale,(view.X-16)/self.Size.X,(view.Y-16)/self.Size.Y)
	local p = self.Root.Position
	local x,y = p.X.Scale*view.X+p.X.Offset,p.Y.Scale*view.Y+p.Y.Offset
	local half = self.Size*self.UIScale.Scale/2
	self.Root.Position = UDim2.fromOffset(math.clamp(x,half.X+4,math.max(half.X+4,view.X-half.X-4)),
		math.clamp(y,half.Y+4,math.max(half.Y+4,view.Y-half.Y-4)))
end
function Window:_point(position)
	local inset = self.Gui.IgnoreGuiInset and Vector2.zero or GuiService:GetGuiInset()
	return Vector2.new(position.X,position.Y)-inset
end
function Window:_drag(handle, update, owner, begin, finish)
	local s = owner or self._scope
	local active, touch
	s:Connect(handle.InputBegan,function(input)
		if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		active,touch = true,input.UserInputType==Enum.UserInputType.Touch and input or nil
		local p = self:_point(input.Position)
		if begin then begin(p) end
		update(p)
	end)
	s:Connect(UIS.InputChanged,function(input)
		if active and ((touch and input==touch) or (not touch and input.UserInputType==Enum.UserInputType.MouseMovement)) then
			update(self:_point(input.Position))
		end
	end)
	s:Connect(UIS.InputEnded,function(input)
		if active and (input==touch or (not touch and input.UserInputType==Enum.UserInputType.MouseButton1)) then
			active,touch = false,nil
			if finish then finish() end
		end
	end)
end
function Window:_closePopup()
	if self._popup then self._popup:Destroy() self._popup=nil end
end
function Window:_popupAt(anchor, width, height, owner, centered)
	self:_closePopup()
	local s = scope(owner or self._scope)
	self._popup = s
	local blocker = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=100},self.Gui)
	s:Add(blocker)
	local panel = self:_frame(blocker,{Size=UDim2.fromOffset(width,height),ZIndex=101,ClipsDescendants=true},"Panel",s)
	corner(panel,self.Radius)
	self:_stroke(panel,"Stroke",s)
	local function position()
		local view = self.Gui.AbsoluteSize
		local w,h = math.min(width,math.max(100,view.X-16)),math.min(height,math.max(80,view.Y-16))
		panel.Size = UDim2.fromOffset(w,h)
		if centered then panel.Position=UDim2.fromOffset((view.X-w)/2,(view.Y-h)/2) return end
		local a,as = anchor.AbsolutePosition,anchor.AbsoluteSize
		local y = a.Y+as.Y+6
		if y+h>view.Y-8 then y=a.Y-h-6 end
		panel.Position=UDim2.fromOffset(math.clamp(a.X,8,math.max(8,view.X-w-8)),math.clamp(y,8,math.max(8,view.Y-h-8)))
	end
	position()
	s:Connect(anchor:GetPropertyChangedSignal("AbsolutePosition"),position)
	s:Connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"),position)
	s:Connect(blocker.Activated,function() self:_closePopup() end)
	-- A panel button consumes clicks inside the popup instead of the outside blocker.
	local shield = new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=101},panel)
	return panel,s
end
function Window:Destroy()
	if not self._scope.alive then return end
	self:_closePopup()
	self._scope:Destroy()
	table.clear(self.Flags)
	table.clear(self.Controls)
	call(self.OnDestroy)
end

function RockUI:CreateWindow(options)
	options=options or {}
	local self=setmetatable({},Window)
	self._scope=scope()
	self._bindings={}
	self.Theme=clone(RockUI.Themes.Dark)
	self.Flags,self.Controls,self.Tabs={},{},{}
	self.Size=options.Size or Vector2.new(760,530)
	self.MinSize=options.MinSize or Vector2.new(480,350)
	self.Scale=options.Scale or 1
	self.Radius=options.Radius or 8
	self.AnimationSpeed=options.AnimationSpeed or 0.2
	self.ReducedMotion=options.ReducedMotion==true
	self.ToggleKey=enumKey(options.ToggleKey) or Enum.KeyCode.RightShift
	self.Visible=options.Visible~=false
	self.OnDestroy=options.OnDestroy
	self.Storage=options.Storage
	if options.Theme then self:SetTheme(options.Theme) end
	local parent=options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
	self.Gui=new("ScreenGui",{Name=options.Name or "RockUI",ResetOnSpawn=false,IgnoreGuiInset=true,
		ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=options.DisplayOrder or 50},parent)
	self._scope:Add(self.Gui)
	self.Root=self:_frame(self.Gui,{Name="Window",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
		Size=UDim2.fromOffset(self.Size.X,self.Size.Y),Visible=self.Visible,ClipsDescendants=true},"Background")
	corner(self.Root,self.Radius+3)
	self:_stroke(self.Root)
	self.UIScale=new("UIScale",{Scale=self.Scale},self.Root)
	local top=self:_frame(self.Root,{Size=UDim2.new(1,0,0,48)},"Panel")
	local title=self:_text(top,options.Title or "Rock UI",{Position=UDim2.fromOffset(16,8),Size=UDim2.new(1,-100,0,19),Font=Enum.Font.GothamBold,TextSize=15},"Text")
	self.TitleLabel=title
	self:_text(top,options.Subtitle or "",{Position=UDim2.fromOffset(16,27),Size=UDim2.new(1,-100,0,14),TextSize=10},"Dim")
	local close=self:_button(top,"×",{Position=UDim2.new(1,-36,0,10),Size=UDim2.fromOffset(26,26),TextSize=19})
	self._scope:Connect(close.Activated,function() self:SetVisible(false) end)
	local sidebar=self:_frame(self.Root,{Position=UDim2.fromOffset(0,48),Size=UDim2.new(0,158,1,-48)},"Panel")
	self.TabList=self:_scroll(sidebar,{Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,1,-20)})
	list(self.TabList,5)
	self.Content=self:_frame(self.Root,{Position=UDim2.fromOffset(170,60),Size=UDim2.new(1,-182,1,-72),BackgroundTransparency=1})
	local start,origin
	self:_drag(title,function(p)
		local d=p-start
		self.Root.Position=UDim2.fromOffset(origin.X+d.X,origin.Y+d.Y)
		self:_fit()
	end,nil,function(p)
		start=p
		origin=self.Root.AbsolutePosition+self.Root.AbsoluteSize/2
	end)
	if options.Resizable~=false then
		local grip=self:_button(self.Root,"◢",{AnchorPoint=Vector2.new(1,1),Position=UDim2.fromScale(1,1),Size=UDim2.fromOffset(18,18),BackgroundTransparency=1,TextSize=12,ZIndex=10})
		local p0,size0
		self:_drag(grip,function(p)
			local delta=(p-p0)/self.UIScale.Scale
			self:SetSize(size0+delta*2)
		end,nil,function(p) p0,size0=p,self.Size end)
	end
	self._scope:Connect(UIS.InputBegan,function(input,processed)
		if input.UserInputType~=Enum.UserInputType.Keyboard then return end
		if self._capture then
			local capture=self._capture
			self._capture=nil
			self._capturedInput=input
			capture(input.KeyCode)
			return
		end
		if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==self.ToggleKey then self:Toggle() end
	end)
	self._scope:Connect(self.Gui:GetPropertyChangedSignal("AbsoluteSize"),function() self:_fit() end)
	self._scope:Connect(self.Gui.Destroying,function() if self._scope.alive then self:Destroy() end end)
	self:SetSize(self.Size)
	if options.Watermark~=false then
		assert(options.Watermark==nil or options.Watermark==true or type(options.Watermark)=="table","Watermark must be boolean or table")
		self.Watermark=createEmbeddedWatermark(self,type(options.Watermark)=="table" and options.Watermark or {})
	end
	return self
end

function Window:SetTitle(text) self.TitleLabel.Text=tostring(text) return self end
function Window:AddSeparator(text)
	local holder=self:_frame(self.TabList,{Size=UDim2.new(1,-3,0,text and 22 or 10),BackgroundTransparency=1,LayoutOrder=#self.TabList:GetChildren()})
	if text then self:_text(holder,string.upper(text),{TextSize=10,Font=Enum.Font.GothamBold},"Muted")
	else self:_frame(holder,{Position=UDim2.fromOffset(0,4),Size=UDim2.new(1,0,0,1)},"Stroke") end
	return holder
end
function Window:AddTab(options)
	if type(options)=="string" then options={Name=options} end
	options=options or {}
	local tab=setmetatable({Window=self,Name=options.Name or "Tab",Children={},Controls={},_scope=scope(self._scope),_visible=true},Container)
	tab.Button=self:_button(self.TabList,tab.Name,{Size=UDim2.new(1,-3,0,32),LayoutOrder=#self.TabList:GetChildren(),TextXAlignment=Enum.TextXAlignment.Left},tab._scope)
	padding(tab.Button,10)
	if options.Icon then
		new("ImageLabel",{Image=image(options.Icon),BackgroundTransparency=1,Size=UDim2.fromOffset(16,16),Position=UDim2.new(0,0,0.5,-8)},tab.Button)
		tab.Button.Text="      " .. tab.Name
	end
	self:_bind(tab.Button,"TextColor3",function(t) return self.ActiveTab==tab and t.Accent or t.Dim end,tab._scope)
	tab.Frame=self:_frame(self.Content,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
	tab._scope:Add(tab.Frame)
	tab._scope:Add(tab.Button)
	self:_text(tab.Frame,tab.Name,{TextSize=18,Font=Enum.Font.GothamBold,Size=UDim2.new(1,0,0,24)},"Accent",tab._scope)
	self:_text(tab.Frame,options.Description or "",{Position=UDim2.fromOffset(0,25),Size=UDim2.new(1,0,0,18)},"Dim",tab._scope)
	tab.Body=self:_scroll(tab.Frame,{Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-48)},tab._scope)
	padding(tab.Body,2)
	list(tab.Body,10)
	tab._scope:Connect(tab.Button.Activated,function() tab:Select() end)
	table.insert(self.Tabs,tab)
	if not self.ActiveTab then tab:Select() end
	return tab
end
function Container:Select()
	local w=self.Window
	if self.IsSubTab then
		self.Parent.ActiveSubTab=self
		for _,sub in ipairs(self.Parent.SubTabs) do
			sub.Frame.Visible=sub==self
			sub.Button.Text=(sub==self and "● " or "") .. sub.Name
		end
	else
		w.ActiveTab=self
		for _,tab in ipairs(w.Tabs) do
			tab.Frame.Visible=tab==self and tab._visible
			tab.Button.TextColor3=tab==self and w.Theme.Accent or w.Theme.Dim
		end
		w:_closePopup()
	end
	return self
end
function Container:AddSubTab(options)
	assert(not self.IsSection and not self.IsSubTab,"Subtabs can only be added to a tab")
	if type(options)=="string" then options={Name=options} end
	options=options or {}
	local w=self.Window
	if not self.SubTabs then
		assert(#self.Children==0 and #self.Controls==0,"Add subtabs before adding tab content")
		self.SubTabs={}
		self.Body:Destroy()
		self.SubBar=w:_frame(self.Frame,{Position=UDim2.fromOffset(0,47),Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
		list(self.SubBar,5,true)
	end
	local sub=setmetatable({Window=w,Parent=self,Name=options.Name or "Subtab",Children={},Controls={},IsSubTab=true,_scope=scope(self._scope),_visible=true},Container)
	sub.Button=w:_button(self.SubBar,sub.Name,{AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,28),LayoutOrder=#self.SubTabs+1},sub._scope)
	padding(sub.Button,10)
	sub.Frame=w:_frame(self.Frame,{Position=UDim2.fromOffset(0,85),Size=UDim2.new(1,0,1,-85),BackgroundTransparency=1,Visible=false})
	sub._scope:Add(sub.Frame)
	sub._scope:Add(sub.Button)
	sub.Body=w:_scroll(sub.Frame,nil,sub._scope)
	padding(sub.Body,2)
	list(sub.Body,10)
	sub._scope:Connect(sub.Button.Activated,function() sub:Select() end)
	table.insert(self.SubTabs,sub)
	if #self.SubTabs==1 then sub:Select() end
	return sub
end
function Container:AddSection(options)
	assert(not self.SubTabs,"Add content to a subtab")
	if type(options)=="string" then options={Name=options} end
	options=options or {}
	local w=self.Window
	local section=setmetatable({Window=w,Parent=self,Children={},Controls={},IsSection=true,Name=options.Name or "Section",_scope=scope(self._scope),_visible=true},Container)
	section.Frame=w:_frame(self.Body,{Size=UDim2.new(1,-6,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=#self.Children+#self.Controls+1},"Panel",section._scope)
	section._scope:Add(section.Frame)
	corner(section.Frame,w.Radius+2)
	w:_stroke(section.Frame,"Stroke",section._scope)
	padding(section.Frame,8)
	list(section.Frame,6)
	local header=w:_button(section.Frame,string.upper(section.Name),{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0},section._scope)
	section.Body=w:_frame(section.Frame,{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,LayoutOrder=1})
	list(section.Body,6)
	section.Collapsed=options.Collapsed==true
	section.Body.Visible=not section.Collapsed
	function section:SetCollapsed(value)
		self.Collapsed=value==true self.Body.Visible=not self.Collapsed
		w:_closePopup()
		return self
	end
	if options.Collapsible~=false then section._scope:Connect(header.Activated,function() section:SetCollapsed(not section.Collapsed) end) end
	table.insert(self.Children,section)
	return section
end
function Container:SetVisible(value)
	self._visible=value==true
	if self.Button then self.Button.Visible=self._visible end
	self.Frame.Visible=self._visible and (self.IsSection or self.IsSubTab and self.Parent.ActiveSubTab==self or self.Window.ActiveTab==self)
	return self
end
function Container:Destroy()
	for _,child in ipairs(self.Children) do child:Destroy() end
	for _,control in ipairs(self.Controls) do control:Destroy() end
	for _,sub in ipairs(self.SubTabs or {}) do sub:Destroy() end
	self._scope:Destroy()
	local w=self.Window
	if w.ActiveTab==self then
		w.ActiveTab=nil
		for _,tab in ipairs(w.Tabs) do if tab~=self and tab._scope.alive then tab:Select() break end end
	end
end
function Container:Search(query)
	for _,control in ipairs(self.Controls) do
		control.Row.Visible=control._visible and contains(control.Name .. " " .. (control.Options.Description or ""),query or "")
	end
	for _,child in ipairs(self.Children) do child:Search(query) end
	return self
end

function Container:_control(kind, options, height)
	assert(not self.SubTabs,"Add content to a subtab")
	options=options or {}
	local w=self.Window
	local c=setmetatable({Window=w,Container=self,Kind=kind,Options=options,Name=options.Name or kind,
		_scope=scope(self._scope),_visible=options.Visible~=false,Disabled=options.Disabled==true,Listeners={}},Control)
	if options.Flag then assert(not w.Controls[options.Flag],"Duplicate flag: " .. options.Flag) end
	c.Row=w:_frame(self.Body,{Size=UDim2.new(1,-6,0,height or (options.Description and 54 or 38)),
		LayoutOrder=#self.Controls+#self.Children+1,Visible=c._visible},"Element",c._scope)
	c._scope:Add(c.Row)
	corner(c.Row,w.Radius)
	c.Label=w:_text(c.Row,c.Name,{Position=UDim2.fromOffset(10,options.Description and 7 or 0),
		Size=UDim2.new(0.53,-14,options.Description and 0 or 1,options.Description and 19 or 0),Font=Enum.Font.GothamMedium},"Text",c._scope)
	if options.Description then c.Description=w:_text(c.Row,options.Description,{Position=UDim2.fromOffset(10,28),Size=UDim2.new(0.53,-14,0,16),TextSize=10},"Dim",c._scope) end
	c.Area=w:_frame(c.Row,{Position=UDim2.new(0.53,0,0,6),Size=UDim2.new(0.47,-10,1,-12),BackgroundTransparency=1})
	if options.Flag then w.Controls[options.Flag]=c c.Flag=options.Flag end
	table.insert(self.Controls,c)
	if options.Tooltip then c:SetTooltip(options.Tooltip) end
	return c
end
function Control:_emit(silent)
	if self.Flag then self.Window.Flags[self.Flag]=clone(self.Value) end
	if silent then return end
	call(self.Options.Callback,self:Get(),self)
	for _,fn in pairs(self.Listeners) do call(fn,self:Get(),self) end
end
function Control:Get() return clone(self.Value) end
function Control:OnChanged(fn)
	assert(type(fn)=="function","Listener must be a function")
	local token={}
	self.Listeners[token]=fn
	return function() self.Listeners[token]=nil end
end
function Control:Set(value, silent)
	if self._validate then value=self._validate(value) end
	self.Value=clone(value)
	if self._render then self._render() end
	self:_emit(silent)
	return self
end
function Control:Reset(silent) return self:Set(clone(self.Default),silent) end
function Control:_init(value)
	self.Default=clone(value)
	self:Set(value,true)
	return self
end
function Control:SetVisible(value) self._visible=value==true self.Row.Visible=self._visible return self end
function Control:SetDisabled(value)
	self.Disabled=value==true
	self.Label.TextTransparency=self.Disabled and 0.5 or 0
	return self
end
function Control:SetName(name) self.Name=tostring(name) self.Label.Text=self.Name return self end
function Control:SetDescription(text)
	if self.Description then self.Description.Text=tostring(text) end
	self.Options.Description=tostring(text)
	return self
end
function Control:SetTooltip(text)
	self.Options.Tooltip=tostring(text)
	if self._tooltipBound then return self end
	self._tooltipBound=true
	local w=self.Window
	local tip,tipScope
	local function hide() if tipScope then tipScope:Destroy() tipScope=nil tip=nil end end
	self._scope:Add(hide)
	self._scope:Connect(self.Row.MouseEnter,function()
		hide()
		tipScope=scope(self._scope)
		tip=w:_frame(w.Gui,{Size=UDim2.fromOffset(260,50),ZIndex=200},"Panel",tipScope)
		tipScope:Add(tip)
		corner(tip,w.Radius)
		w:_text(tip,self.Options.Tooltip,{Position=UDim2.fromOffset(8,6),Size=UDim2.new(1,-16,1,-12),TextWrapped=true,TextTruncate=Enum.TextTruncate.None,ZIndex=201},"Text",tipScope)
		local p=self.Row.AbsolutePosition
		local v=w.Gui.AbsoluteSize
		tip.Position=UDim2.fromOffset(math.clamp(p.X,4,math.max(4,v.X-264)),math.clamp(p.Y-54,4,math.max(4,v.Y-54)))
	end)
	self._scope:Connect(self.Row.MouseLeave,hide)
	return self
end
function Control:Destroy()
	if not self._scope.alive then return end
	if self.Flag then self.Window.Controls[self.Flag]=nil self.Window.Flags[self.Flag]=nil end
	table.clear(self.Listeners)
	self._scope:Destroy()
end
function Container:AddToggle(options)
	local c=self:_control("Toggle",options)
	local w=c.Window
	local hit=w:_button(c.Area,"",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.fromScale(1,0.5),Size=UDim2.fromOffset(32,18)},c._scope)
	hit:SetAttribute("RockUIStaticColor",true)
	corner(hit,20)
	local knob=w:_frame(hit,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(12,12)},nil,c._scope)
	corner(knob,20)
	w:_bind(hit,"BackgroundColor3",function(t) return c.Value and t.Accent or t.Background end,c._scope)
	w:_bind(knob,"BackgroundColor3",function(t) return c.Value and t.Background or t.Dim end,c._scope)
	c._validate=function(v) assert(type(v)=="boolean","Toggle expects boolean") return v end
	c._render=function()
		w:_tween(hit,{BackgroundColor3=c.Value and w.Theme.Accent or w.Theme.Background})
		w:_tween(knob,{Position=UDim2.new(0,c.Value and 23 or 9,0.5,0),BackgroundColor3=c.Value and w.Theme.Background or w.Theme.Dim})
	end
	c._scope:Connect(hit.Activated,function() if not c.Disabled then c:Set(not c.Value) end end)
	return c:_init(options.Default==true)
end
function Container:AddButton(options)
	local c=self:_control("Button",options)
	local b=c.Window:_button(c.Area,options.Text or "Run",{Size=UDim2.fromScale(1,1)},c._scope)
	function c:Press() if not self.Disabled then call(self.Options.Callback,self) end return self end
	c._scope:Connect(b.Activated,function() c:Press() end)
	return c
end
function Container:AddLabel(options)
	if type(options)=="string" then options={Name=options} end
	local c=self:_control("Label",options,options.Height or 34)
	c.Area:Destroy()
	c.Label.Size=UDim2.new(1,-20,1,0)
	c.Label.TextWrapped=true
	c.Label.TextTruncate=Enum.TextTruncate.None
	function c:Set(text) return self:SetName(text) end
	return c
end
function Container:AddParagraph(options)
	local c=self:_control("Paragraph",options,options.Height or 86)
	c.Area:Destroy()
	c.Label.Size=UDim2.new(1,-20,0,20)
	if c.Description then
		c.Description.Size=UDim2.new(1,-20,1,-34)
		c.Description.TextWrapped=true
		c.Description.TextTruncate=Enum.TextTruncate.None
		c.Description.TextYAlignment=Enum.TextYAlignment.Top
	end
	return c
end
function Container:AddInput(options)
	local c=self:_control("Input",options)
	local box=c.Window:_input(c.Area,options.Placeholder or "Enter text...",{Size=UDim2.fromScale(1,1)},c._scope)
	c.Input=box
	c._validate=function(v)
		assert(type(v)=="string","Input expects string")
		if options.MaxLength then
			local index=utf8.offset(v,options.MaxLength+1)
			if index then v=v:sub(1,index-1) end
		end
		if options.Numeric then assert(tonumber(v),"Input expects a number") end
		return v
	end
	c._render=function() box.Text=c.Value end
	local function commit()
		if c.Disabled then box.Text=c.Value return end
		local ok,value=pcall(c._validate,box.Text)
		if ok then c:Set(value) else box.Text=c.Value end
	end
	c._scope:Connect(box.FocusLost,commit)
	if options.Live then c._scope:Connect(box:GetPropertyChangedSignal("Text"),function() if box:IsFocused() then commit() end end) end
	return c:_init(tostring(options.Default or (options.Numeric and "0" or "")))
end
function Container:AddSlider(options)
	local c=self:_control("Slider",options,62)
	local w=c.Window
	local min,max,step=options.Min or 0,options.Max or 100,options.Step or 1
	assert(max>min and step>0,"Slider requires Max > Min and Step > 0")
	c.Label.Position=UDim2.fromOffset(10,3)
	c.Label.Size=UDim2.new(0.55,-10,0,21)
	if c.Description then c.Description.Visible=false end
	c.Area.Position=UDim2.new(1,-100,0,3) c.Area.Size=UDim2.fromOffset(90,23)
	local valueBox=w:_input(c.Area,"",{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Right},c._scope)
	local track=w:_frame(c.Row,{Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-24,0,5),Active=true},"Background",c._scope)
	corner(track,10)
	local fill=w:_frame(track,{Size=UDim2.fromScale(0,1)},"Accent",c._scope) corner(fill,10)
	local knob=w:_frame(track,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0,0.5),Size=UDim2.fromOffset(11,11)},"Accent",c._scope) corner(knob,20)
	local hit=new("TextButton",{Text="",BackgroundTransparency=1,Position=UDim2.fromOffset(0,-10),Size=UDim2.new(1,0,0,25)},track)
	c._validate=function(v)
		assert(type(v)=="number" and v==v and math.abs(v)<math.huge,"Slider expects finite number")
		return math.clamp(min+math.floor((v-min)/step+0.5)*step,min,max)
	end
	c._render=function()
		local ratio=(c.Value-min)/(max-min)
		fill.Size=UDim2.fromScale(ratio,1) knob.Position=UDim2.fromScale(ratio,0.5)
		valueBox.Text=string.format("%.6g",c.Value) .. (options.Suffix or "")
	end
	w:_drag(hit,function(p)
		if c.Disabled then return end
		local ratio=math.clamp((p.X-track.AbsolutePosition.X)/math.max(1,track.AbsoluteSize.X),0,1)
		local value=c._validate(min+(max-min)*ratio)
		if value~=c.Value then c:Set(value) end
	end,c._scope)
	c._scope:Connect(valueBox.FocusLost,function()
		local value=tonumber(valueBox.Text:match("^[%s]*([%+%-]?[%d%.]+)"))
		if not c.Disabled and value then c:Set(value) else c._render() end
	end)
	return c:_init(options.Default or min)
end

local function normalizeOptions(values)
	local result,seen={},{}
	for _,v in ipairs(values or {}) do
		local item
		if type(v)=="table" then item=clone(v) else item={Id=tostring(v),Name=tostring(v)} end
		item.Id=item.Id or item.Value or item.Name
		assert(type(item.Id)=="string" or type(item.Id)=="number","Option needs a string/number Id")
		assert(not seen[item.Id],"Duplicate option Id: " .. tostring(item.Id))
		seen[item.Id]=true
		item.Name=tostring(item.Name or item.Id)
		table.insert(result,item)
	end
	return result
end
local function findOption(values,id)
	for _,v in ipairs(values) do if v.Id==id then return v end end
end
local function setupSelection(c,options)
	c.Items=normalizeOptions(options.Options or options.Items)
	c.Multi=options.Multi==true
	c._validate=function(value)
		if c.Multi then
			assert(type(value)=="table","Multi selection expects an array")
			local out,seen={},{}
			for _,id in ipairs(value) do
				assert(findOption(c.Items,id),"Unknown option: " .. tostring(id))
				if not seen[id] then table.insert(out,id) seen[id]=true end
			end
			return out
		end
		assert(value==nil or findOption(c.Items,value),"Unknown option: " .. tostring(value))
		return value
	end
	function c:IsSelected(id) return self.Multi and table.find(self.Value or {},id)~=nil or not self.Multi and self.Value==id end
	function c:Choose(id)
		if self.Disabled then return self end
		local item=findOption(self.Items,id)
		if not item or item.Disabled then return self end
		if self.Multi then
			local values=self:Get()
			local index=table.find(values,id)
			if index then table.remove(values,index) else table.insert(values,id) end
			self:Set(values)
		elseif self.Value==id and options.AllowNone~=false then self:Set(nil)
		else self:Set(id) end
		return self
	end
	function c:Clear(silent) return self:Set(self.Multi and {} or nil,silent) end
	function c:GetSelectedOptions()
		local out={}
		for _,item in ipairs(self.Items) do if self:IsSelected(item.Id) then table.insert(out,clone(item)) end end
		return out
	end
	function c:SetOptions(values, silent)
		local nextItems=normalizeOptions(values)
		self.Items=nextItems
		local value=self:Get()
		if self.Multi then
			local kept={}
			for _,id in ipairs(value or {}) do if findOption(self.Items,id) then table.insert(kept,id) end end
			value=kept
		elseif not findOption(self.Items,value) then value=nil end
		self:Set(value,silent)
		if self._rebuild then self._rebuild() end
		return self
	end
end
function Window:_preview(parent,item,props,owner)
	props=props or {}
	if item.Model then
		local viewport=new("ViewportFrame",{BackgroundTransparency=1,Size=props.Size or UDim2.fromScale(1,1),
			Position=props.Position or UDim2.new(),ZIndex=props.ZIndex or 1,Ambient=RGB(200,200,200),LightColor=RGB(255,255,255)},parent)
		local world=new("WorldModel",{},viewport)
		local model=item.Model:Clone()
		assert(model,"Preview Model must be Archivable")
		model.Parent=world
		for _,part in ipairs(world:GetDescendants()) do if part:IsA("BasePart") then part.Anchored=true end end
		local cf,size
		if model:IsA("Model") then cf,size=model:GetBoundingBox()
		elseif model:IsA("BasePart") then cf,size=model.CFrame,model.Size
		else error("Preview Model must be a Model or BasePart") end
		local camera=new("Camera",{FieldOfView=35},viewport)
		viewport.CurrentCamera=camera
		local function fitCamera()
			local aspect=viewport.AbsoluteSize.X/math.max(1,viewport.AbsoluteSize.Y)
			local radius=size.Magnitude/2
			local distance=radius/math.sin(math.rad(17.5)*math.min(1,aspect))*1.12
			camera.CFrame=item.CameraCFrame or CFrame.lookAt(cf.Position+Vector3.new(0,0,math.max(1,distance)),cf.Position)
		end
		fitCamera()
		owner:Connect(viewport:GetPropertyChangedSignal("AbsoluteSize"),fitCamera)
		return viewport
	end
	return new("ImageLabel",{BackgroundTransparency=1,Image=image(item.Image or item.Preview),ScaleType=Enum.ScaleType.Fit,
		Size=props.Size or UDim2.fromScale(1,1),Position=props.Position or UDim2.new(),ZIndex=props.ZIndex or 1},parent)
end
function Container:AddDropdown(options)
	local c=self:_control("Dropdown",options)
	local w=c.Window
	setupSelection(c,options)
	local button=w:_button(c.Area,"",{Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Left},c._scope)
	padding(button,7)
	local thumb=new("ImageLabel",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,2),Size=UDim2.fromOffset(22,22),Visible=false},button)
	c._render=function()
		local selected=c:GetSelectedOptions()
		local names={}
		for _,item in ipairs(selected) do table.insert(names,item.Name) end
		local first=selected[1]
		thumb.Visible=first~=nil and (first.Image~=nil or first.Preview~=nil) and not first.Model
		if thumb.Visible then thumb.Image=image(first.Image or first.Preview) end
		button.Text=(thumb.Visible and "       " or "") .. (#names>0 and table.concat(names,", ") or options.Placeholder or "Select...") .. "  ▾"
	end
	function c:Open()
		if self.Disabled then return self end
		local panel,s=w:_popupAt(button,options.PopupWidth or 330,options.PopupHeight or 310,c._scope)
		local search=w:_input(panel,options.SearchPlaceholder or "Search...",{Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,28),ZIndex=103},s)
		local scroll=w:_scroll(panel,{Position=UDim2.fromOffset(8,44),Size=UDim2.new(1,-16,1,-52),ZIndex=103},s)
		list(scroll,4)
		local rows={}
		for i,item in ipairs(c.Items) do
			local hasPreview=item.Image or item.Preview or item.Model
			local b=w:_button(scroll,"",{Size=UDim2.new(1,-4,0,hasPreview and 58 or 32),LayoutOrder=i,ZIndex=104},s)
			if hasPreview then w:_preview(b,item,{Position=UDim2.fromOffset(4,4),Size=UDim2.fromOffset(50,50),ZIndex=105},s) end
			local x=hasPreview and 62 or 10
			w:_text(b,item.Name,{Position=UDim2.fromOffset(x,0),Size=UDim2.new(1,-x-27,1,item.Description and -18 or 0),ZIndex=105},"Text",s)
			if item.Description then w:_text(b,item.Description,{Position=UDim2.new(0,x,1,-22),Size=UDim2.new(1,-x-27,0,18),TextSize=10,ZIndex=105},"Dim",s) end
			local mark=w:_text(b,c:IsSelected(item.Id) and "✓" or "",{Position=UDim2.new(1,-25,0,0),Size=UDim2.new(0,22,1,0),ZIndex=105},"Accent",s)
			if item.Disabled then b.BackgroundTransparency=0.6 end
			table.insert(rows,{Button=b,Item=item,Mark=mark})
			s:Connect(b.Activated,function()
				if c.Disabled or item.Disabled then return end
				c:Choose(item.Id)
				if not c.Multi then w:_closePopup()
				else for _,r in ipairs(rows) do r.Mark.Text=c:IsSelected(r.Item.Id) and "✓" or "" end end
			end)
		end
		local empty=w:_text(scroll,options.EmptyText or "Nothing found",{Size=UDim2.new(1,-4,0,32),Visible=#rows==0,ZIndex=105},"Dim",s)
		s:Connect(search:GetPropertyChangedSignal("Text"),function()
			local count=0
			for _,r in ipairs(rows) do
				r.Button.Visible=contains(r.Item.Name .. " " .. (r.Item.Description or ""),search.Text)
				if r.Button.Visible then count+=1 end
			end
			empty.Visible=count==0
		end)
		return self
	end
	c._scope:Connect(button.Activated,function() c:Open() end)
	c._rebuild=function() w:_closePopup() end
	return c:_init(options.Default or (c.Multi and {} or nil))
end

function Container:AddSegmented(options)
	local c=self:_control("Segmented",options)
	local w=c.Window
	setupSelection(c,options)
	assert(not c.Multi,"Segmented is single-select")
	local buttons,buttonScope={}
	local layout=list(c.Area,4,true)
	c._render=function()
		for _,entry in ipairs(buttons) do
			entry.Button.TextColor3=c:IsSelected(entry.Item.Id) and w.Theme.Accent or w.Theme.Dim
			entry.Button.BackgroundTransparency=c:IsSelected(entry.Item.Id) and 0 or 0.65
		end
	end
	c._rebuild=function()
		if buttonScope then buttonScope:Destroy() end
		buttonScope=scope(c._scope)
		buttons={}
		for i,item in ipairs(c.Items) do
			local b=w:_button(c.Area,item.Name,{Size=UDim2.new(1/math.max(1,#c.Items),-4,1,0),LayoutOrder=i},buttonScope)
			buttonScope:Add(b)
			w:_bind(b,"TextColor3",function(t) return c:IsSelected(item.Id) and t.Accent or t.Dim end,buttonScope)
			buttonScope:Connect(b.Activated,function() c:Choose(item.Id) end)
			table.insert(buttons,{Button=b,Item=item})
		end
		c._render()
	end
	c:_init(options.Default)
	c._rebuild()
	return c
end
Container.AddSelect=Container.AddSegmented

function Container:AddImage(options)
	local c=self:_control("Image",options,options.Height or 180)
	c.Area:Destroy()
	c.Label.Size=UDim2.new(1,-20,0,24)
	c.Label.Position=UDim2.fromOffset(10,3)
	if c.Description then c.Description.Visible=false end
	local preview=new("ImageLabel",{BackgroundTransparency=1,ScaleType=options.ScaleType or Enum.ScaleType.Fit,
		Position=UDim2.fromOffset(8,30),Size=UDim2.new(1,-16,1,-38)},c.Row)
	c._validate=function(v) assert(type(v)=="string" or type(v)=="number","Image expects asset ID or URI") return v end
	c._render=function() preview.Image=image(c.Value) end
	return c:_init(options.Image or options.Default or "")
end
function Container:AddViewport(options)
	local c=self:_control("Viewport",options,options.Height or 220)
	c.Area:Destroy()
	c.Label.Size=UDim2.new(1,-20,0,24)
	c.Label.Position=UDim2.fromOffset(10,3)
	if c.Description then c.Description.Visible=false end
	c.Preview=c.Window:_preview(c.Row,{Model=assert(options.Model,"Viewport needs Model"),CameraCFrame=options.CameraCFrame},
		{Position=UDim2.fromOffset(8,30),Size=UDim2.new(1,-16,1,-38)},c._scope)
	return c
end
function Container:AddDivider(text)
	local c=self:_control("Divider",{Name=text or ""},text and 26 or 10)
	c.Row.BackgroundTransparency=1
	c.Area:Destroy()
	c.Label.Size=UDim2.new(1,-20,1,0)
	if not text then
		c.Label.Visible=false
		c.Window:_frame(c.Row,{Position=UDim2.new(0,6,0.5,0),Size=UDim2.new(1,-12,0,1)},"Stroke",c._scope)
	end
	return c
end

function Container:AddImageSelector(options)
	local c=self:_control("ImageSelector",options,options.Height or 390)
	local w=c.Window
	c.Label.Visible=false
	if c.Description then c.Description.Visible=false end
	c.Area:Destroy()
	c.Row.BackgroundTransparency=1
	setupSelection(c,options)
	local top=w:_frame(c.Row,{Size=UDim2.new(1,0,0,30),BackgroundTransparency=1})
	local cats=w:_scroll(top,{Size=UDim2.new(1,options.Toggle and -104 or 0,1,0),AutomaticCanvasSize=Enum.AutomaticSize.X,
		ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=0},c._scope)
	list(cats,5,true)
	local info=w:_text(c.Row,"",{Position=UDim2.fromOffset(1,36),Size=UDim2.new(1,-186,0,24),TextSize=10},"Dim",c._scope)
	local search=w:_input(c.Row,options.SearchPlaceholder or "Search...",{Position=UDim2.new(1,-178,0,35),Size=UDim2.fromOffset(176,25)},c._scope)
	local grid=w:_scroll(c.Row,{Position=UDim2.fromOffset(0,67),Size=UDim2.new(1,0,1,-67)},c._scope)
	padding(grid,2)
	local layout=new("UIGridLayout",{CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder},grid)
	local empty=w:_text(c.Row,options.EmptyText or "Nothing found",{Position=UDim2.fromOffset(10,98),Size=UDim2.new(1,-20,0,40),TextXAlignment=Enum.TextXAlignment.Center,Visible=false},"Dim",c._scope)
	local enabled=options.Enabled~=false
	c.Enabled=enabled
	if options.Toggle then
		local toggle=w:_button(top,"",{Position=UDim2.new(1,-98,0,0),Size=UDim2.fromOffset(96,30)},c._scope)
		local label=w:_text(toggle,options.ToggleText or "Skins",{Position=UDim2.fromOffset(10,0),Size=UDim2.new(1,-48,1,0),TextSize=11},"Text",c._scope)
		local switch=w:_frame(toggle,{Position=UDim2.new(1,-39,0.5,-8),Size=UDim2.fromOffset(30,16)},nil,c._scope) corner(switch,20)
		local knob=w:_frame(switch,{Position=UDim2.fromOffset(18,3),Size=UDim2.fromOffset(10,10)},nil,c._scope) corner(knob,20)
		w:_bind(switch,"BackgroundColor3",function(t) return c.Enabled and t.Accent or t.Background end,c._scope)
		w:_bind(knob,"BackgroundColor3",function(t) return c.Enabled and t.Background or t.Dim end,c._scope)
		function c:SetEnabled(value,silent)
			self.Enabled=value==true
			w:_tween(switch,{BackgroundColor3=self.Enabled and w.Theme.Accent or w.Theme.Background})
			w:_tween(knob,{Position=UDim2.fromOffset(self.Enabled and 18 or 3,3),BackgroundColor3=self.Enabled and w.Theme.Background or w.Theme.Dim})
			label.TextTransparency=self.Enabled and 0 or 0.4
			if not silent then call(options.OnEnabled,self.Enabled,self) end
			return self
		end
		c:SetEnabled(enabled,true)
		c._scope:Connect(toggle.Activated,function() if not c.Disabled then c:SetEnabled(not c.Enabled) end end)
	end
	local cards,catButtons={},{}
	local renderScope,catScope
	local filtered,shown={},0
	local function updateInfo()
		local names={}
		for _,item in ipairs(c:GetSelectedOptions()) do table.insert(names,item.Name) end
		info.Text=tostring(#filtered) .. " / " .. tostring(#c.Items) .. " · " .. (#names>0 and table.concat(names,", ") or (options.NoneText or "default"))
	end
	c._render=function()
		for _,card in ipairs(cards) do
			local on=c:IsSelected(card.Item.Id)
			card.Stroke.Color=on and w.Theme.Accent or w.Theme.Stroke
			card.Badge.Visible=on
		end
		updateInfo()
	end
	local function resize()
		local width=grid.AbsoluteSize.X/math.max(0.01,w.UIScale.Scale)-7
		local columns=options.Columns or math.max(1,math.floor((width+8)/((options.MinCardWidth or 108)+8)))
		columns=math.max(1,math.min(columns,math.floor((width+8)/60)))
		layout.CellSize=UDim2.new(1/columns,-(8*(columns-1)+6)/columns,0,options.CardHeight or 150)
	end
	local function loadMore()
		local last=math.min(#filtered,shown+(options.PageSize or 32))
		for i=shown+1,last do
			local item=filtered[i]
			local b=w:_button(grid,"",{BackgroundTransparency=1,LayoutOrder=i},renderScope)
			renderScope:Add(b)
			local h=options.CardHeight or 150
			local thumb=w:_frame(b,{Size=UDim2.new(1,0,0,h-48),ClipsDescendants=true},"Card",renderScope)
			corner(thumb,w.Radius)
			local st=w:_stroke(thumb,function(t) return c:IsSelected(item.Id) and t.Accent or t.Stroke end,renderScope)
			local preview=w:_preview(thumb,item,{Position=UDim2.fromScale(0.08,0.08),Size=UDim2.fromScale(0.84,0.84)},renderScope)
			local badge=w:_text(thumb,options.SelectedText or "SELECTED",{Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(62,15),TextSize=8,Font=Enum.Font.GothamBold,
				BackgroundTransparency=0,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=3},"Background",renderScope)
			w:_bind(badge,"BackgroundColor3","Accent",renderScope) corner(badge,4)
			local footer=w:_frame(b,{Position=UDim2.fromOffset(0,h-42),Size=UDim2.new(1,0,0,42)},"Footer",renderScope) corner(footer,w.Radius)
			w:_text(footer,string.upper(item.Name),{Position=UDim2.fromOffset(5,4),Size=UDim2.new(1,-10,0,15),TextSize=10,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Center},"Text",renderScope)
			local rarity=w:_text(footer,item.Rarity or item.Description or "",{Position=UDim2.fromOffset(5,21),Size=UDim2.new(1,-10,0,13),TextSize=10,TextXAlignment=Enum.TextXAlignment.Center},"Warning",renderScope)
			local rarityColor=item.RarityColor or (options.RarityColors or {})[item.Rarity]
			if rarityColor then w:_bind(rarity,"TextColor3",function() return rarityColor end,renderScope) end
			if item.Disabled then thumb.BackgroundTransparency=0.5 end
			table.insert(cards,{Item=item,Stroke=st,Badge=badge})
			renderScope:Connect(b.Activated,function() c:Choose(item.Id) end)
			renderScope:Connect(b.MouseEnter,function() w:_tween(preview,{Position=UDim2.fromScale(0.03,0.03),Size=UDim2.fromScale(0.94,0.94)}) end)
			renderScope:Connect(b.MouseLeave,function() w:_tween(preview,{Position=UDim2.fromScale(0.08,0.08),Size=UDim2.fromScale(0.84,0.84)}) end)
		end
		shown=last
		c._render()
	end
	local function refresh()
		if renderScope then renderScope:Destroy() end
		renderScope=scope(c._scope)
		cards,filtered,shown={},{},0
		for _,item in ipairs(c.Items) do
			if (not c.Category or item.Category==c.Category) and contains(item.Name .. " " .. (item.Rarity or "") .. " " .. (item.Description or ""),search.Text) then table.insert(filtered,item) end
		end
		grid.CanvasPosition=Vector2.zero
		empty.Visible=#filtered==0
		loadMore()
	end
	function c:SetCategory(category)
		self.Category=category
		for _,b in ipairs(catButtons) do b.Button.Text=(b.Value==category and "● " or "") .. b.Name end
		refresh()
		call(options.OnCategory,category,self)
		return self
	end
	function c:SetSearch(query) search.Text=tostring(query) return self end
	c._rebuild=function()
		if catScope then catScope:Destroy() end
		catScope=scope(c._scope)
		catButtons={}
		local categories=clone(options.Categories or {})
		if not options.Categories then
			local seen={}
			for _,item in ipairs(c.Items) do if item.Category and not seen[item.Category] then seen[item.Category]=true table.insert(categories,item.Category) end end
		end
		if options.ShowAll~=false then table.insert(categories,1,{Name=options.AllText or "All"}) end
		local valid=not c.Category
		for i,cat in ipairs(categories) do
			local value=cat
			if type(cat)=="table" then value=cat.Id end
			local name=type(cat)=="table" and (cat.Name or cat.Id) or cat
			local b=w:_button(cats,tostring(name),{Size=UDim2.fromOffset(0,30),AutomaticSize=Enum.AutomaticSize.X,LayoutOrder=i},catScope)
			catScope:Add(b) padding(b,10)
			table.insert(catButtons,{Button=b,Value=value,Name=tostring(name)})
			if c.Category==value then valid=true end
			catScope:Connect(b.Activated,function() c:SetCategory(value) end)
		end
		if not valid then c.Category=nil end
		for _,b in ipairs(catButtons) do b.Button.Text=(b.Value==c.Category and "● " or "") .. b.Name end
		refresh()
	end
	c._scope:Connect(search:GetPropertyChangedSignal("Text"),refresh)
	c._scope:Connect(grid:GetPropertyChangedSignal("AbsoluteSize"),resize)
	c._scope:Connect(grid:GetPropertyChangedSignal("CanvasPosition"),function()
		if shown<#filtered and grid.CanvasPosition.Y+grid.AbsoluteWindowSize.Y>=layout.AbsoluteContentSize.Y-250 then loadMore() end
	end)
	c.Category=options.DefaultCategory
	c:_init(options.Default or (c.Multi and {} or nil))
	resize() c._rebuild()
	return c
end

function Container:AddKeybind(options)
	local c=self:_control("Keybind",options)
	local w=c.Window
	local button=w:_button(c.Area,"",{Size=UDim2.fromScale(1,1)},c._scope)
	c.Mode=options.Mode or "Press"
	assert(c.Mode=="Press" or c.Mode=="Toggle" or c.Mode=="Hold","Invalid keybind mode")
	c.Active=false
	c._validate=function(value) return assert(enumKey(value),"Invalid keybind") end
	c._render=function() button.Text=c.Value.Name end
	c._scope:Connect(button.Activated,function()
		if c.Disabled then return end
		if w._capture then w._capture(Enum.KeyCode.Escape) end
		button.Text="..."
		w._capture=function(key)
			if not c._scope.alive then return end
			if key==Enum.KeyCode.Escape then c._render()
			elseif key==Enum.KeyCode.Backspace then c:Set(Enum.KeyCode.Unknown)
			else c:Set(key) end
		end
	end)
	c._scope:Connect(UIS.InputBegan,function(input,processed)
		if c.Disabled or processed or UIS:GetFocusedTextBox() or w._capture or w._capturedInput==input or input.KeyCode~=c.Value or c.Value==Enum.KeyCode.Unknown then return end
		if c.Mode=="Toggle" then c.Active=not c.Active else c.Active=true end
		call(options.OnTriggered,c.Active,c)
		if c.Mode=="Press" then c.Active=false end
	end)
	c._scope:Connect(UIS.InputEnded,function(input)
		if c.Mode=="Hold" and c.Active and input.KeyCode==c.Value then c.Active=false call(options.OnTriggered,false,c) end
	end)
	return c:_init(enumKey(options.Default) or Enum.KeyCode.Unknown)
end

function Container:AddColorPicker(options)
	local c=self:_control("ColorPicker",options)
	local w=c.Window
	local button=w:_button(c.Area,"",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.fromScale(1,0.5),Size=UDim2.fromOffset(46,23)},c._scope)
	button:SetAttribute("RockUIStaticColor",true)
	w:_bind(button,"BackgroundColor3",function() return c.Value or RGB(255,255,255) end,c._scope)
	c._validate=function(v) assert(typeof(v)=="Color3","ColorPicker expects Color3") return v end
	c._render=function() button.BackgroundColor3=c.Value end
	function c:Open()
		if self.Disabled then return self end
		local panel,s=w:_popupAt(button,288,305,c._scope)
		local h,sat,val=c.Value:ToHSV()
		local square=w:_frame(panel,{Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,0,155),ZIndex=103})
		local white=w:_frame(square,{Size=UDim2.fromScale(1,1),BackgroundColor3=RGB(255,255,255),ZIndex=104})
		new("UIGradient",{Transparency=NumberSequence.new(0,1)},white)
		local black=w:_frame(square,{Size=UDim2.fromScale(1,1),BackgroundColor3=RGB(0,0,0),ZIndex=105})
		new("UIGradient",{Rotation=90,Transparency=NumberSequence.new(1,0)},black)
		local marker=w:_frame(square,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(8,8),BackgroundColor3=RGB(255,255,255),ZIndex=107})
		corner(marker,10) w:_stroke(marker,"Background",s)
		local hit=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=106},square)
		local hue=w:_frame(panel,{Position=UDim2.fromOffset(10,178),Size=UDim2.new(1,-20,0,15),BackgroundColor3=RGB(255,255,255),ZIndex=103})
		local points={}
		for i=0,6 do table.insert(points,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
		new("UIGradient",{Color=ColorSequence.new(points)},hue)
		local hueMark=w:_frame(hue,{Size=UDim2.fromOffset(3,19),Position=UDim2.fromOffset(0,-2),BackgroundColor3=RGB(255,255,255),ZIndex=105})
		local hueHit=new("TextButton",{Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=104},hue)
		local hex=w:_input(panel,"#RRGGBB",{Position=UDim2.fromOffset(10,207),Size=UDim2.new(1,-20,0,28),ZIndex=103},s)
		local channels={}
		for i,name in ipairs({"R","G","B"}) do
			local box=w:_input(panel,name,{Position=UDim2.new((i-1)/3,10,0,244),Size=UDim2.new(1/3,-14,0,27),ZIndex=103},s)
			channels[i]=box
		end
		local function render()
			square.BackgroundColor3=Color3.fromHSV(h,1,1)
			marker.Position=UDim2.fromScale(sat,1-val)
			hueMark.Position=UDim2.new(h,-1,0,-2)
			hex.Text="#" .. c.Value:ToHex():upper()
			channels[1].Text=tostring(math.round(c.Value.R*255))
			channels[2].Text=tostring(math.round(c.Value.G*255))
			channels[3].Text=tostring(math.round(c.Value.B*255))
		end
		local function update() c:Set(Color3.fromHSV(h,sat,val)) render() end
		w:_drag(hit,function(p)
			if c.Disabled then return end
			sat=math.clamp((p.X-square.AbsolutePosition.X)/math.max(1,square.AbsoluteSize.X),0,1)
			val=1-math.clamp((p.Y-square.AbsolutePosition.Y)/math.max(1,square.AbsoluteSize.Y),0,1)
			update()
		end,s)
		w:_drag(hueHit,function(p) if not c.Disabled then h=math.clamp((p.X-hue.AbsolutePosition.X)/math.max(1,hue.AbsoluteSize.X),0,1) update() end end,s)
		s:Connect(hex.FocusLost,function()
			local code=hex.Text:gsub("#","")
			if not c.Disabled and code:match("^%x%x%x%x%x%x$") then c:Set(Color3.fromHex(code)) h,sat,val=c.Value:ToHSV() end
			render()
		end)
		for _,box in ipairs(channels) do s:Connect(box.FocusLost,function()
			local r,g,b=tonumber(channels[1].Text),tonumber(channels[2].Text),tonumber(channels[3].Text)
			if not c.Disabled and r and g and b then c:Set(RGB(math.clamp(r,0,255),math.clamp(g,0,255),math.clamp(b,0,255))) h,sat,val=c.Value:ToHSV() end
			render()
		end) end
		render()
		return self
	end
	c._scope:Connect(button.Activated,function() c:Open() end)
	return c:_init(options.Default or RGB(255,255,255))
end

function Window:Notify(options)
	if type(options)=="string" then options={Title=options} end
	options=options or {}
	if not self.Notifications then
		self.Notifications=self:_frame(self.Gui,{AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-16),Size=UDim2.new(0,300,1,-32),BackgroundTransparency=1,ZIndex=150})
		local layout=list(self.Notifications,8)
		layout.VerticalAlignment=Enum.VerticalAlignment.Bottom
	end
	local s=scope(self._scope)
	local card=self:_frame(self.Notifications,{Size=UDim2.new(1,0,0,76),ZIndex=151,LayoutOrder=#self.Notifications:GetChildren()},"Panel",s)
	s:Add(card) corner(card,self.Radius) self:_stroke(card,"Stroke",s)
	self:_text(card,options.Title or "Notification",{Position=UDim2.fromOffset(12,9),Size=UDim2.new(1,-45,0,19),Font=Enum.Font.GothamBold,ZIndex=152},options.Type=="Error" and "Danger" or options.Type=="Success" and "Success" or "Accent",s)
	self:_text(card,options.Content or "",{Position=UDim2.fromOffset(12,32),Size=UDim2.new(1,-24,0,33),TextWrapped=true,TextSize=11,ZIndex=152},"Dim",s)
	local close=self:_button(card,"×",{Position=UDim2.new(1,-30,0,6),Size=UDim2.fromOffset(24,24),ZIndex=153},s)
	s:Connect(close.Activated,function() s:Destroy() end)
	if options.Duration~=0 then task.delay(options.Duration or 4,function() s:Destroy() end) end
	return { Close=function() s:Destroy() end }
end
function Window:Confirm(options)
	options=options or {}
	local panel,s=self:_popupAt(self.TitleLabel,340,168,nil,true)
	self:_text(panel,options.Title or "Confirm",{Position=UDim2.fromOffset(14,12),Size=UDim2.new(1,-28,0,23),Font=Enum.Font.GothamBold,TextSize=15,ZIndex=104},"Text",s)
	self:_text(panel,options.Content or "",{Position=UDim2.fromOffset(14,42),Size=UDim2.new(1,-28,0,62),TextWrapped=true,ZIndex=104},"Dim",s)
	local yes=self:_button(panel,options.ConfirmText or "Confirm",{Position=UDim2.new(0.5,4,1,-45),Size=UDim2.new(0.5,-18,0,30),ZIndex=104},s)
	local no=self:_button(panel,options.CancelText or "Cancel",{Position=UDim2.fromOffset(14,123),Size=UDim2.new(0.5,-18,0,30),ZIndex=104},s)
	s:Connect(yes.Activated,function() self:_closePopup() call(options.Callback,true) end)
	s:Connect(no.Activated,function() self:_closePopup() call(options.Callback,false) end)
	return { Close=function() if self._popup==s then self:_closePopup() end end }
end

local function packValue(v)
	if typeof(v)=="Color3" then return { Type="Color3",Hex=v:ToHex() } end
	if typeof(v)=="EnumItem" then return { Type="KeyCode",Name=v.Name } end
	return clone(v)
end
local function unpackValue(v)
	if type(v)=="table" and v.Type=="Color3" then
		assert(type(v.Hex)=="string" and v.Hex:match("^%x%x%x%x%x%x$"),"Invalid color")
		return Color3.fromHex(v.Hex)
	end
	if type(v)=="table" and v.Type=="KeyCode" then return assert(enumKey(v.Name),"Invalid saved key") end
	return v
end
function Window:ExportConfig()
	local data={Version=1,Values={},Theme={}}
	for flag,c in pairs(self.Controls) do
		if c.Options.Save~=false and c._validate then data.Values[flag]={Value=packValue(c:Get()),Empty=c.Value==nil} end
	end
	for token,color in pairs(self.Theme) do data.Theme[token]=color:ToHex() end
	if self.Watermark and not self.Watermark.Destroyed then data.Watermark=self.Watermark:_config() end
	return HttpService:JSONEncode(data)
end
function Window:ImportConfig(json, options)
	options=options or {}
	local ok,result=pcall(function()
		local data=HttpService:JSONDecode(json)
		assert(type(data)=="table" and data.Version==1 and type(data.Values)=="table","Unsupported config")
		local pending={}
		for flag,entry in pairs(data.Values) do
			local c=self.Controls[flag]
			if c and c.Options.Save~=false and c._validate then
				assert(type(entry)=="table","Invalid config entry")
				local value
				if not entry.Empty then value=unpackValue(entry.Value) end
				value=c._validate(value)
				table.insert(pending,{Control=c,Value=value})
			end
		end
		local theme={}
		local watermarkData
		if options.Watermark~=false and data.Watermark and self.Watermark and not self.Watermark.Destroyed then
			watermarkData=self.Watermark:_validateConfig(data.Watermark)
		end
		if options.Theme~=false and data.Theme then
			assert(type(data.Theme)=="table","Invalid config theme")
			for token,hex in pairs(data.Theme) do
				assert(self.Theme[token] and type(hex)=="string" and hex:match("^%x%x%x%x%x%x$"),"Invalid theme color")
				theme[token]=Color3.fromHex(hex)
			end
		end
		-- Validate everything before changing any controls; callbacks see fully applied state.
		self:_closePopup()
		for _,entry in ipairs(pending) do entry.Control:Set(entry.Value,true) end
		self:SetTheme(theme)
		if watermarkData then self.Watermark:_applyConfig(watermarkData) end
		if not options.Silent then for _,entry in ipairs(pending) do entry.Control:_emit(false) end end
		return true
	end)
	if not ok then return false,tostring(result) end
	return true
end
function Window:ResetConfig(silent)
	for _,c in pairs(self.Controls) do if c._validate and c.Options.Save~=false then c:Reset(true) end end
	if not silent then for _,c in pairs(self.Controls) do if c._validate and c.Options.Save~=false then c:_emit(false) end end end
	return self
end
local function configName(name)
	assert(type(name)=="string" and #name>0 and #name<=64 and name:match("^[%w_%-]+$"),"Config name: 1-64 ASCII letters, digits, _ or -")
	return name
end
function Window:SaveConfig(name)
	local ok,err=pcall(function()
		configName(name)
		assert(self.Storage and type(self.Storage.Write)=="function","Provide Storage.Write(name, json)")
		self.Storage.Write(name,self:ExportConfig())
	end)
	return ok,not ok and tostring(err) or nil
end
function Window:LoadConfig(name,options)
	local ok,json=pcall(function()
		configName(name)
		assert(self.Storage and type(self.Storage.Read)=="function","Provide Storage.Read(name)")
		return self.Storage.Read(name)
	end)
	if not ok then return false,tostring(json) end
	return self:ImportConfig(json,options)
end
function Window:DeleteConfig(name)
	local ok,err=pcall(function()
		configName(name)
		assert(self.Storage and type(self.Storage.Delete)=="function","Provide Storage.Delete(name)")
		self.Storage.Delete(name)
	end)
	return ok,not ok and tostring(err) or nil
end
function Window:ListConfigs()
	local ok,result=pcall(function()
		assert(self.Storage and type(self.Storage.List)=="function","Provide Storage.List()")
		return self.Storage.List()
	end)
	if not ok then return nil,tostring(result) end
	return result
end

-- Embedded implementation: no require(), HTTP script loader or separate watermark module.
do
	local WM={}
	WM.__index=WM
	function WM:_tween(obj,duration,props,direction,style)
		if self.Destroyed then return end
		if self._tweens[obj] then self._tweens[obj]:Cancel() end
		local tw=TweenService:Create(obj,TweenInfo.new(self.ReducedMotion and 0 or duration,style or Enum.EasingStyle.Quad,direction or Enum.EasingDirection.Out),props)
		self._tweens[obj]=tw tw:Play()
		return tw
	end
	function WM:_pop(frame,scale,on,target)
		target=target or 1 frame:SetAttribute("pzOn",on)
		if on then
			frame.Visible=true scale.Scale=target*0.6
			self:_tween(scale,0.35,{Scale=target},Enum.EasingDirection.Out,Enum.EasingStyle.Back)
		else
			self:_tween(scale,0.18,{Scale=0},Enum.EasingDirection.In)
			task.delay(self.ReducedMotion and 0 or 0.18,function()
				if not self.Destroyed and not frame:GetAttribute("pzOn") then frame.Visible=false end
			end)
		end
	end
	function WM:_responsive()
		local camera=workspace.CurrentCamera
		local view=camera and camera.ViewportSize or Vector2.new(1280,720)
		local target=1
		if self.AutoScale and UIS.TouchEnabled then
			if math.min(view.X,view.Y)>=600 then target=0.85
			else
				local tl,br=Vector2.zero,Vector2.zero
				pcall(function() tl,br=GuiService:GetGuiInset() end)
				local responsive=math.clamp(math.min(math.max(1,view.X-tl.X-br.X-16)/680,math.max(1,view.Y-tl.Y-br.Y-16)/470),0.35,1)
				target=math.clamp(responsive,0.58,0.75)
			end
		end
		self.TargetScale=target*self.Scale
		if self.Visible then self.WatermarkScale.Scale=self.TargetScale end
	end
	function WM:_placeTip()
		local x=self.MenuButton.AbsolutePosition.X-self.Button.AbsolutePosition.X
		local y=self.Button.AbsoluteSize.Y+10
		self.Tip.Position=UDim2.fromOffset(x+self.MenuButton.AbsoluteSize.X+6,y)
		self.TipArrow.Position=UDim2.fromOffset(x+self.MenuButton.AbsoluteSize.X/2,y)
	end
	function WM:ShowTip(on,hideAfter)
		if self.Destroyed then return self end
		on=on==true self._tipSeq+=1
		self.TipTitle.Text=self.MenuOpen and self.CloseHint or self.OpenHint
		self.TipHint.Text=self.DragHint .. "  ·  " .. self.KeyHint .. " " .. self.ToggleKey.Name
		if on~=self._tipShown then
			self._tipShown=on
			if on then self:_placeTip() end
			self:_pop(self.Tip,self.TipScale,on) self.TipArrow.Visible=on
		end
		if on and hideAfter then
			local id=self._tipSeq
			task.delay(hideAfter,function()
				if not self.Destroyed and id==self._tipSeq and not self.Hovering then self:ShowTip(false) end
			end)
		end
		return self
	end
	function WM:_refreshMenuButton()
		if self.Destroyed or not self.Visible then return end
		local t,hover=self.Window.Theme,self.Hovering
		self:_tween(self.WatermarkScale,0.2,{Scale=self.TargetScale*(hover and 1.03 or 1)},Enum.EasingDirection.Out,Enum.EasingStyle.Quint)
		self:_tween(self.WatermarkStroke,0.2,{Transparency=(hover or self.MenuOpen) and 0 or 0.5})
		local bg=hover and t.Accent or (self.MenuOpen and t.Hover or t.Element)
		local fg=hover and t.Background or t.Text
		self:_tween(self.MenuButton,0.2,{BackgroundColor3=bg})
		self:_tween(self.MenuLabel,0.2,{TextColor3=fg})
		for _,l in ipairs(self.BurgerLines) do self:_tween(l,0.2,{BackgroundColor3=fg}) end
		if self.Used or hover then self:_tween(self.MenuStroke,0.2,{Transparency=hover and 0 or 0.6}) end
	end
	function WM:SetMenuOpen(open,silent)
		if self.Destroyed then return self end
		open=open==true
		local changed=self.MenuOpen~=open
		self.MenuOpen=open
		if not silent then
			self.Window:SetVisible(open)
			if changed then call(self.Options.OnToggle,open,self) end
		end
		if not changed then return self end
		local lines=self.BurgerLines
		self:_tween(lines[1],0.35,{Position=UDim2.new(0.5,0,0,open and 5 or 1),Rotation=open and 45 or 0},Enum.EasingDirection.Out,Enum.EasingStyle.Quint)
		self:_tween(lines[2],0.25,{Size=UDim2.fromOffset(open and 0 or 12,2),BackgroundTransparency=open and 1 or 0},Enum.EasingDirection.Out,Enum.EasingStyle.Quint)
		self:_tween(lines[3],0.35,{Position=UDim2.new(0.5,0,0,open and 5 or 9),Rotation=open and -45 or 0},Enum.EasingDirection.Out,Enum.EasingStyle.Quint)
		self.MenuLabel.Text=open and self.CloseText or self.MenuText
		self:_refreshMenuButton()
		if open then self:ShowTip(false)
		elseif self.Tooltip and not self.Used and self.Visible then
			task.delay(0.25,function()
				if not self.Destroyed and self.Visible and not self.MenuOpen and not self.Used then self:ShowTip(true,6) end
			end)
		end
		return self
	end
	function WM:SetVisible(on)
		if self.Destroyed then return self end
		on=on==true
		if on==self.Visible then return self end
		self.Visible=on
		if on then self:_refreshMenuButton() else self:ShowTip(false) end
		self:_pop(self.Button,self.WatermarkScale,on,self.TargetScale)
		return self
	end
	function WM:Show() return self:SetVisible(true) end
	function WM:Hide() return self:SetVisible(false) end
	function WM:Toggle() return self:SetVisible(not self.Visible) end
	function WM:SetPosition(value,silent)
		assert(typeof(value)=="UDim2","Position must be UDim2")
		self.Holder.Position=value
		if not silent then call(self.Options.OnPositionChanged,value,self) end
		return self
	end
	function WM:GetPosition() return self.Holder.Position end
	function WM:SetScale(value)
		assert(type(value)=="number" and value>0 and value<=5,"Watermark Scale must be in (0,5]")
		self.Scale=value self:_responsive() return self
	end
	function WM:SetBrand(value) self.Brand.Text=tostring(value) return self end
	function WM:SetLogo(value)
		self.LogoImage.Image=image(value)
		self.LogoImage.Visible=self.LogoImage.Image~="" self.LogoText.Visible=not self.LogoImage.Visible
		return self
	end
	function WM:SetUsed(value) self.Used=value==true self:_refreshMenuButton() return self end
	function WM:SetToggleKey(value) self.Window:SetToggleKey(value) return self end
	function WM:SetTheme(value) self.Window:SetTheme(value) return self end
	function WM:GetTheme() return self.Window:GetTheme() end
	function WM:_updateStatLabels()
		local t=self.Window.Theme
		local function stat(value,unit)
			return string.format('<font color="#%s">%s</font> <font color="#%s">%s</font>',t.Accent:ToHex(),value,t.Dim:ToHex(),unit)
		end
		self.FPSLabel.Text=stat(self.FPS or "--","fps") self.PingLabel.Text=stat(self.Ping or "--","ms")
		self.ClockLabel.Text='<font color="#'..t.Accent:ToHex()..'">'..os.date(self.ClockFormat)..'</font>'
	end
	function WM:GetStats() return {FPS=self.FPS,Ping=self.Ping,Time=os.date(self.ClockFormat)} end
	function WM:_config()
		local p=self:GetPosition()
		return {Version=1,Position={p.X.Scale,p.X.Offset,p.Y.Scale,p.Y.Offset},Scale=self.Scale,
			Visible=self.Visible,Used=self.Used,Brand=self.Brand.Text}
	end
	function WM:_validateConfig(data)
		assert(type(data)=="table" and data.Version==1,"Unsupported watermark config")
		assert(type(data.Position)=="table" and #data.Position==4,"Invalid watermark position")
		for _,v in ipairs(data.Position) do assert(type(v)=="number" and v==v and math.abs(v)<math.huge,"Invalid watermark position component") end
		assert(type(data.Scale)=="number" and data.Scale>0 and data.Scale<=5,"Invalid watermark scale")
		assert(type(data.Visible)=="boolean" and type(data.Used)=="boolean" and type(data.Brand)=="string","Invalid watermark config")
		return clone(data)
	end
	function WM:_applyConfig(data)
		self:SetPosition(UDim2.new(table.unpack(data.Position)),true) self:SetScale(data.Scale)
		self:SetBrand(data.Brand) self:SetUsed(data.Used) self:SetVisible(data.Visible)
	end
	function WM:ExportConfig() return HttpService:JSONEncode(self:_config()) end
	function WM:ImportConfig(json)
		local ok,err=pcall(function() self:_applyConfig(self:_validateConfig(HttpService:JSONDecode(json))) end)
		return ok,not ok and tostring(err) or nil
	end
	function WM:_ping()
		if self.Options.PingProvider then
			local ok,value=pcall(self.Options.PingProvider)
			if ok and type(value)=="number" then return value end
		end
		local ok,value=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and type(value)=="number" then return value end
		ok,value=pcall(function() return Players.LocalPlayer:GetNetworkPing()*2000 end)
		return ok and type(value)=="number" and value or 0
	end
	function WM:Destroy()
		if self.Destroyed then return end
		self.Destroyed=true
		for _,tw in pairs(self._tweens) do tw:Cancel() end table.clear(self._tweens)
		if self._logoThread and self._logoThread~=coroutine.running() then pcall(task.cancel,self._logoThread) end
		self._scope:Destroy()
		self.Window._scope.items[self]=nil
	end
	createEmbeddedWatermark=function(w,options)
		local self=setmetatable({Window=w,Options=options,_scope=scope(w._scope),_tweens={},Destroyed=false,
			Visible=false,Used=options.Used==true,Hovering=false,_tipShown=false,_tipSeq=0,_lastLevel=-1,TargetScale=1},WM)
		self.Scale=options.Scale or 1 self.AutoScale=options.AutoScale~=false
		assert(type(self.Scale)=="number" and self.Scale>0 and self.Scale<=5,"Invalid watermark Scale")
		self.ReducedMotion=options.ReducedMotion
		if self.ReducedMotion==nil then self.ReducedMotion=w.ReducedMotion end
		self.Shimmer=options.Shimmer~=false self.ShimmerSpeed=options.ShimmerSpeed or 0.35
		self.Pulse=options.Pulse~=false self.Draggable=options.Draggable~=false self.Tooltip=options.Tooltip~=false
		self.ClockFormat=options.ClockFormat or "%H:%M" self.UpdateInterval=options.UpdateInterval or 0.5
		assert(type(self.UpdateInterval)=="number" and self.UpdateInterval>0,"Invalid watermark UpdateInterval")
		self.ToggleKey=w.ToggleKey self.MenuText=options.MenuText or "menu" self.CloseText=options.CloseText or "close"
		self.OpenHint=options.OpenHint or "click to open the menu" self.CloseHint=options.CloseHint or "click to close the menu"
		self.DragHint=options.DragHint or "drag to move" self.KeyHint=options.KeyHint or "or press"
		local s=self._scope
		w._scope:Add(self)
		local function paint(obj,prop,token) w:_bind(obj,prop,token,s) return obj end
		local function frame(parent,props,token)
			local o=new("Frame",props,parent) if token then paint(o,"BackgroundColor3",token) end return o
		end
		local function outline(obj,token,transparency)
			local st=w:_stroke(obj,token,s) st.Transparency=transparency or 0 return st
		end
		self.Holder=frame(w.Gui,{Name="WatermarkHolder",BackgroundTransparency=1,Position=options.Position or UDim2.fromOffset(12,62),Size=UDim2.fromOffset(320,36),ZIndex=50})
		s:Add(self.Holder)
		self.Button=new("TextButton",{Name="Watermark",Text="",AutomaticSize=Enum.AutomaticSize.X,BackgroundTransparency=0.04,Size=UDim2.fromOffset(0,36),Visible=false,ZIndex=50},self.Holder)
		paint(self.Button,"BackgroundColor3","Background") corner(self.Button,10)
		self.WatermarkScale=new("UIScale",{Scale=0},self.Button)
		self.WatermarkStroke=outline(self.Button,"Accent",0.5)
		self.Gradients={new("UIGradient",{},self.WatermarkStroke)}
		new("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingRight=UDim.new(0,6)},self.Button)
		local layout=list(self.Button,9,true) layout.VerticalAlignment=Enum.VerticalAlignment.Center
		local order=0
		local function item(class,props)
			order+=1 props.LayoutOrder=order props.ZIndex=props.ZIndex or 51
			if props.BackgroundTransparency==nil then props.BackgroundTransparency=1 end
			return new(class,props,self.Button)
		end
		local function divider() paint(item("Frame",{Size=UDim2.fromOffset(1,14),BackgroundTransparency=0}),"BackgroundColor3","Stroke") end
		local function label(width)
			return paint(item("TextLabel",{Text="",RichText=true,Font=Enum.Font.GothamMedium,TextSize=12,
				TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromOffset(width,36)}),"TextColor3","Text")
		end
		self.Logo=paint(item("Frame",{Size=UDim2.fromOffset(24,24),BackgroundTransparency=0,ClipsDescendants=true}),"BackgroundColor3","Accent") corner(self.Logo,7)
		table.insert(self.Gradients,new("UIGradient",{Rotation=45},self.Logo))
		self.LogoText=paint(new("TextLabel",{Text=options.LogoText or "rh",Font=Enum.Font.GothamBlack,TextSize=12,
			BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Position=UDim2.fromOffset(0,-1),ZIndex=52},self.Logo),"TextColor3","Background")
		self.LogoImage=new("ImageLabel",{Image="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Fit,Visible=false,ZIndex=53},self.Logo)
		self.Brand=paint(item("TextLabel",{Text=options.Brand or "rock hub",Font=Enum.Font.GothamBold,TextSize=13,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,36)}),"TextColor3","Accent")
		table.insert(self.Gradients,new("UIGradient",{},self.Brand))
		divider() self.FPSLabel=label(50) divider()
		local signalIcon=item("Frame",{Size=UDim2.fromOffset(13,10)}) self.SignalBars={}
		for i=1,3 do
			local bar=frame(signalIcon,{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,(i-1)*5,1,0),Size=UDim2.fromOffset(3,3+i*2.4),ZIndex=52})
			paint(bar,"BackgroundColor3",function(t) return i<=self._lastLevel and t.Accent or t.Hover end)
			corner(bar,1) self.SignalBars[i]=bar
		end
		self.PingLabel=label(44) divider() self.ClockLabel=label(34)
		self.MenuButton=paint(item("Frame",{AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,24),BackgroundTransparency=0}),"BackgroundColor3","Element")
		corner(self.MenuButton,7) self.MenuStroke=outline(self.MenuButton,"Accent",0.6)
		new("UIPadding",{PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,10)},self.MenuButton)
		local menuLayout=list(self.MenuButton,7,true) menuLayout.VerticalAlignment=Enum.VerticalAlignment.Center
		local burger=frame(self.MenuButton,{Size=UDim2.fromOffset(12,10),BackgroundTransparency=1,LayoutOrder=1}) self.BurgerLines={}
		for i=1,3 do
			local l=frame(burger,{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.new(0.5,0,0,1+(i-1)*4),Size=UDim2.fromOffset(12,2),ZIndex=53},"Text")
			new("UICorner",{CornerRadius=UDim.new(1,0)},l) self.BurgerLines[i]=l
		end
		self.MenuLabel=paint(new("TextLabel",{Text=self.MenuText,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,
			BackgroundTransparency=1,Size=UDim2.fromOffset(32,24),LayoutOrder=2,ZIndex=53},self.MenuButton),"TextColor3","Text")
		self.Tip=frame(self.Holder,{Name="WatermarkTip",AnchorPoint=Vector2.new(1,0),AutomaticSize=Enum.AutomaticSize.XY,Visible=false,ZIndex=60},"Panel")
		corner(self.Tip,8) outline(self.Tip,"Hover") self.TipScale=new("UIScale",{Scale=0},self.Tip)
		new("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7)},self.Tip)
		list(self.Tip,2)
		self.TipTitle=paint(new("TextLabel",{Text=self.OpenHint,Font=Enum.Font.GothamBold,TextSize=12,AutomaticSize=Enum.AutomaticSize.XY,BackgroundTransparency=1,LayoutOrder=1,ZIndex=61},self.Tip),"TextColor3","Accent")
		self.TipHint=paint(new("TextLabel",{Text="",Font=Enum.Font.Gotham,TextSize=11,AutomaticSize=Enum.AutomaticSize.XY,BackgroundTransparency=1,LayoutOrder=2,ZIndex=61},self.Tip),"TextColor3","Dim")
		self.TipArrow=frame(self.Holder,{AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(9,9),Rotation=45,Visible=false,ZIndex=59},"Panel") outline(self.TipArrow,"Hover")
		s:Connect(self.Button.MouseEnter,function()
			self.Hovering=true self:_refreshMenuButton()
			local id=self._tipSeq
			task.delay(0.35,function() if not self.Destroyed and self.Tooltip and self.Hovering and id==self._tipSeq then self:ShowTip(true) end end)
		end)
		s:Connect(self.Button.MouseLeave,function() self.Hovering=false self:_refreshMenuButton() self:ShowTip(false) end)
		local start,origin,moved
		w:_drag(self.Button,function(p)
			if not self.Draggable then return end
			local d=p-start
			if not moved and d.Magnitude<6 then return end
			moved=true
			self.Holder.Position=UDim2.new(origin.X.Scale,origin.X.Offset+d.X,origin.Y.Scale,origin.Y.Offset+d.Y)
			local pos,size,v=self.Holder.AbsolutePosition,self.Holder.AbsoluteSize,w.Gui.AbsoluteSize
			local dx=math.clamp(pos.X,0,math.max(0,v.X-size.X))-pos.X
			local dy=math.clamp(pos.Y,0,math.max(0,v.Y-size.Y))-pos.Y
			self.Holder.Position+=UDim2.fromOffset(dx,dy)
		end,s,function(p)
			start,origin,moved=p,self.Holder.Position,false
			self:_tween(self.WatermarkScale,0.1,{Scale=self.TargetScale*0.96})
		end,function()
			if not UIS.MouseEnabled then self.Hovering=false end
			self:_refreshMenuButton()
			if moved then call(options.OnPositionChanged,self.Holder.Position,self)
			else
				if not self.Used then self.Used=true call(options.OnUsed,true,self) end
				self:ShowTip(false) self:SetMenuOpen(not w.Visible)
			end
		end)
		s:Connect(w.Root:GetPropertyChangedSignal("Visible"),function()
			if w.Root.Visible~=w.Visible then w:SetVisible(w.Root.Visible) end
		end)
		s:Connect(w.Gui:GetPropertyChangedSignal("AbsoluteSize"),function() self:_responsive() end)
		local frames,clock,startTime=0,os.clock(),os.clock()
		s:Connect(RunService.RenderStepped,function()
			frames+=1 local now=os.clock()
			if self.Button.Visible then
				if self.Shimmer then
					local points={} local t=(now-startTime)*self.ShimmerSpeed
					for i=0,8 do local x=i/8 local c=math.floor(80+(0.5+0.5*math.sin((x-t)*math.pi*2))*175) table.insert(points,ColorSequenceKeypoint.new(x,RGB(c,c,c))) end
					local seq=ColorSequence.new(points) for _,g in ipairs(self.Gradients) do g.Color=seq end
				end
				if self.Pulse and not self.Used and not self.Hovering then self.MenuStroke.Transparency=0.15+0.55*(0.5+0.5*math.cos((now-startTime)*4)) end
				if self.WatermarkScale.Scale>self.TargetScale*0.99 then self.Holder.Size=UDim2.fromOffset(self.Button.AbsoluteSize.X,self.Button.AbsoluteSize.Y) end
				if self.Tip.Visible then self:_placeTip() end
			end
			if now-clock<self.UpdateInterval then return end
			self.FPS=math.floor(frames/(now-clock)+0.5) frames,clock=0,now
			if not self.Button.Visible then return end
			self.Ping=math.floor(self:_ping()+0.5) self:_updateStatLabels()
			local lit=self.Ping<90 and 3 or (self.Ping<180 and 2 or 1)
			if lit~=self._lastLevel then self._lastLevel=lit for i,b in ipairs(self.SignalBars) do self:_tween(b,0.25,{BackgroundColor3=i<=lit and w.Theme.Accent or w.Theme.Hover}) end end
		end)
		self:_responsive() self:_updateStatLabels() self:SetMenuOpen(w.Visible,true) self:SetVisible(options.Visible~=false)
		if options.LogoImage then self:SetLogo(options.LogoImage)
		elseif options.LogoUrl~=false then
			self._logoThread=task.spawn(function()
				local getAsset=getcustomasset or getsynasset
				if not (writefile and getAsset) then return end
				local path=options.LogoPath or "rockhub_logo.png"
				local ok,value=pcall(function()
					if not (isfile and isfile(path)) then
						local data=game:HttpGet(options.LogoUrl or "https://raw.githubusercontent.com/rockscripter/MM2Drone/refs/heads/main/logo.png")
						assert(type(data)=="string" and #data>0,"Empty logo") writefile(path,data)
					end
					return getAsset(path)
				end)
				if not self.Destroyed and ok and value then self:SetLogo(value) end
			end)
		end
		return self
	end
end

return RockUI
