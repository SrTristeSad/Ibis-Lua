local U={}
local IconSet=require("src.iconset")
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
  fonts.tiny=lg.newFont(9)
  fonts.micro=lg.newFont(8)
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
local function hsv(h,s,v)
  h=h%1
  local i=math.floor(h*6)
  local f=h*6-i
  local p=v*(1-s)
  local q=v*(1-f*s)
  local t=v*(1-(1-f)*s)
  if i==0 then return v,t,p end
  if i==1 then return q,v,p end
  if i==2 then return p,v,t end
  if i==3 then return p,q,v end
  if i==4 then return t,p,v end
  return v,p,q
end
U.hsv=hsv
function U.colorWheel(cx,cy,r,selected)
  local oldR,oldG,oldB,oldA=lg.getColor()
  local count=96
  local inner=r*.58
  for k=0,count-1 do
    local a=-math.pi/2+2*math.pi*k/count
    local b=-math.pi/2+2*math.pi*(k+1)/count
    local red,green,blue=hsv(k/count,1,1)
    lg.setColor(red,green,blue,1)
    lg.polygon("fill",
      cx+math.cos(a)*inner,cy+math.sin(a)*inner,
      cx+math.cos(a)*r,cy+math.sin(a)*r,
      cx+math.cos(b)*r,cy+math.sin(b)*r,
      cx+math.cos(b)*inner,cy+math.sin(b)*inner)
  end
  local col=selected or {0,0,0}
  lg.setColor(col[1],col[2],col[3],1)
  lg.circle("fill",cx,cy,inner-1)
  lg.setColor(1,1,1,0.65)
  lg.circle("line",cx,cy,r)
  lg.setColor(oldR,oldG,oldB,oldA)
end
function U.button(label,x,y,w,h,callback,selected,color)
  U.rect(x,y,w,h,selected and U.C.selected or (color or U.C.bar),4)
  U.text(label,x+5,y+(h-16)/2,w-10,U.C.white,"body","center")
  U.hitbox(x,y,w,h,callback)
end
function U.roundButton(label,x,y,r,callback)
  U.circle(x,y,r,{0.98,0.98,0.98,0.08})
  U.circle(x,y,r,U.C.white,true)
  if label=="My Gallery" then
    U.line(x-11,y+12,x+12,y-12,U.C.white,2.3)
    U.color(U.C.white)
    lg.polygon("line",x-13,y+13,x-8,y+15,x-7,y+9,x-11,y+7)
  elseif label=="Collection" then
    local p={}
    for i=0,9 do
      local angle=-math.pi/2+i*math.pi/5
      local sr=(i%2==0) and 17 or 8
      p[#p+1]=x+math.cos(angle)*sr
      p[#p+1]=y+math.sin(angle)*sr
    end
    U.color(U.C.white);lg.polygon("line",p)
  else
    U.circle(x,y,17,U.C.white,true)
    U.line(x-17,y,x+17,y,U.C.white)
    U.line(x,y-17,x,y+17,U.C.white)
    U.color(U.C.white)
    lg.ellipse("line",x,y,8,17)
  end
  U.text(label,x-r-20,y+r+8,2*r+40,U.C.white,"body","center")
  U.hitbox(x-r,y-r,r*2,r*2,callback)
end
function U.wordmark(x,y)
  U.text("ibis",x,y,110,U.C.white,"title")
  local cx=x+104;local cy=y+26;local radius=21
  for i=0,11 do
    local a=-math.pi/2+i*math.pi/6
    local red,green,blue
    if i<4 then red,green,blue=.94,.31+i*.12,.19
    elseif i<8 then red,green,blue=.17,.74-(i-4)*.08,.48+(i-4)*.11
    else red,green,blue=.32+(i-8)*.12,.26,.83-(i-8)*.11 end
    lg.setColor(red,green,blue,1)
    lg.arc("fill","pie",cx,cy,radius,a,a+math.pi/6)
  end
  U.circle(cx,cy,8,U.C.navy)
  U.text("aint",x+128,y,230,U.C.white,"title")
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
-- Reference-driven standalone vector pictograms; no proprietary sprite assets.
function U.icon(name,cx,cy,size,colour)
  local col=colour or U.C.white
  if not IconSet.draw(name,cx,cy,size or 20,col[1],col[2],col[3]) then
    U.circle(cx,cy,5,col,true)
  end
end
function U.toolButton(name,x,y,w,h,selected,callback)
  if selected then U.rect(x,y,w,h,U.C.accent) end
  U.icon(name,x+w*.5,y+14,17)
  local names={["Magic Wand"]="Magic Wand",["Frame Divider"]="Frame Divider"}
  local labels={["Magic Wand"]="Magic\nWand",["Frame Divider"]="Frame\nDivider",["Special"]="Special",["Eyedropper"]="Eyedropper"}
  U.text(labels[name] or name,x+1,y+26,w-2,U.C.white,"micro","center")
  U.hitbox(x,y,w,h,callback)
end
function U.close(x,y,callback)
  U.text("x",x,y,18,U.C.white,"body","center")
  U.hitbox(x,y,18,20,callback)
end
return U
