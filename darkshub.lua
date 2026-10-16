--[[
    DARK'S HUB PREMIUM - VERSAO FINAL
    Sniper mira antes de atirar + Mapa visual + A* + Rival Bot + tudo integrado
]]

local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local Lighting            = game:GetService("Lighting")
local Workspace           = game:GetService("Workspace")
local CoreGui             = game:GetService("CoreGui")
local HttpService         = game:GetService("HttpService")
local TeleportService     = game:GetService("TeleportService")
local VirtualUser         = game:GetService("VirtualUser")
local Stats               = game:GetService("Stats")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService  = game:GetService("PathfindingService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

print("[Dark's Hub] Iniciando...")

local HAS_DRAWING = pcall(function() return Drawing.new("Square") end)
local HAS_SETCLIPBOARD = pcall(function() return setclipboard end)

local function safeDrawing(kind)
    if not HAS_DRAWING then return nil end
    local ok, obj = pcall(function() return Drawing.new(kind) end)
    if ok then return obj end
    return nil
end
local function safeRemove(obj)
    if not obj then return end
    pcall(function() obj.Visible = false end)
    if obj.Remove then pcall(function() obj:Remove() end) end
end

local C = {
    bg = Color3.fromRGB(14, 16, 24), bgAlt = Color3.fromRGB(20, 23, 34),
    card = Color3.fromRGB(26, 30, 44), cardHover = Color3.fromRGB(34, 40, 58),
    accent = Color3.fromRGB(0, 170, 255), accent2 = Color3.fromRGB(140, 80, 255),
    accentSoft = Color3.fromRGB(0, 120, 200),
    text = Color3.fromRGB(235, 240, 250), textDim = Color3.fromRGB(140, 150, 170),
    success = Color3.fromRGB(50, 200, 130), danger = Color3.fromRGB(220, 70, 90),
    warning = Color3.fromRGB(240, 170, 60), stroke = Color3.fromRGB(45, 55, 80),
}

local ACCOUNTS_KEY = "DarksHub_Accounts"
local CURRENT_USER_KEY = "DarksHub_CurrentUser"

local dataGui = CoreGui:FindFirstChild("DarksHubData")
if not dataGui then
    dataGui = Instance.new("ScreenGui"); dataGui.Name = "DarksHubData"
    dataGui.ResetOnSpawn = false; dataGui.Parent = CoreGui
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
    if _addLogHook then pcall(_addLogHook, msg) end
end

local function mostrarTelaLogin()
    local loginGui = Instance.new("ScreenGui"); loginGui.Name = "LoginGUI"
    loginGui.ResetOnSpawn = false; loginGui.Parent = CoreGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 340)
    frame.Position = UDim2.new(0.5, -190, 0.5, -170)
    frame.BackgroundColor3 = C.bg; frame.Parent = loginGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 18)
    local stroke = Instance.new("UIStroke"); stroke.Color = C.accent
    stroke.Thickness = 1.5; stroke.Transparency = 0.4; stroke.Parent = frame
    local title = Instance.new("TextLabel"); title.Size = UDim2.new(1, 0, 0, 55)
    title.Text = "DARK'S HUB"; title.Font = Enum.Font.GothamBlack
    title.TextSize = 26; title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1; title.Parent = frame
    local sub = Instance.new("TextLabel"); sub.Size = UDim2.new(1, 0, 0, 18)
    sub.Position = UDim2.new(0, 0, 0, 50); sub.Text = "PREMIUM EDITION"
    sub.Font = Enum.Font.GothamBold; sub.TextSize = 10
    sub.TextColor3 = C.accent; sub.BackgroundTransparency = 1; sub.Parent = frame
    local function makeBox(y, ph)
        local b = Instance.new("TextBox"); b.Size = UDim2.new(0.82, 0, 0, 38)
        b.Position = UDim2.new(0.09, 0, y, 0); b.PlaceholderText = ph
        b.Font = Enum.Font.Gotham; b.TextSize = 14
        b.BackgroundColor3 = C.card; b.TextColor3 = C.text
        b.ClearTextOnFocus = false; b.PlaceholderColor3 = C.textDim; b.Parent = frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        return b
    end
    local userBox = makeBox(0.25, "Usuario")
    local passBox = makeBox(0.40, "Senha")
    local confirmBox = makeBox(0.55, "Confirmar senha")
    confirmBox.Visible = false
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(1, 0, 0, 20)
    errorLabel.Position = UDim2.new(0, 0, 0.68, 0)
    errorLabel.Text = ""; errorLabel.Font = Enum.Font.Gotham
    errorLabel.TextSize = 11; errorLabel.TextColor3 = C.danger
    errorLabel.BackgroundTransparency = 1; errorLabel.Visible = false
    errorLabel.Parent = frame
    local loginBtn = Instance.new("TextButton"); loginBtn.Size = UDim2.new(0.36, 0, 0, 42)
    loginBtn.Position = UDim2.new(0.07, 0, 0.8, 0); loginBtn.Text = "ENTRAR"
    loginBtn.Font = Enum.Font.GothamBold; loginBtn.TextSize = 14
    loginBtn.BackgroundColor3 = C.accent; loginBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    loginBtn.Parent = frame; Instance.new("UICorner", loginBtn).CornerRadius = UDim.new(0, 10)
    local createBtn = Instance.new("TextButton"); createBtn.Size = UDim2.new(0.36, 0, 0, 42)
    createBtn.Position = UDim2.new(0.57, 0, 0.8, 0); createBtn.Text = "CRIAR CONTA"
    createBtn.Font = Enum.Font.GothamBold; createBtn.TextSize = 12
    createBtn.BackgroundColor3 = C.card; createBtn.TextColor3 = C.text
    createBtn.Parent = frame; Instance.new("UICorner", createBtn).CornerRadius = UDim.new(0, 10)
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
            errorLabel.Text = "Preencha tudo!"
            errorLabel.TextColor3 = C.danger; errorLabel.Visible = true; return
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

