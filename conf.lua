function love.conf(t)
  t.identity = 'ibis-lua-visual-shell'
  t.version = '11.5'
  t.console = true
  t.window.title = 'Ibis-Lua — Protótipo visual'
  t.window.width, t.window.height = 1220, 800
  t.window.minwidth, t.window.minheight = 800, 600
  t.window.resizable = true
  t.window.highdpi = true
  t.modules.physics = false
  t.modules.audio = false
  t.modules.joystick = false
end
