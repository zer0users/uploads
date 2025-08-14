-- Sistema Operativo Táctil para ComputerCraft: Tweaked
-- Solo funciona con monitor_touch events
-- Autor: Asistente IA

-- Configuración inicial
local monitor = peripheral.find("monitor")
if not monitor then
    error("No se encontró monitor conectado!")
end

monitor.setTextScale(0.5)
local w, h = monitor.getSize()
monitor.setBackgroundColor(colors.black)
monitor.clear()

-- Estado del sistema
local currentApp = "desktop"
local apps = {}
local files = {}
local selectedFile = nil
local scrollPos = 1
local maxVisible = h - 4

-- Colores del tema
local theme = {
    bg = colors.black,
    panel = colors.gray,
    button = colors.lightGray,
    buttonActive = colors.white,
    text = colors.white,
    textActive = colors.black,
    accent = colors.blue,
    success = colors.green,
    warning = colors.yellow,
    error = colors.red
}

-- Utilidades de dibujo
function drawBox(x, y, width, height, bg, fg, text)
    monitor.setBackgroundColor(bg or theme.button)
    monitor.setTextColor(fg or theme.text)
    
    for i = 0, height - 1 do
        monitor.setCursorPos(x, y + i)
        monitor.write(string.rep(" ", width))
    end
    
    if text then
        local textX = x + math.floor((width - #text) / 2)
        local textY = y + math.floor(height / 2)
        monitor.setCursorPos(textX, textY)
        monitor.write(text)
    end
end

function drawButton(x, y, width, height, text, active)
    local bg = active and theme.buttonActive or theme.button
    local fg = active and theme.textActive or theme.text
    drawBox(x, y, width, height, bg, fg, text)
end

function isInside(tx, ty, x, y, width, height)
    return tx >= x and tx < x + width and ty >= y and ty < y + height
end

-- Barra superior del sistema
function drawTopBar()
    drawBox(1, 1, w, 3, theme.panel, theme.text)
    monitor.setCursorPos(2, 2)
    monitor.write("SO Tactil v1.0")
    
    -- Botón de menú
    drawButton(w - 8, 1, 8, 3, "MENU", false)
    
    -- Reloj
    local time = textutils.formatTime(os.time(), false)
    monitor.setCursorPos(w - 15, 2)
    monitor.write(time)
end

-- Aplicaciones del sistema
apps.fileManager = {
    name = "Archivos",
    icon = "[F]",
    run = function()
        currentApp = "fileManager"
        refreshFiles()
    end
}

apps.textEditor = {
    name = "Editor",
    icon = "[E]", 
    run = function()
        currentApp = "textEditor"
    end
}

apps.calculator = {
    name = "Calc",
    icon = "[C]",
    run = function()
        currentApp = "calculator"
    end
}

apps.settings = {
    name = "Config",
    icon = "[S]",
    run = function()
        currentApp = "settings"
    end
}

-- Escritorio principal
function drawDesktop()
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    drawTopBar()
    
    monitor.setCursorPos(2, 5)
    monitor.setTextColor(theme.text)
    monitor.write("Bienvenido al SO Tactil")
    
    -- Iconos de aplicaciones
    local appList = {"fileManager", "textEditor", "calculator", "settings"}
    local cols = 4
    local startX = 2
    local startY = 8
    
    for i, appKey in ipairs(appList) do
        local app = apps[appKey]
        local x = startX + ((i - 1) % cols) * 12
        local y = startY + math.floor((i - 1) / cols) * 4
        
        drawButton(x, y, 10, 3, app.icon, false)
        monitor.setCursorPos(x, y + 3)
        monitor.setBackgroundColor(theme.bg)
        monitor.setTextColor(theme.text)
        monitor.write(app.name)
    end
end

-- Gestor de archivos
function refreshFiles()
    files = {}
    local fileList = fs.list("/")
    for _, file in pairs(fileList) do
        table.insert(files, {
            name = file,
            isDir = fs.isDir(file),
            size = fs.isDir(file) and 0 or fs.getSize(file)
        })
    end
    table.sort(files, function(a, b) return a.name < b.name end)
end

function drawFileManager()
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    drawTopBar()
    
    -- Título
    monitor.setCursorPos(2, 4)
    monitor.setTextColor(theme.accent)
    monitor.write("=== GESTOR DE ARCHIVOS ===")
    
    -- Botones de acción
    drawButton(2, h - 2, 8, 2, "NUEVO", false)
    drawButton(12, h - 2, 8, 2, "BORRAR", selectedFile ~= nil)
    drawButton(22, h - 2, 8, 2, "EDITAR", selectedFile ~= nil)
    drawButton(w - 10, h - 2, 8, 2, "ATRAS", false)
    
    -- Lista de archivos
    local startY = 6
    local visibleFiles = math.min(maxVisible, #files)
    
    for i = 1, visibleFiles do
        local fileIndex = scrollPos + i - 1
        if fileIndex <= #files then
            local file = files[fileIndex]
            local y = startY + i - 1
            local selected = selectedFile == fileIndex
            
            local bg = selected and theme.accent or theme.bg
            local fg = selected and theme.textActive or theme.text
            
            monitor.setBackgroundColor(bg)
            monitor.setTextColor(fg)
            monitor.setCursorPos(2, y)
            
            local prefix = file.isDir and "[DIR]" or "[   ]"
            local displayName = file.name
            if #displayName > w - 15 then
                displayName = string.sub(displayName, 1, w - 18) .. "..."
            end
            
            local line = prefix .. " " .. displayName
            monitor.write(line .. string.rep(" ", w - #line - 1))
        end
    end
    
    -- Scroll indicators
    if scrollPos > 1 then
        monitor.setCursorPos(w - 1, startY)
        monitor.setBackgroundColor(theme.bg)
        monitor.setTextColor(theme.accent)
        monitor.write("^")
    end
    
    if scrollPos + maxVisible < #files then
        monitor.setCursorPos(w - 1, startY + maxVisible - 1)
        monitor.setTextColor(theme.accent)
        monitor.write("v")
    end
end

-- Calculadora simple
local calcDisplay = "0"
local calcNum1 = 0
local calcNum2 = 0
local calcOp = nil
local calcNewNum = true

function drawCalculator()
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    drawTopBar()
    
    monitor.setCursorPos(2, 4)
    monitor.setTextColor(theme.accent)
    monitor.write("=== CALCULADORA ===")
    
    -- Display
    drawBox(2, 6, w - 10, 3, theme.panel, theme.text)
    monitor.setCursorPos(w - 8 - #calcDisplay, 7)
    monitor.write(calcDisplay)
    
    -- Botones
    local buttons = {
        {"C", "0", "=", "+"},
        {"7", "8", "9", "-"},
        {"4", "5", "6", "*"},
        {"1", "2", "3", "/"}
    }
    
    local startY = 10
    for row = 1, 4 do
        for col = 1, 4 do
            local x = 2 + (col - 1) * 8
            local y = startY + (row - 1) * 3
            local btn = buttons[row][col]
            drawButton(x, y, 6, 2, btn, false)
        end
    end
    
    -- Botón atrás
    drawButton(w - 10, h - 2, 8, 2, "ATRAS", false)
end

-- Editor de texto simple
local editorText = ""
local editorFilename = ""

function drawTextEditor()
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    drawTopBar()
    
    monitor.setCursorPos(2, 4)
    monitor.setTextColor(theme.accent)
    monitor.write("=== EDITOR DE TEXTO ===")
    
    -- Nombre del archivo
    monitor.setCursorPos(2, 5)
    monitor.setTextColor(theme.text)
    monitor.write("Archivo: " .. (editorFilename ~= "" and editorFilename or "nuevo.txt"))
    
    -- Área de texto
    drawBox(2, 7, w - 2, h - 10, theme.panel, theme.text)
    
    -- Botones
    drawButton(2, h - 2, 8, 2, "GUARDAR", false)
    drawButton(12, h - 2, 8, 2, "CARGAR", false)
    drawButton(w - 10, h - 2, 8, 2, "ATRAS", false)
end

-- Configuración
function drawSettings()
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    drawTopBar()
    
    monitor.setCursorPos(2, 4)
    monitor.setTextColor(theme.accent)
    monitor.write("=== CONFIGURACION ===")
    
    monitor.setCursorPos(2, 6)
    monitor.setTextColor(theme.text)
    monitor.write("Monitor: " .. w .. "x" .. h)
    
    monitor.setCursorPos(2, 7)
    monitor.write("Escala: 0.5")
    
    monitor.setCursorPos(2, 8)
    monitor.write("SO Version: 1.0")
    
    -- Botón reiniciar
    drawButton(2, 10, 12, 2, "REINICIAR", false)
    drawButton(w - 10, h - 2, 8, 2, "ATRAS", false)
end

-- Función principal de renderizado
function render()
    if currentApp == "desktop" then
        drawDesktop()
    elseif currentApp == "fileManager" then
        drawFileManager()
    elseif currentApp == "calculator" then
        drawCalculator()
    elseif currentApp == "textEditor" then
        drawTextEditor()
    elseif currentApp == "settings" then
        drawSettings()
    end
end

-- Manejo de eventos táctiles
function handleTouch(x, y)
    -- Botón menú siempre disponible
    if isInside(x, y, w - 8, 1, 8, 3) then
        currentApp = "desktop"
        return
    end
    
    if currentApp == "desktop" then
        -- Iconos de aplicaciones
        local appList = {"fileManager", "textEditor", "calculator", "settings"}
        for i, appKey in ipairs(appList) do
            local appX = 2 + ((i - 1) % 4) * 12
            local appY = 8 + math.floor((i - 1) / 4) * 4
            if isInside(x, y, appX, appY, 10, 3) then
                apps[appKey].run()
                return
            end
        end
        
    elseif currentApp == "fileManager" then
        -- Botones de acción
        if isInside(x, y, w - 10, h - 2, 8, 2) then
            currentApp = "desktop"
        elseif isInside(x, y, 2, h - 2, 8, 2) then
            -- Nuevo archivo (simplificado)
            table.insert(files, {name = "nuevo" .. #files, isDir = false, size = 0})
        elseif isInside(x, y, 12, h - 2, 8, 2) and selectedFile then
            -- Borrar archivo
            table.remove(files, selectedFile)
            selectedFile = nil
        elseif isInside(x, y, 22, h - 2, 8, 2) and selectedFile then
            -- Editar archivo
            editorFilename = files[selectedFile].name
            currentApp = "textEditor"
        else
            -- Seleccionar archivo
            local startY = 6
            for i = 1, maxVisible do
                local fileIndex = scrollPos + i - 1
                if fileIndex <= #files then
                    local fileY = startY + i - 1
                    if isInside(x, y, 2, fileY, w - 2, 1) then
                        selectedFile = selectedFile == fileIndex and nil or fileIndex
                        return
                    end
                end
            end
        end
        
    elseif currentApp == "calculator" then
        if isInside(x, y, w - 10, h - 2, 8, 2) then
            currentApp = "desktop"
        else
            -- Botones de calculadora
            local buttons = {
                {"C", "0", "=", "+"},
                {"7", "8", "9", "-"},
                {"4", "5", "6", "*"},
                {"1", "2", "3", "/"}
            }
            
            local startY = 10
            for row = 1, 4 do
                for col = 1, 4 do
                    local btnX = 2 + (col - 1) * 8
                    local btnY = startY + (row - 1) * 3
                    if isInside(x, y, btnX, btnY, 6, 2) then
                        local btn = buttons[row][col]
                        if btn == "C" then
                            calcDisplay = "0"
                            calcNum1 = 0
                            calcNum2 = 0
                            calcOp = nil
                            calcNewNum = true
                        elseif tonumber(btn) then
                            if calcNewNum then
                                calcDisplay = btn
                                calcNewNum = false
                            else
                                calcDisplay = calcDisplay .. btn
                            end
                        elseif btn == "=" then
                            if calcOp then
                                calcNum2 = tonumber(calcDisplay) or 0
                                local result = 0
                                if calcOp == "+" then result = calcNum1 + calcNum2
                                elseif calcOp == "-" then result = calcNum1 - calcNum2
                                elseif calcOp == "*" then result = calcNum1 * calcNum2
                                elseif calcOp == "/" then result = calcNum2 ~= 0 and calcNum1 / calcNum2 or 0
                                end
                                calcDisplay = tostring(result)
                                calcNewNum = true
                                calcOp = nil
                            end
                        else -- Operadores
                            calcNum1 = tonumber(calcDisplay) or 0
                            calcOp = btn
                            calcNewNum = true
                        end
                        return
                    end
                end
            end
        end
        
    elseif currentApp == "textEditor" then
        if isInside(x, y, w - 10, h - 2, 8, 2) then
            currentApp = "desktop"
        elseif isInside(x, y, 2, h - 2, 8, 2) then
            -- Guardar (simplificado)
            monitor.setCursorPos(2, 6)
            monitor.setTextColor(theme.success)
            monitor.write("¡Guardado!")
            sleep(1)
        elseif isInside(x, y, 12, h - 2, 8, 2) then
            -- Cargar (simplificado)
            editorText = "Texto de ejemplo cargado..."
        end
        
    elseif currentApp == "settings" then
        if isInside(x, y, w - 10, h - 2, 8, 2) then
            currentApp = "desktop"
        elseif isInside(x, y, 2, 10, 12, 2) then
            -- Reiniciar
            os.reboot()
        end
    end
end

-- Bucle principal
refreshFiles()
render()

while true do
    local event, side, x, y = os.pullEvent()
    
    if event == "monitor_touch" then
        handleTouch(x, y)
        render()
    elseif event == "terminate" then
        break
    end
end

monitor.setBackgroundColor(colors.black)
monitor.clear()
monitor.setCursorPos(1, 1)
monitor.setTextColor(colors.white)
monitor.write("Sistema apagado.")
