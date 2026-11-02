local Model=require("src.model")
local U=require("src.ui")
local C=U.C
local s=Model.new()
local lg=love.graphics
local dragging=false
local lastX,lastY=0,0
-- Automated screenshot mode is opt-in and does not change normal execution.
local screenshotMode=os.getenv("IBIS_LUA_SCREENSHOT")
local screenshotElapsed=0
local screenshotTaken=false

local function panelBox(x,y,w,h,title)
  U.rect(x,y,w,h,C.panel,5)
  U.hitbox(x,y,w,h,function() end)
  U.rect(x,y,w,37,{0.37,0.37,0.37},5)
  U.text(title,x+14,y+8,w-60,C.white,"heading")
  U.close(x+w-29,y+8,function() s.panel=nil end)
end
local function enterSettings()
  s.previousPage=s.page;s.page="settings";s.panel=nil;s.menu=nil
end
local function back()
  if s.page=="settings" then s.page=s.previousPage or "title";return end
  Model.back(s)
end
local function topLogo(x,y,scale)
  U.wordmark(x,y)
  U.text("Ver. 14.1.4",x+128,y+51,220,C.white,"small")
end
local function titleScreen(w,h)
  U.rect(0,0,w,h*.67,C.blue)
  U.rect(0,h*.67,w,h*.33,C.navy)
  local cx=w*.5
  topLogo(cx-152,h*.16,1)
  local sy=h*.46
  U.roundButton("My Gallery",cx-170,sy,41,function() Model.openGallery(s) end)
  U.roundButton("Collection",cx,sy,41,function() s.page="collection" end)
  U.roundButton("Online Gallery",cx+170,sy,41,function() s.page="online" end)
  U.text("Daily Ranking",0,h*.70,w,C.white,"heading","center")
  U.button("Settings",w-128,14,110,29,enterSettings,false,{0.25,0.38,0.53})
