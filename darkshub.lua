--[[
    DARK'S HUB PREMIUM - VERSAO FINAL COM COMBATE AVANCADO
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

print("Dark's Hub - Iniciando")

-- ============================================================
-- PALETA DE CORES
-- ============================================================
local C = {
    bg          = Color3.fromRGB(14, 16, 24),
    bgAlt       = Color3.fromRGB(20, 23, 34),
    card        = Color3.fromRGB(26, 30, 44),
    cardHover   = Color3.fromRGB(34, 40, 58),
    accent      = Color3.fromRGB(0, 170, 255),
    accent2     = Color3.fromRGB(140, 80, 255),
    accentSoft  = Color3.fromRGB(0, 120, 200),
    text        = Color3.fromRGB(235, 240, 250),
    textDim     = Color3.fromRGB(140, 150, 170),
    success     = Color3.fromRGB(50, 200, 130),
    danger      = Color3.fromRGB(220, 70, 90),
    warning     = Color3.fromRGB(240, 170, 60),
    stroke      = Color3.fromRGB(45, 55, 80),
}

-- ============================================================
-- CONTAS
-- ============================================================
local ACCOUNTS_KEY = "DarksHub_Accounts"
local CURRENT_USER_KEY = "DarksHub_CurrentUser"

local dataGui = CoreGui:FindFirstChild("DarksHubData")
if not dataGui then
    dataGui = Instance.new("ScreenGui")
    dataGui.Name = "DarksHubData"; dataGui.ResetOnSpawn = false
    dataGui.Parent = CoreGui
end
local accountsStr = dataGui:FindFirstChild(ACCOUNTS_KEY)
if not accountsStr then
    accountsStr = Instance.new("StringValue"); accountsStr.Name = ACCOUNTS_KEY
    accountsStr.Parent = dataGui; accountsStr.Value = "{}"
end
local currentUserStr = dataGui:FindFirstChild(CURRENT_USER_KEY)
if not currentUserStr then
    currentUserStr = Instance.new("StringValue"); currentUserStr.Name = CURRENT_USER_KEY
    currentUserStr.Parent = dataGui; currentUserStr.Value = ""
end
local accounts = {}
local function syncAccounts()
    local ok, data = pcall(function() return HttpService:JSONDecode(accountsStr.Value) end)
    if ok and type(data) == "table" then accounts = data else accounts = {} end
    if not accounts["admin"] then
        accounts["admin"] = "admin123"
        accountsStr.Value = HttpService:JSONEncode(accounts)
    end
end
syncAccounts()
local function saveAccounts() accountsStr.Value = HttpService:JSONEncode(accounts) end

local _addLogHook = nil
local function addLog(msg)
    print("[HUB] " .. msg)
    if _addLogHook then _addLogHook(msg) end
end

-- ============================================================
-- LOGIN
-- ============================================================
local function mostrarTelaLogin()
    local loginGui = Instance.new("ScreenGui")
    loginGui.Name = "LoginGUI"; loginGui.ResetOnSpawn = false
    loginGui.Parent = CoreGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 340)
    frame.Position = UDim2.new(0.5, -190, 0.5, -170)
    frame.BackgroundColor3 = C.bg; frame.Parent = loginGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)
    local stroke = Instance.new("UIStroke")
    stroke.Color = C.accent; stroke.Thickness = 1.5; stroke.Transparency = 0.4
    stroke.Parent = frame

    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    glow.Rotation = 90; glow.Parent = stroke

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,55); title.Text = "DARK'S HUB"
    title.Font = Enum.Font.GothamBlack; title.TextSize = 26
    title.TextColor3 = Color3.fromRGB(255,255,255); title.BackgroundTransparency = 1
    title.Parent = frame

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1,0,0,18); sub.Position = UDim2.new(0,0,0,50)
    sub.Text = "PREMIUM EDITION"
    sub.Font = Enum.Font.GothamBold; sub.TextSize = 10
    sub.TextColor3 = C.accent; sub.BackgroundTransparency = 1
    sub.Parent = frame

    local function makeBox(y, ph)
        local b = Instance.new("TextBox")
        b.Size = UDim2.new(0.82,0,0,38); b.Position = UDim2.new(0.09,0,y,0)
        b.PlaceholderText = ph; b.Font = Enum.Font.Gotham
        b.TextSize = 14; b.BackgroundColor3 = C.card
        b.TextColor3 = C.text; b.ClearTextOnFocus = false
        b.PlaceholderColor3 = C.textDim
        b.Parent = frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        local s = Instance.new("UIStroke")
        s.Color = C.stroke; s.Thickness = 1; s.Parent = b
        return b
    end
    local userBox = makeBox(0.25, "Usuario")
    local passBox = makeBox(0.4, "Senha")
    local confirmBox = makeBox(0.55, "Confirmar senha")
    confirmBox.Visible = false

    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1,0,0,20); errorLabel.Position = UDim2.new(0,0,0.68,0)
    errorLabel.Text = ""; errorLabel.Font = Enum.Font.Gotham
    errorLabel.TextSize = 11; errorLabel.TextColor3 = C.danger
    errorLabel.BackgroundTransparency = 1; errorLabel.Visible = false
    errorLabel.Parent = frame

    local loginBtn = Instance.new("TextButton")
    loginBtn.Size = UDim2.new(0.36,0,0,42); loginBtn.Position = UDim2.new(0.07,0,0.8,0)
    loginBtn.Text = "ENTRAR"; loginBtn.Font = Enum.Font.GothamBold
    loginBtn.TextSize = 14; loginBtn.BackgroundColor3 = C.accent
    loginBtn.TextColor3 = Color3.fromRGB(255,255,255); loginBtn.Parent = frame
    Instance.new("UICorner", loginBtn).CornerRadius = UDim.new(0, 10)
    local lg = Instance.new("UIGradient")
    lg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    lg.Parent = loginBtn

    local createBtn = Instance.new("TextButton")
    createBtn.Size = UDim2.new(0.36,0,0,42); createBtn.Position = UDim2.new(0.57,0,0.8,0)
    createBtn.Text = "CRIAR CONTA"; createBtn.Font = Enum.Font.GothamBold
    createBtn.TextSize = 12; createBtn.BackgroundColor3 = C.card
    createBtn.TextColor3 = C.text; createBtn.Parent = frame
    Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = C.stroke; s.Thickness = 1; s.Parent = createBtn

    local createMode = false
    local function setCreateMode(on)
        createMode = on; confirmBox.Visible = on
        title.Text = on and "CRIAR CONTA" or "DARK'S HUB"
        loginBtn.Text = on and "CRIAR" or "ENTRAR"
        createBtn.Text = on and "VOLTAR" or "CRIAR CONTA"
        passBox.PlaceholderText = on and "Nova senha" or "Senha"
        if on then confirmBox.Text = "" end
        errorLabel.Visible = false
    end
    local function attempt()
        local u, p = userBox.Text, passBox.Text
        if u == "" or p == "" then
            errorLabel.Text = "Preencha todos os campos!"; errorLabel.Visible = true; return
        end
        if createMode then
            if p ~= confirmBox.Text then
                errorLabel.Text = "Senhas nao coincidem!"
                errorLabel.TextColor3 = C.danger; errorLabel.Visible = true; return
            end
            if accounts[u] then
                errorLabel.Text = "Usuario ja existe!"
                errorLabel.TextColor3 = C.danger; errorLabel.Visible = true; return
            end
            accounts[u] = p; saveAccounts()
            errorLabel.Text = "Conta criada!"; errorLabel.TextColor3 = C.success
            errorLabel.Visible = true; task.wait(1); setCreateMode(false); passBox.Text = ""
        else
            if accounts[u] == p then
                _G.loggedUser = u; currentUserStr.Value = u
                loginGui:Destroy(); task.wait(0.1); carregarHub()
            else
                errorLabel.Text = "Usuario ou senha incorretos!"
                errorLabel.TextColor3 = C.danger; errorLabel.Visible = true
            end
        end
    end
    createBtn.MouseButton1Click:Connect(function() setCreateMode(not createMode) end)
    loginBtn.MouseButton1Click:Connect(attempt)
    passBox.FocusLost:Connect(function(e) if e then attempt() end end)
    userBox.FocusLost:Connect(function(e) if e then passBox:CaptureFocus() end end)
end

