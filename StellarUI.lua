-- StellarUI Library
-- Por: [Pato_Soud]
-- Versão: 0.1

local StellarUI = {}
StellarUI.__index = StellarUI

-- Configurações padrão
StellarUI.Settings = {
    ActiveMenuKey = "M",
    ShowMouse = true,
    DefaultBackground = Color3.fromRGB(0, 0, 0),
    Theme = "Black"
}

-- Cache de instâncias
StellarUI.Instances = {}
StellarUI.Windows = {}
StellarUI.PlayerStats = {
    Executions = 0
}

-- Serviços
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Player local
local LocalPlayer = Players.LocalPlayer

-- Função para criar elementos UI
function StellarUI:CreateElement(className, properties)
    local element = Instance.new(className)
    for property, value in pairs(properties) do
        element[property] = value
    end
    return element
end

-- Tema de cores
StellarUI.Themes = {
    Black = {
        Background = Color3.fromRGB(0, 0, 0),
        Secondary = Color3.fromRGB(15, 15, 15),
        Accent = Color3.fromRGB(0, 255, 0),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        Border = Color3.fromRGB(40, 40, 40)
    },
    Dark = {
        Background = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(35, 35, 45),
        Accent = Color3.fromRGB(0, 170, 255),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200),
        Border = Color3.fromRGB(60, 60, 80)
    }
}

-- Função para criar cantos arredondados
function StellarUI:ApplyCornerRadius(element, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = element
    return corner
end

-- Função para criar gradiente
function StellarUI:ApplyGradient(element, colors)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = 90
    gradient.Parent = element
    return gradient
end

-- Sistema de arrastar suave
function StellarUI:MakeDraggable(frame)
    local dragToggle = nil
    local dragSpeed = 0.25
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
        
        -- Aplicar suavização no movimento
        local tweenInfo = TweenInfo.new(dragSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, {Position = position})
        tween:Play()
    end
    
    frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragToggle then
                updateInput(input)
            end
        end
    end)
end

