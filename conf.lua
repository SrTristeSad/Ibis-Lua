-- LÖVE 11.5: ambiente mínimo de diagnóstico; não reproduz UI oficial.
function love.conf(t)
    t.identity = "ibis-lua-fidelity"
    t.version = "11.5"
    t.console = false
    t.window.title = "Ibis-Lua | Diagnóstico (UI ainda não reconstruída)"
    t.window.width = 1024
    t.window.height = 768
    t.window.minwidth = 640
    t.window.minheight = 480
    t.window.resizable = true
    t.window.highdpi = true
    t.window.vsync = 1
end
