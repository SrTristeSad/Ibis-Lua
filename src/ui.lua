local U={}
local lg=love.graphics
U.C={
 blue={0.15,0.29,0.46},navy={0.09,0.19,0.32},
 bar={0.38,0.38,0.38},panel={0.29,0.29,0.29,0.95},
 ink={0.12,0.12,0.12},gray={0.64,0.64,0.64},
 white={1,1,1},offwhite={0.96,0.95,0.91},
 pale={0.88,0.88,0.88},accent={0.12,0.52,0.88},
 selected={0.26,0.52,0.78},black={0,0,0}
}
local hits={}
local fonts={}
function U.init()
  fonts.small=lg.newFont(11)
  fonts.body=lg.newFont(14)
  fonts.heading=lg.newFont(19)
  fonts.title=lg.newFont(48)
end
function U.begin()
  hits={}
  lg.setLineWidth(1)
  lg.setLineJoin("none")
end
function U.color(c,alpha)
  lg.setColor(c[1],c[2],c[3],alpha or c[4] or 1)
end
function U.rect(x,y,w,h,c,r)
  U.color(c)
  if r then lg.rectangle("fill",x,y,w,h,r,r) else lg.rectangle("fill",x,y,w,h) end
end
function U.stroke(x,y,w,h,c,r)
  U.color(c)
  if r then lg.rectangle("line",x+0.5,y+0.5,w-1,h-1,r,r)
  else lg.rectangle("line",x+0.5,y+0.5,w-1,h-1) end
end
function U.text(s,x,y,w,color,font,align)
  U.color(color or U.C.white)
  lg.setFont(fonts[font or "body"] or fonts.body)
  lg.printf(tostring(s),x,y,w,align or "left")
end
function U.line(x1,y1,x2,y2,color,thick)
  U.color(color or U.C.white)
  lg.setLineWidth(thick or 1.5)
  lg.line(x1,y1,x2,y2)
  lg.setLineWidth(1)
end
function U.circle(x,y,r,c,outline)
  U.color(c)
  lg.circle(outline and "line" or "fill",x,y,r)
end
function U.hitbox(x,y,w,h,callback)
  if callback then hits[#hits+1]={x=x,y=y,w=w,h=h,fn=callback} end
end
function U.dispatch(x,y)
  for i=#hits,1,-1 do
    local h=hits[i]
    if x>=h.x and x<=h.x+h.w and y>=h.y and y<=h.y+h.h then
      h.fn((x-h.x)/math.max(h.w,1),(y-h.y)/math.max(h.h,1))
      return true
    end
  end
  return false
end
function U.button(label,x,y,w,h,callback,selected,color)
  U.rect(x,y,w,h,selected and U.C.selected or (color or U.C.bar),4)
  U.text(label,x+5,y+(h-16)/2,w-10,U.C.white,"body","center")
  U.hitbox(x,y,w,h,callback)
end
function U.roundButton(label,x,y,r,callback)
  U.circle(x,y,r,{0.98,0.98,0.98,0.10})
  U.circle(x,y,r,U.C.white,true)
  U.text(label,x-r,y+r+8,2*r,U.C.white,"body","center")
  U.hitbox(x-r,y-r,r*2,r*2,callback)
end
function U.slider(label,x,y,w,value,min,max,callback)
  U.text(label,x,y-1,w*.58,U.C.white,"small")
  U.text(tostring(math.floor(value+0.5)),x+w-40,y-1,40,U.C.white,"small","right")
  U.rect(x,y+18,w,3,{0.22,0.22,0.22})
  local t=(value-min)/(max-min)
  U.rect(x,y+18,w*t,3,U.C.accent)
  U.circle(x+w*t,y+19,7,U.C.white)
  U.hitbox(x,y+9,w,23,function(p) callback(min+(max-min)*p) end)
end
function U.icon(name,cx,cy,size,colour)
  local c=colour or U.C.white
  local s=size or 16
  local a=s/2
  if name=="Transform" then
    U.line(cx-a,cy,cx+a,cy,c,1.5); U.line(cx,cy-a,cx,cy+a,c,1.5)
    for _,v in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do
      local x=cx+v[1]*a;local y=cy+v[2]*a
      U.line(x,y,x-v[1]*4-v[2]*3,y-v[2]*4-v[1]*3,c)
      U.line(x,y,x-v[1]*4+v[2]*3,y-v[2]*4+v[1]*3,c)
    end
  elseif name=="Magic Wand" or name=="Special" then
    U.line(cx-6,cy+7,cx+5,cy-5,c,2.3)
    U.line(cx+6,cy-9,cx+6,cy-3,c)
    U.line(cx+3,cy-6,cx+9,cy-6,c)
  elseif name=="Lasso" then
    U.color(c);lg.ellipse("line",cx,cy-2,a*.85,a*.55)
    U.line(cx+5,cy+3,cx-1,cy+10,c)
  elseif name=="Filter" then
    U.circle(cx,cy,a,c,true);U.text("fx",cx-a,cy-6,s,c,"small","center")
  elseif name=="Brush" or name=="Eyedropper" then
    U.line(cx-6,cy+8,cx+6,cy-8,c,3)
    U.circle(cx-7,cy+9,2,c)
  elseif name=="Eraser" then
    U.color(c);lg.polygon("line",cx-7,cy+5,cx+2,cy-7,cx+9,cy-1,cx,cy+9)
  elseif name=="Smudge" then
    U.line(cx-8,cy+6,cx-3,cy-5,c,2)
    U.line(cx-3,cy-5,cx+2,cy+3,c,2)
    U.line(cx+2,cy+3,cx+7,cy-6,c,2)
  elseif name=="Blur" then
    U.color(c);lg.polygon("line",cx,cy-10,cx-7,cy+1,cx-5,cy+8,cx+5,cy+8,cx+7,cy+1)
  elseif name=="Bucket" then
    U.color(c);lg.polygon("line",cx-6,cy-1,cx+1,cy-8,cx+8,cy-1,cx+1,cy+6)
  elseif name=="Vector" then
    U.color(c);lg.polygon("line",cx-6,cy-10,cx-6,cy+9,cx,cy+3,cx+7,cy+4)
  elseif name=="Text" then
    U.text("T",cx-a,cy-a-2,s,c,"heading","center")
  elseif name=="Frame Divider" or name=="Canvas" then
    U.stroke(cx-8,cy-8,16,16,c)
    if name=="Frame Divider" then U.line(cx-8,cy,cx+8,cy,c) end
  else
    U.circle(cx,cy,5,c,true)
  end
end
function U.toolButton(name,x,y,w,h,selected,callback)
  if selected then U.rect(x,y,w,h,U.C.accent) end
  U.icon(name,x+w*.5,y+14,17)
  U.text(name,x+1,y+29,w-2,U.C.white,"small","center")
  U.hitbox(x,y,w,h,callback)
end
function U.close(x,y,callback)
  U.text("x",x,y,18,U.C.white,"body","center")
  U.hitbox(x,y,18,20,callback)
end
return U
