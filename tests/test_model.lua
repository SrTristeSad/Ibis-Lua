-- Execute: luajit tests/test_model.lua (ou lua5.1).
package.path = "./?.lua;./?/init.lua;" .. package.path
local Model = require("src.model")
local function fails(f)
    local ok = pcall(f)
    assert(not ok, "Era esperado um erro")
end

local s = Model.new()
assert(s.screen == "title")
fails(function() s:open_new_canvas() end)
s:open_gallery()
assert(s.screen == "gallery")
s:open_new_canvas()
assert(s.modal == "new_canvas")
s:cancel_new_canvas()
assert(s.modal == nil)
s:open_new_canvas()
fails(function() s:create_canvas(0, 600) end)
fails(function() s:create_canvas(800.5, 600) end)
s:create_canvas(1024, 768)
assert(s.screen == "editor" and s.document.simulated == true)
assert(s.document.width == 1024 and s.document.height == 768)
assert(s.active_tool == "brush")
assert(#s.layers == 1 and s.active_layer_id == 1)
local documented_tools = {
    "transform", "magic_wand", "lasso", "filter", "brush", "eraser",
    "smudge", "blur", "special_pen", "bucket", "vector", "text",
    "frame_divider", "eyedropper", "canvas"
}
for _, name in ipairs(documented_tools) do
    s:set_tool(name)
    assert(s.active_tool == name)
end
s:set_tool("eraser")
assert(s.active_tool == "eraser")
fails(function() s:set_tool("made_up_tool") end)
s:toggle_panel("layer")
assert(s.active_panel == "layer")
s:toggle_panel("layer")
assert(s.active_panel == nil)
s:set_brush_size(12.5)
assert(s.brush_size == 12.5)
fails(function() s:set_brush_size(-1) end)
s:set_color(22, 83, 145)
assert(s.color[1] == 22 and s.color[3] == 145)
fails(function() s:set_color(300, 0, 0) end)
local id = s:add_layer()
assert(id == 2 and #s.layers == 2)
assert(s:toggle_layer_visibility(id) == false)
assert(s.layers[2].visible == false)
s:select_layer(1)
assert(s.active_layer_id == 1)
fails(function() s:toggle_layer_visibility(999) end)
s:open_gallery()
assert(s.screen == "gallery" and s.active_panel == nil)
s:reopen_canvas(640,480)
assert(s.screen=="editor" and s.document.width==640)
assert(#s.layers==1 and s.layers[1].opacity==100)
s:open_gallery()
fails(function() s:reopen_canvas(0,480) end)
assert(s.screen=="gallery")
-- A57: modelo permite reordenar e excluir sem perder ID nem
-- selecionar uma camada removida; ultima camada e protegida.
local layers=Model.new()
layers:open_gallery();layers:open_new_canvas()
layers:create_canvas(64,64)
assert(not layers:move_layer(1,1),'Mover ultima camada nao altera lista')
local second=layers:add_layer()
local third=layers:add_layer()
assert(second==2 and third==3 and layers.active_layer_id==3)
assert(layers:move_layer(2,1) and
    layers.layers[2].id==3 and layers.layers[3].id==2,
    'Movimento acima precisa manter ID e posicao')
assert(layers:move_layer(2,-1) and
    layers.layers[2].id==2,'Movimento abaixo falhou')
local removed=layers:delete_layer(3)
assert(removed.id==3 and #layers.layers==2 and
    layers.active_layer_id==2,'Excluir ativo precisa selecionar vizinha')
removed=layers:delete_layer(2)
assert(#layers.layers==1 and layers.active_layer_id==1)
fails(function() layers:delete_layer(1) end)
fails(function() layers:move_layer(999,1) end)
fails(function() layers:move_layer(1,2) end)
assert(layers:add_layer()==4,
    'IDs de camada nao podem ser reciclados por exclusao')
print("PASS: modelo simulado (navegação, estado, controles e camadas)")
