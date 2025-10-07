-- OrionLite.lua
-- Uma library GUI inspirada na OrionLib, feita para ser fácil de usar e extensível.
-- Use com loadstring ou require (retorna a tabela `OrionLite`).
-- Observações:
--  * Suporta mudar fundo por cor (Color3) ou por imagem (rbxassetid://xxxxx)
--  * Tem a lista de players com tooltip ao passar o mouse (mostra nome, data aproximada de criação e número de execuções locais)
--  * Ativa/Desativa o mouse quando o menu está aberto
--  * Tecla de atalho padrão: "M" — pode ser alterada com opc `activemenutc` nas opções
--  * Tenta persistir o contador de execuções usando writefile/readfile quando disponível (executores), senão usa atributos do jogador
--  * Fácil de estender: exposição de eventos e funções públicas

local OrionLite = {}
OrionLite.__index = OrionLite

-- Versão
OrionLite.Version = "0.9.0"

-- Defaults
local DEFAULTS = {
    activemenutc = "M",
    start_open = false,
    background = Color3.fromRGB(10, 10, 10), -- ou string com rbxassetid://
    title = "OrionLite",
    size = UDim2.new(0, 520, 0, 360),
}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Helpers
local function isColor3(v)
    return typeof(v) == "Color3"
end

local function isAssetString(v)
    return type(v) == "string" and v:match("rbxassetid://%d+")
end

local function tryReadFile(path)
    if (syn and syn.io and syn.io.read) then -- Synapse legacy
        local ok, res = pcall(function() return syn.io.read(path) end)
        if ok then return res end
    end
    if (isfolder and readfile) then
        local ok, res = pcall(function() return readfile(path) end)
        if ok then return res end
    end
    return nil
end

local function tryWriteFile(path, data)
    if (syn and syn.io and syn.io.write) then
        pcall(function() syn.io.write(path, data) end)
        return true
    end
    if (isfolder and writefile) then
        pcall(function() writefile(path, data) end)
        return true
    end
    return false
end

local function daysToDate(days)
    -- Retorna uma string aproximada da data de criação com base em AccountAge (dias)
    local now = os.time()
    local created = now - math.floor(days) * 24 * 60 * 60
    return os.date("%Y-%m-%d", created)
end

-- Cria a tooltip (simples)
local function createTooltip(parent)
    local tip = Instance.new("Frame")
    tip.Name = "_Tooltip"
    tip.Size = UDim2.new(0, 220, 0, 86)
    tip.BackgroundTransparency = 0.12
    tip.BackgroundColor3 = Color3.fromRGB(20,20,20)
    tip.BorderSizePixel = 0
    tip.Visible = false
    tip.AnchorPoint = Vector2.new(0,1)
    tip.ZIndex = 1000

    local uiCorner = Instance.new("UICorner", tip)
    uiCorner.CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", tip)
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 0, 24)
    title.Position = UDim2.new(0,6,0,6)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = "Player"

    local body = Instance.new("TextLabel", tip)
    body.Name = "Body"
    body.Size = UDim2.new(1, -12, 0, 48)
    body.Position = UDim2.new(0,6,0,30)
    body.BackgroundTransparency = 1
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Font = Enum.Font.Gotham
    body.TextSize = 12
    body.TextColor3 = Color3.fromRGB(200,200,200)
    body.TextWrapped = true
    body.Text = ""

    tip.Parent = parent
    return tip
end

