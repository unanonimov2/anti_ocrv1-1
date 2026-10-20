fx_version "cerulean"
game "gta5"

author "UNA-SECURITY"
version "1.1.0"
description "UNA-SECURITY | Anti-OCR standalone — detección de menús por OCR, capturas y logs Discord"

files {
    "html/index.html",
}

ui_page "html/index.html"

client_scripts {
    "config.lua",
    "src/client/anti_ocr.lua",
}

server_scripts {
    "config.lua",
    "src/server/discord.lua",
    "src/server/main.lua",
}

dependencies {
    "screenshot-basic",
}

lua54 "yes"
