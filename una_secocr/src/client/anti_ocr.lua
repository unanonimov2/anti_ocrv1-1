local BUSY_TIMEOUT = 30000
local busySince    = 0
local patterns     = {}

local function log(level, msg)
    local p = { INFO = "^5[UNA-OCR]^7", WARN = "^3[UNA-OCR]^7", ERROR = "^1[UNA-OCR]^7", DETECT = "^1[UNA-OCR !]^7" }
    print((p[level] or "[UNA-OCR]") .. " " .. tostring(msg))
end

local function isBusy()
    return busySince ~= 0 and (GetGameTimer() - busySince) < BUSY_TIMEOUT
end

local function normalize(str)
    local s = string.lower(str):gsub("[^%w]+", " ")
    return (s:match("^%s*(.-)%s*$"))
end

local function buildPatterns()
    local ocr       = Config.OCR or {}
    local wholeWord = ocr.WholeWord ~= false
    local seen      = {}
    for _, word in ipairs(ocr.Words or {}) do
        local n = normalize(word)
        if n ~= "" and not seen[n] then
            seen[n] = true
            patterns[#patterns + 1] = { word = word, needle = wholeWord and (" " .. n .. " ") or n }
        end
    end
end

local function findWord(text)
    local haystack = " " .. normalize(text) .. " "
    for _, p in ipairs(patterns) do
        if string.find(haystack, p.needle, 1, true) then
            return p.word
        end
    end
    return nil
end

local function hasScreenshotExport(name)
    local ok, fn = pcall(function() return exports['screenshot-basic'][name] end)
    return ok and type(fn) == "function"
end

local function uploadToRaw(callback)
    local wh = Config.Webhooks and Config.Webhooks.RawScreenshots
    if not wh or wh == "" or not hasScreenshotExport("requestScreenshotUpload") then
        callback(nil)
        return
    end

    local ok, err = pcall(function()
        exports['screenshot-basic']:requestScreenshotUpload(wh, 'files[]', { encoding = "webp", quality = 1 }, function(result)
            local url = nil
            if result and result ~= "" then
                local ok2, resp = pcall(json.decode, result)
                if ok2 and resp and resp.attachments and resp.attachments[1] then
                    url = resp.attachments[1].proxy_url
                end
            end
            log("INFO", url and ("Captura: " .. url) or "Sin URL de captura")
            callback(url)
        end)
    end)

    if not ok then
        log("ERROR", tostring(err))
        callback(nil)
    end
end

local function captureForOcr()
    busySince = GetGameTimer()
    local ok = pcall(function()
        exports['screenshot-basic']:requestScreenshot({ encoding = "webp" }, function(imgData)
            if not imgData then
                busySince = 0
                return
            end
            SendNUIMessage({
                action        = GetCurrentResourceName() .. ":checkString",
                image         = imgData,
                minConfidence = (Config.OCR and Config.OCR.Confidence) or 0,
            })
        end)
    end)
    if not ok then busySince = 0 end
end

RegisterNUICallback("checktext", function(data, cb)
    busySince = 0
    if cb then cb({ success = true }) end
    if not data or type(data.text) ~= "string" or data.text == "" then return end

    local found = findWord(data.text)
    if not found then return end

    log("DETECT", ("Detectado: \"%s\" — subiendo captura..."):format(found))
    uploadToRaw(function(screenshotUrl)
        TriggerServerEvent("una_secocr:detected", found, screenshotUrl)
    end)
end)

CreateThread(function()
    Wait(5000)

    if not hasScreenshotExport("requestScreenshot") then
        log("WARN", "screenshot-basic no disponible")
        return
    end

    buildPatterns()
    if #patterns == 0 then
        log("WARN", "Sin palabras OCR configuradas")
        return
    end

    local interval = (Config.OCR and Config.OCR.ScreenshotInterval) or 8500
    log("INFO", ("Iniciado | %d palabras | intervalo %dms"):format(#patterns, interval))

    while true do
        if not isBusy() and not IsPauseMenuActive() then
            captureForOcr()
        end
        Wait(interval)
    end
end)

RegisterNetEvent("una_secocr:doScreenshot", function()
    log("INFO", "Captura manual solicitada")
    uploadToRaw(function(url)
        TriggerServerEvent("una_secocr:screenshotDone", url)
    end)
end)
