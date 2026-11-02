-- Geometria de interface. Coordenadas lógicas proporcionais a 512 px de altura.
-- Nenhum elemento desta camada conhece ou modifica pixels de uma obra.
local M = {}
M.TOOLS = {
  {'transform','Transformar'}, {'wand','Varinha Mágica'},
  {'lasso','Laço'}, {'filter','Filtro'}, {'brush','Pincel'},
  {'eraser','Borracha'}, {'smudge','Borrar'}, {'blur','Desfoque'},
  {'special','Caneta especial'}, {'bucket','Balde'},
  {'vector','Vetor'}, {'text','Texto'}, {'frame','Dividir quadros'},
  {'picker','Conta-gotas'}, {'canvas','Tela'}
}
M.DOCK = {'brush-toggle','tool-select','properties','color','fullscreen',
  'undo','redo','layers','back'}
M.TOP = {'view','selection','stabilizer','shape','ruler','material'}
local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end
function M.viewport(width,height)
  assert(type(width)=='number' and type(height)=='number'
    and width>=640 and height>=480, 'Janela menor que 640x480')
  local scale=height/512
  return {w=width/scale,h=512,scale=scale}
end
function M.contains(r,x,y)
  return r and x>=r.x and y>=r.y and x<r.x+r.w and y<r.y+r.h
end
function M.rail(i,position,v)
  assert(i>=1 and i<=#M.TOOLS,'Índice da ferramenta inválido')
  return rect(position=='right' and v.w-49 or 0, 22+(i-1)*26,49,26)
end
function M.dock(i,v)
  assert(i>=1 and i<=#M.DOCK,'Comando inferior inválido')
  local width=50
  local x=(v.w-#M.DOCK*width)/2+(i-1)*width
  return rect(x,478,width,34)
end
function M.top(i,v)
  assert(i>=1 and i<=#M.TOP,'Comando superior inválido')
  return rect(v.w-6*46-10+(i-1)*46,5,41,31)
end
function M.panel(name,v,columns)
  local specs={
    tools={w=258,h=370,side='left'},
    brushes={w=420,h=423,side='left'},
    layers={w=311,h=360,side='right'},
    color={w=371,h=395,side='right'},
    settings={w=445,h=390,side='center'},
    canvas_new={w=409,h=398,side='center'},
    back={w=329,h=220,side='center'},
    view={w=275,h=275,side='right'},
    selection={w=320,h=320,side='right'},
    stabilizer={w=335,h=335,side='right'},
    shape={w=320,h=330,side='right'},
    ruler={w=320,h=350,side='right'},
    material={w=380,h=390,side='right'},
    properties={w=310,h=340,side='left'},
    blend={w=299,h=362,side='right'},
    filter={w=350,h=375,side='left'},
    text={w=350,h=310,side='left'},
    tool_options={w=330,h=335,side='left'},
  }
  local s=assert(specs[name],'Painel desconhecido: '..tostring(name))
  local w=s.w
  if name=='tools' and columns==3 then w=365 end
  if name=='tools' and columns==1 then w=188 end
  local x=s.side=='left' and 54 or s.side=='right' and (v.w-w-12)
    or (v.w-w)/2
  local y=(name=='tools' or name=='brushes' or name=='tool_options')
    and (470-s.h) or math.max(42,(467-s.h)/2)
  return rect(math.max(7,math.min(x,v.w-w-7)),math.max(38,y),w,s.h)
end
function M.toolCell(panel,index,columns)
  columns=columns or 2
  assert(columns>=1 and columns<=3,'Colunas inválidas')
  local cellW=(panel.w-18)/columns
  local col=(index-1)%columns
  local row=math.floor((index-1)/columns)
  return rect(panel.x+9+col*cellW,panel.y+32+row*40,cellW,40)
end
function M.canvas(v,ratio,zoom,panX,panY)
  ratio=ratio or 1.38
  zoom=zoom or 1
  local availW=v.w-132
  local availH=370
  local fitW=math.min(availW,availH*ratio)
  local fitH=fitW/ratio
  local w,h=fitW*zoom,fitH*zoom
  return rect(50+(v.w-50)/2-w/2+(panX or 0),
    226-h/2+(panY or 0),w,h)
end
return M
