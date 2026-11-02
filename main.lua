-- Ibis-Lua. Windows reference-based UI reconstruction, not the official application.
-- Layout evidence: Windows gallery/new canvas (Uptodown), Windows tool editor
-- (Microsoft Store, independent Windows screenshots), official tool manual.
-- Fidelity to version 14.1.4 is NOT yet certified. No paint/image engine.
local Model = require("src.model")
local Viewport = require("src.viewport")
local ViewState = require("src.view_state")
local CanvasPresets = require("src.canvas_presets")
local Gallery = require("src.gallery")
local utf8 = require("utf8")
local state = Model.new()
local view = Viewport.new()
local visual = ViewState.new()
local gallery = Gallery.new()
local gallery_selecting=false
local gallery_dialog=nil
local gallery_input=""
local gallery_input_replace=true
local active_artwork_id=nil
local controls = {}
local font = {}
local scale, W, H = 1, 1024, 768
local panel, gallery_menu = nil, nil
local gallery_scroll, preset_selected = 0, 0
local drag_dimension = nil
local current_width, current_height = "1000", "1000"
local focus, opacity, size_zoom = nil, 100, 100
local input_replace = true
local layer_press = nil
local layer_position, layer_size, drag_layer, drag_layer_resize, drag_opacity = nil, nil, nil, nil, nil
local layer_blend_open = false
local selected_brush, palette_index = 1, 1
local toast, toast_until = nil, 0
local smoke = os.getenv("IBIS_LUA_SMOKE") == "1"
local e2e = os.getenv("IBIS_LUA_E2E") == "1"
local e2e_stage = 0
local gallery_e2e = os.getenv("IBIS_LUA_GALLERY_E2E") == "1"
local gallery_e2e_stage = 0
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
local presets = CanvasPresets.list()
local active_dpi=nil

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
    elseif name=="view" then
        g.rectangle("line",-9*d,-7*d,18*d,14*d)
        g.line(-6*d,-3*d,6*d,-3*d)
        g.line(-6*d,1*d,5*d,1*d)
        g.line(-6*d,5*d,2*d,5*d)
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

-- Gallery layout inspired by a published Windows image and the official
-- artwork-folder tutorial. Exact version-14.1.4 geometry is not certified.
local function gallery_open_dialog(mode,id)
    gallery_dialog={mode=mode,id=id}
    gallery_input=mode=="rename" and gallery:get(id).name or "New Folder"
    gallery_input_replace=true
    gallery_menu=nil
end

local function gallery_header()
    rectangle(0,0,W,48,C.dark)
    local folder=gallery:folder(gallery.current_folder)
    label(folder.id==0 and ("My Gallery ("..gallery:total_artworks()..")")
            or folder.name,74,12,math.max(180,W-475),"normal","left",C.white)
    icon_button(8,3,48,42,"back",function()
        if not gallery:back() then
            state.screen="title"
            gallery_selecting=false
        end
        gallery_menu=nil
        gallery:clear_selection()
    end)
    -- The official 12.2+ New menu permits choosing Canvas or Folder.
    local actions={
        {"plus",function() gallery_menu=gallery_menu=="new" and nil or "new" end},
        {"settings",function() gallery_menu=gallery_menu=="cloud" and nil or "cloud" end},
        {"play",function() notice("Time-lapse: unavailable without artwork engine.") end},
        {"material",function() notice("Export requires image processing.") end},
        {"more",function() gallery_menu=gallery_menu=="more" and nil or "more" end}
    }
    local start=W-270
    for i,a in ipairs(actions) do
        icon_button(start+(i-1)*42,4,39,40,a[1],a[2])
    end
    label(gallery_selecting and "Done" or "Select",
        W-81,14,50,"small","center",C.white)
    hit(W-86,4,55,40,function()
        gallery_selecting=not gallery_selecting
        if not gallery_selecting then
            gallery:clear_selection();gallery_menu=nil
        end
    end,"gallery_select")
    label("Edit",W-38,14,37,"small","center",C.white)
    hit(W-42,4,40,40,function()
        if gallery.current_folder~=0 then
            gallery_open_dialog("rename",gallery.current_folder)
        else
            notice("Select an artwork or open a folder to edit its details.")
        end
    end,"gallery_edit")
end

local function gallery_item(tile,item)
    local x,y,w,h=tile.x,tile.y,tile.w,tile.h
    rectangle(x,y,w,h,C.white,1,2)
    stroke(x,y,w,h,{0.74,0.74,0.74},0.75)
    if item.type=="folder" then
        -- Geometric placeholder; official 14.1.4 folder artwork unverified.
        rectangle(x+26,y+23,w-52,107,{0.72,0.72,0.72},1,4)
        rectangle(x+26,y+15,w*0.39,20,{0.78,0.78,0.78},1,3)
        rectangle(x+30,y+30,w-60,94,{0.80,0.80,0.80},1,2)
        label("Folder",x+20,y+132,w-40,"tiny","center",{0.43,0.43,0.43})
    else
        -- The screenshot contains only the blank simulated canvas.
        local avail_w,avail_h=w-29,h-63
        local ratio=item.width/item.height
        local cw,ch=math.min(avail_w,avail_h*ratio),math.min(avail_h,avail_w/ratio)
        rectangle(x+(w-cw)/2,y+14+(avail_h-ch)/2,cw,ch,C.paper)
        stroke(x+(w-cw)/2,y+14+(avail_h-ch)/2,cw,ch,C.soft)
        label(item.width.." x "..item.height,x+10,y+132,w-20,
            "tiny","center",{0.55,0.55,0.55})
    end
    local name=item.name
    if #name>22 then name=name:sub(1,20).."…" end
    label(name,x+6,y+h-34,w-12,"small","center",C.ink)
    if gallery.selected[item.id] then
        rectangle(x,y,w,h,C.blue,0.22)
        rectangle(x+w-31,y+7,24,24,C.blue,0.93,12)
        glyph("check",x+w-19,y+19,12)
    end
    local id=item.id
    hit(x,y,w,h,function()
        if gallery_selecting then
            gallery:select(id)
        elseif item.type=="folder" then
            gallery:enter(id)
        else
            state:reopen_canvas(item.width,item.height)
            active_artwork_id=id
            view:reset()
        end
        gallery_menu=nil
    end,item.type.."_"..id)
