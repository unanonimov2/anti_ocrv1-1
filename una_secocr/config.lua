Config = Config or {}

Config.Webhooks = {
    RawScreenshots = "https://discord.com/api/webhooks/...",
    Screenshots    = "https://discord.com/api/webhooks/...",
    Detections     = "https://discord.com/api/webhooks/...",
}

Config.KickMessage = "Has sido expulsado del servidor por uso de menú de trampas. [UNA-SECURITY]"

Config.OCR = {
    ScreenshotInterval = 8500,
    Confidence         = 0.50,
    WholeWord          = true,
    Words = {
        "FlexSkazaMenu", "SidMenu", "Lynx8", "LynxEvo", "Maestro Menu",
        "redEngine", "HamMafia", "tzx", "HamHaxia", "Dopameme", "redMENU",
        "Desudo", "gamesense", "Tapatio", "Malossi", "RedStonia",
        "Chocohax", "susano", "MEDUSA", "Nexus", "Eulen", "Cherax",
        "Kiddions", "2Take1", "Stand", "Disturbed", "Ozark", "BigBase",
        "Midnight", "Paragon", "Skulled", "Chimera", "Modest", "Vega",
        "Sentinel", "Hydra", "Celery", "Aspect", "Eruption",
        "Absolute", "Absolute Alpha", "Auttaja", "BartowMenu",
        "Bitizy", "Brutan", "Dopamine", "Exia", "Falcon", "FendinX",
        "LeX", "Lumia", "Luminous", "Lynx7", "Lynx9", "Tumx", "Aries",
        "BadWolf", "Biznes", "Chocolat Blanc", "Chocolat Noir", "Cience",
        "Cobra Menu", "Crusader", "Dreah", "Emperior", "FiveSense",
        "Wizard Menu", "XAries", "Derp", "Leaker", "brutan menu",
        "brutan premium", "eulen lynx", "absolute eulen",
        "god mode", "godmode", "invisible", "invisibility",
        "infinite ammo", "munición infinita", "unlimited ammo",
        "infinite health", "vida infinita", "max health",
        "infinite armor", "give armor", "max armor",
        "Infinity Stamina", "no ragdoll", "super jump",
        "super speed", "fast run", "override player speed",
        "no fall damage", "never wanted", "clear wanted",
        "max wanted", "set wanted level", "police ignore",
        "super punch", "one hit kill", "off the radar",
        "ghost mode", "semi god", "never die",
        "vehicle god", "vehicle godmode", "vehicle invisibility",
        "boost vehicle", "instant repair", "vehicle no damage",
        "spawn vehicle", "delete vehicle", "flip vehicle",
        "drive underwater", "boost speed", "vehicle speed",
        "give all weapons", "weapon modifier", "no recoil",
        "rapid fire", "explosive ammo", "explosive bullets",
        "fire ammo", "incendiary ammo", "infinite magazine",
        "no spread", "aimbot",
        "crash players", "kick players", "freeze players",
        "teleport to player", "spectate", "send to coords",
        "clone player", "steal identity", "set model",
        "money drop", "give money", "drop cash",
        "spawn object", "delete entity", "clear entities",
        "explosion loop", "gravity gun",
    },
}

Config.CommandPermission = "group.admin"

Config.Colors = {
    Pending    = 16776960,
    Detection  = 15158332,
    Screenshot = 3447003,
}