-- Animação suave para mostrar estatísticas
function StellarUI:AnimateStatsShow()
    local stats = self.PlayerStatsFrame
    stats.Visible = true
    
    -- Reset da transparência
    for _, child in ipairs(stats:GetChildren()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
        end
    end
    
    stats.BackgroundTransparency = 1
    
    -- Animação de fade in
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local backgroundTween = TweenService:Create(stats, tweenInfo, {BackgroundTransparency = 0.1})
    backgroundTween:Play()
    
    -- Animação sequencial dos labels
    for i, child in ipairs(stats:GetChildren()) do
        if child:IsA("TextLabel") then
            wait(0.05) -- Delay entre cada linha
            local labelTween = TweenService:Create(child, tweenInfo, {TextTransparency = 0})
            labelTween:Play()
        end
    end
end

-- Animação suave para esconder estatísticas
function StellarUI:AnimateStatsHide()
    local stats = self.PlayerStatsFrame
    
    local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    -- Animação de fade out para todos os elementos
    local backgroundTween = TweenService:Create(stats, tweenInfo, {BackgroundTransparency = 1})
    
    for _, child in ipairs(stats:GetChildren()) do
        if child:IsA("TextLabel") then
            local labelTween = TweenService:Create(child, tweenInfo, {TextTransparency = 1})
            labelTween:Play()
        end
    end
    
    backgroundTween:Play()
    
    -- Esperar a animação terminar antes de esconder
    wait(0.2)
    stats.Visible = false
end

-- Inicializar a library
function StellarUI:Init()
    if self.Initialized then return end
    
    -- Criar interface principal
    self.ScreenGui = self:CreateElement("ScreenGui", {
        Name = "StellarUIMain",
        DisplayOrder = 10,
        ResetOnSpawn = false
    })
    
    -- Container principal
    self.MainFrame = self:CreateElement("Frame", {
        Name = "MainFrame",
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Background,
        BorderSizePixel = 0,
        Visible = false
    })
    
    -- Aplicar bordas arredondadas
    self:ApplyCornerRadius(self.MainFrame, 12)
    
    -- Background personalizável
    self.Background = self:CreateElement("Frame", {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = self.Settings.DefaultBackground,
        BorderSizePixel = 0,
        ZIndex = 0
    })
    
    self:ApplyCornerRadius(self.Background, 12)
    
    self.BackgroundImage = self:CreateElement("ImageLabel", {
        Name = "BackgroundImage",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Visible = false
    })
    
    self:ApplyCornerRadius(self.BackgroundImage, 12)
    
    -- Header (área de arrasto)
    self.Header = self:CreateElement("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
        BorderSizePixel = 0
    })
    
    self:ApplyCornerRadius(self.Header, 12)
    
    self.Title = self:CreateElement("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Text = "Stellar UI",
        TextColor3 = self.Themes[self.Settings.Theme].Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    self.CloseButton = self:CreateElement("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = Color3.fromRGB(255, 60, 60),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "X",
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })
    
    self:ApplyCornerRadius(self.CloseButton, 15)
    
    -- Player Info Section
    self.PlayerSection = self:CreateElement("Frame", {
        Name = "PlayerSection",
        Size = UDim2.new(0, 150, 0, 320),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
        BorderSizePixel = 0
    })
    
    self:ApplyCornerRadius(self.PlayerSection, 8)
    
    self.PlayerIcon = self:CreateElement("ImageLabel", {
        Name = "PlayerIcon",
        Size = UDim2.new(0, 80, 0, 80),
        Position = UDim2.new(0.5, -40, 0, 10),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Background,
        BorderSizePixel = 0,
        Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=150&height=150&format=png"
    })
    
    self:ApplyCornerRadius(self.PlayerIcon, 40)
    
    self.PlayerName = self:CreateElement("TextLabel", {
        Name = "PlayerName",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 100),
        BackgroundTransparency = 1,
        Text = LocalPlayer.Name,
        TextColor3 = self.Themes[self.Settings.Theme].Text,
        TextSize = 14,
        Font = Enum.Font.Gotham
    })
    
    self.PlayerStatsFrame = self:CreateElement("Frame", {
        Name = "PlayerStatsFrame",
        Size = UDim2.new(1, -10, 0, 150),
        Position = UDim2.new(0, 5, 0, 130),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Background,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Visible = false
    })
    
    self:ApplyCornerRadius(self.PlayerStatsFrame, 8)
    
    -- Content Area
    self.ContentFrame = self:CreateElement("Frame", {
        Name = "ContentFrame",
        Size = UDim2.new(0, 320, 0, 320),
        Position = UDim2.new(0, 170, 0, 50),
        BackgroundTransparency = 1
    })
    
    -- Tab System
    self.Tabs = self:CreateElement("Frame", {
        Name = "Tabs",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1
    })
    
    self.TabContainer = self:CreateElement("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    -- Montar a interface
    self.BackgroundImage.Parent = self.Background
    self.Background.Parent = self.MainFrame
    
    self.Title.Parent = self.Header
    self.CloseButton.Parent = self.Header
    self.Header.Parent = self.MainFrame
    
    self.PlayerIcon.Parent = self.PlayerSection
    self.PlayerName.Parent = self.PlayerSection
    self.PlayerStatsFrame.Parent = self.PlayerSection
    self.PlayerSection.Parent = self.MainFrame
    
    self.TabContainer.Parent = self.Tabs
    self.Tabs.Parent = self.ContentFrame
    self.ContentFrame.Parent = self.MainFrame
    
    self.MainFrame.Parent = self.ScreenGui
    self.ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Tornar arrastável
    self:MakeDraggable(self.MainFrame)
    
    -- Conectar eventos
    self.CloseButton.MouseButton1Click:Connect(function()
        self:ToggleUI()
    end)
    
    -- Eventos do mouse sobre o player
    self.PlayerSection.MouseEnter:Connect(function()
        self:ShowPlayerStats()
    end)
    
    self.PlayerSection.MouseLeave:Connect(function()
        self:HidePlayerStats()
    end)
    
    -- Input bind
    self.InputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode[self.Settings.ActiveMenuKey] then
            self:ToggleUI()
        end
    end)
    
    -- Incrementar contador de execuções
    self.PlayerStats.Executions += 1
    
    self.Initialized = true
    print("StellarUI inicializada com sucesso! Pressione " .. self.Settings.ActiveMenuKey .. " para abrir/fechar.")
end

