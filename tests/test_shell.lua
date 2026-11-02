-- Teste de fluxo com LÖVE simulado. Não comprova renderização real.
package.path='./?.lua;./?/init.lua;'..package.path
local width,height=1220,800
local px,py=0,0
local g={}
for _,name in ipairs({'push','pop','scale','clear','setColor','rectangle',
  'line','circle','arc','ellipse','polygon','setFont','print','printf',
  'translate','setLineWidth','setLineJoin','setLineStyle'}) do
  g[name]=function()end
end
-- Reprodução do contrato real do LÖVE 11.5: 'round' não é válido.
g.setLineJoin=function(style)
  assert(style=='none' or style=='miter' or style=='bevel',
    "setLineJoin inválido: "..tostring(style))
end
g.setLineStyle=function(style)
  assert(style=='rough' or style=='smooth',
    "setLineStyle inválido: "..tostring(style))
end
g.getWidth=function()return width end
g.getHeight=function()return height end
g.newFont=function(size)
  return {getWidth=function(_,s)return #tostring(s)*size*.55 end,
    getHeight=function()return size end}
end
love={graphics=g,mouse={getX=function()return px end,
  getY=function()return py end}}
assert(loadfile('main.lua'))()
love.load()
local function click(logicalX,logicalY)
  local scale=height/512
  px,py=logicalX*scale,logicalY*scale
  love.draw()
  love.mousepressed(px,py,1)
  love.draw()
end
local v=require('src.layout').viewport(width,height)
-- Home > galeria > Nova tela > editor.
love.draw()
click(v.w/2-168,340)
click(40,491)
local p=require('src.layout').panel('canvas_new',v)
click(p.x+p.w-74,p.y+p.h-26)
-- Clica seletor de ferramentas e escolhe borracha.
local dock=require('src.layout').dock(2,v)
click(dock.x+dock.w/2,494)
local tools=require('src.layout').panel('tools',v,2)
local c=require('src.layout').toolCell(tools,6,2)
click(c.x+c.w/2,c.y+c.h/2)
-- Camadas: adicionar, selecionar e fechar.
dock=require('src.layout').dock(8,v)
click(dock.x+dock.w/2,494)
local lay=require('src.layout').panel('layers',v)
click(lay.x+32,lay.y+lay.h-65)
click(lay.x+lay.w-19,lay.y+16)
-- Cor: roda e paleta.
dock=require('src.layout').dock(4,v)
click(dock.x+dock.w/2,494)
local color=require('src.layout').panel('color',v)
click(color.x+115,color.y+116)
click(color.x+color.w-45,color.y+55)
click(color.x+24,color.y+100)
click(color.x+color.w-19,color.y+14)
-- Voltar > configurações > voltar para galeria.
dock=require('src.layout').dock(9,v)
click(dock.x+dock.w/2,494)
local back=require('src.layout').panel('back',v)
click(back.x+50,back.y+114)
local settings=require('src.layout').panel('settings',v)
click(settings.x+40,settings.y+195)
click(settings.x+settings.w-76,settings.y+settings.h-34)
click(dock.x+dock.w/2,494)
back=require('src.layout').panel('back',v)
click(back.x+75,back.y+65)
print('OK: navegação com eventos de clique e render simulado')
