-- Integracao do motor real de SrTristeSad/Ibis-Rebuild-Windows.
package.path='./?.lua;./?/init.lua;'..package.path
local Bridge=require('src.raster_bridge')
local Raster=require('src.engine.raster_lua')
local b=Bridge.new(32,24)
local layers={{id=1,visible=true,opacity=100,alpha_lock=false,
    blending='Normal'}}
b:sync(layers)
assert(not b:canUndo() and not b:canRedo())
assert(Raster.readPixel(b:composed(),5,5)==0)
b:beginStroke('brush',1,5.5,5.5,4,255,40,20,1)
b:moveStroke(12.5,5.5)
assert(b:finishStroke())
local painted=Raster.readPixel(b:buffer(1),5,5)
assert(painted~=0 and painted~=0x00000000,
    'Pincel nao produziu pixels RGBA reais')
assert(b:canUndo() and not b:canRedo())
assert(b:undo() and Raster.readPixel(b:buffer(1),5,5)==0,
    'Undo nao recuperou bytes da camada')
assert(b:redo() and Raster.readPixel(b:buffer(1),5,5)==painted,
    'Redo nao recuperou pixels')
b:beginStroke('eraser',1,5.5,5.5,4,0,0,0,1)
assert(b:finishStroke())
assert(Raster.readPixel(b:buffer(1),5,5)==0,
    'Borracha nao removeu alfa')
assert(b:undo() and Raster.readPixel(b:buffer(1),5,5)==painted)
-- Camada superior usa mistura Normal do mesmo rasterizador.
layers[2]={id=2,visible=true,opacity=100,alpha_lock=false,
    blending='Normal'}
b:sync(layers)
b:beginStroke('brush',2,5.5,5.5,3,0,0,255,1)
assert(b:finishStroke())
local above=Raster.readPixel(b:composed(),5,5)
assert(above~=painted,'Compositor nao aplicou a camada superior')
layers[2].visible=false
b:sync(layers)
assert(Raster.readPixel(b:composed(),5,5)==painted,
    'Ocultar camada deve recompor raster')
layers[2].visible=true
layers[2].opacity=0
b:sync(layers)
assert(Raster.readPixel(b:composed(),5,5)==painted,
    'Opacidade zero deve retirar contribuicao da camada')
layers[2].opacity=100
b:sync(layers)
assert(Raster.readPixel(b:composed(),5,5)==above)
-- Estado Alpha Lock e repassado ao buffer nativo.
layers[2].alpha_lock=true
b:sync(layers)
assert(b:buffer(2).alphaLock==true)
assert(not pcall(Bridge.new,2049,5),'Motor nao suporta eixos > 2048')
assert(not pcall(b.beginStroke,b,'bucket',1,2,2,2,0,0,0,1),
    'Ferramenta nao conectada nao deve pintar')
-- Balde e conta-gotas reutilizam os algoritmos Rebuild sem UI duplicada.
local c=Bridge.new(10,10)
c:sync({{id=10,visible=true,opacity=100,
    blending='Normal',alpha_lock=false}})
assert(c:pick(4,4)==nil,'Conta-gotas deve ignorar transparencia')
assert(c:bucket(10,4,4,12,34,56,1,0)==100,
    'Balde contiguo nao preencheu o canvas transparente')
local r,g,blue=c:pick(4,4)
assert(r==12 and g==34 and blue==56,
    'Conta-gotas nao amostrou RGB do compositor')
assert(c:canUndo() and c:undo() and c:pick(4,4)==nil,
    'Undo nao reverteu o balde')
assert(c:redo() and select(1,c:pick(4,4))==12,
    'Redo nao restaurou o balde')
assert(not pcall(c.bucket,c,10,4,4,1,2,3,1,256),
    'Balde deve rejeitar tolerancia invalida')
-- A57: ordem cronologica unificada entre pixels e estrutura.
local Model=require('src.model')
local model=Model.new()
model:open_gallery()
model:open_new_canvas()
model:create_canvas(16,16)
local h=Bridge.new(16,16)
h:sync(model.layers)
h:beginStroke('brush',1,4,4,4,200,20,30,1)
assert(h:finishStroke())
local base=Raster.readPixel(h:buffer(1),4,4)
assert(base~=0)
assert(h:changeLayer(model,'add')==2 and #model.layers==2)
h:beginStroke('brush',2,11,11,3,15,180,240,1)
assert(h:finishStroke())
local colored=Raster.readPixel(h:buffer(2),11,11)
assert(colored~=0)
assert(h:changeLayer(model,'down',2)==true
    and model.layers[1].id==2 and model.layers[2].id==1,
    'Reordenar alterou a camada errada')
local removed=h:changeLayer(model,'delete',2)
assert(removed.id==2 and #model.layers==1 and not h:buffer(2),
    'Excluir camada deve retirar buffer e atualizar lista')
assert(not pcall(h.changeLayer,h,model,'delete',1),
    'Nao pode remover ultima camada')
assert(h:undo(model) and #model.layers==2
    and Raster.readPixel(h:buffer(2),11,11)==colored,
    'Desfazer exclusao perdeu pixels RGBA da camada')
assert(h:undo(model) and model.layers[1].id==1
    and model.layers[2].id==2,
    'Desfazer movimento nao restaurou ordem')
assert(h:undo(model) and
    Raster.readPixel(h:buffer(2),11,11)==0,
    'Desfazer pintura na camada restaurada falhou')
assert(h:undo(model) and #model.layers==1
    and not h:buffer(2) and model.active_layer_id==1,
    'Desfazer adicao nao removeu camada criada')
assert(h:undo(model) and Raster.readPixel(h:buffer(1),4,4)==0,
    'Desfazer inicial nao restaurou base')
assert(not h:canUndo() and h:canRedo())
assert(h:redo(model) and Raster.readPixel(h:buffer(1),4,4)==base)
assert(h:redo(model) and #model.layers==2
    and Raster.readPixel(h:buffer(2),11,11)==0,
    'Refazer adicao deve restaurar a camada VAZIA, nao a pintura futura')
assert(h:redo(model) and
    Raster.readPixel(h:buffer(2),11,11)==colored,
    'Refazer pintura deve recuperar seus bytes')
assert(h:redo(model) and model.layers[1].id==2)
assert(h:redo(model) and #model.layers==1
    and not h:buffer(2) and not h:canRedo(),
    'Refazer exclusao deve deixar somente a base')
assert(h.historyBytes<=h.MAX_HISTORY_BYTES and
    #h.undoStack<=h.MAX_HISTORY_ENTRIES,
    'Historico estrutural deve cumprir limites de memoria')
-- Undo de Delete e nova pintura devem limpar Redo futuro.
assert(h:undo(model) and #model.layers==2)
h:beginStroke('brush',2,8,8,2,80,20,10,1)
assert(h:finishStroke() and not h:canRedo(),
    'Novo traco apos undo precisa invalidar redo')
-- Metadata e ID precisam retornar ao estado anterior a exclusao.
assert(h:changeLayer(model,'up',2))
assert(h:undo(model) and model.active_layer_id==1)
assert(not h:changeLayer(model,'up',1),
    'Mover camada alem da borda superior nao deve gerar registro')
print('OK: RGBA + historico unificado de tracos, camada, exclusao e ordem')


