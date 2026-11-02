-- Estado de interação SIMULADO e puro; não equivale ao layout ou à execução oficial.
-- Nenhum pixel da imagem ou da obra é processado.
local Model = {}
Model.__index = Model

local valid_tools = { brush = true, eraser = true }
local valid_panels = { brush = true, color = true, layer = true }

local function require_screen(self, screen)
    assert(self.screen == screen, "Operação inválida fora da tela: " .. screen)
end

local function uint(value, max)
    return type(value) == "number"
       and value == math.floor(value)
       and value >= 1
       and value <= max
end

function Model.new()
    return setmetatable({
        screen = "title",
        modal = nil,
        document = nil,
        active_tool = nil,
        active_panel = nil,
        brush_size = 1,
        color = { 0, 0, 0 },
        layers = {},
        active_layer_id = nil,
        next_layer_id = 1
    }, Model)
end

function Model:open_gallery()
    assert(self.screen == "title" or self.screen == "editor")
    self.screen = "gallery"
    self.active_panel = nil
    self.modal = nil
end

function Model:open_new_canvas()
    require_screen(self, "gallery")
    self.modal = "new_canvas"
end

function Model:cancel_new_canvas()
    require_screen(self, "gallery")
    assert(self.modal == "new_canvas", "Não há diálogo aberto")
    self.modal = nil
end

function Model:add_layer()
    require_screen(self, "editor")
    local id = self.next_layer_id
    self.next_layer_id = id + 1
    self.layers[#self.layers + 1] = {
        id = id,
        name = "Camada demonstrativa " .. tostring(id),
        visible = true
    }
    self.active_layer_id = id
    return id
end

function Model:create_canvas(width, height)
    require_screen(self, "gallery")
    assert(self.modal == "new_canvas", "Abra o diálogo de nova tela")
    assert(uint(width, 16384) and uint(height, 16384), "Dimensões inválidas")
    self.document = { width = width, height = height, simulated = true }
    self.screen = "editor"
    self.modal = nil
    self.active_tool = "brush"
    self.active_panel = nil
    self.layers = {}
    self.active_layer_id = nil
    self.next_layer_id = 1
    self:add_layer()
end

function Model:set_tool(tool)
    require_screen(self, "editor")
    assert(valid_tools[tool], "Ferramenta não documentada no modelo")
    self.active_tool = tool
end

function Model:toggle_panel(panel)
    require_screen(self, "editor")
    assert(valid_panels[panel], "Painel não documentado no modelo")
    if self.active_panel == panel then
        self.active_panel = nil
    else
        self.active_panel = panel
    end
end

function Model:set_brush_size(size)
    require_screen(self, "editor")
    assert(type(size) == "number" and size == size and size >= 0.1 and size <= 1000,
        "Espessura inválida")
    self.brush_size = size
end

function Model:set_color(r, g, b)
    require_screen(self, "editor")
    for _, c in ipairs({ r, g, b }) do
        assert(type(c) == "number" and c == c and c >= 0 and c <= 255 and c == math.floor(c),
            "Canal de cor inválido")
    end
    self.color = { r, g, b }
end

function Model:toggle_layer_visibility(id)
    require_screen(self, "editor")
    for _, layer in ipairs(self.layers) do
        if layer.id == id then
            layer.visible = not layer.visible
            return layer.visible
        end
    end
    error("Camada inexistente")
end

function Model:select_layer(id)
    require_screen(self, "editor")
    for _, layer in ipairs(self.layers) do
        if layer.id == id then self.active_layer_id = id; return end
    end
    error("Camada inexistente")
end

return Model