-- Cria UI principal
function OrionLite.new(opts)
    opts = opts or {}
    for k,v in pairs(DEFAULTS) do if opts[k] == nil then opts[k] = v end end

    local self = setmetatable({}, OrionLite)
    self.Options = opts
    self.Open = false
    self.RunsPath = ("OrionLite_runs_%s.json"):format(tostring(LocalPlayer.UserId))
    self.RunCount = 0

    -- Load run count (try file then attribute fallback)
    local ok, raw = pcall(function() return tryReadFile(self.RunsPath) end)
    if ok and raw then
        local success, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if success and type(data) == "table" and data.count then
            self.RunCount = tonumber(data.count) or 0
        end
    else
        local attr = LocalPlayer:GetAttribute("OrionLiteRuns")
        if attr then self.RunCount = tonumber(attr) or 0 end
    end
    self.RunCount = self.RunCount + 1
    -- save back
    pcall(function()
        tryWriteFile(self.RunsPath, HttpService:JSONEncode({count = self.RunCount}))
    end)
    pcall(function() LocalPlayer:SetAttribute("OrionLiteRuns", self.RunCount) end)

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OrionLiteGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 50
    screenGui.Parent = game:GetService("CoreGui") or game:GetService("PlayersLocalPlayer")
    self.ScreenGui = screenGui

    -- Main window
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = opts.size
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    main.Visible = opts.start_open
    main.ZIndex = 50
    main.Parent = screenGui
    self.Main = main

    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0,10)

    -- Background: color or image
    if isColor3(opts.background) then
        main.BackgroundColor3 = opts.background
    elseif isAssetString(opts.background) then
        main.BackgroundColor3 = Color3.fromRGB(8,8,8)
        local img = Instance.new("ImageLabel", main)
        img.Size = UDim2.new(1,0,1,0)
        img.Position = UDim2.new(0,0,0,0)
        img.Image = opts.background
        img.ScaleType = Enum.ScaleType.Crop
        img.BackgroundTransparency = 1
        img.ZIndex = 1
    else
        main.BackgroundColor3 = Color3.fromRGB(8,8,8)
    end

    -- Title
    local title = Instance.new("TextLabel", main)
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 0, 28)
    title.Position = UDim2.new(0,6,0,6)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextColor3 = Color3.new(1,1,1)
    title.Text = opts.title .. " - v"..OrionLite.Version

    -- Close button
    local close = Instance.new("TextButton", main)
    close.Name = "Close"
    close.Size = UDim2.new(0,28,0,20)
    close.Position = UDim2.new(1, -36, 0, 8)
    close.Text = "X"
    close.Font = Enum.Font.SourceSansBold
    close.TextSize = 18
    close.BackgroundTransparency = 0.6
    close.BorderSizePixel = 0
    close.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Left: player list
    local left = Instance.new("Frame", main)
    left.Name = "Left"
    left.Size = UDim2.new(0, 180, 1, -46)
    left.Position = UDim2.new(0,8,0,40)
    left.BackgroundTransparency = 0.12
    left.BorderSizePixel = 0
    local leftCorner = Instance.new("UICorner", left)
    leftCorner.CornerRadius = UDim.new(0,8)

    local playersLabel = Instance.new("TextLabel", left)
    playersLabel.Size = UDim2.new(1, -12, 0, 20)
    playersLabel.Position = UDim2.new(0,6,0,6)
    playersLabel.BackgroundTransparency = 1
    playersLabel.Font = Enum.Font.GothamBold
    playersLabel.TextSize = 13
    playersLabel.TextColor3 = Color3.new(1,1,1)
    playersLabel.Text = "Players"

    local scroll = Instance.new("ScrollingFrame", left)
    scroll.Name = "PlayerScroll"
    scroll.Size = UDim2.new(1, -12, 1, -38)
    scroll.Position = UDim2.new(0,6,0,30)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 6
    scroll.BackgroundTransparency = 1

    local uiList = Instance.new("UIListLayout", scroll)
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Padding = UDim.new(0,6)

    -- Tooltip
    local tooltip = createTooltip(main)
    self.Tooltip = tooltip

    -- Right: content placeholder
    local right = Instance.new("Frame", main)
    right.Name = "Right"
    right.Size = UDim2.new(1, -204, 1, -46)
    right.Position = UDim2.new(0,196,0,40)
    right.BackgroundTransparency = 1

    -- Simple content label
    local contentLabel = Instance.new("TextLabel", right)
    contentLabel.Size = UDim2.new(1, -12, 1, -12)
    contentLabel.Position = UDim2.new(0,6,0,6)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 14
    contentLabel.TextColor3 = Color3.fromRGB(220,220,220)
    contentLabel.TextWrapped = true
    contentLabel.Text = "Use OrionLite:AddContent(func) para popular esta área."

    -- Public references
    self.Left = left
    self.Right = right
    self.Scroll = scroll
    self.ContentLabel = contentLabel

    -- Functions para popular player list
    local function makePlayerEntry(player)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 30)
        btn.BackgroundTransparency = 0.9
        btn.Text = player.Name
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 13
        btn.TextColor3 = Color3.new(1,1,1)
        btn.AutoButtonColor = false
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = #self.Scroll:GetChildren()

        btn.MouseEnter:Connect(function(x,y)
            local ageDays = player.AccountAge or 0
            local dateStr = daysToDate(ageDays)
            local runs = nil
            -- try to read saved runs for that player if same user
            if player == LocalPlayer then runs = self.RunCount else runs = player:GetAttribute("OrionLiteRuns") or "-" end
            tooltip.Title.Text = player.Name
            tooltip.Body.Text = ("Criado aprox.: %s\nExecuções (local): %s"):format(dateStr, tostring(runs))
            tooltip.Position = UDim2.new(0, x + 12, 0, y - 8)
            tooltip.Visible = true
        end)
        btn.MouseMoved:Connect(function(x,y)
            tooltip.Position = UDim2.new(0, x + 12, 0, y - 8)
        end)
        btn.MouseLeave:Connect(function()
            tooltip.Visible = false
        end)
        return btn
    end

    local function refreshPlayers()
        -- Clear
        for _,c in pairs(scroll:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        -- Populate
        for _,pl in pairs(Players:GetPlayers()) do
            local entry = makePlayerEntry(pl)
            entry.Parent = scroll
        end
        -- Update canvas size
        RunService.Heartbeat:Wait()
        scroll.CanvasSize = UDim2.new(0,0,0, uiList.AbsoluteContentSize.Y + 8)
    end

    refreshPlayers()
    Players.PlayerAdded:Connect(function() refreshPlayers() end)
    Players.PlayerRemoving:Connect(function() refreshPlayers() end)

    -- Input for toggle
    local activKey = string.upper(tostring(opts.activemenutc or "M"))
    local function onInput(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local key = input.KeyCode and input.KeyCode.Name or nil
            if key == activKey then
                self:Toggle()
            end
        end
    end
    UserInputService.InputBegan:Connect(onInput)

    -- Mouse icon handling
    self._mouseWasHidden = not UserInputService.MouseIconEnabled

    -- Public API functions
    function self:Toggle()
        self.Open = not self.Open
        self.Main.Visible = self.Open
        UserInputService.MouseIconEnabled = self.Open or (not self._mouseWasHidden == false)
    end

    function self:SetBackground(value)
        if isColor3(value) then
            self.Main.BackgroundColor3 = value
            for _,v in pairs(self.Main:GetChildren()) do if v:IsA("ImageLabel") then v:Destroy() end end
        elseif isAssetString(value) then
            for _,v in pairs(self.Main:GetChildren()) do if v:IsA("ImageLabel") then v:Destroy() end end
            local img = Instance.new("ImageLabel", self.Main)
            img.Size = UDim2.new(1,0,1,0)
            img.Position = UDim2.new(0,0,0,0)
            img.Image = value
            img.ScaleType = Enum.ScaleType.Crop
            img.BackgroundTransparency = 1
        end
    end

    function self:AddContent(func)
        if type(func) ~= "function" then return end
        local ok, res = pcall(function() return func(self.Right) end)
        if not ok then warn("OrionLite:AddContent error:", res) end
    end

    function self:Destroy()
        if self.ScreenGui then self.ScreenGui:Destroy() end
    end

    -- Expose some convenient fields
    self._refreshPlayers = refreshPlayers

    -- Expose to user
    self._internal = {
        tooltip = tooltip,
        titleLabel = title,
        closeButton = close,
    }

    -- Inicializa aberto se pedido
    if opts.start_open then
        self.Open = true
        self.Main.Visible = true
        UserInputService.MouseIconEnabled = true
    end

    return self
end

-- Short helper to create and return immediately (facil para loadstring)
function OrionLite.Create(opts)
    return OrionLite.new(opts)
end

return OrionLite
