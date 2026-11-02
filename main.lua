-- Ibis-Lua: primeira tela visual em Lua/LÖVE.
-- A tela inicial baseia-se em documentação Windows, inclusive capturas HISTÓRICAS.
-- Não foi validada contra a compilação Windows 14.1.4: ver docs/VALIDACAO.md.
local Model = require("src.model")
local state = Model.new()
local buttons = {}
local fonts = {}
local smoke = os.getenv("IBIS_LUA_SMOKE") == "1"
local capture_requested = smoke
local capture_pending, capture_done, capture_error = false, false, nil
local W, H, scale, offx, offy = 1024, 768, 1, 0, 0
local width_text, height_text = "1800", "2400"
local focused_input = nil

local C = {
    blue = {0.133, 0.278, 0.435},
    ranking = {0.088, 0.163, 0.257},
    white = {0.98, 0.98, 0.99},
    cream = {0.952, 0.950, 0.936},
    dark = {0.14, 0.14, 0.14},
    pale = {0.72, 0.79, 0.87},
    accent = {0.27, 0.61, 0.89},
    modal = {0.96, 0.96, 0.95}
}

local function color(rgb, alpha)
    love.graphics.setColor(rgb[1], rgb[2], rgb[3], alpha or 1)
end
local function text(str, x, y, width, font, align, rgb)
    love.graphics.setFont(font or fonts.medium)
    color(rgb or C.white)
    love.graphics.printf(str, x, y, width, align or "center")
