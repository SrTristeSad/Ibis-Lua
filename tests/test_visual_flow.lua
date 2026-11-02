-- Regressao de interface 14.x com LÖVE simulado. Sem renderizador grafico.
package.path='./?.lua;./?/init.lua;'..package.path
local width,height=1220,800
local px,py=0,0
local g={}
local calls={rectangle=0,arc=0,draw=0}
local function finite(v)
  return type(v)=='number' and v==v and v<math.huge and v>-math.huge
end
for _,name in ipairs({'push','pop','scale','clear','ellipse','polygon',
  'setFont','print','printf','translate','line'}) do
  g[name]=function()end
end
g.setColor=function(r,gg,b,a)
  for _,v in ipairs({r,gg,b,a or 1}) do
    assert(finite(v) and v>=0 and v<=1.00001,
      'Canal de cor invalido: '..tostring(v))
  end
end
g.setLineWidth=function(v)
  assert(finite(v) and v>0,'Espessura de linha invalida')
end
g.setLineJoin=function(v)
  assert(v=='none' or v=='miter' or v=='bevel',
    'LineJoin nao suportado por LOVE 11.5')
end
g.setLineStyle=function(v)
  assert(v=='rough' or v=='smooth','LineStyle nao suportado')
end
g.rectangle=function(mode,x,y,w,h)
  assert(mode=='line' or mode=='fill')
  assert(finite(x) and finite(y) and finite(w) and finite(h)
    and w>=0 and h>=0,'Geometria de retangulo invalida')
  calls.rectangle=calls.rectangle+1
end
g.circle=function(mode,x,y,r,n)
  assert(mode=='line' or mode=='fill')
  assert(finite(x) and finite(y) and finite(r) and r>0)
  assert(not n or (type(n)=='number' and n>=3))
end
g.arc=function(mode,arcType,x,y,r,a,b,segments)
  assert(mode=='line' or mode=='fill')
  assert(arcType=='pie' or arcType=='open' or arcType=='closed')
  assert(finite(r) and r>0 and finite(a) and finite(b))
  assert(not segments or segments>=3)
  calls.arc=calls.arc+1
end
local captured
g.captureScreenshot=function(name)
  assert(name:match('^ibis%-lua%-.+%.png$'),'Nome de PNG invalido')
  captured=name
end
g.getWidth=function()return width end
g.getHeight=function()return height end
g.newFont=function(size)
  return {getWidth=function(_,s)return #tostring(s)*size*.55 end,
    getHeight=function()return size end}
end
love={graphics=g,mouse={getX=function()return px end,
  getY=function()return py end},
  filesystem={getSaveDirectory=function()return 'teste' end}}
assert(loadfile('main.lua'))()
love.load()
local L=require('src.layout')
local v=L.viewport(width,height)
local function draw()
  calls.draw=calls.draw+1
  love.draw()
end
local function click(x,y)
  px,py=x*v.scale,y*v.scale
  draw()
  love.mousepressed(px,py,1)
  draw()
end
-- Inicio > galeria > nova tela > editor
draw()
click(v.w/2-125,322)
click(28,486)
local newer=L.panel('canvas_new',v)
click(newer.x+newer.w-55,newer.y+newer.h-25)
-- Biblioteca de pinceis, troca de categoria, filtro de pesquisa
local b=L.dock(3,v)
click(b.x+b.w/2,494)
local p=L.panel('brushes',v)
click(p.x+37,p.y+115+2+4*40+14)
click(p.x+p.w-23,p.y+99)
love.textinput('C')
love.textinput('a')
love.textinput('n')
draw()
love.keypressed('backspace')
love.wheelmoved(0,-1)
draw()
click(p.x+p.w-19,p.y+17)
-- Cores: anel, sliders HSB/RGB, paleta e selecao cromatica
b=L.dock(4,v)
click(b.x+b.w/2,494)
local c=L.panel('color',v)
click(c.x+c.w/2+91,c.y+172)
click(c.x+c.w-44,c.y+290)
click(c.x+c.w-25,c.y+54)
draw()
click(c.x+29,c.y+110)
click(c.x+c.w-19,c.y+14)
-- Camadas: adicionar, fechar
b=L.dock(8,v)
click(b.x+b.w/2,494)
local layers=L.panel('layers',v)
click(layers.x+27,layers.y+layers.h-67)
click(layers.x+layers.w-19,layers.y+14)
-- Opcao de uma coluna, antes sujeita a falha por pagina nil
b=L.dock(9,v)
click(b.x+b.w/2,494)
local back=L.panel('back',v)
click(back.x+45,back.y+113)
local settings=L.panel('settings',v)
click(settings.x+45,settings.y+199)
click(settings.x+settings.w-69,settings.y+settings.h-34)
b=L.dock(2,v)
click(b.x+b.w/2,494)
local tools=L.panel('tools',v,1)
click(tools.x+tools.w-25,tools.y+tools.h-27)
draw()
love.keypressed('f12')
assert(captured and captured:find('tools',1,true),'Captura F12 nao acionada')
assert(calls.rectangle>100 and calls.arc>100 and calls.draw>40,
  'Componentes cromaticos e fluxo de desenho nao executados')
print('OK: fluxo visual 14.x, categorias, cores, ferramentas e validacao de primitivas')
