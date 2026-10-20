local PENDING_TIMEOUT = 30000

local allowedWords = {}
for _, word in ipairs(Config.OCR and Config.OCR.Words or {}) do
    allowedWords[word] = true
end

local handled         = {}
local pendingCaptures = {}

local function log(level, msg)
    local p = { INFO = "^5[UNA-OCR]^7", WARN = "^3[UNA-OCR]^7", ERROR = "^1[UNA-OCR]^7", CMD = "^6[UNA-OCR CMD]^7", DETECT = "^1[UNA-OCR !]^7" }
    print((p[level] or "[UNA-OCR]") .. " " .. tostring(msg))
end

local function pName(src)
    if not src or src == 0 then return "Consola" end
    return GetPlayerName(src) or ("ID:" .. src)
end

local function isAdmin(src)
    if src == 0 then return true end
    return IsPlayerAceAllowed(src, Config.CommandPermission)
end

local function validScreenshotUrl(url)
    if type(url) ~= "string" or #url > 1024 then return nil end
    if url:find("^https://cdn%.discordapp%.com/") or url:find("^https://media%.discordapp%.net/") then
        return url
    end
    return nil
end

AddEventHandler("playerDropped", function()
    local src = source
    handled[src] = nil
    pendingCaptures[src] = nil
end)

RegisterNetEvent("una_secocr:detected", function(word, screenshotUrl)
    local src  = source
    local name = GetPlayerName(src)
    if not name or handled[src] then return end
    if type(word) ~= "string" or not allowedWords[word] then return end
    handled[src] = true

    log("DETECT", ("[%s / ID:%d] -> \"%s\""):format(name, src, word))

    local ids = Discord.formatIdentifiers(src)
    Discord.logDetection(name, src, ids, word, validScreenshotUrl(screenshotUrl))

    DropPlayer(src, Config.KickMessage or "Expulsado por deteccion OCR. [UNA-SECURITY]")
end)

RegisterNetEvent("una_secocr:screenshotDone", function(screenshotUrl)
    local src     = source
    local pending = pendingCaptures[src]
    pendingCaptures[src] = nil
    if not pending or (GetGameTimer() - pending.at) > PENDING_TIMEOUT then return end

    local requesterId = pending.requester
    local tName       = GetPlayerName(src) or ("ID:" .. src)
    local aName       = pName(requesterId)
    local url         = validScreenshotUrl(screenshotUrl)

    Discord.logScreenshotFinal(aName, tName, src, Discord.formatIdentifiers(src), url)

    if requesterId and requesterId ~= 0 and GetPlayerName(requesterId) then
        TriggerClientEvent("chat:addMessage", requesterId, {
            color = { 0, 200, 255 }, multiline = true,
            args  = { "[UNA-SEC]", url
                and ("Captura de %s enviada"):format(tName)
                or  ("No se pudo capturar a %s"):format(tName) },
        })
    end
end)

RegisterCommand("un_seccap", function(src, args)
    if not isAdmin(src) then return end

    local targetId = tonumber(args[1])
    if not targetId then log("WARN", "Uso: un_seccap <server_id>"); return end

    local tName = GetPlayerName(targetId)
    if not tName then log("WARN", ("ID %d no encontrado"):format(targetId)); return end

    local aName = pName(src)
    log("CMD", ("Captura -> [%s/%d] por [%s]"):format(tName, targetId, aName))

    pendingCaptures[targetId] = { requester = src, at = GetGameTimer() }
    Discord.logScreenshotPending(aName, tName, targetId)
    TriggerClientEvent("una_secocr:doScreenshot", targetId)
end, true)

log("INFO", "una_secocr cargado  |  un_seccap <id>")
log("INFO", "server.cfg -> add_ace group.admin command.un_seccap allow")
