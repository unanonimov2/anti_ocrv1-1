# UNA-SECURITY · Anti-OCR Standalone

Script independiente extraído de **UNA_AC** que detecta menús de trampas mediante OCR sobre capturas de pantalla, sube la captura como evidencia y registra todo en Discord con canales diferenciados. **No graba vídeo.**

---

## Índice

- [Qué hace](#qué-hace)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Configuración](#configuración)
- [Canales Discord](#canales-discord)
- [Comandos](#comandos)
- [Flujo de logs](#flujo-de-logs)
- [Estructura](#estructura)
- [FAQ](#faq)

---

## Qué hace

| Función | Descripción |
|---|---|
| **Anti-OCR automático** | Captura la pantalla de cada jugador cada X ms y analiza el texto con Tesseract.js. Si detecta el nombre de un menú o una opción de trampa, sube la captura como evidencia, registra el log y kickea al jugador. |
| **3 canales separados** | Cada tipo de log va a su canal: imágenes crudas, capturas manuales con embed y detecciones completas. |
| **Captura manual** | `/un_seccap <id>` sube la imagen al canal `RawScreenshots` y publica el embed con datos completos del jugador en el canal `Screenshots`. |

---

## Requisitos

| Recurso | Uso |
|---|---|
| [`screenshot-basic`](https://github.com/citizenfx/screenshot-basic) | Capturas de pantalla |

`screenshot-basic` debe iniciarse **antes** que `una_secocr`.

---

## Instalación

1. Copia la carpeta `una_secocr` en tu directorio de resources:
   ```
   resources/[seguridad]/una_secocr/
   ```

2. Añade al `server.cfg`:
   ```
   ensure screenshot-basic
   ensure una_secocr

   add_ace group.admin command.un_seccap allow
   ```

3. Configura `config.lua` (ver sección siguiente).

4. Ejecuta `refresh` + `ensure una_secocr`.

---

## Configuración

### Webhooks

```lua
Config.Webhooks = {
    RawScreenshots = "...",  -- imágenes crudas (detección y manuales)
    Screenshots    = "...",  -- embed captura manual con datos del jugador
    Detections     = "...",  -- embed detección OCR completo con captura incrustada
}
```

El cliente sube la imagen directamente a `RawScreenshots` con `requestScreenshotUpload`. La `proxy_url` del attachment resultante se referencia luego en los embeds de `Screenshots` y `Detections` mediante `image.url`, sin re-subir la imagen. El servidor solo acepta URLs de Discord (`cdn.discordapp.com` y `media.discordapp.net`).

### Kick

```lua
Config.KickMessage = "Has sido expulsado del servidor por uso de menú de trampas. [UNA-SECURITY]"
```

### OCR

```lua
Config.OCR = {
    ScreenshotInterval = 8500,  -- ms entre capturas automáticas
    Confidence         = 0.50,  -- confianza mínima por palabra (0.0 – 1.0)
    WholeWord          = true,  -- true: solo palabras completas; false: también dentro de otras palabras
    Words              = { ... }
}
```

- `Confidence`: las palabras que Tesseract reconoce con menos confianza que este valor se descartan. Subirlo reduce falsos positivos; bajarlo detecta más en tipografías raras.
- `WholeWord`: con `true`, `Stand` no salta con "understand" ni "standing". Con `false` se busca como subcadena.
- La comparación ignora mayúsculas, signos y saltos de línea.

### Permisos

```lua
Config.CommandPermission = "group.admin"
```

---

## Canales Discord

| Webhook key | Canal | Qué recibe |
|---|---|---|
| `RawScreenshots` | Evidencias | Imagen cruda subida por `screenshot-basic`, sin texto ni embed. Tanto las de detección OCR como las de `/un_seccap`. |
| `Screenshots` | Capturas admin | Embed pending → embed final con foto incrustada, datos del jugador e identifiers. Solo para `/un_seccap`. |
| `Detections` | Detecciones OCR | Embed con foto incrustada (URL de `RawScreenshots`), palabra detectada e identifiers. |

---

## Comandos

Solo disponibles desde la consola del servidor o con el ace configurado en `Config.CommandPermission`.

### `un_seccap <id>`

```
un_seccap 12
```

1. → `Screenshots`: embed pending amarillo
2. El cliente sube la imagen a `RawScreenshots` y devuelve la URL
3. → `Screenshots`: embed final azul con foto incrustada + identifiers

---

## Flujo de logs

### Detección OCR automática

```
CLIENTE
  ├─ OCR detecta palabra
  ├─ requestScreenshotUpload → Webhooks.RawScreenshots
  └─ TriggerServerEvent("una_secocr:detected", word, screenshotUrl)

SERVIDOR
  ├─ valida palabra y URL
  ├─ → Webhooks.Detections   🚨 Final (rojo)
  │        image.url = screenshotUrl  ← URL de RawScreenshots
  │        🪪 identifiers completos
  │        footer: powered by UNA-SECURITY
  └─ DropPlayer() kick
```

### Captura manual

```
SERVIDOR recibe /un_seccap
  ├─ → Webhooks.Screenshots  ⏳ Pending (amarillo)
  └─ TriggerClientEvent("una_secocr:doScreenshot")

CLIENTE
  └─ requestScreenshotUpload → Webhooks.RawScreenshots → devuelve URL

SERVIDOR
  └─ → Webhooks.Screenshots  📸 Final (azul)
           image.url = screenshotUrl
           🪪 identifiers completos
```

---

## Estructura

```
una_secocr/
├── fxmanifest.lua
├── config.lua
├── README.md
├── html/
│   └── index.html              ← NUI: Tesseract.js (OCR en el cliente)
└── src/
    ├── client/
    │   └── anti_ocr.lua        ← loop OCR + subida a RawScreenshots + listeners
    └── server/
        ├── discord.lua         ← embeds por canal, cola anti-rate-limit
        └── main.lua            ← detección, kick y comando de captura
```

---

## FAQ

**¿Por qué la imagen aparece en `RawScreenshots` Y en el embed de detecciones?**
El cliente sube la imagen una sola vez a `RawScreenshots`. La `proxy_url` del attachment resultante se usa como `image.url` en el embed del canal `Detections`. Discord sirve la misma imagen — no hay doble subida.

**¿Graba vídeo?**
No. Se eliminó la grabación junto con el resource `screencapture`, el comando `/un_secgrabar` y la integración con FiveManage. Solo se usan capturas de pantalla.

**El OCR da falsos positivos.**
Sube `Config.OCR.Confidence` (por ejemplo a `0.70`), deja `WholeWord = true` y/o elimina las palabras más genéricas del array `Words`.

**Se me escapan detecciones.**
Baja `Config.OCR.Confidence` (por ejemplo a `0.30`) o pon `WholeWord = false`.

**¿Los tres webhooks pueden apuntar al mismo canal?**
Técnicamente sí, pero pierde todo el sentido de la separación por canales.

