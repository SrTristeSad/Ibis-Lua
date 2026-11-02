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
  U.text("ibisPaint",x,y,500,C.white,"title")
  U.text("Ver. 14.1.4 (Windows reference)",x+126,y+52,350,C.white,"small")
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
  U.text("Online previews not yet reproduced - source assets are not bundled.",
    0,h*.82,w,C.pale,"body","center")
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
  local left=49;local top=31;local bottom=h-53
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
  local top=31;local bottom=h-51
  U.rect(0,0,w,top,{0.89,0.89,0.89})
  U.text("ibisPaint  |  "..s.workName,55,8,w*.58,C.ink,"small")
  U.rect(0,top,49,bottom-top,{0.43,0.43,0.43})
  local stride=math.min(46,(bottom-top)/#Model.tools)
  for i,name in ipairs(Model.tools) do
    local yy=top+(i-1)*stride
    U.toolButton(name,0,yy,49,stride,s.tool==name,function() Model.setTool(s,name) end)
  end
  U.rect(0,bottom,w,h-bottom,{0.42,0.42,0.42})
  local cy=bottom+23
  U.button("B/E",61,bottom+8,48,30,function()
    Model.setTool(s,s.tool=="Brush" and "Eraser" or "Brush")
  end)
  U.button("Tool",118,bottom+8,54,30,function() Model.togglePanel(s,"tools") end)
  U.button("Size",180,bottom+8,55,30,function() Model.togglePanel(s,"size") end)
  U.circle(261,cy,14,s.color)
  U.circle(261,cy,14,C.white,true)
  U.hitbox(246,bottom+6,34,36,function() Model.togglePanel(s,"color") end)
  U.button("Layer",295,bottom+8,61,30,function() Model.togglePanel(s,"layer") end)
  U.button("Undo",w*.48,bottom+8,56,30,function() s.notification="No painting engine: nothing to undo." end)
  U.button("Redo",w*.48+64,bottom+8,56,30,function() s.notification="No painting engine: nothing to redo." end)
  U.text(s.zoom.."%",w-235,bottom+15,55,C.white,"small","center")
  U.button("-",w-173,bottom+8,36,30,function() Model.setZoom(s,s.zoom-10) end)
  U.button("+",w-135,bottom+8,36,30,function() Model.setZoom(s,s.zoom+10) end)
  U.button("Back",w-92,bottom+8,82,30,function() s.menu=s.menu=="back" and nil or "back" end)
  local topY=2
  U.button("View",w-248,topY,55,26,function() s.menu=s.menu=="view" and nil or "view" end)
  U.button("Select",w-190,topY,60,26,function() Model.togglePanel(s,"selection") end)
  U.button("Ruler",w-127,topY,58,26,function() Model.togglePanel(s,"ruler") end)
  U.button("...",w-64,topY,54,26,function() s.menu=s.menu=="more" and nil or "more" end)
end
local function brushPanel(w,h)
  local pw=math.min(620,w-70);local ph=math.min(604,h-115)
  local x=57;local y=39
  panelBox(x,y,pw,ph,"Brush ("..#Model.brushes..")")
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
      U.line(x+25,yy+27,x+100,yy+11,C.ink,math.max(1,(i%6)+1))
      U.text(Model.brushes[i],x+112,yy+11,listW-128,C.ink,"small")
      U.hitbox(x+12,yy,listW-18,36,function() Model.setBrush(s,i) end)
    end
  else
    U.text(s.brushTab.." brushes",x+15,y+102,listW-30,C.ink,"body")
  end
  local sx=x+listW+15;local sw=pw-listW-29
  U.text(Model.brushes[s.brush],sx,y+51,sw,C.white,"body")
  U.text("Basic   Fade   Shape",sx,y+88,sw,C.pale,"small")
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
  local pw=304;local ph=math.min(573,h-92);local x=w-pw-12;local y=40
  panelBox(x,y,pw,ph,"Layer")
  U.rect(x+9,y+42,pw-18,54,{0.9,0.9,0.9})
  U.text("Selection Layer",x+54,y+61,pw-66,C.ink,"body")
  U.stroke(x+14,y+54,28,28,C.gray)
  local rows=math.min(#s.layers,math.floor((ph-230)/67))
  for i=1,rows do
    local ly=y+100+(i-1)*67
    local layer=s.layers[i]
    U.rect(x+9,ly,pw-18,65,s.selectedLayer==i and {0.7,0.82,0.93} or {0.86,0.86,0.86})
    U.rect(x+17,ly+6,50,50,C.white)
    U.stroke(x+17,ly+6,50,50,C.gray)
    U.text(layer.name,x+80,ly+10,132,C.ink,"body")
    U.text(layer.opacity.."%   "..layer.blend,x+80,ly+33,145,C.ink,"small")
    U.text(layer.visible and "eye" or "hide",x+242,ly+20,38,C.ink,"small")
    U.hitbox(x+9,ly,pw-18,65,function() Model.selectLayer(s,i) end)
    U.hitbox(x+234,ly+5,50,52,function() layer.visible=not layer.visible end)
  end
  local fy=y+ph-117
  U.button("+",x+10,fy,40,31,function() Model.addLayer(s) end)
  U.button("Duplicate",x+55,fy,83,31,function() Model.duplicateLayer(s) end)
  U.button("Delete",x+143,fy,77,31,function() Model.deleteLayer(s) end)
  U.button("More",x+226,fy,68,31,function() s.menu=s.menu=="layerMore" and nil or "layerMore" end)
  U.text("Blending Mode",x+14,fy+39,110,C.white,"small")
  U.button(s.blend,x+126,fy+35,168,28,function()
    s.menu=s.menu=="blend" and nil or "blend"
  end)
  U.slider("Opacity",x+14,fy+72,pw-28,s.layerOpacity,0,100,function(v) Model.setLayerOpacity(s,v) end)
end
local swatches={
  {0,0,0},{1,1,1},{.9,.12,.18},{1,.47,.1},{1,.86,.2},{.2,.65,.3},
  {.08,.72,.8},{.1,.3,.85},{.43,.2,.8},{.9,.22,.6},
  {.43,.29,.2},{.64,.64,.64},{.9,.7,.55},{.12,.14,.16},
  {.35,.58,.7},{.79,.29,.27},{.58,.66,.34},{.44,.38,.61}
}
local function colorPanel(w,h)
  local pw=318;local ph=420;local x=w-pw-16;local y=46
  panelBox(x,y,pw,ph,"Color")
  U.rect(x+16,y+49,280,124,{1,1,1})
  for i=1,14 do
    local r=i/14
    U.rect(x+16+(i-1)*20,y+49,20,124,{r,0.32,1-r})
  end
  U.text("Palette",x+16,y+186,90,C.white,"body")
  for i,col in ipairs(swatches) do
    local coln=(i-1)%6
    local row=math.floor((i-1)/6)
    local sx=x+16+coln*47;local sy=y+219+row*49
    U.rect(sx,sy,39,39,col,3)
    U.stroke(sx,sy,39,39,C.gray)
    U.hitbox(sx,sy,39,39,function() Model.setColor(s,col[1],col[2],col[3]) end)
  end
  U.rect(x+17,y+369,47,32,s.color)
  U.text("Current color",x+72,y+377,200,C.white,"body")
end
local function genericPanel(w,h)
  local name=s.panel
  if name=="tools" then
    local x=58;local y=52;local pw=227;local ph=math.min(h-115,640)
    panelBox(x,y,pw,ph,"Tool Selection")
    local rowH=(ph-48)/#Model.tools
    for i,tool in ipairs(Model.tools) do
      U.toolButton(tool,x+4,y+38+(i-1)*rowH,pw-8,rowH,s.tool==tool,
        function() Model.setTool(s,tool) end)
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
      or screenshotMode=="layer" or screenshotMode=="color" then
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