function carregarHub()
    Hub_gui = Instance.new("ScreenGui")
    Hub_gui.Name = "DarksHubPremium"; Hub_gui.ResetOnSpawn = false
    Hub_gui.Parent = CoreGui

    Hub_keybinds = {}; Hub_listening = nil
    function Hub_formatKey(key)
        if not key then return "—" end
        local n = tostring(key):gsub("Enum.KeyCode.", "")
        if #n > 5 then n = n:sub(1, 5) end
        return n
    end
    function Hub_startListening(id, btn)
        if Hub_listening and Hub_listening.btn then
            local ok = Hub_keybinds[Hub_listening.id]
            Hub_listening.btn.Text = ok and Hub_formatKey(ok.key) or "—"
            Hub_listening.btn.BackgroundColor3 = C.card
        end
        Hub_listening = {id = id, btn = btn}; btn.Text = "..."
        btn.BackgroundColor3 = C.warning; addLog("Pressione uma tecla (ESC cancela)")
    end
    UserInputService.InputBegan:Connect(function(input, gpe)
        if Hub_listening then
            if input.KeyCode == Enum.KeyCode.Escape then
                local ok = Hub_keybinds[Hub_listening.id]
                Hub_listening.btn.Text = ok and Hub_formatKey(ok.key) or "—"
                Hub_listening.btn.BackgroundColor3 = C.card
                Hub_listening = nil; return
            end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Hub_keybinds[Hub_listening.id] = Hub_keybinds[Hub_listening.id] or {}
                Hub_keybinds[Hub_listening.id].key = input.KeyCode
                Hub_listening.btn.Text = Hub_formatKey(input.KeyCode)
                Hub_listening.btn.BackgroundColor3 = C.card
                Hub_listening = nil; return
            end
            return
        end
        if gpe then return end
        for _, kb in pairs(Hub_keybinds) do
            if kb.key and kb.key == input.KeyCode and kb.callback then pcall(kb.callback) end
        end
    end)

    Hub_avatarURL = ""
    pcall(function()
        Hub_avatarURL = Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)

    Hub_panel = Instance.new("Frame"); Hub_panel.Size = UDim2.new(0, 210, 0, 62)
    Hub_panel.Position = UDim2.new(0, 10, 1, -72); Hub_panel.BackgroundColor3 = C.bg
    Hub_panel.BackgroundTransparency = 0.1; Hub_panel.BorderSizePixel = 0
    Hub_panel.Parent = Hub_gui
    Instance.new("UICorner", Hub_panel).CornerRadius = UDim.new(0, 14)

    Hub_avatarImg = Instance.new("ImageLabel"); Hub_avatarImg.Size = UDim2.new(0, 46, 0, 46)
    Hub_avatarImg.Position = UDim2.new(0, 8, 0.5, -23); Hub_avatarImg.BackgroundColor3 = C.card
    Hub_avatarImg.BorderSizePixel = 0; Hub_avatarImg.Image = Hub_avatarURL
    Hub_avatarImg.Parent = Hub_panel
    Instance.new("UICorner", Hub_avatarImg).CornerRadius = UDim.new(1, 0)

    Hub_nameLbl = Instance.new("TextLabel"); Hub_nameLbl.Size = UDim2.new(1, -70, 0, 22)
    Hub_nameLbl.Position = UDim2.new(0, 62, 0, 12); Hub_nameLbl.Text = LP.Name
    Hub_nameLbl.Font = Enum.Font.GothamBold; Hub_nameLbl.TextSize = 13
    Hub_nameLbl.TextColor3 = C.text; Hub_nameLbl.BackgroundTransparency = 1
    Hub_nameLbl.TextXAlignment = Enum.TextXAlignment.Left; Hub_nameLbl.Parent = Hub_panel

    Hub_userLbl = Instance.new("TextLabel"); Hub_userLbl.Size = UDim2.new(1, -70, 0, 18)
    Hub_userLbl.Position = UDim2.new(0, 62, 0, 32); Hub_userLbl.Text = "Conta: " .. (_G.loggedUser or "?")
    Hub_userLbl.Font = Enum.Font.Gotham; Hub_userLbl.TextSize = 11
    Hub_userLbl.TextColor3 = C.accent; Hub_userLbl.BackgroundTransparency = 1
    Hub_userLbl.TextXAlignment = Enum.TextXAlignment.Left; Hub_userLbl.Parent = Hub_panel

    Hub_btn = Instance.new("ImageButton"); Hub_btn.Size = UDim2.new(0, 78, 0, 78)
    Hub_btn.Position = UDim2.new(0, 10, 0.5, -39); Hub_btn.BackgroundTransparency = 1
    Hub_btn.ImageTransparency = 1; Hub_btn.Parent = Hub_gui

    Hub_glow = Instance.new("Frame"); Hub_glow.Size = UDim2.new(1, 8, 1, 8)
    Hub_glow.Position = UDim2.new(0, -4, 0, -4); Hub_glow.BackgroundColor3 = C.accent
    Hub_glow.BackgroundTransparency = 0.7; Hub_glow.BorderSizePixel = 0
    Hub_glow.Parent = Hub_btn
    Instance.new("UICorner", Hub_glow).CornerRadius = UDim.new(0, 14)

    Hub_hex = Instance.new("Frame"); Hub_hex.Size = UDim2.new(1, 0, 1, 0)
    Hub_hex.BackgroundColor3 = C.bgAlt; Hub_hex.Parent = Hub_btn
    Instance.new("UICorner", Hub_hex).CornerRadius = UDim.new(0, 14)

    Hub_dText = Instance.new("TextLabel"); Hub_dText.Size = UDim2.new(1, 0, 1, 0)
    Hub_dText.Text = "DK"; Hub_dText.Font = Enum.Font.GothamBlack
    Hub_dText.TextSize = 30; Hub_dText.TextColor3 = Color3.fromRGB(255, 255, 255)
    Hub_dText.BackgroundTransparency = 1; Hub_dText.Parent = Hub_hex

    task.spawn(function()
        while Hub_gui.Parent do
            pcall(function()
                TweenService:Create(Hub_glow, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    BackgroundTransparency = 0.4, Size = UDim2.new(1, 14, 1, 14)
                }):Play()
            end)
            task.wait(1.4)
        end
    end)

    Hub_mainFrame = Instance.new("Frame"); Hub_mainFrame.Size = UDim2.new(0, 780, 0, 590)
    Hub_mainFrame.Position = UDim2.new(0.5, -390, 0.5, -295); Hub_mainFrame.BackgroundColor3 = C.bg
    Hub_mainFrame.Visible = false; Hub_mainFrame.Parent = Hub_gui
    Instance.new("UICorner", Hub_mainFrame).CornerRadius = UDim.new(0, 18)
    local mainStroke = Instance.new("UIStroke"); mainStroke.Color = C.stroke
    mainStroke.Thickness = 1; mainStroke.Parent = Hub_mainFrame

    Hub_titleBar = Instance.new("Frame"); Hub_titleBar.Size = UDim2.new(1, 0, 0, 52)
    Hub_titleBar.BackgroundColor3 = C.bgAlt; Hub_titleBar.Parent = Hub_mainFrame
    Instance.new("UICorner", Hub_titleBar).CornerRadius = UDim.new(0, 18)

    Hub_titleLbl = Instance.new("TextLabel"); Hub_titleLbl.Size = UDim2.new(1, -160, 1, 0)
    Hub_titleLbl.Position = UDim2.new(0, 20, 0, 0); Hub_titleLbl.Text = "DARK'S HUB  •  " .. (_G.loggedUser or "?")
    Hub_titleLbl.Font = Enum.Font.GothamBold; Hub_titleLbl.TextSize = 15
    Hub_titleLbl.TextColor3 = C.text; Hub_titleLbl.BackgroundTransparency = 1
    Hub_titleLbl.TextXAlignment = Enum.TextXAlignment.Left; Hub_titleLbl.Parent = Hub_titleBar

    Hub_accentBar = Instance.new("Frame"); Hub_accentBar.Size = UDim2.new(0, 4, 0, 26)
    Hub_accentBar.Position = UDim2.new(0, 10, 0.5, -13); Hub_accentBar.BackgroundColor3 = C.accent
    Hub_accentBar.BorderSizePixel = 0; Hub_accentBar.Parent = Hub_titleBar
    Instance.new("UICorner", Hub_accentBar).CornerRadius = UDim.new(1, 0)

    Hub_minimizeBtn = Instance.new("TextButton"); Hub_minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    Hub_minimizeBtn.Position = UDim2.new(1, -84, 0, 10); Hub_minimizeBtn.Text = "—"
    Hub_minimizeBtn.Font = Enum.Font.GothamBold; Hub_minimizeBtn.TextSize = 16
    Hub_minimizeBtn.BackgroundColor3 = C.card; Hub_minimizeBtn.TextColor3 = C.text
    Hub_minimizeBtn.Parent = Hub_titleBar
    Instance.new("UICorner", Hub_minimizeBtn).CornerRadius = UDim.new(0, 8)

    Hub_closeBtn = Instance.new("TextButton"); Hub_closeBtn.Size = UDim2.new(0, 32, 0, 32)
    Hub_closeBtn.Position = UDim2.new(1, -46, 0, 10); Hub_closeBtn.Text = "X"
    Hub_closeBtn.Font = Enum.Font.GothamBold; Hub_closeBtn.TextSize = 14
    Hub_closeBtn.BackgroundColor3 = C.danger; Hub_closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Hub_closeBtn.Parent = Hub_titleBar
    Instance.new("UICorner", Hub_closeBtn).CornerRadius = UDim.new(0, 8)

    Hub_reopenBtn = Instance.new("TextButton"); Hub_reopenBtn.Size = UDim2.new(0, 42, 0, 42)
    Hub_reopenBtn.Position = UDim2.new(0, 10, 0, 10); Hub_reopenBtn.Text = "▼"
    Hub_reopenBtn.Font = Enum.Font.GothamBold; Hub_reopenBtn.TextSize = 18
    Hub_reopenBtn.BackgroundColor3 = C.accent; Hub_reopenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Hub_reopenBtn.Visible = false; Hub_reopenBtn.Parent = Hub_gui
    Instance.new("UICorner", Hub_reopenBtn).CornerRadius = UDim.new(0, 12)

    function Hub_fecharTudo()
        Hub_mainFrame.Visible = false; Hub_btn.Visible = false
        Hub_panel.Visible = false; Hub_reopenBtn.Visible = true
    end
    function Hub_reabrirTudo()
        Hub_btn.Visible = true; Hub_panel.Visible = true; Hub_reopenBtn.Visible = false
    end
    Hub_closeBtn.MouseButton1Click:Connect(Hub_fecharTudo)
    Hub_minimizeBtn.MouseButton1Click:Connect(function() Hub_mainFrame.Visible = false end)
    Hub_reopenBtn.MouseButton1Click:Connect(Hub_reabrirTudo)

    Hub_keybinds["menu_toggle"] = Hub_keybinds["menu_toggle"] or {}
    Hub_keybinds["menu_toggle"].callback = function()
        Hub_mainFrame.Visible = not Hub_mainFrame.Visible
        if Hub_mainFrame.Visible then Hub_reabrirTudo() end
    end

    Hub_sidebar = Instance.new("ScrollingFrame"); Hub_sidebar.Size = UDim2.new(0, 150, 1, -60)
    Hub_sidebar.Position = UDim2.new(0, 6, 0, 56); Hub_sidebar.BackgroundColor3 = C.bgAlt
    Hub_sidebar.BorderSizePixel = 0; Hub_sidebar.CanvasSize = UDim2.new(0, 0, 0, 700)
    Hub_sidebar.ScrollBarThickness = 3; Hub_sidebar.ScrollBarImageColor3 = C.accent
    Hub_sidebar.Parent = Hub_mainFrame
    Instance.new("UICorner", Hub_sidebar).CornerRadius = UDim.new(0, 14)

    Hub_tabNames = {
        {"MIRA", "◎"}, {"ESP", "◈"}, {"JOGADOR", "☰"}, {"COMBATE", "✦"},
        {"UTIL", "⚙"}, {"EXTRAS", "✧"}, {"MUNDO", "◐"}, {"LOG", "≡"},
        {"SERV", "⌘"}, {"CONFIG", "☰"}, {"TROLL", "☠"}, {"PERSONALIZAR", "❋"},
    }
    Hub_tabButtons = {}; Hub_contentFrames = {}
    function Hub_switchTab(index)
        for i, f in ipairs(Hub_contentFrames) do f.Visible = (i == index) end
        for i, data in ipairs(Hub_tabButtons) do
            local isActive = (i == index)
            data.btn.BackgroundColor3 = isActive and C.card or C.bgAlt
            data.btn.TextColor3 = isActive and C.text or C.textDim
            data.indicator.BackgroundColor3 = isActive and C.accent or C.bgAlt
            data.icon.TextColor3 = isActive and C.accent or C.textDim
        end
    end
    for i, data in ipairs(Hub_tabNames) do
        local name, icon = data[1], data[2]
        local btnTab = Instance.new("TextButton"); btnTab.Size = UDim2.new(1, -12, 0, 38)
        btnTab.Position = UDim2.new(0, 6, 0, 6 + (i - 1) * 44)
        btnTab.Text = ""; btnTab.BackgroundColor3 = C.bgAlt
        btnTab.BorderSizePixel = 0; btnTab.Parent = Hub_sidebar
        Instance.new("UICorner", btnTab).CornerRadius = UDim.new(0, 10)
        local ind = Instance.new("Frame"); ind.Size = UDim2.new(0, 3, 0, 20)
        ind.Position = UDim2.new(0, 2, 0.5, -10); ind.BackgroundColor3 = C.bgAlt
        ind.BorderSizePixel = 0; ind.Parent = btnTab
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
        local ic = Instance.new("TextLabel"); ic.Size = UDim2.new(0, 24, 1, 0)
        ic.Position = UDim2.new(0, 12, 0, 0); ic.Text = icon
        ic.Font = Enum.Font.GothamBold; ic.TextSize = 15; ic.TextColor3 = C.textDim
        ic.BackgroundTransparency = 1; ic.Parent = btnTab
        local lb = Instance.new("TextLabel"); lb.Size = UDim2.new(1, -42, 1, 0)
        lb.Position = UDim2.new(0, 40, 0, 0); lb.Text = name
        lb.Font = Enum.Font.GothamSemibold; lb.TextSize = 11
        lb.TextColor3 = C.textDim; lb.BackgroundTransparency = 1
        lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = btnTab
        btnTab.MouseButton1Click:Connect(function() Hub_switchTab(i) end)
        btnTab.MouseEnter:Connect(function()
            if Hub_contentFrames[i] and not Hub_contentFrames[i].Visible then
                btnTab.BackgroundColor3 = C.cardHover
            end
        end)
        btnTab.MouseLeave:Connect(function()
            if Hub_contentFrames[i] and not Hub_contentFrames[i].Visible then
                btnTab.BackgroundColor3 = C.bgAlt
            end
        end)
        Hub_tabButtons[i] = {btn = btnTab, indicator = ind, icon = ic, label = lb}
        local frame = Instance.new("ScrollingFrame"); frame.Size = UDim2.new(1, -168, 1, -66)
        frame.Position = UDim2.new(0, 162, 0, 60); frame.BackgroundTransparency = 1
        frame.CanvasSize = UDim2.new(0, 0, 0, 2200); frame.ScrollBarThickness = 3
        frame.ScrollBarImageColor3 = C.accent; frame.BorderSizePixel = 0
        frame.Parent = Hub_mainFrame; frame.Visible = (i == 1)
        Hub_contentFrames[i] = frame
    end
    Hub_switchTab(1)

    function addHeader(parent, text, yPos)
        local h = Instance.new("TextLabel"); h.Size = UDim2.new(1, -20, 0, 26)
        h.Position = UDim2.new(0, 10, 0, yPos); h.Text = string.upper(text)
        h.Font = Enum.Font.GothamBold; h.TextSize = 11; h.TextColor3 = C.accent
        h.BackgroundTransparency = 1; h.TextXAlignment = Enum.TextXAlignment.Left
        h.Parent = parent
        local line = Instance.new("Frame"); line.Size = UDim2.new(1, -20, 0, 1)
        line.Position = UDim2.new(0, 10, 0, yPos + 22); line.BackgroundColor3 = C.stroke
        line.BorderSizePixel = 0; line.BackgroundTransparency = 0.5; line.Parent = parent
        return yPos + 30
    end

    function addToggle(parent, id, text, yPos, def, cb)
        local f = Instance.new("Frame"); f.Size = UDim2.new(1, -20, 0, 40)
        f.Position = UDim2.new(0, 10, 0, yPos); f.BackgroundColor3 = C.card
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -170, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0); lbl.Text = text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = C.text
        lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd; lbl.Parent = f
        local kbBtn = Instance.new("TextButton"); kbBtn.Size = UDim2.new(0, 50, 0, 24)
        kbBtn.Position = UDim2.new(1, -120, 0.5, -12)
        kbBtn.Text = Hub_keybinds[id] and Hub_formatKey(Hub_keybinds[id].key) or "—"
        kbBtn.Font = Enum.Font.GothamBold; kbBtn.TextSize = 10
        kbBtn.BackgroundColor3 = C.bgAlt; kbBtn.TextColor3 = C.textDim
        kbBtn.BorderSizePixel = 0; kbBtn.Parent = f
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 6)
        local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 50, 0, 24)
        b.Position = UDim2.new(1, -62, 0.5, -12); b.Text = ""
        b.BackgroundColor3 = def and C.success or C.bgAlt
        b.BorderSizePixel = 0; b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
        local knob = Instance.new("Frame"); knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = def and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0; knob.Parent = b
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
        local state = def
        local function toggle()
            state = not state
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = state and C.success or C.bgAlt}):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            }):Play()
            pcall(cb, state)
        end
        b.MouseButton1Click:Connect(toggle)
        kbBtn.MouseButton1Click:Connect(function() Hub_startListening(id, kbBtn) end)
        Hub_keybinds[id] = Hub_keybinds[id] or {}
        Hub_keybinds[id].callback = toggle; Hub_keybinds[id].btn = kbBtn
    end

    function addKeybindRow(parent, id, text, yPos, cb)
        local f = Instance.new("Frame"); f.Size = UDim2.new(1, -20, 0, 40)
        f.Position = UDim2.new(0, 10, 0, yPos); f.BackgroundColor3 = C.card
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -110, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0); lbl.Text = text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = C.text
        lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local kbBtn = Instance.new("TextButton"); kbBtn.Size = UDim2.new(0, 80, 0, 28)
        kbBtn.Position = UDim2.new(1, -92, 0.5, -14)
        kbBtn.Text = Hub_keybinds[id] and Hub_formatKey(Hub_keybinds[id].key) or "—"
        kbBtn.Font = Enum.Font.GothamBold; kbBtn.TextSize = 11
        kbBtn.BackgroundColor3 = C.bgAlt; kbBtn.TextColor3 = C.text
        kbBtn.BorderSizePixel = 0; kbBtn.Parent = f
        Instance.new("UICorner", kbBtn).CornerRadius = UDim.new(0, 8)
        Hub_keybinds[id] = Hub_keybinds[id] or {}
        if cb then Hub_keybinds[id].callback = cb end
        Hub_keybinds[id].btn = kbBtn
        kbBtn.MouseButton1Click:Connect(function() Hub_startListening(id, kbBtn) end)
    end

    function addButton(parent, text, yPos, color, cb)
        local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -20, 0, 40)
        b.Position = UDim2.new(0, 10, 0, yPos); b.Text = text
        b.Font = Enum.Font.GothamBold; b.TextSize = 12
        b.BackgroundColor3 = color; b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.BorderSizePixel = 0; b.Parent = parent
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
        if cb then b.MouseButton1Click:Connect(function() pcall(cb) end) end
        return b
    end

    function addSlider(parent, text, yPos, minv, maxv, def, cb)
        local f = Instance.new("Frame"); f.Size = UDim2.new(1, -20, 0, 60)
        f.Position = UDim2.new(0, 10, 0, yPos); f.BackgroundColor3 = C.card
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.7, 0, 0, 22)
        lbl.Position = UDim2.new(0, 12, 0, 6); lbl.Text = text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = C.text
        lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local valLbl = Instance.new("TextLabel"); valLbl.Size = UDim2.new(0, 60, 0, 22)
        valLbl.Position = UDim2.new(1, -140, 0, 6); valLbl.Text = tostring(def)
        valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 12
        valLbl.TextColor3 = C.accent; valLbl.BackgroundTransparency = 1; valLbl.Parent = f
        local barBg = Instance.new("Frame"); barBg.Size = UDim2.new(1, -80, 0, 6)
        barBg.Position = UDim2.new(0, 12, 0, 36); barBg.BackgroundColor3 = C.bgAlt
        barBg.BorderSizePixel = 0; barBg.Parent = f
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
        local barFill = Instance.new("Frame")
        local initScale = (maxv - minv > 0) and ((def - minv) / (maxv - minv)) or 0
        barFill.Size = UDim2.new(initScale, 0, 1, 0); barFill.BackgroundColor3 = C.accent
        barFill.BorderSizePixel = 0; barFill.Parent = barBg
        Instance.new("UICorner", barFill).CornerRadius = UDim.new(1, 0)
        local minus = Instance.new("TextButton"); minus.Size = UDim2.new(0, 26, 0, 26)
        minus.Position = UDim2.new(1, -62, 0.5, -13); minus.Text = "−"
        minus.Font = Enum.Font.GothamBold; minus.TextSize = 16
        minus.BackgroundColor3 = C.bgAlt; minus.TextColor3 = C.text
        minus.BorderSizePixel = 0; minus.Parent = f
        Instance.new("UICorner", minus).CornerRadius = UDim.new(0, 6)
        local plus = Instance.new("TextButton"); plus.Size = UDim2.new(0, 26, 0, 26)
        plus.Position = UDim2.new(1, -32, 0.5, -13); plus.Text = "+"
        plus.Font = Enum.Font.GothamBold; plus.TextSize = 16
        plus.BackgroundColor3 = C.bgAlt; plus.TextColor3 = C.text
        plus.BorderSizePixel = 0; plus.Parent = f
        Instance.new("UICorner", plus).CornerRadius = UDim.new(0, 6)
        local val = def
        local function update()
            valLbl.Text = tostring(val)
            local scale = (maxv - minv > 0) and ((val - minv) / (maxv - minv)) or 0
            TweenService:Create(barFill, TweenInfo.new(0.15), {Size = UDim2.new(scale, 0, 1, 0)}):Play()
            pcall(cb, val)
        end
        minus.MouseButton1Click:Connect(function() val = math.clamp(val - 1, minv, maxv); update() end)
        plus.MouseButton1Click:Connect(function() val = math.clamp(val + 1, minv, maxv); update() end)
        pcall(cb, def)
    end

    function addColorPicker(parent, text, yPos, def, cb)
        local f = Instance.new("Frame"); f.Size = UDim2.new(1, -20, 0, 40)
        f.Position = UDim2.new(0, 10, 0, yPos); f.BackgroundColor3 = C.card
        f.BorderSizePixel = 0; f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Position = UDim2.new(0, 12, 0, 0); lbl.Text = text
        lbl.Font = Enum.Font.Gotham; lbl.TextSize = 12; lbl.TextColor3 = C.text
        lbl.BackgroundTransparency = 1; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Parent = f
        local colorBtn = Instance.new("TextButton"); colorBtn.Size = UDim2.new(0, 50, 0, 26)
        colorBtn.Position = UDim2.new(1, -62, 0.5, -13); colorBtn.Text = ""
        colorBtn.BackgroundColor3 = def; colorBtn.BorderSizePixel = 0; colorBtn.Parent = f
        Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 8)
        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 100, 255),
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255),
            Color3.fromRGB(255, 140, 0), Color3.fromRGB(0, 255, 255),
        }
        local idx = 1
        colorBtn.MouseButton1Click:Connect(function()
            idx = idx % #colors + 1
            colorBtn.BackgroundColor3 = colors[idx]
            pcall(cb, colors[idx])
        end)
        pcall(cb, def)
    end

    do
        local fLog = Hub_contentFrames[8]
        Hub_logScrl = Instance.new("ScrollingFrame"); Hub_logScrl.Size = UDim2.new(1, -20, 1, -20)
        Hub_logScrl.Position = UDim2.new(0, 10, 0, 10); Hub_logScrl.BackgroundColor3 = C.bgAlt
        Hub_logScrl.BorderSizePixel = 0; Hub_logScrl.CanvasSize = UDim2.new(0, 0, 0, 40)
        Hub_logScrl.ScrollBarThickness = 3; Hub_logScrl.ScrollBarImageColor3 = C.accent
        Hub_logScrl.Parent = fLog
        Instance.new("UICorner", Hub_logScrl).CornerRadius = UDim.new(0, 12)
        Hub_logPh = Instance.new("TextLabel"); Hub_logPh.Size = UDim2.new(1, 0, 0, 30)
        Hub_logPh.Position = UDim2.new(0, 0, 0, 10); Hub_logPh.Text = "Nenhum registro..."
        Hub_logPh.Font = Enum.Font.Gotham; Hub_logPh.TextSize = 13
        Hub_logPh.TextColor3 = C.textDim; Hub_logPh.BackgroundTransparency = 1
        Hub_logPh.Parent = Hub_logScrl
        Hub_logsList = {}
        _addLogHook = function(msg)
            local t = os.date("%H:%M:%S")
            table.insert(Hub_logsList, 1, {time = t, text = msg})
            if #Hub_logsList > 80 then table.remove(Hub_logsList) end
            for _, c in ipairs(Hub_logScrl:GetChildren()) do
                if c:IsA("TextLabel") and c ~= Hub_logPh then c:Destroy() end
            end
            local dy = 5
            for _, log in ipairs(Hub_logsList) do
                local line = Instance.new("TextLabel"); line.Size = UDim2.new(1, -20, 0, 26)
                line.Position = UDim2.new(0, 10, 0, dy)
                line.Text = "  [" .. log.time .. "]  " .. log.text
                line.Font = Enum.Font.Gotham; line.TextSize = 11
                line.TextColor3 = C.text; line.BackgroundColor3 = C.card
                line.BorderSizePixel = 0; line.TextXAlignment = Enum.TextXAlignment.Left
                line.TextTruncate = Enum.TextTruncate.AtEnd; line.Parent = Hub_logScrl
                Instance.new("UICorner", line).CornerRadius = UDim.new(0, 6)
                dy = dy + 30
            end
            if dy == 5 then
                Hub_logPh.Visible = true
                Hub_logScrl.CanvasSize = UDim2.new(0, 0, 0, 40)
            else
                Hub_logPh.Visible = false
                Hub_logScrl.CanvasSize = UDim2.new(0, 0, 0, dy + 10)
            end
        end
        addLog("Hub carregado. Usuario: " .. (_G.loggedUser or "?"))
    end

    -- ============================================================
    -- ESTADO
    -- ============================================================
    aimActive = false; aimFOV = 200; aimSmooth = 5; aimPart = "Head"
    showFOV = true; fovColor = Color3.fromRGB(0, 170, 255)
    aimAssistOn = false; aimAssistStrength = 0.15
    triggerBotOn = false; triggerBotDelay = 0.05
    espOn = false; espBox = true; espName = true; espDist = true
    espTracers = false; espThick = 1; espSkel = false; espHealth = true
    espEnemyColor = Color3.fromRGB(255, 0, 0); espAllyColor = Color3.fromRGB(0, 255, 0)
    tracerColor = Color3.fromRGB(255, 255, 255)
    speedOn = false; speedVal = 80; noclipOn = false
    hitboxExpand = false; hitboxSize = 1.5
    timeLock = false; timeVal = 12; fogOn = false; brightNight = false; noFog = false
    killAuraOn = false; killAuraRange = 15; killAuraDmg = 5
    noRecoilOn = false; noSpreadOn = false; infiniteAmmoOn = false; rapidFireOn = false
    antiAfkOn = false; infiniteJumpOn = false; flyOn = false; flySpeed = 80
    fullBrightOn = false; fpsCounterOn = false; pingCounterOn = false; antiFlingOn = false
    savedPosition = nil
    movementOwner = "none"; matchStarted = false

    autoPlayOn = false; autoPlayConn = nil; autoPlayPad = nil; autoPlayPadName = ""
    autoPlayLastCheck = 0; autoPlayCheckInterval = 1
    autoPlayPath = nil; autoPlayWaypoints = {}; autoPlayWaypointIndex = 1; autoPlayLastPathTime = 0

    rivalBotOn = false; rivalBotConn = nil; rivalBotTarget = nil
    rivalBotRange = 300; rivalBotAutoShoot = true; rivalBotFollow = true
    rivalBotAutoJump = true; rivalBotAutoSlide = true; rivalBotAutoSprint = true
    rivalBotSprintActive = false
    rivalBotSlideKey = Enum.KeyCode.C
    rivalBotSlideCooldown = 0.35; rivalBotLastSlide = 0; rivalBotSlideDuration = 0.15
    rivalBotFireDelay = 0.08; rivalBotAimCamera = true; rivalBotForceAim = true
    rivalBotLastPos = nil; rivalBotPath = nil; rivalBotWaypoints = {}
    rivalBotWaypointIndex = 1; rivalBotLastPathTime = 0
    rivalBotStuckTime = 0; rivalBotLastJump = 0

    PATH_RECOMPUTE_INTERVAL = 0.3; WAYPOINT_REACHED_DIST = 2.5
    STUCK_TIMEOUT = 0.35; JUMP_COOLDOWN = 0.35

    dodgeOn = true; dodgeDetectionRange = 300; dodgeChangeInterval = 0.35
    dodgeCurrentDir = 1; dodgeLastChange = 0; dodgeActive = false
    dodgeThreatDir = nil; dodgeLastThreatTime = 0; dodgeThreatHold = 0.6
    dodgeLastProjectileScan = 0; dodgeProjectileScanInterval = 0.05; dodgeBullets = {}

    voidSafetyOn = true; voidCheckDistance = 30
    voidSafeWaypoints = {}; voidLastSafePos = nil
    voidSaveInterval = 0.3; voidLastSaveTime = 0
    voidFallRecovery = true; voidFallTime = 0; voidFallThreshold = 1.5; voidLastGroundTime = 0

    rivalBotShowPath = true
    rivalBotPathColor = Color3.fromRGB(0, 255, 100)
    rivalBotTargetDotColor = Color3.fromRGB(255, 255, 100)
    pathLines = {}; pathWaypointDots = {}; pathTargetDot = nil

    -- SNIPER AIM
    sniperAimEnabled = true
    sniperIsAiming = false
    sniperAimDelay = 0.35
    sniperAimStarted = 0
    sniperLastWeapon = nil
    sniperWeaponKeywords = {
        "sniper", "awp", "scope", "scoped", "mosin", "barrett",
        "intervention", "railgun", "hunting", "kar98", "aw50",
        "dragunov", "svd", "remington", "50cal", "50.cal",
        "l96", "l115", "r700", "m24", "m40", "accuracy",
    }

    -- MAPA
    mapGrid = {}
    mapGridDrawings = {}
    mapCellSize = 5
    mapRadius = 60
    mapScanInterval = 2.5
    mapLastScan = 0
    mapLastOrigin = nil
    mapShowGrid = false
    mapLastDraw = 0
    mapDrawInterval = 0.12
    mapAutoScanRunning = false

    STAIR_COLUMN_HEIGHTS = {0.5, 1.5, 2.5, 3.5, 4.5, 5.5}

    -- ============================================================
    -- SNIPER HELPERS
    -- ============================================================
    function isSniperWeapon(tool)
        if not tool then return false end
        local n = tool.Name:lower()
        for _, kw in ipairs(sniperWeaponKeywords) do
            if n:find(kw, 1, true) then return true end
        end
        for _, d in ipairs(tool:GetDescendants()) do
            local dn = d.Name:lower()
            if dn:find("scope") or dn:find("sniper") or dn:find("zoom") then
                return true
            end
        end
        return false
    end

    function getEquippedWeapon()
        if not LP.Character then return nil end
        return LP.Character:FindFirstChildOfClass("Tool")
    end

    function startSniperAim()
        if sniperIsAiming then return end
        sniperIsAiming = true
        sniperAimStarted = tick()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2,
                1, true, game, 0
            )
        end)
    end

    function stopSniperAim()
        if not sniperIsAiming then return end
        sniperIsAiming = false
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2,
                1, false, game, 0
            )
        end)
    end

    function canShootSniper()
        if not sniperAimEnabled then return true end
        local tool = getEquippedWeapon()
        if not tool then return true end
        if not isSniperWeapon(tool) then
            if sniperIsAiming then stopSniperAim() end
            return true
        end
        if sniperLastWeapon and sniperLastWeapon ~= tool then
            stopSniperAim()
            sniperLastWeapon = tool
        end
        sniperLastWeapon = tool
        if not sniperIsAiming then
            startSniperAim()
            return false
        end
        if tick() - sniperAimStarted >= sniperAimDelay then
            return true
        end
        return false
    end

    -- ============================================================
    -- MAPA FUNCTIONS
    -- ============================================================
    function mapWorldToKey(pos)
        return math.floor(pos.X / mapCellSize) .. "_" .. math.floor(pos.Z / mapCellSize)
    end
    function mapKeyToWorld(key)
        local sx, sz = key:match("(-?%d+)_(-?%d+)")
        if not sx or not sz then return nil, nil end
        return tonumber(sx) * mapCellSize + mapCellSize/2,
               tonumber(sz) * mapCellSize + mapCellSize/2
    end

    function scanMapCell(cx, cz, refY)
        local cell = {
            key = cx .. "_" .. cz, cx = cx, cz = cz,
            hasFloor = false, floorY = nil, floorNormal = nil,
            floorInstance = nil, slope = 0, type = "void",
            walls = {N=false, S=false, E=false, W=false},
            refY = refY,
        }
        local originX = cx * mapCellSize + mapCellSize/2
        local originZ = cz * mapCellSize + mapCellSize/2
        local searchTop = refY + 40
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = {LP.Character}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignore, p.Character) end
        end
        params.FilterDescendantsInstances = ignore
        params.IgnoreWater = true

        local floorHit = Workspace:Raycast(
            Vector3.new(originX, searchTop, originZ),
            Vector3.new(0, -200, 0), params
        )
        if floorHit then
            cell.hasFloor = true
            cell.floorY = floorHit.Position.Y
            cell.floorNormal = floorHit.Normal
            cell.floorInstance = floorHit.Instance
            cell.slope = math.deg(math.acos(math.clamp(floorHit.Normal.Y, -1, 1)))
            if cell.slope > 50 then cell.type = "wall"
            elseif cell.slope > 15 then cell.type = "ramp"
            else cell.type = "floor" end
        end
        if cell.hasFloor and cell.slope < 55 then
            local hits = 0
            for _, h in ipairs(STAIR_COLUMN_HEIGHTS) do
                local probe = Workspace:Raycast(
                    Vector3.new(originX, cell.floorY + h, originZ),
                    Vector3.new(0, 0.3, 0), params
                )
                if probe then hits = hits + 1 end
            end
            if hits >= 3 then cell.type = "stair" end
        end
        local dirs = {
            N = Vector3.new(0, 0, -1), S = Vector3.new(0, 0, 1),
            E = Vector3.new(1, 0, 0), W = Vector3.new(-1, 0, 0),
        }
        local baseY = cell.hasFloor and (cell.floorY + 3) or (refY + 3)
        for dirName, dirVec in pairs(dirs) do
            local hit = Workspace:Raycast(Vector3.new(originX, baseY, originZ),
                dirVec * (mapCellSize * 0.9), params)
            if hit then cell.walls[dirName] = true end
        end
        return cell
    end

    function scanMap()
        if not LP.Character then return nil end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local origin = hrp.Position
        local newGrid = {}
        local steps = math.floor(mapRadius / mapCellSize)
        local cxOrigin = math.floor(origin.X / mapCellSize)
        local czOrigin = math.floor(origin.Z / mapCellSize)
        for dx = -steps, steps do
            for dz = -steps, steps do
                local cx = cxOrigin + dx
                local cz = czOrigin + dz
                local cell = scanMapCell(cx, cz, origin.Y)
                newGrid[cell.key] = cell
            end
        end
        mapGrid = newGrid
        mapLastOrigin = origin
        local counts = {floor=0, ramp=0, stair=0, wall=0, void=0}
        for _, c in pairs(mapGrid) do
            counts[c.type] = (counts[c.type] or 0) + 1
        end
        return counts
    end

    function clearMapDrawings()
        for _, d in pairs(mapGridDrawings) do safeRemove(d) end
        mapGridDrawings = {}
    end

    function drawMapGrid()
        if not HAS_DRAWING then return end
        if not mapShowGrid then
            if next(mapGridDrawings) then clearMapDrawings() end
            return
        end

        local camPos = Camera.CFrame.Position

        for key, cell in pairs(mapGrid) do
            local wx, wz = mapKeyToWorld(key)
            if wx then
                local worldPos = Vector3.new(wx, cell.hasFloor and cell.floorY or cell.refY, wz)
                local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)

                local draw = mapGridDrawings[key]
                if not draw then
                    draw = safeDrawing("Square")
                    if draw then
                        draw.Thickness = 1
                        draw.Filled = true
                        mapGridDrawings[key] = draw
                    end
                end

                if draw then
                    if not onScreen then
                        draw.Visible = false
                    else
                        local dx = worldPos.X - camPos.X
                        local dz = worldPos.Z - camPos.Z
                        local horizDist = math.sqrt(dx*dx + dz*dz)

                        local size = (mapCellSize / math.max(screenPos.Z, 0.1)) * 900
                        size = math.clamp(size, 2, 60)

                        if horizDist > mapRadius + 15 or size < 2 then
                            draw.Visible = false
                        else
                            local baseColor
                            local alpha

                            if cell.type == "floor" then
                                baseColor = Color3.fromRGB(30, 230, 110); alpha = 0.55
                            elseif cell.type == "ramp" then
                                baseColor = Color3.fromRGB(255, 210, 40); alpha = 0.55
                            elseif cell.type == "stair" then
                                baseColor = Color3.fromRGB(170, 110, 255); alpha = 0.55
                            elseif cell.type == "wall" then
                                baseColor = Color3.fromRGB(230, 60, 70); alpha = 0.55
                            else
                                baseColor = Color3.fromRGB(70, 70, 80); alpha = 0.35
                            end

                            local distFactor = math.clamp(1 - (horizDist / (mapRadius + 10)), 0.35, 1)
                            local finalColor = Color3.new(
                                baseColor.R * distFactor,
                                baseColor.G * distFactor,
                                baseColor.B * distFactor
                            )

                            draw.Color = finalColor
                            draw.Transparency = alpha + (1 - distFactor) * 0.3
                            draw.Size = Vector2.new(size, size)
                            draw.Position = Vector2.new(
                                screenPos.X - size / 2,
                                screenPos.Y - size / 2
                            )
                            draw.Visible = true
                        end
                    end
                end
            end
        end
    end

    function startAutoMapScan()
        if mapAutoScanRunning then return end
        mapAutoScanRunning = true
        task.spawn(function()
            addLog("Mapa: scan automatico iniciado")
            while Hub_gui and Hub_gui.Parent do
                if LP.Character then
                    local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local now = tick()
                        if now - mapLastScan >= mapScanInterval then
                            mapLastScan = now
                            local pos = hrp.Position
                            local needRescan = false
                            if not mapLastOrigin then
                                needRescan = true
                            elseif (pos - mapLastOrigin).Magnitude > 12 then
                                needRescan = true
                            end
                            if needRescan then
                                pcall(scanMap)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
            mapAutoScanRunning = false
        end)
    end

    -- ============================================================
    -- A*
    -- ============================================================
    function cellWalkable(cell)
        if not cell then return false end
        return cell.type == "floor" or cell.type == "ramp" or cell.type == "stair"
    end

    function aStar(startCell, goalCell, maxIter)
        maxIter = maxIter or 600
        if not startCell or not goalCell then return nil end
        if startCell.key == goalCell.key then return {startCell} end
        local openSet = {startCell.key}
        local openMap = {[startCell.key] = true}
        local cameFrom = {}
        local gScore = {[startCell.key] = 0}
        local fScore = {[startCell.key] = (startCell.cx - goalCell.cx)^2 + (startCell.cz - goalCell.cz)^2}
        local iterations = 0
        while #openSet > 0 and iterations < maxIter do
            iterations = iterations + 1
            local currentKey = openSet[1]
            local currentF = fScore[currentKey] or math.huge
            local currentIdx = 1
            for i, k in ipairs(openSet) do
                local f = fScore[k] or math.huge
                if f < currentF then currentF = f; currentKey = k; currentIdx = i end
            end
            table.remove(openSet, currentIdx)
            openMap[currentKey] = nil
            if currentKey == goalCell.key then
                local path = {}
                local k = currentKey
                while k do
                    table.insert(path, 1, mapGrid[k])
                    k = cameFrom[k]
                end
                return path
            end
            local current = mapGrid[currentKey]
            if not current then continue end
            local neighbors = {
                {current.cx + 1, current.cz, "E"},
                {current.cx - 1, current.cz, "W"},
                {current.cx, current.cz + 1, "S"},
                {current.cx, current.cz - 1, "N"},
            }
            for _, n in ipairs(neighbors) do
                local nx, nz, dir = n[1], n[2], n[3]
                local nKey = nx .. "_" .. nz
                local nCell = mapGrid[nKey]
                if nCell and cellWalkable(nCell) then
                    local blocked = false
                    if current.walls[dir] then
                        if nCell.type ~= "stair" and nCell.type ~= "ramp" then
                            blocked = true
                        end
                    end
                    if current.hasFloor and nCell.hasFloor then
                        local dy = math.abs(nCell.floorY - current.floorY)
                        if dy > 8 then blocked = true end
                    end
                    if not blocked then
                        local tentative = (gScore[currentKey] or 0) + 1
                        if not gScore[nKey] or tentative < gScore[nKey] then
                            cameFrom[nKey] = currentKey
                            gScore[nKey] = tentative
                            fScore[nKey] = tentative + math.sqrt((nCell.cx - goalCell.cx)^2 + (nCell.cz - goalCell.cz)^2)
                            if not openMap[nKey] then
                                table.insert(openSet, nKey)
                                openMap[nKey] = true
                            end
                        end
                    end
                end
            end
        end
        return nil
    end

    -- ============================================================
    -- HELPERS
    -- ============================================================
    function isTeammate(p) return LP.Team and p.Team and LP.Team == p.Team end

    function hasLineOfSight(fromPos, targetPart)
        local params = RaycastParams.new()
        local ok = pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end)
        if not ok then pcall(function() params.FilterType = Enum.RaycastFilterType.Blacklist end) end
        params.FilterDescendantsInstances = {LP.Character}
        params.IgnoreWater = true
        local dir = targetPart.Position - fromPos
        local result
        pcall(function() result = Workspace:Raycast(fromPos, dir, params) end)
        if not result then return true end
        if result.Instance then
            local hit = result.Instance
            local targetChar = targetPart:FindFirstAncestorOfClass("Model")
            if targetChar and (hit == targetPart or hit:IsDescendantOf(targetChar)) then return true end
        end
        return false
    end

    function isInFront(targetPos, minDot)
        minDot = minDot or 0.3
        local toTarget = (targetPos - Camera.CFrame.Position).Unit
        return Camera.CFrame.LookVector:Dot(toTarget) >= minDot
    end

    function hasGroundBelow(pos, maxDist)
        maxDist = maxDist or voidCheckDistance
        local params = RaycastParams.new()
        local ok = pcall(function() params.FilterType = Enum.RaycastFilterType.Exclude end)
        if not ok then pcall(function() params.FilterType = Enum.RaycastFilterType.Blacklist end) end
        local ignoreList = {LP.Character}
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then table.insert(ignoreList, p.Character) end
        end
        params.FilterDescendantsInstances = ignoreList
        params.IgnoreWater = false
        local result
        pcall(function() result = Workspace:Raycast(pos, Vector3.new(0, -maxDist, 0), params) end)
        if result and result.Instance then return true, result.Position, result.Instance end
        return false, nil, nil
    end

    function isPlayerOnGround()
        local ch = LP.Character
        if not ch then return false end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        return hasGroundBelow(hrp.Position, 15)
    end

    function saveLastSafePos()
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hasGroundBelow(hrp.Position, 15) then voidLastSafePos = hrp.CFrame end
    end

    function recoverFromVoid()
        if not voidLastSafePos then return end
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        pcall(function()
            hrp.CFrame = voidLastSafePos + Vector3.new(0, 3, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
        end)
        addLog("Anti-Void: recuperado!")
        voidFallTime = 0
    end

    function filterSafeWaypoints()
        if not voidSafetyOn then voidSafeWaypoints = rivalBotWaypoints; return end
        voidSafeWaypoints = {}
        for _, wp in ipairs(rivalBotWaypoints) do
            if hasGroundBelow(wp.Position, voidCheckDistance) then
                table.insert(voidSafeWaypoints, wp)
            end
        end
    end

    Hub_START_PAD_KEYWORDS = {"start","begin","play","ready","pad","square","plate","button","spawn","queue","enter","join","arena","match","lobby","waiting","startpad"}
    function isStartPad(obj)
        if not obj:IsA("BasePart") then return false end
        local n = obj.Name:lower()
        for _, kw in ipairs(Hub_START_PAD_KEYWORDS) do
            if n:find(kw, 1, true) then return true end
        end
        return false
    end

    function findStartPad()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == "PadBase1" then
                if obj:IsA("BasePart") then return obj
                elseif obj:IsA("Model") then
                    local part = obj:FindFirstChildWhichIsA("BasePart")
                    if part then return part end
                end
            end
        end
        if autoPlayPadName and autoPlayPadName ~= "" then
            local found = Workspace:FindFirstChild(autoPlayPadName, true)
            if found then
                if found:IsA("BasePart") then return found end
                if found:IsA("Model") then
                    local part = found:FindFirstChildWhichIsA("BasePart")
                    if part then return part end
                end
            end
        end
        local candidates = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isStartPad(obj) then table.insert(candidates, obj) end
        end
        if #candidates == 0 then return nil end
        if not LP.Character then return candidates[1] end
        local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return candidates[1] end
        local myPos = myHRP.Position
        table.sort(candidates, function(a, b)
            return (a.Position - myPos).Magnitude < (b.Position - myPos).Magnitude
        end)
        return candidates[1]
    end

    function detectMatchStart()
        if not autoPlayPad or not autoPlayPad.Parent then return true end
        if autoPlayPad.Transparency >= 0.9 then return true end
        if LP.Character and autoPlayPad then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - autoPlayPad.Position).Magnitude > 200 then return true end
        end
        return false
    end

    function updateAutoPlay()
        if not autoPlayOn then
            if autoPlayConn then autoPlayConn:Disconnect() autoPlayConn = nil end
            return
        end
        if autoPlayConn then return end
        autoPlayConn = RunService.RenderStepped:Connect(function(dt)
            if not autoPlayOn then return end
            if movementOwner == "rivalbot" then return end
            if not LP.Character then return end
            if autoPlayPad then
                if detectMatchStart() then
                    matchStarted = true; autoPlayOn = false
                    autoPlayPad = nil; autoPlayPath = nil; autoPlayWaypoints = {}
                    addLog("Partida iniciada! Auto Play desligado.")
                    return
                end
            end
            local now = tick()
            if not autoPlayPad or not autoPlayPad.Parent then
                if now - autoPlayLastCheck > autoPlayCheckInterval then
                    autoPlayLastCheck = now
                    autoPlayPad = findStartPad()
                    if autoPlayPad then addLog("Quadrado: " .. autoPlayPad:GetFullName()) end
                end
                if not autoPlayPad then return end
            end
            local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
            local myHum = LP.Character:FindFirstChildOfClass("Humanoid")
            if not myHRP or not myHum then return end
            movementOwner = "autoplay"
            local padPos = autoPlayPad.Position
            local myPos = myHRP.Position
            local dist = (padPos - myPos).Magnitude
            if dist < 5 then
                pcall(function() myHum:Move(Vector3.zero, false) end); return
            end
            if now - autoPlayLastPathTime > PATH_RECOMPUTE_INTERVAL or #autoPlayWaypoints == 0 then
                autoPlayLastPathTime = now
                local success, path = pcall(function()
                    local p = PathfindingService:CreatePath({
                        AgentRadius = 2, AgentHeight = 5, AgentCanJump = true,
                        AgentJumpHeight = 10, AgentMaxSlope = 70, WaypointSpacing = 3,
                        Costs = {Water = 20},
                    })
                    p:ComputeAsync(myHRP.Position, padPos); return p
                end)
                if success and path and path.Status == Enum.PathStatus.Success then
                    autoPlayPath = path; autoPlayWaypoints = path:GetWaypoints()
                    autoPlayWaypointIndex = 2
                else autoPlayWaypoints = {} end
            end
            local wp = #autoPlayWaypoints > 0 and autoPlayWaypoints[autoPlayWaypointIndex] or nil
            if wp then
                pcall(function() myHum:MoveTo(wp.Position) end)
                if (wp.Position - myPos).Magnitude < WAYPOINT_REACHED_DIST then
                    autoPlayWaypointIndex = autoPlayWaypointIndex + 1
                end
                if wp.Action == Enum.PathWaypointAction.Jump then
                    pcall(function() myHum.Jump = true end)
                end
            else
                pcall(function() myHum:MoveTo(padPos) end)
            end
        end)
    end

    function getClosestTarget(fov)
        fov = fov or aimFOV
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local bestD, bestT, bestP = fov, nil, nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or isTeammate(p) then continue end
            local ch = p.Character
            if not ch then continue end
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

    function updateAim()
        if not aimActive then return end
        local _, pos = getClosestTarget()
        if pos then
            local cf = CFrame.new(Camera.CFrame.Position, pos)
            Camera.CFrame = aimSmooth <= 1 and cf or Camera.CFrame:Lerp(cf, aimSmooth / 20)
        end
    end

    function updateAimAssist()
        if not aimAssistOn then return end
        local _, pos = getClosestTarget(300)
        if pos then
            local cf = CFrame.new(Camera.CFrame.Position, pos)
            Camera.CFrame = Camera.CFrame:Lerp(cf, aimAssistStrength)
        end
    end

    triggerConn = nil
    function updateTriggerBot()
        if not triggerBotOn then
            if triggerConn then triggerConn:Disconnect() triggerConn = nil end
            return
        end
        if triggerConn then return end
        triggerConn = RunService.Heartbeat:Connect(function()
            if not triggerBotOn then return end
            if not LP.Character then return end
            local myHead = LP.Character:FindFirstChild("Head")
            if not myHead then return end
            local target, targetPos = getClosestTarget(aimFOV)
            if not target or not targetPos then return end
            local targetChar = target.Character
            if not targetChar then return end
            local tPart = targetChar:FindFirstChild(aimPart) or targetChar:FindFirstChild("Head")
            if not tPart then return end
            if not isInFront(targetPos) then return end
            if not hasLineOfSight(myHead.Position, tPart) then return end
            if canShootSniper() then
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 0)
                    task.wait(triggerBotDelay)
                    VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 0)
                end)
            end
            task.wait(triggerBotDelay)
        end)
    end

    function detectThreats()
        local myChar = LP.Character
        if not myChar then return nil end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local myPos = myHRP.Position
        local threat = nil; local threatDist = math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or isTeammate(p) then continue end
            local ch = p.Character
            if not ch then continue end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            local head = ch:FindFirstChild("Head")
            if not hum or not hrp or not head or hum.Health <= 0 then continue end
            local dist = (hrp.Position - myPos).Magnitude
            if dist > dodgeDetectionRange then continue end
            local theirLook = head.CFrame.LookVector
            local toMe = (myPos - head.Position).Unit
            local dot = theirLook:Dot(toMe)
            if dot > 0.85 then
                if hasLineOfSight(head.Position, myHRP) then
                    if dist < threatDist then
                        threatDist = dist
                        threat = {pos = hrp.Position, dir = toMe, source = "player", player = p}
                    end
                end
            end
        end
        local now = tick()
        if now - dodgeLastProjectileScan > dodgeProjectileScanInterval then
            dodgeLastProjectileScan = now
            dodgeBullets = {}
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("BasePart") and obj ~= myHRP then
                    local vel = obj.AssemblyLinearVelocity
                    if vel.Magnitude > 50 then
                        local size = obj.Size
                        if size.X < 5 and size.Y < 5 and size.Z < 5 then
                            local toMe = myPos - obj.Position
                            local dist = toMe.Magnitude
                            if dist < dodgeDetectionRange then
                                local dot = vel.Unit:Dot(toMe.Unit)
                                if dot > 0.8 then
                                    table.insert(dodgeBullets, {pos = obj.Position, vel = vel, dist = dist})
                                end
                            end
                        end
                    end
                end
            end
        end
        for _, b in ipairs(dodgeBullets) do
            if b.dist < threatDist then
                threatDist = b.dist
                threat = {pos = b.pos, dir = (myPos - b.pos).Unit, source = "bullet"}
            end
        end
        return threat
    end

    function computeDodgeDirection()
        if not dodgeOn then dodgeActive = false; return Vector3.zero end
        local myChar = LP.Character
        if not myChar then dodgeActive = false; return Vector3.zero end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then dodgeActive = false; return Vector3.zero end
        local now = tick()
        local threat = detectThreats()
        if threat then
            dodgeThreatDir = threat.dir; dodgeLastThreatTime = now; dodgeActive = true
        else
            if now - dodgeLastThreatTime < dodgeThreatHold then dodgeActive = true
            else dodgeActive = false; return Vector3.zero end
        end
        if now - dodgeLastChange > dodgeChangeInterval then
            dodgeLastChange = now
            dodgeCurrentDir = (math.random() < 0.5) and -1 or 1
        end
        local threatDir = dodgeThreatDir or myHRP.CFrame.LookVector
        local perp = Vector3.new(-threatDir.Z, 0, threatDir.X)
        if perp.Magnitude < 0.01 then perp = myHRP.CFrame.RightVector end
        perp = perp.Unit * dodgeCurrentDir
        return perp
    end

    function getClosestRival()
        if not LP.Character then return nil end
        local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local bestD, bestP = rivalBotRange, nil
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LP or isTeammate(p) then continue end
            local ch = p.Character
            if not ch then continue end
            local hum = ch:FindFirstChildOfClass("Humanoid")
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local d = (hrp.Position - myHRP.Position).Magnitude
                if d < bestD then bestD = d; bestP = p end
            end
        end
        return bestP
    end

    function startSprint()
        if rivalBotSprintActive then return end
        rivalBotSprintActive = true
        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end)
    end

    function stopSprint()
        if not rivalBotSprintActive then return end
        rivalBotSprintActive = false
        pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game) end)
    end

    function pressSlide()
        if not LP.Character then return end
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end)
        task.wait(0.05)
        pcall(function() VirtualInputManager:SendKeyEvent(true, rivalBotSlideKey, false, game) end)
        task.delay(rivalBotSlideDuration, function()
            pcall(function() VirtualInputManager:SendKeyEvent(false, rivalBotSlideKey, false, game) end)
        end)
    end

    -- ============================================================
    -- RIVAL BOT
    -- ============================================================
    function updateRivalBot()
        if not rivalBotOn then
            if rivalBotConn then rivalBotConn:Disconnect() rivalBotConn = nil end
            rivalBotTarget = nil; rivalBotPath = nil
            rivalBotWaypoints = {}; voidSafeWaypoints = {}
            rivalBotWaypointIndex = 1; rivalBotLastPos = nil
            rivalBotStuckTime = 0; dodgeActive = false; voidFallTime = 0
            if movementOwner == "rivalbot" then movementOwner = "none" end
            stopSprint(); stopSniperAim()
            return
        end
        if rivalBotConn then return end

        rivalBotConn = RunService.RenderStepped:Connect(function(dt)
            if not rivalBotOn then return end
            if autoPlayOn and not matchStarted and autoPlayPad and autoPlayPad.Parent then
                if movementOwner == "rivalbot" then movementOwner = "autoplay" end
                stopSprint(); return
            end
            movementOwner = "rivalbot"
            if not LP.Character then return end

            local myHRP = LP.Character:FindFirstChild("HumanoidRootPart")
            local myHead = LP.Character:FindFirstChild("Head")
            local myHum = LP.Character:FindFirstChildOfClass("Humanoid")
            if not myHRP or not myHead or not myHum then return end

            local now = tick()

            if voidSafetyOn and now - voidLastSaveTime > voidSaveInterval then
                voidLastSaveTime = now; saveLastSafePos()
            end

            if voidSafetyOn and voidFallRecovery then
                local vel = myHRP.AssemblyLinearVelocity
                local onGround = isPlayerOnGround()
                if onGround then voidLastGroundTime = now; voidFallTime = 0
                else
                    if vel.Y < -50 then
                        voidFallTime = voidFallTime + dt
                        if voidFallTime > voidFallThreshold then recoverFromVoid() end
                    elseif vel.Y > 0 then voidFallTime = 0 end
                end
            end

            local closest = getClosestRival()
            if closest ~= rivalBotTarget then
                rivalBotTarget = closest; rivalBotPath = nil
                rivalBotWaypoints = {}; voidSafeWaypoints = {}
                rivalBotWaypointIndex = 1; rivalBotLastPos = nil
                rivalBotStuckTime = 0; rivalBotLastPathTime = 0
            end

            local target = rivalBotTarget
            if not target or not target.Character then
                pcall(function() myHum:Move(Vector3.zero, false) end)
                stopSprint(); return
            end
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            if not tHRP then stopSprint(); return end

            if rivalBotForceAim then
                local targetHead = target.Character:FindFirstChild(aimPart)
                                or target.Character:FindFirstChild("Head") or tHRP
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            elseif rivalBotAimCamera then
                local targetHead = target.Character:FindFirstChild(aimPart)
                                or target.Character:FindFirstChild("Head") or tHRP
                local lookAt = CFrame.new(Camera.CFrame.Position, targetHead.Position)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, 0.5)
            end

            local currentPos = tHRP.Position
            local myPos = myHRP.Position
            local dist = (currentPos - myPos).Magnitude
            local heightDiff = currentPos.Y - myPos.Y

            local isStuck = false
            if rivalBotLastPos then
                local moved = (myPos - rivalBotLastPos).Magnitude
                if moved < 0.08 and dist > 3 then
                    rivalBotStuckTime = rivalBotStuckTime + dt
                    if rivalBotStuckTime > STUCK_TIMEOUT then isStuck = true end
                else rivalBotStuckTime = 0 end
            end
            rivalBotLastPos = myPos
            if isStuck then rivalBotLastPathTime = 0 end

            if rivalBotFollow then
                local needNewPath = (now - rivalBotLastPathTime > 0.35)
                                  or (#rivalBotWaypoints == 0)
                                  or (rivalBotWaypointIndex > #rivalBotWaypoints)

                if needNewPath and dist > 3 then
                    rivalBotLastPathTime = now
                    local targetOnGround = hasGroundBelow(currentPos, voidCheckDistance)

                    if not targetOnGround and voidSafetyOn then
                        pcall(function() myHum:Move(Vector3.zero, false) end)
                    else
                        local pathFound = false
                        local settingsList = {
                            {AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentJumpHeight = 10, AgentMaxSlope = 70, WaypointSpacing = 3, Costs = {Water = 20}},
                            {AgentRadius = 1.5, AgentHeight = 4, AgentCanJump = true, AgentJumpHeight = 14, AgentMaxSlope = 80, WaypointSpacing = 2, Costs = {Water = 20}},
                        }
                        for _, settings in ipairs(settingsList) do
                            local success, path = pcall(function()
                                local p = PathfindingService:CreatePath(settings)
                                p:ComputeAsync(myHRP.Position, currentPos); return p
                            end)
                            if success and path and path.Status == Enum.PathStatus.Success then
                                rivalBotPath = path
                                rivalBotWaypoints = path:GetWaypoints()
                                rivalBotWaypointIndex = 2
                                filterSafeWaypoints()
                                pathFound = true; break
                            end
                        end

                        if not pathFound then
                            local startCell = mapGrid[mapWorldToKey(myPos)]
                            local goalCell = mapGrid[mapWorldToKey(currentPos)]
                            if not goalCell then
                                local gcx = math.floor(currentPos.X / mapCellSize)
                                local gcz = math.floor(currentPos.Z / mapCellSize)
                                for dx = -3, 3 do
                                    for dz = -3, 3 do
                                        local alt = mapGrid[(gcx+dx).."_"..(gcz+dz)]
                                        if alt and alt.hasFloor then goalCell = alt; break end
                                    end
                                    if goalCell then break end
                                end
                            end
                            if startCell and goalCell then
                                local aPath = aStar(startCell, goalCell)
                                if aPath and #aPath > 1 then
                                    rivalBotWaypoints = {}
                                    for _, c in ipairs(aPath) do
                                        local wx, wz = mapKeyToWorld(c.key)
                                        if wx then
                                            table.insert(rivalBotWaypoints, {
                                                Position = Vector3.new(wx, (c.floorY or myPos.Y) + 3, wz),
                                                Action = (c.type == "stair") and Enum.PathWaypointAction.Jump or Enum.PathWaypointAction.Walk,
                                            })
                                        end
                                    end
                                    rivalBotWaypointIndex = 2
                                    voidSafeWaypoints = rivalBotWaypoints
                                    pathFound = true
                                end
                            end
                        end

                        if not pathFound then
                            rivalBotWaypoints = {}; voidSafeWaypoints = {}
                        end
                    end
                end

                if #voidSafeWaypoints > 0 then
                    local wp = voidSafeWaypoints[rivalBotWaypointIndex]
                    if wp and (wp.Position - myPos).Magnitude < WAYPOINT_REACHED_DIST then
                        rivalBotWaypointIndex = rivalBotWaypointIndex + 1
                    end
                end
            end

            if rivalBotAutoJump then
                local canJump = (now - rivalBotLastJump) > JUMP_COOLDOWN
                if canJump and heightDiff > 1.5 and dist < 40 then
                    pcall(function() myHum.Jump = true end); rivalBotLastJump = now
                end
                if canJump and isStuck then
                    pcall(function() myHum.Jump = true end)
                    rivalBotLastJump = now; rivalBotStuckTime = 0
                end
                local wp = voidSafeWaypoints[rivalBotWaypointIndex]
                if wp and wp.Action == Enum.PathWaypointAction.Jump and canJump then
                    pcall(function() myHum.Jump = true end); rivalBotLastJump = now
                end
            end

            if rivalBotAutoSlide and not isStuck then
                local baseCd = math.max(rivalBotSlideCooldown, 0.6)
                if dodgeActive then baseCd = baseCd * 0.7 end
                local canSlide = (now - rivalBotLastSlide) > baseCd
                if canSlide and dist > 6 and dist < rivalBotRange and #voidSafeWaypoints > 0 then
                    if not voidSafetyOn or isPlayerOnGround() then
                        pressSlide(); rivalBotLastSlide = now
                    end
                end
            end

            local dodgeDir = computeDodgeDirection()
            local usingPath = #voidSafeWaypoints > 0
            if usingPath then
                local wp = voidSafeWaypoints[rivalBotWaypointIndex]
                if wp then
                    if dodgeActive and dodgeDir.Magnitude > 0.1 then
                        local toWp = wp.Position - myPos
                        local flat = Vector3.new(toWp.X, 0, toWp.Z)
                        if flat.Magnitude > 0.1 then
                            local combined = flat.Unit * 0.7 + dodgeDir * 1.0
                            if combined.Magnitude > 0.1 then
                                local camRel = Camera.CFrame:VectorToObjectSpace(combined.Unit)
                                pcall(function() myHum:Move(Vector3.new(camRel.X, 0, camRel.Z), false) end)
                            end
                        end
                    else
                        pcall(function() myHum:MoveTo(wp.Position) end)
                    end
                    if rivalBotAutoSprint then startSprint() end
                else
                    pcall(function() myHum:Move(Vector3.zero, false) end); stopSprint()
                end
            elseif dist > 3 then
                if dodgeActive and dodgeDir.Magnitude > 0.1 then
                    local toTarget = currentPos - myPos
                    local flat = Vector3.new(toTarget.X, 0, toTarget.Z)
                    if flat.Magnitude > 0.1 then
                        local combined = flat.Unit * 0.7 + dodgeDir * 1.0
                        if combined.Magnitude > 0.1 then
                            local camRel = Camera.CFrame:VectorToObjectSpace(combined.Unit)
                            pcall(function() myHum:Move(Vector3.new(camRel.X, 0, camRel.Z), false) end)
                        end
                    end
                else
                    pcall(function() myHum:MoveTo(currentPos) end)
                end
                if rivalBotAutoSprint then startSprint() end
            else
                pcall(function() myHum:Move(Vector3.zero, false) end); stopSprint()
            end

            if rivalBotAutoShoot then
                local tPart = target.Character:FindFirstChild(aimPart)
                             or target.Character:FindFirstChild("Head") or tHRP
                if isInFront(currentPos, 0.3) then
                    if hasLineOfSight(myHead.Position, tPart) then
                        if canShootSniper() then
                            pcall(function()
                                VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, true, game, 0)
                                task.wait(rivalBotFireDelay)
                                VirtualInputManager:SendMouseButtonEvent(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2, 0, false, game, 0)
                            end)
                        end
                    else
                        if sniperIsAiming then stopSniperAim() end
                    end
                else
                    if sniperIsAiming then stopSniperAim() end
                end
            else
                if sniperIsAiming then stopSniperAim() end
            end
        end)
    end

    function clearPathVisual()
        for _, l in ipairs(pathLines) do safeRemove(l) end
        for _, d in ipairs(pathWaypointDots) do safeRemove(d) end
        if pathTargetDot then safeRemove(pathTargetDot) end
        pathLines = {}; pathWaypointDots = {}; pathTargetDot = nil
    end

    function updatePathVisual()
        if not HAS_DRAWING then return end
        if not rivalBotShowPath or not rivalBotOn then
            if #pathLines > 0 or #pathWaypointDots > 0 or pathTargetDot then clearPathVisual() end
            return
        end
        local target = rivalBotTarget
        if not target or not target.Character then
            if #pathLines > 0 then clearPathVisual() end; return
        end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP then
            if #pathLines > 0 then clearPathVisual() end; return
        end
        local myHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local points = { myHRP.Position }
        local usedWaypoints = voidSafeWaypoints
        if #usedWaypoints == 0 and #rivalBotWaypoints > 0 then usedWaypoints = rivalBotWaypoints end
        for i = rivalBotWaypointIndex, #usedWaypoints do
            table.insert(points, usedWaypoints[i].Position)
        end
        table.insert(points, tHRP.Position)
        for i = 1, #points - 1 do
            if not pathLines[i] then
                pathLines[i] = safeDrawing("Line")
                if pathLines[i] then
                    pathLines[i].Thickness = 2; pathLines[i].Transparency = 0.25
                    pathLines[i].Color = rivalBotPathColor
                end
            end
            local line = pathLines[i]
            if line then
                local p1, on1 = Camera:WorldToViewportPoint(points[i])
                local p2, on2 = Camera:WorldToViewportPoint(points[i + 1])
                if on1 and on2 then
                    line.From = Vector2.new(p1.X, p1.Y); line.To = Vector2.new(p2.X, p2.Y)
                    line.Color = rivalBotPathColor; line.Visible = true
                else line.Visible = false end
            end
        end
        for i = #points, #pathLines do
            if pathLines[i] then pathLines[i].Visible = false end
        end
        for i = 1, #usedWaypoints do
            if not pathWaypointDots[i] then
                pathWaypointDots[i] = safeDrawing("Circle")
                if pathWaypointDots[i] then
                    pathWaypointDots[i].NumSides = 12; pathWaypointDots[i].Filled = true
                    pathWaypointDots[i].Thickness = 1
                end
            end
            local dot = pathWaypointDots[i]
            if dot then
                local pos, on = Camera:WorldToViewportPoint(usedWaypoints[i].Position)
                if on then
                    dot.Position = Vector2.new(pos.X, pos.Y); dot.Radius = 3
                    dot.Color = rivalBotPathColor; dot.Transparency = 0.4; dot.Visible = true
                else dot.Visible = false end
            end
        end
        for i = #usedWaypoints + 1, #pathWaypointDots do
            if pathWaypointDots[i] then pathWaypointDots[i].Visible = false end
        end
        if not pathTargetDot then
            pathTargetDot = safeDrawing("Circle")
            if pathTargetDot then
                pathTargetDot.Filled = true; pathTargetDot.NumSides = 24; pathTargetDot.Thickness = 2
            end
        end
        if pathTargetDot then
            local pos, on = Camera:WorldToViewportPoint(tHRP.Position)
            if on then
                pathTargetDot.Position = Vector2.new(pos.X, pos.Y)
                pathTargetDot.Radius = 8; pathTargetDot.Color = rivalBotTargetDotColor
                pathTargetDot.Transparency = 0.2; pathTargetDot.Visible = true
            else pathTargetDot.Visible = false end
        end
    end

    killAuraConn = nil
    function updateKillAura()
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
                    if (hrp.Position - myHRP.Position).Magnitude <= killAuraRange then
                        pcall(function()
                            local tool = LP.Character:FindFirstChildOfClass("Tool")
                            if tool then tool:Activate() else hum:TakeDamage(killAuraDmg) end
                        end)
                    end
                end
            end
        end)
    end

    hitboxSizes = {}
    function updateHitbox()
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
                if part and part.Parent then pcall(function() part.Size = orig end) end
            end
            hitboxSizes = {}
        end
    end

    function applyWeaponMods()
        if not LP.Character then return end
        local tool = LP.Character:FindFirstChildOfClass("Tool")
        if not tool then return end
        if noSpreadOn or noRecoilOn then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") then
                    local n = v.Name:lower()
                    if n:find("spread") or n:find("recoil") then
                        pcall(function() v.Value = 0 end)
                    end
                end
            end
        end
        if infiniteAmmoOn then
            for _, v in ipairs(tool:GetDescendants()) do
                if v:IsA("NumberValue") then
                    local n = v.Name:lower()
                    if n:find("ammo") or n:find("clip") then
                        pcall(function() v.Value = 999 end)
                    end
                end
            end
        end
    end

    task.spawn(function()
        while Hub_gui.Parent do
            pcall(function()
                if LP.Character then
                    local tool = LP.Character:FindFirstChildOfClass("Tool")
                    if tool and (noRecoilOn or noSpreadOn or infiniteAmmoOn or rapidFireOn) then
                        applyWeaponMods()
                    end
                end
            end)
            task.wait(0.5)
        end
    end)

    espDrawings = {}; allDrawings = {}
    espLastReset = 0; ESP_RESET_INTERVAL = 2
    espLastFrameUpdate = 0; ESP_FRAME_INTERVAL = 0.033
    function createESP(kind)
        local d = safeDrawing(kind)
        if d then table.insert(allDrawings, d) end
        return d
    end
    function resetAllESP()
        for _, d in ipairs(allDrawings) do pcall(function() d.Visible = false end) end
        for _, d in ipairs(allDrawings) do safeRemove(d) end
        allDrawings = {}; espDrawings = {}
    end

    SKELETON_R15 = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
    }
    SKELETON_R6 = {
        {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
        {"Torso","Left Leg"},{"Torso","Right Leg"},
    }
    JOINTS_R15 = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
    JOINTS_R6 = {"Head","Torso","Left Arm","Right Arm","Left Leg","Right Leg"}

    function getHealthColor(health, maxHealth)
        local ratio = math.clamp(health / math.max(maxHealth, 1), 0, 1)
        if ratio > 0.66 then return Color3.fromRGB(0, 220, 90)
        elseif ratio > 0.33 then return Color3.fromRGB(255, 200, 50)
        else return Color3.fromRGB(240, 60, 60) end
    end

    function updateESP()
        if not HAS_DRAWING then return end
        if not espOn then
            if #allDrawings > 0 then resetAllESP() end; return
        end
        local now = tick()
        if now - espLastReset >= ESP_RESET_INTERVAL then
            espLastReset = now; resetAllESP(); espLastFrameUpdate = 0
        end
        if now - espLastFrameUpdate < ESP_FRAME_INTERVAL then return end
        espLastFrameUpdate = now
        local players = Players:GetPlayers()
        local camPos = Camera.CFrame.Position
        local vp = Camera.ViewportSize
        for plr, objs in pairs(espDrawings) do
            if not plr.Parent or not plr.Character then espDrawings[plr] = nil end
        end
        for _, p in ipairs(players) do
            if p == LP then continue end
            local ch = p.Character
            if not ch then espDrawings[p] = nil; continue end
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then espDrawings[p] = nil; continue end
            local head = ch:FindFirstChild("Head") or hrp
            local topPos, topOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.2, 0))
            local botPos, botOn = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            if not topOn or not botOn then
                if espDrawings[p] then
                    local objs = espDrawings[p]
                    for k, v in pairs(objs) do
                        if type(v) == "table" then
                            for _, item in ipairs(v) do if item then pcall(function() item.Visible = false end) end end
                        elseif v then pcall(function() v.Visible = false end) end
                    end
                end
                continue
            end
            espDrawings[p] = espDrawings[p] or {}
            local objs = espDrawings[p]
            local color = isTeammate(p) and espAllyColor or espEnemyColor
            local boxTopY = topPos.Y
            local boxBotY = botPos.Y
            local boxH = math.max(boxBotY - boxTopY, 10)
            local boxW = boxH * 0.55
            local boxX = topPos.X - boxW / 2
            local boxY = boxTopY
            if espBox then
                if not objs.Box then
                    objs.Box = createESP("Square")
                    if objs.Box then objs.Box.Filled = false; objs.Box.Thickness = espThick end
                end
                if objs.Box then
                    objs.Box.Size = Vector2.new(boxW, boxH)
                    objs.Box.Position = Vector2.new(boxX, boxY)
                    objs.Box.Color = color; objs.Box.Transparency = 0.1; objs.Box.Visible = true
                end
            elseif objs.Box then objs.Box.Visible = false end
            if espHealth then
                local barW = 3; local barX = boxX - barW - 3; local barY = boxY
                if not objs.HpBg then
                    objs.HpBg = createESP("Square")
                    if objs.HpBg then objs.HpBg.Filled = true; objs.HpBg.Thickness = 0
                        objs.HpBg.Color = Color3.fromRGB(15,15,15) end
                end
                if objs.HpBg then
                    objs.HpBg.Size = Vector2.new(barW, boxH); objs.HpBg.Position = Vector2.new(barX, barY)
                    objs.HpBg.Transparency = 0.15; objs.HpBg.Visible = true
                end
                local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                local fillH = boxH * ratio
                if not objs.HpFill then
                    objs.HpFill = createESP("Square")
                    if objs.HpFill then objs.HpFill.Filled = true; objs.HpFill.Thickness = 0 end
                end
                if objs.HpFill then
                    objs.HpFill.Size = Vector2.new(barW, fillH)
                    objs.HpFill.Position = Vector2.new(barX, barY + (boxH - fillH))
                    objs.HpFill.Color = getHealthColor(hum.Health, hum.MaxHealth); objs.HpFill.Visible = true
                end
                if not objs.HpText then
                    objs.HpText = createESP("Text")
                    if objs.HpText then
                        objs.HpText.Size = 11; objs.HpText.Center = false; objs.HpText.Outline = true
                        objs.HpText.OutlineColor = Color3.fromRGB(0,0,0)
                    end
                end
                if objs.HpText then
                    objs.HpText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                    objs.HpText.Color = getHealthColor(hum.Health, hum.MaxHealth)
                    objs.HpText.Position = Vector2.new(barX + barW + 3, boxY + boxH - 12)
                    objs.HpText.Visible = true
                end
            else
                if objs.HpBg then objs.HpBg.Visible = false end
                if objs.HpFill then objs.HpFill.Visible = false end
                if objs.HpText then objs.HpText.Visible = false end
            end
            if espName then
                local nameText = p.Name; local nameSize = 13
                local estimatedW = #nameText * 7 + 14
                local bgH = 18; local bgX = topPos.X - estimatedW / 2
                local bgY = boxY - bgH - 5
                if not objs.NameBg then
                    objs.NameBg = createESP("Square")
                    if objs.NameBg then objs.NameBg.Filled = true; objs.NameBg.Thickness = 0 end
                end
                if objs.NameBg then
                    objs.NameBg.Size = Vector2.new(estimatedW, bgH)
                    objs.NameBg.Position = Vector2.new(bgX, bgY)
                    objs.NameBg.Color = Color3.fromRGB(15,15,20)
                    objs.NameBg.Transparency = 0.35; objs.NameBg.Visible = true
                end
                if not objs.Name then
                    objs.Name = createESP("Text")
                    if objs.Name then
                        objs.Name.Size = nameSize; objs.Name.Center = true
                        objs.Name.Outline = true; objs.Name.OutlineColor = Color3.fromRGB(0,0,0)
                    end
                end
                if objs.Name then
                    objs.Name.Text = nameText
                    objs.Name.Color = Color3.fromRGB(255,255,255)
                    objs.Name.Position = Vector2.new(topPos.X, bgY + 2)
                    objs.Name.Visible = true
                end
            else
                if objs.NameBg then objs.NameBg.Visible = false end
                if objs.Name then objs.Name.Visible = false end
            end
            if espDist then
                local dist = (hrp.Position - camPos).Magnitude
                local distText = "[" .. math.floor(dist) .. "m]"
                local distW = #distText * 6 + 10
                local distH = 14; local distX = topPos.X - distW / 2
                local distY = boxY + boxH + 3
                if not objs.DistBg then
                    objs.DistBg = createESP("Square")
                    if objs.DistBg then objs.DistBg.Filled = true; objs.DistBg.Thickness = 0 end
                end
                if objs.DistBg then
                    objs.DistBg.Size = Vector2.new(distW, distH)
                    objs.DistBg.Position = Vector2.new(distX, distY)
                    objs.DistBg.Color = Color3.fromRGB(0,40,15)
                    objs.DistBg.Transparency = 0.4; objs.DistBg.Visible = true
                end
                if not objs.Dist then
                    objs.Dist = createESP("Text")
                    if objs.Dist then
                        objs.Dist.Size = 11; objs.Dist.Center = true
                        objs.Dist.Outline = true; objs.Dist.OutlineColor = Color3.fromRGB(0,0,0)
                    end
                end
                if objs.Dist then
                    objs.Dist.Text = distText
                    objs.Dist.Color = Color3.fromRGB(0,255,100)
                    objs.Dist.Position = Vector2.new(topPos.X, distY + 1)
                    objs.Dist.Visible = true
                end
            else
                if objs.DistBg then objs.DistBg.Visible = false end
                if objs.Dist then objs.Dist.Visible = false end
            end
            if espTracers then
                if not objs.Tracer then
                    objs.Tracer = createESP("Line")
                    if objs.Tracer then objs.Tracer.Thickness = 1 end
                end
                if objs.Tracer then
                    objs.Tracer.From = Vector2.new(vp.X/2, vp.Y)
                    objs.Tracer.To = Vector2.new(topPos.X, boxY + boxH)
                    objs.Tracer.Color = color; objs.Tracer.Visible = true
                end
            elseif objs.Tracer then objs.Tracer.Visible = false end
            if espSkel then
                local isR15 = ch:FindFirstChild("UpperTorso") ~= nil
                local bones = isR15 and SKELETON_R15 or SKELETON_R6
                local joints = isR15 and JOINTS_R15 or JOINTS_R6
                if not objs.SkelOutline then objs.SkelOutline = {} end
                if not objs.SkelCore then objs.SkelCore = {} end
                if not objs.SkelJoints then objs.SkelJoints = {} end
                local outlineColor = Color3.fromRGB(0,0,0)
                for i, bonePair in ipairs(bones) do
                    local partA = ch:FindFirstChild(bonePair[1])
                    local partB = ch:FindFirstChild(bonePair[2])
                    if not objs.SkelOutline[i] then
                        objs.SkelOutline[i] = createESP("Line")
                        if objs.SkelOutline[i] then
                            objs.SkelOutline[i].Thickness = 3; objs.SkelOutline[i].Color = outlineColor
                        end
                    end
                    if not objs.SkelCore[i] then
                        objs.SkelCore[i] = createESP("Line")
                        if objs.SkelCore[i] then objs.SkelCore[i].Thickness = 1 end
                    end
                    local outline = objs.SkelOutline[i]; local core = objs.SkelCore[i]
                    if partA and partB then
                        local posA, onA = Camera:WorldToViewportPoint(partA.Position)
                        local posB, onB = Camera:WorldToViewportPoint(partB.Position)
                        if onA and onB then
                            local vA = Vector2.new(posA.X, posA.Y); local vB = Vector2.new(posB.X, posB.Y)
                            if outline then outline.From = vA; outline.To = vB; outline.Visible = true end
                            if core then core.From = vA; core.To = vB; core.Color = color; core.Visible = true end
                        else
                            if outline then outline.Visible = false end
                            if core then core.Visible = false end
                        end
                    else
                        if outline then outline.Visible = false end
                        if core then core.Visible = false end
                    end
                end
                for i, jointName in ipairs(joints) do
                    local part = ch:FindFirstChild(jointName)
                    if not objs.SkelJoints[i] then
                        objs.SkelJoints[i] = createESP("Circle")
                        if objs.SkelJoints[i] then
                            objs.SkelJoints[i].NumSides = 6; objs.SkelJoints[i].Filled = true
                            objs.SkelJoints[i].Thickness = 1
                        end
                    end
                    local hex = objs.SkelJoints[i]
                    if hex then
                        if part then
                            local pos, on = Camera:WorldToViewportPoint(part.Position)
                            if on then
                                local radius = math.clamp(140 / pos.Z, 2, 5)
                                hex.Position = Vector2.new(pos.X, pos.Y); hex.Radius = radius
                                hex.Color = color; hex.Transparency = 1; hex.Visible = true
                            else hex.Visible = false end
                        else hex.Visible = false end
                    end
                end
            else
                if objs.SkelOutline then
                    for _, l in ipairs(objs.SkelOutline) do if l then l.Visible = false end end
                end
                if objs.SkelCore then
                    for _, l in ipairs(objs.SkelCore) do if l then l.Visible = false end end
                end
                if objs.SkelJoints then
                    for _, c in ipairs(objs.SkelJoints) do if c then c.Visible = false end end
                end
            end
        end
    end

    fovCircle = nil
    function updateFOV()
        if not HAS_DRAWING then return end
        if not showFOV or not aimActive then
            if fovCircle then fovCircle.Visible = false end; return
        end
        if not fovCircle then fovCircle = safeDrawing("Circle") end
        if fovCircle then
            fovCircle.Thickness = 2; fovCircle.Filled = false; fovCircle.NumSides = 64
            fovCircle.Transparency = 0.6
            fovCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            fovCircle.Radius = aimFOV; fovCircle.Color = fovColor; fovCircle.Visible = true
        end
    end

    function updateWorld()
        if timeLock then Lighting.ClockTime = timeVal end
        if fogOn then Lighting.FogEnd = 500
        elseif not noFog then Lighting.FogEnd = 100000 end
        if noFog then Lighting.FogEnd = 0 end
        if brightNight then
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        elseif not fullBrightOn then
            Lighting.Brightness = 1
            Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
        end
    end

    antiAfkConn = nil
    function toggleAntiAfk(state)
        if state then
            antiAfkConn = LP.Idled:Connect(function()
                pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
            end)
            addLog("Anti-AFK ON")
        else
            if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
            addLog("Anti-AFK OFF")
        end
    end

    infJumpConn = nil
    function toggleInfiniteJump(state)
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

    flyBV = nil; flyBG = nil
    function startFly()
        if not LP.Character then return end
        local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        flyBV = Instance.new("BodyVelocity"); flyBV.Name = "HubFlyBV"
        flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBV.Velocity = Vector3.zero; flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro"); flyBG.Name = "HubFlyBG"
        flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBG.P = 1000; flyBG.D = 50; flyBG.CFrame = hrp.CFrame
        flyBG.Parent = hrp
        addLog("Fly ON")
    end
    function stopFly()
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
        addLog("Fly OFF")
    end
    function updateFly()
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

    function toggleFullBright(state)
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

    fpsDraw = nil; pingDraw = nil; fpsConn = nil
    function startCounters()
        if fpsCounterOn and not fpsDraw and HAS_DRAWING then
            fpsDraw = safeDrawing("Text")
            if fpsDraw then
                fpsDraw.Size = 16; fpsDraw.Color = Color3.fromRGB(50,220,130)
                fpsDraw.Outline = true; fpsDraw.Position = Vector2.new(15,15)
            end
        end
        if pingCounterOn and not pingDraw and HAS_DRAWING then
            pingDraw = safeDrawing("Text")
            if pingDraw then
                pingDraw.Size = 16; pingDraw.Color = C.accent
                pingDraw.Outline = true; pingDraw.Position = Vector2.new(15,38)
            end
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
                            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                        end)
                        pingDraw.Text = "Ping: " .. (ok and p or "?") .. " ms"
                    end
                end
                if fpsDraw then fpsDraw.Visible = fpsCounterOn end
                if pingDraw then pingDraw.Visible = pingCounterOn end
            end)
        end
    end

    antiFlingConn = nil
    function toggleAntiFling(state)
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

    waterWalkParts = {}
    function toggleWaterWalk(state)
        if state then
            waterWalkParts = {}; local found = 0
            for _, part in ipairs(Workspace:GetChildren()) do
                if part:IsA("BasePart") and part.Name:lower():find("water") then
                    table.insert(waterWalkParts, {part = part, orig = part.CanCollide})
                    part.CanCollide = true; found = found + 1
                end
            end
            addLog(found > 0 and ("Agua ON (" .. found .. ")") or "Nenhuma agua")
        else
            for _, e in ipairs(waterWalkParts) do
                if e.part and e.part.Parent then pcall(function() e.part.CanCollide = e.orig end) end
            end
            waterWalkParts = {}; addLog("Agua OFF")
        end
    end

    function puxarTools()
        local count = 0
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj:IsA("Tool") then
                pcall(function() if LP.Backpack then obj.Parent = LP.Backpack end end)
                count = count + 1
            end
        end
        addLog("Puxadas " .. count .. " tools")
    end

    function criarToolTeleporte()
        local backpack = LP:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        local old = backpack:FindFirstChild("Teleport Tool")
        if old then old:Destroy() end
        local tool = Instance.new("Tool"); tool.Name = "Teleport Tool"
        tool.RequiresHandle = false; tool.CanBeDropped = false
        tool.Activated:Connect(function()
            local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
            local ray = Ray.new(unitRay.Origin, unitRay.Direction * 2000)
            local _, pos = Workspace:FindPartOnRay(ray, LP.Character)
            if pos and LP.Character then
                local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
            end
        end)
        tool.Parent = backpack
    end
    task.spawn(function() task.wait(0.5); pcall(criarToolTeleporte) end)
    LP.CharacterAdded:Connect(function() task.wait(1.5); pcall(criarToolTeleporte) end)

    function savePos()
        if LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then savedPosition = hrp.CFrame; addLog("Posicao salva") end
        end
    end
    function loadPos()
        if savedPosition and LP.Character then
            local hrp = LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = savedPosition + Vector3.new(0,2,0) end
            addLog("Posicao carregada")
        else addLog("Nenhuma posicao salva") end
    end
    function resetChar()
        if LP.Character then
            local hum = LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
    function rejoinServer()
        addLog("Rejoin...")
        pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
    end
    function copyJobId()
        if HAS_SETCLIPBOARD then
            pcall(function() setclipboard(game.JobId) end)
            addLog("Job ID copiado")
        end
    end
    function copyPlaceId()
        if HAS_SETCLIPBOARD then
            pcall(function() setclipboard(tostring(game.PlaceId)) end)
            addLog("Place ID copiado")
        end
    end

    trollLoops = {}
    function pararTodosTrolls()
        for _, c in pairs(trollLoops) do if c then c:Disconnect() end end
        trollLoops = {}
    end
    function getHRP()
        if not LP.Character then return nil end
        return LP.Character:FindFirstChild("HumanoidRootPart")
    end
    trollActions = {
        {name="Girar Rapido", cb=function()
            if trollLoops.spin then trollLoops.spin:Disconnect() end
            trollLoops.spin = RunService.Heartbeat:Connect(function(dt)
                local hrp = getHRP()
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, dt * 20, 0) end
            end)
        end},
        {name="Flutuar", cb=function()
            if trollLoops.float then trollLoops.float:Disconnect() end
            trollLoops.float = RunService.Heartbeat:Connect(function()
                local hrp = getHRP()
                if hrp then hrp.Velocity = Vector3.new(0, 30, 0) end
            end)
        end},
        {name="Congelar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 0; h.JumpPower = 0 end
        end},
        {name="Descongelar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16; h.JumpPower = 50 end
        end},
        {name="Inflar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value = 5; h.BodyWidthScale.Value = 5
                h.BodyDepthScale.Value = 5; h.HeadScale.Value = 3
            end) end
        end},
        {name="Encolher", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value = 0.3; h.BodyWidthScale.Value = 0.3
                h.BodyDepthScale.Value = 0.3; h.HeadScale.Value = 0.5
            end) end
        end},
        {name="Resetar tamanho", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then pcall(function()
                h.BodyHeightScale.Value = 1; h.BodyWidthScale.Value = 1
                h.BodyDepthScale.Value = 1; h.HeadScale.Value = 1
            end) end
        end},
        {name="TP aleatorio", cb=function()
            local hrp = getHRP()
            if hrp then hrp.CFrame = CFrame.new(math.random(-500,500), math.random(50,200), math.random(-500,500)) end
        end},
        {name="Explodir", cb=function()
            local hrp = getHRP()
            if hrp then
                local e = Instance.new("Explosion"); e.Position = hrp.Position
                e.BlastRadius = 20; e.BlastPressure = 500000
                e.DestroyJointRadiusPercent = 0; e.Parent = Workspace
            end
        end},
        {name="Cair (ragdoll)", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = true end
        end},
        {name="Levantar", cb=function()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.PlatformStand = false end
        end},
        {name="Parar TODOS", cb=function()
            pararTodosTrolls()
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 16; h.PlatformStand = false; h.JumpPower = 50 end
        end},
    }

    local y

    -- MIRA
    do
        local f1 = Hub_contentFrames[1]; y = 8
        y = addHeader(f1, "Mira Automatica", y)
        addToggle(f1, "aim_lock", "Trava Mira (Aimbot)", y, false, function(v) aimActive = v; updateFOV() end); y = y + 46
        addSlider(f1, "FOV", y, 50, 400, aimFOV, function(v) aimFOV = v; updateFOV() end); y = y + 66
        addSlider(f1, "Suavidade", y, 1, 20, aimSmooth, function(v) aimSmooth = v end); y = y + 66
        y = addHeader(f1, "Aim Assist", y)
        addToggle(f1, "aim_assist", "Aim Assist", y, false, function(v) aimAssistOn = v end); y = y + 46
        addSlider(f1, "Forca (%)", y, 1, 50, 15, function(v) aimAssistStrength = v / 100 end); y = y + 66
        y = addHeader(f1, "Configuracoes", y)
        local pf = Instance.new("Frame"); pf.Size = UDim2.new(1,-20,0,40)
        pf.Position = UDim2.new(0,10,0,y); pf.BackgroundColor3 = C.card
        pf.BorderSizePixel = 0; pf.Parent = f1
        Instance.new("UICorner", pf).CornerRadius = UDim.new(0,10)
        local pl = Instance.new("TextLabel"); pl.Size = UDim2.new(0.5,0,1,0)
        pl.Position = UDim2.new(0,12,0,0); pl.Text = "Mirar parte"
        pl.Font = Enum.Font.Gotham; pl.TextSize = 12; pl.TextColor3 = C.text
        pl.BackgroundTransparency = 1; pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Parent = pf
        local pb = Instance.new("TextButton"); pb.Size = UDim2.new(0,90,0,28)
        pb.Position = UDim2.new(1,-102,0.5,-14); pb.Text = aimPart
        pb.Font = Enum.Font.GothamBold; pb.TextSize = 11
        pb.BackgroundColor3 = C.bgAlt; pb.TextColor3 = C.accent
        pb.BorderSizePixel = 0; pb.Parent = pf
        Instance.new("UICorner", pb).CornerRadius = UDim.new(0,8)
        pb.MouseButton1Click:Connect(function()
            aimPart = aimPart == "Head" and "HumanoidRootPart" or "Head"; pb.Text = aimPart
        end)
        y = y + 46
        addToggle(f1, "aim_showfov", "Mostrar FOV", y, showFOV, function(v) showFOV = v; updateFOV() end); y = y + 46
        addColorPicker(f1, "Cor do FOV", y, fovColor, function(c) fovColor = c; updateFOV() end)
    end

    -- ESP
    do
        local f2 = Hub_contentFrames[2]; y = 8
        y = addHeader(f2, "ESP Jogadores", y)
        addToggle(f2, "esp_on", "Ativar ESP", y, false, function(v) espOn = v end); y = y + 46
        addToggle(f2, "esp_box", "Caixa", y, espBox, function(v) espBox = v end); y = y + 46
        addToggle(f2, "esp_name", "Nome", y, espName, function(v) espName = v end); y = y + 46
        addToggle(f2, "esp_dist", "Distancia", y, espDist, function(v) espDist = v end); y = y + 46
        addToggle(f2, "esp_hp", "Barra de Vida", y, espHealth, function(v) espHealth = v end); y = y + 46
        addToggle(f2, "esp_skel", "Esqueleto", y, espSkel, function(v) espSkel = v end); y = y + 46
        addToggle(f2, "esp_tracer", "Rastros", y, espTracers, function(v) espTracers = v end); y = y + 46
        addSlider(f2, "Espessura", y, 1, 3, espThick, function(v) espThick = v end); y = y + 66
        y = addHeader(f2, "Cores", y)
        addColorPicker(f2, "Cor inimigo", y, espEnemyColor, function(c) espEnemyColor = c end); y = y + 46
        addColorPicker(f2, "Cor aliado", y, espAllyColor, function(c) espAllyColor = c end)
    end

    -- JOGADOR
    do
        local f3 = Hub_contentFrames[3]; y = 8
        y = addHeader(f3, "Movimento", y)
        addToggle(f3, "speed_on", "Super Velocidade", y, false, function(v) speedOn = v end); y = y + 46
        addSlider(f3, "Velocidade", y, 16, 200, speedVal, function(v) speedVal = v end); y = y + 66
        addToggle(f3, "noclip_on", "Noclip", y, false, function(v) noclipOn = v end); y = y + 46
        y = addHeader(f3, "Ambiente", y)
        addToggle(f3, "water_walk", "Andar na agua", y, false, function(v) toggleWaterWalk(v) end)
    end

    -- COMBATE
    do
        local f4 = Hub_contentFrames[4]; y = 8

        y = addHeader(f4, "AUTO PLAY", y)
        addToggle(f4, "autoplay_on", "Ativar Auto Play", y, false, function(v)
            autoPlayOn = v
            if v then
                matchStarted = false; autoPlayPad = nil; autoPlayLastCheck = 0
                addLog("Auto Play ON"); updateAutoPlay()
            else addLog("Auto Play OFF") end
        end); y = y + 46
        addButton(f4, "Procurar PadBase1", y, C.accentSoft, function()
            local pad = findStartPad()
            if pad then autoPlayPad = pad; addLog("Encontrado: " .. pad:GetFullName())
            else addLog("PadBase1 nao encontrado") end
        end); y = y + 46

        y = addHeader(f4, "MAPA (auto scan + A*)", y)
        addToggle(f4, "map_show", "Mostrar Mapa na Tela", y, false, function(v)
            mapShowGrid = v
            addLog(v and "Mapa visual ON" or "Mapa visual OFF")
            if not v then clearMapDrawings() end
        end); y = y + 46
        addButton(f4, "Escanear Mapa Agora", y, C.accentSoft, function()
            task.spawn(function()
                local counts = scanMap()
                if counts then
                    addLog("Mapa: " .. (counts.floor or 0) .. " chao, " ..
                           (counts.ramp or 0) .. " rampa, " ..
                           (counts.stair or 0) .. " escada, " ..
                           (counts.wall or 0) .. " parede, " ..
                           (counts.void or 0) .. " void")
                end
            end)
        end); y = y + 46
        addSlider(f4, "Mapa Raio (studs)", y, 20, 150, mapRadius, function(v)
            mapRadius = v
        end); y = y + 66

        y = addHeader(f4, "Rival Bot", y)
        addToggle(f4, "rival_bot", "Ativar Rival Bot", y, false, function(v)
            rivalBotOn = v; updateRivalBot()
            addLog(v and "Rival Bot ON" or "Rival Bot OFF")
        end); y = y + 46
        addToggle(f4, "rival_force_aim", "MIRA TRAVADA", y, true, function(v) rivalBotForceAim = v end); y = y + 46
        addToggle(f4, "rival_follow", "Perseguir (Path + A*)", y, true, function(v) rivalBotFollow = v end); y = y + 46
        addToggle(f4, "rival_shoot", "Atirar automaticamente", y, true, function(v) rivalBotAutoShoot = v end); y = y + 46
        addToggle(f4, "rival_jump", "Pular automaticamente", y, true, function(v) rivalBotAutoJump = v end); y = y + 46
        addToggle(f4, "rival_sprint", "Correr (W)", y, true, function(v)
            rivalBotAutoSprint = v; if not v then stopSprint() end
        end); y = y + 46
        addToggle(f4, "rival_slide", "Deslizar (C)", y, true, function(v) rivalBotAutoSlide = v end); y = y + 46
        addToggle(f4, "rival_show_path", "Mostrar Rota", y, true, function(v) rivalBotShowPath = v end); y = y + 46
        addColorPicker(f4, "Cor da Rota", y, rivalBotPathColor, function(c) rivalBotPathColor = c end); y = y + 46
        addSlider(f4, "Rival Range", y, 10, 500, rivalBotRange, function(v) rivalBotRange = v end); y = y + 66
        addSlider(f4, "Fire Delay (ms)", y, 1, 50, 8, function(v) rivalBotFireDelay = v / 100 end); y = y + 66

        y = addHeader(f4, "Sniper", y)
        addToggle(f4, "sniper_aim", "Sniper: Mirar antes de atirar", y, true, function(v)
            sniperAimEnabled = v
            if not v and sniperIsAiming then stopSniperAim() end
            addLog(v and "Sniper Aim ON" or "Sniper Aim OFF")
        end); y = y + 46
        addSlider(f4, "Sniper Aim Delay (ms)", y, 50, 800, 350, function(v)
            sniperAimDelay = v / 1000
        end); y = y + 66

        addButton(f4, "Resetar Alvo Rival", y, C.warning, function()
            rivalBotTarget = nil; rivalBotLastPos = nil; rivalBotPath = nil
            rivalBotWaypoints = {}; rivalBotWaypointIndex = 1; clearPathVisual()
        end); y = y + 46

        y = addHeader(f4, "Dodge", y)
        addToggle(f4, "dodge_on", "Desviar de Tiros", y, true, function(v) dodgeOn = v end); y = y + 46
        addSlider(f4, "Dodge Range", y, 50, 600, dodgeDetectionRange, function(v) dodgeDetectionRange = v end); y = y + 66

        y = addHeader(f4, "Anti-Void", y)
        addToggle(f4, "void_safety", "Nunca cair no void", y, true, function(v) voidSafetyOn = v end); y = y + 46
        addToggle(f4, "void_recovery", "Recuperar caindo", y, true, function(v) voidFallRecovery = v end); y = y + 46

        y = addHeader(f4, "Trigger Bot", y)
        addToggle(f4, "trigger_bot", "Trigger Bot", y, false, function(v) triggerBotOn = v; updateTriggerBot() end); y = y + 46
        addSlider(f4, "Trigger Delay", y, 1, 100, 5, function(v) triggerBotDelay = v / 100 end); y = y + 66

        y = addHeader(f4, "Kill Aura", y)
        addToggle(f4, "kill_aura", "Kill Aura", y, false, function(v) killAuraOn = v; updateKillAura() end); y = y + 46
        addSlider(f4, "Alcance", y, 5, 50, killAuraRange, function(v) killAuraRange = v end); y = y + 66
        addSlider(f4, "Dano", y, 1, 100, killAuraDmg, function(v) killAuraDmg = v end); y = y + 66

        y = addHeader(f4, "Hitbox + Arma", y)
        addToggle(f4, "hitbox", "Hitbox Expander", y, false, function(v) hitboxExpand = v end); y = y + 46
        addSlider(f4, "Tamanho (x)", y, 2, 10, 2, function(v) hitboxSize = v end); y = y + 66
        addToggle(f4, "no_recoil", "No Recoil", y, false, function(v) noRecoilOn = v end); y = y + 46
        addToggle(f4, "no_spread", "No Spread", y, false, function(v) noSpreadOn = v end); y = y + 46
        addToggle(f4, "inf_ammo", "Infinite Ammo", y, false, function(v) infiniteAmmoOn = v end); y = y + 46
        addToggle(f4, "rapid_fire", "Rapid Fire", y, false, function(v) rapidFireOn = v end)
    end

    -- UTIL
    do
        local f5 = Hub_contentFrames[5]; y = 8
        y = addHeader(f5, "Ferramentas", y)
        addButton(f5, "Puxar Tools", y, C.accentSoft, puxarTools); y = y + 46
        addButton(f5, "Recriar Teleport Tool", y, C.accentSoft, criarToolTeleporte); y = y + 46
    end

    -- EXTRAS
    do
        local f6 = Hub_contentFrames[6]; y = 8
        y = addHeader(f6, "Anti / Auto", y)
        addToggle(f6, "anti_afk", "Anti-AFK", y, false, function(v) antiAfkOn = v; toggleAntiAfk(v) end); y = y + 46
        addToggle(f6, "inf_jump", "Infinite Jump", y, false, function(v) infiniteJumpOn = v; toggleInfiniteJump(v) end); y = y + 46
        addToggle(f6, "fly_on", "Fly", y, false, function(v) flyOn = v; if v then startFly() else stopFly() end end); y = y + 46
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
        addButton(f6, "Copy Job ID", y, C.cardHover, copyJobId); y = y + 46
        addButton(f6, "Copy Place ID", y, C.cardHover, copyPlaceId)
    end

    -- MUNDO
    do
        local f7 = Hub_contentFrames[7]; y = 8
        y = addHeader(f7, "Tempo e Luz", y)
        addToggle(f7, "time_lock", "Travar Hora", y, false, function(v) timeLock = v end); y = y + 46
        addSlider(f7, "Horario", y, 0, 24, timeVal, function(v) timeVal = v end); y = y + 66
        addToggle(f7, "bright_night", "Noite Clara", y, false, function(v) brightNight = v end); y = y + 46
        y = addHeader(f7, "Nevoa", y)
        addToggle(f7, "fog_on", "Nevoa", y, false, function(v) fogOn = v end); y = y + 46
        addToggle(f7, "no_fog", "Sem Nevoa", y, false, function(v) noFog = v end)
    end

    -- SERV
    do
        local f9s = Hub_contentFrames[9]; y = 8
        y = addHeader(f9s, "Informacoes", y)
        local servInfo = {
            {"PlaceId", tostring(game.PlaceId)},
            {"Job ID", game.JobId},
            {"Usuario", _G.loggedUser or "?"},
            {"Drawing", HAS_DRAWING and "SIM" or "NAO"},
        }
        for _, info in ipairs(servInfo) do
            local fr = Instance.new("Frame"); fr.Size = UDim2.new(1,-20,0,42)
            fr.Position = UDim2.new(0,10,0,y); fr.BackgroundColor3 = C.card
            fr.BorderSizePixel = 0; fr.Parent = f9s
            Instance.new("UICorner", fr).CornerRadius = UDim.new(0,10)
            local l1 = Instance.new("TextLabel"); l1.Size = UDim2.new(0.4,0,1,0)
            l1.Position = UDim2.new(0,12,0,0); l1.Text = info[1]
            l1.Font = Enum.Font.GothamBold; l1.TextSize = 12
            l1.TextColor3 = C.textDim; l1.BackgroundTransparency = 1
            l1.TextXAlignment = Enum.TextXAlignment.Left; l1.Parent = fr
            local l2 = Instance.new("TextLabel"); l2.Size = UDim2.new(0.55,0,1,0)
            l2.Position = UDim2.new(0.42,0,0,0); l2.Text = info[2]
            l2.Font = Enum.Font.Gotham; l2.TextSize = 12
            l2.TextColor3 = C.text; l2.BackgroundTransparency = 1
            l2.TextXAlignment = Enum.TextXAlignment.Left
            l2.TextTruncate = Enum.TextTruncate.AtEnd; l2.Parent = fr
            y = y + 48
        end
    end

    -- TROLL
    do
        local f11 = Hub_contentFrames[11]; y = 8
        y = addHeader(f11, "Troll", y)
        for _, act in ipairs(trollActions) do
            local color = C.cardHover
            if act.name:find("Parar") or act.name:find("Congelar") or act.name:find("Cair") then
                color = Color3.fromRGB(140,50,60)
            elseif act.name:find("Levantar") or act.name:find("Descongelar") or act.name:find("Resetar") then
                color = Color3.fromRGB(40,130,80)
            end
            addButton(f11, act.name, y, color, act.cb); y = y + 46
        end
    end

    -- CONFIG
    do
        local f10 = Hub_contentFrames[10]; y = 8
        y = addHeader(f10, "Gerenciamento", y)
        addButton(f10, "Resetar Hub", y, C.warning, function()
            Hub_gui:Destroy(); task.wait(0.1); carregarHub()
        end); y = y + 46
        addButton(f10, "Sair da Conta", y, C.cardHover, function()
            _G.loggedUser = nil; currentUserStr.Value = ""
            Hub_gui:Destroy(); task.wait(0.1); mostrarTelaLogin()
        end); y = y + 46
        y = addHeader(f10, "Fechar", y)
        addButton(f10, "Fechar Menu", y, Color3.fromRGB(140,60,60), Hub_fecharTudo); y = y + 46
        addButton(f10, "DESTRUIR MENU", y, C.danger, function()
            task.spawn(function()
                task.wait(2)
                rivalBotOn = false; autoPlayOn = false
                if rivalBotConn then rivalBotConn:Disconnect() rivalBotConn = nil end
                if autoPlayConn then autoPlayConn:Disconnect() autoPlayConn = nil end
                stopSprint(); stopSniperAim(); clearMapDrawings(); clearPathVisual()
                pcall(resetAllESP)
                task.wait(0.1)
                pcall(function() Hub_gui:Destroy() end)
                _addLogHook = nil
            end)
        end)
    end

    -- PERSONALIZAR
    do
        local f12 = Hub_contentFrames[12]; y = 8
        y = addHeader(f12, "Atalhos", y)
        addKeybindRow(f12, "menu_toggle", "Abrir / Fechar Menu", y); y = y + 46
        y = addHeader(f12, "Interface", y)
        addToggle(f12, "panel_show", "Mostrar Painel", y, true, function(v) Hub_panel.Visible = v end); y = y + 46
        addToggle(f12, "hex_show", "Mostrar Botao DK", y, true, function(v) Hub_btn.Visible = v end); y = y + 46
        y = addHeader(f12, "Resetar", y)
        addButton(f12, "Resetar Keybinds", y, C.warning, function()
            for _, kb in pairs(Hub_keybinds) do
                kb.key = nil
                if kb.btn then kb.btn.Text = "—"; kb.btn.BackgroundColor3 = C.card end
            end
            addLog("Keybinds resetadas")
        end)
    end

    -- ============================================================
    -- LOOPS
    -- ============================================================
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
                elseif hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
            end
        end
    end)

    task.spawn(function()
        while Hub_gui.Parent do
            pcall(updateHitbox); task.wait(0.3)
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not Hub_gui.Parent then return end
        pcall(updateAim)
        if aimAssistOn then pcall(updateAimAssist) end
        pcall(updateESP)
        pcall(updateWorld)
        pcall(updateFOV)
        if flyOn then pcall(updateFly) end
        pcall(updatePathVisual)
        if mapShowGrid then
            local now = tick()
            if now - mapLastDraw > mapDrawInterval then
                mapLastDraw = now
                pcall(drawMapGrid)
            end
        end
    end)

    Hub_btn.MouseButton1Click:Connect(function()
        Hub_mainFrame.Visible = not Hub_mainFrame.Visible
        if Hub_mainFrame.Visible then Hub_reabrirTudo() end
    end)

    Hub_gui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            pcall(resetAllESP); pcall(clearPathVisual)
            pcall(stopSprint); pcall(stopSniperAim)
            pcall(clearMapDrawings)
        end
    end)

    task.wait(1)
    startAutoMapScan()

    print("[Dark's Hub] Hub carregado!")
    addLog("Hub pronto! Clique no botao DK")
end

task.defer(function()
    local u = _G.loggedUser
    if u and accounts[u] then
        print("[Dark's Hub] Login auto: " .. u)
        pcall(carregarHub)
    else
        print("[Dark's Hub] Login...")
        pcall(mostrarTelaLogin)
    end
end)
