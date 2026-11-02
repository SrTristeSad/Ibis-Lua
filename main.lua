-- Ibis-Lua: reprodução independente da casca visual do ibisPaint.
-- SEM motor de desenho, exportação, leitura de .ipv ou salvamento de pixels.
local Layout=require('src.layout')
local UI=require('src.ui')
local Icons=require('src.icons')
local lg=love.graphics
local S={screen='home',popup=nil,tool='brush',rail='left',columns=2,
  showLabels=true,fullscreen=false,zoom=1,panX=0,panY=0,
  size=6.6,opacity=100,hue=210,saturation=.7,brightness=.95,
  selectedLayer=1,layerOpacity=100,brush='Caneta (Dura)',
  colorTab='HSB',colorValue={.18,.51,.91},
  works={},project=nil,layers={},canvasPreset=1,
  optionChoice=1,collectionTab='Básico',drag=nil}
local V
local function inside(r,x,y) return Layout.contains(r,x,y) end
local function open(kind) S.popup=kind end
local function close() S.popup=nil end
local function newLayers()
  S.layers={{name='1',visible=true,opacity=100}}
  S.selectedLayer=1
end
local function openEditor(work)
  S.screen='editor';S.project=work;S.zoom=1;S.panX=0;S.panY=0
  S.tool='brush';S.fullscreen=false;close();newLayers()