-- Mostrar estatísticas do player com animação
function StellarUI:ShowPlayerStats()
    local stats = self.PlayerStatsFrame
    
    -- Limpar stats anteriores
    for _, child in ipairs(stats:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    -- Criar stats
    local accountAge = math.floor((os.time() - LocalPlayer.AccountAge * 86400) / 86400)
    
    local statLabels = {
        {Text = "Estatísticas:", Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 5, 0, 5), Font = Enum.Font.GothamBold},
        {Text = "Nome: " .. LocalPlayer.Name, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 5, 0, 30)},
        {Text = "ID: " .. LocalPlayer.UserId, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 5, 0, 50)},
        {Text = "Idade da Conta: " .. accountAge .. " dias", Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 5, 0, 70)},
        {Text = "Execuções: " .. self.PlayerStats.Executions, Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 5, 0, 90)},
        {Text = "Premium: " .. (LocalPlayer.MembershipType == Enum.MembershipType.Premium and "Sim" or "Não"), Size = UDim2.new(1, 0, 0, 15), Position = UDim2.new(0, 5, 0, 110)}
    }
    
    for i, stat in ipairs(statLabels) do
        local label = self:CreateElement("TextLabel", {
            Size = stat.Size,
            Position = stat.Position,
            BackgroundTransparency = 1,
            Text = stat.Text,
            TextColor3 = self.Themes[self.Settings.Theme].Text,
            TextTransparency = 1, -- Começa transparente
            TextSize = 12,
            Font = stat.Font or Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left
        })
        label.Parent = stats
    end
    
    -- Mostrar com animação
    self:AnimateStatsShow()
end

-- Esconder estatísticas do player com animação
function StellarUI:HidePlayerStats()
    self:AnimateStatsHide()
end

-- Alternar UI
function StellarUI:ToggleUI()
    self.MainFrame.Visible = not self.MainFrame.Visible
    
    if self.Settings.ShowMouse then
        if self.MainFrame.Visible then
            UserInputService.MouseIconEnabled = true
        else
            UserInputService.MouseIconEnabled = false
        end
    end
end

-- Mudar background
function StellarUI:SetBackground(type, value)
    if type == "color" then
        self.Background.BackgroundColor3 = value
        self.BackgroundImage.Visible = false
    elseif type == "image" then
        self.BackgroundImage.Image = value
        self.BackgroundImage.Visible = true
    elseif type == "rbxassetid" then
        self.BackgroundImage.Image = "rbxassetid://" .. value
        self.BackgroundImage.Visible = true
    end
end

-- Mudar tecla de ativação
function StellarUI:SetActivationKey(key)
    self.Settings.ActiveMenuKey = key
    print("Tecla de ativação alterada para: " .. key)
end

-- Criar uma nova aba
function StellarUI:CreateTab(name)
    local tabId = #self.Windows + 1
    local tab = {
        Id = tabId,
        Name = name,
        Elements = {}
    }
    
    -- Botão da aba
    local tabButton = self:CreateElement("TextButton", {
        Name = "Tab" .. tabId,
        Size = UDim2.new(0, 80, 1, 0),
        Position = UDim2.new(0, (tabId - 1) * 85, 0, 0),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Secondary,
        TextColor3 = self.Themes[self.Settings.Theme].Text,
        Text = name,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    self:ApplyCornerRadius(tabButton, 6)
    
    -- Conteúdo da aba
    local tabContent = self:CreateElement("ScrollingFrame", {
        Name = "TabContent" .. tabId,
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        Visible = tabId == 1,
        CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    
    local uiListLayout = self:CreateElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8)
    })
    
    local padding = self:CreateElement("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5)
    })
    
    uiListLayout.Parent = tabContent
    padding.Parent = tabContent
    tabContent.Parent = self.ContentFrame
    
    -- Evento do botão da aba
    tabButton.MouseButton1Click:Connect(function()
        for i, window in ipairs(self.Windows) do
            local content = self.ContentFrame:FindFirstChild("TabContent" .. window.Id)
            if content then
                content.Visible = i == tabId
            end
        end
    end)
    
    tabButton.Parent = self.TabContainer
    self.TabContainer.CanvasSize = UDim2.new(0, tabId * 85, 0, 0)
    
    table.insert(self.Windows, tab)
    return tab
end

