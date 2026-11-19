-- Veloria Hub UI Library | Dark Edition
-- Layout: Sidebar + Topbar + Tabs, matches Stealth-X style
-- Usage: local VLH = loadstring(...)() or require(...)

local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local TextService    = game:GetService("TextService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ─────────────────────────────────────────────
-- THEME
-- ─────────────────────────────────────────────
local Theme = {
    -- backgrounds
    BG          = Color3.fromRGB(13, 13, 15),
    BGAlt       = Color3.fromRGB(18, 18, 21),
    Panel       = Color3.fromRGB(22, 22, 26),
    Card        = Color3.fromRGB(26, 26, 30),
    CardHover   = Color3.fromRGB(32, 32, 38),
    -- text
    Text        = Color3.fromRGB(230, 230, 235),
    TextDim     = Color3.fromRGB(120, 120, 130),
    TextDisabled= Color3.fromRGB(70, 70, 80),
    -- accent
    Accent      = Color3.fromRGB(100, 100, 110),
    AccentLine  = Color3.fromRGB(60, 60, 70),
    -- controls
    Toggle      = Color3.fromRGB(40, 160, 90),
    ToggleOff   = Color3.fromRGB(50, 50, 58),
    Slider      = Color3.fromRGB(80, 80, 95),
    SliderFill  = Color3.fromRGB(180, 180, 200),
    -- sidebar
    SidebarBG   = Color3.fromRGB(16, 16, 19),
    SidebarText = Color3.fromRGB(100, 100, 110),
    SideTabActive   = Color3.fromRGB(28, 28, 33),
    SideTabText     = Color3.fromRGB(210, 210, 220),
    -- topbar
    TopbarBG    = Color3.fromRGB(13, 13, 15),
    TopbarText  = Color3.fromRGB(220, 220, 230),
    -- border
    Border      = Color3.fromRGB(38, 38, 45),
    BorderLight = Color3.fromRGB(55, 55, 65),
    -- red
    Red         = Color3.fromRGB(220, 55, 60),
    RedHover    = Color3.fromRGB(255, 80, 85),
    -- white
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0, 0, 0),
}

-- ─────────────────────────────────────────────
-- UTILITY
-- ─────────────────────────────────────────────
local U = {}

function U.Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

function U.Corner(inst, r)
    return U.Create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, inst)
end

function U.Stroke(inst, color, trans, thick)
    return U.Create("UIStroke", {
        Color = color or Theme.Border,
        Transparency = trans or 0,
        Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, inst)
end

function U.Padding(inst, t, r, b, l)
    return U.Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or 0),
        PaddingBottom = UDim.new(0, b or 0),
        PaddingLeft   = UDim.new(0, l or 0),
    }, inst)
end

function U.ListLayout(inst, dir, align, padding)
    return U.Create("UIListLayout", {
        FillDirection = dir or Enum.FillDirection.Vertical,
        HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or 0),
    }, inst)
end

function U.Tween(inst, t, props, style, dir)
    local tween = TweenService:Create(inst,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props)
    tween:Play()
    return tween
end

function U.Label(parent, props)
    local defaults = {
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.Text,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        RichText = false,
    }
    for k, v in pairs(props) do defaults[k] = v end
    return U.Create("TextLabel", defaults, parent)
end

function U.Ripple(btn, color)
    btn.ClipsDescendants = true
    btn.MouseButton1Down:Connect(function(x, y)
        local abs = btn.AbsolutePosition
        local rx, ry = x - abs.X, y - abs.Y
        local c = U.Create("Frame", {
            BackgroundColor3 = color or Theme.White,
            BackgroundTransparency = 0.85,
            BorderSizePixel = 0,
            Position = UDim2.new(0, rx - 4, 0, ry - 4),
            Size = UDim2.new(0, 8, 0, 8),
            ZIndex = btn.ZIndex + 1,
        }, btn)
        U.Corner(c, 999)
        U.Tween(c, 0.35, { Size = UDim2.new(0, 80, 0, 80), Position = UDim2.new(0, rx - 40, 0, ry - 40), BackgroundTransparency = 1 })
        task.delay(0.4, function() c:Destroy() end)
    end)
end

function U.AutoSize(frame, axis)
    frame.AutomaticSize = axis or Enum.AutomaticSize.Y
end

-- ─────────────────────────────────────────────
-- DRAGGING
-- ─────────────────────────────────────────────
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ─────────────────────────────────────────────
-- ICON PATHS (SVG-like string icons via ImageLabel not available;
-- we use text glyphs or simple Frame shapes)
-- For topbar icon we use the custom asset id
-- ─────────────────────────────────────────────
local Icons = {
    community = "rbxassetid://3926305904", -- group icon placeholder
    discord   = "rbxassetid://3926307971",
    farm      = "rbxassetid://3926305904",
    shop      = "rbxassetid://3926307971",
    activity  = "rbxassetid://3926307971",
    tools     = "rbxassetid://3926307971",
    utility   = "rbxassetid://3926307971",
    server    = "rbxassetid://3926307971",
    settings  = "rbxassetid://3926305904",
    close     = "rbxassetid://3926307971",
    search    = "rbxassetid://3926307971",
    minimize  = "rbxassetid://3926307971",
    check     = "rbxassetid://3926307971",
    chevron   = "rbxassetid://3926307971",
    slider    = "rbxassetid://3926307971",
    keybind   = "rbxassetid://3926307971",
    color     = "rbxassetid://3926307971",
    copy      = "rbxassetid://3926307971",
    link      = "rbxassetid://3926307971",
}

-- ─────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────
local NotifyGui
local NotifyHolder

local function EnsureNotifyGui()
    if NotifyGui and NotifyGui.Parent then return end
    local sg = pcall(function()
        NotifyGui = U.Create("ScreenGui", {
            Name = "VLHNotify",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            DisplayOrder = 999,
        }, CoreGui)
    end)
    if not sg then
        NotifyGui = U.Create("ScreenGui", {
            Name = "VLHNotify",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            DisplayOrder = 999,
        }, LocalPlayer.PlayerGui)
    end
    NotifyHolder = U.Create("Frame", {
        Name = "Holder",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 280, 1, -32),
    }, NotifyGui)
    local layout = U.ListLayout(NotifyHolder, Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, 6)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

