-- Ibis-Lua. Windows reference-based UI reconstruction, not the official application.
-- Layout evidence: Windows gallery/new canvas (Uptodown), Windows tool editor
-- (Microsoft Store, independent Windows screenshots), official tool manual.
-- Fidelity to version 14.1.4 is NOT yet certified. No paint/image engine.
local Model = require("src.model")
local Viewport = require("src.viewport")
local state = Model.new()
local view = Viewport.new()
local controls = {}
local font = {}
local scale, W, H = 1, 1024, 768
local panel, gallery_menu = nil, nil
local gallery_scroll, preset_selected = 0, 1
local current_width, current_height = "1000", "1000"
local focus, opacity, size_zoom = nil, 100, 100
local input_replace = true
local layer_press = nil
local selected_brush, palette_index = 1, 1
local toast, toast_until = nil, 0
local smoke = os.getenv("IBIS_LUA_SMOKE") == "1"
local e2e = os.getenv("IBIS_LUA_E2E") == "1"
local e2e_stage = 0
local smoke_screen = os.getenv("IBIS_LUA_SCREEN") or "title"
local capture_requested, capture_done, capture_pending, capture_error = false, false, false, nil
local C = {
    background={0.75,0.76,0.76}, bar={0.365,0.365,0.365},
    deep={0.17,0.17,0.17}, dark={0.23,0.23,0.23},
    light={0.90,0.90,0.90}, paper={0.973,0.972,0.951},
    blue={0.12,0.48,0.75}, title={0.145,0.295,0.46},
    ranking={0.09,0.18,0.29}, ink={0.12,0.12,0.12},
    white={1,1,1}, soft={0.80,0.80,0.80},
}
local tools = {
    {"Transform","transform"},{"Magic Wand","magic_wand"},{"Lasso","lasso"},
    {"Filter","filter"},{"Brush","brush"},{"Eraser","eraser"},
    {"Smudge","smudge"},{"Blur","blur"},{"Special","special_pen"},
    {"Bucket","bucket"},{"Vector","vector"},{"Text","text"},
    {"Frame Divider","frame_divider"},{"Eyedropper","eyedropper"},{"Canvas","canvas"}
}
local presets = {
    {"SD (Speed)",1024,768},{"1 : 1 (SD)",1280,1280},{"3 : 4 (SD)",1024,768},
    {"9 : 16 (SD)",720,1280},{"Twitter Header",1500,500},
    {"Chat Stamp",370,320},{"Vertical",690,4096},
    {"Manga Manuscript",2576,3648},{"Postcard (JP)",1748,1181},
    {"A4",1754,1240},{"A5",1240,874},{"B4",2085,1476},{"B5",1476,1039}
}
local palette = {
    {0,0,0},{255,255,255},{235,48,48},{252,147,33},
    {249,229,49},{34,171,65},{16,182,222},{33,88,209},
    {109,55,184},{245,80,177},{140,140,140},{181,107,55}
}

local function rgba(rgb,alpha)
    love.graphics.setColor(rgb[1],rgb[2],rgb[3],alpha or 1)
end
local function rectangle(x,y,w,h,col,alpha,round)
    rgba(col,alpha)
    love.graphics.rectangle("fill",x,y,w,h,round or 0,round or 0)
