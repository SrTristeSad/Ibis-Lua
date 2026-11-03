-- Ponte do formato RBD2 original do Ibis-Rebuild-Windows.
-- Visual e IDs numericos da galeria ficam no Ibis-Lua; arquivos de
-- pixel e revisoes pertencem ao Store original, sem um formato paralelo.
local Store=require('src.engine.store')
local Bridge=require('src.raster_bridge')
local Raster=require('src.engine.raster_lua')
local Project={}
Project.__index=Project
function Project.open(root)
    return setmetatable({store=Store.open(root or 'rbd2-projects')},Project)
end
function Project:list()
    return self.store:listProjects('')
end
local function checkModel(model,engine)
    assert(model and model.screen=='editor' and model.document,
        'Salvamento exige editor aberto')
    assert(engine and engine.width==model.document.width
        and engine.height==model.document.height,
        'Buffer real precisa corresponder ao canvas')
    assert(#model.layers>=1 and #model.layers<=Store.MAX_LAYERS,
        'RBD2 suporta no maximo oito camadas nesta versao')
    for _,layer in ipairs(model.layers) do
        assert(layer.blending=='Normal',
            'RBD2 suporta apenas mesclagem Normal; altere o modo antes de salvar')
    end
    engine:finishStroke()
    engine:sync(model.layers)
end
local function documentLayers(self,record,model,engine)
    local mapping=record and record.layerIds or {}
    local layers={}
    local newMapping={}
    local active
    for i,layer in ipairs(model.layers) do
        local id=mapping[layer.id] or self.store:newLayerId()
        assert(engine:buffer(layer.id),'Camada nao tem buffer RGBA')
        layers[i]={id=id,name=layer.name,visible=layer.visible,
            opacity=layer.opacity/100,
            alpha_lock=layer.alpha_lock==true,
            pixels=Raster.bytes(engine:buffer(layer.id))}
        newMapping[layer.id]=id
        if layer.id==model.active_layer_id then active=i end
    end
    assert(active,'Camada ativa ausente do documento')
    return layers,newMapping,active
end
function Project:save(record,model,engine,name)
    checkModel(model,engine)
    local layers,mapping,active=documentLayers(self,record,model,engine)
    local doc
    if record then
        doc=record.doc
        assert(doc.width==model.document.width and
            doc.height==model.document.height,
            'Documento nao pode mudar de tamanho durante save')
    else
        -- API publicada do Store gera um ID de projeto valido. Converter
        -- o primeiro snapshot RBD1 imediatamente para RBD2 layered.
        doc=self.store:createProject(name or 'Untitled',
            model.document.width,model.document.height,'',
            layers[1].pixels)
    end
    doc.name=name or doc.name
    doc.layers=layers
    doc.pixels=nil
    doc.active_layer=active
    self.store:saveProject(doc)
    return {doc=doc,layerIds=mapping}
end
function Project:load(id,model)
    assert(model and model.screen=='gallery',
        'Abertura de projeto exige galeria')
    local doc=self.store:openProject(id)
    assert(doc.width<=Bridge.MAX_AXIS and
        doc.height<=Bridge.MAX_AXIS,
        'Documento salvo excede o motor raster ativo')
    -- Documentos RBD1 antigos tambem podem ser abertos sem converter
    -- o arquivo ate o proximo save explicito.
    local loaded=doc.layers
    if not loaded then
        loaded={{id=self.store:newLayerId(),name='Raster 1',
            visible=true,opacity=1,alpha_lock=false,pixels=doc.pixels}}
    end
    model:reopen_canvas(doc.width,doc.height)
    model.layers={}
    local ids={}
    for i,layer in ipairs(loaded) do
        model.layers[i]={id=i,name=layer.name,
            visible=layer.visible,
            opacity=math.floor(layer.opacity*100+.5),
            blending='Normal',clipping=false,
            alpha_lock=layer.alpha_lock==true,locked=false}
        ids[i]=layer.id
    end
    model.active_layer_id=doc.active_layer or 1
    model.next_layer_id=#model.layers+1
    local engine=Bridge.new(doc.width,doc.height)
    engine:sync(model.layers)
    for i,layer in ipairs(loaded) do
        engine.buffers[i]=Raster.buffer(doc.width,doc.height,layer.pixels)
        engine.buffers[i].alphaLock=layer.alpha_lock==true
    end
    engine.dirty=true
    return {doc=doc,layerIds=ids},engine
end
return Project
