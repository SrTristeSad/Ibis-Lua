-- Original vector redraws based on publicly visible ibisPaint Windows UI screenshots.
-- Reference only: https://ibispaint.com/lecture/index.jsp?no=04
-- No images, font files, sprite sheets or icons have been extracted from the application.
local I = {}
local lg = love.graphics

local function L(...) lg.line(...) end
local function P(...) lg.polygon("fill", ...) end
local function O(...) lg.polygon("line", ...) end
local function R(x,y,w,h) lg.rectangle("fill",x,y,w,h) end
local function E(x,y,rx,ry) lg.ellipse("line",x,y,rx,ry) end
local function F(x,y,r) lg.circle("fill",x,y,r) end
local function S(x,y,r) lg.circle("line",x,y,r) end
local function W(n) lg.setLineWidth(n) end
local function join(x,y) F(x,y,1.1) end

local function star(x,y,r)
  L(x-r,y,x+r,y)
  L(x,y-r,x,y+r)
  L(x-r*.55,y-r*.55,x+r*.55,y+r*.55)
  L(x+r*.55,y-r*.55,x-r*.55,y+r*.55)
end

local function droplet()
  P(0,-11, -4,-4, -7,3, -6,7, -3,10, 2,11, 6,8, 7,3, 4,-4)
end

local renderers = {}

renderers["Transform"] = function()
  W(2.2)
  L(-9,0,9,0)
  L(0,-9,0,9)
  P(-12,0,-6,-4,-6,4)
  P(12,0,6,-4,6,4)
  P(0,-12,-4,-6,4,-6)
  P(0,12,-4,6,4,6)
  F(0,0,2)
end
renderers["Magic Wand"] = function()
  W(3.1)
  L(-9,9,3,-3)
  W(1.1)
  star(6,-7,4)
  star(-6,-8,2)
  star(9,3,1.9)
end
renderers["Lasso"] = function()
  W(2.4)
  lg.arc("line","open",-1,-3,8,0.15,math.pi*1.93)
  L(5,3,-2,11)
  L(-2,11,2,9)
end
renderers["Filter"] = function()
  F(0,0,10)
  lg.setColor(.35,.35,.35)
  local f=lg.getFont()
  local txt="FX"
  lg.print(txt,-f:getWidth(txt)*.5,-f:getHeight()*.5)
end
renderers["Brush"] = function()
  P(-10,11, -7,3, 4,-8, 8,-4, -3,7)
  P(4,-8,7,-11,11,-7,8,-4)
  P(-7,3,-10,7,-12,12,-6,10,-3,7)
end
renderers["Eraser"] = function()
  P(-11,2,1,-10,11,0,-1,12)
  lg.setColor(.4,.4,.4)
  W(1.4)
  L(-6,7,6,-5)
  L(0,11,10,1)
end
renderers["Smudge"] = function()
  -- Raised finger/hand silhouette.
  W(3.3)
  L(-8,7,-6,1,-2,-3,0,-10)
  L(0,-10,2,-11,4,-9,3,-1)
  L(3,-1,6,-4,8,-3,7,2,4,8)
  L(-8,7,-3,11,3,10,4,8)
end
renderers["Blur"] = droplet
renderers["Special"] = function()
  W(2.6)
  L(-10,10,2,-4)
  L(-5,11,6,-3)
  W(1.6)
  star(8,-8,3)
  star(-7,-7,2)
end
renderers["Special Pen"] = renderers["Special"]
renderers["Bucket"] = function()
  P(-9,-1,0,-10,10,0,1,9)
  lg.setColor(.42,.42,.42)
  W(1.2)
  L(-7,-1,2,-9)
  lg.setColor(1,1,1)
  droplet()
end
renderers["Vector"] = function()
  P(-8,-11,-8,11,-2,5,3,12,7,10,2,3,10,3)
  lg.setColor(.42,.42,.42)
  W(1)
  L(-5,-7,-5,6)
end
renderers["Text"] = function()
  W(2.2)
  L(-9,-10,9,-10)
  L(0,-10,0,11)
  L(-4,11,4,11)
end
renderers["Frame Divider"] = function()
  W(2)
  O(-10,-10,10,-10,10,10,-10,10)
  L(-10,1,10,1)
  L(3,-10,3,1)
end
renderers["Eyedropper"] = function()
  W(3)
  L(-8,9,5,-4)
  W(2)
  L(2,-8,7,-3)
  L(6,-10,10,-6)
  L(-10,8,-7,11)
end
renderers["Canvas"] = function()
  W(1.8)
  O(-10,-10,10,-10,10,10,-10,10)
  L(-10,5,10,5)
  S(5,-5,2)
end
renderers["Layer"] = function()
  W(1.6)
  for i=0,2 do
    local off=i*2.3
    O(-10+off,-8-off,4+off,-8-off,4+off,5-off,-10+off,5-off)
  end
  lg.setColor(.2,.2,.2)
  lg.print("1",-2,-9)
end
renderers["Undo"] = function()
  W(2.4)
  lg.arc("line","open",2,2,8,-2.3,1.5)
  P(-11,-5,-2,-8,-4,0)
end
renderers["Redo"] = function()
  W(2.4)
  lg.arc("line","open",-2,2,8,1.65,5.4)
  P(11,-5,2,-8,4,0)
end
renderers["Back"] = function()
  W(1.9)
  L(-9,0,10,0)
  L(-9,0,-2,-7)
  L(-9,0,-2,7)