local function Notify(opts)
    if type(opts) == "string" then opts = { Title = "VLH", Content = opts } end
    EnsureNotifyGui()

    local title   = tostring(opts.Title or opts[1] or "Veloria Hub")
    local content = tostring(opts.Content or opts[2] or "")
    local duration = tonumber(opts.Duration or opts[3] or 3)

    local card = U.Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ClipsDescendants = true,
        BackgroundTransparency = 0.05,
    }, NotifyHolder)
    U.Corner(card, 8)
    U.Stroke(card, Theme.Border, 0, 1)

    local accent = U.Create("Frame", {
        BackgroundColor3 = Theme.SliderFill,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 3, 1, 0),
    }, card)
    U.Corner(accent, 2)

    local inner = U.Create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
    }, card)
    U.Padding(inner, 8, 10, 8, 2)
    U.ListLayout(inner, Enum.FillDirection.Vertical, nil, 3)

    U.Label(inner, {
        Text = title,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Text,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 1,
    })
    if content ~= "" then
        U.Label(inner, {
            Text = content,
            TextSize = 10,
            TextColor3 = Theme.TextDim,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextWrapped = true,
            LayoutOrder = 2,
        })
    end

    card.BackgroundTransparency = 1
    U.Tween(card, 0.2, { BackgroundTransparency = 0.05 })
    task.delay(duration, function()
        U.Tween(card, 0.2, { BackgroundTransparency = 1 })
        task.delay(0.25, function() card:Destroy() end)
    end)
end

-- ─────────────────────────────────────────────
-- LIBRARY
-- ─────────────────────────────────────────────
local VLH = {}
VLH.__index = VLH
VLH.Notify = Notify
VLH.Flags = {}
VLH.ConfigFolder = "VeloriaHub/Configs"

