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
print('OK: ponte raster, pincel, borracha, undo/redo e camadas Normais')