-- ============================================================
-- HUB
-- ============================================================
function carregarHub()
    print("Carregando hub...")

    local gui = Instance.new("ScreenGui")
    gui.Name = "DarksHubPremium"; gui.ResetOnSpawn = false
    gui.Parent = CoreGui

    -- KEYBINDS ============================================
    local keybinds = {}
    local listening = nil
    local function formatKey(key)
        if not key then return "—" end
        local n = tostring(key):gsub("Enum.KeyCode.", "")
        if #n > 5 then n = n:sub(1, 5) end
        return n
    end
    local function startListening(id, btn)
        if listening and listening.btn then
            local ok = keybinds[listening.id]
            listening.btn.Text = ok and formatKey(ok.key) or "—"
            listening.btn.BackgroundColor3 = C.card
        end
        listening = {id = id, btn = btn}
        btn.Text = "..."; btn.BackgroundColor3 = C.warning
        addLog("Pressione uma tecla (ESC cancela)")
    end
    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening then
            if input.KeyCode == Enum.KeyCode.Escape then
                local ok = keybinds[listening.id]
                listening.btn.Text = ok and formatKey(ok.key) or "—"
                listening.btn.BackgroundColor3 = C.card
                listening = nil; return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[listening.id] = keybinds[listening.id] or {}
                keybinds[listening.id].key = input.KeyCode
                listening.btn.Text = formatKey(input.KeyCode)
                listening.btn.BackgroundColor3 = C.card
                addLog("Keybind: " .. tostring(input.KeyCode))
                listening = nil; return
            end
            return
        end
        if gpe then return end
        for _, kb in pairs(keybinds) do
            if kb.key and kb.key == input.KeyCode and kb.callback then kb.callback() end
        end
    end)

    -- PAINEL =============================================
    local avatarURL = ""
    pcall(function()
        avatarURL = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 210, 0, 62)
    panel.Position = UDim2.new(0, 10, 1, -72)
    panel.BackgroundColor3 = C.bg
    panel.BackgroundTransparency = 0.1; panel.BorderSizePixel = 0
    panel.Parent = gui; Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
    local pStroke = Instance.new("UIStroke")
    pStroke.Color = C.accent; pStroke.Thickness = 1.5
    pStroke.Transparency = 0.35; pStroke.Parent = panel
    local pGrad = Instance.new("UIGradient")
    pGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    pGrad.Rotation = 45; pGrad.Parent = pStroke
    local avatarImg = Instance.new("ImageLabel")
    avatarImg.Size = UDim2.new(0, 46, 0, 46)
    avatarImg.Position = UDim2.new(0, 8, 0.5, -23)
    avatarImg.BackgroundColor3 = C.card; avatarImg.BorderSizePixel = 0
    avatarImg.Image = avatarURL; avatarImg.Parent = panel
    Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
    local avStroke = Instance.new("UIStroke")
    avStroke.Color = C.accent; avStroke.Thickness = 1.5
    avStroke.Parent = avatarImg
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -70, 0, 22)
    nameLbl.Position = UDim2.new(0, 62, 0, 12)
    nameLbl.Text = LP.Name; nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 13; nameLbl.TextColor3 = C.text
    nameLbl.BackgroundTransparency = 1; nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd; nameLbl.Parent = panel
    local userLbl = Instance.new("TextLabel")
    userLbl.Size = UDim2.new(1, -70, 0, 18)
    userLbl.Position = UDim2.new(0, 62, 0, 32)
    userLbl.Text = "Conta: " .. (_G.loggedUser or "?")
    userLbl.Font = Enum.Font.Gotham; userLbl.TextSize = 11
    userLbl.TextColor3 = C.accent
    userLbl.BackgroundTransparency = 1; userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd; userLbl.Parent = panel

    -- HEX ================================================
    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(0, 78, 0, 78)
    btn.Position = UDim2.new(0, 10, 0.5, -39)
    btn.BackgroundTransparency = 1; btn.ImageTransparency = 1
    btn.Parent = gui
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1,8,1,8); glow.Position = UDim2.new(0,-4,0,-4)
    glow.BackgroundColor3 = C.accent
    glow.BackgroundTransparency = 0.7; glow.BorderSizePixel = 0
    glow.Parent = btn; Instance.new("UICorner", glow).CornerRadius = UDim.new(0,14)
    local hex = Instance.new("Frame")
    hex.Size = UDim2.new(1,0,1,0); hex.BackgroundColor3 = C.bgAlt
    hex.Parent = btn; Instance.new("UICorner", hex).CornerRadius = UDim.new(0,14)
    local hexStroke = Instance.new("UIStroke")
    hexStroke.Color = C.accent; hexStroke.Thickness = 1.5
    hexStroke.Transparency = 0.3; hexStroke.Parent = hex
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    grad.Rotation = 45; grad.Parent = hex
    local dText = Instance.new("TextLabel")
    dText.Size = UDim2.new(1,0,1,0); dText.Text = "DK"
    dText.Font = Enum.Font.GothamBlack; dText.TextSize = 30
    dText.TextColor3 = Color3.fromRGB(255,255,255); dText.BackgroundTransparency = 1
    dText.Parent = hex
    task.spawn(function()
        while gui.Parent do
            TweenService:Create(glow, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                BackgroundTransparency = 0.4, Size = UDim2.new(1, 14, 1, 14)
            }):Play()
            task.wait(1.4)
        end
    end)

    -- MENU ================================================
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 780, 0, 590)
    mainFrame.Position = UDim2.new(0.5, -390, 0.5, -295)
    mainFrame.BackgroundColor3 = C.bg
    mainFrame.Visible = false; mainFrame.Parent = gui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18)
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = C.stroke; mainStroke.Thickness = 1; mainStroke.Parent = mainFrame

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1,0,0,52); titleBar.BackgroundColor3 = C.bgAlt
    titleBar.Parent = mainFrame
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0,18)
    local tbFix = Instance.new("Frame")
    tbFix.Size = UDim2.new(1,0,0.5,0); tbFix.Position = UDim2.new(0,0,0.5,0)
    tbFix.BackgroundColor3 = C.bgAlt; tbFix.BorderSizePixel = 0; tbFix.Parent = titleBar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1,-160,1,0); titleLbl.Position = UDim2.new(0,20,0,0)
    titleLbl.Text = "DARK'S HUB  •  " .. (_G.loggedUser or "?")
    titleLbl.Font = Enum.Font.GothamBold; titleLbl.TextSize = 15
    titleLbl.TextColor3 = C.text; titleLbl.BackgroundTransparency = 1
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.Parent = titleBar

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 0, 26); accentBar.Position = UDim2.new(0, 10, 0.5, -13)
    accentBar.BackgroundColor3 = C.accent; accentBar.BorderSizePixel = 0
    accentBar.Parent = titleBar
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(1, 0)
    local abGrad = Instance.new("UIGradient")
    abGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    abGrad.Parent = accentBar

    local minimizeBtn = Instance.new("TextButton")
    minimizeBtn.Size = UDim2.new(0,32,0,32); minimizeBtn.Position = UDim2.new(1,-84,0,10)
    minimizeBtn.Text = "—"; minimizeBtn.Font = Enum.Font.GothamBold
    minimizeBtn.TextSize = 16; minimizeBtn.BackgroundColor3 = C.card
    minimizeBtn.TextColor3 = C.text; minimizeBtn.Parent = titleBar
    Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0,8)
    local minimizeStroke = Instance.new("UIStroke")
    minimizeStroke.Color = C.stroke; minimizeStroke.Thickness = 1; minimizeStroke.Parent = minimizeBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0,32,0,32); closeBtn.Position = UDim2.new(1,-46,0,10)
    closeBtn.Text = "X"; closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14; closeBtn.BackgroundColor3 = C.danger
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255); closeBtn.Parent = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

    local reopenBtn = Instance.new("TextButton")
    reopenBtn.Size = UDim2.new(0,42,0,42); reopenBtn.Position = UDim2.new(0,10,0,10)
    reopenBtn.Text = "▼"; reopenBtn.Font = Enum.Font.GothamBold
    reopenBtn.TextSize = 18; reopenBtn.BackgroundColor3 = C.accent
    reopenBtn.TextColor3 = Color3.fromRGB(255,255,255); reopenBtn.Visible = false
    reopenBtn.Parent = gui; Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0,12)
    local rg = Instance.new("UIGradient")
    rg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2)
    })
    rg.Parent = reopenBtn

    local function fecharTudo()
        mainFrame.Visible = false; btn.Visible = false
        panel.Visible = false; reopenBtn.Visible = true
    end
    local function reabrirTudo()
        btn.Visible = true; panel.Visible = true; reopenBtn.Visible = false
    end
    closeBtn.MouseButton1Click:Connect(fecharTudo)
    minimizeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)
    reopenBtn.MouseButton1Click:Connect(reabrirTudo)
    keybinds["menu_toggle"] = keybinds["menu_toggle"] or {}
    keybinds["menu_toggle"].callback = function()
        mainFrame.Visible = not mainFrame.Visible
        if mainFrame.Visible then reabrirTudo() end
    end

    -- SIDEBAR =============================================
    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Size = UDim2.new(0, 150, 1, -60)
    sidebar.Position = UDim2.new(0, 6, 0, 56)
    sidebar.BackgroundColor3 = C.bgAlt
    sidebar.BorderSizePixel = 0
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 800)
    sidebar.ScrollBarThickness = 3
    sidebar.ScrollBarImageColor3 = C.accent
    sidebar.Parent = mainFrame
    Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 14)

    local tabNames = {
        {"MIRA", "◎"},
        {"ESP", "◈"},
        {"JOGADOR", "☰"},
        {"COMBATE", "✦"},
        {"UTIL", "⚙"},
        {"EXTRAS", "✧"},
        {"MUNDO", "◐"},
        {"LOG", "≡"},
        {"SERV", "⌘"},
        {"CONFIG", "☰"},
        {"TROLL", "☠"},
        {"PERSONALIZAR", "❋"}
    }
    local tabButtons, contentFrames = {}, {}
    local function switchTab(index)
        for i, f in ipairs(contentFrames) do
            f.Visible = (i == index)
        end
        for i, data in ipairs(tabButtons) do
            local isActive = (i == index)
            data.btn.BackgroundColor3 = isActive and C.card or C.bgAlt
            data.btn.TextColor3 = isActive and C.text or C.textDim
            data.indicator.BackgroundColor3 = isActive and C.accent or C.bgAlt
            data.icon.TextColor3 = isActive and C.accent or C.textDim
        end
    end
    for i, data in ipairs(tabNames) do
        local name, icon = data[1], data[2]
        local btnTab = Instance.new("TextButton")
        btnTab.Size = UDim2.new(1,-12,0,38); btnTab.Position = UDim2.new(0,6,0,6+(i-1)*44)
        btnTab.Text = ""; btnTab.BackgroundColor3 = C.bgAlt
        btnTab.BorderSizePixel = 0; btnTab.Parent = sidebar
        Instance.new("UICorner", btnTab).CornerRadius = UDim.new(0, 10)

        local ind = Instance.new("Frame")
        ind.Size = UDim2.new(0, 3, 0, 20); ind.Position = UDim2.new(0, 2, 0.5, -10)
        ind.BackgroundColor3 = C.bgAlt; ind.BorderSizePixel = 0; ind.Parent = btnTab
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

        local ic = Instance.new("TextLabel")
        ic.Size = UDim2.new(0, 24, 1, 0); ic.Position = UDim2.new(0, 12, 0, 0)
        ic.Text = icon; ic.Font = Enum.Font.GothamBold; ic.TextSize = 15
        ic.TextColor3 = C.textDim; ic.BackgroundTransparency = 1; ic.Parent = btnTab

        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1, -42, 1, 0); lb.Position = UDim2.new(0, 40, 0, 0)
        lb.Text = name; lb.Font = Enum.Font.GothamSemibold; lb.TextSize = 11
        lb.TextColor3 = C.textDim; lb.BackgroundTransparency = 1
        lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = btnTab

        btnTab.MouseButton1Click:Connect(function() switchTab(i) end)
        btnTab.MouseEnter:Connect(function()
            if tabButtons[i] and contentFrames[i] and not contentFrames[i].Visible then
                btnTab.BackgroundColor3 = C.cardHover
            end
        end)
        btnTab.MouseLeave:Connect(function()
            if contentFrames[i] and not contentFrames[i].Visible then
                btnTab.BackgroundColor3 = C.bgAlt
            end
        end)

        tabButtons[i] = {btn = btnTab, indicator = ind, icon = ic, label = lb}

        local frame = Instance.new("ScrollingFrame")
        frame.Size = UDim2.new(1,-168,1,-66); frame.Position = UDim2.new(0,162,0,60)
        frame.BackgroundTransparency = 1
        frame.CanvasSize = UDim2.new(0,0,0,900)
        frame.ScrollBarThickness = 3
        frame.ScrollBarImageColor3 = C.accent
        frame.BorderSizePixel = 0; frame.Parent = mainFrame
        frame.Visible = (i == 1); contentFrames[i] = frame
    end
    switchTab(1)

    -- UI HELPERS ==========================================
    local function addHeader(parent, text, y)
        local h = Instance.new("TextLabel")
        h.Size = UDim2.new(1,-20,0,26); h.Position = UDim2.new(0,10,0,y)
        h.Text = string.upper(text)
        h.Font = Enum.Font.GothamBold; h.TextSize = 11
        h.TextColor3 = C.accent; h.BackgroundTransparency = 1
        h.TextXAlignment = Enum.TextXAlignment.Left
        h.Parent = parent
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1,-20,0,1); line.Position = UDim2.new(0,10,0,y+22)
        line.BackgroundColor3 = C.stroke; line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.5; line.Parent = parent
        return y + 30
    end

    local function addToggle(parent, id, text, y, def, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,-20,0,40); f.Position = UDim2.new(0,10,0,y)
        f.BackgroundColor3 = C.card; f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = C.stroke; fs.Thickness = 1; fs.Transparency = 0.5; fs.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-170,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = C.text; lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd; lbl.Parent = f

        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0,50,0,24); kbBtn.Position = UDim2.new(1,-120,0.5,-12)
        kbBtn.Text = keybinds[id] and formatKey(keybinds[id].key) or "—"
        kbBtn.Font = Enum.Font.GothamBold; kbBtn.TextSize = 10
        kbBtn.BackgroundColor3 = C.bgAlt
        kbBtn.TextColor3 = C.textDim; kbBtn.BorderSizePixel = 0
        kbBtn.Parent = f
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)
        local kbs = Instance.new("UIStroke")
        kbs.Color = C.stroke; kbs.Thickness = 1; kbs.Parent = kbBtn

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,50,0,24); b.Position = UDim2.new(1,-62,0.5,-12)
        b.Text = ""; b.Font = Enum.Font.GothamBold; b.TextSize = 10
        b.BackgroundColor3 = def and C.success or C.bgAlt
        b.BorderSizePixel = 0; b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
        local bs = Instance.new("UIStroke")
        bs.Color = def and C.success or C.stroke; bs.Thickness = 1; bs.Parent = b

        -- knob
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = def and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
        knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        knob.BorderSizePixel = 0; knob.Parent = b
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = def
        local function toggle()
            state = not state
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = state and C.success or C.bgAlt
            }):Play()
            TweenService:Create(bs, TweenInfo.new(0.15), {
                Color = state and C.success or C.stroke
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1,-21,0.5,-9) or UDim2.new(0,3,0.5,-9)
            }):Play()
            cb(state)
        end

        b.MouseButton1Click:Connect(toggle)
        kbBtn.MouseButton1Click:Connect(function() startListening(id, kbBtn) end)

        f.MouseEnter:Connect(function()
            TweenService:Create(f, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
        end)
        f.MouseLeave:Connect(function()
            TweenService:Create(f, TweenInfo.new(0.15), {BackgroundColor3 = C.card}):Play()
        end)

        keybinds[id] = keybinds[id] or {}
        keybinds[id].callback = toggle
        keybinds[id].btn = kbBtn
    end

    local function addKeybindRow(parent, id, text, y, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,-20,0,40); f.Position = UDim2.new(0,10,0,y)
        f.BackgroundColor3 = C.card; f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = C.stroke; fs.Thickness = 1; fs.Transparency = 0.5; fs.Parent = f
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1,-110,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = C.text; lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local kbBtn = Instance.new("TextButton")
        kbBtn.Size = UDim2.new(0,80,0,28); kbBtn.Position = UDim2.new(1,-92,0.5,-14)
        kbBtn.Text = keybinds[id] and formatKey(keybinds[id].key) or "—"
        kbBtn.Font = Enum.Font.GothamBold; kbBtn.TextSize = 11
        kbBtn.BackgroundColor3 = C.bgAlt; kbBtn.TextColor3 = C.text
        kbBtn.BorderSizePixel = 0; kbBtn.Parent = f
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 8)
        local kbs = Instance.new("UIStroke")
        kbs.Color = C.stroke; kbs.Thickness = 1; kbs.Parent = kbBtn
        keybinds[id] = keybinds[id] or {}
        if cb then keybinds[id].callback = cb end
        keybinds[id].btn = kbBtn
        kbBtn.MouseButton1Click:Connect(function() startListening(id, kbBtn) end)
    end

    local function addButton(parent, text, y, color, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,-20,0,40); b.Position = UDim2.new(0,10,0,y)
        b.Text = text; b.Font = Enum.Font.GothamBold; b.TextSize = 12
        b.BackgroundColor3 = color; b.TextColor3 = Color3.fromRGB(255,255,255)
        b.BorderSizePixel = 0; b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        local bs = Instance.new("UIStroke")
        bs.Color = color:Lerp(Color3.new(1,1,1), 0.3); bs.Thickness = 1
        bs.Transparency = 0.5; bs.Parent = b
        local baseColor = color
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = baseColor:Lerp(Color3.new(1,1,1), 0.15)
            }):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {
                BackgroundColor3 = baseColor
            }):Play()
        end)
        if cb then b.MouseButton1Click:Connect(cb) end
        return b
    end

    local function addSlider(parent, text, y, minv, maxv, def, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,-20,0,60); f.Position = UDim2.new(0,10,0,y)
        f.BackgroundColor3 = C.card; f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = C.stroke; fs.Thickness = 1; fs.Transparency = 0.5; fs.Parent = f

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7,0,0,22); lbl.Position = UDim2.new(0,12,0,6)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = C.text; lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 60, 0, 22); valLbl.Position = UDim2.new(1,-140,0,6)
        valLbl.Text = tostring(def); valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12; valLbl.TextColor3 = C.accent
        valLbl.BackgroundTransparency = 1; valLbl.Parent = f

        -- Barra de progresso visual
        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1,-80,0,6); barBg.Position = UDim2.new(0,12,0,36)
        barBg.BackgroundColor3 = C.bgAlt; barBg.BorderSizePixel = 0
        barBg.Parent = f
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new((def-minv)/(maxv-minv), 0, 1, 0)
        barFill.BackgroundColor3 = C.accent; barFill.BorderSizePixel = 0
        barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
        local bg2 = Instance.new("UIGradient")
        bg2.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.accent),
            ColorSequenceKeypoint.new(1, C.accent2)
        })
        bg2.Parent = barFill

        local minus = Instance.new("TextButton")
        minus.Size = UDim2.new(0,26,0,26); minus.Position = UDim2.new(1,-62,0.5,-13)
        minus.Text = "−"; minus.Font = Enum.Font.GothamBold; minus.TextSize = 16
        minus.BackgroundColor3 = C.bgAlt; minus.TextColor3 = C.text
        minus.BorderSizePixel = 0; minus.Parent = f
        Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
        local mns = Instance.new("UIStroke")
        mns.Color = C.stroke; mns.Thickness = 1; mns.Parent = minus

        local plus = Instance.new("TextButton")
        plus.Size = UDim2.new(0,26,0,26); plus.Position = UDim2.new(1,-32,0.5,-13)
        plus.Text = "+"; plus.Font = Enum.Font.GothamBold; plus.TextSize = 16
        plus.BackgroundColor3 = C.bgAlt; plus.TextColor3 = C.text
        plus.BorderSizePixel = 0; plus.Parent = f
        Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
        local pls = Instance.new("UIStroke")
        pls.Color = C.stroke; pls.Thickness = 1; pls.Parent = plus

        local val = def
        local function update()
            valLbl.Text = tostring(val)
            TweenService:Create(barFill, TweenInfo.new(0.15), {
                Size = UDim2.new((val-minv)/(maxv-minv), 0, 1, 0)
            }):Play()
            cb(val)
        end
        minus.MouseButton1Click:Connect(function()
            val = math.clamp(val - 1, minv, maxv); update()
        end)
        plus.MouseButton1Click:Connect(function()
            val = math.clamp(val + 1, minv, maxv); update()
        end)
        cb(def)
    end

    local function addColorPicker(parent, text, y, def, cb)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1,-20,0,40); f.Position = UDim2.new(0,10,0,y)
        f.BackgroundColor3 = C.card; f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local fs = Instance.new("UIStroke")
        fs.Color = C.stroke; fs.Thickness = 1; fs.Transparency = 0.5; fs.Parent = f
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.6,0,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.Text = text; lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12
        lbl.TextColor3 = C.text; lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local colorBtn = Instance.new("TextButton")
        colorBtn.Size = UDim2.new(0,50,0,26); colorBtn.Position = UDim2.new(1,-62,0.5,-13)
        colorBtn.Text = ""; colorBtn.BackgroundColor3 = def
        colorBtn.BorderSizePixel = 0; colorBtn.Parent = f
        Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 8)
        local cbs = Instance.new("UIStroke")
        cbs.Color = C.stroke; cbs.Thickness = 1; cbs.Parent = colorBtn
        local colors = {
            Color3.fromRGB(255,0,0), Color3.fromRGB(0,100,255), Color3.fromRGB(255,255,255),
            Color3.fromRGB(0,255,0), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255),
            Color3.fromRGB(255,140,0), Color3.fromRGB(0,255,255)
        }
        local idx = 1
        colorBtn.MouseButton1Click:Connect(function()
            idx = idx % #colors + 1
            colorBtn.BackgroundColor3 = colors[idx]; cb(colors[idx])
        end)
        cb(def)
    end

    -- LOG ================================================
    local logScrl, logPh, logsList
    do
        local fLog = contentFrames[8]
        logScrl = Instance.new("ScrollingFrame")
        logScrl.Size = UDim2.new(1,-20,1,-20); logScrl.Position = UDim2.new(0,10,0,10)
        logScrl.BackgroundColor3 = C.bgAlt
        logScrl.BorderSizePixel = 0
        logScrl.CanvasSize = UDim2.new(0,0,0,40); logScrl.ScrollBarThickness = 3
        logScrl.ScrollBarImageColor3 = C.accent
        logScrl.Parent = fLog
        Instance.new("UICorner", logScrl).CornerRadius = UDim.new(0,12)
        logPh = Instance.new("TextLabel")
        logPh.Size = UDim2.new(1,0,0,30); logPh.Position = UDim2.new(0,0,0,10)
        logPh.Text = "Nenhum registro..."; logPh.Font = Enum.Font.Gotham
        logPh.TextSize = 13; logPh.TextColor3 = C.textDim
        logPh.BackgroundTransparency = 1; logPh.Parent = logScrl
        logsList = {}
        _addLogHook = function(msg)
            local t = os.date("%H:%M:%S")
            table.insert(logsList, 1, {time = t, text = msg})
            if #logsList > 100 then table.remove(logsList) end
            for _, c in ipairs(logScrl:GetChildren()) do
                if c:IsA("TextLabel") and c ~= logPh then c:Destroy() end
            end
            local dy = 5
            for _, log in ipairs(logsList) do
                local line = Instance.new("TextLabel")
                line.Size = UDim2.new(1,-20,0,26); line.Position = UDim2.new(0,10,0,dy)
                line.Text = "  ["..log.time.."]  "..log.text
                line.Font = Enum.Font.Gotham; line.TextSize = 11
                line.TextColor3 = C.text
                line.BackgroundColor3 = C.card
                line.BorderSizePixel = 0
                line.TextXAlignment = Enum.TextXAlignment.Left
                line.Parent = logScrl
                Instance.new("UICorner", line).CornerRadius = UDim.new(0,6)
                dy = dy + 30
            end
            if dy == 5 then
                logPh.Visible = true; logScrl.CanvasSize = UDim2.new(0,0,0,40)
            else
                logPh.Visible = false; logScrl.CanvasSize = UDim2.new(0,0,0,dy+10)
            end
        end
        addLog("Hub carregado. Usuario: " .. (_G.loggedUser or "?"))
    end

    -- ESTADO =============================================
    local aimActive, aimFOV, aimSmooth, aimPart = false, 200, 5, "Head"
    local showFOV, fovColor = true, Color3.fromRGB(0,170,255)
    local aimAssistOn, aimAssistStrength = false, 0.15
    local triggerBotOn, triggerBotDelay = false, 0.05
    local espOn, espBox, espName, espDist = false, true, true, true
    local espHealth, espSkel, espTracers, espThick = false, false, false, 1
    local espEnemyColor = Color3.fromRGB(255,0,0)
    local espAllyColor = Color3.fromRGB(0,255,0)
    local tracerColor = Color3.fromRGB(255,255,255)
    local speedOn, speedVal, noclipOn = false, 80, false
    local silentAim, silentAimFOV = false, 100
    local hitboxExpand, hitboxSize = false, 1.5
    local timeLock, timeVal, fogOn, brightNight, noFog = false, 12, false, false, false

    -- COMBATE AVANCADO
    local killAuraOn, killAuraRange, killAuraDmg = false, 15, 5
    local wallBangOn = false
    local noRecoilOn = false
    local noSpreadOn = false
    local autoReloadOn = false
    local infiniteAmmoOn = false
    local rapidFireOn = false
    local instantHitOn = false

    -- EXTRAS
    local antiAfkOn = false
    local infiniteJumpOn = false
    local flyOn = false
    local flySpeed = 80
    local fullBrightOn = false
    local fpsCounterOn = false
    local pingCounterOn = false
    local antiFlingOn = false
    local savedPosition = nil

    -- AGUA ================================================
    local waterWalkParts = {}
    local function toggleWaterWalk(state)
        if state then
            waterWalkParts = {}
            local found = 0
            for _, part in ipairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    local n = part.Name:lower()
                    local inWater = false
                    local p = part.Parent
                    while p do
                        if p:IsA("Model") and p.Name:lower():find("water") then
                            inWater = true; break
                        end
                        p = p.Parent
                    end
                    if n:find("water") or inWater then
                        table.insert(waterWalkParts, {part = part, orig = part.CanCollide})
                        part.CanCollide = true; found = found + 1
                    end
                end
            end
            addLog(found > 0 and ("Agua ON ("..found..")") or "Nenhuma agua")
        else
            for _, e in ipairs(waterWalkParts) do
                if e.part and e.part.Parent then e.part.CanCollide = e.orig end
            end
            waterWalkParts = {}; addLog("Agua OFF")
        end
    end

    -- PUXAR TOOLS
    local function puxarTools()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") then
                local ok = pcall(function()
                    if LP.Backpack then obj.Parent = LP.Backpack end
                end)
                if ok then count = count + 1 end
            end
        end
        addLog("Puxadas " .. count .. " tools")
    end

    -- TP TOOL
    local function criarToolTeleporte()
        local backpack = LP:FindFirstChildOfClass("Backpack")
        if not backpack then
            pcall(function() LP:WaitForChild("Backpack", 5) end)
            backpack = LP:FindFirstChildOfClass("Backpack")
        end
        if not backpack then return end
        for _, p in ipairs({backpack, LP.Character}) do
            if p then
                local old = p:FindFirstChild("Teleport Tool")
                if old then old:Destroy() end
            end
        end
        local tool = Instance.new("Tool")
        tool.Name = "Teleport Tool"; tool.RequiresHandle = false
        tool.CanBeDropped = false; tool.ToolTip = "Clique onde quiser"
        tool.Activated:Connect(function()
            local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
            local ray = Ray.new(unitRay.Origin, unitRay.Direction * 2000)
            local _, pos = Workspace:FindPartOnRay(ray, LP.Character)
            if pos and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) end
            end
        end)
        tool.Parent = backpack
        addLog("TP Tool criada")
    end
    task.spawn(function() task.wait(0.3); pcall(criarToolTeleporte) end)
    LP.CharacterAdded:Connect(function() task.wait(1.5); pcall(criarToolTeleporte) end)

    -- AIMBOT ==============================================
    local function isTeammate(p) return LP.Team and p.Team and LP.Team == p.Team end
    local function getClosestTarget(fov)
        fov = fov or aimFOV
        local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        local bestD, bestT, bestP = fov, nil, nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or isTeammate(p) then continue end
            local ch = p.Character; if not ch then continue end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end
            local part = ch:FindFirstChild(aimPart) or ch:FindFirstChild("Head")
            if not part then continue end
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if not on then continue end
            local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
            if d < bestD then bestD, bestT, bestP = d, p, part.Position end
        end
        return bestT, bestP
    end
    local function updateAim()
        if not aimActive then return end
        local _, pos = getClosestTarget()
        if pos then
            local cf = CFrame.new(Camera.CFrame.Position, pos)
            Camera.CFrame = aimSmooth <= 1 and cf or Camera.CFrame:Lerp(cf, aimSmooth/20)
        end
    end
    local function updateAimAssist()
        if not aimAssistOn then return end
        local _, pos = getClosestTarget(300)
        if pos then
            local cf = CFrame.new(Camera.CFrame.Position, pos)
            Camera.CFrame = Camera.CFrame:Lerp(cf, aimAssistStrength)
        end
    end

    -- Trigger Bot
    local triggerConn = nil
    local function updateTriggerBot()
        if not triggerBotOn then
            if triggerConn then triggerConn:Disconnect() triggerConn = nil end
            return
        end
        if triggerConn then return end
        triggerConn = RunService.Heartbeat:Connect(function()
            if not triggerBotOn then return end
            local _, pos = getClosestTarget(aimFOV)
            if pos then
                pcall(function()
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                        Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2,
                        0, true, game, 0
                    )
                    task.wait(triggerBotDelay)
                    game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                        Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2,
                        0, false, game, 0
                    )
                end)
                task.wait(triggerBotDelay)
            end
        end)
    end

    -- Silent Aim
    local origFilter = nil
    local function setupSilentAim()
        if silentAim and not origFilter then
            origFilter = Mouse.TargetFilter
            Mouse.TargetFilter = Instance.new("Folder")
        elseif not silentAim and origFilter then
            if Mouse.TargetFilter then Mouse.TargetFilter:Destroy() end
            Mouse.TargetFilter = origFilter; origFilter = nil
        end
    end

    -- Hitbox
    local hitboxSizes = {}
    local function updateHitbox()
        if hitboxExpand then
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LP then continue end
                local ch = p.Character
                if ch then
                    for _, part in ipairs(ch:GetDescendants()) do
                        if part:IsA("BasePart") and not hitboxSizes[part] then
                            hitboxSizes[part] = part.Size
                            part.Size = part.Size * hitboxSize
                        end
                    end
                end
            end
        else
            for part, orig in pairs(hitboxSizes) do
                if part and part.Parent then part.Size = orig end
            end
            hitboxSizes = {}
        end
    end

    -- Kill Aura
    local killAuraConn = nil
    local function updateKillAura()
        if not killAuraOn then
            if killAuraConn then killAuraConn:Disconnect() killAuraConn = nil end
            return
        end
        if killAuraConn then return end
        killAuraConn = RunService.Heartbeat:Connect(function()
            if not killAuraOn or not LP.Character then return end
            local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LP or isTeammate(p) then continue end
                local ch = p.Character
                if not ch then continue end
                local hum = ch:FindFirstChildOfClass("Humanoid")
                local hrp = ch:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - myHRP.Position).Magnitude
                    if dist <= killAuraRange then
                        pcall(function()
                            local tool = LP.Character:FindFirstChildOfClass("Tool")
                            if tool then
                                tool:Activate()
                            else
                                hum:TakeDamage(killAuraDmg)
                            end
                        end)
                    end
                end
            end
        end)
    end

    -- Weapon Mods (aplica em Tools no character)
    local weaponConn = nil
    local function applyWeaponMods()
        if not LP.Character then return end
        local tool = LP.Character:FindFirstChildOfClass("Tool")
        if not tool then return end

        -- No Recoil / No Spread via Camera (afeita a maioria dos jogos)
        if noRecoilOn then
            pcall(function()
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                -- Nada generico, mas tenta zerar
            end)
        end

        if noSpreadOn then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") then
                    if v.Name:lower():find("spread") then pcall(function() v.Value = 0 end) end
                    if v.Name:lower():find("recoil") then pcall(function() v.Value = 0 end) end
                end
            end
        end

        if infiniteAmmoOn then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") then
                    if v.Name:lower():find("ammo") or v.Name:lower():find("clip") then
                        pcall(function() v.Value = 999 end)
                    end
                end
            end
        end

        if rapidFireOn then
            pcall(function()
                if tool:FindFirstChild("Cooldown") then tool.Cooldown.Value = 0 end
                if tool:FindFirstChild("FireRate") then tool.FireRate.Value = 999 end
            end)
        end
    end
    task.spawn(function()
        while gui.Parent do
            if LP.Character then
                local tool = LP.Character:FindFirstChildOfClass("Tool")
                if tool and (noRecoilOn or noSpreadOn or infiniteAmmoOn or rapidFireOn) then
                    pcall(applyWeaponMods)
                end
            end
            task.wait(0.3)
        end
    end)

    -- Instant Hit (via Hitbox grande rapido)
    -- (efeito combinado com hitbox expander)

    -- ESP =================================================
    local espDrawings = {}
    local function updateESP()
        if not espOn then
            for _, objs in pairs(espDrawings) do
                for _, d in pairs(objs) do if d and d.Remove then d:Remove() end end
            end
            espDrawings = {}; return
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP then continue end
            local ch = p.Character
            local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                if espDrawings[p] then
                    for _, d in pairs(espDrawings[p]) do if d and d.Remove then d:Remove() end end
                    espDrawings[p] = nil
                end
                continue
            end
            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            if not on then
                if espDrawings[p] then
                    for _, d in pairs(espDrawings[p]) do if d then d.Visible = false end end
                end
                continue
            end
            espDrawings[p] = espDrawings[p] or {}
            local objs = espDrawings[p]
            local scale = 100 / pos.Z
            local w, h = 40 * scale, 60 * scale
            local color = isTeammate(p) and espAllyColor or espEnemyColor
            if espBox then
                if not objs.Box then
                    objs.Box = Drawing.new("Square")
                    objs.Box.Thickness = espThick; objs.Box.Filled = false
                end
                objs.Box.Size = Vector2.new(w,h)
                objs.Box.Position = Vector2.new(pos.X - w/2, pos.Y - h/2)
                objs.Box.Visible = true; objs.Box.Color = color
            elseif objs.Box then objs.Box.Visible = false end
            if espName then
                if not objs.Name then
                    objs.Name = Drawing.new("Text")
                    objs.Name.Size = 12; objs.Name.Center = true
                    objs.Name.Outline = true
                    objs.Name.Color = Color3.fromRGB(255,255,255)
                end
                objs.Name.Text = p.Name
                objs.Name.Position = Vector2.new(pos.X, pos.Y - h/2 - 15)
                objs.Name.Visible = true
            elseif objs.Name then objs.Name.Visible = false end
            if espDist then
                if not objs.Dist then
                    objs.Dist = Drawing.new("Text")
                    objs.Dist.Size = 10; objs.Dist.Center = true
                    objs.Dist.Outline = true
                end
                objs.Dist.Text = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude) .. "m"
                objs.Dist.Position = Vector2.new(pos.X, pos.Y + h/2 + 5)
                objs.Dist.Visible = true
            elseif objs.Dist then objs.Dist.Visible = false end
            if espHealth then
                if not objs.Health then
                    objs.Health = Drawing.new("Text")
                    objs.Health.Size = 10; objs.Health.Center = true
                    objs.Health.Outline = true
                end
                objs.Health.Text = math.floor(hum.Health) .. " HP"
                objs.Health.Position = Vector2.new(pos.X, pos.Y - h/2 - 30)
                objs.Health.Visible = true
            elseif objs.Health then objs.Health.Visible = false end
            if espTracers then
                if not objs.Tracer then
                    objs.Tracer = Drawing.new("Line")
                    objs.Tracer.Thickness = 1
                end
                local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                objs.Tracer.From = c; objs.Tracer.To = Vector2.new(pos.X, pos.Y)
                objs.Tracer.Visible = true; objs.Tracer.Color = tracerColor
            elseif objs.Tracer then objs.Tracer.Visible = false end
            if espSkel then
                local head = ch:FindFirstChild("Head")
                if head then
                    local hp, hon = Camera:WorldToViewportPoint(head.Position)
                    if hon then
                        if not objs.Skel then
                            objs.Skel = Drawing.new("Line")
                            objs.Skel.Thickness = espThick
                        end
                        objs.Skel.From = Vector2.new(pos.X, pos.Y)
                        objs.Skel.To = Vector2.new(hp.X, hp.Y)
                        objs.Skel.Visible = true; objs.Skel.Color = color
                    elseif objs.Skel then objs.Skel.Visible = false end
                elseif objs.Skel then objs.Skel.Visible = false end
            elseif objs.Skel then objs.Skel.Visible = false end
        end
    end

    local function updateWorld()
        if timeLock then Lighting.ClockTime = timeVal end
        if fogOn then Lighting.FogEnd = 500 elseif not noFog then Lighting.FogEnd = 100000 end
        if noFog then Lighting.FogEnd = 0 end
        if brightNight then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        elseif not fullBrightOn then
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
        end
    end

    local fovCircle = nil
    local function updateFOV()
        if not showFOV or not aimActive then
            if fovCircle then fovCircle.Visible = false end
            return
        end
        if not fovCircle then
            pcall(function()
                fovCircle = Drawing.new("Circle")
                fovCircle.Thickness = 2; fovCircle.Filled = false
                fovCircle.NumSides = 64; fovCircle.Transparency = 0.6
            end)
        end
        if fovCircle then
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Radius = aimFOV; fovCircle.Color = fovColor
            fovCircle.Visible = true
        end
    end

    -- EXTRAS: SISTEMAS ====================================
    local antiAfkConn = nil
    local function toggleAntiAfk(state)
        if state then
            antiAfkConn = LP.Idled:Connect(function()
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end)
            addLog("Anti-AFK ON")
        else
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
            addLog("Anti-AFK OFF")
        end
    end

    local infJumpConn = nil
    local function toggleInfiniteJump(state)
        if state then
            infJumpConn = UserInputService.JumpRequest:Connect(function()
                if LP.Character then
                    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
            addLog("Inf Jump ON")
        else
            if infJumpConn then infJumpConn:Disconnect() infJumpConn = nil end
            addLog("Inf Jump OFF")
        end
    end

    local flyBV, flyBG = nil, nil
    local function startFly()
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        flyBV = Instance.new("BodyVelocity")
        flyBV.Name = "HubFlyBV"; flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.Name = "HubFlyBG"; flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 1000; flyBG.D = 50; flyBG.CFrame = hrp.CFrame; flyBG.Parent = hrp
        addLog("Fly ON")
    end
    local function stopFly()
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        addLog("Fly OFF")
    end
    local function updateFly()
        if not flyOn then return end
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if not flyBV or flyBV.Parent ~= hrp then startFly() end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        if flyBV then flyBV.Velocity = move.Magnitude > 0 and move.Unit * flySpeed or Vector3.zero end
        if flyBG then flyBG.CFrame = Camera.CFrame end
    end

    local function toggleFullBright(state)
        if state then
            pcall(function()
                Lighting.Ambient = Color3.fromRGB(178,178,178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
                Lighting.Brightness = 2; Lighting.ClockTime = 12
                Lighting.GlobalShadows = false; Lighting.FogEnd = 100000
            end)
            addLog("Full Bright ON")
        else
            pcall(function()
                Lighting.Ambient = Color3.fromRGB(0,0,0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
                Lighting.Brightness = 1; Lighting.GlobalShadows = true
            end)
            addLog("Full Bright OFF")
        end
    end

    local fpsDraw, pingDraw, fpsConn = nil, nil, nil
    local function startCounters()
        if fpsCounterOn and not fpsDraw then
            pcall(function()
                fpsDraw = Drawing.new("Text")
                fpsDraw.Size = 16; fpsDraw.Color = Color3.fromRGB(50,220,130)
                fpsDraw.Outline = true; fpsDraw.Position = Vector2.new(15, 15)
            end)
        end
        if pingCounterOn and not pingDraw then
            pcall(function()
                pingDraw = Drawing.new("Text")
                pingDraw.Size = 16; pingDraw.Color = C.accent
                pingDraw.Outline = true; pingDraw.Position = Vector2.new(15, 38)
            end)
        end
        if not fpsConn then
            local frames, lastT = 0, tick()
            fpsConn = RunService.RenderStepped:Connect(function()
                frames = frames + 1
                if tick() - lastT >= 0.5 then
                    local fps = math.floor(frames / (tick() - lastT))
                    if fpsDraw then fpsDraw.Text = "FPS: " .. fps end
                    frames = 0; lastT = tick()
                    if pingDraw then
                        local ok, p = pcall(function()
                            return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
                        end)
                        pingDraw.Text = "Ping: " .. (ok and p or "?") .. " ms"
                    end
                end
                if fpsDraw then fpsDraw.Visible = fpsCounterOn end
                if pingDraw then pingDraw.Visible = pingCounterOn end
            end)
        end
    end

    local antiFlingConn = nil
    local function toggleAntiFling(state)
        if state then
            antiFlingConn = RunService.Heartbeat:Connect(function()
                if LP.Character then
                    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        for _, v in ipairs(hrp:GetChildren()) do
                            if v:IsA("BodyVelocity") and v.Name ~= "HubFlyBV" then v:Destroy() end
                            if v:IsA("BodyAngularVelocity") then v:Destroy() end
                        end
                        if hrp.AssemblyLinearVelocity.Magnitude > 500 then
                            hrp.AssemblyLinearVelocity = Vector3.zero
                        end
                    end
                end
            end)
            addLog("Anti-Fling ON")
        else
            if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn = nil end
            addLog("Anti-Fling OFF")
        end
    end

    local function savePos()
        if LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then savedPosition = hrp.CFrame; addLog("Posicao salva") end
        end
    end
    local function loadPos()
        if savedPosition and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = savedPosition + Vector3.new(0, 2, 0) end
            addLog("Posicao carregada")
        else
            addLog("Nenhuma posicao salva")
        end
    end
    local function resetChar()
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
    local function rejoinServer()
        addLog("Rejoin...")
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
    local function serverHop()
        addLog("Buscando servidores...")
        task.spawn(function()
            local ok, result = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                return HttpService:JSONDecode(game:HttpGet(url))
            end)
            if ok and result and result.data then
                local servers = {}
                for _, s in ipairs(result.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then
                        table.insert(servers, s.id)
                    end
                end
                if #servers > 0 then
                    local chosen = servers[math.random(1, #servers)]
                    addLog("Entrando em servidor novo...")
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen, LP) end)
                else
                    addLog("Nenhum servidor disponivel")
                end
            else
                addLog("Falha ao buscar servidores")
            end
        end)
    end
    local function copyJobId()
        pcall(function()
            setclipboard(game.JobId)
            addLog("Job ID copiado")
        end)
    end
    local function copyPlaceId()
        pcall(function()
            setclipboard(tostring(game.PlaceId))
            addLog("Place ID copiado")
        end)
    end

    -- FREECAM =============================================
    local freecamActive = false
    local freecamPart = nil
    local freecamSpeed = 50
    local freecamYaw, freecamPitch = 0, 0
    local freecamEffects = {}
    local freecamMouseConn = nil
    local freecamGui = nil

    local function spawnFreecamEffect(kind)
        if not freecamPart then return end
        local pos = freecamPart.Position
        local part = Instance.new("Part")
        part.Size = Vector3.new(2,2,2); part.Anchored = true
        part.CanCollide = false; part.Transparency = 1; part.Position = pos
        part.Parent = Workspace
        if kind == "fire" then
            local fire = Instance.new("Fire")
            fire.Heat = 10; fire.Size = 12; fire.Parent = part
            local light = Instance.new("PointLight")
            light.Color = Color3.fromRGB(255,150,50)
            light.Range = 20; light.Brightness = 3; light.Parent = part
        elseif kind == "explosion" then
            local exp = Instance.new("Explosion")
            exp.Position = pos; exp.BlastRadius = 15
            exp.BlastPressure = 500000; exp.DestroyJointRadiusPercent = 0
            exp.Parent = Workspace
            task.wait(0.05); part:Destroy(); return
        elseif kind == "smoke" then
            local smoke = Instance.new("Smoke")
            smoke.Size = 8; smoke.RiseVelocity = 5
            smoke.Color = Color3.fromRGB(100,100,100)
            smoke.Opacity = 0.5; smoke.Parent = part
        elseif kind == "sparkles" then
            local sp = Instance.new("Sparkles")
            sp.SparkleColor = Color3.fromRGB(255,255,100); sp.Parent = part
        elseif kind == "rainbow" then
            local em = Instance.new("ParticleEmitter")
            em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            em.Rate = 100; em.Lifetime = NumberRange.new(1,2)
            em.Speed = NumberRange.new(5,10)
            em.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
            })
            em.Parent = part
        end
        table.insert(freecamEffects, part)
    end
    local function limparEfeitos()
        for _, p in ipairs(freecamEffects) do
            if p and p.Parent then p:Destroy() end
        end
        freecamEffects = {}
    end
    local function createFreecamGui()
        if freecamGui then freecamGui:Destroy() end
        freecamGui = Instance.new("Frame")
        freecamGui.Size = UDim2.new(0, 330, 0, 400)
        freecamGui.Position = UDim2.new(0.5, -165, 1, -410)
        freecamGui.BackgroundColor3 = C.bg
        freecamGui.BackgroundTransparency = 0.1
        freecamGui.BorderSizePixel = 0; freecamGui.Parent = gui
        Instance.new("UICorner", freecamGui).CornerRadius = UDim.new(0, 14)
        local fgStroke = Instance.new("UIStroke")
        fgStroke.Color = C.accent; fgStroke.Thickness = 1.5; fgStroke.Transparency = 0.4
        fgStroke.Parent = freecamGui

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1,0,0,26); title.Position = UDim2.new(0,0,0,6)
        title.Text = "FREECAM  •  mouse = olhar"
        title.Font = Enum.Font.GothamBold; title.TextSize = 12
        title.TextColor3 = C.accent; title.BackgroundTransparency = 1
        title.Parent = freecamGui

        local sz, sp = 45, 6
        local function mk(t, x, y, cb)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, sz, 0, sz); b.Position = UDim2.new(0, x, 0, y)
            b.Text = t; b.Font = Enum.Font.GothamBold; b.TextSize = 14
            b.BackgroundColor3 = C.card; b.TextColor3 = C.text
            b.BorderSizePixel = 0; b.Parent = freecamGui
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            local s = Instance.new("UIStroke")
            s.Color = C.stroke; s.Thickness = 1; s.Parent = b
            b.MouseButton1Click:Connect(cb)
        end
        local gx = 10
        mk("W", gx+sz+sp, 36, function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame + freecamPart.CFrame.LookVector * freecamSpeed end end)
        mk("A", gx, 36+sz+sp, function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame - freecamPart.CFrame.RightVector * freecamSpeed end end)
        mk("S", gx+sz+sp, 36+sz+sp, function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame - freecamPart.CFrame.LookVector * freecamSpeed end end)
        mk("D", gx+2*(sz+sp), 36+sz+sp, function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame + freecamPart.CFrame.RightVector * freecamSpeed end end)
        mk("↑", gx+sz+sp, 36+2*(sz+sp), function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame + Vector3.new(0, freecamSpeed, 0) end end)
        mk("↓", gx+sz+sp, 36+3*(sz+sp), function() if freecamPart then freecamPart.CFrame = freecamPart.CFrame - Vector3.new(0, freecamSpeed, 0) end end)

        local ax = 10 + 3*(sz+sp) + 10
        local function ab(t, y, color, cb)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 165, 0, 30); b.Position = UDim2.new(0, ax, 0, y)
            b.Text = t; b.Font = Enum.Font.GothamBold; b.TextSize = 11
            b.BackgroundColor3 = color; b.TextColor3 = Color3.fromRGB(255,255,255)
            b.BorderSizePixel = 0; b.Parent = freecamGui
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
            b.MouseButton1Click:Connect(cb)
        end
        ab("TP para camera", 36, C.accentSoft, function()
            if freecamPart and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(freecamPart.Position) end
            end
        end)
        ab("Fogo", 72, Color3.fromRGB(200,90,40), function() spawnFreecamEffect("fire") end)
        ab("Explosao", 108, Color3.fromRGB(200,40,40), function() spawnFreecamEffect("explosion") end)
        ab("Fumaca", 144, Color3.fromRGB(100,100,100), function() spawnFreecamEffect("smoke") end)
        ab("Faiscas", 180, Color3.fromRGB(200,180,60), function() spawnFreecamEffect("sparkles") end)
        ab("Arco-iris", 216, Color3.fromRGB(150,50,200), function() spawnFreecamEffect("rainbow") end)
        ab("Limpar Efeitos", 252, Color3.fromRGB(120,40,40), limparEfeitos)
        ab("Sair do Freecam", 288, Color3.fromRGB(80,80,100), function() stopFreecam() end)

        local info = Instance.new("TextLabel")
        info.Size = UDim2.new(1,0,0,20); info.Position = UDim2.new(0,0,1,-24)
        info.Text = "Mouse = olhar  |  WASD = mover"
        info.Font = Enum.Font.Gotham; info.TextSize = 10
        info.TextColor3 = C.textDim; info.BackgroundTransparency = 1
        info.Parent = freecamGui
    end
    function startFreecam()
        if freecamActive then return end
        freecamActive = true
        if not freecamPart then
            freecamPart = Instance.new("Part")
            freecamPart.Size = Vector3.new(0.5,0.5,0.5)
            freecamPart.Anchored = true; freecamPart.CanCollide = false
            freecamPart.Transparency = 1; freecamPart.Parent = Workspace
        end
        freecamPart.CFrame = Camera.CFrame
        local look = Camera.CFrame.LookVector
        freecamYaw = math.atan2(-look.X, -look.Z)
        freecamPitch = math.asin(look.Y)
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            UserInputService.MouseIconEnabled = false
        end)
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.JumpHeight = 0 end
        end
        freecamMouseConn = UserInputService.InputChanged:Connect(function(input)
            if not freecamActive then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                freecamYaw = freecamYaw - input.Delta.X * 0.006
                freecamPitch = math.clamp(freecamPitch - input.Delta.Y * 0.006, -math.rad(89), math.rad(89))
            end
        end)
        createFreecamGui()
        addLog("Freecam ON")
    end
    function stopFreecam()
        if not freecamActive then return end
        freecamActive = false
        if freecamMouseConn then freecamMouseConn:Disconnect() freecamMouseConn = nil end
        pcall(function()
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        end)
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                pcall(function() hum.JumpPower = 50; hum.JumpHeight = 7.2 end)
            end
        end
        Camera.CameraSubject = LP.Character
        Camera.CameraType = Enum.CameraType.Custom
        if freecamGui then freecamGui:Destroy() freecamGui = nil end
        limparEfeitos()
        addLog("Freecam OFF")
    end
    function updateFreecam()
        if not freecamActive or not freecamPart then return end
        local rot = CFrame.fromEulerAnglesYXZ(freecamPitch, freecamYaw, 0)
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0,-1,0) end
        if move.Magnitude > 0 then
            freecamPart.CFrame = freecamPart.CFrame + (rot * move.Unit) * freecamSpeed
        end
        freecamPart.CFrame = CFrame.new(freecamPart.Position) * rot
        Camera.CFrame = freecamPart.CFrame
    end

    -- SPECTATE / TP PLAYER ================================
    local spectateActive, spectateTarget = false, nil
    local function updateSpectate()
        if spectateActive then
            if spectateTarget and spectateTarget.Character and spectateTarget.Character:FindFirstChild("HumanoidRootPart") then
                Camera.CameraSubject = spectateTarget.Character.HumanoidRootPart
                Camera.CameraType = Enum.CameraType.Custom
            else
                spectateActive = false; spectateTarget = nil
                Camera.CameraSubject = LP.Character
            end
        end
    end
    local function teleportToPlayer(plr)
        if plr and plr.Character and LP.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local lpHRP = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and lpHRP then lpHRP.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        end
    end
    local function createPlayerDropdown(parent, y, cb, title)
        local dd = Instance.new("Frame")
        dd.Size = UDim2.new(1,-20,0,200); dd.Position = UDim2.new(0,10,0,y+44)
        dd.BackgroundColor3 = C.bgAlt; dd.BorderSizePixel = 0; dd.Parent = parent
        Instance.new("UICorner", dd).CornerRadius = UDim.new(0, 10)
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1,0,0,32); h.BackgroundColor3 = C.card
        h.BorderSizePixel = 0; h.Parent = dd
        Instance.new("UICorner", h).CornerRadius = UDim.new(0, 10)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,-30,1,0); t.Position = UDim2.new(0,12,0,0)
        t.Text = title; t.Font = Enum.Font.GothamBold; t.TextSize = 11
        t.TextColor3 = C.accent; t.BackgroundTransparency = 1
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = h
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0,24,0,24); close.Position = UDim2.new(1,-28,0,4)
        close.Text = "X"; close.Font = Enum.Font.GothamBold; close.TextSize = 11
        close.BackgroundColor3 = C.danger
        close.TextColor3 = Color3.fromRGB(255,255,255); close.Parent = h
        Instance.new("UICorner", close).CornerRadius = UDim.new(0,6)
        close.MouseButton1Click:Connect(function() dd:Destroy() end)
        local sc = Instance.new("ScrollingFrame")
        sc.Size = UDim2.new(1,0,1,-32); sc.Position = UDim2.new(0,0,0,32)
        sc.BackgroundTransparency = 1
        sc.CanvasSize = UDim2.new(0,0,0,0); sc.ScrollBarThickness = 3
        sc.ScrollBarImageColor3 = C.accent; sc.Parent = dd
        local dy = 5
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP then
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1,-10,0,30); b.Position = UDim2.new(0,5,0,dy)
                b.Text = p.Name; b.Font = Enum.Font.Gotham; b.TextSize = 11
                b.BackgroundColor3 = C.card; b.TextColor3 = C.text
                b.BorderSizePixel = 0; b.Parent = sc
                Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
                b.MouseButton1Click:Connect(function() cb(p); dd:Destroy() end)
                dy = dy + 34
            end
        end
        sc.CanvasSize = UDim2.new(0,0,0,dy+5)
        dd.Size = UDim2.new(1,-20,0,math.min(dy+40,220))
        return dd
    end

    -- TROLL ==============================================
    local trollLoops = {}
    local function pararTroll(id)
        if trollLoops[id] then trollLoops[id]:Disconnect() trollLoops[id] = nil end
    end
    local function pararTodosTrolls()
        for _, c in pairs(trollLoops) do if c then c:Disconnect() end end
        trollLoops = {}
    end
    local function getHRP()
        if not LP.Character then return nil end
        return LP.Character:FindFirstChild("HumanoidRootPart")
    end
    local trollActions = {
        {name="Girar Rapido", cb=function()
            pararTroll("spin")
            trollLoops["spin"] = RunService.Heartbeat:Connect(function(dt)
                local hrp = getHRP()
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt*20, 0) end
            end)
        end},
        {name="Fling (vomitar)", cb=function()
            local hrp = getHRP()
            if hrp then hrp.Velocity = Vector3.new(math.random(-300,300), 500, math.random(-300,300)) end
        end},
        {name="Flutuar", cb=function()
            pararTroll("float")
            trollLoops["float"] = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.Velocity = Vector3.new(0,30,0) end
            end)
        end},
        {name="De cabeca pra baixo", cb=function()
            pararTroll("inv")
            trollLoops["inv"] = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(math.rad(180),0,0) end
            end)
        end},
        {name="Tornado", cb=function()
            pararTroll("tor")
            trollLoops["tor"] = RunService.Heartbeat:Connect(function(dt)
                local hrp = getHRP()
                if hrp then
                    hrp.Velocity = Vector3.new(0,15,0)
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt*40, 0)
                end
            end)
        end},
        {name="Congelar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=0; h.JumpPower=0; pcall(function() h.JumpHeight=0 end) end
        end},
        {name="Descongelar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=16; pcall(function() h.JumpPower=50; h.JumpHeight=7.2 end) end
        end},
        {name="Inflar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value=5; h.BodyWidthScale.Value=5
                h.BodyDepthScale.Value=5; h.HeadScale.Value=3
            end) end
        end},
        {name="Encolher", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value=0.3; h.BodyWidthScale.Value=0.3
                h.BodyDepthScale.Value=0.3; h.HeadScale.Value=0.5
            end) end
        end},
        {name="Resetar tamanho", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value=1; h.BodyWidthScale.Value=1
                h.BodyDepthScale.Value=1; h.HeadScale.Value=1
            end) end
        end},
        {name="TP aleatorio", cb=function()
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(math.random(-500,500), math.random(50,200), math.random(-500,500)) end
        end},
        {name="Explodir", cb=function()
            local hrp = getHRP()
            if hrp then
                local e = Instance.new("Explosion")
                e.Position = hrp.Position; e.BlastRadius = 20
                e.BlastPressure = 500000; e.DestroyJointRadiusPercent = 0
                e.Parent = Workspace
            end
        end},
        {name="Rastro de fogo", cb=function()
            pararTroll("ft")
            trollLoops["ft"] = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then
                    local p = Instance.new("Part")
                    p.Size=Vector3.new(2,2,2); p.Anchored=true
                    p.CanCollide=false; p.Transparency=1; p.Position=hrp.Position
                    p.Parent = Workspace
                    local f = Instance.new("Fire")
                    f.Size=6; f.Heat=5; f.Parent=p
                    task.delay(1.5, function() if p.Parent then p:Destroy() end end)
                end
            end)
        end},
        {name="Cair (ragdoll)", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = true end
        end},
        {name="Levantar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
        end},
        {name="Parar TODOS os trolls", cb=function()
            pararTodosTrolls()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed=16; h.PlatformStand=false; pcall(function() h.JumpPower=50; h.JumpHeight=7.2 end) end
        end}
    }

    -- ============================================================
    -- CONSTRUCAO DAS ABAS
    -- ============================================================
    local y
    -- MIRA (1)
    local f1 = contentFrames[1]; y = 8
    y = addHeader(f1, "Mira Automatica", y)
    addToggle(f1, "aim_lock", "Trava Mira (Aimbot)", y, false, function(v) aimActive = v; updateFOV() end); y = y + 46
    addSlider(f1, "FOV", y, 50, 400, aimFOV, function(v) aimFOV = v; updateFOV() end); y = y + 66
    addSlider(f1, "Suavidade", y, 1, 20, aimSmooth, function(v) aimSmooth = v end); y = y + 66
    y = addHeader(f1, "Aim Assist", y)
    addToggle(f1, "aim_assist", "Aim Assist (suave)", y, false, function(v) aimAssistOn = v end); y = y + 46
    addSlider(f1, "Forca Assist (%)", y, 1, 50, 15, function(v) aimAssistStrength = v / 100 end); y = y + 66
    y = addHeader(f1, "Configuracoes", y)

    local pf = Instance.new("Frame")
    pf.Size = UDim2.new(1,-20,0,40); pf.Position = UDim2.new(0,10,0,y)
    pf.BackgroundColor3 = C.card; pf.BorderSizePixel = 0; pf.Parent = f1
    Instance.new("UICorner", pf).CornerRadius = UDim.new(0, 10)
    local pfs = Instance.new("UIStroke")
    pfs.Color = C.stroke; pfs.Thickness = 1; pfs.Transparency = 0.5; pfs.Parent = pf
    local pl = Instance.new("TextLabel")
    pl.Size = UDim2.new(0.5,0,1,0); pl.Position = UDim2.new(0,12,0,0)
    pl.Text = "Mirar parte"; pl.Font = Enum.Font.Gotham; pl.TextSize = 12
    pl.TextColor3 = C.text; pl.BackgroundTransparency = 1
    pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Parent = pf
    local pb = Instance.new("TextButton")
    pb.Size = UDim2.new(0,90,0,28); pb.Position = UDim2.new(1,-102,0.5,-14)
    pb.Text = aimPart; pb.Font = Enum.Font.GothamBold; pb.TextSize = 11
    pb.BackgroundColor3 = C.bgAlt; pb.TextColor3 = C.accent
    pb.BorderSizePixel = 0; pb.Parent = pf
    Instance.new("UICorner", pb).CornerRadius = UDim.new(0,8)
    pb.MouseButton1Click:Connect(function()
        aimPart = aimPart == "Head" and "HumanoidRootPart" or "Head"
        pb.Text = aimPart
    end)
    y = y + 46
    addToggle(f1, "aim_showfov", "Mostrar FOV", y, showFOV, function(v) showFOV = v; updateFOV() end); y = y + 46
    addColorPicker(f1, "Cor do FOV", y, fovColor, function(c) fovColor = c; updateFOV() end)

    -- ESP (2)
    local f2 = contentFrames[2]; y = 8
    y = addHeader(f2, "ESP", y)
    addToggle(f2, "esp_on", "Ativar ESP", y, false, function(v) espOn = v end); y = y + 46
    addToggle(f2, "esp_box", "Caixa", y, espBox, function(v) espBox = v end); y = y + 46
    addToggle(f2, "esp_name", "Nome", y, espName, function(v) espName = v end); y = y + 46
    addToggle(f2, "esp_dist", "Distancia", y, espDist, function(v) espDist = v end); y = y + 46
    addToggle(f2, "esp_hp", "Vida", y, espHealth, function(v) espHealth = v end); y = y + 46
    addToggle(f2, "esp_skel", "Esqueleto", y, espSkel, function(v) espSkel = v end); y = y + 46
    addToggle(f2, "esp_tracer", "Rastros", y, espTracers, function(v) espTracers = v end); y = y + 46
    addSlider(f2, "Espessura", y, 1, 3, espThick, function(v) espThick = v end); y = y + 66
    y = addHeader(f2, "Cores", y)
    addColorPicker(f2, "Cor inimigo", y, espEnemyColor, function(c) espEnemyColor = c end); y = y + 46
    addColorPicker(f2, "Cor aliado", y, espAllyColor, function(c) espAllyColor = c end); y = y + 46
    addColorPicker(f2, "Cor rastros", y, tracerColor, function(c) tracerColor = c end)

    -- JOGADOR (3)
    local f3 = contentFrames[3]; y = 8
    y = addHeader(f3, "Movimento", y)
    addToggle(f3, "speed_on", "Super Velocidade", y, false, function(v) speedOn = v end); y = y + 46
    addSlider(f3, "Velocidade", y, 16, 200, speedVal, function(v) speedVal = v end); y = y + 66
    addToggle(f3, "noclip_on", "Noclip", y, false, function(v) noclipOn = v end); y = y + 46
    y = addHeader(f3, "Ambiente", y)
    addToggle(f3, "water_walk", "Andar na agua", y, false, function(v) toggleWaterWalk(v) end)

    -- COMBATE (4) - ABa expandida
    local f4 = contentFrames[4]; y = 8
    y = addHeader(f4, "Mira / Disparo", y)
    addToggle(f4, "silent_aim", "Silent Aim", y, false, function(v) silentAim = v; setupSilentAim() end); y = y + 46
    addSlider(f4, "Silent Aim FOV", y, 50, 400, silentAimFOV, function(v) silentAimFOV = v end); y = y + 66
    addToggle(f4, "trigger_bot", "Trigger Bot (auto fire)", y, false, function(v) triggerBotOn = v; updateTriggerBot() end); y = y + 46
    addSlider(f4, "Trigger Delay (ms)", y, 1, 100, 5, function(v) triggerBotDelay = v / 100 end); y = y + 66
    y = addHeader(f4, "Dano / Alcance", y)
    addToggle(f4, "kill_aura", "Kill Aura", y, false, function(v) killAuraOn = v; updateKillAura() end); y = y + 46
    addSlider(f4, "Kill Aura Alcance", y, 5, 50, killAuraRange, function(v) killAuraRange = v end); y = y + 66
    addSlider(f4, "Kill Aura Dano", y, 1, 100, killAuraDmg, function(v) killAuraDmg = v end); y = y + 66
    addToggle(f4, "hitbox", "Hitbox Expander", y, false, function(v) hitboxExpand = v end); y = y + 46
    addSlider(f4, "Hitbox Tamanho (x)", y, 2, 10, 2, function(v) hitboxSize = v end); y = y + 66
    y = addHeader(f4, "Mods de Arma", y)
    addToggle(f4, "wall_bang", "Wall Bang", y, false, function(v)
        wallBangOn = v
        if v then addLog("Wall Bang ON (efeito visual)") else addLog("Wall Bang OFF") end
    end); y = y + 46
    addToggle(f4, "no_recoil", "No Recoil", y, false, function(v)
        noRecoilOn = v
        if v then addLog("No Recoil ON") else addLog("No Recoil OFF") end
    end); y = y + 46
    addToggle(f4, "no_spread", "No Spread", y, false, function(v) noSpreadOn = v; addLog(v and "No Spread ON" or "No Spread OFF") end); y = y + 46
    addToggle(f4, "auto_reload", "Auto Reload", y, false, function(v)
        autoReloadOn = v
        if v then addLog("Auto Reload ON") else addLog("Auto Reload OFF") end
    end); y = y + 46
    addToggle(f4, "inf_ammo", "Infinite Ammo", y, false, function(v) infiniteAmmoOn = v; addLog(v and "Inf Ammo ON" or "Inf Ammo OFF") end); y = y + 46
    addToggle(f4, "rapid_fire", "Rapid Fire", y, false, function(v) rapidFireOn = v; addLog(v and "Rapid Fire ON" or "Rapid Fire OFF") end); y = y + 46
    addToggle(f4, "instant_hit", "Instant Hit", y, false, function(v)
        instantHitOn = v
        if v then addLog("Instant Hit ON") else addLog("Instant Hit OFF") end
    end)

    -- UTIL (5)
    local f5 = contentFrames[5]; y = 8
    y = addHeader(f5, "Camera", y)
    addToggle(f5, "freecam", "Freecam (mouse)", y, false, function(v) if v then startFreecam() else stopFreecam() end end); y = y + 46
    addSlider(f5, "Vel. Freecam", y, 10, 200, freecamSpeed, function(v) freecamSpeed = v end); y = y + 66
    y = addHeader(f5, "Ferramentas", y)
    addButton(f5, "Puxar Tools do Jogo", y, C.accentSoft, function() pcall(puxarTools) end); y = y + 46
    addButton(f5, "Recriar Teleport Tool", y, C.accentSoft, function() pcall(criarToolTeleporte) end); y = y + 46
    y = addHeader(f5, "Jogadores", y)
    local spectateBtn = Instance.new("TextButton")
    spectateBtn.Size = UDim2.new(0.6,-25,0,40); spectateBtn.Position = UDim2.new(0,10,0,y)
    spectateBtn.Text = "Espectar: Nenhum"; spectateBtn.Font = Enum.Font.GothamBold
    spectateBtn.TextSize = 12; spectateBtn.BackgroundColor3 = C.card
    spectateBtn.TextColor3 = C.text; spectateBtn.BorderSizePixel = 0; spectateBtn.Parent = f5
    Instance.new("UICorner", spectateBtn).CornerRadius = UDim.new(0, 10)
    local sbs = Instance.new("UIStroke")
    sbs.Color = C.stroke; sbs.Thickness = 1; sbs.Parent = spectateBtn
    local stopSpec = Instance.new("TextButton")
    stopSpec.Size = UDim2.new(0.3,-15,0,40); stopSpec.Position = UDim2.new(0.7,-15,0,y)
    stopSpec.Text = "Parar"; stopSpec.Font = Enum.Font.GothamBold; stopSpec.TextSize = 11
    stopSpec.BackgroundColor3 = C.danger
    stopSpec.TextColor3 = Color3.fromRGB(255,255,255); stopSpec.BorderSizePixel = 0; stopSpec.Parent = f5
    Instance.new("UICorner", stopSpec).CornerRadius = UDim.new(0, 10)
    local specDrop = nil
    spectateBtn.MouseButton1Click:Connect(function()
        if specDrop then specDrop:Destroy() specDrop = nil return end
        specDrop = createPlayerDropdown(f5, y, function(p)
            spectateTarget = p; spectateActive = true
            spectateBtn.Text = "Espectar: " .. p.Name
        end, "Espectar")
    end)
    stopSpec.MouseButton1Click:Connect(function()
        spectateActive = false; spectateTarget = nil
        spectateBtn.Text = "Espectar: Nenhum"
        Camera.CameraSubject = LP.Character
    end)
    y = y + 46
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(1,-20,0,40); tpBtn.Position = UDim2.new(0,10,0,y)
    tpBtn.Text = "Teleportar para: Nenhum"; tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 12; tpBtn.BackgroundColor3 = C.card
    tpBtn.TextColor3 = C.text; tpBtn.BorderSizePixel = 0; tpBtn.Parent = f5
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 10)
    local tbs = Instance.new("UIStroke")
    tbs.Color = C.stroke; tbs.Thickness = 1; tbs.Parent = tpBtn
    local tpDrop = nil
    tpBtn.MouseButton1Click:Connect(function()
        if tpDrop then tpDrop:Destroy() tpDrop = nil return end
        tpDrop = createPlayerDropdown(f5, y, function(p)
            teleportToPlayer(p); tpBtn.Text = "Teleportar: " .. p.Name
        end, "Teleportar")
    end)

    -- EXTRAS (6)
    local f6 = contentFrames[6]; y = 8
    y = addHeader(f6, "Anti / Auto", y)
    addToggle(f6, "anti_afk", "Anti-AFK", y, false, function(v) antiAfkOn = v; toggleAntiAfk(v) end); y = y + 46
    addToggle(f6, "inf_jump", "Infinite Jump", y, false, function(v) infiniteJumpOn = v; toggleInfiniteJump(v) end); y = y + 46
    addToggle(f6, "fly_on", "Fly", y, false, function(v)
        flyOn = v
        if v then startFly() else stopFly() end
    end); y = y + 46
    addSlider(f6, "Vel. Fly", y, 20, 400, flySpeed, function(v) flySpeed = v end); y = y + 66
    addToggle(f6, "anti_fling", "Anti-Fling", y, false, function(v) antiFlingOn = v; toggleAntiFling(v) end); y = y + 46
    y = addHeader(f6, "Visual", y)
    addToggle(f6, "full_bright", "Full Bright", y, false, function(v) fullBrightOn = v; toggleFullBright(v) end); y = y + 46
    addToggle(f6, "fps_counter", "FPS Counter", y, false, function(v) fpsCounterOn = v; startCounters() end); y = y + 46
    addToggle(f6, "ping_counter", "Ping Counter", y, false, function(v) pingCounterOn = v; startCounters() end); y = y + 46
    y = addHeader(f6, "Posicao", y)
    addButton(f6, "Salvar Posicao", y, C.accentSoft, savePos); y = y + 46
    addButton(f6, "Carregar Posicao", y, C.accentSoft, loadPos); y = y + 46
    y = addHeader(f6, "Servidor", y)
    addButton(f6, "Reset Character", y, C.danger, resetChar); y = y + 46
    addButton(f6, "Rejoin Server", y, C.success, rejoinServer); y = y + 46
    addButton(f6, "Server Hop", y, C.success, serverHop); y = y + 46
    addButton(f6, "Copy Job ID", y, C.cardHover, copyJobId); y = y + 46
    addButton(f6, "Copy Place ID", y, C.cardHover, copyPlaceId)

    -- MUNDO (7)
    local f7 = contentFrames[7]; y = 8
    y = addHeader(f7, "Tempo e Luz", y)
    addToggle(f7, "time_lock", "Travar Hora", y, false, function(v) timeLock = v end); y = y + 46
    addSlider(f7, "Horario", y, 0, 24, timeVal, function(v) timeVal = v end); y = y + 66
    addToggle(f7, "bright_night", "Noite Clara", y, false, function(v) brightNight = v end); y = y + 46
    y = addHeader(f7, "Nevoa", y)
    addToggle(f7, "fog_on", "Nevoa", y, false, function(v) fogOn = v end); y = y + 46
    addToggle(f7, "no_fog", "Sem Nevoa", y, false, function(v) noFog = v end)

    -- SERV (9)
    local f9s = contentFrames[9]; y = 8
    y = addHeader(f9s, "Informacoes do Servidor", y)
    local servInfo = {
        {"Nome do Jogo", (function() local ok, r = pcall(function() return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end); return ok and r or "?" end)()},
        {"ID do Lugar", tostring(game.PlaceId)},
        {"Job ID", game.JobId},
        {"Usuario", _G.loggedUser or "?"},
        {"Ping", (function() local ok, p = pcall(function() return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end); return (ok and p or "?") .. " ms" end)()}
    }
    for _, info in ipairs(servInfo) do
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1,-20,0,42); fr.Position = UDim2.new(0,10,0,y)
        fr.BackgroundColor3 = C.card; fr.BorderSizePixel = 0; fr.Parent = f9s
        Instance.new("UICorner", fr).CornerRadius = UDim.new(0,10)
        local frs = Instance.new("UIStroke")
        frs.Color = C.stroke; frs.Thickness = 1; frs.Transparency = 0.5; frs.Parent = fr
        local l1 = Instance.new("TextLabel")
        l1.Size = UDim2.new(0.4,0,1,0); l1.Position = UDim2.new(0,12,0,0)
        l1.Text = info[1]; l1.Font = Enum.Font.GothamBold
        l1.TextSize = 12; l1.TextColor3 = C.textDim
        l1.BackgroundTransparency = 1
        l1.TextXAlignment = Enum.TextXAlignment.Left; l1.Parent = fr
        local l2 = Instance.new("TextLabel")
        l2.Size = UDim2.new(0.55,0,1,0); l2.Position = UDim2.new(0.42,0,0,0)
        l2.Text = info[2]; l2.Font = Enum.Font.Gotham; l2.TextSize = 12
        l2.TextColor3 = C.text; l2.BackgroundTransparency = 1
        l2.TextXAlignment = Enum.TextXAlignment.Left
        l2.TextTruncate = Enum.TextTruncate.AtEnd; l2.Parent = fr
        y = y + 48
    end

    -- TROLL (11)
    local f11 = contentFrames[11]; y = 8
    y = addHeader(f11, "Animacoes Troll", y)
    for _, act in ipairs(trollActions) do
        local color = C.cardHover
        if act.name:find("Parar") or act.name:find("Congelar") or act.name:find("Cair") then
            color = Color3.fromRGB(140, 50, 60)
        elseif act.name:find("Levantar") or act.name:find("Descongelar") or act.name:find("Resetar") then
            color = Color3.fromRGB(40, 130, 80)
        end
        addButton(f11, act.name, y, color, act.cb); y = y + 46
    end

    -- CONFIG (10)
    local f10 = contentFrames[10]; y = 8
    y = addHeader(f10, "Gerenciamento", y)
    addButton(f10, "Resetar Hub", y, C.warning, function() gui:Destroy(); carregarHub() end); y = y + 46
    addButton(f10, "Sair da Conta", y, C.cardHover, function()
        _G.loggedUser = nil; currentUserStr.Value = ""
        gui:Destroy(); mostrarTelaLogin()
    end); y = y + 46
    y = addHeader(f10, "Fechar", y)
    addButton(f10, "Fechar Menu Todo", y, Color3.fromRGB(140, 60, 60), fecharTudo); y = y + 46
    addButton(f10, "DESTRUIR MENU", y, C.danger, function()
        task.spawn(function()
            task.spawn(function()
                local t0 = tick()
                while tick() - t0 < 3 do
                    Lighting.Ambient = Color3.fromHSV((tick()*0.8)%1, 1, 1)
                    Lighting.OutdoorAmbient = Color3.fromHSV((tick()*0.8)%1, 1, 1)
                    task.wait(0.05)
                end
                Lighting.Ambient = Color3.fromRGB(0,0,0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
            end)
            task.spawn(function()
                for i=1,8 do
                    if not gui.Parent then break end
                    local msg = Instance.new("TextLabel")
                    msg.Size = UDim2.new(0,420,0,44)
                    msg.Position = UDim2.new(0.5,-210, math.random(5,85)/100, 0)
                    msg.Text = "VOCE FOI TROLADO" .. string.rep("!", math.random(1,5))
                    msg.Font = Enum.Font.GothamBlack; msg.TextSize = 26
                    msg.TextColor3 = Color3.fromRGB(math.random(100,255), math.random(100,255), math.random(100,255))
                    msg.BackgroundTransparency = 1; msg.TextStrokeTransparency = 0
                    msg.Parent = gui
                    task.delay(1.5, function() if msg.Parent then msg:Destroy() end end)
                    task.wait(0.3)
                end
            end)
            task.wait(3)
            aimActive=false; espOn=false; speedOn=false; noclipOn=false
            silentAim=false; hitboxExpand=false; timeLock=false
            fogOn=false; brightNight=false; noFog=false; showFOV=false
            flyOn=false; antiAfkOn=false; infiniteJumpOn=false
            fullBrightOn=false; antiFlingOn=false
            fpsCounterOn=false; pingCounterOn=false
            killAuraOn=false; triggerBotOn=false; aimAssistOn=false
            pararTodosTrolls()
            if flyBV then flyBV:Destroy() flyBV=nil end
            if flyBG then flyBG:Destroy() flyBG=nil end
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn=nil end
            if infJumpConn then infJumpConn:Disconnect() infJumpConn=nil end
            if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn=nil end
            if triggerConn then triggerConn:Disconnect() triggerConn=nil end
            if killAuraConn then killAuraConn:Disconnect() killAuraConn=nil end
            if fpsConn then fpsConn:Disconnect() fpsConn=nil end
            if fpsDraw then pcall(function() fpsDraw:Remove() end) fpsDraw=nil end
            if pingDraw then pcall(function() pingDraw:Remove() end) pingDraw=nil end
            if fovCircle then pcall(function() fovCircle:Remove() end) end
            if origFilter then
                if Mouse.TargetFilter and Mouse.TargetFilter:IsA("Folder") then Mouse.TargetFilter:Destroy() end
                Mouse.TargetFilter = origFilter; origFilter = nil
            end
            if freecamActive then pcall(stopFreecam) end
            for _, e in ipairs(waterWalkParts) do
                if e.part and e.part.Parent then e.part.CanCollide = e.orig end
            end
            waterWalkParts = {}
            for part, orig in pairs(hitboxSizes) do
                if part and part.Parent then part.Size = orig end
            end
            hitboxSizes = {}
            for _, objs in pairs(espDrawings) do
                for _, d in pairs(objs) do
                    if d and d.Remove then pcall(function() d:Remove() end) end
                end
            end
            espDrawings = {}
            pcall(function()
                Lighting.ClockTime = 14; Lighting.Brightness = 1
                Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
                Lighting.Ambient = Color3.fromRGB(0,0,0)
                Lighting.FogEnd = 100000; Lighting.GlobalShadows = true
            end)
            if LP.Character then
                local hum = LP.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
            local backpack = LP:FindFirstChildOfClass("Backpack")
            if backpack then
                local t = backpack:FindFirstChild("Teleport Tool")
                if t then t:Destroy() end
            end
            addLog("Menu destruido!")
            task.wait(0.1)
            pcall(function() gui:Destroy() end)
            _addLogHook = nil
        end)
    end)

    -- PERSONALIZAR (12)
    local f12 = contentFrames[12]; y = 8
    y = addHeader(f12, "Atalhos", y)
    addKeybindRow(f12, "menu_toggle", "Abrir / Fechar Menu", y); y = y + 46
    y = addHeader(f12, "Interface", y)
    addToggle(f12, "panel_show", "Mostrar Painel do Jogador", y, true, function(v) panel.Visible = v end); y = y + 46
    addToggle(f12, "hex_show", "Mostrar Botao Hexagono", y, true, function(v) btn.Visible = v end); y = y + 46
    y = addHeader(f12, "Resetar", y)
    addButton(f12, "Resetar Keybinds", y, C.warning, function()
        for id, kb in pairs(keybinds) do
            kb.key = nil
            if kb.btn then
                kb.btn.Text = "—"
                kb.btn.BackgroundColor3 = C.card
            end
        end
        addLog("Keybinds resetadas")
    end)

    -- LOOPS ==============================================
    RunService.Stepped:Connect(function()
        if noclipOn and LP.Character then
            for _, v in pairs(LP.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                if speedOn then hum.WalkSpeed = speedVal
                elseif hum.WalkSpeed ~= 16 and not freecamActive then hum.WalkSpeed = 16 end
            end
        end
    end)

    task.spawn(function()
        while gui.Parent do
            updateHitbox()
            setupSilentAim()
            task.wait(0.2)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not gui.Parent then return end
        pcall(updateAim)
        if aimAssistOn then pcall(updateAimAssist) end
        pcall(updateESP)
        pcall(updateWorld)
        pcall(updateFOV)
        if freecamActive then pcall(updateFreecam) end
        pcall(updateSpectate)
        if flyOn then pcall(updateFly) end
    end)

    btn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    print("Hub carregado! Usuario: " .. (_G.loggedUser or "?"))
end

-- ============================================================
-- VERIFICACAO
-- ============================================================
task.defer(function()
    local u = _G.loggedUser
    if u and accounts[u] then
        print("Login automatico: " .. u)
        carregarHub()
    else
        print("Mostrando tela de login...")
        mostrarTelaLogin()
    end
end)