-- ─────────────────────────────────────────────
-- CREATE WINDOW
-- ─────────────────────────────────────────────
function VLH:CreateWindow(opts)
    opts = opts or {}
    local Title       = tostring(opts[1] or opts.Title or "Veloria Hub")
    local Description = tostring(opts[2] or opts.Description or "")
    local SideWidth   = tonumber(opts[3] or opts.SidebarWidth or 112)
    local Size        = opts[4] or opts.Size or UDim2.fromOffset(530, 310)
    local Keybind     = opts[5] or opts.Keybind or Enum.KeyCode.RightControl
    local Icon        = tostring(opts[6] or opts.Icon or "rbxassetid://131946786209484")

    -- Root ScreenGui
    local ScreenGui
    local ok = pcall(function()
        ScreenGui = U.Create("ScreenGui", {
            Name = "VeloriaHub",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 100,
        }, CoreGui)
    end)
    if not ok then
        ScreenGui = U.Create("ScreenGui", {
            Name = "VeloriaHub",
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 100,
        }, LocalPlayer.PlayerGui)
    end

    -- Blur / backdrop dim
    local Backdrop = U.Create("Frame", {
        Name = "Backdrop",
        BackgroundColor3 = Theme.Black,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 0,
        Visible = false,
    }, ScreenGui)

    -- Main window frame
    local Win = U.Create("Frame", {
        Name = "Window",
        BackgroundColor3 = Theme.BG,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = Size,
        ClipsDescendants = true,
    }, ScreenGui)
    U.Corner(Win, 10)
    U.Stroke(Win, Theme.Border, 0, 1)

    -- ── TOPBAR ──────────────────────────────
    local Topbar = U.Create("Frame", {
        Name = "Topbar",
        BackgroundColor3 = Theme.TopbarBG,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        ZIndex = 10,
    }, Win)
    -- subtle bottom border on topbar
    U.Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
    }, Topbar)

    -- Logo icon in topbar
    local TopIcon = U.Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 18, 0, 18),
        Image = Icon,
        ImageColor3 = Theme.Text,
    }, Topbar)

    -- Window title
    local TopTitle = U.Label(Topbar, {
        Text = Title,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.TopbarText,
        Position = UDim2.new(0, 34, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 160, 0, 20),
    })

    -- Separator between title and game label
    U.Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 200, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 1, 0, 16),
    }, Topbar)

    -- Game/subtitle label (right of separator)
    local TopSub = U.Label(Topbar, {
        Text = Description,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.TextDim,
        Position = UDim2.new(0, 208, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 180, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
    })

    -- Search box
    local SearchHolder = U.Create("Frame", {
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -78, 0.5, 0),
        Size = UDim2.new(0, 100, 0, 22),
    }, Topbar)
    U.Corner(SearchHolder, 5)
    U.Stroke(SearchHolder, Theme.Border, 0, 1)
    -- search icon placeholder
    U.Label(SearchHolder, {
        Text = "🔍",
        TextSize = 10,
        TextColor3 = Theme.TextDim,
        Position = UDim2.new(0, 4, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 16, 0, 16),
        Font = Enum.Font.Gotham,
    })
    local SearchBox = U.Create("TextBox", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search",
        PlaceholderColor3 = Theme.TextDim,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
    }, SearchHolder)

    -- Minimize button
    local MinBtn = U.Create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "−",
        TextColor3 = Theme.TextDim,
        TextSize = 16,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -32, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
    }, Topbar)

    -- Close button
    local CloseBtn = U.Create("TextButton", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Theme.TextDim,
        TextSize = 18,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0, 24, 0, 24),
    }, Topbar)
    CloseBtn.MouseEnter:Connect(function() CloseBtn.TextColor3 = Theme.Red end)
    CloseBtn.MouseLeave:Connect(function() CloseBtn.TextColor3 = Theme.TextDim end)

    -- ── BODY ─────────────────────────────────
    local Body = U.Create("Frame", {
        Name = "Body",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 36),
        Size = UDim2.new(1, 0, 1, -36),
        ClipsDescendants = true,
    }, Win)

    -- ── SIDEBAR ──────────────────────────────
    local Sidebar = U.Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.SidebarBG,
        BorderSizePixel = 0,
        Size = UDim2.new(0, SideWidth, 1, 0),
    }, Body)
    -- right border line
    U.Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0),
    }, Sidebar)

    local SideScroll = U.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true,
    }, Sidebar)
    local SideList = U.ListLayout(SideScroll, Enum.FillDirection.Vertical, nil, 1)
    U.Padding(SideScroll, 6, 0, 6, 0)

    -- ── CONTENT AREA ─────────────────────────
    local ContentHolder = U.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, SideWidth, 0, 0),
        Size = UDim2.new(1, -SideWidth, 1, 0),
        ClipsDescendants = true,
    }, Body)

    -- ── DRAGGING ─────────────────────────────
    MakeDraggable(Topbar, Win)

    -- ── OPEN/CLOSE ───────────────────────────
    local WinVisible = true
    local function SetVisible(v)
        WinVisible = v
        Win.Visible = v
    end

    MinBtn.MouseButton1Click:Connect(function()
        SetVisible(not WinVisible)
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        SetVisible(false)
    end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Keybind then
            SetVisible(not WinVisible)
        end
    end)

    -- ── WINDOW OBJECT ────────────────────────
    local WindowObj = {
        _screen      = ScreenGui,
        _win         = Win,
        _topbar      = Topbar,
        _sidebar     = Sidebar,
        _sideScroll  = SideScroll,
        _sideList    = SideList,
        _content     = ContentHolder,
        _searchBox   = SearchBox,
        _tabs        = {},
        _sideGroups  = {},
        _currentTab  = nil,
    }

    -- ── SEARCH FILTER ────────────────────────
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(SearchBox.Text)
        if query == "" then
            for _, tab in ipairs(WindowObj._tabs) do
                for _, element in ipairs(tab._elements or {}) do
                    if element._frame then element._frame.Visible = true end
                end
            end
            return
        end
        for _, tab in ipairs(WindowObj._tabs) do
            for _, element in ipairs(tab._elements or {}) do
                if element._frame and element._name then
                    element._frame.Visible = string.find(string.lower(element._name), query, 1, true) ~= nil
                end
            end
        end
    end)

    -- ── SIDEBAR CATEGORY LABEL ───────────────
    function WindowObj:AddSideCategory(name)
        local lbl = U.Label(SideScroll, {
            Text = string.upper(name),
            TextSize = 9,
            Font = Enum.Font.GothamBold,
            TextColor3 = Theme.TextDisabled,
            Size = UDim2.new(1, 0, 0, 20),
            LayoutOrder = #SideScroll:GetChildren(),
        })
        U.Padding(lbl, 0, 0, 0, 10)
        return lbl
    end

    -- ── ADD TAB ──────────────────────────────
    function WindowObj:AddTab(opts)
        opts = opts or {}
        local tabName = tostring(opts[1] or opts.Name or opts.Title or "Tab")
        local tabIcon = tostring(opts[2] or opts.Icon or "")
        local tabOrder = #self._tabs + 1

        -- Sidebar button
        local SideBtn = U.Create("TextButton", {
            Name = "Tab_" .. tabName,
            BackgroundColor3 = Theme.SidebarBG,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = tabOrder * 10,
        }, SideScroll)
        U.Corner(SideBtn, 6)

        local SideBtnInner = U.Create("Frame", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(1, -8, 1, 0),
        }, SideBtn)
        local SideBtnLayout = U.ListLayout(SideBtnInner, Enum.FillDirection.Horizontal, nil, 6)
        SideBtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center

        -- Icon dot / symbol
        local SideIconFrame = U.Create("Frame", {
            BackgroundColor3 = Theme.SidebarText,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 14, 0, 14),
            LayoutOrder = 1,
        }, SideBtnInner)
        U.Corner(SideIconFrame, 3)
        -- inner icon fill
        U.Create("Frame", {
            BackgroundColor3 = Theme.SidebarBG,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(0, 6, 0, 6),
        }, SideIconFrame)

        local SideLbl = U.Label(SideBtnInner, {
            Text = tabName,
            TextSize = 11,
            Font = Enum.Font.GothamMedium,
            TextColor3 = Theme.SidebarText,
            Size = UDim2.new(1, -20, 1, 0),
            LayoutOrder = 2,
        })

        -- Tab content page (ScrollingFrame)
        local Page = U.Create("ScrollingFrame", {
            Name = "Page_" .. tabName,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true,
            Visible = false,
        }, ContentHolder)
        U.Padding(Page, 8, 10, 10, 10)
        U.ListLayout(Page, Enum.FillDirection.Vertical, nil, 6)

        -- Tab object
        local TabObj = {
            _btn      = SideBtn,
            _icon     = SideIconFrame,
            _label    = SideLbl,
            _page     = Page,
            _name     = tabName,
            _elements = {},
            _window   = self,
        }

        -- Activate tab
        local function Activate()
            -- deactivate all
            for _, t in ipairs(self._tabs) do
                t._page.Visible = false
                t._btn.BackgroundColor3 = Theme.SidebarBG
                t._label.TextColor3 = Theme.SidebarText
                t._icon.BackgroundColor3 = Theme.SidebarText
            end
            -- activate this
            Page.Visible = true
            SideBtn.BackgroundColor3 = Theme.SideTabActive
            SideLbl.TextColor3 = Theme.SideTabText
            SideIconFrame.BackgroundColor3 = Theme.SliderFill
            self._currentTab = TabObj
        end

        SideBtn.MouseButton1Click:Connect(Activate)
        SideBtn.MouseEnter:Connect(function()
            if self._currentTab ~= TabObj then
                U.Tween(SideBtn, 0.1, { BackgroundColor3 = Theme.CardHover })
            end
        end)
        SideBtn.MouseLeave:Connect(function()
            if self._currentTab ~= TabObj then
                U.Tween(SideBtn, 0.15, { BackgroundColor3 = Theme.SidebarBG })
            end
        end)

        table.insert(self._tabs, TabObj)

        -- Auto-select first tab
        if #self._tabs == 1 then
            task.defer(Activate)
        end

        -- ── SECTION ──────────────────────────
        function TabObj:AddSection(opts)
            opts = opts or {}
            if type(opts) == "string" then opts = { opts } end
            local sectionName = tostring(opts[1] or opts.Name or opts.Title or "")

            local SecFrame = U.Create("Frame", {
                Name = "Section_" .. sectionName,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                LayoutOrder = #Page:GetChildren(),
            }, Page)
            U.ListLayout(SecFrame, Enum.FillDirection.Vertical, nil, 4)
            U.Padding(SecFrame, 0, 0, 0, 0)

            if sectionName ~= "" then
                local SecHeader = U.Create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 20),
                    LayoutOrder = 1,
                }, SecFrame)
                local layout = U.ListLayout(SecHeader, Enum.FillDirection.Horizontal, nil, 6)
                layout.VerticalAlignment = Enum.VerticalAlignment.Center

                U.Label(SecHeader, {
                    Text = sectionName,
                    TextSize = 10,
                    Font = Enum.Font.GothamBold,
                    TextColor3 = Theme.TextDim,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    LayoutOrder = 1,
                })
                -- line after label
                U.Create("Frame", {
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -60, 0, 1),
                    AnchorPoint = Vector2.new(0, 0.5),
                    LayoutOrder = 2,
                }, SecHeader)
            end

            local SectionObj = {
                _frame    = SecFrame,
                _page     = Page,
                _tab      = TabObj,
                _elements = TabObj._elements,
            }

            -- ────── ADD BUTTON ────────────────
            function SectionObj:AddButton(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name     = tostring(opts[1] or opts.Name or "Button")
                local desc     = tostring(opts[2] or opts.Description or opts.Content or "")
                local callback = opts[3] or opts.Callback or function() end

                local Btn = U.Create("TextButton", {
                    Name = "Button_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                    ClipsDescendants = true,
                }, SecFrame)
                U.Corner(Btn, 7)
                U.Stroke(Btn, Theme.Border, 0.3, 1)
                U.Ripple(Btn)

                local innerLayout = U.ListLayout(Btn, Enum.FillDirection.Horizontal, nil, 0)
                innerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                innerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

                -- left icon bar
                U.Create("Frame", {
                    BackgroundColor3 = Theme.SliderFill,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    Size = UDim2.new(0, 3, 1, 0),
                    LayoutOrder = 1,
                }, Btn)

                local LabelHolder = U.Create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -3, 1, 0),
                    LayoutOrder = 2,
                }, Btn)
                U.Padding(LabelHolder, 0, 8, 0, 8)

                U.Label(LabelHolder, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, 0, 0, desc ~= "" and 14 or 18),
                    Position = UDim2.new(0, 0, desc ~= "" and 0.1 or 0.5, 0),
                    AnchorPoint = Vector2.new(0, desc ~= "" and 0 or 0.5),
                })
                if desc ~= "" then
                    U.Label(LabelHolder, {
                        Text = desc,
                        TextSize = 9,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        Size = UDim2.new(1, 0, 0, 12),
                        Position = UDim2.new(0, 0, 1, -14),
                    })
                end

                Btn.MouseEnter:Connect(function()
                    U.Tween(Btn, 0.1, { BackgroundColor3 = Theme.CardHover })
                end)
                Btn.MouseLeave:Connect(function()
                    U.Tween(Btn, 0.15, { BackgroundColor3 = Theme.Card })
                end)
                Btn.MouseButton1Click:Connect(function()
                    task.spawn(callback)
                end)

                local el = { _frame = Btn, _name = name }
                table.insert(self._elements, el)
                return { Button = Btn, SetName = function(n) end }
            end

            -- ────── ADD TOGGLE ────────────────
            function SectionObj:AddToggle(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name     = tostring(opts[1] or opts.Name or "Toggle")
                local default  = opts[2] or opts.Default or false
                local callback = opts[3] or opts.Callback or function() end
                local flagId   = opts.Flag or name

                local value = default == true

                local Row = U.Create("Frame", {
                    Name = "Toggle_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 0, 10, 0, 10)

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(1, -44, 0, 18),
                })

                -- Toggle pill
                local Pill = U.Create("Frame", {
                    BackgroundColor3 = value and Theme.Toggle or Theme.ToggleOff,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 32, 0, 16),
                }, Row)
                U.Corner(Pill, 999)

                local Knob = U.Create("Frame", {
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, value and 18 or 2, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                }, Pill)
                U.Corner(Knob, 999)

                local function SetValue(v, fromFlag)
                    value = v
                    U.Tween(Pill, 0.15, { BackgroundColor3 = v and Theme.Toggle or Theme.ToggleOff })
                    U.Tween(Knob, 0.15, { Position = UDim2.new(0, v and 18 or 2, 0.5, 0) })
                    VLH.Flags[flagId] = v
                    if not fromFlag then task.spawn(callback, v) end
                end
                SetValue(value, true)

                local ClickBtn = U.Create("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                }, Row)
                ClickBtn.MouseButton1Click:Connect(function()
                    SetValue(not value)
                end)
                Row.MouseEnter:Connect(function()
                    U.Tween(Row, 0.1, { BackgroundColor3 = Theme.CardHover })
                end)
                Row.MouseLeave:Connect(function()
                    U.Tween(Row, 0.15, { BackgroundColor3 = Theme.Card })
                end)

                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
                return {
                    Toggle = ClickBtn,
                    Set = SetValue,
                    Get = function() return value end,
                }
            end

            -- ────── ADD SLIDER ────────────────
            function SectionObj:AddSlider(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name     = tostring(opts[1] or opts.Name or "Slider")
                local min      = tonumber(opts[2] or opts.Min or 0)
                local max      = tonumber(opts[3] or opts.Max or 100)
                local default  = tonumber(opts[4] or opts.Default or min)
                local callback = opts[5] or opts.Callback or function() end
                local flagId   = opts.Flag or name
                local suffix   = tostring(opts.Suffix or "")
                local decimal  = tonumber(opts.Decimal or 0)

                local value = math.clamp(default, min, max)

                local Row = U.Create("Frame", {
                    Name = "Slider_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 6, 10, 6, 10)

                local TopRow = U.Create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 16),
                    LayoutOrder = 1,
                }, Row)
                local layout = U.ListLayout(Row, Enum.FillDirection.Vertical, nil, 4)

                U.Label(TopRow, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, -50, 1, 0),
                })
                local ValLbl = U.Label(TopRow, {
                    Text = tostring(value) .. suffix,
                    TextSize = 10,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 50, 1, 0),
                })

                -- Track
                local Track = U.Create("Frame", {
                    BackgroundColor3 = Theme.Slider,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 4),
                    LayoutOrder = 2,
                }, Row)
                U.Corner(Track, 999)
                local Fill = U.Create("Frame", {
                    BackgroundColor3 = Theme.SliderFill,
                    BorderSizePixel = 0,
                    Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                }, Track)
                U.Corner(Fill, 999)
                local Knob = U.Create("Frame", {
                    BackgroundColor3 = Theme.White,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                    Size = UDim2.new(0, 10, 0, 10),
                    ZIndex = 2,
                }, Track)
                U.Corner(Knob, 999)

                local function SetValue(v, fromFlag)
                    local mult = 10 ^ decimal
                    v = math.floor(math.clamp(v, min, max) * mult + 0.5) / mult
                    value = v
                    local pct = (v - min) / (max - min)
                    Fill.Size = UDim2.new(pct, 0, 1, 0)
                    Knob.Position = UDim2.new(pct, 0, 0.5, 0)
                    ValLbl.Text = tostring(v) .. suffix
                    VLH.Flags[flagId] = v
                    if not fromFlag then task.spawn(callback, v) end
                end

                local dragging = false
                local function UpdateFromInput(input)
                    local abs = Track.AbsolutePosition
                    local sz  = Track.AbsoluteSize
                    local pct = math.clamp((input.Position.X - abs.X) / sz.X, 0, 1)
                    SetValue(min + pct * (max - min))
                end

                Track.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateFromInput(input)
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateFromInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                Row.MouseEnter:Connect(function()
                    U.Tween(Row, 0.1, { BackgroundColor3 = Theme.CardHover })
                end)
                Row.MouseLeave:Connect(function()
                    U.Tween(Row, 0.15, { BackgroundColor3 = Theme.Card })
                end)

                SetValue(value, true)
                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
                return { Set = SetValue, Get = function() return value end }
            end

            -- ────── ADD DROPDOWN ─────────────
            function SectionObj:AddDropdown(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name     = tostring(opts[1] or opts.Name or "Dropdown")
                local options  = opts[2] or opts.Options or {}
                local default  = opts[3] or opts.Default or (options[1] or "")
                local callback = opts[4] or opts.Callback or function() end
                local flagId   = opts.Flag or name
                local multi    = opts.Multi == true

                local selected = multi and {} or default
                if multi and type(default) == "table" then selected = default end

                local open = false
                local Row = U.Create("Frame", {
                    Name = "Dropdown_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                    ClipsDescendants = false,
                    ZIndex = 5,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 0, 10, 0, 10)

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.6, 0, 0, 18),
                })

                local CurLbl = U.Label(Row, {
                    Text = multi and "Select..." or tostring(selected),
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -14, 0.5, 0),
                    Size = UDim2.new(0.35, 0, 0, 18),
                    TextTruncate = Enum.TextTruncate.AtEnd,
                })

                -- chevron
                local ChevLbl = U.Label(Row, {
                    Text = "▾",
                    TextSize = 10,
                    TextColor3 = Theme.TextDim,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -1, 0.5, 0),
                    Size = UDim2.new(0, 12, 0, 12),
                    TextXAlignment = Enum.TextXAlignment.Right,
                })

                -- Dropdown list (spawned as child of Page to avoid clipping)
                local DropList = U.Create("Frame", {
                    Name = "DropList",
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ZIndex = 20,
                    ClipsDescendants = true,
                }, Row)
                U.Corner(DropList, 7)
                U.Stroke(DropList, Theme.Border, 0, 1)
                local DropScroll = U.Create("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 1, 0),
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Theme.Border,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 20,
                }, DropList)
                U.ListLayout(DropScroll)
                U.Padding(DropScroll, 4, 0, 4, 0)

                local function Refresh()
                    for _, c in ipairs(DropScroll:GetChildren()) do
                        if c:IsA("GuiObject") and c.Name ~= "UIListLayout" and c.Name ~= "UIPadding" then
                            c:Destroy()
                        end
                    end
                    for i, opt in ipairs(options) do
                        local isSelected = multi and table.find(selected, opt) ~= nil or selected == opt
                        local OptBtn = U.Create("TextButton", {
                            BackgroundColor3 = isSelected and Theme.CardHover or Theme.Panel,
                            BackgroundTransparency = 0,
                            BorderSizePixel = 0,
                            Size = UDim2.new(1, 0, 0, 24),
                            Text = "",
                            AutoButtonColor = false,
                            LayoutOrder = i,
                            ZIndex = 21,
                        }, DropScroll)
                        U.Padding(OptBtn, 0, 0, 0, 8)

                        U.Label(OptBtn, {
                            Text = tostring(opt),
                            TextSize = 10,
                            Font = isSelected and Enum.Font.GothamMedium or Enum.Font.Gotham,
                            TextColor3 = isSelected and Theme.Text or Theme.TextDim,
                            Size = UDim2.new(1, 0, 1, 0),
                        })

                        OptBtn.MouseButton1Click:Connect(function()
                            if multi then
                                local idx = table.find(selected, opt)
                                if idx then table.remove(selected, idx) else table.insert(selected, opt) end
                                CurLbl.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
                                VLH.Flags[flagId] = selected
                                task.spawn(callback, selected)
                                Refresh()
                            else
                                selected = opt
                                CurLbl.Text = opt
                                VLH.Flags[flagId] = opt
                                task.spawn(callback, opt)
                                open = false
                                DropList.Visible = false
                                ChevLbl.Text = "▾"
                                Refresh()
                            end
                        end)
                        OptBtn.MouseEnter:Connect(function()
                            if not (not multi and selected == opt) then
                                U.Tween(OptBtn, 0.1, { BackgroundColor3 = Theme.CardHover })
                            end
                        end)
                        OptBtn.MouseLeave:Connect(function()
                            if not (not multi and selected == opt) then
                                U.Tween(OptBtn, 0.1, { BackgroundColor3 = Theme.Panel })
                            end
                        end)
                    end
                    -- height
                    local h = math.min(#options * 24 + 8, 120)
                    DropList.Size = UDim2.new(1, 0, 0, h)
                end

                local ToggleBtn = U.Create("TextButton", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                    Size = UDim2.new(1, 0, 1, 0),
                    ZIndex = 10,
                }, Row)
                ToggleBtn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then Refresh() end
                    DropList.Visible = open
                    ChevLbl.Text = open and "▴" or "▾"
                end)

                Row.MouseEnter:Connect(function()
                    if not open then U.Tween(Row, 0.1, { BackgroundColor3 = Theme.CardHover }) end
                end)
                Row.MouseLeave:Connect(function()
                    if not open then U.Tween(Row, 0.15, { BackgroundColor3 = Theme.Card }) end
                end)

                VLH.Flags[flagId] = selected
                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)

                return {
                    Set = function(v)
                        selected = v
                        CurLbl.Text = multi and (type(v) == "table" and table.concat(v, ", ") or "Select...") or tostring(v)
                        VLH.Flags[flagId] = v
                    end,
                    Get = function() return selected end,
                    Refresh = function(newOpts)
                        if newOpts then options = newOpts end
                        Refresh()
                    end,
                }
            end

            -- ────── ADD INPUT (TEXTBOX) ───────
            function SectionObj:AddInput(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name        = tostring(opts[1] or opts.Name or "Input")
                local placeholder = tostring(opts[2] or opts.Placeholder or "Enter text...")
                local default     = tostring(opts[3] or opts.Default or "")
                local callback    = opts[4] or opts.Callback or function() end
                local flagId      = opts.Flag or name

                local Row = U.Create("Frame", {
                    Name = "Input_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 40),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 4, 10, 4, 10)

                U.ListLayout(Row, Enum.FillDirection.Vertical, nil, 3)

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, 0, 0, 14),
                    LayoutOrder = 1,
                })

                local InputHolder = U.Create("Frame", {
                    BackgroundColor3 = Theme.BG,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 18),
                    LayoutOrder = 2,
                }, Row)
                U.Corner(InputHolder, 4)
                U.Stroke(InputHolder, Theme.Border, 0, 1)
                U.Padding(InputHolder, 0, 0, 0, 6)

                local Box = U.Create("TextBox", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = Enum.Font.Gotham,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Theme.TextDim,
                    Text = default,
                    TextColor3 = Theme.Text,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Size = UDim2.new(1, 0, 1, 0),
                }, InputHolder)

                Box.Focused:Connect(function()
                    U.Tween(InputHolder, 0.15, { BackgroundColor3 = Theme.Panel })
                end)
                Box.FocusLost:Connect(function(enter)
                    U.Tween(InputHolder, 0.15, { BackgroundColor3 = Theme.BG })
                    VLH.Flags[flagId] = Box.Text
                    task.spawn(callback, Box.Text, enter)
                end)

                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
                return {
                    Set = function(v) Box.Text = tostring(v) end,
                    Get = function() return Box.Text end,
                }
            end

            -- ────── ADD KEYBIND ───────────────
            function SectionObj:AddKeybind(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name     = tostring(opts[1] or opts.Name or "Keybind")
                local default  = opts[2] or opts.Default or Enum.KeyCode.E
                local callback = opts[3] or opts.Callback or function() end
                local flagId   = opts.Flag or name

                local value = default
                local binding = false

                local Row = U.Create("Frame", {
                    Name = "Keybind_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 0, 10, 0, 10)

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(1, -70, 0, 18),
                })

                local KeyBtn = U.Create("TextButton", {
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    Text = tostring(value.Name),
                    TextColor3 = Theme.TextDim,
                    TextSize = 9,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 60, 0, 18),
                    AutoButtonColor = false,
                }, Row)
                U.Corner(KeyBtn, 4)
                U.Stroke(KeyBtn, Theme.Border, 0, 1)

                KeyBtn.MouseButton1Click:Connect(function()
                    binding = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Theme.Text
                end)

                UserInputService.InputBegan:Connect(function(input, gpe)
                    if binding and not gpe then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            value = input.KeyCode
                            VLH.Flags[flagId] = value
                            KeyBtn.Text = tostring(value.Name)
                            KeyBtn.TextColor3 = Theme.TextDim
                            binding = false
                        end
                    elseif not binding and input.KeyCode == value then
                        task.spawn(callback, value)
                    end
                end)

                Row.MouseEnter:Connect(function()
                    U.Tween(Row, 0.1, { BackgroundColor3 = Theme.CardHover })
                end)
                Row.MouseLeave:Connect(function()
                    U.Tween(Row, 0.15, { BackgroundColor3 = Theme.Card })
                end)

                VLH.Flags[flagId] = value
                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
                return {
                    Set = function(v)
                        value = v
                        KeyBtn.Text = tostring(v.Name)
                        VLH.Flags[flagId] = v
                    end,
                    Get = function() return value end,
                }
            end

            -- ────── ADD LABEL ─────────────────
            function SectionObj:AddLabel(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local text = tostring(opts[1] or opts.Text or opts.Name or "")
                local desc = tostring(opts[2] or opts.Description or opts.Content or "")

                local Row = U.Create("Frame", {
                    Name = "Label_" .. text,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Padding(Row, 2, 10, 2, 10)

                U.Label(Row, {
                    Text = text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    LayoutOrder = 1,
                })
                if desc ~= "" then
                    U.Label(Row, {
                        Text = desc,
                        TextSize = 10,
                        Font = Enum.Font.Gotham,
                        TextColor3 = Theme.TextDim,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        TextWrapped = true,
                        LayoutOrder = 2,
                    })
                end

                local el = { _frame = Row, _name = text }
                table.insert(self._elements, el)
                return {
                    Set = function(v)
                        local lbl = Row:FindFirstChild("TextLabel")
                        if lbl then lbl.Text = tostring(v) end
                    end,
                }
            end

            -- ────── ADD PARAGRAPH ─────────────
            function SectionObj:AddParagraph(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local title   = tostring(opts[1] or opts.Title or opts.Name or "")
                local content = tostring(opts[2] or opts.Content or opts.Description or "")

                local Row = U.Create("Frame", {
                    Name = "Para_" .. title,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 8, 10, 8, 10)
                U.ListLayout(Row, Enum.FillDirection.Vertical, nil, 4)

                if title ~= "" then
                    U.Label(Row, {
                        Text = title,
                        TextSize = 11,
                        Font = Enum.Font.GothamBold,
                        TextColor3 = Theme.Text,
                        Size = UDim2.new(1, 0, 0, 14),
                        LayoutOrder = 1,
                    })
                end
                U.Label(Row, {
                    Text = content,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    TextWrapped = true,
                    LayoutOrder = 2,
                })

                local el = { _frame = Row, _name = title }
                table.insert(self._elements, el)
            end

            -- ────── ADD SEPARATOR ─────────────
            function SectionObj:AddSeparator()
                local Line = U.Create("Frame", {
                    BackgroundColor3 = Theme.Border,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                local el = { _frame = Line, _name = "" }
                table.insert(self._elements, el)
            end

            -- ────── ADD SOCIAL ────────────────
            function SectionObj:AddSocial(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name = tostring(opts[1] or opts.Name or "Link")
                local url  = tostring(opts[2] or opts.Url or "")

                local Row = U.Create("TextButton", {
                    Name = "Social_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    AutoButtonColor = false,
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 0, 10, 0, 10)

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    Size = UDim2.new(0.7, 0, 0, 18),
                })
                U.Label(Row, {
                    Text = "Open ↗",
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0.3, 0, 0, 18),
                })

                Row.MouseEnter:Connect(function() U.Tween(Row, 0.1, { BackgroundColor3 = Theme.CardHover }) end)
                Row.MouseLeave:Connect(function() U.Tween(Row, 0.15, { BackgroundColor3 = Theme.Card }) end)
                Row.MouseButton1Click:Connect(function()
                    local ok = pcall(function()
                        game:GetService("GuiService"):OpenBrowserWindow(url)
                    end)
                    if not ok and setclipboard then
                        pcall(setclipboard, url)
                        Notify({ Title = "VLH", Content = "URL copied to clipboard." })
                    end
                end)

                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
            end

            -- ────── ADD COPY GROUP ────────────
            function SectionObj:AddCopyGroup(opts)
                opts = opts or {}
                local name = tostring(opts[1] or opts.Name or "Copy")
                local text = tostring(opts[2] or opts.Text or "")

                local Row = U.Create("Frame", {
                    Name = "Copy_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 30),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 0, 6, 0, 10)

                local layout = U.ListLayout(Row, Enum.FillDirection.Horizontal, nil, 6)
                layout.VerticalAlignment = Enum.VerticalAlignment.Center

                U.Label(Row, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, -50, 0, 18),
                    LayoutOrder = 1,
                })

                local CopyBtn = U.Create("TextButton", {
                    BackgroundColor3 = Theme.Panel,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    Text = "Copy",
                    TextColor3 = Theme.TextDim,
                    TextSize = 10,
                    Size = UDim2.new(0, 44, 0, 20),
                    AutoButtonColor = false,
                    LayoutOrder = 2,
                }, Row)
                U.Corner(CopyBtn, 4)
                U.Stroke(CopyBtn, Theme.Border, 0, 1)

                CopyBtn.MouseButton1Click:Connect(function()
                    if setclipboard then
                        pcall(setclipboard, text)
                        CopyBtn.Text = "✓"
                        task.delay(1.5, function() CopyBtn.Text = "Copy" end)
                    end
                end)

                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
            end

            -- ────── ADD PROGRESS ──────────────
            function SectionObj:AddProgress(opts)
                opts = opts or {}
                if type(opts) == "string" then opts = { opts } end
                local name    = tostring(opts[1] or opts.Name or "Progress")
                local default = tonumber(opts[2] or opts.Default or 0)
                local flagId  = opts.Flag or name

                local value = math.clamp(default, 0, 100)

                local Row = U.Create("Frame", {
                    Name = "Progress_" .. name,
                    BackgroundColor3 = Theme.Card,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 36),
                    LayoutOrder = #SecFrame:GetChildren() + 1,
                }, SecFrame)
                U.Corner(Row, 7)
                U.Stroke(Row, Theme.Border, 0.3, 1)
                U.Padding(Row, 6, 10, 6, 10)
                U.ListLayout(Row, Enum.FillDirection.Vertical, nil, 4)

                local TopRow = U.Create("Frame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 14),
                    LayoutOrder = 1,
                }, Row)

                U.Label(TopRow, {
                    Text = name,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    TextColor3 = Theme.Text,
                    Size = UDim2.new(1, -40, 1, 0),
                })
                local PctLbl = U.Label(TopRow, {
                    Text = value .. "%",
                    TextSize = 10,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 40, 1, 0),
                })

                local Track = U.Create("Frame", {
                    BackgroundColor3 = Theme.Slider,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 4),
                    LayoutOrder = 2,
                }, Row)
                U.Corner(Track, 999)
                local Fill = U.Create("Frame", {
                    BackgroundColor3 = Theme.SliderFill,
                    BorderSizePixel = 0,
                    Size = UDim2.new(value / 100, 0, 1, 0),
                }, Track)
                U.Corner(Fill, 999)

                local el = { _frame = Row, _name = name }
                table.insert(self._elements, el)
                return {
                    Set = function(v)
                        value = math.clamp(v, 0, 100)
                        U.Tween(Fill, 0.3, { Size = UDim2.new(value / 100, 0, 1, 0) })
                        PctLbl.Text = value .. "%"
                        VLH.Flags[flagId] = value
                    end,
                    Get = function() return value end,
                }
            end

            return SectionObj
        end -- AddSection

        -- Shortcut: AddSection for direct access
        function TabObj:AddButton(opts)
            return self:AddSection({}):AddButton(opts)
        end
        function TabObj:AddToggle(opts)
            return self:AddSection({}):AddToggle(opts)
        end
        function TabObj:AddSlider(opts)
            return self:AddSection({}):AddSlider(opts)
        end
        function TabObj:AddDropdown(opts)
            return self:AddSection({}):AddDropdown(opts)
        end
        function TabObj:AddInput(opts)
            return self:AddSection({}):AddInput(opts)
        end
        function TabObj:AddKeybind(opts)
            return self:AddSection({}):AddKeybind(opts)
        end
        function TabObj:AddLabel(opts)
            return self:AddSection({}):AddLabel(opts)
        end
        function TabObj:AddParagraph(opts)
            return self:AddSection({}):AddParagraph(opts)
        end
        function TabObj:AddSeparator()
            return self:AddSection({}):AddSeparator()
        end
        function TabObj:AddSocial(opts)
            return self:AddSection({}):AddSocial(opts)
        end

        return TabObj
    end -- AddTab

    -- ── WINDOW HELPERS ───────────────────────
    function WindowObj:SetTitle(t)
        TopTitle.Text = tostring(t)
    end
    function WindowObj:SetDescription(t)
        TopSub.Text = tostring(t)
    end
    function WindowObj:Toggle()
        SetVisible(not WinVisible)
    end
    function WindowObj:Destroy()
        ScreenGui:Destroy()
    end
    function WindowObj:Notify(opts)
        Notify(opts)
    end

    return WindowObj
end -- CreateWindow

-- ─────────────────────────────────────────────
-- COMMUNITY DISCORD CARD HELPER
-- Matches the Stealth-X Community tab exactly
-- ─────────────────────────────────────────────
function VLH.MakeCommunityTab(window, opts)
    opts = opts or {}
    local hubName = tostring(opts.Name or "Veloria Hub")
    local tagline = tostring(opts.Tagline or "Join for updates, support and giveaways.")
    local inviteURL = tostring(opts.InviteURL or "https://discord.gg/GrWpVXbWfj")
    local iconId = tostring(opts.Icon or "rbxassetid://131946786209484")

    local Tab = window:AddTab({ "Community", "community" })

    local Sec = Tab:AddSection({ "Community" })

    -- Discord card (matches screenshot)
    local CardFrame = U.Create("Frame", {
        Name = "DiscordCard",
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 56),
        LayoutOrder = #Sec._frame:GetChildren() + 1,
    }, Sec._frame)
    U.Corner(CardFrame, 8)
    U.Stroke(CardFrame, Theme.Border, 0.3, 1)
    U.Padding(CardFrame, 8, 10, 8, 10)

    local CLayout = U.ListLayout(CardFrame, Enum.FillDirection.Horizontal, nil, 10)
    CLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    -- Icon box
    local IconBox = U.Create("Frame", {
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 36, 0, 36),
        LayoutOrder = 1,
    }, CardFrame)
    U.Corner(IconBox, 8)
    U.Stroke(IconBox, Theme.Border, 0, 1)
    U.Create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0.7, 0, 0.7, 0),
        Image = iconId,
        ImageColor3 = Theme.Text,
    }, IconBox)

    -- Text column
    local TextCol = U.Create("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -46, 1, 0),
        LayoutOrder = 2,
    }, CardFrame)
    U.ListLayout(TextCol, Enum.FillDirection.Vertical, nil, 2)
    TextCol.AutomaticSize = Enum.AutomaticSize.Y

    U.Label(TextCol, {
        Text = hubName,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextColor3 = Theme.Text,
        Size = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 1,
    })
    U.Label(TextCol, {
        Text = tagline,
        TextSize = 9,
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.TextDim,
        Size = UDim2.new(1, 0, 0, 12),
        LayoutOrder = 2,
    })

    -- Copy Invite button
    Sec:AddButton({
        "Copy Invite",
        "",
        function()
            if setclipboard then
                pcall(setclipboard, inviteURL)
                VLH.Notify({ Title = "VLH", Content = "Discord invite copied to clipboard." })
            else
                local ok = pcall(function()
                    game:GetService("GuiService"):OpenBrowserWindow(inviteURL)
                end)
                if not ok then
                    VLH.Notify({ Title = "VLH", Content = "Could not open Discord." })
                end
            end
        end,
    })

    -- Unload button
    Sec:AddButton({
        "Unload Script",
        "",
        function()
            VLH.Notify({ Title = "VLH", Content = "Unloading..." })
            task.delay(0.3, function()
                if VLH._screen then VLH._screen:Destroy() end
                if NotifyGui then NotifyGui:Destroy() end
            end)
        end,
    })

    return Tab
end

-- ─────────────────────────────────────────────
-- RETURN
-- ─────────────────────────────────────────────
return VLH