end
local function stroke(x,y,w,h,col,alpha)
    rgba(col,alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line",x,y,w,h)
end
local function line(x1,y1,x2,y2,width,col,alpha)
    rgba(col or C.white,alpha)
    love.graphics.setLineWidth(width or 1.5)
    love.graphics.line(x1,y1,x2,y2)
end
local function label(s,x,y,w,typ,align,col)
    love.graphics.setFont(font[typ or "normal"])
    rgba(col or C.white)
    love.graphics.printf(tostring(s),x,y,w,align or "left")
end
local function hit(x,y,w,h,fn,key)
    controls[#controls+1] = {x=x,y=y,w=w,h=h,fn=fn,key=key}
end
local function pointer()
    local x,y = love.mouse.getPosition()
    return x/scale,y/scale
end
local function over(x,y,w,h)
    local mx,my=pointer()
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end
local function notice(s)
    toast=s
    toast_until=love.timer.getTime()+3.5
end
local function current()
    return state.screen=="editor"
end
local function set_panel(name)
    if panel==name then panel=nil else panel=name end
    if name=="brush" or name=="layer" or name=="color" then
        state.active_panel=panel==name and name or nil
    else
        state.active_panel=nil
    end
end
local picker_hue=0
local function hsv_rgb(h,s,v)
    h=(h%1)*6
    local i=math.floor(h)
    local f=h-i
    local p=v*(1-s)
    local q=v*(1-f*s)
    local t=v*(1-(1-f)*s)
    if i==0 then return {v,t,p}
    elseif i==1 then return {q,v,p}
    elseif i==2 then return {p,v,t}
    elseif i==3 then return {p,q,v}
    elseif i==4 then return {t,p,v}
    else return {v,p,q} end
end
local function draw_hue_wheel(cx,cy,r)
    local steps=72
    for i=0,steps-1 do
        local a=-math.pi/2+i*2*math.pi/steps
        local b=-math.pi/2+(i+1)*2*math.pi/steps
        rgba(hsv_rgb(i/steps,1,1))
        love.graphics.polygon("fill",
            cx+math.cos(a)*r,cy+math.sin(a)*r,
            cx+math.cos(b)*r,cy+math.sin(b)*r,
            cx+math.cos(b)*(r-17),cy+math.sin(b)*(r-17),
            cx+math.cos(a)*(r-17),cy+math.sin(a)*(r-17))
    end
    local N=24
    local radius=r-23
    for i=0,N-1 do
        for j=0,N-1 do
            local u=(i+0.5)/N
            local v=(j+0.5)/N
            rgba(hsv_rgb(picker_hue,u,1-v))
            local function q(uu,vv)
                return cx+(uu-vv)*radius,cy+(uu+vv-1)*radius
            end
            local x1,y1=q(i/N,j/N)
            local x2,y2=q((i+1)/N,j/N)
            local x3,y3=q((i+1)/N,(j+1)/N)
            local x4,y4=q(i/N,(j+1)/N)
            love.graphics.polygon("fill",x1,y1,x2,y2,x3,y3,x4,y4)
        end
    end
    rgba(C.white)
    love.graphics.setLineWidth(1.4)
    love.graphics.polygon("line",cx,cy-radius,cx+radius,cy,cx,cy+radius,cx-radius,cy)
    local t=picker_hue*2*math.pi-math.pi/2
    love.graphics.circle("line",cx+math.cos(t)*(r-8),cy+math.sin(t)*(r-8),6)
end

local function outline_circle(x,y,r,alpha)
    rgba(C.white,alpha or 0.8)
    love.graphics.setLineWidth(1.6)
    love.graphics.circle("line",x,y,r)
end

-- Manually constructed icon geometry, tied to visible Windows reference imagery;
-- none of these are extracted proprietary graphic assets or certified pixel copies.
local function glyph(name,cx,cy,r)
    local g=love.graphics
    g.push()
    g.translate(cx,cy)
    local d=r/12
    rgba(C.white,0.94)
    g.setLineWidth(math.max(1.2,d*1.65))
    if name=="brush" or name=="pen" then
        g.rotate(math.pi/4)
        g.rectangle("line",-3*d,-9*d,6*d,13*d,1.5*d,1.5*d)
        g.line(-3*d,4*d,0,10*d,3*d,4*d)
        g.line(-3*d,-5*d,3*d,-5*d)
    elseif name=="eraser" then
        g.rotate(-math.pi/4)
        g.polygon("line",-8*d,-5*d,5*d,-5*d,8*d,4*d,-5*d,4*d)
        g.line(-1*d,-5*d,2*d,4*d)
    elseif name=="transform" then
        g.line(-8*d,0,8*d,0)
        g.line(0,-8*d,0,8*d)
        g.polygon("fill",-10*d,0,-5*d,-3*d,-5*d,3*d)
        g.polygon("fill",10*d,0,5*d,-3*d,5*d,3*d)
        g.polygon("fill",0,-10*d,-3*d,-5*d,3*d,-5*d)
        g.polygon("fill",0,10*d,-3*d,5*d,3*d,5*d)
    elseif name=="magic_wand" or name=="special_pen" then
        g.line(-7*d,8*d,5*d,-6*d)
        g.line(-9*d,-7*d,-5*d,-7*d)
        g.line(-7*d,-9*d,-7*d,-5*d)
        g.line(4*d,-9*d,4*d,-4*d)
        g.line(2*d,-7*d,6*d,-7*d)
        g.line(7*d,1*d,7*d,5*d)
        g.line(5*d,3*d,9*d,3*d)
    elseif name=="lasso" then
        g.ellipse("line",0,-2*d,8*d,6*d)
        g.line(-4*d,3*d,-5*d,9*d,0,5*d)
    elseif name=="filter" then
        g.circle("line",0,0,9*d)
        g.setFont(font.icon)
        g.print("FX",-7*d,-6*d)
    elseif name=="smudge" then
        g.line(-5*d,7*d,-5*d,-3*d,-2*d,-8*d,1*d,-6*d,1*d,2*d)
        g.line(1*d,0,4*d,-2*d,6*d,1*d,5*d,8*d,-5*d,8*d)
    elseif name=="blur" then
        g.polygon("line",0,-10*d,-7*d,2*d,-6*d,7*d,0,10*d,6*d,7*d,7*d,2*d)
    elseif name=="bucket" then
        g.rotate(-math.pi/4)
        g.rectangle("line",-7*d,-4*d,12*d,10*d)
        g.line(-7*d,-4*d,5*d,-4*d)
    elseif name=="vector" then
        g.polygon("line",-6*d,-10*d,8*d,3*d,1*d,4*d,-1*d,10*d)
    elseif name=="text" then
        g.setFont(font.big_icon)
        g.print("T",-8*d,-13*d)
    elseif name=="frame_divider" then
        g.rectangle("line",-9*d,-9*d,18*d,18*d)
        g.line(-9*d,0,9*d,0)
        g.line(0,-9*d,0,9*d)
    elseif name=="eyedropper" then
        g.rotate(-math.pi/4)
        g.rectangle("line",-2*d,-7*d,5*d,13*d)
        g.line(-2*d,6*d,0,10*d,3*d,6*d)
        g.line(-5*d,-7*d,6*d,-7*d)
    elseif name=="canvas" then
        g.rectangle("line",-9*d,-8*d,18*d,15*d)
        g.line(-5*d,9*d,5*d,9*d)
    elseif name=="color" then
        g.circle("line",0,0,9*d)
        local cols={{1,0.22,0.25},{1,0.83,0.05},{0.22,0.79,0.34},{0.15,0.65,1},{0.65,0.3,0.9}}
        for i,col in ipairs(cols) do
            local a=-math.pi/2+(i-1)*2*math.pi/#cols
            g.setColor(col)
            g.arc("fill","pie",0,0,7.7*d,a,a+2*math.pi/#cols)
        end
        rgba(C.white)
        g.circle("fill",0,0,3*d)
    elseif name=="layer" then
        g.rectangle("line",-5*d,-7*d,12*d,11*d)
        g.rectangle("line",-8*d,-4*d,12*d,11*d)
    elseif name=="back" then
        g.line(5*d,-8*d,-4*d,0,5*d,8*d)
    elseif name=="undo" or name=="redo" then
        if name=="redo" then g.scale(-1,1) end
        g.arc("line","open",0,2*d,8*d,-math.pi*0.9,math.pi*0.55)
        g.line(-8*d,-2*d,-8*d,5*d,-2*d,2*d)
    elseif name=="plus" then
        g.line(-9*d,0,9*d,0)
        g.line(0,-9*d,0,9*d)
    elseif name=="fullscreen" then
        g.line(-8*d,-3*d,-8*d,-8*d,-3*d,-8*d)
        g.line(8*d,3*d,8*d,8*d,3*d,8*d)
        g.line(-8*d,3*d,-8*d,8*d,-3*d,8*d)
        g.line(8*d,-3*d,8*d,-8*d,3*d,-8*d)
    elseif name=="settings" then
        g.circle("line",0,0,8*d)
        g.circle("line",0,0,3*d)
    elseif name=="selection" then
        g.setLineStyle("rough")
        g.rectangle("line",-8*d,-8*d,16*d,16*d)
        g.setLineStyle("smooth")
    elseif name=="stabilizer" then
        g.line(-9*d,5*d,9*d,-5*d)
        g.circle("line",-5*d,-2*d,3*d)
    elseif name=="shape" then
        g.circle("line",-3*d,-3*d,6*d)
        g.rectangle("line",-2*d,-2*d,11*d,11*d)
    elseif name=="ruler" then
        g.rotate(-math.pi/4)
        g.rectangle("line",-9*d,-4*d,18*d,8*d)
        for i=-6,6,4 do g.line(i*d,-4*d,i*d,0) end
    elseif name=="material" then
        g.rectangle("line",-9*d,-8*d,18*d,16*d)
        g.polygon("line",-8*d,6*d,-2*d,-1*d,2*d,4*d,5*d,0,9*d,6*d)
    elseif name=="globe" then
        g.circle("line",0,0,9*d)
        g.ellipse("line",0,0,4*d,9*d)
        g.line(-9*d,0,9*d,0)
        g.arc("line","open",0,0,6*d,0.7,2.45)
        g.arc("line","open",0,0,6*d,3.85,5.6)
    elseif name=="more" then
        g.circle("fill",-6*d,0,1.5*d)
        g.circle("fill",0,0,1.5*d)
        g.circle("fill",6*d,0,1.5*d)
    elseif name=="play" then
        g.polygon("fill",-5*d,-8*d,8*d,0,-5*d,8*d)
    elseif name=="check" then
        g.line(-8*d,-1*d,-2*d,6*d,9*d,-7*d)
    elseif name=="eye" then
        g.ellipse("line",0,0,9*d,5*d)
        g.circle("fill",0,0,2.3*d)
    end
    g.pop()
end
local function icon_button(x,y,w,h,name,fn,active,disabled)
    if active then rectangle(x,y,w,h,C.blue,0.7,3)
    elseif over(x,y,w,h) and not disabled then rectangle(x,y,w,h,C.white,0.14,3) end
    glyph(name,x+w/2,y+h/2,math.min(w,h)*0.33)
    if fn and not disabled then hit(x,y,w,h,fn,name) end
end
local function plain_button(x,y,w,h,name,fn,accent)
    rectangle(x,y,w,h,accent and C.blue or C.deep,over(x,y,w,h) and 0.94 or 0.80,3)
    label(name,x,y+(h-17)/2,w,"normal","center",C.white)
    hit(x,y,w,h,fn,name)
end
local function title_screen()
    rectangle(0,0,W,H*0.66,C.title)
    rectangle(0,H*0.66,W,H*0.34,C.ranking)
    local cx=W/2
    label("ibis",cx-215,H*0.19,148,"logo","right",C.white)
    glyph("color",cx-15,H*0.19+38,34)
    label("Paint",cx+29,H*0.19,210,"logo","left",C.white)
    label("Ver. 14.1.4",cx+82,H*0.19+85,150,"small","left",C.white)
    local function circular(x,name,labeltext,fn)
        local cy=H*0.43
        rgba(C.white,over(x-52,cy-52,104,126) and 1 or 0.75)
        love.graphics.setLineWidth(1.8)
        love.graphics.circle("line",x,cy,50)
        glyph(name,x,cy,27)
        label(labeltext,x-105,cy+66,210,"normal","center",C.white)
        hit(x-54,cy-54,108,138,fn,name)
    end
    circular(cx-131,"brush","My Gallery",function() state:open_gallery() end)
    circular(cx+131,"globe","Online Gallery",function()
        love.system.openURL("https://ibispaint.com/")
    end)
    label("Daily Ranking",0,H*0.69,W,"header","center",C.white)
    line(W*0.12,H*0.75,W*0.88,H*0.75,1,C.white,0.25)
    label("Online Gallery",0,H*0.83,W,"normal","center",C.soft)
end

local function gallery_header()
    rectangle(0,0,W,48,C.dark)
    label("My Gallery ("..tostring(state.document and 1 or 0)..")",74,12,275,"normal","left",C.white)
    icon_button(8,3,48,42,"back",function() state.screen="title" end)
    local actions={
        {"plus",function() state:open_new_canvas();gallery_menu=nil end},
        {"settings",function() gallery_menu=gallery_menu=="cloud" and nil or "cloud" end},
        {"play",function() notice("Reprodução indisponível sem motor de pintura.") end},
        {"material",function() notice("Exportação real excluída deste projeto.") end},
        {"more",function() gallery_menu=gallery_menu=="more" and nil or "more" end}
    }
    local start=W-270
    for i,a in ipairs(actions) do icon_button(start+(i-1)*42,4,39,40,a[1],a[2]) end
    label("Select",W-81,14,50,"small","center",C.white)
    hit(W-86,4,55,40,function() gallery_menu="select" end,"select")
    label("Edit",W-38,14,37,"small","center",C.white)
    hit(W-42,4,40,40,function() gallery_menu="edit" end,"edit")
end
local function gallery_screen()
    rectangle(0,0,W,H,C.paper)
    gallery_header()
    rectangle(0,49,W,34,{0.94,0.94,0.92})
    label("Cloud Synchronization",16,57,205,"small","left",{0.52,0.52,0.52})
    rectangle(220,57,35,18,{0.80,0.80,0.80},1,9)
    rgba(C.white);love.graphics.circle("fill",229,66,8)
    hit(214,51,48,30,function() gallery_menu="cloud" end,"cloud")
    if state.document then
        rectangle(40,130,160,206,C.white,1,2)
        rectangle(54,143,132,160,{0.93,0.93,0.93})
        label(tostring(state.document.width).." x "..tostring(state.document.height),45,316,150,"small","center",C.ink)
        hit(40,130,160,216,function() state.screen="editor" end,"artwork")
    else
        label("There is no artwork.",0,H*0.54,W,"small","center",{0.63,0.63,0.63})
        label("Press '+' button to create a new artwork.",0,H*0.54+23,W,"small","center",{0.63,0.63,0.63})
    end
    if gallery_menu and state.modal~="new_canvas" then
        local x=W-245
        rectangle(x,49,238,138,C.dark,0.95,3)
        local text_map={cloud="Cloud Synchronization (offline)",select="Selection: no artworks selected",
           edit="Edit: demonstration only",more="My Gallery options"}
        label(text_map[gallery_menu] or "",x+10,66,218,"small","center",C.white)
        plain_button(x+22,124,190,33,"Close",function() gallery_menu=nil end)
    end
    if state.modal=="new_canvas" then
        draw_new_canvas()
    end
end

-- This side-aligned full-height panel follows the WINDOWS screenshot,
-- replacing the ungrounded central modal used in prior commits.
function draw_new_canvas()
    local pw=math.min(700,math.max(440,W*0.69))
    local px=W-pw-4
    rectangle(px-3,47,pw+7,H-48,C.deep,0.98,2)
    rectangle(px,50,pw,H-54,C.light)
    rectangle(px,50,pw,28,C.dark)
    label("New Canvas",px,55,pw,"small","center",C.white)
    -- Bloqueio da tela sob o painel: o cabeçalho da galeria não recebe cliques.
    hit(0,0,W,H,function() end,"canvas_panel_capture")
    hit(0,48,px-3,H-48,function()
        state:cancel_new_canvas();focus=nil
    end,"outside_canvas_panel")
    -- Content area is clipped, independently scrolled by the mouse wheel.
    local top=80
    love.graphics.setScissor(px*scale,top*scale,pw*scale,(H-top-42)*scale)
    local yy=top-gallery_scroll
    local function row(n,y,extra,fn)
        local ry=y
        rectangle(px+2,ry,pw-5,extra or 29,{0.88,0.88,0.88})
        line(px+2,ry+extra-1,px+pw-3,ry+extra-1,1,{0.73,0.73,0.73})
        label(n,px+31,ry+6,pw-170,"small","left",C.ink)
        if fn and ry>=top and ry < H-70 then
            hit(px+2,ry,pw-5,extra or 29,fn,"preset")
        end
    end
    row("Import Picture",yy,35,function()
        notice("Importar imagem exige o motor de obras, excluído nesta fase.")
    end)
    label("W",px+15,yy+43,18,"small","left",C.ink)
    label("H",px+15,yy+70,18,"small","left",C.ink)
    for i,f in ipairs({{key="width",value=current_width},{key="height",value=current_height}}) do
        local y=yy+42+(i-1)*28
        rectangle(px+39,y,pw*0.25,24,C.white)
        stroke(px+39,y,pw*0.25,24,focus==f.key and C.blue or C.soft)
        label(f.value,px+43,y+3,pw*0.25-8,"small","center",C.ink)
        hit(px+39,y,pw*0.25,24,function() focus=f.key;input_replace=true end,"input_"..f.key)
        local sx=px+pw*0.32
        line(sx,y+12,sx+pw*0.56,y+12,4,{0.68,0.68,0.68})
        rectangle(sx+pw*0.14,y+5,14,14,C.white,1,7)
        hit(sx,y,sx+pw*0.56-sx,24,function() notice("Use o campo numérico para alterar a dimensão.") end,"slider")
    end
    label("Speed ↔ Quality",px,yy+108,pw,"small","center",{0.30,0.30,0.30})
    yy=yy+128
    for i,p in ipairs(presets) do
        local row_y=yy+(i-1)*30
        if row_y+30>=top and row_y<=H-42 then
            local selected=preset_selected==i
            rectangle(px+4,row_y,pw-8,29,selected and {0.78,0.84,0.88} or C.light)
            stroke(px+5,row_y+4,22,20,{0.45,0.45,0.45})
            label(p[1],px+36,row_y+6,pw-205,"small","left",C.ink)
            label(p[2].." x "..p[3],px+pw-156,row_y+6,144,"small","right",C.ink)
            line(px+3,row_y+29,px+pw-6,row_y+29,1,{0.73,0.73,0.73})
            hit(px+4,row_y,pw-8,29,function()
                preset_selected=i
                current_width=tostring(p[2]);current_height=tostring(p[3])
                focus=nil;input_replace=true
            end,"preset_"..i)
        end
    end
    love.graphics.setScissor()
    rectangle(px,H-42,pw,38,C.dark)
    label("Pixels",px+12,H-32,66,"small","left",C.white)
    plain_button(px+pw-136,H-38,127,30,"OK",function()
        local ww,hh=tonumber(current_width),tonumber(current_height)
        if not ww or not hh or ww<1 or hh<1 or ww>16384 or hh>16384
        or ww~=math.floor(ww) or hh~=math.floor(hh) then
            notice("Informe dimensões inteiras de 1 a 16384 pixels.")
            return
        end
        state:create_canvas(ww,hh)
        view:reset()
        panel=nil;gallery_menu=nil;focus=nil
    end,true)
end

local function draw_editor_toolbar()
    local bottom=H-51
    rectangle(0,bottom,W,51,C.bar)
    -- Main toolbar: Brush/Eraser, Tool Select, Properties, Color, Fullscreen,
    -- Undo, Redo, Layer, Back (verified official control order).
    local entries={
        {"brush",function()
            state:set_tool(state.active_tool=="eraser" and "brush" or "eraser")
        end},
        {"transform",function() set_panel("tools") end},
        {"settings",function() set_panel("brush") end},
        {"color",function() set_panel("color") end},
        {"fullscreen",function()
            love.window.setFullscreen(not love.window.getFullscreen())
        end},
        {"undo",function() notice("Nenhuma alteração de pintura para desfazer.") end},
        {"redo",function() notice("Nenhuma alteração de pintura para refazer.") end},
        {"layer",function() set_panel("layer") end},
        {"back",function() set_panel("back") end}
    }
    local gap=math.min(128,(W-60)/9)
    local start=(W-gap*9)/2
    for i,e in ipairs(entries) do
        local active=(i==1 and state.active_tool=="brush")
            or (i==8 and panel=="layer")
        icon_button(start+(i-1)*gap+4,bottom+3,gap-8,45,
            i==1 and (state.active_tool=="eraser" and "eraser" or "brush") or e[1],e[2],active)
    end
end
local function draw_size_controls()
    local y=H-78
    rectangle(0,y,W,27,{0.70,0.70,0.70},0.93)
    label(string.format("%.1f px",state.brush_size),15,y+7,84,"small","left",C.ink)
    rectangle(100,y+12,math.min(W*0.25,230),3,{0.95,0.95,0.95})
    rectangle(100,y+12,math.min(W*0.25,230)*(state.brush_size/100),3,C.deep)
    local x=100+math.min(W*0.25,230)*math.min(state.brush_size/100,1)
    rgba(C.white);love.graphics.circle("fill",x,y+13,8)
    hit(100,y,math.min(W*0.25,230),27,function()
        local mx=pointer()
        state:set_brush_size(math.max(0.1,math.floor((mx-100)/math.min(W*0.25,230)*1000)/10))
    end,"brush_slider")
    local x2=W*0.48
    label(tostring(opacity).."%",x2,y+7,49,"small","left",C.ink)
    rectangle(x2+61,y+12,math.min(250,W*0.24),3,{0.97,0.97,0.97})
    rectangle(x2+61,y+12,math.min(250,W*0.24)*opacity/100,3,C.dark)
    rgba(C.white);love.graphics.circle("fill",x2+61+math.min(250,W*0.24)*opacity/100,y+13,8)
    hit(x2+61,y,math.min(250,W*0.24),27,function()
        local mx=pointer()
        opacity=math.max(0,math.min(100,math.floor((mx-x2-61)/math.min(250,W*0.24)*100+0.5)))
    end,"opacity_slider")
end

local function editor_screen()
    rectangle(0,0,W,H,C.background)
    local right=W-5
    local space_left=62
    local aw=W-space_left-34
    local ah=H-111
    local dw,dh=state.document.width,state.document.height
    local canvas_scale=math.min(aw/dw,ah/dh,1.1)
    local cx=space_left+(W-space_left)/2
    local cy=28+ah/2
    local actual_scale=canvas_scale*view.zoom
    love.graphics.push()
    love.graphics.translate(cx+view.pan_x,cy+view.pan_y)
    love.graphics.rotate(view.rotation)
    love.graphics.scale(actual_scale)
    local shadow=3/actual_scale
    rectangle(-dw/2-shadow,-dh/2-shadow,dw+shadow*2,dh+shadow*2,C.deep,0.16)
    rectangle(-dw/2,-dh/2,dw,dh,C.white)
    love.graphics.pop()
    -- Top-right Windows editor controls, seen in product screenshot.
    local tops={"settings","selection","stabilizer","shape","ruler","material"}
    for i,name in ipairs(tops) do
        local x=right-34*(#tops-i+1)
        if over(x,9,31,31) then rectangle(x,9,31,31,C.dark,0.2,16) end
        rgba(C.deep,0.31)
        love.graphics.circle("fill",x+15,24,15)
        glyph(name,x+15,24,15)
        hit(x,9,31,31,function() set_panel(name) end,name)
    end
    -- Always-visible Windows tool selection strip, not fictional bottom text buttons.
    rectangle(0,0,59,H-78,C.bar,0.98)
    local top=8
    local each=math.min(45,(H-99)/#tools)
    for i,entry in ipairs(tools) do
        local y=top+(i-1)*each
        local selected=state.active_tool==entry[2]
        if selected then rectangle(0,y,58,each,C.blue,0.85) end
        if over(0,y,58,each) and not selected then
            rectangle(0,y,58,each,C.white,0.12)
        end
        glyph(entry[2],29,y+each*0.38,math.min(17,each*0.35))
        label(entry[1],0,y+each*0.70,58,"tiny","center",C.white)
        local key=entry[2]
        hit(0,y,58,each,function()
            state:set_tool(key)
            if key=="brush" or key=="eraser" then set_panel("brush")
            elseif key=="text" then set_panel("text")
            else panel=nil;state.active_panel=nil end
        end,key)
    end
    draw_size_controls()
    label(string.format("%d%%",math.floor(view.zoom*100+0.5)),
        W-72,H-72,67,"small","right",C.ink)
    draw_editor_toolbar()
    if panel then draw_editor_panel() end
end

local function draw_panel_box(x,y,w,h,title)
    rectangle(x-1,y-1,w+2,h+2,C.deep,0.80,3)
    rectangle(x,y,w,h,{0.31,0.31,0.31},0.89,3)
    rectangle(x,y,w,36,{0.38,0.38,0.38},0.96)
    label(title,x+9,y+8,w-53,"small","left",C.white)
    hit(x,y,w,h,function() end,"panel_surface")
    icon_button(x+w-37,y+2,35,32,"check",function()
        panel=nil;state.active_panel=nil
    end)
end
function draw_editor_panel()
    local name=panel
    local x,y,w,h
    if name=="brush" or name=="tools" or name=="color" then
        x=65;y=92;w=math.min(505,W-140);h=math.min(570,H-185)
    elseif name=="layer" then
        w=math.min(390,W-120);h=math.min(390,H-160)
        x=W-w-18;y=H-h-100
    else
        w=math.min(320,W-90);h=math.min(330,H-160)
        x=W-w-22;y=58
    end
    local titles={brush="Brush",tools="Tool Select",color="Color",layer="Layer",
        back="Back",settings="View Menu",selection="Selection Area",
        stabilizer="Stabilizer",shape="Shape",ruler="Ruler",material="Material",
        text="Text"}
    draw_panel_box(x,y,w,h,titles[name] or name)
    if name=="layer" then
        local bx=x+12
        rectangle(bx,y+49,w-59,45,{0.76,0.76,0.76},0.3)
        label("Selection Layer",bx+38,y+61,w-106,"small","left",C.white)
        for i=#state.layers,1,-1 do
            local ly=y+100+(#state.layers-i)*53
            if ly<y+h-93 then
                local layer=state.layers[i]
                rectangle(bx,ly,w-58,50,layer.id==state.active_layer_id and C.blue or C.light,
                    layer.id==state.active_layer_id and 0.53 or 0.20)
                rectangle(bx+4,ly+4,42,41,C.white)
                label(tostring(layer.id),bx+51,ly+5,34,"small","center",C.white)
                label("100%",bx+96,ly+3,60,"small","center",C.white)
                label("Normal",bx+96,ly+25,72,"small","center",C.white)
                local id=layer.id
                hit(bx+1,ly+1,w-97,49,function() state:select_layer(id) end,"select_layer")
                glyph("eye",x+w-31,ly+24,13)
                hit(x+w-48,ly+4,36,41,function()
                    layer_press={id=id,started=love.timer.getTime()}
                end,"visibility")
                if not layer.visible then rectangle(bx,ly,w-58,50,C.deep,0.40) end
            end
        end
        label(state.solo_layer_id and "Solo Mode" or "Hold eye icon: Solo Mode",
            x+13,y+h-76,w-26,"small","center",C.white)
        plain_button(x+13,y+h-46,w-28,36,"+   Add Layer",function() state:add_layer() end)
    elseif name=="brush" then
        label("Brush",x+15,y+54,w-30,"normal","center",C.white)
        local tabs={"Basic","Custom","Online"}
        for i,t in ipairs(tabs) do
            plain_button(x+17+(i-1)*(w-34)/3,y+81,(w-43)/3,32,t,function()
                if i~=1 then notice(t.." não possui dados locais nesta fase.") end
            end,i==1)
        end
        local brush_names={"Dip Pen (Hard)","Dip Pen (Soft)","Digital Pen","Felt Tip Pen",
            "Airbrush (Normal)","Pencil (#2)","Watercolor (Opaque)","Marker"}
        local rowh=math.min(42,(h-210)/#brush_names)
        for i,n in ipairs(brush_names) do
            local yy=y+121+(i-1)*rowh
            rectangle(x+15,yy,w*0.58,rowh-2,i==selected_brush and C.blue or C.white,
                i==selected_brush and 0.45 or 0.10)
            line(x+25,yy+rowh/2,x+85,yy+rowh/2,math.max(1.2,i*0.6),C.ink)
            label(n,x+93,yy+rowh*0.30,w*0.58-105,"tiny","left",C.white)
            local id=i
            hit(x+15,yy,w*0.58,rowh,function() selected_brush=id end,"brush_preset")
        end
        local rx=x+w*0.64
        label("Thickness",rx,y+130,w*0.31,"small","left",C.white)
        label(string.format("%.1fpx",state.brush_size),rx,y+160,w*0.31,"normal","center",C.white)
        plain_button(rx,y+201,43,32,"-",function()
            state:set_brush_size(math.max(0.1,state.brush_size-1))
        end)
        plain_button(rx+52,y+201,43,32,"+",function()
            state:set_brush_size(math.min(1000,state.brush_size+1))
        end)
        label("Opacity: "..opacity.."%",rx,y+256,w*0.31,"small","left",C.white)
    elseif name=="color" then
        label("Color",x+10,y+47,w-20,"normal","center",C.white)
        local sw=28
        for i,c in ipairs(palette) do
            local col={c[1]/255,c[2]/255,c[3]/255}
            local xx=x+17+(i-1)%6*(sw+7)
            local yy=y+86+math.floor((i-1)/6)*(sw+7)
            rectangle(xx,yy,sw,sw,col)
            if i==palette_index then stroke(xx-2,yy-2,sw+4,sw+4,C.white) end
            local id=i
            hit(xx,yy,sw,sw,function()
                palette_index=id
                state:set_color(c[1],c[2],c[3])
            end,"color_swatch")
        end
        local wheel_x=x+w-132
        local wheel_y=y+204
        local radius=106
        draw_hue_wheel(wheel_x,wheel_y,radius)
        hit(wheel_x-radius,wheel_y-radius,radius*2,radius*2,function()
            local mx,my=pointer()
            local dx,dy=mx-wheel_x,my-wheel_y
            local distance=math.sqrt(dx*dx+dy*dy)
            if distance>radius-25 then
                local a
                if math.atan2 then
                    a=math.atan2(dy,dx)
                elseif dx~=0 then
                    a=math.atan(dy/dx)
                    if dx<0 then a=a+math.pi end
                else
                    a=dy>=0 and math.pi/2 or -math.pi/2
                end
                picker_hue=((a+math.pi/2)/(2*math.pi))%1
                local rgb=hsv_rgb(picker_hue,1,1)
                state:set_color(math.floor(rgb[1]*255+0.5),
                    math.floor(rgb[2]*255+0.5),math.floor(rgb[3]*255+0.5))
                palette_index=0
            else
                local u=(dx+dy)/((radius-23)*2)+0.5
                local v=(dy-dx)/((radius-23)*2)+0.5
                u=math.max(0,math.min(1,u))
                v=math.max(0,math.min(1,v))
                local rgb=hsv_rgb(picker_hue,u,1-v)
                state:set_color(math.floor(rgb[1]*255+0.5),
                    math.floor(rgb[2]*255+0.5),math.floor(rgb[3]*255+0.5))
                palette_index=0
            end
        end,"hue_wheel")
        local rgb=state.color
        label(string.format("#%02X%02X%02X",rgb[1],rgb[2],rgb[3]),
            x+15,y+330,w-30,"normal","center",C.white)
        rectangle(x+16,y+360,w-32,34,
            {rgb[1]/255,rgb[2]/255,rgb[3]/255})
        local channel_names={"R","G","B"}
        local sliders={{1,0,0},{0,1,0},{0,0,1}}
        for i=1,3 do
            local yy=y+418+(i-1)*36
            label(channel_names[i],x+22,yy,w*0.17,"small","left",C.white)
            rectangle(x+64,yy+4,w-141,5,C.soft,0.60)
            local xx=x+64+(w-141)*rgb[i]/255
            rectangle(x+64,yy+4,(w-141)*rgb[i]/255,5,sliders[i])
            rgba(C.white);love.graphics.circle("fill",xx,yy+6,7)
            label(tostring(rgb[i]),x+w-67,yy,w*0.1,"small","right",C.white)
            local channel=i
            hit(x+64,yy-6,w-141,25,function()
                local mx=pointer()
                local next_rgb={state.color[1],state.color[2],state.color[3]}
                next_rgb[channel]=math.floor(math.max(0,
                    math.min(1,(mx-x-64)/(w-141)))*255+0.5)
                state:set_color(next_rgb[1],next_rgb[2],next_rgb[3])
                palette_index=0
            end,"rgb_slider")
        end
    elseif name=="tools" then
        for i,item in ipairs(tools) do
            local bw=(w-24)/3
            local row=math.floor((i-1)/3)
            local col=(i-1)%3
            local xx=x+11+col*bw
            local yy=y+47+row*math.min(80,(h-54)/5)
            if yy+56<=y+h-4 then
                rectangle(xx,yy,bw-4,56,item[2]==state.active_tool and C.blue or C.deep,
                    item[2]==state.active_tool and 0.8 or 0.50,3)
                glyph(item[2],xx+(bw-4)/2,yy+21,16)
                label(item[1],xx,yy+37,bw-4,"tiny","center",C.white)
                local key=item[2]
                hit(xx,yy,bw-4,56,function()
                    state:set_tool(key);panel=nil;state.active_panel=nil
                end,"tool_choice")
            end
        end
    elseif name=="back" then
        label("Return to My Gallery?",x+20,y+82,w-40,"normal","center",C.white)
        plain_button(x+20,y+151,w-40,41,"Back to My Gallery",function()
            state:open_gallery();panel=nil
        end,true)
    elseif name=="text" then
        label("Text tool selected.",x+15,y+99,w-30,"normal","center",C.white)
        label("Editing artwork is outside the UI-only scope.",x+12,y+145,w-24,"small","center",C.soft)
    else
        label((titles[name] or name).." settings",x+20,y+90,w-40,"normal","center",C.white)
        label("Insufficient verified Windows 14.1.4 references",x+20,y+139,w-40,"small","center",C.soft)
        label("No unverified controls have been added.",x+20,y+168,w-40,"small","center",C.soft)
    end
end

local function queue_capture()
    if capture_pending then return end
    capture_pending=true
    love.graphics.captureScreenshot(function(image)
        local ok,encoded=pcall(function() return image:encode("png") end)
        if not ok then capture_error=tostring(encoded)
        else
            local saved,err=love.filesystem.write("ci-smoke.png",encoded)
            if not saved then capture_error=tostring(err) end
        end
        capture_pending=false
        capture_done=true
    end)
end

function love.load()
    font.tiny=love.graphics.newFont(10)
    font.small=love.graphics.newFont(12)
    font.normal=love.graphics.newFont(16)
    font.header=love.graphics.newFont(19)
    font.logo=love.graphics.newFont(65)
    font.icon=love.graphics.newFont(14)
    font.big_icon=love.graphics.newFont(26)
    if smoke then
        if smoke_screen=="gallery" then state:open_gallery()
        elseif smoke_screen=="new_canvas" then state:open_gallery();state:open_new_canvas()
        elseif smoke_screen=="editor" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
        elseif smoke_screen=="layer" or smoke_screen=="color" or smoke_screen=="brush" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            set_panel(smoke_screen)
        elseif smoke_screen=="zoom" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            view:zoom_at(2,512,384,512,384)
            view:rotate_wheel(3)
            view:begin_pan(500,360);view:pan_to(540,380);view:end_pan()
        elseif smoke_screen=="solo" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            state:add_layer();state:toggle_layer_solo(1)
            set_panel("layer")
        end
        capture_requested=true
    end
end

function love.draw()
    local real_w,real_h=love.graphics.getDimensions()
    scale=math.max(0.70,math.min(1.4,real_h/768))
    W=real_w/scale;H=real_h/scale
    love.graphics.push()
    love.graphics.scale(scale)
    controls={}
    if state.screen=="title" then title_screen()
    elseif state.screen=="gallery" then gallery_screen()
    elseif current() then editor_screen()
    end
    if toast and love.timer.getTime()<toast_until then
        local tw=math.min(W*0.7,520)
        rectangle((W-tw)/2,H-116,tw,31,C.deep,0.91,4)
        label(toast,(W-tw)/2+8,H-108,tw-16,"small","center",C.white)
    end
    love.graphics.pop()
    if capture_requested then capture_requested=false;queue_capture() end
end

function love.mousepressed(rx,ry,button)
    if button~=1 then return end
    layer_press=nil
    local x,y=rx/scale,ry/scale
    for i=#controls,1,-1 do
        local b=controls[i]
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
            b.fn()
            return
        end
    end
    if state.screen=="editor" and not panel and love.keyboard.isDown("space") then
        view:begin_pan(x,y)
    elseif panel then panel=nil;state.active_panel=nil end
end
function love.mousemoved(rx,ry,dx,dy)
    if view.is_panning then
        if love.keyboard.isDown("space") then view:pan_to(rx/scale,ry/scale)
        else view:end_pan() end
    end
end
function love.mousereleased(rx,ry,button)
    if button~=1 then return end
    view:end_pan()
    if layer_press then
        if state.screen=="editor" and panel=="layer" then
            if love.timer.getTime()-layer_press.started>=0.55 then
                state:toggle_layer_solo(layer_press.id)
            else
                state:toggle_layer_visibility(layer_press.id)
            end
        end
        layer_press=nil
    end
end
function love.wheelmoved(dx,dy)
    if state.screen=="gallery" and state.modal=="new_canvas" then
        gallery_scroll=math.max(0,math.min(300,gallery_scroll-dy*28))
    elseif state.screen=="editor" and not panel then
        if love.keyboard.isDown("lshift","rshift") then
            view:rotate_wheel(dy)
        else
            local x,y=pointer()
            local cx=62+(W-62)/2
            local cy=28+(H-111)/2
            view:zoom_at(dy,x,y,cx,cy)
        end
    end
end
function love.textinput(t)
    if state.screen~="gallery" or state.modal~="new_canvas" or not focus then return end
    if not t:match("^%d+$") then return end
    if focus=="width" then
        current_width=(input_replace and t or current_width..t):sub(-5)
    elseif focus=="height" then
        current_height=(input_replace and t or current_height..t):sub(-5)
    end
    input_replace=false
end
function love.keypressed(key)
    if key=="f12" then capture_requested=true;return end
    if state.modal=="new_canvas" then
        if key=="escape" then state:cancel_new_canvas();focus=nil;return end
        if key=="backspace" then
            if focus=="width" then current_width=input_replace and "" or current_width:sub(1,-2)
            elseif focus=="height" then current_height=input_replace and "" or current_height:sub(1,-2) end
            input_replace=false
            return
        end
        if key=="tab" then
            focus=focus=="width" and "height" or "width"
            input_replace=true
            return
        end
        if key=="return" or key=="kpenter" then
            local ww,hh=tonumber(current_width),tonumber(current_height)
            if ww and hh and ww>=1 and hh>=1 and ww<=16384 and hh<=16384
            and ww==math.floor(ww) and hh==math.floor(hh) then
                state:create_canvas(ww,hh);view:reset();focus=nil;panel=nil
            else notice("Dimensões inválidas") end
            return
        end
    end
    if key=="escape" then
        view:end_pan()
        if panel then panel=nil;state.active_panel=nil
        elseif state.screen=="editor" then set_panel("back")
        elseif state.screen=="gallery" then state.screen="title"
        else love.event.quit() end
    elseif state.screen=="editor" then
        if key=="b" then state:set_tool("brush")
        elseif key=="e" then state:set_tool("eraser")
        elseif key=="l" then set_panel("layer")
        elseif key=="c" then set_panel("color")
        elseif key=="[" then state:set_brush_size(math.max(0.1,state.brush_size-1))
        elseif key=="]" then state:set_brush_size(math.min(1000,state.brush_size+1))
        end
    end
end
local function click_control(key)
    local b
    for i=#controls,1,-1 do
        if controls[i].key==key then b=controls[i];break end
    end
    assert(b,"UI e2e: controle indisponível: "..key)
    local x=(b.x+b.w/2)*scale
    local y=(b.y+b.h/2)*scale
    love.mousepressed(x,y,1)
    love.mousereleased(x,y,1)
end

function love.update()
    if smoke and capture_done then
        if capture_error then error("Screenshot: "..capture_error) end
        love.event.quit(0)
    end
    -- Teste real de callbacks de UI: o próximo passo ocorre depois do draw
    -- do frame anterior, para que os hitboxes correspondam à tela visível.
    if not e2e or #controls==0 then return end
    if e2e_stage==0 then
        assert(state.screen=="title")
        click_control("brush") -- My Gallery
        assert(state.screen=="gallery")
        e2e_stage=1
    elseif e2e_stage==1 then
        click_control("plus")
        assert(state.modal=="new_canvas")
        e2e_stage=2
    elseif e2e_stage==2 then
        click_control("input_width")
        for ch in ("900"):gmatch(".") do love.textinput(ch) end
        click_control("input_height")
        for ch in ("600"):gmatch(".") do love.textinput(ch) end
        click_control("OK")
        assert(state.screen=="editor" and state.document.width==900
            and state.document.height==600,"UI e2e: nova tela com dimensões erradas")
        e2e_stage=3
    elseif e2e_stage==3 then
        click_control("layer")
        assert(panel=="layer","UI e2e: painel de camadas não abriu")
        e2e_stage=4
    elseif e2e_stage==4 then
        click_control("visibility")
        assert(not state.layers[1].visible,"UI e2e: visibilidade não alterou")
        love.keypressed("escape")
        assert(panel==nil,"UI e2e: painel não fechou")
        love.wheelmoved(0,1)
        assert(view.zoom>1,"UI e2e: zoom por roda não respondeu")
        e2e_stage=5
    else
        print("PASS: UI LÖVE end-to-end (galeria, canvas, camadas, zoom)")
        love.event.quit(0)
    end
end
