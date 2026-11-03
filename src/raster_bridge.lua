-- Ponte de raster RGBA8 real entre Paint Lua (UI) e Ibis-Rebuild-Windows.
-- O modelo continua responsavel pelos controles; aqui vivem apenas pixels.
-- Estagio 1: pincel/borracha, camadas Normal, undo/redo por pincelada.
local ffi=require('ffi')
local Raster=require('src.engine.raster_lua')
local Bridge={}
Bridge.__index=Bridge
Bridge.MAX_AXIS=2048
Bridge.MAX_HISTORY_BYTES=48*1024*1024
Bridge.MAX_HISTORY_ENTRIES=12

local function validCoord(x,y,w,h)
    return type(x)=='number' and x==x and
        type(y)=='number' and y==y and
        x>=0 and y>=0 and x<w and y<h
end
local function validDim(n)
    return type(n)=='number' and n%1==0 and n>=1 and n<=Bridge.MAX_AXIS
end
local function cap(n,a,b) return math.max(a,math.min(b,n)) end

function Bridge.new(width,height)
    assert(validDim(width) and validDim(height),
        'Motor RGBA suporta documentos de 1..2048 por eixo')
    return setmetatable({
        width=width,height=height,buffers={},meta={},order={},
        composite=Raster.buffer(width,height),pending=nil,
        undoStack={},redoStack={},historyBytes=0,
        dirty=true,texture=nil
    },Bridge)