end
renderers["Full Screen"] = function()
  W(1.8)
  L(-10,-4,-10,-10,-4,-10)
  L(10,-4,10,-10,4,-10)
  L(-10,4,-10,10,-4,10)
  L(10,4,10,10,4,10)
end
renderers["BrushEraser"] = function()
  W(2.2)
  L(-9,-8,7,8)
  L(-9,8,7,-8)
  P(7,8,11,11,9,6)
  P(7,-8,11,-11,9,-6)
end
renderers["Tool Select"] = function()
  -- Slanted pen-tip silhouette follows the Windows toolbar reference.
  P(-10,9,-8,1,6,-10,10,-6,-4,5)
  P(-10,9,-4,5,-6,11)
end
renderers["Properties"] = function()
  W(2.2)
  L(-10,-7,10,-7)
  L(-10,0,10,0)
  L(-10,7,10,7)
  F(-3,-7,2.5);F(5,0,2.5);F(-5,7,2.5)
end
renderers["View"] = function()
  W(2)
  L(-10,-6,10,-6);L(-10,6,10,6)
  F(0,-6,2.3);F(-4,6,2.3)
end
renderers["Selection"] = function()
  W(1.7)
  for x=-9,9,5 do
    L(x,-9,math.min(x+2,10),-9)
    L(x,9,math.min(x+2,10),9)
  end
  for y=-9,9,5 do
    L(-9,y,-9,math.min(y+2,10))
    L(9,y,9,math.min(y+2,10))
  end
end
renderers["Stabilizer"] = function()
  W(2.1)
  L(-7,9,-8,2,-3,-1,-2,-10)
  L(-2,-10,1,-11,2,-8,1,-1)
  L(1,-1,5,-4,8,-2,8,3,5,9)
  L(-7,9,0,11,5,9)
end
renderers["Shape"] = function()
  W(1.9)
  S(-4,-3,6)
  O(0,-1,10,-1,10,9,0,9)
end
renderers["Ruler"] = function()
  W(1.8)
  O(-10,1,2,-11,11,-2,-1,10)
  L(-4,-5,-1,-2);L(1,-6,4,-3);L(0,1,3,4)
end
renderers["Material"] = function()
  W(1.6)
  O(-10,-9,10,-9,10,9,-10,9)
  F(4,-4,2)
  P(-8,7,-3,-1,0,2,4,-3,9,7)
end
renderers["Down"] = function()
  W(2)
  L(0,-10,0,9);L(-7,2,0,9,7,2)
end
renderers["Minus"] = function() W(2.2) L(-7,0,7,0) end
renderers["Plus"] = function() W(2.2) L(-7,0,7,0) L(0,-7,0,7) end
renderers["Info"] = function()
  W(1.6)
  S(0,0,10)
  F(0,-5,1.2)
  L(0,-2,0,7)
end
renderers["Play"] = function()
  P(-6,-10,10,0,-6,10)
end
renderers["Share"] = function()
  W(1.8)
  O(-10,0,-10,10,9,10,9,0)
  L(-2,4,10,-8)
  L(3,-8,10,-8,10,-1)
end
renderers["GalleryAdd"] = function()
  W(2)
  L(-9,0,9,0)
  L(0,-9,0,9)
end
renderers["Camera"] = function()
  W(1.75)
  O(-11,-7,-5,-7,-3,-10,4,-10,6,-7,11,-7,11,9,-11,9)
  S(0,1,5)
  F(8,-4,1.1)
end
renderers["Check"] = function()
  W(2.8)
  L(-9,0,-3,6,10,-8)
end
renderers["Move"] = function()
  W(1.8)
  L(-9,-5,8,-5)
  L(-9,0,8,0)
  L(-9,5,8,5)
end
renderers["Eye"] = function()
  W(1.8)
  lg.arc("line","open",0,0,11,-.9,math.pi+.9)
  lg.arc("line","open",0,0,11,math.pi-.9,math.pi*2+.9)
  S(0,0,4)
  F(0,0,2)
end
renderers["Trash"] = function()
  W(1.8)
  O(-7,-6,7,-6,5,10,-5,10)
  L(-9,-9,9,-9)
  L(-4,-11,4,-11)
  L(-2,-3,-2,6)
  L(2,-3,2,6)
end
renderers["Duplicate"] = function()
  W(1.8)
  O(-10,-7,4,-7,4,7,-10,7)
  O(-5,-11,10,-11,10,4,4,4)
end
renderers["Folder"] = function()
  W(1.8)
  O(-10,-5,-4,-5,-2,-8,2,-8,4,-5,10,-5,10,8,-10,8)
end
renderers["Lock"] = function()
  W(2)
  O(-8,-1,8,-1,8,10,-8,10)
  lg.arc("line","open",0,-2,6,math.pi,2*math.pi)
end
renderers["More"] = function()
  F(-8,0,2);F(0,0,2);F(8,0,2)
end

function I.draw(name,x,y,size,r,g,b)
  local painter=renderers[name]
  if not painter then return false end
  local oldR,oldG,oldB,oldA=lg.getColor()
  local oldWidth=lg.getLineWidth()
  lg.push()
  lg.translate(x,y)
  lg.scale((size or 22)/24)
  lg.setColor(r or 1,g or 1,b or 1)
  lg.setLineStyle("smooth")
  painter()
  lg.pop()
  lg.setLineWidth(oldWidth)
  lg.setColor(oldR,oldG,oldB,oldA)
  return true
end

return I