end
local function galleryScreen(w,h)
  U.rect(0,0,w,h,C.offwhite)
  U.rect(0,0,w,42,{0.23,0.23,0.23})
  U.text("My Gallery ("..#s.works..")",18,10,w*.4,C.white,"body","center")
  U.button("+",w-205,5,40,32,function() Model.openNewCanvas(s) end,false,{0.25,0.25,0.25})
  U.button("Select",w-160,5,72,32,function() s.menu=s.menu=="select" and nil or "select" end)
  U.button("Edit",w-84,5,74,32,function() s.menu=s.menu=="edit" and nil or "edit" end)
  U.text("Cloud Synchronization",15,58,180,C.gray,"small")
  U.button("OFF",185,52,58,25,function() s.settings.cloud=not s.settings.cloud end,s.settings.cloud)
  if #s.works==0 then
    U.text("There is no artwork.",0,h*.56,w,C.gray,"body","center")
    U.text("Press '+' button to create a new artwork.",0,h*.56+24,w,C.gray,"small","center")
  else
    local size=170;local gap=23
    for i,work in ipairs(s.works) do
      local col=(i-1)%math.max(1,math.floor((w-25)/(size+gap)))
      local row=math.floor((i-1)/math.max(1,math.floor((w-25)/(size+gap))))
      local x=22+col*(size+gap);local y=120+row*(size+gap+36)
      U.rect(x,y,size,size,{1,1,1})
      U.stroke(x,y,size,size,{0.8,0.8,0.8})
      U.text("Blank Canvas",x,y+size*.45,size,C.gray,"small","center")
      U.text(work.title,x,y+size+8,size,C.ink,"body","center")
      U.hitbox(x,y,size,size+33,function() Model.openWork(s,i) end)
    end
  end
  U.button("Back",15,h-42,90,30,back)
end
local function textField(label,value,x,y,width,key)
  U.text(label,x,y,width,C.ink,"small")
  U.rect(x,y+17,width,30,{0.98,0.98,0.98},2)
  U.stroke(x,y+17,width,30,{0.66,0.66,0.66})
  U.text(tostring(value),x+5,y+23,width-10,C.ink,"body","center")
  U.hitbox(x,y+17,width,30,function() s.focus=key end)
end
local function newCanvasDialog(w,h)
  U.rect(0,0,w,h,{0,0,0,0.35})
  U.hitbox(0,0,w,h,function() s.modal=nil;s.focus=nil end)
  local dw=430;local dh=math.min(h-56,656)
  local x=(w-dw)/2;local y=(h-dh)/2
  U.rect(x,y,dw,dh,{0.29,0.29,0.29},4)
  U.hitbox(x,y,dw,dh,function() end)
  U.text("New Canvas",x+9,y+8,dw-18,C.white,"body","center")
  U.rect(x+6,y+34,dw-12,40,{0.92,0.92,0.92})
  U.text("Import Picture",x+15,y+46,dw-32,C.ink,"body")
  U.hitbox(x+6,y+34,dw-12,40,function() s.notification="Image import requires the file-processing engine." end)
  U.rect(x+6,y+81,dw-12,97,C.pale)
  textField("W",s.w,x+35,y+87,155,"w")
  textField("H",s.h,x+235,y+87,155,"h")
  U.text("Speed  < >  Quality",x+30,y+145,dw-60,C.ink,"small","center")
  local start=y+180;local usable=dh-226;local rows=math.min(#Model.presets,math.floor(usable/33))
  for i=1,rows do
    local item=Model.presets[i]
    local yy=start+(i-1)*33
    U.rect(x+6,yy,dw-12,31,i%2==0 and {0.83,0.83,0.83} or {0.9,0.9,0.9})
    U.stroke(x+12,yy+6,20,18,C.gray)
    U.text(item[1],x+41,yy+7,235,C.ink,"body")
    U.text(item[2].." x "..item[3],x+289,yy+7,116,C.ink,"small","right")
    U.hitbox(x+6,yy,dw-12,31,function()
      s.w=item[2];s.h=item[3];s.preset=i;s.focus=nil
    end)
  end
  U.button("Cancel",x+12,y+dh-42,95,30,function() s.modal=nil;s.focus=nil end)
  U.button("OK",x+dw-95,y+dh-42,80,30,function() s.focus=nil;Model.createCanvas(s) end,true)
end

local function drawCanvas(w,h)
  local left=49;local top=72;local bottom=h-82
  U.rect(left,top,w-left,bottom-top,{0.72,0.72,0.72})
  local maxW=w-left-100;local maxH=bottom-top-48
  local ratio=s.w/s.h
  local baseH=math.min(maxH,maxW/math.max(.1,ratio))
  local baseW=baseH*ratio
  local scale=s.zoom/100
  local cw=baseW*scale;local ch=baseH*scale
  local x=left+(w-left-cw)/2+s.panX
  local y=top+(bottom-top-ch)/2+s.panY
  U.rect(x+4,y+4,cw,ch,{0.57,0.57,0.57})
  U.rect(x,y,cw,ch,C.white)
  U.stroke(x,y,cw,ch,{0.55,0.55,0.55})
end
local function editorBar(w,h)
  -- Windows build: toolbar at left, six round actions in the top-right,
  -- separate sliders above the actual main toolbar.
  local top=72
  local bottom=h-82
  U.rect(0,0,w,28,{.94,.94,.94})
  U.text("ibisPaint",12,7,130,C.ink,"small")
  U.rect(0,28,w,44,{.77,.77,.77})
  U.rect(0,top,49,bottom-top,{.42,.42,.42})
  local stride=(bottom-top)/#Model.tools
  for i,name in ipairs(Model.tools) do
    local yy=top+(i-1)*stride
    U.toolButton(name,0,yy,49,stride,s.tool==name,function()
      Model.setTool(s,name)
    end)
  end
  local actions={
    {"View",function() s.menu=s.menu=="view" and nil or "view" end},
    {"Selection",function() Model.togglePanel(s,"selection") end},
    {"Stabilizer",function() Model.togglePanel(s,"stabilizer") end},
    {"Shape",function() Model.togglePanel(s,"shape") end},
    {"Ruler",function() Model.togglePanel(s,"ruler") end},
    {"Material",function() Model.togglePanel(s,"material") end}
  }
  for i,action in ipairs(actions) do
    local x=w-290+(i-1)*45
    U.circle(x,49,17,{.60,.60,.60})
    U.icon(action[1],x,49,20)
    U.hitbox(x-20,29,40,41,action[2])
  end
  -- Windows screenshot structure has two control rows under canvas.
  U.rect(0,bottom,w,44,{.69,.69,.69})
  U.text(string.format("%.1f",s.brushSize),6,bottom+2,44,C.ink,"small","center")
  U.circle(34,bottom+27,10,C.ink)
  U.icon("Minus",34,bottom+27,12)
  U.hitbox(23,bottom+16,22,22,function() Model.setBrushSize(s,s.brushSize-1) end)
  U.slider("Brush size",55,bottom+2,w*.38,s.brushSize,1,120,
    function(v) Model.setBrushSize(s,v) end)
  local plusA=63+w*.38
  U.circle(plusA,bottom+27,10,C.ink)
  U.icon("Plus",plusA,bottom+27,12)
  U.hitbox(plusA-11,bottom+16,22,22,function() Model.setBrushSize(s,s.brushSize+1) end)
  local bx=w*.53
  U.text(s.brushOpacity.."%",bx-35,bottom+2,46,C.ink,"small","center")
  U.circle(bx,bottom+27,10,C.ink)
  U.icon("Minus",bx,bottom+27,12)
  U.hitbox(bx-11,bottom+16,22,22,function() Model.setBrushOpacity(s,s.brushOpacity-1) end)
  U.slider("Opacity",bx+19,bottom+2,w*.35,s.brushOpacity,0,100,
    function(v) Model.setBrushOpacity(s,v) end)
  local plusB=bx+27+w*.35
  U.circle(plusB,bottom+27,10,C.ink)
  U.icon("Plus",plusB,bottom+27,12)
  U.hitbox(plusB-11,bottom+16,22,22,function() Model.setBrushOpacity(s,s.brushOpacity+1) end)

  local bottomY=h-38
  U.rect(0,bottomY,w,38,{.42,.42,.42})
  local cy=bottomY+19
  local function glyph(name,position,callback,active)
    local x=w*position
    if active then U.rect(x-22,bottomY,44,38,{.33,.33,.33}) end
    U.icon(name,x,cy,22)
    U.hitbox(x-25,bottomY,50,38,callback)
  end
  glyph("Tool Select",.027,function() Model.togglePanel(s,"tools") end,s.panel=="tools")
  glyph(s.tool=="Eraser" and "Eraser" or "Brush",.109,function()
    Model.togglePanel(s,s.tool=="Brush" and "brush" or "size")
  end,s.panel=="brush")
  local colorX=w*.215
  U.colorWheel(colorX,cy,15,s.color)
  U.hitbox(colorX-22,bottomY,44,38,function()Model.togglePanel(s,"color")end)
  local sampleX=w*.305
  U.rect(sampleX-13,cy-13,26,26,s.color)
  U.stroke(sampleX-13,cy-13,26,26,C.white)
  U.hitbox(sampleX-22,bottomY,44,38,function()Model.togglePanel(s,"color")end)
  glyph("Down",.44,function() s.notification="No painting engine; no canvas operation." end)
  glyph("Undo",.55,function() s.notification="Nothing to undo (visual-only mode)." end)
  glyph("Redo",.66,function() s.notification="Nothing to redo (visual-only mode)." end)
  glyph("Layer",.79,function() Model.togglePanel(s,"layer") end,s.panel=="layer")
  glyph("Back",.94,function() s.menu=s.menu=="back" and nil or "back" end)
end
local function brushPanel(w,h)
  local pw=math.min(620,w-70);local ph=math.min(604,h-115)
  local x=57;local y=39
  panelBox(x,y,pw,ph,"Brush")
  local listW=math.floor(pw*.53)
  local tabs={"Basic","Custom","Online"}
  for i,name in ipairs(tabs) do
    U.button(name,x+9+(i-1)*(listW-14)/3,y+44,(listW-15)/3,27,
      function() s.brushTab=name end,s.brushTab==name)
  end
  U.rect(x+8,y+75,listW-10,ph-90,{0.89,0.89,0.89})
  if s.brushTab=="Basic" then
    local limit=math.min(#Model.brushes,math.floor((ph-110)/38))
    for i=1,limit do
      local yy=y+80+(i-1)*38
      U.rect(x+12,yy,listW-18,36,s.brush==i and {0.66,0.8,0.94} or {0.94,0.94,0.94})
      U.circle(x+31,yy+18,10,C.white)
      U.circle(x+31,yy+18,10,C.gray,true)
      U.icon("Plus",x+31,yy+18,12,C.ink)
      for k=0,17 do
        local bx=x+50+k*(listW-75)/18
        local nx=x+50+(k+1)*(listW-75)/18
        local by=yy+15+math.sin(k*.41+i*.23)*2.8
        local ny=yy+15+math.sin((k+1)*.41+i*.23)*2.8
        U.line(bx,by,nx,ny,C.ink,math.max(1,(i%4)+1))
      end
      U.text(Model.brushes[i],x+52,yy+24,listW-73,C.ink,"small")
      U.hitbox(x+12,yy,listW-18,36,function() Model.setBrush(s,i) end)
    end
  else
    U.text(s.brushTab.." brushes",x+15,y+102,listW-30,C.ink,"body")
  end
  local sx=x+listW+15;local sw=pw-listW-29
  U.text(Model.brushes[s.brush],sx,y+51,sw,C.white,"body")
  U.text("Basic   Fade   Shape   Dynamic",sx,y+88,sw,C.pale,"small")
  U.slider("Thickness",sx,y+130,sw,s.brushSize,1,120,function(v) Model.setBrushSize(s,v) end)
  U.slider("Opacity",sx,y+197,sw,s.brushOpacity,0,100,function(v) Model.setBrushOpacity(s,v) end)
  U.text("Stroke preview",sx,y+265,sw,C.white,"small")
  U.rect(sx,y+288,sw,80,C.pale,5)
  U.line(sx+16,y+328,sx+sw-16,y+328,C.ink,math.min(16,s.brushSize/4))
  U.button("Reset",sx+sw-95,y+390,93,29,function()
    Model.setBrushSize(s,17);Model.setBrushOpacity(s,100)
  end)
end
local function layerPanel(w,h)
  local pw=394
  local ph=math.min(536,h-158)
  local x=w-pw-15
  local y=80
  panelBox(x,y,pw,ph,"Layer")
  local innerY=y+38
  local footerY=y+ph-100
  local previewW=115
  local toolbarW=34
  local listX=x+previewW+8
  local listW=pw-previewW-toolbarW-17
  local toolsX=x+pw-toolbarW-5
  U.rect(x+7,innerY,previewW,footerY-innerY,{.96,.96,.96})
  U.stroke(x+7,innerY,previewW,footerY-innerY,C.gray)
  U.text(s.workName,x+11,innerY+9,previewW-8,C.gray,"small","center")
  U.text("Blank canvas",x+11,innerY+80,previewW-8,C.gray,"small","center")
  U.rect(listX,innerY,listW,footerY-innerY,{.83,.83,.83})
  U.rect(toolsX,innerY,toolbarW,footerY-innerY,{.05,.05,.05})
  U.rect(listX+2,innerY+4,listW-4,50,{.96,.96,.96})
  U.rect(listX+7,innerY+11,32,32,{.91,.72,.89})
  U.stroke(listX+7,innerY+11,32,32,C.gray)
  U.text("Selection Layer",listX+45,innerY+21,listW-50,C.ink,"small")
  local itemHeight=59
  local limit=math.min(#s.layers,math.max(1,math.floor((footerY-innerY-114)/itemHeight)))
  for i=1,limit do
    local layer=s.layers[i]
    local ly=innerY+58+(i-1)*itemHeight
    U.rect(listX+2,ly,listW-4,itemHeight-2,
      s.selectedLayer==i and {.68,.79,.91} or {.96,.96,.96})
    -- Plain white thumbnail is intentional: processing / painting is out of scope.
    U.rect(listX+8,ly+6,43,42,C.white)
    U.stroke(listX+8,ly+6,43,42,{.70,.70,.70})
    U.text(layer.name,listX+57,ly+8,105,C.ink,"body")
    U.text(layer.opacity.."%",listX+57,ly+29,48,C.gray,"small")
    U.text(layer.blend,listX+106,ly+29,70,C.gray,"small")
    U.icon(layer.visible and "Eye" or "Selection",
      listX+listW-17,ly+27,16,C.ink)
    U.hitbox(listX+2,ly,listW-4,itemHeight-2,function() Model.selectLayer(s,i) end)
    U.hitbox(listX+listW-30,ly+6,28,45,function()
      layer.visible=not layer.visible
    end)
  end
  local bgY=footerY-58
  if bgY>innerY+60+limit*itemHeight then
    U.rect(listX+2,bgY,listW-4,51,{.95,.95,.95})
    U.text("Background",listX+46,bgY+18,listW-51,C.gray,"small")
    U.rect(listX+8,bgY+7,29,29,C.white)
    U.stroke(listX+8,bgY+7,29,29,C.gray)
  end
  local sideButtons={
    {"Plus",function()Model.addLayer(s)end},
    {"Duplicate",function()Model.duplicateLayer(s)end},
    {"Folder",function()Model.addLayer(s,"folder")end},
    {"Layer",function()Model.addLayer(s,"vector")end},
    {"Trash",function()Model.deleteLayer(s)end},
    {"More",function()s.menu=s.menu=="layerMore" and nil or "layerMore" end}
  }
  local sideH=36
  for i,item in ipairs(sideButtons) do
    local cy=innerY+18+(i-1)*sideH
    U.icon(item[1],toolsX+toolbarW/2,cy,21)
    U.hitbox(toolsX,cy-17,toolbarW,sideH,item[2])
  end
  U.rect(x+7,footerY,pw-12,95,{.08,.08,.08})
  U.icon("Down",x+25,footerY+18,20)
  U.text("Background",x+44,footerY+11,128,C.white,"small")
  U.button(s.blend,x+208,footerY+5,161,27,function()
    s.menu=s.menu=="blend" and nil or "blend"
  end,false,{.28,.28,.28})
  U.text("Opacity",x+15,footerY+43,102,C.white,"small")
  U.slider("a",x+102,footerY+44,pw-124,s.layerOpacity,0,100,
    function(v)Model.setLayerOpacity(s,v)end)
end
local swatches={
  {0,0,0},{1,1,1},{.9,.12,.18},{1,.47,.1},{1,.86,.2},{.2,.65,.3},
  {.08,.72,.8},{.1,.3,.85},{.43,.2,.8},{.9,.22,.6},
  {.43,.29,.2},{.64,.64,.64},{.9,.7,.55},{.12,.14,.16},
  {.35,.58,.7},{.79,.29,.27},{.58,.66,.34},{.44,.38,.61}
}
local function colorPanel(w,h)
  local pw=418
  local ph=math.min(h-108,526)
  local x=w-pw-15
  local y=80
  panelBox(x,y,pw,ph,"Color")
  U.text("Palette",x+15,y+47,130,C.white,"body")
  U.rect(x+13,y+75,150,202,{.82,.82,.82})
  -- Palette from visual reference, not extracted pixels.
  for i,col in ipairs(swatches) do
    local column=(i-1)%6
    local row=math.floor((i-1)/6)
    local px=x+19+column*24
    local py=y+84+row*32
    U.rect(px,py,22,28,col)
    U.stroke(px,py,22,28,C.gray)
    U.hitbox(px,py,22,28,function()
      Model.setColor(s,col[1],col[2],col[3])
    end)
  end
  for i=1,6 do
    local px=x+19+(i-1)*24
    U.rect(px,y+84+3*32,22,28,{1,1,1})
    U.stroke(px,y+84+3*32,22,28,C.gray)
  end
  U.text("Color History",x+16,y+285,142,C.white,"small")
  for i=1,5 do
    local col=swatches[math.min(i+1,#swatches)]
    local px=x+18+(i-1)*29
    U.rect(px,y+303,27,23,col)
    U.hitbox(px,y+303,27,23,function()
      Model.setColor(s,col[1],col[2],col[3])
    end)
  end

  local cx=x+289
  local cy=y+151
  local radius=102
  U.colorWheel(cx,cy,radius,s.color)
  -- Diamond-shaped saturation/value area, matching color picker structure.
  U.circle(cx,cy,75,{.31,.31,.31})
  local diamond=61
  local step=3
  for iy=-diamond,diamond,step do
    for ix=-diamond,diamond,step do
      if math.abs(ix)+math.abs(iy)<=diamond-step then
        local sat=math.max(0,math.min(1,(ix+diamond)/(2*diamond)))
        local bright=math.max(0,math.min(1,1-(iy+diamond)/(2*diamond)))
        local cr,cg,cb=U.hsv(s.hue,sat,bright)
        U.rect(cx+ix-3,cy+iy-3,step,step,{cr,cg,cb})
      end
    end
  end
  U.stroke(cx-5,cy-5,10,10,C.white,2)
  U.hitbox(cx-radius,cy-radius,2*radius,2*radius,function(rx,ry)
    local dx=rx*2-1; local dy=ry*2-1
    local dist=math.sqrt(dx*dx+dy*dy)
    if dist>.68 then
      local ang
      if math.abs(dx)<.0001 then
        ang=dy>=0 and math.pi*.5 or -math.pi*.5
      else
        ang=math.atan(dy/dx)
        if dx<0 then ang=ang+math.pi end
      end
      s.hue=((ang+math.pi*.5)/(2*math.pi))%1
      Model.setColor(s,U.hsv(s.hue,.95,1))
    else
      local sat=math.max(0,math.min(1,rx))
      local v=math.max(0,math.min(1,1-ry))
      Model.setColor(s,U.hsv(s.hue,sat,v))
    end
  end)
  local red=math.floor(s.color[1]*255+.5)
  local green=math.floor(s.color[2]*255+.5)
  local blue=math.floor(s.color[3]*255+.5)
  local colorCode=string.format("#%02X%02X%02X",red,green,blue)
  U.rect(x+15,y+347,62,29,s.color)
  U.text(colorCode,x+88,y+353,108,C.white,"body")
  U.button(s.colorMode or "HSB",x+283,y+343,110,31,function()
    s.colorMode=(s.colorMode=="RGB") and "HSB" or "RGB"
  end,false,{.38,.38,.38})
  local px=x+17;local py=y+388;local ww=pw-36
  if s.colorMode=="RGB" then
    U.slider("Red",px,py,ww,red,0,255,function(v)
      Model.setColor(s,v/255,s.color[2],s.color[3])
    end)
    U.slider("Green",px,py+38,ww,green,0,255,function(v)
      Model.setColor(s,s.color[1],v/255,s.color[3])
    end)
    U.slider("Blue",px,py+76,ww,blue,0,255,function(v)
      Model.setColor(s,s.color[1],s.color[2],v/255)
    end)
  else
    U.slider("H",px,py,ww,math.floor(s.hue*360),0,360,function(v)
      s.hue=v/360
      Model.setColor(s,U.hsv(s.hue,1,1))
    end)
    U.slider("S",px,py+38,ww,s.saturation or 100,0,100,function(v)
      s.saturation=v
      Model.setColor(s,U.hsv(s.hue,v/100,(s.brightness or 100)/100))
    end)
    U.slider("B",px,py+76,ww,s.brightness or 100,0,100,function(v)
      s.brightness=v
      Model.setColor(s,U.hsv(s.hue,(s.saturation or 100)/100,v/100))
    end)
  end
  U.text("a: 100%",px,y+ph-24,120,C.white,"small")
end
local function genericPanel(w,h)
  local name=s.panel
  if name=="tools" then
    local x=58;local y=82;local pw=268;local ph=math.min(h-160,452)
    U.rect(x,y,pw,ph,{.34,.34,.34,.94},5)
    U.hitbox(x,y,pw,ph,function() end)
    local cols=2
    local rows=math.ceil(#Model.tools/cols)
    local cw=(pw-12)/cols
    local ch=(ph-15)/rows
    for i,tool in ipairs(Model.tools) do
      local col=(i-1)%cols
      local row=math.floor((i-1)/cols)
      local xx=x+6+col*cw
      local yy=y+6+row*ch
      if s.tool==tool then U.rect(xx,yy,cw-2,ch-2,{.26,.47,.65,.75},3) end
      U.icon(tool,xx+cw*.5,yy+15,24)
      local label=tool=="Frame Divider" and "Frame Divider"
        or tool=="Magic Wand" and "Magic Wand"
        or tool=="Special" and "Special Pen" or tool
      U.text(label,xx+3,yy+29,cw-6,C.white,"small","center")
      U.hitbox(xx,yy,cw,ch,function() Model.setTool(s,tool) end)
    end
  elseif name=="size" then
    panelBox(172,h-181,290,125,"Brush Size")
    U.slider("Thickness",189,h-128,252,s.brushSize,1,120,function(v) Model.setBrushSize(s,v) end)
  else
    local x=w-333;local y=47
    panelBox(x,y,314,175,name:gsub("^%l",string.upper))
    U.text("Pending Windows 14.1.4 visual reference.",x+16,y+63,280,C.white,"body")
    U.text("Tool selection works; layout not verified.",x+16,y+104,280,C.pale,"small")
  end
end
local function dropdown(w,h)
  if not s.menu then return end
  local m=s.menu
  local items={}
  if m=="back" or m=="more" then
    items={{"Settings",enterSettings},{"Back to My Gallery",function()Model.openGallery(s)end}}
  elseif m=="view" then
    items={{"Reference Window",function()s.settings.reference=not s.settings.reference end},
      {"Grid",function()s.settings.showGrid=not s.settings.showGrid end}}
  elseif m=="blend" then
    items={{"Normal",function()Model.setBlend(s,"Normal")end},
      {"Multiply",function()Model.setBlend(s,"Multiply")end},
      {"Screen",function()Model.setBlend(s,"Screen")end},
      {"Overlay",function()Model.setBlend(s,"Overlay")end}}
  elseif m=="layerMore" then
    items={{"Add Folder",function()Model.addLayer(s,"folder")end},
      {"Add Vector Layer",function()Model.addLayer(s,"vector")end},
      {"Duplicate Layer",function()Model.duplicateLayer(s)end}}
  else items={{"Close",function()end}} end
  local pw=213;local itemH=33
  local x=(m=="blend" and w-223) or (w-224)
  local y=(m=="blend" and math.min(h-50-#items*itemH,h-180)) or 34
  U.rect(x,y,pw,#items*itemH,{0.25,0.25,0.25,0.98},4)
  U.hitbox(x,y,pw,#items*itemH,function() end)
  for i,item in ipairs(items) do
    local yy=y+(i-1)*itemH
    U.text(item[1],x+10,yy+8,pw-20,C.white,"body")
    U.hitbox(x,yy,pw,itemH,function() s.menu=nil;item[2]() end)
  end
end
local function editorScreen(w,h)
  drawCanvas(w,h)
  editorBar(w,h)
  if s.panel=="brush" then brushPanel(w,h)
  elseif s.panel=="layer" then layerPanel(w,h)
  elseif s.panel=="color" then colorPanel(w,h)
  elseif s.panel then genericPanel(w,h) end
  dropdown(w,h)
end
local function settingsScreen(w,h)
  U.rect(0,0,w,h,C.offwhite)
  U.rect(0,0,w,45,C.bar)
  U.text("Settings",24,12,280,C.white,"heading")
  U.button("Back",w-110,8,90,29,back)
  local x=math.max(24,(w-620)/2);local y=75;local width=620
  U.text("User Interface",x,y,width,C.ink,"heading")
  local settings={
    {"Reference Window","reference"},
    {"Invert Direction of Mouse Wheel","invertWheel"},
    {"Show Grid","showGrid"},
    {"Dark Canvas Background","darkCanvas"}
  }
  for i,it in ipairs(settings) do
    local yy=y+50+(i-1)*55
    U.rect(x,yy,width,45,{0.89,0.89,0.89},3)
    U.text(it[1],x+14,yy+12,450,C.ink,"body")
    U.button(s.settings[it[2]] and "ON" or "OFF",x+width-87,yy+6,76,33,function()
      s.settings[it[2]]=not s.settings[it[2]]
    end,s.settings[it[2]])
  end
  U.text("Some settings are awaiting verified Windows-specific screenshots.",
    x,y+310,width,C.gray,"small")
end
local function simpleScreen(w,h,title)
  U.rect(0,0,w,h,C.blue)
  U.text(title,0,h*.32,w,C.white,"heading","center")
  U.text("Requires verified Windows interface reference.",0,h*.42,w,C.pale,"body","center")
  U.button("Back",w/2-60,h*.55,120,38,back)
end

function love.load()
  love.window.setTitle("Ibis-Lua | Windows UI reference 14.1.4")
  love.window.setMode(1280,800,{resizable=true,minwidth=880,minheight=610})
  U.init()
  if screenshotMode=="gallery" or screenshotMode=="newCanvas" then
    Model.openGallery(s)
    if screenshotMode=="newCanvas" then Model.openNewCanvas(s) end
  elseif screenshotMode=="editor" or screenshotMode=="brush"
      or screenshotMode=="layer" or screenshotMode=="color"
      or screenshotMode=="tools" then
    Model.openGallery(s)
    Model.createCanvas(s)
    if screenshotMode~="editor" then s.panel=screenshotMode end
  end
end
function love.update(dt)
  if not screenshotMode then return end
  screenshotElapsed=screenshotElapsed+dt
  if screenshotElapsed>0.35 and not screenshotTaken then
    lg.captureScreenshot("ibis-lua-"..screenshotMode..".png")
    screenshotTaken=true
  elseif screenshotElapsed>1.35 and screenshotTaken then
    love.event.quit()
  end
end
function love.draw()
  local w,h=lg.getDimensions()
  U.begin()
  if s.page=="title" then titleScreen(w,h)
  elseif s.page=="gallery" then galleryScreen(w,h)
  elseif s.page=="editor" then editorScreen(w,h)
  elseif s.page=="settings" then settingsScreen(w,h)
  else simpleScreen(w,h,s.page=="collection" and "Collection" or "Online Gallery") end
  if s.modal=="newCanvas" then newCanvasDialog(w,h) end
  if s.notification then
    U.rect(w/2-230,h-96,460,35,{0.18,0.18,0.18,0.91},5)
    U.text(s.notification,w/2-218,h-88,436,C.white,"small","center")
    U.hitbox(w/2-230,h-96,460,35,function()s.notification=nil end)
  end
end
function love.mousepressed(x,y,button)
  if button==1 then
    if U.dispatch(x,y) then return end
    if s.page=="editor" then dragging=love.keyboard.isDown("space");lastX=x;lastY=y end
  elseif button==2 and s.page=="editor" and s.tool=="Brush" then
    Model.togglePanel(s,"color")
  end
end
function love.mousereleased() dragging=false end
function love.mousemoved(x,y,dx,dy)
  if dragging and s.page=="editor" then
    s.panX=s.panX+dx;s.panY=s.panY+dy
  end
end
function love.wheelmoved(dx,dy)
  if s.page=="editor" then
    local delta=s.settings.invertWheel and -dy or dy
    Model.setZoom(s,s.zoom+delta*10)
  end
end
function love.keypressed(key)
  if s.focus then
    if key=="backspace" then
      s[s.focus]=math.floor((tonumber(s[s.focus]) or 0)/10)
    elseif key=="return" or key=="kpenter" or key=="escape" then s.focus=nil end
    return
  end
  if key=="escape" then back();return end
  if s.page~="editor" then return end
  if key=="b" then Model.setTool(s,"Brush")
  elseif key=="e" then Model.setTool(s,"Eraser")
  elseif key=="l" then Model.togglePanel(s,"layer")
  elseif key=="leftbracket" then Model.setBrushSize(s,s.brushSize-1)
  elseif key=="rightbracket" then Model.setBrushSize(s,s.brushSize+1)
  elseif key=="f12" then
    lg.captureScreenshot(os.date("ibis-lua-%Y%m%d-%H%M%S.png"))
    s.notification="Screenshot queued in the LOVE save directory."
  end
end
function love.textinput(text)
  if s.focus and text:match("^%d$") then
    s[s.focus]=math.min(16000,tonumber(tostring(s[s.focus])..text) or 1)
  end
end
