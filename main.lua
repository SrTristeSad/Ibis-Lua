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
  optionChoice=1,collectionTab='Básico',toolPage=1,
  brushSearchOpen=false,brushQuery='',paletteGroup=1,colorMode='HSB',
  brushCategory='Todos',brushCategoryPage=1,brushScroll=0,drag=nil}
local V
local captureScene=nil
local captureFrame=0
local function inside(r,x,y) return Layout.contains(r,x,y) end
local function open(kind)
  if kind=='color' and S.popup~='color' then
    S.previousColor={S.colorValue[1],S.colorValue[2],S.colorValue[3]}
  end
  S.popup=kind
end
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
  UI.text('^',w-35,rankY+4,22,'white')
  local count=math.max(2,math.floor((w-40)/120))
  for i=1,count do
    local xx=20+(i-1)*(w-40)/count
    UI.rect(xx,rankY+34,math.min(105,(w-52)/count-5),56,{.96,.96,.97},1)
  end
end
local function drawGallery()
  -- Galeria: faixa superior e inferior escuras, miniaturas em fundo creme.
  lg.clear(.966,.966,.939,1)
  local w=V.w
  UI.rect(0,0,w,34,'toolbar')
  UI.text('‹ Voltar',12,9,12,'blue')
  UI.text(('Minha Galeria (%d)'):format(#S.works),
    0,9,14,'white','center',w)
  UI.text('Selecionar',w-94,10,12,'blue')
  UI.hit({x=0,y=0,w=90,h=34},function()S.screen='home' end)
  UI.hit({x=w-102,y=0,w=102,h=34},
    function()open('gallery_selection')end)
  local cols=math.max(3,math.floor((w-32)/135))
  local tile=(w-40-(cols-1)*12)/cols
  tile=math.min(130,tile)
  if #S.works==0 then
    UI.text('Nenhuma obra ainda',0,213,15,'ink','center',w)
    UI.text('Toque em + para criar uma tela',0,237,11,'ink','center',w)
  else
    for i,work in ipairs(S.works) do
      local col=(i-1)%cols
      local row=math.floor((i-1)/cols)
      local x=16+col*(tile+12)
      local y=43+row*(tile+38)
      UI.rect(x,y,tile,tile,{.995,.995,.995},1)
      UI.rect(x+.5,y+.5,tile-1,tile-1,{.68,.68,.68},0,true)
      local ratio=work.width/work.height
      local tw=math.min(tile-12,(tile-12)*ratio)
      local th=math.min(tile-12,(tile-12)/ratio)
      UI.rect(x+(tile-tw)/2,y+(tile-th)/2,tw,th,'paper',1)
      UI.text(work.name,x,y+tile+6,11,'ink')
      UI.hit({x=x,y=y,w=tile,h=tile+25},
        function()openEditor(work)end)
    end
  end
  UI.rect(0,474,w,38,'toolbar')
  local actions={{'plus',function()S.canvasPreset=1;open('canvas_new')end},
    {'settings',function()open('gallery_selection')end},
    {'play',function()open('gallery_selection')end},
    {'folder',function()open('gallery_selection')end},
    {'menu',function()open('gallery_selection')end}}
  for i,item in ipairs(actions) do
    local xx=8+(i-1)*52
    glyph(item[1],xx+20,493,i==1 and 23 or 19,
      i==1 and 'blue' or 'soft')
    UI.hit({x=xx-6,y=474,w=50,h=38},item[2])
  end
  UI.text('Editar',w-66,487,12,'soft')
  UI.hit({x=w-90,y=474,w=90,h=38},
    function()open('gallery_selection')end)
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
      local short={special='Especial',frame='Quadros',wand='Varinha',
        picker='Conta-gotas'}
      local label=short[item[1]] or item[2]
      local font=#label>10 and 6 or 7
      UI.text(label,r.x+1,r.y+17,font,active and 'blue' or 'white',
        'center',47)
    end
    UI.hit(r,function()pickTool(item[1])end)
  end
end
local function drawTop()
  for i,id in ipairs(Layout.TOP) do
    local r=Layout.top(i,V)
    UI.rect(r.x,r.y,r.w,r.h,{.49,.50,.51,.82},17)
    glyph(id,r.x+r.w/2,r.y+r.h/2,20)
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
  -- Dois ajustes rápidos lado a lado sobre a barra inferior, como no editor.
  local sliderWidth=math.min(220,math.max(108,(w-210)/2))
  local space=sliderWidth+108
  local first=(w-(2*space-20))/2
  for i,kind in ipairs({'size','opacity'}) do
    local x=first+(i-1)*space
    local y=452
    local value=kind=='size' and S.size or S.opacity
    UI.text(kind=='size' and ('%.1f px'):format(value) or (value..'%'),
      x,y+1,10,'ink')
    UI.rect(x+51,y-1,19,19,'dark',10)
    UI.text('−',x+51,y-2,15,'white','center',19)
    UI.hit({x=x+51,y=y-1,w=19,h=20},function()
      if kind=='size' then S.size=math.max(.1,S.size-1)
      else S.opacity=math.max(1,S.opacity-5) end
    end)
    UI.slider(x+77,y,sliderWidth,kind=='size' and S.size/100
      or S.opacity/100,function(t)
      if kind=='size' then S.size=math.floor((.1+t*99.9)*10)/10
      else S.opacity=math.floor(t*100+.5) end
    end,{track='line',fill='white'})
    UI.rect(x+79+sliderWidth,y-1,19,19,'dark',10)
    UI.text('+',x+79+sliderWidth,y-2,14,'white','center',19)
    UI.hit({x=x+79+sliderWidth,y=y-1,w=19,h=20},function()
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
  local catalog=require('src.brush_catalog')
  local p=panelBase('brushes','Pincel')
  local x,y=p.x+8,p.y+34
  local innerW=p.w-16
  local previewH=50
  -- Imagem de amostra com fundo xadrez da janela original.
  UI.checker(x,y,innerW,previewH,9)
  UI.rect(x,y,innerW,previewH,'line',0,true)
  UI.color('ink');lg.setLineWidth(2.1)
  local pts={}
  for k=0,100 do
    local t=k/100
    pts[#pts+1]=x+10+t*(innerW-22)
    pts[#pts+1]=y+25-math.sin(t*math.pi*2)*7
  end
  lg.line(pts)
  if S.brushSearchOpen then
    UI.rect(x+3,y+3,innerW-6,previewH-6,'white',2)
    UI.text('Pesquisar: '..(S.brushQuery or '')..'|',
      x+15,y+17,13,'ink')
  end
  local top=y+previewH+2
  local sideW=56
  local mainX=x+sideW
  local mainW=innerW-sideW
  UI.rect(x,top,innerW,29,'toolbar')
  local tabs={'Básico','Personalizado','Online'}
  local tabW=(mainW-30)/3
  for i,title in ipairs(tabs) do
    local tx=mainX+(i-1)*tabW
    UI.rect(tx,top,tabW-1,27,
      S.collectionTab==title and 'white' or {.55,.56,.57},0)
    UI.text(title,tx,top+9,10,
      S.collectionTab==title and 'ink' or 'white','center',tabW)
    UI.hit({x=tx,y=top,w=tabW,h=27},function()
      S.collectionTab=title;S.brushScroll=0
    end)
  end
  UI.rect(x,top,sideW,27,{.10,.11,.12})
  glyph('brush',x+sideW/2,top+13,17)
  UI.rect(x+innerW-30,top,30,27,{.08,.08,.09})
  glyph('search',x+innerW-15,top+13,19)
  UI.hit({x=x+innerW-30,y=top,w=30,h=27},function()
    S.brushSearchOpen=not S.brushSearchOpen
    S.brushQuery=''
    S.brushScroll=0
  end)
  local listY=top+29
  local footerY=p.y+p.h-91
  local areaH=footerY-listY
  UI.rect(x,listY,sideW,areaH,{.065,.068,.074},0)
  UI.rect(mainX,listY,mainW,areaH,{.96,.96,.96},0)
  -- A versão 14 inclui uma coluna compacta de categorias com ícones.
  local categoryRows=math.floor((areaH-13)/40)
  local categoryMax=math.max(0,#catalog.categories-categoryRows)
  S.brushCategoryPage=math.max(0,math.min(S.brushCategoryPage,categoryMax))
  for i=1,categoryRows do
    local cat=catalog.categories[i+S.brushCategoryPage]
    if cat then
      local cy=listY+2+(i-1)*40
      if S.brushCategory==cat[1] then
        UI.rect(x+1,cy,sideW-2,39,{.28,.35,.43},0)
        UI.rect(x,cy,3,39,'blue',0)
      end
      glyph(cat[2],x+sideW/2,cy+14,19,
        S.brushCategory==cat[1] and 'blue' or 'white')
      UI.text(cat[1],x+2,cy+25,7,'white','center',sideW-4)
      UI.hit({x=x,y=cy,w=sideW,h=40},function()
        S.brushCategory=cat[1];S.brushScroll=0
      end)
    end
  end
  UI.rect(x,listY+areaH-13,sideW,13,{.14,.15,.16})
  UI.text('⌄',x,listY+areaH-15,16,'white','center',sideW)
  UI.hit({x=x,y=listY+areaH-13,w=sideW,h=13},function()
    S.brushCategoryPage=(S.brushCategoryPage+1)%(categoryMax+1)
  end)
  if S.collectionTab=='Básico' then
    local data=catalog.filter(S.brushCategory,S.brushQuery)
    local rowH=32
    local rows=math.floor(areaH/rowH)
    local maxScroll=math.max(0,#data-rows)
    S.brushScroll=math.max(0,math.min(S.brushScroll,maxScroll))
    for i=1,rows do
      local entry=data[i+S.brushScroll]
      if entry then
        local ry=listY+(i-1)*rowH
        local selected=S.brush==entry[1]
        UI.rect(mainX,ry,mainW,rowH-1,
          selected and {.81,.88,.97} or 'white',0)
        if selected then UI.rect(mainX,ry,2,rowH,'blue',0) end
        UI.text(entry[1],mainX+9,ry+2,9,'ink')
        UI.color('ink')
        local thickness=math.max(.8,math.min(6,entry[3]/8))
        lg.setLineWidth(thickness)
        local curve={}
        for k=0,33 do
          local t=k/33
          curve[#curve+1]=mainX+9+t*(mainW-72)
          curve[#curve+1]=ry+23+math.sin(t*6.3)*2.2
        end
        lg.line(curve)
        UI.text(('%.1f'):format(entry[3]),mainX+mainW-38,ry+2,8,'ink')
        UI.text('›',mainX+mainW-20,ry+7,16,'ink')
        UI.hit({x=mainX,y=ry,w=mainW,h=rowH},function()
          S.brush=entry[1];S.size=entry[3]
        end)
      end
    end
    if #data>rows then
      UI.rect(mainX+mainW-3,listY+2,3,areaH-4,{.79,.79,.79})
      UI.rect(mainX+mainW-3,listY+2+
        S.brushScroll/math.max(1,maxScroll)*(areaH-33),
        3,29,{.40,.40,.40})
    end
  else
    UI.text(S.collectionTab=='Personalizado' and
      'Sem pincéis personalizados' or 'Galeria online indisponível',
      mainX+9,listY+20,12,'ink')
  end
  -- Rodapé fixo: espessura e opacidade; não executa pinceladas.
  UI.rect(x,footerY,innerW,90,{.43,.44,.45},0)
  UI.text('Espessura',x+10,footerY+7,11,'white')
  UI.text(('%.1f px'):format(S.size),x+innerW-84,footerY+7,11,'white')
  UI.rect(x+6,footerY+26,18,18,{.20,.21,.22},10)
  UI.text('−',x+6,footerY+25,16,'white','center',18)
  UI.hit({x=x+6,y=footerY+26,w=18,h=18},function()
    S.size=math.max(.1,S.size-1) end)
  UI.slider(x+32,footerY+27,innerW-64,S.size/100,function(t)
    S.size=math.floor((.1+t*99.9)*10)/10 end)
  UI.rect(x+innerW-24,footerY+26,18,18,{.20,.21,.22},10)
  UI.text('+',x+innerW-24,footerY+25,15,'white','center',18)
  UI.hit({x=x+innerW-24,y=footerY+26,w=18,h=18},function()
    S.size=math.min(100,S.size+1) end)
  UI.text('Opacidade',x+10,footerY+47,11,'white')
  UI.text(S.opacity..'%',x+innerW-58,footerY+47,11,'white')
  UI.slider(x+32,footerY+69,innerW-64,S.opacity/100,function(t)
    S.opacity=math.floor(t*100+.5)end)
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
local function rgbToHsv(r,g,b)
  local mx=math.max(r,g,b);local mn=math.min(r,g,b)
  local d=mx-mn;local hue=0
  if d>0 then
    if mx==r then hue=((g-b)/d)%6
    elseif mx==g then hue=(b-r)/d+2
    else hue=(r-g)/d+4 end
    hue=hue*60
  end
  return hue,mx==0 and 0 or d/mx,mx
end
local function drawColor()
  local p=panelBase('color','Cor')
  local x=p.x+10
  local w=p.w-20
  local rgb=S.colorValue
  S.previousColor=S.previousColor or {rgb[1],rgb[2],rgb[3]}
  UI.rect(x,p.y+35,w,35,'toolbar',1)
  local previewW=(w-84)/2
  UI.rect(x+40,p.y+39,previewW,26,rgb,1)
  UI.rect(x+40+previewW,p.y+39,previewW,26,S.previousColor,1)
  UI.text('◀',x+3,p.y+43,17,'white')
  UI.hit({x=x,y=p.y+36,w=36,h=34},close)
  UI.rect(x+w-38,p.y+39,33,26,'dark',13)
  UI.text('›',x+w-35,p.y+40,20,'white','center',27)
  UI.hit({x=x+w-38,y=p.y+39,w=33,h=26},function()
    S.colorTab=S.colorTab=='HSB' and 'Paleta' or 'HSB'
  end)
  if S.colorTab=='Paleta' then
    UI.rect(x,p.y+75,w,p.h-91,{.93,.93,.93},0)
    local groups={'Padrão','Personalizada','Histórico'}
    S.paletteGroup=S.paletteGroup or 1
    local groupW=w/3
    for i,item in ipairs(groups) do
      local xx=x+(i-1)*groupW
      UI.rect(xx,p.y+77,groupW-1,24,
        S.paletteGroup==i and 'white' or {.68,.68,.68},0)
      UI.text(item,xx,p.y+83,10,'ink','center',groupW)
      UI.hit({x=xx,y=p.y+77,w=groupW,h=25},
        function()S.paletteGroup=i end)
    end
    UI.checker(x+3,p.y+103,w-6,p.h-158,12)
    if S.paletteGroup==1 then
      local basic={
        {0,0,0},{1,1,1},{1,0,0},{1,.48,0},{1,1,0},{.43,1,0},
        {0,1,0},{0,1,.5},{0,1,1},{0,.4,1},{.1,0,.9},{.5,0,1},
        {1,0,1},{1,0,.6},{1,.6,.7},{1,.83,.57},{.8,.7,.6},
        {.5,.31,.23},{.86,.89,.95}
      }
      local cell=(w-10)/10
      for i,c in ipairs(basic) do
        local col=(i-1)%10;local row=math.floor((i-1)/10)
        local xx=x+5+col*cell;local yy=p.y+106+row*cell
        UI.rect(xx,yy,cell-2,cell-2,c,0)
        UI.hit({x=xx,y=yy,w=cell-2,h=cell-2},function()
          S.colorValue={c[1],c[2],c[3]}
          S.hue,S.saturation,S.brightness=rgbToHsv(c[1],c[2],c[3])
        end)
      end
    else
      UI.text(S.paletteGroup==2 and 'Nova paleta  +' or
        'Nenhuma cor no histórico',x+18,p.y+174,12,'ink')
    end
    UI.text('100%',x+5,p.y+p.h-42,10,'white')
    UI.slider(x+65,p.y+p.h-42,w-73,S.opacity/100,function(t)
      S.opacity=math.floor(t*100+.5) end)
    return
  end
  local cx=p.x+p.w/2;local cy=p.y+172
  local radius=105
  -- Anel cromático com 120 fatias contíguas e interior em cinza neutro.
  for i=0,119 do
    local a=(i/120)*math.pi*2
    UI.color(hsv(i*3,1,1))
    lg.arc('fill','pie',cx,cy,radius,a,a+math.pi*2/120+.003,3)
  end
  UI.color({.42,.43,.45})
  lg.circle('fill',cx,cy,78,96)
  -- Losango de saturação/valor no centro.
  local square=59
  for yy=-square,square,2 do
    for xx=-square,square,2 do
      if math.abs(xx)+math.abs(yy)<=square then
        local sat=math.max(0,math.min(1,(xx+square)/(square*2)))
        local val=math.max(0,math.min(1,(square-yy)/(square*2)))
        UI.color(hsv(S.hue,sat,val))
        lg.rectangle('fill',cx+xx,cy+yy,2.5,2.5)
      end
    end
  end
  local markerAngle=math.rad(S.hue)
  UI.color('white');lg.setLineWidth(2)
  lg.circle('line',cx+math.cos(markerAngle)*92,
    cy+math.sin(markerAngle)*92,8,32)
  UI.color('ink')
  lg.circle('line',cx+(S.saturation*2-1)*square*.45,
    cy+(1-S.brightness*2)*square*.45,6,28)
  UI.hit({x=cx-radius,y=cy-radius,w=2*radius,h=2*radius},function()
    local mx=love.mouse.getX()/V.scale
    local my=love.mouse.getY()/V.scale
    local dx,dy=mx-cx,my-cy
    local dist=math.sqrt(dx*dx+dy*dy)
    if dist>78 then
      S.hue=(math.deg(math.atan2 and math.atan2(dy,dx) or
        math.atan(dy,dx))+360)%360
    elseif math.abs(dx)+math.abs(dy)<=square then
      S.saturation=math.max(0,math.min(1,(dx+square)/(2*square)))
      S.brightness=math.max(0,math.min(1,(square-dy)/(2*square)))
    end
    S.colorValue=hsv(S.hue,S.saturation,S.brightness)
  end)
  UI.rect(x+4,p.y+278,w-8,21,'toolbar',2)
  UI.text('#'..('%.2X%.2X%.2X'):format(
    math.floor(rgb[1]*255+.5),math.floor(rgb[2]*255+.5),
    math.floor(rgb[3]*255+.5)),x+14,p.y+282,12,'white')
  UI.button(S.colorMode=='RGB' and 'RGB' or 'HSB',x+w-71,p.y+279,
    60,19,function()
      S.colorMode=S.colorMode=='RGB' and 'HSB' or 'RGB'
    end,{bg='dark',font=10})
  local start=p.y+306
  for i=1,4 do
    local isRGB=S.colorMode=='RGB'
    local label=(isRGB and ({'R','G','B','A'})[i]) or
      ({'H','S','B','A'})[i]
    local t
    if label=='H' then t=S.hue/360
    elseif label=='S' then t=S.saturation
    elseif label=='B' and not isRGB then t=S.brightness
    elseif label=='A' then t=S.opacity/100
    else t=rgb[i] end
    local sy=start+(i-1)*20
    UI.text(label,x+5,sy,10,'white')
    UI.rect(x+21,sy+1,17,17,'dark',9)
    UI.text('−',x+21,sy,13,'white','center',17)
    UI.hit({x=x+21,y=sy+1,w=17,h=17},function()
      if label=='A' then S.opacity=math.max(0,S.opacity-1)
      elseif label=='H' then S.hue=(S.hue-1)%360
      elseif label=='S' then S.saturation=math.max(0,S.saturation-.01)
      elseif label=='B' and not isRGB then
        S.brightness=math.max(0,S.brightness-.01)
      else
        local idx=({R=1,G=2,B=3})[label]
        rgb[idx]=math.max(0,rgb[idx]-.01)
        S.hue,S.saturation,S.brightness=rgbToHsv(
          rgb[1],rgb[2],rgb[3])
      end
      S.colorValue=hsv(S.hue,S.saturation,S.brightness)
    end)
    local trackX=x+44
    local trackW=w-89
    for k=0,40 do
      local frac=k/40
      local c
      if label=='H' then c=hsv(frac*360,1,1)
      elseif label=='S' then c=hsv(S.hue,frac,S.brightness)
      elseif label=='B' and not isRGB then
        c=hsv(S.hue,S.saturation,frac)
      elseif label=='A' then c={frac,frac,frac}
      else
        c={rgb[1],rgb[2],rgb[3]}
        c[({R=1,G=2,B=3})[label]]=frac
      end
      UI.rect(trackX+frac*trackW,sy+7,trackW/40+1,5,c,0)
    end
    UI.slider(trackX,sy,trackW,t,function(frac)
      if label=='H' then S.hue=frac*360
      elseif label=='S' then S.saturation=frac
      elseif label=='B' and not isRGB then S.brightness=frac
      elseif label=='A' then S.opacity=math.floor(frac*100+.5)
      else
        local idx=({R=1,G=2,B=3})[label]
        rgb[idx]=frac
        S.hue,S.saturation,S.brightness=rgbToHsv(
          rgb[1],rgb[2],rgb[3])
      end
      S.colorValue=hsv(S.hue,S.saturation,S.brightness)
    end,{noTrack=true})
    UI.rect(x+w-26,sy+1,17,17,'dark',9)
    UI.text('+',x+w-26,sy,12,'white','center',17)
    UI.hit({x=x+w-26,y=sy+1,w=17,h=17},function()
      if label=='A' then S.opacity=math.min(100,S.opacity+1)
      elseif label=='H' then S.hue=(S.hue+1)%360
      elseif label=='S' then S.saturation=math.min(1,S.saturation+.01)
      elseif label=='B' and not isRGB then
        S.brightness=math.min(1,S.brightness+.01)
      else
        local idx=({R=1,G=2,B=3})[label]
        rgb[idx]=math.min(1,rgb[idx]+.01)
        S.hue,S.saturation,S.brightness=rgbToHsv(
          rgb[1],rgb[2],rgb[3])
      end
      S.colorValue=hsv(S.hue,S.saturation,S.brightness)
    end)
  end
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
  -- Tela "New": importar imagem, dimensões W/H e relação de presets.
  UI.rect(p.x+6,p.y+34,p.w-12,p.h-83,{.92,.92,.92},1)
  UI.rect(p.x+8,p.y+36,p.w-16,39,'white',1)
  UI.rect(p.x+17,p.y+43,31,25,'ink',2)
  glyph('canvas',p.x+32,p.y+55,19)
  UI.text('Importar imagem',p.x+58,p.y+46,16,'ink')
  UI.rect(p.x+8,p.y+76,p.w-16,21,{.37,.37,.37})
  UI.text('Ilustração',p.x+17,p.y+79,12,'white')
  local sizes={{1280,920,'Padrão'},{1280,1280,'1 : 1 (Quadrado)'},
    {1920,1080,'16 : 9 (Paisagem)'},{1080,1920,'9 : 16 (Retrato)'},
    {512,512,'Pequeno'}}
  local current=sizes[S.canvasPreset]
  UI.rect(p.x+150,p.y+99,57,27,'white',2)
  UI.rect(p.x+220,p.y+99,57,27,'white',2)
  UI.text(tostring(current[1]),p.x+150,p.y+105,13,'ink','center',57)
  UI.text('×',p.x+209,p.y+106,13,'ink','center',11)
  UI.text(tostring(current[2]),p.x+220,p.y+105,13,'ink','center',57)
  for i,lab in ipairs({'W','H'}) do
    local yy=p.y+132+(i-1)*25
    UI.text(lab,p.x+64,yy+2,13,'ink')
    UI.rect(p.x+88,yy,20,20,'ink',11)
    UI.text('−',p.x+88,yy,15,'white','center',20)
    UI.slider(p.x+123,yy+2,p.w-216,.48,function(t)
      S.canvasPreset=math.min(5,math.max(1,math.floor(1+t*5)))
    end,{track='line',fill='blue'})
    UI.rect(p.x+p.w-78,yy,20,20,'ink',11)
    UI.text('+',p.x+p.w-78,yy+1,14,'white','center',20)
  end
  UI.text('Velocidade    -    Qualidade',p.x+84,p.y+185,12,'ink')
  UI.rect(p.x+9,p.y+203,p.w-18,19,{.37,.37,.37})
  UI.text('Tamanhos predefinidos',p.x+19,p.y+205,11,'white')
  for i,item in ipairs(sizes) do
    local y=p.y+222+(i-1)*27
    UI.rect(p.x+9,y,p.w-18,27,
      S.canvasPreset==i and {.82,.89,.97} or {.91,.91,.91},0)
    UI.line(p.x+10,y+26,p.x+p.w-10,y+26,{.67,.67,.67},.6)
    UI.rect(p.x+17,y+3,21,21,'ink',0,true)
    UI.text(item[3],p.x+48,y+5,12,'ink')
    UI.rect(p.x+p.w-119,y+2,108,24,'white',1)
    UI.text(item[1]..' × '..item[2],p.x+p.w-118,y+8,11,'ink',
      'center',106)
    UI.hit({x=p.x+9,y=y,w=p.w-18,h=27},
      function()S.canvasPreset=i end)
  end
  UI.rect(p.x+7,p.y+p.h-48,p.w-14,43,'toolbar',1)
  UI.button('Cancelar',p.x+15,p.y+p.h-43,102,31,close,{bg='dark'})
  UI.button('OK',p.x+p.w-126,p.y+p.h-43,111,31,
    createWork,{bg='dark'})
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
function love.load(args)
  UI.font(10);UI.font(11);UI.font(12);UI.font(13)
  UI.font(14);UI.font(18);UI.font(22);UI.font(68)
  -- Uso restrito aos testes de comparacao visual em CI:
  -- love . --capture-ui home|gallery|editor|brushes|layers|color|tools|canvas_new
  if type(args)=='table' then
    for i=1,#args do
      if args[i]=='--capture-ui' then
        local scene=args[i+1] or 'editor'
        local valid={home=true,gallery=true,editor=true,brushes=true,
          layers=true,color=true,tools=true,canvas_new=true}
        if not valid[scene] then error('Cena de captura desconhecida: '..scene) end
        captureScene=scene
        captureFrame=0
        if scene~='home' then
          if scene=='canvas_new' then
            S.screen='gallery'
            open('canvas_new')
          else
            createWork()
            if scene=='gallery' then S.screen='gallery'
            elseif scene~='editor' then open(scene) end
          end
        end
        break
      end
    end
  end
end
function love.update(dt)
  if not captureScene then return end
  captureFrame=captureFrame+1
  if captureFrame==6 then
    lg.captureScreenshot('visual-'..captureScene..'.png')
  elseif captureFrame>=14 then
    love.event.quit(0)
  end
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
  if S.popup=='brushes' then
    local catalog=require('src.brush_catalog')
    local entries=catalog.filter(S.brushCategory,S.brushQuery)
    S.brushScroll=math.max(0,math.min(math.max(0,#entries-6),
      S.brushScroll-(dy>0 and 1 or dy<0 and -1 or 0)))
    return
  end
  if S.screen=='editor' and not S.popup then
    S.zoom=math.max(.25,math.min(3,S.zoom*(dy>0 and 1.1 or .9)))
  end
end
function love.textinput(char)
  if S.popup=='brushes' and S.brushSearchOpen then
    S.brushQuery=(S.brushQuery or '')..char
    S.brushScroll=0
  end
end
function love.keypressed(key)
  if key=='f12' then
    if lg.captureScreenshot then
      local screen=tostring(S.popup or S.screen):gsub('[^%w_-]','')
      local name='ibis-lua-'..screen..'-'..os.date('%Y%m%d-%H%M%S')..'.png'
      lg.captureScreenshot(name)
      if love.filesystem and love.filesystem.getSaveDirectory then
        print('Captura PNG: '..love.filesystem.getSaveDirectory()..'/'..name)
      end
    end
    return
  end
  if S.popup=='brushes' and S.brushSearchOpen and key=='backspace' then
    local q=S.brushQuery or ''
    S.brushQuery=q:sub(1,-2)
    S.brushScroll=0
    return
  end
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