end
local function hit(x,y,w,h,callback,tag)
    buttons[#buttons+1] = { x=x,y=y,w=w,h=h,fn=callback,tag=tag }
end
local function inside(b,x,y)
    return x >= b.x and x <= b.x+b.w and y >= b.y and y <= b.y+b.h
end
local function cursor()
    local x,y = love.mouse.getPosition()
    return (x-offx)/scale, (y-offy)/scale
end
local function hovered(x,y,w,h)
    local mx,my = cursor()
    return inside({x=x,y=y,w=w,h=h},mx,my)
end

-- Ícones vetoriais traçados a partir do aspecto público dos controles,
-- não extraídos de arquivos ou bibliotecas proprietárias.
local function pen(cx,cy,s)
    love.graphics.push()
    love.graphics.translate(cx,cy)
    love.graphics.rotate(math.pi/4)
    color(C.white, 0.93)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line",-s*0.13,-s*0.49,s*0.26,s*0.79,3,3)
    love.graphics.line(-s*0.13,s*0.29,0,s*0.50,s*0.13,s*0.29)
    love.graphics.line(-s*0.13,-s*0.33,s*0.13,-s*0.33)
    love.graphics.pop()
end
local function globe(cx,cy,r)
    color(C.white,0.91)
    love.graphics.setLineWidth(1.9)
    love.graphics.circle("line",cx,cy,r)
    love.graphics.ellipse("line",cx,cy,r*0.45,r)
    love.graphics.line(cx-r,cy,cx+r,cy)
    love.graphics.arc("line","open",cx,cy,r*0.72,math.pi*0.22,math.pi*0.78)
    love.graphics.arc("line","open",cx,cy,r*0.72,math.pi*1.22,math.pi*1.78)
end
local function plus(cx,cy,r)
    love.graphics.setLineWidth(3)
    color(C.white)
    love.graphics.line(cx-r,cy,cx+r,cy)
    love.graphics.line(cx,cy-r,cx,cy+r)
end
local function back(cx,cy,r)
    love.graphics.setLineWidth(2.8)
    color(C.white)
    love.graphics.line(cx+r*0.3,cy-r,cx-r*0.7,cy,cx+r*0.3,cy+r)
end
local function draw_wheel(cx,cy,r)
    local colors = {
        {0.94,0.24,0.26},{0.96,0.47,0.17},{0.97,0.74,0.12},
        {0.67,0.80,0.18},{0.29,0.72,0.35},{0.19,0.74,0.64},
        {0.15,0.63,0.82},{0.19,0.38,0.76},{0.35,0.26,0.67},
        {0.67,0.31,0.66},{0.87,0.29,0.50},{0.95,0.26,0.34}
    }
    love.graphics.setLineWidth(1)
    local count = #colors
    for i=1,count do
        local a = (i-1)*2*math.pi/count-math.pi/2
        local b = i*2*math.pi/count-math.pi/2
        local p = {cx,cy}
        for j=0,5 do
            local t=a+(b-a)*j/5
            p[#p+1]=cx+math.cos(t)*r
            p[#p+1]=cy+math.sin(t)*r
        end
        color(colors[i])
        love.graphics.polygon("fill",p)
    end
    color(C.white)
    love.graphics.circle("fill",cx,cy,r*0.52)
    color(C.blue)
    love.graphics.circle("fill",cx,cy,r*0.41)
    color(C.white)
    love.graphics.setLineWidth(2.5)
    love.graphics.circle("line",cx,cy,r+1)
end
local function icon_circle(cx,cy,label,kind,callback)
    local r=53
    local active=hovered(cx-r-14,cy-r-10,2*r+28,2*r+47)
    color(C.white, active and 0.19 or 0.05)
    love.graphics.circle("fill",cx,cy,r)
    color(C.white, active and 1 or 0.65)
    love.graphics.setLineWidth(active and 2.4 or 1.45)
    love.graphics.circle("line",cx,cy,r)
    if kind=="pen" then pen(cx,cy,45) else globe(cx,cy,24) end
    text(label,cx-112,cy+r+17,224,fonts.medium,"center",C.white)
    hit(cx-r-14,cy-r-10,2*r+28,2*r+47,callback,kind)
end
local function horizontal_bar(y,h,rgb)
    color(rgb)
    love.graphics.rectangle("fill",0,y,W,h)
end
local function draw_title()
    horizontal_bar(0,522,C.blue)
    horizontal_bar(522,H-522,C.ranking)
    -- Organização observada em screenshot da edição Windows 9.4.2.
    -- A geometria/arte da versão 14.1.4 continua NÃO verificada.
    local mx=W/2
    local fw=fonts.logo:getWidth("ibis")
    local pw=fonts.logo:getWidth("Paint")
    local total=fw+65+pw
    local x=mx-total/2
    text("ibis",x,135,fw+5,fonts.logo,"left",C.white)
    draw_wheel(x+fw+31,169,29)
    text("Paint",x+fw+62,135,pw+8,fonts.logo,"left",C.white)
    text("Ver. 14.1.4",mx+55,210,165,fonts.small,"left",C.white)
    -- Collection foi retirada na versão 12.2.0; não replicá-la a partir de 9.4.2.
    icon_circle(381,363,"My Gallery","pen",function() state:open_gallery() end)
    icon_circle(643,363,"Online Gallery","globe",function()
        love.system.openURL("https://ibispaint.com/")
    end)
    color(C.white,0.24)
    love.graphics.rectangle("fill",0,522,W,1)
    text("Daily Ranking",0,544,W,fonts.header,"center",C.white)
    color(C.white,0.18)
    love.graphics.rectangle("fill",130,593,764,1)
    text("O conteúdo online não é simulado nesta reconstrução.",160,644,704,fonts.medium,"center",C.pale)
    text("Ibis-Lua: referência Windows histórica; fidelidade 14.1.4 pendente",
        0,737,W,fonts.small,"center",C.pale)
end

local function draw_header(title, action, back_cb)
    color(C.dark)
    love.graphics.rectangle("fill",0,0,W,51)
    color(C.white, hovered(9,6,46,39) and 0.17 or 0)
    love.graphics.rectangle("fill",9,6,46,39,5,5)
    back(32,25,13)
    text(title,90,13,W-180,fonts.header,"center",C.white)
    hit(9,6,46,39,back_cb,"back")
    if action then
        color(C.white,hovered(958,6,49,40) and 0.18 or 0.07)
        love.graphics.rectangle("fill",958,6,49,40,4,4)
        plus(982,26,11)
        hit(958,6,49,40,action,"add")
    end
end

local function button(x,y,w,h,label,callback,accent)
    local over=hovered(x,y,w,h)
    color(accent and C.accent or C.dark, over and 0.98 or 0.88)
    love.graphics.rectangle("fill",x,y,w,h,6,6)
    text(label,x,y+(h-18)/2,w,fonts.medium,"center",C.white)
    hit(x,y,w,h,callback,label)
end
local function draw_gallery()
    horizontal_bar(0,H,C.cream)
    draw_header("My Gallery",function()
        state:open_new_canvas()
    end,function() state.screen="title" end)
    color(C.dark,0.16)
    love.graphics.setLineWidth(1)
    love.graphics.line(0,51,W,51)
    text("Nenhuma obra demonstrativa criada",0,330,W,fonts.medium,"center",{0.52,0.52,0.52})
    text("Use + para abrir a criação de tela.",0,364,W,fonts.small,"center",{0.62,0.62,0.62})
    if state.modal=="new_canvas" then
        color({0,0,0},0.52)
        love.graphics.rectangle("fill",0,0,W,H)
        -- Bloqueia clique nos controles da tela abaixo da janela modal.
        hit(0,0,W,H,function() end,"modal_scrim")
        local x,y,w,h=306,171,412,422
        color(C.modal)
        love.graphics.rectangle("fill",x,y,w,h,10,10)
        color(C.dark)
        text("New Canvas",x+30,y+22,w-60,fonts.header,"center",C.dark)
        text("Any Size",x+32,y+89,w-64,fonts.medium,"center",C.dark)
        local fields={
            {key="width",label="Width",value=width_text,px=x+38,py=y+158},
            {key="height",label="Height",value=height_text,px=x+220,py=y+158}
        }
        for _,f in ipairs(fields) do
            text(f.label,f.px,f.py-28,153,fonts.small,"left",C.dark)
            color(C.white)
            love.graphics.rectangle("fill",f.px,f.py,153,45,4,4)
            color(focused_input==f.key and C.accent or {0.65,0.66,0.67})
            love.graphics.setLineWidth(focused_input==f.key and 2 or 1)
            love.graphics.rectangle("line",f.px,f.py,153,45,4,4)
            text(f.value,f.px+8,f.py+12,137,fonts.medium,"center",C.dark)
            hit(f.px,f.py,153,45,function() focused_input=f.key end,"field_"..f.key)
        end
        text("Pixels",x+35,y+217,w-70,fonts.small,"center",{0.52,0.52,0.52})
        button(x+36,y+289,158,47,"Cancel",function()
            state:cancel_new_canvas()
            focused_input=nil
        end,false)
        button(x+215,y+289,158,47,"OK",function()
            local wi,he=tonumber(width_text),tonumber(height_text)
            if wi and he and wi>=1 and wi<=16384 and wi==math.floor(wi)
            and he>=1 and he<=16384 and he==math.floor(he) then
                state:create_canvas(wi,he)
                focused_input=nil
            end
        end,true)
        text("Dimensões e diálogo ainda aguardam validação visual.",
            x+20,y+364,w-40,fonts.small,"center",{0.45,0.45,0.45})
    end
end
local function draw_editor()
    -- Apenas a estrutura de navegação confirmada nos tutoriais;
    -- não constitui implementação estética do editor Windows 14.1.4.
    horizontal_bar(0,H,{0.70,0.71,0.73})
    local canvas_w=math.min(585,640)
    local aspect=(state.document.width/state.document.height)
    local canvas_h=math.min(520,canvas_w/aspect)
    canvas_w=math.min(585,canvas_h*aspect)
    color(C.white)
    love.graphics.rectangle("fill", (W-canvas_w)/2,92,canvas_w,canvas_h)
    draw_header("Canvas",nil,function() state:open_gallery() end)
    color(C.dark)
    love.graphics.rectangle("fill",0,H-61,W,61)
    local controls={
        {"Brush","brush"},{"Eraser","eraser"},{"Tools","tools"},
        {"Properties","brush_panel"},{"Color","color"},{"Undo","undo"},
        {"Redo","redo"},{"Layer","layer"},{"Back","back"}
    }
    local bw=W/#controls
    for i,item in ipairs(controls) do
        local x=(i-1)*bw
        if hovered(x,H-61,bw,61) then
            color(C.white,0.12)
            love.graphics.rectangle("fill",x,H-61,bw,61)
        end
        text(item[1],x,H-40,bw,fonts.small,"center",C.white)
        local key=item[2]
        hit(x,H-61,bw,61,function()
            if key=="brush" or key=="eraser" then state:set_tool(key)
            elseif key=="color" then state:toggle_panel("color")
            elseif key=="layer" then state:toggle_panel("layer")
            elseif key=="brush_panel" then state:toggle_panel("brush")
            elseif key=="back" then state:open_gallery()
            elseif key=="tools" then state.active_panel="tools"
            end
        end,item[2])
    end
    if state.active_panel then
        local x,y,w,h=W-334,67,314,340
        color(C.dark,0.96)
        love.graphics.rectangle("fill",x,y,w,h,6,6)
        local label = ({brush="Brush",color="Color",layer="Layer",tools="Tool Select"})[state.active_panel]
        text(label,x+16,y+16,w-32,fonts.header,"center",C.white)
        if state.active_panel=="layer" then
            for i,layer in ipairs(state.layers) do
                local yy=y+58+(i-1)*44
                if yy<y+h-55 then
                    text(layer.name,x+12,yy,w-76,fonts.small,"left",C.white)
                    text(layer.visible and "On" or "Off",x+w-58,yy,43,fonts.small,"center",C.white)
                    hit(x+10,yy,w-20,34,function() state:toggle_layer_visibility(layer.id) end,"layer")
                end
            end
            button(x+65,y+h-60,185,38,"+ Layer",function() state:add_layer() end,true)
        elseif state.active_panel=="brush" then
            text("Brush size: "..tostring(state.brush_size),x+15,y+102,w-30,fonts.medium,"center",C.white)
            button(x+33,y+163,96,43,"-",function() state:set_brush_size(math.max(0.1,state.brush_size-1)) end)
            button(x+184,y+163,96,43,"+",function() state:set_brush_size(math.min(1000,state.brush_size+1)) end)
        elseif state.active_panel=="color" then
            text("RGB "..table.concat(state.color,", "),x+16,y+74,w-32,fonts.medium,"center",C.white)
            for i,entry in ipairs({{0,0,0},{255,255,255},{255,0,0},{0,140,235},{34,181,90}}) do
                local px=x+17+(i-1)*57
                love.graphics.setColor(entry[1]/255,entry[2]/255,entry[3]/255)
                love.graphics.rectangle("fill",px,y+131,46,45,3,3)
                hit(px,y+131,46,45,function() state:set_color(entry[1],entry[2],entry[3]) end,"swatch")
            end
        elseif state.active_panel=="tools" then
            local names={{"Brush","brush"},{"Eraser","eraser"},{"Transform","transform"},
                {"Magic Wand","magic_wand"},{"Lasso","lasso"},{"Filter","filter"},
                {"Bucket","bucket"},{"Text","text"},{"Eyedropper","eyedropper"}}
            for i,item in ipairs(names) do
                local px=x+11+((i-1)%2)*151
                local py=y+53+math.floor((i-1)/2)*43
                if py<y+h-32 then
                    local tool_key=item[2]
                    button(px,py,141,35,item[1],function()
                        state:set_tool(tool_key)
                        state.active_panel=nil
                    end)
                end
            end
        end
    end
    text("Editor visual 14.1.4 ainda não validado",0,69,W,fonts.small,"center",{0.30,0.30,0.30})
end

local function screenshot()
    if capture_pending then return end
    capture_pending=true
    love.graphics.captureScreenshot(function(image)
        local ok, data=pcall(function() return image:encode("png") end)
        if not ok then capture_error=tostring(data)
        else
            local wrote,err=love.filesystem.write("ci-smoke.png",data)
            if not wrote then capture_error=tostring(err) end
        end
        capture_pending=false
        capture_done=true
    end)
end

function love.load()
    fonts.small=love.graphics.newFont(13)
    fonts.medium=love.graphics.newFont(16)
    fonts.header=love.graphics.newFont(21)
    fonts.logo=love.graphics.newFont(68)
end

function love.resize()
    -- Projeção recalculada a cada draw.
end

function love.draw()
    local w,h=love.graphics.getDimensions()
    scale=math.min(w/W,h/H)
    offx=(w-W*scale)/2
    offy=(h-H*scale)/2
    love.graphics.clear(0.08,0.09,0.11,1)
    love.graphics.push()
    love.graphics.translate(offx,offy)
    love.graphics.scale(scale)
    buttons={}
    if state.screen=="title" then draw_title()
    elseif state.screen=="gallery" then draw_gallery()
    elseif state.screen=="editor" then draw_editor()
    end
    love.graphics.pop()
    if capture_requested then
        capture_requested=false
        screenshot()
    end
end

function love.mousepressed(x,y,button)
    if button~=1 then return end
    x=(x-offx)/scale
    y=(y-offy)/scale
    -- Ordenação reversa: elementos sobrepostos são interativos antes dos de trás.
    for i=#buttons,1,-1 do
        local b=buttons[i]
        if inside(b,x,y) then b.fn(); return end
    end
    if focused_input and state.modal~="new_canvas" then focused_input=nil end
end
function love.textinput(t)
    if state.modal~="new_canvas" or not focused_input then return end
    if not t:match("^%d$") then return end
    if focused_input=="width" then
        if #width_text<5 then width_text=width_text..t end
    elseif #height_text<5 then height_text=height_text..t end
end
function love.keypressed(key)
    if key=="f12" then capture_requested=true; return end
    if state.modal=="new_canvas" then
        if key=="escape" then
            state:cancel_new_canvas();focused_input=nil
        elseif key=="backspace" then
            if focused_input=="width" then width_text=width_text:sub(1,-2)
            elseif focused_input=="height" then height_text=height_text:sub(1,-2) end
        elseif key=="tab" then focused_input=(focused_input=="width" and "height" or "width")
        elseif key=="return" then
            local wi,he=tonumber(width_text),tonumber(height_text)
            if wi and he and wi>=1 and wi<=16384 and he>=1 and he<=16384 then
                state:create_canvas(wi,he);focused_input=nil
            end
        end
        return
    end
    if key=="escape" then
        if state.active_panel then state.active_panel=nil
        elseif state.screen=="editor" then state:open_gallery()
        elseif state.screen=="gallery" then state.screen="title"
        else love.event.quit() end
    end
end
function love.update()
    if smoke and capture_done then
        if capture_error then error("Falha na captura: "..capture_error) end
        love.event.quit(0)
    end
end
