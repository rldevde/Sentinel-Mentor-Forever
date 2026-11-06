-- Sentinel look: flat near-black panels, hairline border, gold accent.
-- Widget factory shared by every view so the whole addon has one style.
local ADDON_NAME, SM = ...
local M = {}
SM.Style = M

local TEX = "Interface\\AddOns\\SentinelCore\\Media\\Textures\\"
M.tex = {
	blank = [[Interface\Buttons\WHITE8X8]],
	flat = TEX .. "Flat",
	inset = "Interface\\AddOns\\SentinelMentor\\Media\\inset",
}

local locale = GetLocale()
M.font = { normal = "Fonts\\ARIALN.TTF", header = "Fonts\\FRIZQT__.TTF" }
if locale == "zhCN" or locale == "zhTW" then
	local f = (locale == "zhCN") and "Fonts\\ARKai_T.ttf" or "Fonts\\bHEI01B.ttf"
	M.font.normal, M.font.header = f, f
elseif locale == "koKR" then
	M.font.normal, M.font.header = "Fonts\\K_Pagetext.ttf", "Fonts\\K_Pagetext.ttf"
elseif locale == "ruRU" then
	M.font.header = "Fonts\\FRIZQT___CYR.TTF"
end

M.colors = {
	bg = { r = 0.05, g = 0.06, b = 0.105, a = 1 },
	bgInset = { r = 0.035, g = 0.04, b = 0.075, a = 1 },
	bgRaised = { r = 0.075, g = 0.085, b = 0.14, a = 1 },
	bgFade = { r = 0.04, g = 0.05, b = 0.09, a = 0.9 },
	border = { r = 0.15, g = 0.19, b = 0.30 },
	borderLit = { r = 0.92, g = 0.68, b = 0.20 },
	accent = { r = 0.92, g = 0.68, b = 0.20 },
	accent2 = { r = 0.20, g = 0.62, b = 1.00 },
	text = { r = 0.92, g = 0.92, b = 0.95 },
	textDim = { r = 0.55, g = 0.57, b = 0.64 },
	red = { r = 0.94, g = 0.32, b = 0.36 },
	green = { r = 0.30, g = 0.85, b = 0.47 },
}
M.accentHex = "ebad33"
M.accent2Hex = "339eff"

local backdropFlat = { bgFile = M.tex.blank, edgeFile = M.tex.blank, edgeSize = 1 }

local function Sheen(f, show)
	if not show then
		if f.smSheen then f.smSheen:Hide() end
		return
	end
	if not f.smSheen then
		local t = f:CreateTexture(nil, "BORDER", nil, -7)
		t:SetTexture(M.tex.blank)
		if t.SetGradient and CreateColor then
			t:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0.05), CreateColor(1, 1, 1, 0))
		else
			t:SetVertexColor(1, 1, 1, 0.03)
		end
		t:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
		t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
		t:SetPoint("BOTTOM", f, "CENTER", 0, 0)
		f.smSheen = t
	end
	f.smSheen:Show()
end

function M:Template(f, style)
	if not f.SetBackdrop then
		if f.IsObjectType and f:IsObjectType("Frame") then
			Mixin(f, BackdropTemplateMixin or {})
			if f.OnBackdropLoaded then f:OnBackdropLoaded() end
		end
	end
	if not f.SetBackdrop then return end
	style = style or "panel"
	if style == "none" then
		f:SetBackdrop(nil)
		Sheen(f, false)
		return
	end
	if style == "fill" then
		f:SetBackdrop({bgFile = M.tex.blank})
		local c = self.colors.bg
		f:SetBackdropColor(c.r, c.g, c.b, c.a)
		Sheen(f, false)
		return
	end
	f:SetBackdrop(backdropFlat)
	local c = self.colors
	local bg = c.bg
	if style == "inset" then bg = c.bgInset elseif style == "raised" then bg = c.bgRaised elseif style == "ghost" then bg = c.bgFade end
	f:SetBackdropColor(bg.r, bg.g, bg.b, bg.a)
	f:SetBackdropBorderColor(c.border.r, c.border.g, c.border.b, 1)
	Sheen(f, style ~= "inset")
end

function M:SetBorderLit(f, lit)
	local c = lit and self.colors.accent or self.colors.border
	if f.SetBackdropBorderColor then f:SetBackdropBorderColor(c.r, c.g, c.b, 1) end
