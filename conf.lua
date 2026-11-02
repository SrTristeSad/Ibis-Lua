-- Janela LÖVE para protótipo visual parcial; consulte docs para restrições.
function love.conf(t)
    t.identity = "ibis-lua-fidelity"
    t.version = "11.5"
    t.console = false
    t.window.title = "Ibis-Lua | Reconstrução visual parcial (não validada)"
    t.window.width = 1024
    t.window.height = 768
    t.window.minwidth = 640
    t.window.minheight = 480
    t.window.resizable = true
    t.window.highdpi = true
    t.window.vsync = 1
end
