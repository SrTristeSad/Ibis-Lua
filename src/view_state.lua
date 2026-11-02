-- Estado de visualização, sem edição de pixels nem arquivos.
-- Campos baseados na documentação do View Menu do ibisPaint (Windows).
-- Valores iniciais para os intervalos são demonstrativos, NÃO medidos na 14.1.4.
local ViewState={}
ViewState.__index=ViewState

local function integer(value)
    return type(value)=="number" and value==value
       and value==math.floor(value)
end

function ViewState.new()
    return setmetatable({
        grid=false,
        reference=false,
        manga=false,
        interpolation="smooth",
        invert_wheel=false,
        grid1=64,
        grid2=256,
        offset_x=0,
        offset_y=0
    }, ViewState)
end

function ViewState:toggle_grid()
    self.grid=not self.grid
    return self.grid
end

function ViewState:toggle_reference()
    self.reference=not self.reference
    return self.reference
end

function ViewState:toggle_manga()
    self.manga=not self.manga
    return self.manga
end

function ViewState:toggle_interpolation()
    self.interpolation=self.interpolation=="smooth" and "pixelated" or "smooth"
    return self.interpolation
end

function ViewState:toggle_wheel_direction()
    self.invert_wheel=not self.invert_wheel
    return self.invert_wheel
end

function ViewState:set_interval(which,value)
    assert(which=="grid1" or which=="grid2","Intervalo desconhecido")
    assert(integer(value) and value>=1 and value<=8192,"Intervalo inválido")
    self[which]=value
end

function ViewState:set_origin(x,y)
    assert(integer(x) and integer(y)
      and math.abs(x)<=16384 and math.abs(y)<=16384,
      "Origem da grade inválida")
    self.offset_x=x
    self.offset_y=y
end

function ViewState:reset_grid()
    self.grid1=64
    self.grid2=256
    self.offset_x=0
    self.offset_y=0
end

function ViewState:reset()
    self.grid=false
    self.reference=false
    self.manga=false
    self.interpolation="smooth"
    self.invert_wheel=false
    self:reset_grid()
end

return ViewState
