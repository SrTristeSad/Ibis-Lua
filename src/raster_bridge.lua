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
    -- A57: jamais descartar historico de um ID que desapareceu.
    -- Um Delete pode ser desfeito, repondo o buffer RGBA removido.
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
-- Pilha cronologica unica: pintura e alteracoes de camada.
-- Retencao e limitada em bytes e em quantidade, inclusive redo.
local function pushHistory(self,entry)
    for _,old in ipairs(self.redoStack) do
        self.historyBytes=self.historyBytes-old.size
    end
    self.redoStack={}
    if entry.size>self.MAX_HISTORY_BYTES then
        self.undoStack={}
        self.historyBytes=0
        return false
    end
    while (#self.undoStack>=self.MAX_HISTORY_ENTRIES or
           self.historyBytes+entry.size>self.MAX_HISTORY_BYTES)
            and #self.undoStack>0 do
        local evicted=table.remove(self.undoStack,1)
        self.historyBytes=self.historyBytes-evicted.size
    end
    self.undoStack[#self.undoStack+1]=entry
    self.historyBytes=self.historyBytes+entry.size
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
    pushHistory(self,entry)
    self.dirty=true
    return true
end
-- Balde do Rebuild: flood-fill contiguo no buffer ativo com undo.
-- Tolerancia inicial 0 enquanto o front-end nao expuser o controle.
function Bridge:bucket(id,x,y,r,g,b,opacity,tolerance)
    assert(self.buffers[id],'Camada ativa inexistente')
    assert(validCoord(x,y,self.width,self.height),
        'Balde fora do canvas')
    for _,v in ipairs({r,g,b}) do
        assert(type(v)=='number' and v%1==0 and v>=0 and v<=255,
            'Cor RGB invalida')
    end
    assert(type(opacity)=='number' and opacity==opacity and
        opacity>=0 and opacity<=1,'Opacidade invalida')
    tolerance=tolerance or 0
    assert(type(tolerance)=='number' and tolerance%1==0 and
        tolerance>=0 and tolerance<=255,'Tolerancia invalida')
    self:finishStroke()
    local layer=self.buffers[id]
    self.pending={id=id,before=Raster.bytes(layer)}
    local rgba=r*16777216+g*65536+b*256+
        math.floor(opacity*255+.5)
    local changed=Raster.bucketFill(layer,
        math.floor(x),math.floor(y),rgba,tolerance)
    if changed>0 then self.dirty=true end
    self:finishStroke()
    return changed
end
-- Conta-gotas amostra a composicao visivel; pixel transparente
-- nao muda a cor selecionada da UI.
function Bridge:pick(x,y)
    assert(validCoord(x,y,self.width,self.height),
        'Conta-gotas fora do canvas')
    local rgba=Raster.readPixel(self:composed(),
        math.floor(x),math.floor(y))
    if rgba%256==0 then return nil end
    return math.floor(rgba/16777216)%256,
        math.floor(rgba/65536)%256,
        math.floor(rgba/256)%256
end
-- A57: snapshots estruturais sao pequenos; pixels sao guardados
-- APENAS para a camada que entrou/saiu, preservando o limite de 48 MiB.
-- IDs existentes mantem seus buffers e suas pinceladas na pilha.
local function cloneLayers(layers)
    local result={}
    for i,layer in ipairs(layers) do
        local copy={}
        for k,v in pairs(layer) do copy[k]=v end
        result[i]=copy
    end
    return result
end
local function layerSnapshot(model)
    local solo={}
    for id,v in pairs(model.solo_before or {}) do solo[id]=v end
    return {layers=cloneLayers(model.layers),
        active=model.active_layer_id,nextId=model.next_layer_id,
        solo=model.solo_layer_id,soloBefore=solo}
end
function Bridge:changeLayer(model,action,id)
    assert(model and model.screen=='editor' and
        model.document.width==self.width and
        model.document.height==self.height,
        'Historico estrutural exige o modelo do canvas ativo')
    assert(action=='add' or action=='delete' or
        action=='up' or action=='down',
        'Operacao estrutural desconhecida')
    self:finishStroke()
    self:sync(model.layers)
    local before=layerSnapshot(model)
    local removed={}
    if action=='delete' then
        assert(#model.layers>1,'Nao e permitido remover a ultima camada')
        assert(self.buffers[id],'Camada inexistente')
        removed[id]=Raster.bytes(self.buffers[id])
    end
    local changed
    if action=='add' then
        changed=model:add_layer()
    elseif action=='delete' then
        changed=model:delete_layer(id)
    else
        changed=model:move_layer(id,action=='up' and 1 or -1)
        if not changed then return false end
    end
    self:sync(model.layers)
    local added={}
    if action=='add' then
        added[changed]=Raster.bytes(self.buffers[changed])
    end
    local payload=192+#before.layers*128
    for _,pixels in pairs(removed) do payload=payload+#pixels end
    for _,pixels in pairs(added) do payload=payload+#pixels end
    local entry={kind='structure',beforeState=before,
        afterState=layerSnapshot(model),
        beforePixels=removed,afterPixels=added,size=payload}
    pushHistory(self,entry)
    self.dirty=true
    return changed
end
local function restoreStructure(self,model,snapshot,pixels)
    model.layers=cloneLayers(snapshot.layers)
    model.active_layer_id=snapshot.active
    model.next_layer_id=snapshot.nextId
    model.solo_layer_id=snapshot.solo
    model.solo_before={}
    for id,value in pairs(snapshot.soloBefore) do
        model.solo_before[id]=value
    end
    self:sync(model.layers)
    for id,raw in pairs(pixels) do
        local buf=Raster.buffer(self.width,self.height,raw)
        for _,layer in ipairs(model.layers) do
            if layer.id==id then
                buf.alphaLock=layer.alpha_lock==true
                break
            end
        end
        self.buffers[id]=buf
    end
    self.dirty=true
end
local function apply(self,entry,key)
    local b=Raster.buffer(self.width,self.height,entry[key])
    b.alphaLock=self.buffers[entry.id].alphaLock
    self.buffers[entry.id]=b
    self.dirty=true
end
function Bridge:undo(model)
    self:finishStroke()
    local entry=self.undoStack[#self.undoStack]
    if not entry then return false end
    if entry.kind=='structure' then
        assert(model and model.screen=='editor',
            'Desfazer camada exige modelo ativo')
        restoreStructure(self,model,entry.beforeState,entry.beforePixels)
    else
        apply(self,entry,'before')
    end
    table.remove(self.undoStack)
    self.redoStack[#self.redoStack+1]=entry
    return true
end
function Bridge:redo(model)
    self:finishStroke()
    local entry=self.redoStack[#self.redoStack]
    if not entry then return false end
    if entry.kind=='structure' then
        assert(model and model.screen=='editor',
            'Refazer camada exige modelo ativo')
        restoreStructure(self,model,entry.afterState,entry.afterPixels)
    else
        apply(self,entry,'after')
    end
    table.remove(self.redoStack)
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
