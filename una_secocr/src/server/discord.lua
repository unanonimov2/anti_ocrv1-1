Discord = Discord or {}

local FOOTER = { text = "powered by UNA-SECURITY" }

local queues     = {}
local processing = {}

local function ts()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function wh(key)
    return Config.Webhooks and Config.Webhooks[key] or ""
end

local function enqueue(url, payload)
    if not url or url == "" then return end
    local encoded = json.encode(payload)
    if not encoded then return end
    queues[url] = queues[url] or {}
    table.insert(queues[url], { url = url, body = encoded })
end

local function startProcessor(url)
    if processing[url] then return end
    processing[url] = true
    queues[url] = queues[url] or {}

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(350)
            local q    = queues[url]
            local item = table.remove(q, 1)
            if item then
                PerformHttpRequest(item.url, function(code)
                    if code == 429 then
                        table.insert(q, 1, item)
                        Citizen.Wait(2000)
                    end
                end, "POST", item.body, { ["Content-Type"] = "application/json" })
                Citizen.Wait(1100)
            end
        end
    end)
end

Citizen.CreateThread(function()
    Citizen.Wait(500)
    for _, url in pairs(Config.Webhooks or {}) do
        if type(url) == "string" and url ~= "" and not url:find("TU_WEBHOOK") then
            startProcessor(url)
        end
    end
end)

function Discord.formatIdentifiers(pid)
    local out = {}
    for _, t in ipairs({ "license", "steam", "discord", "fivem", "xbl", "live" }) do
        local id = GetPlayerIdentifierByType(pid, t)
        if id then
            if t == "discord" then
                table.insert(out, "Discord › <@" .. id:gsub("discord:", "") .. ">")
            elseif t == "steam" then
                local dec = tonumber(id:gsub("steam:", ""), 16)
                table.insert(out, dec
                    and "Steam › [Ver perfil](https://steamcommunity.com/profiles/" .. dec .. ")"
                    or  "Steam › `" .. id .. "`")
            elseif t == "fivem" then
                local num = id:gsub("fivem:", "")
                table.insert(out, "FiveM › [" .. num .. "](https://forum.cfx.re/u/" .. num .. "/summary)")
            else
                table.insert(out, t:upper() .. " › `" .. id .. "`")
            end
        end
    end
    local ep = GetPlayerEndpoint(pid)
    if ep then table.insert(out, "IP › `" .. ep .. "`") end
    return #out > 0 and table.concat(out, "\n") or "`Sin identifiers`"
end

function Discord.logDetection(playerName, serverId, identifiers, word, screenshotUrl)
    local evidencias = "*Sin captura disponible*"
    if screenshotUrl and screenshotUrl ~= "" then
        evidencias = "📸 [Ver captura](" .. screenshotUrl .. ")"
    end

    local embed = {
        title       = "🚨  Menú de Trampas Detectado — OCR",
        color       = Config.Colors.Detection,
        description = ("El jugador **%s** ha sido **kickeado** por detección OCR."):format(playerName),
        fields = {
            { name = "👤  Jugador",          value = ("`%s`  (ID: **%d**)"):format(playerName, serverId), inline = true  },
            { name = "🔍  Palabra detectada", value = ("`%s`"):format(word),                               inline = true  },
            { name = "🪪  Identifiers",       value = identifiers or "`Sin identifiers`",                  inline = false },
            { name = "🎥  Evidencias",        value = evidencias,                                          inline = false },
        },
        timestamp = ts(),
        footer    = FOOTER,
    }

    if screenshotUrl and screenshotUrl ~= "" then
        embed.image = { url = screenshotUrl }
    end

    enqueue(wh("Detections"), {
        username = "UNA-SECURITY | Anti-OCR",
        embeds   = { embed },
    })
end

function Discord.logScreenshotPending(adminName, targetName, targetId)
    enqueue(wh("Screenshots"), {
        username = "UNA-SECURITY | Capturas",
        embeds = {{
            title       = "⏳  Captura Manual — En curso",
            color       = Config.Colors.Pending,
            description = ("Captura solicitada por **%s** sobre **%s** (ID: %d).\n🔄 Esperando respuesta del cliente..."):format(adminName, targetName, targetId),
            timestamp   = ts(),
            footer      = FOOTER,
        }},
    })
end

function Discord.logScreenshotFinal(adminName, targetName, targetId, identifiers, screenshotUrl)
    local embed = {
        title       = "📸  Captura Manual — Completada",
        color       = Config.Colors.Screenshot,
        description = ("Captura de pantalla de **%s** solicitada por **%s**."):format(targetName, adminName),
        fields = {
            { name = "🛡️  Admin",      value = ("`%s`"):format(adminName),                          inline = true  },
            { name = "🎯  Objetivo",   value = ("`%s`  (ID: **%d**)"):format(targetName, targetId), inline = true  },
            { name = "🪪  Identifiers", value = identifiers or "`Sin identifiers`",                 inline = false },
        },
        timestamp = ts(),
        footer    = FOOTER,
    }

    if screenshotUrl and screenshotUrl ~= "" then
        embed.image = { url = screenshotUrl }
        table.insert(embed.fields, { name = "🔗  Enlace", value = "[Abrir captura](" .. screenshotUrl .. ")", inline = false })
    else
        table.insert(embed.fields, { name = "⚠️  Estado", value = "No se pudo obtener la captura.", inline = false })
    end

    enqueue(wh("Screenshots"), {
        username = "UNA-SECURITY | Capturas",
        embeds   = { embed },
    })
end
