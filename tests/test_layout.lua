package.path='./?.lua;./?/init.lua;'..package.path
local L=require('src.layout')
assert(#L.TOOLS==15 and #L.DOCK==9 and #L.TOP==6)
assert(L.TOOLS[1][1]=='transform' and L.TOOLS[15][1]=='canvas')
for _,size in ipairs({{960,640},{1220,800},{1920,1080}}) do
  local v=L.viewport(size[1],size[2])
  local railBottom=0
  for i=1,15 do
    local r=L.rail(i,'left',v)
    assert(r.y>=railBottom and r.y+r.h<=420)
    assert(L.contains(r,r.x+8,r.y+8))
    railBottom=r.y+r.h
  end
  local rightStart=L.rail(1,'right',v)
  local rightEnd=L.rail(15,'right',v)
  assert(rightStart.y>=56 and rightEnd.y+rightEnd.h<=421,
    'Faixa direita deve ficar abaixo dos comandos superiores e acima dos sliders')
  local last=0
  for i=1,9 do
    local r=L.dock(i,v)
    assert(r.x>=last and r.y>=476 and r.y+r.h<=512)
    last=r.x+r.w
  end
  local t=L.top(6,v);assert(t.x>=0 and t.x+t.w<=v.w)
  for _,name in ipairs({'tools','brushes','layers','color','settings',
    'canvas_new','back','view','selection','stabilizer','shape',
    'ruler','material','properties','blend','filter','text',
    'tool_options'}) do
    local p=L.panel(name,v)
    assert(p.x>=0 and p.x+p.w<=v.w)
    assert(p.y>=0 and p.y+p.h<=v.h)
  end
  local c=L.canvas(v,1.38,1,0,0)
  assert(c.x>45 and c.y>0 and c.x+c.w<v.w)
end
print('OK: 15 ferramentas, 9 comandos, 6 botoes superiores e geometria')