end

-- signature: gold corner brackets on one edge of a frame
function M:AccentEdge(f, edge)
	if f.smAccentEdge then return f.smAccentEdge end
	local side = (edge == "BOTTOM") and "BOTTOM" or "TOP"
	local c = self.colors.accent
	local ticks = {}
	local function tick(point, w, h)
		local t = f:CreateTexture(nil, "OVERLAY", nil, 7)
		t:SetTexture(M.tex.blank)
		t:SetVertexColor(c.r, c.g, c.b, 0.95)
		t:SetPoint(point, f, point, 0, 0)
		t:SetSize(w, h)
		ticks[#ticks + 1] = t
	end
	tick(side .. "LEFT", 9, 2)
	tick(side .. "LEFT", 2, 9)
	tick(side .. "RIGHT", 9, 2)
	tick(side .. "RIGHT", 2, 9)
	f.smAccentEdge = ticks
	return ticks
end

function M:Font(parent, size, flags, color)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(self.font.normal, size or 12, flags or "OUTLINE")
	local c = color or self.colors.text
	fs:SetTextColor(c.r, c.g, c.b)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("MIDDLE")
	return fs
end

function M:Panel(parent, w, h, style)
	local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	f:SetSize(w or 100, h or 100)
	self:Template(f, style or "panel")
	return f
end

function M:Button(parent, text, w, h)
	local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
	b:SetSize(w or 90, h or 24)
	self:Template(b, "raised")
	b.label = self:Font(b, 11)
	b.label:SetPoint("CENTER")
	b.label:SetText(text or "")
	b:SetScript("OnEnter", function(self2)
		M:SetBorderLit(self2, true)
		self2.label:SetTextColor(M.colors.accent.r, M.colors.accent.g, M.colors.accent.b)
	end)
	b:SetScript("OnLeave", function(self2)
		M:SetBorderLit(self2, false)
		self2.label:SetTextColor(M.colors.text.r, M.colors.text.g, M.colors.text.b)
	end)
	function b:SetText(t) self.label:SetText(t) end
	function b:GetText() return self.label:GetText() end
	function b:GetTextWidth() return self.label:GetStringWidth() or 0 end
	function b:SetEnabled(enabled)
		self.enabledState = enabled
		self:SetAlpha(enabled and 1 or 0.45)
		if enabled then self:EnableMouse(true) else self:EnableMouse(false) end
	end
	return b
end

function SM:CreateButton(text, parent)
	return M:Button(parent, text)
end

function M:Check(parent, label, w)
	local c = CreateFrame("Button", nil, parent)
	c:SetSize(w or 24, 20)
	c.box = CreateFrame("Frame", nil, c, "BackdropTemplate")
	c.box:SetSize(14, 14)
	c.box:SetPoint("LEFT", 0, 0)
	self:Template(c.box, "inset")
	c.mark = c.box:CreateTexture(nil, "OVERLAY")
	c.mark:SetPoint("CENTER")
	c.mark:SetSize(8, 8)
	c.mark:SetTexture(self.tex.blank)
	c.mark:SetVertexColor(self.colors.accent.r, self.colors.accent.g, self.colors.accent.b)
	c.mark:Hide()
	c.label = self:Font(c, 12)
	c.label:SetPoint("LEFT", c.box, "RIGHT", 6, 0)
	c.label:SetText(label or "")
	c.text = c.label
	-- toggle in PreClick so callers can replace OnClick and still read the new state
	c:SetScript("PreClick", function(self2)
		self2:SetChecked(not self2.checked)
		if PlaySound then PlaySound(SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856) end
	end)
	c:SetScript("OnEnter", function() M:SetBorderLit(c.box, true) end)
	c:SetScript("OnLeave", function() M:SetBorderLit(c.box, false) end)
	function c:SetChecked(v)
		self.checked = v and true or false
		if self.checked then self.mark:Show() else self.mark:Hide() end
	end
	function c:GetChecked() return self.checked and true or false end
	return c
end

-- dropdown ----------------------------------------------------------------------
local openMenus = {}
function M:Dropdown(parent, w)
	local d = CreateFrame("Button", nil, parent, "BackdropTemplate")
	d:SetSize(w or 160, 24)
	self:Template(d, "raised")
	d.Text = self:Font(d, 12)
	d.Text:SetPoint("LEFT", 8, 0)
	d.Text:SetPoint("RIGHT", -20, 0)
	d.Text:SetJustifyH("LEFT")
	d.arrow = d:CreateTexture(nil, "OVERLAY")
	d.arrow:SetSize(8, 8)
	d.arrow:SetPoint("RIGHT", -8, 0)
	d.arrow:SetTexture(self.tex.blank)
	d.arrow:SetVertexColor(self.colors.accent.r, self.colors.accent.g, self.colors.accent.b)
	d.menu = CreateFrame("Frame", nil, d, "BackdropTemplate")
	self:Template(d.menu, "panel")
	self:AccentEdge(d.menu, "TOP")
	d.menu:SetPoint("TOPLEFT", d, "BOTTOMLEFT", 0, -2)
	d.menu:SetPoint("TOPRIGHT", d, "BOTTOMRIGHT", 0, -2)
	d.menu:SetFrameStrata("TOOLTIP")
	d.menu:Hide()
	d.pool = {}
	d:SetScript("OnEnter", function() M:SetBorderLit(d, true) end)
	d:SetScript("OnLeave", function() M:SetBorderLit(d, false) end)

	local function BuildRoot()
		local items = {}
		local root = {}
		function root:CreateTitle(text) items[#items + 1] = { kind = "title", text = text } end
		function root:CreateRadio(text, isSel, onSel) items[#items + 1] = { kind = "radio", text = text, isSel = isSel, onSel = onSel } end
		function root:CreateCheckbox(text, isSel, onSel, arg) items[#items + 1] = { kind = "check", text = text, isSel = isSel, onSel = onSel, arg = arg } end
		function root:CreateButton(text, func) items[#items + 1] = { kind = "button", text = text, func = func } end
		function root:CreateDivider() items[#items + 1] = { kind = "divider" } end
		function root:CreateSpacer() items[#items + 1] = { kind = "divider" } end
		return root, items
	end

	function d:SetupMenu(generator) self.menuGen = generator end
	function d:SetText(t) self.Text:SetText(t) end
	function d:GetText() return self.Text:GetText() end
	function d:SetSelectionText(fn) self.selText = fn; if fn then self:SetText(fn()) end end
	function d:SetTooltip(fn)
		self.tooltipFn = fn
		self:HookScript("OnEnter", function(self2)
			if self2.tooltipFn then
				GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
				self2.tooltipFn(GameTooltip)
				GameTooltip:Show()
			end
		end)
		self:HookScript("OnLeave", GameTooltip_Hide)
	end
	function d:ClearMenuState() if self.menu then self.menu:Hide() end end

	local function Acquire(i)
		local b = d.pool[i]
		if b then return b end
		b = CreateFrame("Button", nil, d.menu)
		b:SetHeight(20)
		b.mark = b:CreateTexture(nil, "OVERLAY")
		b.mark:SetSize(8, 8)
		b.mark:SetTexture(M.tex.blank)
		b.mark:SetVertexColor(M.colors.accent.r, M.colors.accent.g, M.colors.accent.b)
		b.mark:SetPoint("LEFT", 8, 0)
		b.mark:Hide()
		b.txt = M:Font(b, 12)
		b.txt:SetPoint("LEFT", 20, 0)
		b.txt:SetPoint("RIGHT", -6, 0)
		b.txt:SetJustifyH("LEFT")
		b.hl = b:CreateTexture(nil, "HIGHLIGHT")
		b.hl:SetTexture(M.tex.blank)
		b.hl:SetVertexColor(M.colors.accent.r, M.colors.accent.g, M.colors.accent.b, 0.12)
		b.hl:SetAllPoints()
		d.pool[i] = b
		return b
	end

	local function Open()
		for _, m in ipairs(openMenus) do if m ~= d.menu then m:Hide() end end
		local root, items = BuildRoot()
		if d.menuGen then d.menuGen(d, root) end
		for _, b in ipairs(d.pool) do b:Hide() end
		local y = -6
		local poolIndex = 0
		for _, item in ipairs(items) do
			if item.kind == "title" then
				local t = d.menu["title" .. y]
				if not t then
					t = M:Font(d.menu, 10, nil, M.colors.accent)
					d.menu["title" .. y] = t
				end
				t:ClearAllPoints()
				t:SetPoint("TOPLEFT", d.menu, "TOPLEFT", 10, y - 4)
				t:SetText(item.text or "")
				t:Show()
				y = y - 16
			elseif item.kind == "divider" then
				y = y - 6
			else
				poolIndex = poolIndex + 1
				local b = Acquire(poolIndex)
				b:ClearAllPoints()
				b:SetPoint("TOPLEFT", d.menu, "TOPLEFT", 4, y)
				b:SetPoint("TOPRIGHT", d.menu, "TOPRIGHT", -4, y)
				b.txt:SetText(item.text or "")
				local selected = item.isSel and item.isSel() or false
				b.mark:SetShown(selected)
				b:SetScript("OnClick", function()
					if item.kind == "check" then
						if item.onSel then item.onSel(item.arg ~= nil and item.arg or nil) end
						b.mark:SetShown(item.isSel and item.isSel() or false)
					else
						if item.onSel then item.onSel() end
						if item.func then item.func() end
						d.menu:Hide()
					end
				end)
				b:Show()
				y = y - 20
			end
		end
		for key, t in pairs(d.menu) do
			if type(key) == "string" and key:sub(1, 5) == "title" then
				local used
				for _, item in ipairs(items) do
					if item.kind == "title" and t:GetText() == item.text then used = true break end
				end
				if not used then t:Hide() end
			end
		end
		d.menu:SetHeight(math.max(20, -y + 8))
		d.menu:Show()
	end

	d:SetScript("OnClick", function()
		if d.menu:IsShown() then d.menu:Hide() else Open() end
	end)
	tinsert(openMenus, d.menu)
	return d
end

-- editbox / search -------------------------------------------------------------
function M:EditBox(parent, w, h)
	local holder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	holder:SetSize(w or 160, h or 22)
	self:Template(holder, "inset")
	local e = CreateFrame("EditBox", nil, holder)
	e:SetPoint("TOPLEFT", 6, -2)
	e:SetPoint("BOTTOMRIGHT", -6, 2)
	e:SetFont(self.font.normal, 12, "")
	e:SetTextColor(self.colors.text.r, self.colors.text.g, self.colors.text.b)
	e:SetAutoFocus(false)
	e:SetScript("OnEscapePressed", function(self2) self2:ClearFocus() end)
	e:SetScript("OnEditFocusGained", function() M:SetBorderLit(holder, true) end)
	e:SetScript("OnEditFocusLost", function() M:SetBorderLit(holder, false) end)
	holder.edit = e
	return holder
end

-- native content background: talent-tree tile if present, else the journal tile
local BOOK_BG_ATLASES = {"talents-background-tile", "talents-animations-bg", "talents-bg", "talents-frame-bg"}
function M:ApplyBookBackground(tex)
	if not tex then return end
	if C_Texture and C_Texture.GetAtlasInfo then
		for _, atlas in ipairs(BOOK_BG_ATLASES) do
			if C_Texture.GetAtlasInfo(atlas) then
				tex:SetAtlas(atlas)
				tex:SetHorizTile(true)
				tex:SetVertTile(true)
				tex:SetVertexColor(1, 1, 1, 1)
				return
			end
		end
		if C_Texture.GetAtlasInfo("collections-background-tile") then
			tex:SetAtlas("collections-background-tile")
			tex:SetHorizTile(true)
			tex:SetVertTile(true)
			tex:SetVertexColor(1, 1, 1, 1)
			return
		end
	end
	tex:SetTexture(self.tex.blank)
	local c = self.colors.bgInset
	tex:SetVertexColor(c.r, c.g, c.b, 1)
end

-- restyle a Blizzard SearchBoxTemplate into the flat look
function M:SkinSearchBox(box)
	if not box then return end
	for _, key in ipairs({ "Left", "Middle", "Right", "Mid" }) do
		local tex = box[key]
		if tex and tex.Hide then tex:Hide() end
	end
	if box.SetBackdrop then
		self:Template(box, "inset")
		box:SetBackdropBorderColor(self.colors.border.r, self.colors.border.g, self.colors.border.b, 1)
	elseif not box.smBG then
		local bg = CreateFrame("Frame", nil, box:GetParent(), "BackdropTemplate")
		bg:SetAllPoints(box)
		bg:SetFrameLevel(math.max(0, box:GetFrameLevel() - 1))
		M:Template(bg, "inset")
		box.smBG = bg
	end
	local icon = box.SearchIcon or box.searchIcon
	if icon and icon.SetVertexColor then icon:SetVertexColor(self.colors.textDim.r, self.colors.textDim.g, self.colors.textDim.b) end
	box:HookScript("OnEditFocusGained", function() M:SetBorderLit(box, true) end)
	box:HookScript("OnEditFocusLost", function() M:SetBorderLit(box, false) end)
end

-- flat scroll holder -------------------------------------------------------------
function M:Scroll(parent, w, h)
	local holder = self:Panel(parent, w or 200, h or 200, "inset")
	local sf = CreateFrame("ScrollFrame", nil, holder)
	sf:SetPoint("TOPLEFT", 2, -2)
	sf:SetPoint("BOTTOMRIGHT", -16, 2)
	local child = CreateFrame("Frame", nil, sf)
	child:SetSize(1, 1)
	sf:SetScrollChild(child)
	holder.child = child
	holder.scroll = sf
	local bar = CreateFrame("Frame", nil, holder, "BackdropTemplate")
	bar:SetPoint("TOPRIGHT", -2, -2)
	bar:SetPoint("BOTTOMRIGHT", -2, 2)
	bar:SetWidth(10)
	self:Template(bar, "inset")
	local thumb = CreateFrame("Frame", nil, bar, "BackdropTemplate")
	thumb:SetWidth(6)
	self:Template(thumb, "raised")
	thumb:SetBackdropColor(self.colors.accent.r, self.colors.accent.g, self.colors.accent.b, 0.85)
	bar.thumb = thumb
	local function layout()
		local ch = child:GetHeight()
		local vh = sf:GetHeight()
		local range = math.max(0, ch - vh)
		sf.range = range
		if range <= 0 then thumb:Hide() return end
		thumb:Show()
		local th = math.max(20, bar:GetHeight() * vh / ch)
		thumb:SetHeight(th)
		local pct = (sf:GetVerticalScroll() or 0) / range
		thumb:ClearAllPoints()
		thumb:SetPoint("TOP", bar, "TOP", 0, -pct * (bar:GetHeight() - th))
	end
	holder.layoutScroll = layout
	sf:SetScript("OnVerticalScroll", function(_, v) layout() end)
	sf:SetScript("OnMouseWheel", function(self2, delta)
		self2:SetVerticalScroll(math.max(0, math.min(self2.range or 0, (self2:GetVerticalScroll() or 0) - delta * 30)))
		layout()
	end)
	child:SetScript("OnSizeChanged", layout)
	holder:SetScript("OnSizeChanged", layout)
	return holder
end

-- window frame (replaces the old library window) ----------------------------------
function SM:CreateUIWindowFrame(name, parent, templates)
	local f = M:Panel(parent, 400, 300, "panel")
	if name then _G[name] = f end
	f:SetFrameStrata("HIGH")
	f:SetClampedToScreen(true)
	M:AccentEdge(f, "TOP")
	f.titleBar = CreateFrame("Frame", nil, f)
	f.titleBar:SetPoint("TOPLEFT", 1, -1)
	f.titleBar:SetPoint("TOPRIGHT", -1, -1)
	f.titleBar:SetHeight(26)
	local accentLine = f.titleBar:CreateTexture(nil, "ARTWORK")
	accentLine:SetTexture(M.tex.blank)
	accentLine:SetVertexColor(M.colors.accent.r, M.colors.accent.g, M.colors.accent.b, 0.6)
	accentLine:SetHeight(1)
	accentLine:SetPoint("BOTTOMLEFT", f.titleBar, "BOTTOMLEFT", 0, 0)
	accentLine:SetPoint("BOTTOMRIGHT", f.titleBar, "BOTTOMRIGHT", 0, 0)
	f.TitleText = M:Font(f.titleBar, 13, nil, M.colors.accent)
	f.TitleText:SetPoint("CENTER", f.titleBar, "CENTER", 0, 0)
	f.TitleContainer = { TitleText = f.TitleText }
	f.closeButton = M:Button(f.titleBar, "x", 20, 18)
	f.closeButton:SetPoint("RIGHT", -4, 0)
	f.closeButton:SetScript("OnClick", function() f:Hide() end)
	if UISpecialFrames and name and not tContains(UISpecialFrames, name) then
		tinsert(UISpecialFrames, name)
	end
	return f
end

-- settings window (compatible with the window object the settings code builds) -----
function SM:CreateUIWindow(opts)
	local win = self:CreateUIWindowFrame(opts.name, UIParent)
	win:SetSize(opts.width or 520, opts.height or 560)
	win:SetPoint("CENTER")
	win:SetMovable(true)
	win:EnableMouse(true)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", win.StopMovingOrSizing)
	win.TitleText:SetText(opts.title or "")
	win.entries = {}
	win.controls = {}
	win.searchText = ""
	local scroll = M:Scroll(win, opts.width - 32, opts.height - 74)
	scroll:SetPoint("TOPLEFT", 16, -52)
	scroll:SetPoint("BOTTOMRIGHT", -16, 16)
	win.scrollArea = scroll
	win.content = scroll.child
	win.content:SetWidth((opts.width or 520) - 60)

	local function ControlBase(control, height)
		control:SetHeight(height or 24)
		control.deps = {}
		control.requires = {}
		win.controls[#win.controls + 1] = control
		return control
	end

	function win:Layout()
		local y = -4
		local search = (self.searchText or ""):lower()
		for _, entry in ipairs(self.entries) do
			local frame = entry.frame
			local visible = true
			if search ~= "" and entry.searchable then
				visible = (entry.searchText or ""):lower():find(search, 1, true) ~= nil
			end
			if visible then
				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", entry.indent or 0, y)
				frame:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, y)
				frame:Show()
				y = y - (frame:GetHeight() + entry.gap)
			else
				frame:Hide()
			end
		end
		self.content:SetHeight(math.max(1, -y + 8))
		if scroll.layoutScroll then scroll.layoutScroll() end
	end

	function win:AddCategory(def)
		local holder = CreateFrame("Frame", nil, self.content)
		holder:SetHeight(28)
		local label = M:Font(holder, 13, nil, M.colors.accent)
		label:SetPoint("TOPLEFT", 0, -2)
		label:SetText(SM:Trans(def.label) or def.key or "")
		local line = holder:CreateTexture(nil, "ARTWORK")
		line:SetTexture(M.tex.blank)
		line:SetVertexColor(M.colors.border.r, M.colors.border.g, M.colors.border.b, 1)
		line:SetHeight(1)
		line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
		line:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -9)
		self.entries[#self.entries + 1] = { frame = holder, gap = 6, searchable = false, indent = 0 }
		return holder
	end

	function win:AddCheckbox(def)
		local box = M:Check(self.content, SM:Trans(def.label) or def.label, (self:GetWidth() or 460) - 60)
		ControlBase(box, 24)
		box:SetChecked(def.value)
		box:SetScript("OnClick", function(self2)
			if def.func then def.func(self2.checked) end
		end)
		self.entries[#self.entries + 1] = { frame = box, gap = 4, searchable = true, searchText = SM:Trans(def.label) or def.label or "", indent = 14 }
		return box
	end

	function win:AddDropdown(def)
		local holder = CreateFrame("Frame", nil, self.content)
		holder:SetHeight(40)
		local label = M:Font(holder, 11, nil, M.colors.textDim)
		label:SetPoint("TOPLEFT", 0, 0)
		label:SetText(SM:Trans(def.label) or def.label or "")
		local dd = M:Dropdown(holder, 240)
		dd:SetPoint("BOTTOMLEFT", 0, 2)
		local function Label(v)
			for _, choice in ipairs(def.choices or {}) do
				if choice.value == v then return SM:Trans(choice.label) or choice.label end
			end
			return tostring(v)
		end
		local current = def.value
		dd:SetText(Label(current))
		dd:SetupMenu(function(_, root)
			for _, choice in ipairs(def.choices or {}) do
				local v = choice.value
				root:CreateRadio(Label(v), function() return current == v end, function()
					current = v
					dd:SetText(Label(v))
					if def.func then def.func(v) end
				end)
			end
		end)
		ControlBase(holder, 40)
		holder.dropdown = dd
		self.entries[#self.entries + 1] = { frame = holder, gap = 4, searchable = true, searchText = SM:Trans(def.label) or def.label or "", indent = 14 }
		return holder
	end

	function win:AddInfo(def)
		local holder = CreateFrame("Frame", nil, self.content)
		holder:SetHeight(18)
		local label = M:Font(holder, 11, nil, M.colors.textDim)
		label:SetPoint("TOPLEFT", 0, -2)
		label:SetText(SM:Trans(def.label) or def.label or "")
		local value = M:Font(holder, 12)
		value:SetPoint("TOPLEFT", 140, -2)
		value:SetText(def.text or "")
		if def.color then value:SetTextColor(def.color.r, def.color.g, def.color.b) end
		ControlBase(holder, 18)
		self.entries[#self.entries + 1] = {frame = holder, gap = 2, searchable = true, searchText = (SM:Trans(def.label) or "") .. " " .. (def.text or ""), indent = 14}
		return holder
	end

	function win:AddDependency(control, fn, indent)
		control.deps[#control.deps + 1] = { fn = fn, indent = indent }
		for _, entry in ipairs(self.entries) do
			if entry.frame == control then entry.indent = 14 + (indent or 0) * 14 end
		end
	end

	function win:AddRequirement(control, parent)
		control.requires[#control.requires + 1] = parent
	end

	function win:UpdateDependencies()
		for _, control in ipairs(self.controls) do
			local ok = true
			for _, dep in ipairs(control.deps) do
				if dep.fn and not dep.fn() then ok = false end
			end
			for _, parent in ipairs(control.requires) do
				if parent.GetChecked and not parent:GetChecked() then ok = false end
				if parent.checked == false then ok = false end
			end
			control:SetAlpha(ok and 1 or 0.4)
			if control.EnableMouse then control:EnableMouse(ok) end
		end
	end

	function win:AddSearch()
		if self.searchBox then return end
		local holder = M:EditBox(self, 150, 20)
		holder:SetPoint("TOPRIGHT", self.titleBar, "TOPRIGHT", -30, -3)
		holder.edit:SetScript("OnTextChanged", function(box)
			self.searchText = box:GetText() or ""
			self:Layout()
		end)
		self.searchBox = holder
	end

	return win
end

-- minimap button -------------------------------------------------------------------
SM.minimapButtons = {}
function SM:CreateMinimapButton(def)
	local name = def.name
	local button = CreateFrame("Button", name .. "MinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(8)
	button.icon = button:CreateTexture(nil, "BACKGROUND")
	button.icon:SetPoint("CENTER")
	button.icon:SetSize(20, 20)
	button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
	button.icon:SetTexture(def.icon or 133741)
	local ring = button:CreateTexture(nil, "OVERLAY")
	ring:SetSize(53, 53)
	ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	ring:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
	local hl = button:CreateTexture(nil, "HIGHLIGHT")
	hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	hl:SetBlendMode("ADD")
	hl:SetAllPoints()
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	local function UpdatePos()
		local db = def.dbtab
		local angle = (db and db["minimapPos" .. name]) or 225
		local x = math.cos(math.rad(angle)) * 80
		local y = math.sin(math.rad(angle)) * 80
		button:ClearAllPoints()
		button:SetPoint("CENTER", Minimap, "CENTER", x, y)
	end
	button:SetScript("OnDragStart", function(self2)
		self2.dragging = true
		self2:SetScript("OnUpdate", function()
			local mx, my = Minimap:GetCenter()
			local cx, cy = GetCursorPosition()
			local scale = UIParent:GetEffectiveScale()
			local angle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
			if def.dbtab then def.dbtab["minimapPos" .. name] = angle end
			UpdatePos()
		end)
	end)
	button:SetScript("OnDragStop", function(self2)
		self2.dragging = nil
		self2:SetScript("OnUpdate", nil)
	end)
	button:SetScript("OnClick", function(_, btn)
		if btn == "RightButton" and def.funcR then def.funcR() elseif def.funcL then def.funcL() end
	end)
	button:SetScript("OnEnter", function(self2)
		GameTooltip:SetOwner(self2, "ANCHOR_LEFT")
		for _, line in ipairs(def.vTT or {}) do
			GameTooltip:AddLine(line[1] or "", 1, 1, 1)
		end
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	UpdatePos()
	button:SetShown(not def.dbtab or def.dbtab[def.dbkey or "showMinimapButton"] ~= false)
	self.minimapButtons[name] = button
	return button
end

function SM:ShowMMBtn(name)
	local b = self.minimapButtons[name]
	if b then b:Show() end
end

function SM:HideMMBtn(name)
	local b = self.minimapButtons[name]
	if b then b:Hide() end
end

function SM:IsClassicUIForeverProfessions()
	return false
end