-- Criar botão
function StellarUI:CreateButton(tab, text, callback)
    local button = self:CreateElement("TextButton", {
        Name = "Button_" .. text,
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = self.Themes[self.Settings.Theme].Accent,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        AutoButtonColor = false
    })
    
    self:ApplyCornerRadius(button, 8)
    
    -- Efeitos hover
    button.MouseEnter:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 255, 50)})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = self.Themes[self.Settings.Theme].Accent})
        tween:Play()
    end)
    
    button.MouseButton1Click:Connect(callback)
    button.Parent = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    table.insert(tab.Elements, button)
    
    -- Atualizar tamanho do canvas
    local content = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    if content then
        content.CanvasSize = UDim2.new(0, 0, 0, #tab.Elements * 43)
    end
    
    return button
end

-- Criar label
function StellarUI:CreateLabel(tab, text)
    local label = self:CreateElement("TextLabel", {
        Name = "Label_" .. text,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        TextColor3 = self.Themes[self.Settings.Theme].Text,
        Text = text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    label.Parent = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    table.insert(tab.Elements, label)
    
    local content = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    if content then
        content.CanvasSize = UDim2.new(0, 0, 0, #tab.Elements * 33)
    end
    
    return label
end

-- Criar toggle
function StellarUI:CreateToggle(tab, text, default, callback)
    local toggleState = default or false
    
    local toggleFrame = self:CreateElement("Frame", {
        Name = "Toggle_" .. text,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1
    })
    
    local label = self:CreateElement("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = self.Themes[self.Settings.Theme].Text,
        Text = text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local toggleButton = self:CreateElement("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(0, 50, 0, 25),
        Position = UDim2.new(1, -50, 0, 2),
        BackgroundColor3 = toggleState and self.Themes[self.Settings.Theme].Accent or self.Themes[self.Settings.Theme].Secondary,
        Text = "",
        TextSize = 0,
        AutoButtonColor = false
    })
    
    self:ApplyCornerRadius(toggleButton, 12)
    
    -- Indicador interno do toggle
    local toggleIndicator = self:CreateElement("Frame", {
        Name = "Indicator",
        Size = UDim2.new(0, 21, 0, 21),
        Position = UDim2.new(0, toggleState and 27 or 2, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0
    })
    
    self:ApplyCornerRadius(toggleIndicator, 10)
    
    label.Parent = toggleFrame
    toggleButton.Parent = toggleFrame
    toggleIndicator.Parent = toggleButton
    toggleFrame.Parent = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    table.insert(tab.Elements, toggleFrame)
    
    local content = self.ContentFrame:FindFirstChild("TabContent" .. tab.Id)
    if content then
        content.CanvasSize = UDim2.new(0, 0, 0, #tab.Elements * 38)
    end
    
    toggleButton.MouseButton1Click:Connect(function()
        toggleState = not toggleState
        
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local backgroundTween = TweenService:Create(toggleButton, tweenInfo, {
            BackgroundColor3 = toggleState and self.Themes[self.Settings.Theme].Accent or self.Themes[self.Settings.Theme].Secondary
        })
        
        local indicatorTween = TweenService:Create(toggleIndicator, tweenInfo, {
            Position = UDim2.new(0, toggleState and 27 or 2, 0, 2)
        })
        
        backgroundTween:Play()
        indicatorTween:Play()
        
        callback(toggleState)
    end)
    
    return {
        Set = function(state)
            toggleState = state
            toggleButton.BackgroundColor3 = toggleState and self.Themes[self.Settings.Theme].Accent or self.Themes[self.Settings.Theme].Secondary
            toggleIndicator.Position = UDim2.new(0, toggleState and 27 or 2, 0, 2)
        end,
        Get = function()
            return toggleState
        end
    }
end

-- Mudar tema
function StellarUI:SetTheme(themeName)
    if self.Themes[themeName] then
        self.Settings.Theme = themeName
        local theme = self.Themes[themeName]
        
        self.MainFrame.BackgroundColor3 = theme.Background
        self.Header.BackgroundColor3 = theme.Secondary
        self.PlayerSection.BackgroundColor3 = theme.Secondary
        self.Title.TextColor3 = theme.Text
        self.PlayerName.TextColor3 = theme.Text
        
        -- Atualizar outros elementos dinamicamente
        print("Tema alterado para: " .. themeName)
    else
        warn("Tema '" .. themeName .. "' não encontrado!")
    end
end

-- Destruir UI
function StellarUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    if self.InputConnection then
        self.InputConnection:Disconnect()
    end
    self.Initialized = false
end

-- Inicializar automaticamente
StellarUI:Init()

return StellarUI