end

local function gallery_screen()
    rectangle(0,0,W,H,C.paper)
    gallery_header()
    rectangle(0,49,W,34,{0.94,0.94,0.92})
    label("Cloud Synchronization",16,57,205,"small","left",{0.52,0.52,0.52})
    rectangle(220,57,35,18,{0.80,0.80,0.80},1,9)
    rgba(C.white);love.graphics.circle("fill",229,66,8)
    hit(214,51,48,30,function() gallery_menu="cloud" end,"cloud")
    local items=gallery:items()
    if #items==0 then
        label(gallery.current_folder==0 and "There is no artwork."
             or "This folder is empty.",0,H*0.54,W,"small","center",
             {0.63,0.63,0.63})
        label("Press '+' to create an artwork or folder.",0,H*0.54+23,W,
             "small","center",{0.63,0.63,0.63})
    else
        local tile_w=166
        local gap=19
        local left=29
        local count=math.max(1,math.floor((W-left*2+gap)/(tile_w+gap)))
        for i,item in ipairs(items) do
            local row=math.floor((i-1)/count)
            local col=(i-1)%count
            local tile={x=left+col*(tile_w+gap),y=109+row*204,w=tile_w,h=184}
            if tile.y+tile.h<H-58 then gallery_item(tile,item) end
        end
    end
    if gallery_selecting then
        rectangle(0,H-49,W,49,C.dark)
        label(tostring(#gallery:selection()).." selected",15,H-32,210,
            "small","left",C.white)
        plain_button(W-181,H-43,168,36,"Move",function()
            if #gallery:selection()>0 then gallery_menu="move"
            else notice("Select an artwork or folder first.") end
        end,true)
    end

    if gallery_menu=="new" and state.modal~="new_canvas" then
        local x=math.max(66,W-326)
        rectangle(x,49,256,130,C.dark,0.98,3)
        label("New",x+11,60,230,"small","left",C.white)
        plain_button(x+9,81,238,38,"Canvas",function()
            state:open_new_canvas();gallery_menu=nil
        end)
        hit(x+9,81,238,38,function()
            state:open_new_canvas();gallery_menu=nil
        end,"new_canvas")
        plain_button(x+9,125,238,38,"Folder (Pro)",function()
            gallery_open_dialog("create")
        end)
        hit(x+9,125,238,38,function()
            gallery_open_dialog("create")
        end,"new_folder")
    elseif gallery_menu=="move" and state.modal~="new_canvas" then
        local folders=gallery:folders()
        local n=math.min(#folders,10)
        local menu_w=292
        local x=W-menu_w-11
        local y=82
        rectangle(x,y,menu_w,45+n*34,C.dark,0.99,3)
        hit(x,y,menu_w,45+n*34,function() end,"move_surface")
        label("Move to folder",x+12,y+10,menu_w-25,"normal","left",C.white)
        for i=1,n do
            local folder=folders[i]
            local yy=y+42+(i-1)*34
            local fid=folder.id
            rectangle(x+9,yy,menu_w-18,32,
                over(x+9,yy,menu_w-18,32) and C.blue or C.bar,0.72,2)
            label(folder.name,x+19,yy+9,menu_w-40,"small","left",C.white)
            hit(x+9,yy,menu_w-18,32,function()
                local ok,result=pcall(function()
                    return gallery:move_selection(fid)
                end)
                if not ok then notice("Move not permitted: folder hierarchy.")
                else
                    gallery_menu=nil;gallery_selecting=false
                    notice(result.." item(s) moved.")
                end
            end,"move_to_"..fid)
        end
    elseif gallery_menu and state.modal~="new_canvas" then
        local x=W-245
        rectangle(x,49,238,138,C.dark,0.95,3)
        local text_map={
            cloud="Cloud synchronization requires an account.",
            more="My Gallery (demonstration only)"
        }
        label(text_map[gallery_menu] or "",x+10,66,218,
            "small","center",C.white)
        plain_button(x+22,124,190,33,"Close",function()
            gallery_menu=nil
        end)
    end

    if gallery_dialog then
        rectangle(0,0,W,H,C.deep,0.56)
        hit(0,0,W,H,function() end,"folder_scrim")
        local ww=math.min(W-52,408)
        local xx=(W-ww)/2
        local yy=H/2-119
        rectangle(xx,yy,ww,238,C.light,1,8)
        label(gallery_dialog.mode=="rename" and "Rename Folder" or "New Folder",
            xx+18,yy+20,ww-36,"header","center",C.ink)
        label("Folder name",xx+26,yy+74,ww-52,"small","left",C.ink)
        rectangle(xx+26,yy+97,ww-52,41,C.white,1,3)
        stroke(xx+26,yy+97,ww-52,41,C.blue)
        label(gallery_input,xx+36,yy+108,ww-72,"normal","left",C.ink)
        hit(xx+26,yy+97,ww-52,41,function()
            gallery_input_replace=true
        end,"folder_name")
        plain_button(xx+26,yy+171,(ww-63)/2,39,"Cancel",function()
            gallery_dialog=nil
        end)
        plain_button(xx+37+(ww-63)/2,yy+171,(ww-63)/2,39,"OK",function()
            local valid=gallery_input~="" and #gallery_input<=100
                and not gallery_input:match("^%s*$")
            if not valid then notice("Enter a valid folder name.");return end
            if gallery_dialog.mode=="rename" then
                gallery:rename(gallery_dialog.id,gallery_input)
            else
                gallery:add_folder(gallery_input)
            end
            gallery_dialog=nil
        end,true)
        hit(xx+37+(ww-63)/2,yy+171,(ww-63)/2,39,function()
            local valid=gallery_input~="" and #gallery_input<=100
                and not gallery_input:match("^%s*$")
            if valid then
                if gallery_dialog.mode=="rename" then
                    gallery:rename(gallery_dialog.id,gallery_input)
                else gallery:add_folder(gallery_input) end
                gallery_dialog=nil
            else notice("Enter a valid folder name.") end
        end,"folder_confirm")
    end
    if state.modal=="new_canvas" then draw_new_canvas() end
end

local function finish_new_canvas(wi,he)
    state:create_canvas(wi,he)
    active_artwork_id=gallery:add_artwork(
        wi,he,"Untitled "..tostring(gallery:total_artworks()+1))
    view:reset()
    panel=nil;gallery_menu=nil;focus=nil
    gallery_selecting=false
end

-- This side-aligned full-height panel follows the WINDOWS screenshot,
-- replacing the ungrounded central modal used in prior commits.
function draw_new_canvas()
    local pw=math.min(1050,math.max(440,W*0.69))
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
        local key=f.key
        local function update_dimension(value)
            local n=math.max(1,math.min(16384,math.floor(value+0.5)))
            if key=="width" then current_width=tostring(n)
            else current_height=tostring(n) end
            preset_selected=0
            active_dpi=nil
            focus=nil
            input_replace=true
        end
        rectangle(px+39,y,pw*0.25,24,C.white)
        stroke(px+39,y,pw*0.25,24,focus==key and C.blue or C.soft)
        label(f.value,px+43,y+3,pw*0.25-8,"small","center",C.ink)
        hit(px+39,y,pw*0.25,24,function() focus=key;input_replace=true end,"input_"..key)
        local sx=px+pw*0.35
        local track_w=pw*0.51
        line(sx,y+12,sx+track_w,y+12,4,{0.68,0.68,0.68})
        local value=tonumber(f.value) or 1
        local fill=math.max(0,math.min(1,(value-1)/8191))
        rectangle(sx,y+10,track_w*fill,4,C.blue)
        rgba(C.white)
        love.graphics.circle("fill",sx+track_w*fill,y+12,7)
        rgba(C.deep)
        love.graphics.circle("fill",sx-15,y+12,10)
        love.graphics.circle("fill",sx+track_w+15,y+12,10)
        line(sx-19,y+12,sx-11,y+12,1.7,C.white)
        line(sx+track_w+11,y+12,sx+track_w+19,y+12,1.7,C.white)
        line(sx+track_w+15,y+8,sx+track_w+15,y+16,1.7,C.white)
        hit(sx-26,y,21,24,function() update_dimension(value-1) end,"decrease_"..key)
        hit(sx,y,track_w,24,function()
            local mx=pointer()
            update_dimension(1+math.max(0,math.min(1,(mx-sx)/track_w))*8191)
            drag_dimension={key=key,sx=sx,width=track_w}
        end,"slider_"..key)
        hit(sx+track_w+5,y,23,24,function() update_dimension(value+1) end,"increase_"..key)
    end
    label("Speed ↔ Quality",px,yy+108,pw,"small","center",{0.30,0.30,0.30})
    yy=yy+128
    local row_h=math.min(39,math.max(25,(H-250)/#presets))
    for i,p in ipairs(presets) do
        local row_y=yy+(i-1)*row_h
        if row_y+row_h>=top and row_y<=H-42 then
            local selected=preset_selected==i
            rectangle(px+4,row_y,pw-8,row_h-1,
                selected and {0.77,0.83,0.87} or C.light)
            local ar=p.width/p.height
            local thumb_w=math.min(24,math.max(4,19*ar))
            local thumb_h=math.min(22,math.max(4,19/ar))
            stroke(px+8+(24-thumb_w)/2,
                row_y+(row_h-thumb_h)/2,thumb_w,thumb_h,{0.43,0.43,0.43})
            label(p.name,px+39,row_y+(row_h-16)/2,pw-(p.dpi and 245 or 165),
                "small","left",C.ink)
            local shown_w,shown_h=CanvasPresets.pixels(
                p,preset_selected==i and active_dpi or nil)
            label(tostring(shown_w).." x "..tostring(shown_h),
                px+pw-123,row_y+(row_h-16)/2,109,"small","right",C.ink)
            line(px+4,row_y+row_h-1,px+pw-4,row_y+row_h-1,
                1,{0.72,0.72,0.72})
            hit(px+4,row_y,pw-8,row_h,function()
                preset_selected=i
                active_dpi=p.dpi
                local wi,he=CanvasPresets.pixels(p,active_dpi)
                current_width=tostring(wi)
                current_height=tostring(he)
                focus=nil;input_replace=true
            end,"preset_"..i)
            if p.dpi then
                local dpi=preset_selected==i and active_dpi or p.dpi
                local dpi_x=px+pw-210
                rectangle(dpi_x,row_y+4,81,row_h-9,C.white,0.96,2)
                stroke(dpi_x,row_y+4,81,row_h-9,C.soft)
                label(tostring(dpi).." dpi",dpi_x+3,
                    row_y+(row_h-15)/2,75,"tiny","center",C.ink)
                hit(dpi_x,row_y+4,81,row_h-9,function()
                    if preset_selected~=i then
                        preset_selected=i
                        active_dpi=p.dpi
                    end
                    active_dpi=CanvasPresets.next_dpi(p,active_dpi)
                    local wi,he=CanvasPresets.pixels(p,active_dpi)
                    current_width=tostring(wi)
                    current_height=tostring(he)
                    focus=nil;input_replace=true
                end,"dpi_"..p.id)
            end
        end
    end
    love.graphics.setScissor()
    rectangle(px,H-42,pw,38,C.dark)
    label(current_width.." x "..current_height.." px",
        px+12,H-32,pw-154,"small","left",C.white)
    plain_button(px+pw-136,H-38,127,30,"OK",function()
        local ww,hh=tonumber(current_width),tonumber(current_height)
        if not ww or not hh or ww<1 or hh<1 or ww>16384 or hh>16384
        or ww~=math.floor(ww) or hh~=math.floor(hh) then
            notice("Informe dimensões inteiras de 1 a 16384 pixels.")
            return
        end
        finish_new_canvas(ww,hh)
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

-- Os guias existem apenas na visualização: nenhum pixel de obra é modificado.
-- Coordenadas em pixels do canvas; todo o conjunto herda pan/zoom/rotação.
local function draw_view_guides(dw,dh,canvas_scale)
    if visual.grid then
        local function grid_pass(interval,shade,alpha)
            -- Evitar milhares de linhas invisíveis em zooms muito baixos.
            if interval*canvas_scale<6 then return end
            rgba(shade,alpha)
            love.graphics.setLineWidth(math.max(0.2,0.85/canvas_scale))
            local begin_x=visual.offset_x%interval
            local begin_y=visual.offset_y%interval
            local x=begin_x
            while x<dw do
                love.graphics.line(x-dw/2,-dh/2,x-dw/2,dh/2)
                x=x+interval
            end
            local y=begin_y
            while y<dh do
                love.graphics.line(-dw/2,y-dh/2,dw/2,y-dh/2)
                y=y+interval
            end
        end
        grid_pass(visual.grid2,visual:grid_color("grid2"),0.22)
        grid_pass(visual.grid1,visual:grid_color("grid1"),0.48)
    end
    if visual.manga then
        rgba({0.94,0.25,0.29},0.55)
        love.graphics.setLineWidth(math.max(0.2,1.2/canvas_scale))
        love.graphics.rectangle("line",-dw*0.47,-dh*0.47,dw*0.94,dh*0.94)
        love.graphics.rectangle("line",-dw*0.40,-dh*0.40,dw*0.80,dh*0.80)
    end
end
local function draw_reference_window()
    local pw=210
    local x,y=W-pw-14,53
    local h=178
    rectangle(x,y,pw,h,C.deep,0.94,3)
    rectangle(x,y,pw,30,C.bar,0.98,3)
    label("Reference Window",x+7,y+8,pw-48,"small","left",C.white)
    icon_button(x+pw-31,y+2,27,26,"check",function()
        visual:toggle_reference()
    end)
    rectangle(x+13,y+40,pw-26,111,C.light,0.97)
    local dw,dh=state.document.width,state.document.height
    local factor=math.min((pw-54)/dw,93/dh)
    rectangle(x+pw/2-dw*factor/2,y+49+(93-dh*factor)/2,
        dw*factor,dh*factor,C.white)
    label("Canvas mode (simulado)",x+5,y+156,pw-10,"tiny","center",C.white)
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
    if state.background_mode=="white" then
        rectangle(-dw/2,-dh/2,dw,dh,C.white)
    else
        -- Checkerboard visual only: no image compositing or raster engine.
        local count=14
        local rows=math.max(2,math.floor(count*dh/dw+0.5))
        local tw,th=dw/count,dh/rows
        for i=0,count-1 do for j=0,rows-1 do
            local dark=state.background_mode=="transparent_dark"
            local level=(i+j)%2==0 and (dark and 0.25 or 0.78)
                or (dark and 0.38 or 0.94)
            rectangle(-dw/2+i*tw,-dh/2+j*th,tw+0.1,th+0.1,
                {level,level,level})
        end end
    end
    draw_view_guides(dw,dh,actual_scale)
    love.graphics.pop()
    -- Top-right Windows editor controls, seen in product screenshot.
    local tops={"view","selection","stabilizer","shape","ruler","material"}
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
    if visual.reference then draw_reference_window() end
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
    elseif name=="view" then
        w=math.min(350,W-90);h=342
        x=W-w-20;y=50
    elseif name=="grid_settings" then
        w=math.min(370,W-90);h=440
        x=W-w-20;y=50
    elseif name=="layer" then
        w=math.max(310,math.min(layer_size and layer_size.w or 408,W-110))
        h=math.max(360,math.min(layer_size and layer_size.h or 468,H-125))
        x=layer_position and layer_position.x or W-w-18
        y=layer_position and layer_position.y or H-h-91
        x=math.max(63,math.min(W-w-5,x))
        y=math.max(3,math.min(H-h-54,y))
    else
        w=math.min(320,W-90);h=math.min(330,H-160)
        x=W-w-22;y=58
    end
    local titles={brush="Brush",tools="Tool Select",color="Color",layer="Layer",
        back="Back",view="View Menu",grid_settings="Grid Settings",
        settings="Settings",selection="Selection Area",
        stabilizer="Stabilizer",shape="Shape",ruler="Ruler",material="Material",
        text="Text"}
    draw_panel_box(x,y,w,h,titles[name] or name)
    if name=="view" then
        local bx=x+12
        local function option(yy,title,enabled,action,key)
            rectangle(bx,yy,w-24,34,C.white,over(bx,yy,w-24,34) and 0.13 or 0.04,2)
            label(title,bx+10,yy+9,w-95,"small","left",C.white)
            local xx=bx+w-79
            rectangle(xx,yy+6,42,23,
                enabled and C.blue or {0.60,0.60,0.60},1,11)
            rgba(C.white)
            love.graphics.circle("fill",enabled and xx+31 or xx+11,yy+17,9)
            hit(bx,yy,w-24,34,action,key)
        end
        option(y+47,"Reference Window",visual.reference,
            function() visual:toggle_reference() end,"view_reference")
        option(y+85,"Grid",visual.grid,
            function() visual:toggle_grid() end,"view_grid")
        option(y+165,"Manga Manuscript",visual.manga,
            function() visual:toggle_manga() end,"view_manga")
        local function section_row(yy,text,callback,key)
            rectangle(bx+12,yy,w-49,32,C.deep,over(bx+12,yy,w-49,32) and 0.94 or 0.75,16)
            label(text,bx+18,yy+9,w-61,"small","center",C.white)
            hit(bx+12,yy,w-49,32,callback,key)
        end
        section_row(y+123,"Grid Settings",function() set_panel("grid_settings") end,
            "view_grid_settings")
        section_row(y+203,"Manga Manuscript Settings",function()
            notice("Geometria das opções de manuscrito ainda não verificada no Windows.")
        end,"view_manga_settings")
        label("Display when zooming",bx+9,y+245,w-44,"small","left",C.white)
        local bw=(w-48)/2
        local xx=bx+12
        rectangle(xx,y+267,bw,35,
            visual.interpolation=="smooth" and C.blue or C.deep,0.84,2)
        rectangle(xx+bw,y+267,bw,35,
            visual.interpolation=="pixelated" and C.blue or C.deep,0.84,2)
        label("Smooth",xx,y+277,bw,"small","center",C.white)
        label("Pixelated",xx+bw,y+277,bw,"small","center",C.white)
        hit(xx,y+267,bw,35,function()
            visual:set_interpolation("smooth")
        end,"view_smooth")
        hit(xx+bw,y+267,bw,35,function()
            visual:set_interpolation("pixelated")
        end,"view_pixelated")
    elseif name=="grid_settings" then
        local bx=x+13
        local function interval_row(yy,title,value,key,step)
            label(title,bx,yy,w-26,"small","left",C.white)
            local by=yy+19
            rectangle(bx,by,w-26,37,C.white,0.09,2)
            label(tostring(value).." px",bx+57,by+11,w-150,"small","center",C.white)
            local dec=function()
                visual:set_interval(key,math.max(1,visual[key]-step))
            end
            local inc=function()
                visual:set_interval(key,math.min(8192,visual[key]+step))
            end
            plain_button(bx+3,by+3,35,31,"-",dec)
            plain_button(x+w-59,by+3,35,31,"+",inc)
            hit(x+w-59,by+3,35,31,inc,"increase_"..key)
        end
        interval_row(y+76,"Grid 1 Interval",visual.grid1,"grid1",8)
        interval_row(y+145,"Grid 2 Interval",visual.grid2,"grid2",8)
        local function color_row(yy,title,key)
            label(title,bx,yy+8,w-115,"small","left",C.white)
            local xx=x+w-75
            rectangle(xx,yy+3,53,27,visual:grid_color(key),1,2)
            stroke(xx,yy+3,53,27,C.white,0.5)
            hit(xx-2,yy,58,34,function()
                visual:cycle_grid_color(key)
            end,"grid_color_"..key)
        end
        color_row(y+214,"Grid 1 Color","grid1")
        color_row(y+248,"Grid 2 Color","grid2")
        label("Position X",bx,y+288,(w-24)/2,"small","left",C.white)
        label("Position Y",bx+(w-24)/2,y+288,(w-24)/2,"small","left",C.white)
        local bw=(w-42)/4
        plain_button(bx,y+310,bw,28,"-",function()
            visual:set_origin(visual.offset_x-8,visual.offset_y)
        end)
        plain_button(bx+bw,y+310,bw,28,
            tostring(visual.offset_x),function()
                visual:set_origin(0,visual.offset_y)
            end)
        plain_button(bx+2*bw+9,y+310,bw,28,"-",function()
            visual:set_origin(visual.offset_x,visual.offset_y-8)
        end)
        plain_button(bx+3*bw+9,y+310,bw,28,
            tostring(visual.offset_y),function()
                visual:set_origin(visual.offset_x,0)
            end)
        local toggle_x=x+w-90
        label("Show Grid",bx,y+49,w-110,"small","left",C.white)
        rectangle(toggle_x,y+46,60,23,
            visual.grid and C.blue or {0.5,0.5,0.5},1,11)
        rgba(C.white)
        love.graphics.circle("fill",
            visual.grid and toggle_x+46 or toggle_x+12,y+57,9)
        hit(toggle_x,y+43,62,29,function() visual:toggle_grid() end,
            "settings_grid_toggle")
        plain_button(bx,y+367,w-26,33,
            "Reset Grid",function() visual:reset_grid() end)
    elseif name=="layer" then
        hit(x+3,y+2,w-48,32,function()
            local mx,my=pointer()
            drag_layer={dx=mx-x,dy=my-y}
        end,"layer_drag")
        local bx=x+10
        rectangle(bx,y+43,w-53,37,C.light,0.20,2)
        label("Selection Layer",bx+40,y+54,w-101,"small","left",C.white)
        rectangle(bx+7,y+48,25,25,C.white)
        local max_rows=math.max(1,math.floor((h-269)/52))
        for slot=1,math.min(#state.layers,max_rows) do
            local index=#state.layers-slot+1
            local layer=state.layers[index]
            local yy=y+85+(slot-1)*52
            local active=layer.id==state.active_layer_id
            rectangle(bx,yy,w-53,50,
                active and C.blue or C.light,active and 0.72 or 0.15,2)
            -- Transparent thumbnails: artwork pixels are not implemented.
            for i=0,3 do for j=0,3 do
                local v=(i+j)%2==0 and 0.87 or 0.65
                rectangle(bx+4+i*10,yy+5+j*10,10,10,{v,v,v})
            end end
            stroke(bx+4,yy+5,40,40,C.soft,0.7)
            label(tostring(index),bx+48,yy+4,30,"small","center",C.white)
            label(layer.name,bx+79,yy+4,w-185,"tiny","left",C.white)
            label(tostring(layer.opacity).."%   "..layer.blending,
                bx+79,yy+24,w-172,"small","left",C.white)
            local id=layer.id
            hit(bx,yy,w-98,50,function() state:select_layer(id) end,
                "select_layer")
            glyph("eye",x+w-29,yy+25,12)
            hit(x+w-48,yy+3,41,44,function()
                layer_press={id=id,started=love.timer.getTime()}
            end,"visibility")
            if not layer.visible then
                rectangle(bx,yy,w-53,50,C.deep,0.34)
            end
        end
        icon_button(x+w-39,y+44,31,31,"plus",function()
            state:add_layer()
        end)
        hit(x+w-39,y+44,31,31,function() state:add_layer() end,
            "layer_add")
        local active=state:active_layer()
        local foot=y+h-174
        line(x+8,foot-8,x+w-8,foot-8,1,C.soft,0.3)
        label("Opacity",x+13,foot,w-40,"small","left",C.white)
        label(active.opacity.."%",x+w-53,foot,45,"small","right",C.white)
        local slider_x=x+94
        local slider_w=w-157
        rectangle(slider_x,foot+12,slider_w,4,C.soft,0.58)
        rectangle(slider_x,foot+12,slider_w*active.opacity/100,4,C.blue)
        rgba(C.white)
        love.graphics.circle("fill",slider_x+slider_w*active.opacity/100,foot+14,7)
        hit(slider_x,foot+2,slider_w,27,function()
            local mx=pointer()
            state:set_layer_opacity(active.id,
                math.floor(math.max(0,math.min(1,(mx-slider_x)/slider_w))*100+0.5))
            drag_opacity={id=active.id,x=slider_x,w=slider_w}
        end,"layer_opacity")
        local bw=(w-29)/2
        local function toggle(xx,name,enabled,fn,key)
            rectangle(xx,foot+37,bw,30,enabled and C.blue or C.deep,0.92,2)
            label(name,xx+1,foot+45,bw-2,"small","center",C.white)
            hit(xx,foot+37,bw,30,fn,key)
        end
        toggle(x+10,"Clipping",active.clipping,function()
            state:toggle_layer_clipping(active.id)
        end,"layer_clipping")
        toggle(x+19+bw,"Alpha Lock",active.alpha_lock,function()
            state:toggle_layer_alpha_lock(active.id)
        end,"layer_alpha_lock")
        rectangle(x+10,foot+72,w-20,30,C.deep,0.86,2)
        label("Blending Mode   "..active.blending.."   ▾",
            x+19,foot+80,w-38,"small","left",C.white)
        hit(x+10,foot+72,w-20,30,function()
            layer_blend_open=not layer_blend_open
        end,"layer_blend")
        label("Background",x+10,foot+109,w-20,"small","left",C.white)
        local backgrounds={
            {"White","white"},{"Light","transparent_light"},
            {"Dark","transparent_dark"}
        }
        for i,option in ipairs(backgrounds) do
            local ww=(w-24)/3
            local xx=x+9+(i-1)*ww
            local enabled=state.background_mode==option[2]
            rectangle(xx,foot+128,ww-3,31,
                enabled and C.blue or C.deep,enabled and 0.96 or 0.79,2)
            label(option[1],xx+1,foot+136,ww-5,"small","center",C.white)
            local mode=option[2]
            hit(xx,foot+128,ww-3,31,function()
                state:set_background(mode)
            end,"background_"..mode)
        end
        -- Floating Layer Window grip: size-adjustment is documented for PCs.
        line(x+w-17,y+h-5,x+w-5,y+h-17,1.2,C.white)
        line(x+w-11,y+h-5,x+w-5,y+h-11,1.2,C.white)
        hit(x+w-24,y+h-24,24,24,function()
            local mx,my=pointer()
            drag_layer_resize={start_x=mx,start_y=my,w=w,h=h}
        end,"layer_resize")
        if layer_blend_open then
            local opts={"Normal","Multiply","Screen","Overlay","Darken","Lighten",
                "Color Burn","Color Dodge","Soft Light"}
            local popup_x=x+w-210
            local popup_y=y+35
            rectangle(popup_x,popup_y,201,#opts*27+6,C.deep,0.99,2)
            hit(popup_x,popup_y,201,#opts*27+6,function() end,"blend_surface")
            for i,mode in ipairs(opts) do
                local yy=popup_y+3+(i-1)*27
                if active.blending==mode then
                    rectangle(popup_x+2,yy,197,26,C.blue,0.80,2)
                end
                label(mode,popup_x+11,yy+7,174,"small","left",C.white)
                hit(popup_x+3,yy,195,26,function()
                    state:set_layer_blending(state.active_layer_id,mode)
                    layer_blend_open=false
                end,"blend_"..mode)
            end
        end
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
    if e2e and os.getenv("IBIS_LUA_E2E_RES") then
        local w,h=os.getenv("IBIS_LUA_E2E_RES"):match("^(%d+)x(%d+)$")
        assert(w and h,"IBIS_LUA_E2E_RES deve ser largura x altura")
        local ok=love.window.setMode(tonumber(w),tonumber(h),{resizable=true})
        assert(ok,"Não foi possível configurar resolução de teste")
    end
    if smoke then
        if smoke_screen=="gallery" then state:open_gallery()
        elseif smoke_screen=="gallery_new" then
            state:open_gallery();gallery_menu="new"
        elseif smoke_screen=="gallery_folders" then
            state:open_gallery()
            gallery:add_folder("Projects")
            gallery:add_folder("Archive")
            gallery:add_artwork(1024,768,"Untitled 1")
        elseif smoke_screen=="gallery_inside" then
            state:open_gallery()
            local fid=gallery:add_folder("Projects")
            gallery:enter(fid)
            gallery:add_artwork(900,600,"Study")
        elseif smoke_screen=="gallery_selection" then
            state:open_gallery()
            gallery:add_folder("Projects")
            local id=gallery:add_artwork(900,600,"Study")
            gallery_selecting=true
            gallery:select(id)
        elseif smoke_screen=="new_canvas" then state:open_gallery();state:open_new_canvas()
        elseif smoke_screen=="new_canvas_dpi" then
            state:open_gallery();state:open_new_canvas()
            preset_selected=10;active_dpi=300
            local wi,he=CanvasPresets.pixels(presets[10],active_dpi)
            current_width=tostring(wi);current_height=tostring(he)
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
        elseif smoke_screen=="layer_floating" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            state:add_layer()
            layer_size={w=340,h=390}
            layer_position={x=128,y=86}
            set_panel("layer")
        elseif smoke_screen=="layer_properties" or smoke_screen=="layer_blend"
            or smoke_screen=="transparent" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            state:add_layer()
            state:set_layer_opacity(2,63)
            state:toggle_layer_clipping(2)
            state:toggle_layer_alpha_lock(2)
            state:set_layer_blending(2,"Multiply")
            state:set_background("transparent_dark")
            if smoke_screen~="transparent" then
                set_panel("layer")
                layer_blend_open=smoke_screen=="layer_blend"
            end
        elseif smoke_screen=="view" or smoke_screen=="grid_settings"
            or smoke_screen=="grid" or smoke_screen=="reference" then
            state:open_gallery();state:open_new_canvas();state:create_canvas(1800,2400)
            visual.grid=true
            if smoke_screen=="reference" then visual.reference=true
            elseif smoke_screen=="view" then panel="view"
            elseif smoke_screen=="grid_settings" then panel="grid_settings" end
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
    elseif panel then panel=nil;state.active_panel=nil;layer_blend_open=false end
end
function love.mousemoved(rx,ry,dx,dy)
    if drag_layer and panel=="layer" then
        layer_position={x=rx/scale-drag_layer.dx,y=ry/scale-drag_layer.dy}
    end
    if drag_layer_resize and panel=="layer" then
        local g=drag_layer_resize
        layer_size={
            w=math.max(310,math.min(W-110,g.w+rx/scale-g.start_x)),
            h=math.max(360,math.min(H-125,g.h+ry/scale-g.start_y))
        }
    end
    if drag_opacity and panel=="layer" then
        local p=drag_opacity
        state:set_layer_opacity(p.id,math.floor(
            math.max(0,math.min(1,(rx/scale-p.x)/p.w))*100+0.5))
    end
    if drag_dimension and state.modal=="new_canvas" then
        local value=math.floor(1+math.max(0,math.min(1,
            (rx/scale-drag_dimension.sx)/drag_dimension.width))*8191+0.5)
        if drag_dimension.key=="width" then current_width=tostring(value)
        else current_height=tostring(value) end
    end
    if view.is_panning then
        if love.keyboard.isDown("space") then view:pan_to(rx/scale,ry/scale)
        else view:end_pan() end
    end
end
function love.mousereleased(rx,ry,button)
    if button~=1 then return end
    drag_dimension=nil
    drag_layer=nil
    drag_layer_resize=nil
    drag_opacity=nil
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
        local row_h=math.min(39,math.max(25,(H-250)/#presets))
        local last=80+128+#presets*row_h
        gallery_scroll=math.max(0,math.min(
            math.max(0,last-(H-42)+6),gallery_scroll-dy*28))
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
    if gallery_dialog and state.screen=="gallery" then
        if t~="" and #gallery_input+#t<=100 then
            gallery_input=gallery_input_replace and t or gallery_input..t
            gallery_input_replace=false
        end
        return
    end
    if state.screen~="gallery" or state.modal~="new_canvas" or not focus then return end
    if not t:match("^%d+$") then return end
    if focus=="width" then
        current_width=(input_replace and t or current_width..t):sub(-5)
    elseif focus=="height" then
        current_height=(input_replace and t or current_height..t):sub(-5)
    end
    preset_selected=0
    active_dpi=nil
    input_replace=false
end
function love.keypressed(key)
    if key=="f12" then capture_requested=true;return end
    if gallery_dialog and state.screen=="gallery" then
        if key=="escape" then gallery_dialog=nil
        elseif key=="backspace" then
            if gallery_input_replace then gallery_input=""
            else
                local index=utf8.offset(gallery_input,-1)
                gallery_input=index and gallery_input:sub(1,index-1) or ""
            end
            gallery_input_replace=false
        elseif key=="return" or key=="kpenter" then
            if gallery_input=="" or #gallery_input>100 or gallery_input:match("^%s*$") then
                notice("Enter a valid folder name.")
            else
                if gallery_dialog.mode=="rename" then
                    gallery:rename(gallery_dialog.id,gallery_input)
                else gallery:add_folder(gallery_input) end
                gallery_dialog=nil
            end
        end
        return
    end
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
                finish_new_canvas(ww,hh)
            else notice("Dimensões inválidas") end
            return
        end
    end
    if key=="escape" then
        view:end_pan()
        if layer_blend_open then layer_blend_open=false
        elseif panel then panel=nil;state.active_panel=nil
        elseif state.screen=="editor" then set_panel("back")
        elseif state.screen=="gallery" then
            if gallery_menu then gallery_menu=nil
            elseif gallery_selecting then
                gallery_selecting=false;gallery:clear_selection()
            elseif not gallery:back() then state.screen="title" end
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
    -- Mouse callbacks that use love.mouse.getPosition must see this cursor.
    love.mouse.setPosition(x,y)
    love.mousepressed(x,y,1)
    love.mousereleased(x,y,1)
end

local function gallery_e2e_update()
    if gallery_e2e_stage==0 then
        click_control("brush")
        assert(state.screen=="gallery")
        gallery_e2e_stage=1
    elseif gallery_e2e_stage==1 then
        click_control("plus")
        assert(gallery_menu=="new")
        gallery_e2e_stage=2
    elseif gallery_e2e_stage==2 then
        click_control("new_folder")
        assert(gallery_dialog and gallery_dialog.mode=="create")
        gallery_e2e_stage=3
    elseif gallery_e2e_stage==3 then
        for character in ("Projects"):gmatch(".") do love.textinput(character) end
        click_control("folder_confirm")
        assert(not gallery_dialog and #gallery:items()==1)
        assert(gallery:get(1).name=="Projects")
        gallery_e2e_stage=4
    elseif gallery_e2e_stage==4 then
        click_control("folder_1")
        assert(gallery.current_folder==1)
        gallery_e2e_stage=5
    elseif gallery_e2e_stage==5 then
        click_control("plus")
        gallery_e2e_stage=6
    elseif gallery_e2e_stage==6 then
        click_control("new_canvas")
        assert(state.modal=="new_canvas")
        gallery_e2e_stage=7
    elseif gallery_e2e_stage==7 then
        click_control("OK")
        assert(state.screen=="editor" and gallery:total_artworks()==1)
        assert(gallery:get(2).parent==1)
        gallery_e2e_stage=8
    elseif gallery_e2e_stage==8 then
        click_control("back")
        assert(panel=="back")
        gallery_e2e_stage=9
    elseif gallery_e2e_stage==9 then
        click_control("Back to My Gallery")
        assert(state.screen=="gallery" and gallery.current_folder==1)
        gallery_e2e_stage=10
    elseif gallery_e2e_stage==10 then
        click_control("gallery_select")
        assert(gallery_selecting)
        gallery_e2e_stage=11
    elseif gallery_e2e_stage==11 then
        click_control("artwork_2")
        assert(#gallery:selection()==1)
        gallery_e2e_stage=12
    elseif gallery_e2e_stage==12 then
        click_control("Move")
        assert(gallery_menu=="move")
        gallery_e2e_stage=13
    elseif gallery_e2e_stage==13 then
        click_control("move_to_0")
        assert(gallery:get(2).parent==0 and not gallery_selecting)
        gallery_e2e_stage=14
    elseif gallery_e2e_stage==14 then
        click_control("back")
        assert(gallery.current_folder==0)
        gallery_e2e_stage=15
    elseif gallery_e2e_stage==15 then
        click_control("artwork_2")
        assert(state.screen=="editor" and state.document.width==1000)
        gallery_e2e_stage=16
    elseif gallery_e2e_stage==16 then
        click_control("back")
        gallery_e2e_stage=17
    elseif gallery_e2e_stage==17 then
        click_control("Back to My Gallery")
        assert(state.screen=="gallery")
        gallery_e2e_stage=18
    elseif gallery_e2e_stage==18 then
        click_control("folder_1")
        assert(gallery.current_folder==1)
        gallery_e2e_stage=19
    elseif gallery_e2e_stage==19 then
        click_control("gallery_edit")
        assert(gallery_dialog and gallery_dialog.mode=="rename")
        gallery_e2e_stage=20
    elseif gallery_e2e_stage==20 then
        for character in ("Ideas"):gmatch(".") do love.textinput(character) end
        click_control("folder_confirm")
        assert(gallery:get(1).name=="Ideas" and gallery_dialog==nil)
        gallery_e2e_stage=21
    else
        print("PASS: My Gallery click E2E (folder, canvas, move, reopen, rename)")
        love.event.quit(0)
    end
end

function love.update()
    if smoke and capture_done then
        if capture_error then error("Screenshot: "..capture_error) end
        love.event.quit(0)
    end
    -- Each stage runs after a draw; hitboxes represent the visible UI.
    if gallery_e2e and #controls>0 then
        gallery_e2e_update()
        return
    end
    if not e2e or #controls==0 then return end
    if e2e_stage==0 then
        assert(state.screen=="title")
        click_control("brush") -- My Gallery
        assert(state.screen=="gallery")
        e2e_stage=1
    elseif e2e_stage==1 then
        click_control("plus")
        assert(gallery_menu=="new")
        e2e_stage=1.5
    elseif e2e_stage==1.5 then
        click_control("new_canvas")
        assert(state.modal=="new_canvas")
        e2e_stage=2
    elseif e2e_stage==2 then
        click_control("increase_width")
        assert(current_width=="1001","UI e2e: incremento inicial da largura falhou")
        click_control("preset_10")
        assert(current_width=="1754" and current_height=="1240",
            "UI e2e: preset A4 não aplicado")
        click_control("dpi_a4")
        assert(current_width=="3508" and current_height=="2480",
            "UI e2e: DPI A4 não mudou dimensões")
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
    elseif e2e_stage==5 then
        click_control("view")
        assert(panel=="view","UI e2e: View Menu não abriu")
        e2e_stage=6
    elseif e2e_stage==6 then
        click_control("view_grid")
        assert(visual.grid,"UI e2e: grade não ativou")
        click_control("view_reference")
        assert(visual.reference,"UI e2e: janela de referência não ativou")
        click_control("view_pixelated")
        assert(visual.interpolation=="pixelated",
            "UI e2e: interpolação não alternou")
        click_control("view_grid_settings")
        assert(panel=="grid_settings","UI e2e: Grid Settings não abriu")
        e2e_stage=7
    elseif e2e_stage==7 then
        click_control("increase_grid1")
        assert(visual.grid1==72,"UI e2e: intervalo da grade não foi alterado")
        click_control("Reset Grid")
        assert(visual.grid1==64 and visual.grid2==256,
            "UI e2e: Reset Grid não restaurou os intervalos")
        e2e_stage=8
    elseif e2e_stage==8 then
        love.keypressed("escape")
        click_control("layer")
        assert(panel=="layer","UI e2e: retorno ao painel Layer falhou")
        e2e_stage=9
    elseif e2e_stage==9 then
        click_control("layer_add")
        assert(#state.layers==2,"UI e2e: Add Layer falhou")
        e2e_stage=10
    elseif e2e_stage==10 then
        click_control("layer_clipping")
        click_control("layer_alpha_lock")
        assert(state:active_layer().clipping and state:active_layer().alpha_lock,
            "UI e2e: clipping ou alpha lock falhou")
        click_control("layer_opacity")
        assert(state:active_layer().opacity<100,
            "UI e2e: controle de opacidade falhou")
        click_control("layer_blend")
        assert(layer_blend_open,"UI e2e: lista de blending não abriu")
        e2e_stage=11
    elseif e2e_stage==11 then
        click_control("blend_Multiply")
        assert(state:active_layer().blending=="Multiply",
            "UI e2e: modo Multiply não selecionado")
        assert(not layer_blend_open)
        e2e_stage=12
    elseif e2e_stage==12 then
        click_control("background_transparent_dark")
        assert(state.background_mode=="transparent_dark",
            "UI e2e: transparência de fundo não alterada")
        e2e_stage=13
    elseif e2e_stage==13 then
        -- Drive actual mouse movement through the floating-window grip.
        local resize
        for i=#controls,1,-1 do
            if controls[i].key=="layer_resize" then
                resize=controls[i];break
            end
        end
        assert(resize,"UI e2e: resize grip missing")
        local mx=(resize.x+resize.w/2)*scale
        local my=(resize.y+resize.h/2)*scale
        love.mouse.setPosition(mx,my)
        love.mousepressed(mx,my,1)
        love.mousemoved(mx-40*scale,my-30*scale,-40*scale,-30*scale)
        love.mousereleased(mx-40*scale,my-30*scale,1)
        assert(layer_size and layer_size.w<408 and layer_size.h<468,
            "UI e2e: resize da janela Layer falhou")
        e2e_stage=14
    else
        print("PASS: UI LÖVE end-to-end (galeria, canvas, View e camadas flutuantes)")
        love.event.quit(0)
    end
end
