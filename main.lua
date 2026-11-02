-- Ponto de entrada novo: propositalmente NÃO representa uma UI do ibisPaint.
-- Tarefas de interface devem começar apenas após referência Windows da versão-alvo.
local Model = require("src.model")
local state = Model.new()
local smoke = os.getenv("IBIS_LUA_SMOKE") == "1"
local capture_requested = false
local capture_pending = false
local capture_done = false
local capture_error = nil

local function queue_capture()
    if capture_pending then return end
    capture_pending = true
    love.graphics.captureScreenshot(function(image)
        local ok, data = pcall(function() return image:encode("png") end)
        if not ok then
            capture_error = tostring(data)
        else
            local wrote, err = love.filesystem.write("ci-smoke.png", data)
            if not wrote then capture_error = tostring(err) end
        end
        capture_pending = false
        capture_done = true
    end)
end

function love.load()
    if smoke then capture_requested = true end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f12" then
        capture_requested = true
    end
end

function love.update()
    if smoke and capture_done then
        if capture_error then error("Captura: " .. capture_error) end
        love.event.quit(0)
    end
end

function love.draw()
    love.graphics.clear(0.08, 0.09, 0.11, 1)
    love.graphics.setColor(0.9, 0.91, 0.93, 1)
    love.graphics.print("IBIS-LUA | DIAGNÓSTICO TÉCNICO", 35, 35)
    love.graphics.setColor(0.68, 0.72, 0.77, 1)
    love.graphics.print("Versão-alvo: ibisPaint para Windows 14.1.4", 35, 70)
    love.graphics.print("UI oficial ainda NÃO reconstruída e NÃO validada.", 35, 96)
    love.graphics.print("F12: captura de diagnóstico   Esc: sair", 35, 144)
    love.graphics.print("Modelo independente: " .. state.screen, 35, 179)

    if capture_requested then
        capture_requested = false
        queue_capture()
    end
end
