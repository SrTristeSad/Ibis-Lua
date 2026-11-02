-- Primitivas visuais e despacho de hitboxes. Sem motor gráfico de pintura.
local UI={hits={},fonts={}}
local lg=love.graphics
UI.colors={
  workspace={0.745,0.749,0.753}, dark={0.25,0.26,0.27},
  toolbar={0.205,0.209,0.220}, panel={0.263,0.270,0.285},
  panel2={0.32,0.33,0.35}, line={0.46,0.47,0.49},
  white={0.97,0.97,0.98}, soft={0.75,0.77,0.79},
  blue={0.28,0.64,0.96}, accent={0.25,0.63,0.94},
  pink={1,0.82,0.9}, gallery={0.94,0.94,0.95},
  ink={0.17,0.19,0.21}, paper={1,1,1},
}
function UI.font(size)
  if not UI.fonts[size] then UI.fonts[size]=lg.newFont(size) end
  return UI.fonts[size]
end
function UI.color(name,alpha)
  local c=type(name)=='table' and name or UI.colors[name] or UI.colors.white
  lg.setColor(c[1],c[2],c[3],alpha or c[4] or 1)
end
function UI.rect(x,y,w,h,name,r,outline)
  UI.color(name)
  lg.rectangle(outline and 'line' or 'fill',x,y,w,h,r or 0,r or 0)
end
function UI.line(x1,y1,x2,y2,color,width)
  UI.color(color)
  lg.setLineWidth(width or 1)
  lg.line(x1,y1,x2,y2)
end
function UI.text(str,x,y,size,color,align,width)
  UI.color(color or 'white')
  lg.setFont(UI.font(size or 12))
  if width then lg.printf(tostring(str),x,y,width,align or 'left')
  else lg.print(tostring(str),x,y) end
end
function UI.hit(rect,action)
  if action then UI.hits[#UI.hits+1]={rect=rect,action=action} end
end
function UI.button(label,x,y,w,h,action,opt)
  opt=opt or {}
  UI.rect(x,y,w,h,opt.bg or 'panel2',opt.radius or 3)
  if opt.border then UI.rect(x+.5,y+.5,w-1,h-1,opt.border,3,true) end
  UI.text(label,x,y+(h-(opt.font or 13))/2-1,opt.font or 13,
    opt.fg or 'white','center',w)
  UI.hit({x=x,y=y,w=w,h=h},action)
end
function UI.dispatch(x,y)
  for i=#UI.hits,1,-1 do
    local h=UI.hits[i]
    if x>=h.rect.x and x<h.rect.x+h.rect.w
      and y>=h.rect.y and y<h.rect.y+h.rect.h then
      h.action();return true
    end
  end
  return false
end
function UI.checker(x,y,w,h,cell)
  cell=cell or 10
  for row=0,math.ceil(h/cell)-1 do
    for col=0,math.ceil(w/cell)-1 do
      local t=(row+col)%2==0 and .95 or .78
      lg.setColor(t,t,t,1)
      lg.rectangle('fill',x+col*cell,y+row*cell,
        math.min(cell,w-col*cell),math.min(cell,h-row*cell))
    end
  end
end
function UI.slider(x,y,w,value,onClick,opts)
  opts=opts or {}
  local v=math.max(0,math.min(1,value))
  if not opts.noTrack then
    UI.rect(x,y+5,w,5,opts.track or 'line',3)
    UI.rect(x,y+5,math.max(1,w*v),5,opts.fill or 'white',3)
  end
  UI.rect(x+w*v-7,y,14,15,'white',7)
  UI.hit({x=x,y=y-6,w=w,h=25},function()
    local mx=love.mouse.getX()/(love.graphics.getHeight()/512)
    onClick(math.max(0,math.min(1,(mx-x)/w)))
  end)
end
function UI.frame(x,y,w,h,title,close)
  UI.rect(x+3,y+5,w,h,'dark',5)
  UI.rect(x,y,w,h,'panel',5)
  UI.rect(x,y,w,32,'toolbar',5)
  UI.line(x,y+31,x+w,y+31,'line',1)
  UI.text(title,x+13,y+8,14,'white')
  UI.button('×',x+w-33,y+3,29,25,close,{bg='toolbar',font=18})
end
return UI
