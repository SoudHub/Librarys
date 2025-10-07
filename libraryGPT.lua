-- OrionMini.lua
-- Simple and easy-to-use GUI Library inspired by OrionLib
-- Lightweight, single-window, and beginner-friendly.
-- Features:
--  • Easy setup with loadstring
--  • Supports background color or image
--  • Keybind to toggle (default: M)
--  • Mouse visible when open
--  • AddButton, AddLabel, AddTextbox, SetBackground

local OrionMini = {}
OrionMini.__index = OrionMini

-- // Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- // Defaults
local DEFAULTS = {
    activemenutc = "M",
    title = "OrionMini",
    background = Color3.fromRGB(20, 20, 20)
}

-- // Helper
local function isColor3(v)
    return typeof(v) == "Color3"
end

local function isAssetString(v)
    return type(v) == "string" and v:match("rbxassetid://%d+")
end

-- // Create Library
function OrionMini.Create(opts)
    opts = opts or {}
    for k, v in pairs(DEFAULTS) do
        if opts[k] == nil then opts[k] = v end
    end

    local self = setmetatable({}, OrionMini)
    self.Options = opts
    self.Open = false

    -- // ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "OrionMiniGui"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")

    -- // Main Window
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.Visible = false
    frame.Parent = gui

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    if isColor3(opts.background) then
        frame.BackgroundColor3 = opts.background
    elseif isAssetString(opts.background) then
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        local img = Instance.new("ImageLabel", frame)
        img.Size = UDim2.new(1, 0, 1, 0)
        img.Position = UDim2.new(0, 0, 0, 0)
        img.Image = opts.background
        img.ScaleType = Enum.ScaleType.Crop
        img.BackgroundTransparency = 1
    end

    -- // Title
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = opts.title
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.TextColor3 = Color3.new(1, 1, 1)

    -- // Content area
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -20, 1, -50)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- // Save references
    self.Gui = gui
    self.Frame = frame
    self.Scroll = scroll
    self.Layout = layout

    -- // Toggle function
    function self:Toggle()
        self.Open = not self.Open
        frame.Visible = self.Open
        UserInputService.MouseIconEnabled = self.Open
    end

    -- // Background changer
    function self:SetBackground(value)
        for _, v in pairs(frame:GetChildren()) do
            if v:IsA("ImageLabel") then v:Destroy() end
        end
        if isColor3(value) then
            frame.BackgroundColor3 = value
        elseif isAssetString(value) then
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
            local img = Instance.new("ImageLabel", frame)
            img.Size = UDim2.new(1, 0, 1, 0)
            img.Position = UDim2.new(0, 0, 0, 0)
            img.Image = value
            img.ScaleType = Enum.ScaleType.Crop
            img.BackgroundTransparency = 1
        end
    end

    -- // AddLabel
    function self:AddLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -10, 0, 30)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Parent = scroll
        return lbl
    end

    -- // AddButton
    function self:AddButton(text, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Parent = scroll

        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            if callback then
                pcall(callback)
            end
        end)
        return btn
    end

    -- // AddTextbox
    function self:AddTextbox(placeholder, callback)
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -10, 0, 35)
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        box.PlaceholderText = placeholder or "Type here..."
        box.Text = ""
        box.Font = Enum.Font.Gotham
        box.TextSize = 14
        box.TextColor3 = Color3.new(1, 1, 1)
        box.Parent = scroll

        local corner = Instance.new("UICorner", box)
        corner.CornerRadius = UDim.new(0, 6)

        box.FocusLost:Connect(function(enter)
            if enter and callback then
                pcall(callback, box.Text)
            end
        end)
        return box
    end

    -- // Update Canvas Size
    local function updateCanvas()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    -- // Keybind for toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == opts.activemenutc then
            self:Toggle()
        end
    end)

    return self
end

return OrionMini