end
local function createWork()
  local presets={{1280,920},{1280,1280},{1920,1080},{1080,1920},{512,512}}
  local dim=presets[S.canvasPreset]
  local work={name='Sem título '..(#S.works+1),width=dim[1],height=dim[2]}
  S.works[#S.works+1]=work
  openEditor(work)
end
local function pickTool(id)
  S.tool=id
  close()
end
local function hsv(h,s,v)
  local i=math.floor((h%360)/60)
  local f=(h/60)-math.floor(h/60)
  local p=v*(1-s);local q=v*(1-f*s);local t=v*(1-(1-f)*s)
  if i==0 then return {v,t,p} elseif i==1 then return {q,v,p}
  elseif i==2 then return {p,v,t} elseif i==3 then return {p,q,v}
  elseif i==4 then return {t,p,v} end
  return {v,p,q}
end
local function glyph(id,x,y,d,color)
  local rgb=UI.colors[color or 'white'] or UI.colors.white
  Icons.draw(id,x,y,d,rgb[1],rgb[2],rgb[3])
end
local function iconAction(id,rect,fn,selected,bg)
  if bg then UI.rect(rect.x,rect.y,rect.w,rect.h,bg,4) end
  if selected then UI.rect(rect.x+3,rect.y+2,rect.w-6,rect.h-4,'panel2',4) end
  glyph(id,rect.x+rect.w/2,rect.y+rect.h/2,22,
    selected and 'blue' or 'white')
  UI.hit(rect,fn)
end
local function sectionLine(x,y,w) UI.line(x,y,x+w,y,'line') end
local function wheelLogo(cx,cy,r)
  for i=0,11 do
    local a=(i/12)*math.pi*2
    UI.color(hsv(i*30,.8,.95))
    lg.arc('fill','pie',cx,cy,r,a+.02,a+.47,12)
  end
  UI.color('white');lg.circle('fill',cx,cy,r*.46,28)
  UI.color('dark');lg.circle('fill',cx,cy,r*.22,28)
end
local function drawHome()
  -- Composição baseada na tela de entrada do ibisPaint 14.x:
  -- azul profundo, logo central, galeria local/online e ranking inferior.
  lg.clear(.145,.302,.458,1)
  local w=V.w
  local headerY=math.max(104,math.min(141,V.h*.25))
  UI.color({.99,.79,.17});lg.circle('fill',w-88,22,12,28)
  UI.text('P',w-95,12,16,'white','center',14)
  UI.color('white');lg.circle('line',w-52,22,12,26)
  UI.text('?',w-59,12,16,'white','center',14)
  glyph('settings',w-20,22,22)
  UI.hit({x=w-44,y=0,w=44,h=44},function()open('settings')end)
  local logoFont=math.min(70,math.floor(w*.092))
  local f=UI.font(logoFont)
  local ibisW,aintW=f:getWidth('ibis'),f:getWidth('aint')
  local wheelWidth=logoFont*.94
  local left=(w-(ibisW+wheelWidth+aintW))/2
  UI.text('ibis',left,headerY,logoFont,'white')
  wheelLogo(left+ibisW+wheelWidth/2,headerY+logoFont*.49,wheelWidth*.46)
  UI.text('aint',left+ibisW+wheelWidth,headerY,logoFont,'white')
  UI.text('Ver.14.1.2',left+ibisW+wheelWidth+aintW-74,
    headerY+logoFont+3,11,'white')
  local y=322
  local positions={w/2-125,w/2+125}
  for i,item in ipairs({{'Minha Galeria','brush'},{'Galeria Online','globe'}}) do
    local cx=positions[i]
    UI.color({.91,.94,.97});lg.setLineWidth(1)
    lg.circle('line',cx,y,44,52)
    glyph(item[2],cx,y,42)
    UI.text(item[1],cx-85,y+54,14,'white','center',170)
    UI.hit({x=cx-80,y=y-49,w=160,h=120},function()
      if i==1 then S.screen='gallery';close()
      else open('online') end
    end)
  end
  local rankY=420
  UI.rect(0,rankY,w,92,{.09,.20,.33})
  UI.text('Ranking diário',20,rankY+9,14,'white')
  UI.text('⌃',w-35,rankY+4,22,'white')
  local count=math.max(2,math.floor((w-40)/120))
  for i=1,count do
    local xx=20+(i-1)*(w-40)/count
    UI.rect(xx,rankY+34,math.min(105,(w-52)/count-5),56,{.96,.96,.97},1)
  end
end
local function drawGallery()
  lg.clear(.935,.938,.945,1)
  local w=V.w
  UI.rect(0,0,w,54,{.99,.99,.99})
  glyph('back',28,27,22,'ink')
  UI.text('A Minha Galeria',61,14,22,'ink')
  UI.hit({x=0,y=0,w=50,h=54},function()S.screen='home' end)
  UI.rect(0,54,w,1,'line')
  if #S.works==0 then
    UI.text('Nenhuma obra',0,190,23,'ink','center',w)
    UI.text('Toque em + para criar uma nova tela.',0,222,14,'ink','center',w)
  else
    local cols=math.max(1,math.floor((w-35)/166))
    for i,work in ipairs(S.works) do
      local col=(i-1)%cols
      local row=math.floor((i-1)/cols)
      local x=19+col*166;local y=73+row*173
      UI.rect(x,y,150,156,'white',3)
      UI.rect(x+6,y+6,138,111,'gallery')
      UI.checker(x+28,y+20,94,82,9)
      UI.rect(x+27,y+19,96,84,'line',1,true)
      UI.text(work.name,x+10,y+122,13,'ink')
      UI.text(work.width..' × '..work.height,x+10,y+139,10,'ink')
      UI.hit({x=x,y=y,w=150,h=156},function()openEditor(work)end)
    end
  end
  UI.rect(0,471,w,41,'white')
  UI.button('+',18,478,53,29,function()S.canvasPreset=1;open('canvas_new')end,
    {bg='blue',font=24})
  UI.text('Selecionar',w-132,483,14,'ink')
  UI.hit({x=w-155,y=471,w=155,h=41},function()open('gallery_selection')end)
end
local function drawCanvas()
  local work=S.project or {width=1280,height=920}
  local r=Layout.canvas(V,work.width/work.height,S.zoom,S.panX,S.panY)
  UI.rect(r.x+2,r.y+3,r.w,r.h,'dark',1)
  UI.rect(r.x,r.y,r.w,r.h,'paper',1)
  UI.rect(r.x,r.y,r.w,r.h,{.93,.93,.93},0,true)
  return r
end
local function drawRail()
  if S.rail=='popup' then return end
  local x=S.rail=='right' and V.w-49 or 0
  local first=Layout.rail(1,S.rail,V)
  local last=Layout.rail(#Layout.TOOLS,S.rail,V)
  UI.rect(x,first.y,49,last.y+last.h-first.y,{.45,.46,.47,.92},2)
  for i,item in ipairs(Layout.TOOLS) do
    local r=Layout.rail(i,S.rail,V)
    local active=S.tool==item[1]
    if active then UI.rect(r.x+2,r.y+1,45,r.h-1,{.57,.60,.63,.8},2) end
    glyph(item[1],r.x+24,r.y+9,17,active and 'blue' or 'white')
    if S.showLabels then
      local label=item[2]
      local font=#label>13 and 6 or 7
      UI.text(label,r.x+1,r.y+17,font,active and 'blue' or 'white',
        'center',47)
    end
    UI.hit(r,function()pickTool(item[1])end)
  end
end
local function drawTop()
  for i,id in ipairs(Layout.TOP) do
    local r=Layout.top(i,V)
    UI.rect(r.x,r.y,r.w,r.h,'dark',17)
    glyph(id,r.x+r.w/2,r.y+r.h/2,21)
    UI.hit(r,function()open(id)end)
  end
end
local function drawEditor()
  lg.clear(.745,.749,.753,1)
  local w=V.w
  drawCanvas()
  if S.fullscreen then
    UI.rect(8,7,54,26,'toolbar',4)
    UI.text('Voltar',11,12,13,'white')
    UI.hit({x=8,y=7,w=65,h=28},function()S.fullscreen=false end)
    return
  end
  drawTop()
  drawRail()
  -- Dois controles horizontais conforme a referência do editor Android.
  local sx=(w-385)/2
  for i,kind in ipairs({'size','opacity'}) do
    local y=i==1 and 425 or 448
    local value=kind=='size' and S.size or S.opacity
    UI.text(kind=='size' and ('%.1f'):format(value) or tostring(value),
      sx-35,y+2,10,'ink')
    UI.rect(sx-11,y+2,19,19,'dark',10)
    UI.text('−',sx-11,y,16,'white','center',19)
    UI.hit({x=sx-11,y=y,w=19,h=21},function()
      if kind=='size' then S.size=math.max(.1,S.size-1)
      else S.opacity=math.max(1,S.opacity-5) end
    end)
    UI.slider(sx+21,y+4,285,kind=='size' and (S.size/100) or
      (S.opacity/100),function(t)
      if kind=='size' then S.size=math.floor((.1+t*99.9)*10)/10
      else S.opacity=math.floor(t*100+.5) end
    end,{track='line',fill='white'})
    UI.rect(sx+319,y+2,19,19,'dark',10)
    UI.text('+',sx+319,y+1,15,'white','center',19)
    UI.hit({x=sx+319,y=y,w=19,h=21},function()
      if kind=='size' then S.size=math.min(100,S.size+1)
      else S.opacity=math.min(100,S.opacity+5) end
    end)
  end
  UI.rect(0,476,w,36,'toolbar')
  for i,id in ipairs(Layout.DOCK) do
    local r=Layout.dock(i,V)
    if i>1 then UI.line(r.x,483,r.x,505,'line') end
    if id=='color' then
      local col=S.colorValue
      UI.rect(r.x+r.w/2-10,r.y+8,20,17,col,1)
      UI.rect(r.x+r.w/2-10,r.y+8,20,17,'soft',0,true)
      UI.hit(r,function()open('color')end)
    else
      iconAction(id,r,function()
        if id=='brush-toggle' then
          pickTool(S.tool=='eraser' and 'brush' or 'eraser')
        elseif id=='tool-select' then open('tools')
        elseif id=='properties' then
          open((S.tool=='brush' or S.tool=='eraser') and 'brushes'
            or 'tool_options')
        elseif id=='fullscreen' then S.fullscreen=true
        elseif id=='layers' then open('layers')
        elseif id=='back' then open('back')
        elseif id=='undo' or id=='redo' then
          -- A casca não possui histórico de pintura. Intencionalmente vazio.
        end
      end,false)
    end
  end
end
local function panelBase(kind,title)
  local p=Layout.panel(kind,V,S.columns)
  -- Interceptar cliques externos antes de renderizar hitboxes do painel.
  UI.hit({x=0,y=0,w=V.w,h=V.h},close)
  UI.hit(p,function()end)
  UI.frame(p.x,p.y,p.w,p.h,title,close)
  return p
end
local function drawTools()
  local p=panelBase('tools','Ferramentas')
  local first=S.columns==1 and ((S.toolPage-1)*7+1) or 1
  local last=S.columns==1 and math.min(15,first+6) or 15
  for i=first,last do
    local item=Layout.TOOLS[i]
    local c=Layout.toolCell(p,i-first+1,S.columns)
    local active=S.tool==item[1]
    if active then UI.rect(c.x,c.y,c.w-1,c.h-1,'panel2',3) end
    glyph(item[1],c.x+c.w/2,c.y+12,21,active and 'blue' or 'white')
    UI.text(item[2],c.x+1,c.y+26,9,'white','center',c.w-2)
    UI.hit(c,function()pickTool(item[1])end)
  end
  if S.columns==1 then
    local y=p.y+p.h-42
    UI.button('‹',p.x+8,y,43,29,function()
      S.toolPage=math.max(1,S.toolPage-1) end,{font=18})
    UI.text(S.toolPage..' / 3',p.x+58,y+8,11,'white')
    UI.button('›',p.x+p.w-52,y,43,29,function()
      S.toolPage=math.min(3,S.toolPage+1) end,{font=18})
  end
end
local function drawBrushes()
  local p=panelBase('brushes','Pincel ('..S.brush..')')
  -- Interface 14.x: categorias verticais escuras, prévia e itens claros.
  local side=p.x+9
  UI.rect(p.x+9,p.y+34,p.w-18,p.h-126,{.96,.96,.96},1)
  UI.rect(side,p.y+88,72,p.h-215,{.055,.059,.063},1)
  local contentX=p.x+86
  local contentW=p.w-98
  UI.checker(contentX,p.y+39,contentW,45,8)
  UI.color('ink');lg.setLineWidth(3)
  local wave={}
  for i=0,34 do
    wave[#wave+1]=contentX+10+i*(contentW-20)/34
    wave[#wave+1]=p.y+61+math.sin(i*.29)*6
  end
  lg.line(wave)
  local tabs={'Básico','Personalizado','Online'}
  for i,title in ipairs(tabs) do
    local tw=(contentW-7)/3
    local tx=contentX+(i-1)*tw
    UI.rect(tx,p.y+89,tw-1,25,
      S.collectionTab==title and 'white' or {.68,.68,.68},1)
    UI.text(title,tx+1,p.y+95,10,'ink','center',tw-2)
    UI.hit({x=tx,y=p.y+89,w=tw,h=26},
      function()S.collectionTab=title end)
  end
  local categories={'Todos','Simples','Esboço','Quadrinho','Tinta','Vetor',
    'Aerógrafo'}
  S.brushCategory=S.brushCategory or 'Todos'
  for i,title in ipairs(categories) do
    local yy=p.y+120+(i-1)*26
    if title==S.brushCategory then
      UI.rect(side+1,yy,70,25,{.20,.30,.37},1)
    end
    UI.text(title,side+2,yy+7,9,
      title==S.brushCategory and 'blue' or 'white','center',68)
    UI.hit({x=side,y=yy,w=72,h=26},function()S.brushCategory=title end)
  end
  local brushes={
    {'Caneta (Dura)','Simples'},{'Caneta (Suave)','Simples'},
    {'Caneta (Tinta)','Tinta'},{'Lápis (Grafite)','Esboço'},
    {'Pincel (Duro)','Tinta'},{'Aerógrafo (Normal)','Aerógrafo'},
    {'Caneta Vetorial','Vetor'},{'Caneta para mangá','Quadrinho'}}
  if S.collectionTab=='Básico' then
    local visible=0
    for i,item in ipairs(brushes) do
      if S.brushCategory=='Todos' or S.brushCategory==item[2] then
        visible=visible+1
        if visible<=6 then
          local y=p.y+118+(visible-1)*32
          UI.rect(contentX,y,contentW,31,
            S.brush==item[1] and {.79,.87,.97} or 'white',1)
          UI.line(contentX,y+31,contentX+contentW,y+31,{.80,.80,.80},.65)
          UI.color('ink');lg.setLineWidth(1+visible*.25)
          local pts={}
          for k=0,22 do
            pts[#pts+1]=contentX+6+k*2.3
            pts[#pts+1]=y+19+math.sin(k*.33)*4
          end
          lg.line(pts)
          UI.text(item[1],contentX+64,y+8,10,'ink')
          UI.text('›',contentX+contentW-18,y+4,18,'ink')
          UI.hit({x=contentX,y=y,w=contentW,h=31},function()
            S.brush=item[1];S.optionChoice=i
          end)
        end
      end
    end
  else
    UI.text(S.collectionTab=='Personalizado' and 'Sem pincéis personalizados'
      or 'Biblioteca online indisponível',contentX+7,p.y+138,11,'ink')
  end
  local fy=p.y+p.h-126
  UI.rect(p.x+9,fy,p.w-18,126,'toolbar',1)
  UI.text(('Tamanho     %.1f px'):format(S.size),p.x+20,fy+12,11,'white')
  UI.slider(p.x+134,fy+12,p.w-158,S.size/100,
    function(t)S.size=math.floor((.1+t*99.9)*10)/10 end)
  UI.text(('Opacidade  %d%%'):format(S.opacity),p.x+20,fy+48,11,'white')
  UI.slider(p.x+134,fy+48,p.w-158,S.opacity/100,
    function(t)S.opacity=math.floor(t*100+.5)end)
end
local function drawLayers()
  local p=panelBase('layers','Camadas')
  local x=p.x+9
  local mainW=p.w-66
  local contentY=p.y+35
  -- Miniaturas claras, seleção azul e barra vertical preta.
  UI.rect(x,contentY,mainW,p.h-126,{.94,.94,.94},1)
  UI.rect(x+mainW,contentY,42,p.h-126,{.055,.06,.065},1)
  UI.rect(x,contentY,mainW,49,{.89,.89,.89},1)
  UI.checker(x+5,contentY+6,38,37,7)
  UI.rect(x+5,contentY+6,38,37,{1,.6,.72,.7})
  UI.text('Camada de seleção',x+52,contentY+7,11,'ink')
  UI.text('Sem seleção',x+52,contentY+26,10,'ink')
  local count=math.min(#S.layers,3)
  for i=1,count do
    local index=#S.layers-i+1
    local layer=S.layers[index]
    local y=contentY+50+(i-1)*50
    UI.rect(x,y,mainW,49,
      index==S.selectedLayer and {.79,.86,.96} or {.94,.94,.94},1)
    UI.line(x,y+49,x+mainW,y+49,{.73,.73,.73},.6)
    UI.checker(x+6,y+6,41,38,7)
    UI.rect(x+6,y+6,41,38,
      index==S.selectedLayer and 'blue' or {.74,.74,.74},0,true)
    UI.text(layer.name,x+54,y+4,13,'ink')
    glyph('eye',x+68,y+32,16,layer.visible and 'ink' or 'soft')
    UI.text(('%d%%'):format(layer.opacity),x+111,y+24,11,'ink')
    UI.text('Normal',x+162,y+24,10,'ink')
    UI.hit({x=x+50,y=y,w=mainW-50,h=49},
      function()S.selectedLayer=index end)
    UI.hit({x=x+52,y=y+23,w=32,h=25},
      function()layer.visible=not layer.visible end)
  end
  local barX=x+mainW
  for i,id in ipairs({'layers','plus','transform','selection','eye','menu'}) do
    local yy=contentY+4+(i-1)*32
    glyph(id,barX+21,yy+12,17)
    UI.hit({x=barX,y=yy,w=42,h=32},function()
      if id=='plus' then
        local index=#S.layers+1
        S.layers[index]={name=tostring(index),visible=true,opacity=100}
        S.selectedLayer=index
      elseif id=='menu' then open('blend') end
    end)
  end
  local fy=p.y+p.h-91
  UI.rect(x,fy,p.w-18,85,'toolbar',1)
  UI.button('+',x+4,fy+9,44,29,function()
    local index=#S.layers+1
    S.layers[index]={name=tostring(index),visible=true,opacity=100}
    S.selectedLayer=index
  end,{font=22,bg='dark'})
  UI.button('Duplicar',x+54,fy+9,69,29,function()
    local layer=S.layers[S.selectedLayer]
    local index=#S.layers+1
    S.layers[index]={name=layer.name..' cópia',visible=layer.visible,
      opacity=layer.opacity}
    S.selectedLayer=index
  end,{font=11,bg='dark'})
  UI.button('Excluir',x+129,fy+9,61,29,function()
    if #S.layers>1 then table.remove(S.layers,S.selectedLayer)
      S.selectedLayer=math.min(#S.layers,S.selectedLayer) end
  end,{font=11,bg='dark'})
  UI.button('Normal ▾',x+195,fy+9,92,29,
    function()open('blend')end,{font=10,bg='dark'})
  UI.text('100%',x+7,fy+52,10,'white')
  local current=S.layers[S.selectedLayer]
  UI.slider(x+62,fy+48,p.w-91,current.opacity/100,function(t)
    current.opacity=math.floor(100*t+.5)
  end)
end
local function drawColor()
  local p=panelBase('color','Cor')
  local rgb=S.colorValue
  UI.rect(p.x+12,p.y+39,62,28,rgb,2)
  UI.rect(p.x+83,p.y+39,62,28,'white',2)
  UI.text('Atual',p.x+14,p.y+70,10,'soft')
  UI.text('Anterior',p.x+88,p.y+70,10,'soft')
  UI.button(S.colorTab=='HSB' and 'Paleta' or 'HSB',p.x+p.w-92,p.y+42,78,27,
    function()S.colorTab=S.colorTab=='HSB' and 'Paleta' or 'HSB' end,{font=11})
  if S.colorTab=='Paleta' then
    for row=0,5 do for col=0,8 do
      local hue=(row*9+col)*360/54
      local c=hsv(hue,.65,.96)
      local x,y=p.x+19+col*37,p.y+92+row*35
      UI.rect(x,y,31,30,c,2)
      UI.hit({x=x,y=y,w=31,h=30},function()
        S.hue=hue;S.colorValue=c
      end)
    end end
    UI.text('Histórico de cores',p.x+18,p.y+331,12,'white')
    return
  end
  local cx=p.x+115;local cy=p.y+192
  for i=0,71 do
    local a=i*math.pi/36;local b=(i+1)*math.pi/36
    UI.color(hsv(i*5,.96,1))
    lg.setLineWidth(18)
    lg.line(cx+math.cos(a)*76,cy+math.sin(a)*76,
      cx+math.cos(b)*76,cy+math.sin(b)*76)
  end
  -- Losango HSB: amostragem cromática apenas para apresentação.
  for yy=-44,44,3 do for xx=-44,44,3 do
    if math.abs(xx)+math.abs(yy)<=43 then
      local ss=math.max(0,math.min(1,(xx+44)/88))
      local vv=math.max(0,math.min(1,(44-yy)/88))
      UI.color(hsv(S.hue,ss,vv))
      lg.rectangle('fill',cx+xx,cy+yy,3.3,3.3)
    end
  end end
  UI.hit({x=cx-90,y=cy-90,w=180,h=180},function()
    local mx=love.mouse.getX()/V.scale
    local my=love.mouse.getY()/V.scale
    local dx,dy=mx-cx,my-cy
    local d=math.sqrt(dx*dx+dy*dy)
    if d>59 and d<96 then
      S.hue=(math.deg(math.atan2 and math.atan2(dy,dx) or
        math.atan(dy,dx))+360)%360
    elseif math.abs(dx)+math.abs(dy)<=45 then
      S.saturation=math.max(0,math.min(1,(dx+44)/88))
      S.brightness=math.max(0,math.min(1,(44-dy)/88))
    end
    S.colorValue=hsv(S.hue,S.saturation,S.brightness)
  end)
  local sx=p.x+223;local sy=p.y+114
  for i,lab in ipairs({'H','S','B','A'}) do
    local y=sy+(i-1)*48
    UI.text(lab,sx,y,12,'white')
    local t=lab=='H' and S.hue/360 or lab=='S' and S.saturation
      or lab=='B' and S.brightness or S.opacity/100
    UI.slider(sx+24,y,p.w-252,t,function(v)
      if lab=='H' then S.hue=v*360
      elseif lab=='S' then S.saturation=v
      elseif lab=='B' then S.brightness=v
      else S.opacity=math.floor(v*100+.5) end
      S.colorValue=hsv(S.hue,S.saturation,S.brightness)
    end)
  end
  UI.text('HEX   #'..('%.2X%.2X%.2X'):format(math.floor(rgb[1]*255),
    math.floor(rgb[2]*255),math.floor(rgb[3]*255)),
    p.x+20,p.y+p.h-39,12,'white')
end
local function drawSettings()
  local p=panelBase('settings','Configurações')
  UI.text('INTERFACE DO USUÁRIO',p.x+21,p.y+47,12,'soft')
  UI.text('Posição da seleção de ferramentas',p.x+21,p.y+78,13,'white')
  for i,choice in ipairs({{'left','Esquerda'},{'right','Direita'},
    {'popup','Popup'}}) do
    UI.button(choice[2],p.x+21+(i-1)*138,p.y+103,129,34,
      function() S.rail=choice[1] end,
      {bg=S.rail==choice[1] and 'blue' or 'panel2',font=12})
  end
  UI.text('Número de colunas do seletor',p.x+21,p.y+159,13,'white')
  for i=1,3 do
    UI.button(tostring(i),p.x+21+(i-1)*138,p.y+184,129,34,
      function()S.columns=i end,
      {bg=S.columns==i and 'blue' or 'panel2'})
  end
  UI.text('Mostrar nomes das ferramentas',p.x+21,p.y+237,13,'white')
  UI.button('Ativado',p.x+21,p.y+263,197,34,
    function()S.showLabels=true end,
    {bg=S.showLabels and 'blue' or 'panel2'})
  UI.button('Desativado',p.x+226,p.y+263,197,34,
    function()S.showLabels=false end,
    {bg=not S.showLabels and 'blue' or 'panel2'})
  UI.button('Concluir',p.x+p.w-136,p.y+p.h-53,120,36,close,{bg='blue'})
end
local function drawNewCanvas()
  local p=panelBase('canvas_new','Nova tela')
  UI.text('Escolha o tamanho da tela',p.x+17,p.y+44,13,'white')
  local sizes={{1280,920,'Padrão'},{1280,1280,'Quadrado'},
    {1920,1080,'Paisagem'},{1080,1920,'Retrato'},
    {512,512,'Pequeno'}}
  for i,preset in ipairs(sizes) do
    local y=p.y+74+(i-1)*48
    UI.button(preset[3]..'     '..preset[1]..' × '..preset[2],
      p.x+16,y,p.w-32,41,function()S.canvasPreset=i end,
      {bg=S.canvasPreset==i and 'blue' or 'panel2',font=12})
  end
  UI.text('Prévia do formato',p.x+18,p.y+326,11,'soft')
  local dim=sizes[S.canvasPreset]
  local width=dim[1]/math.max(dim[1],dim[2])*34
  local height=dim[2]/math.max(dim[1],dim[2])*26
  UI.rect(p.x+154,p.y+318,width,height,'white',1)
  UI.button('Cancelar',p.x+18,p.y+p.h-44,115,32,close)
  UI.button('OK',p.x+p.w-129,p.y+p.h-44,111,32,createWork,{bg='blue'})
end
local function drawBack()
  local p=panelBase('back','Voltar')
  UI.button('Voltar para A Minha Galeria',p.x+18,p.y+47,p.w-36,40,
    function()S.screen='gallery';close()end)
  UI.button('Configurações',p.x+18,p.y+95,p.w-36,40,
    function()open('settings')end)
  UI.button('Cancelar',p.x+18,p.y+143,p.w-36,40,close)
end
local function drawBlend()
  local p=panelBase('blend','Modo de mesclagem')
  local names={'Normal','Multiplicar','Tela','Sobrepor','Adicionar',
    'Subtrair','Escurecer','Clarear'}
  for i,name in ipairs(names) do
    local y=p.y+40+(i-1)*36
    UI.rect(p.x+10,y,p.w-20,34,i==1 and 'panel2' or 'panel',2)
    UI.text(name,p.x+24,y+8,12,i==1 and 'white' or 'soft')
    if i==1 then
      UI.hit({x=p.x+10,y=y,w=p.w-20,h=34},function()open('layers')end)
    end
  end
end
local function drawSimple(kind)
  local titles={view='Visualização',selection='Área de seleção',
    stabilizer='Estabilizador',shape='Formas',ruler='Réguas',
    material='Materiais',properties='Propriedades',
    filter='Filtros',text='Texto',tool_options='Opções da ferramenta'}
  local p=panelBase(kind,titles[kind] or kind)
  if kind=='view' then
    UI.button('Encaixar na tela',p.x+15,p.y+47,p.w-30,34,
      function()S.zoom=1;S.panX=0;S.panY=0 end)
    UI.button('−',p.x+15,p.y+98,43,34,function()
      S.zoom=math.max(.25,S.zoom/1.25)end)
    UI.text(('Zoom   %d%%'):format(S.zoom*100),p.x+77,p.y+108,13,'white')
    UI.button('+',p.x+p.w-58,p.y+98,43,34,function()
      S.zoom=math.min(3,S.zoom*1.25)end)
    UI.button('Visualização em tela cheia',p.x+15,p.y+153,p.w-30,36,
      function()S.fullscreen=true;close()end)
  elseif kind=='stabilizer' then
    UI.text('Estabilizador',p.x+15,p.y+55,14,'white')
    UI.slider(p.x+25,p.y+97,p.w-50,(S.optionChoice-1)/9,function(t)
      S.optionChoice=1+math.floor(t*9+.5) end)
    UI.text('Intensidade     '..S.optionChoice,p.x+17,p.y+132,12,'soft')
    UI.button('Desenho em tempo real',p.x+15,p.y+169,p.w-30,36,
      function()S.optionChoice=1 end)
    UI.button('Depois de desenhar',p.x+15,p.y+212,p.w-30,36,
      function()S.optionChoice=2 end)
  elseif kind=='material' then
    UI.text('Pesquisar materiais',p.x+18,p.y+52,12,'white')
    UI.rect(p.x+15,p.y+75,p.w-30,35,'panel2',3)
    UI.text('Buscar',p.x+26,p.y+83,13,'soft')
    for i,title in ipairs({'Todos','Padrões','Fundos','Mangá'}) do
      UI.button(title,p.x+16,p.y+125+(i-1)*43,p.w-32,36,
        function()S.optionChoice=i end,
        {bg=S.optionChoice==i and 'panel2' or 'panel'})
    end
  elseif kind=='shape' then
    for i,item in ipairs({'Reta','Retângulo','Elipse','Polígono',
      'Preenchimento','Contorno'}) do
      local x=p.x+15+(i-1)%2*145
      local y=p.y+50+math.floor((i-1)/2)*53
      UI.button(item,x,y,139,43,function()S.optionChoice=i end,
        {bg=S.optionChoice==i and 'blue' or 'panel2'})
    end
  elseif kind=='tool_options' or kind=='filter' then
    UI.text(S.tool=='filter' and 'Categorias de filtro' or
      'Ferramenta: '..S.tool,p.x+20,p.y+50,13,'soft')
    for i,item in ipairs(kind=='filter' and
      {'Ajustes','Desfoque','Estilo','Artístico','Desenho'} or
      {'Opção 1','Opção 2','Opção 3'}) do
      UI.button(item,p.x+18,p.y+80+(i-1)*47,p.w-36,40,
        function()S.optionChoice=i end,
        {bg=S.optionChoice==i and 'blue' or 'panel2'})
    end
  else
    UI.text('Painel de interface',p.x+20,p.y+57,13,'soft')
    sectionLine(p.x+15,p.y+82,p.w-30)
    UI.text('Sem função de edição nesta versão.',p.x+20,p.y+107,13,'soft')
  end
end
local function drawInfo(kind)
  local p=panelBase('settings',kind=='online' and 'Galeria Online'
    or kind=='collection' and 'Coleção' or 'Selecionar')
  UI.text('Tela demonstrativa sem serviço conectado.',
    p.x+23,p.y+73,14,'white')
  UI.button('Fechar',p.x+p.w-138,p.y+p.h-55,118,35,close,{bg='blue'})
end
function love.load()
  UI.font(10);UI.font(11);UI.font(12);UI.font(13)
  UI.font(14);UI.font(18);UI.font(22);UI.font(68)
end
function love.draw()
  V=Layout.viewport(lg.getWidth(),lg.getHeight())
  UI.hits={}
  lg.push('all')
  lg.scale(V.scale,V.scale)
  if S.screen=='home' then drawHome()
  elseif S.screen=='gallery' then drawGallery()
  else drawEditor() end
  if S.popup then
    local kind=S.popup
    if kind=='tools' then drawTools()
    elseif kind=='brushes' then drawBrushes()
    elseif kind=='layers' then drawLayers()
    elseif kind=='color' then drawColor()
    elseif kind=='settings' then drawSettings()
    elseif kind=='canvas_new' then drawNewCanvas()
    elseif kind=='back' then drawBack()
    elseif kind=='blend' then drawBlend()
    elseif kind=='collection' or kind=='online' or
      kind=='gallery_selection' then drawInfo(kind)
    else drawSimple(kind) end
  end
  lg.pop()
end
function love.mousepressed(x,y,button)
  if not V then return end
  if button==1 then
    UI.dispatch(x/V.scale,y/V.scale)
  elseif button==2 and S.screen=='editor' and not S.popup then
    S.drag={x=x,y=y,panX=S.panX,panY=S.panY}
  end
end
function love.mousemoved(x,y)
  if S.drag and V then
    S.panX=S.drag.panX+(x-S.drag.x)/V.scale
    S.panY=S.drag.panY+(y-S.drag.y)/V.scale
  end
end
function love.mousereleased(x,y,button)
  if button==2 then S.drag=nil end
end
function love.wheelmoved(dx,dy)
  if S.screen=='editor' and not S.popup then
    S.zoom=math.max(.25,math.min(3,S.zoom*(dy>0 and 1.1 or .9)))
  end
end
function love.keypressed(key)
  if key=='escape' then
    if S.popup then close()
    elseif S.screen=='editor' and S.fullscreen then S.fullscreen=false
    elseif S.screen=='editor' then open('back')
    elseif S.screen=='gallery' then S.screen='home' end
    return
  end
  if S.screen=='editor' and not S.popup then
    if key=='tab' then S.fullscreen=not S.fullscreen
    elseif key=='l' then open('layers')
    elseif key=='t' then open('tools')
    elseif key=='c' then open('color')
    elseif key=='b' then pickTool('brush')
    elseif key=='e' then pickTool('eraser') end
  elseif S.screen=='home' and key=='return' then S.screen='gallery' end
end