end
function Bridge:sync(layers)
    assert(type(layers)=='table','Camadas de interface invalidas')
    local previous=self.meta
    local fresh,order,meta={}, {}, {}
    for _,layer in ipairs(layers) do
        assert(type(layer.id)=='number' and not fresh[layer.id],
            'ID de camada duplicado')
        fresh[layer.id]=self.buffers[layer.id] or
            Raster.buffer(self.width,self.height)
        fresh[layer.id].alphaLock=layer.alpha_lock==true
        order[#order+1]=layer.id
        meta[layer.id]={visible=layer.visible~=false,
            opacity=cap((layer.opacity or 100)/100,0,1),
            blend=layer.blending or 'Normal'}
        local old=previous[layer.id]
        if not old or old.visible~=meta[layer.id].visible or
            old.opacity~=meta[layer.id].opacity or
            old.blend~=meta[layer.id].blend then self.dirty=true end
    end
    if #self.order~=#order then self.dirty=true end
    for i,id in ipairs(order) do
        if self.order[i]~=id then self.dirty=true end
    end
    -- Ao remover camadas, remover tambem historico que as referenciava.
    local function filterHistory(stack)
        local kept={}
        for _,entry in ipairs(stack) do
            if fresh[entry.id] then kept[#kept+1]=entry end
        end
        return kept
    end
    self.undoStack=filterHistory(self.undoStack)
    self.redoStack=filterHistory(self.redoStack)
    self.historyBytes=0
    for _,stack in ipairs({self.undoStack,self.redoStack}) do
        for _,entry in ipairs(stack) do
            self.historyBytes=self.historyBytes+entry.size
        end
    end
    self.buffers,self.meta,self.order=fresh,meta,order
end
local function paint(self,x0,y0,x1,y1)
    local p=self.pending
    local buf=self.buffers[p.id]
    if not buf then return end
    Raster.accumulatedStroke(buf,p.before,p.coverage,
        x0,y0,x1,y1,p.size,p.size,p.rgba,
        p.opacity,p.opacity,1,0,0,p.tool=='eraser' and 2 or 0)
    self.dirty=true
end
function Bridge:beginStroke(tool,id,x,y,size,r,g,b,opacity)
    assert(tool=='brush' or tool=='eraser','Ferramenta sem raster nesta ponte')
    assert(self.buffers[id],'Camada ativa inexistente')
    assert(validCoord(x,y,self.width,self.height),'Ponto inicial fora do canvas')
    assert(type(size)=='number' and size>=.1 and size==size,
        'Tamanho de pincel invalido')
    for _,v in ipairs({r,g,b}) do
        assert(type(v)=='number' and v%1==0 and v>=0 and v<=255,
            'Cor RGB invalida')
    end
    assert(type(opacity)=='number' and opacity>=0 and opacity<=1,
        'Opacidade invalida')
    if self.pending then self:finishStroke() end
    local buf=self.buffers[id]
    self.pending={tool=tool,id=id,x=x,y=y,
        size=cap(size,1,256),rgba=r*16777216+g*65536+b*256+255,
        opacity=opacity,before=Raster.bytes(buf),
        coverage=Raster.strokeCoverage(buf)}
    paint(self,x,y,x,y)
    return true
end
function Bridge:moveStroke(x,y)
    local p=self.pending
    if not p then return false end
    assert(type(x)=='number' and x==x and
        type(y)=='number' and y==y,'Ponto invalido')
    x=cap(x,0,self.width-0.001)
    y=cap(y,0,self.height-0.001)
    paint(self,p.x,p.y,x,y)
    p.x,p.y=x,y
    return true
end
function Bridge:finishStroke()
    local p=self.pending
    if not p then return false end
    self.pending=nil
    local buf=self.buffers[p.id]
    if not buf then return false end
    local after=Raster.bytes(buf)
    if after==p.before then return false end
    local entry={id=p.id,before=p.before,after=after,
        size=#after+#p.before}
    -- Um canvas de 2048² ainda cabe no orçamento por pincelada.
    if entry.size<=self.MAX_HISTORY_BYTES then
        for _,old in ipairs(self.redoStack) do
            self.historyBytes=self.historyBytes-old.size
        end
        self.redoStack={}
        while (#self.undoStack>=self.MAX_HISTORY_ENTRIES or
                self.historyBytes+entry.size>self.MAX_HISTORY_BYTES)
                and #self.undoStack>0 do
            local oldest=table.remove(self.undoStack,1)
            self.historyBytes=self.historyBytes-oldest.size
        end
        self.undoStack[#self.undoStack+1]=entry
        self.historyBytes=self.historyBytes+entry.size
    else
        self.undoStack={};self.redoStack={};self.historyBytes=0
    end
    self.dirty=true
    return true
end
local function apply(self,entry,key)
    local b=Raster.buffer(self.width,self.height,entry[key])
    b.alphaLock=self.buffers[entry.id].alphaLock
    self.buffers[entry.id]=b
    self.dirty=true
end
function Bridge:undo()
    self:finishStroke()
    local entry=table.remove(self.undoStack)
    if not entry then return false end
    apply(self,entry,'before')
    self.redoStack[#self.redoStack+1]=entry
    return true
end
function Bridge:redo()
    self:finishStroke()
    local entry=table.remove(self.redoStack)
    if not entry then return false end
    apply(self,entry,'after')
    self.undoStack[#self.undoStack+1]=entry
    return true
end
function Bridge:canUndo() return #self.undoStack>0 end
function Bridge:canRedo() return #self.redoStack>0 end
function Bridge:buffer(id) return self.buffers[id] end
function Bridge:composed()
    if self.dirty then
        Raster.clear(self.composite,0)
        for _,id in ipairs(self.order) do
            local m=self.meta[id]
            if m.visible and m.opacity>0 then
                -- Blend modes alem de Normal continuam simulados na UI.
                Raster.composite(self.composite,self.buffers[id],m.opacity)
            end
        end
    end
    return self.composite
end
function Bridge:image()
    -- ImageData/getFFIPointer sao APIs do LOVE 11.5 (LuaJIT).
    if not self.dirty and self.texture then return self.texture end
    local pixels=self:composed()
    local data=love.image.newImageData(self.width,self.height,'rgba8')
    ffi.copy(data:getFFIPointer(),pixels.bytes,pixels.size)
    if self.texture then self.texture:replacePixels(data)
    else
        self.texture=love.graphics.newImage(data)
        self.texture:setFilter('linear','linear')
    end
    self.dirty=false
    data:release()
    return self.texture
end
return Bridge
