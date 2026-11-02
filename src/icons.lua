-- Ícones vetoriais independentes feitos para esta casca demonstrativa.
-- Não inclui imagens, fontes ou sprites retirados do aplicativo original.
local M={}
local g=love.graphics
local smallFont
local function line(...) g.line(...) end
local function cir(mode,x,y,r) g.circle(mode,x,y,r,24) end
local function box(mode,x,y,w,h) g.rectangle(mode,x,y,w,h,1,1) end
local function poly(mode,...)g.polygon(mode,...)end
local function label(s,x,y)
  if not smallFont then smallFont=g.newFont(10) end
  g.setFont(smallFont);g.print(s,x,y)
end
function M.draw(id,x,y,diameter,r,gc,b)
  g.push('all')
  g.translate(x,y)
  g.scale((diameter or 22)/24)
  g.setColor(r or .97,gc or .97,b or .97,1)
  g.setLineWidth(1.65);g.setLineJoin('bevel')
  if id=='brush' or id=='brush-toggle' or id=='special' then
    line(-8,8,-4,4,7,-8);poly('line',-9,7,-7,10,-3,8,-4,4)
    if id=='special' then cir('fill',8,-8,1.5);line(5,-8,11,-8) end
  elseif id=='eraser' then
    poly('line',-10,2,-2,-8,9,0,3,9,-4,9)
    line(-4,9,11,9)
  elseif id=='transform' then
    line(-9,-7,-4,-7);line(-9,-7,-9,-2)
    line(9,-7,4,-7);line(9,-7,9,-2)
    line(-9,7,-4,7);line(-9,7,-9,2)
    line(9,7,4,7);line(9,7,9,2)
    line(-3,0,3,0);line(0,-3,0,3)
  elseif id=='wand' then
    line(-6,8,7,-7);line(5,-10,5,-5);line(2,-7,8,-7)
    line(-9,-4,-9,-8);line(-11,-6,-7,-6)
  elseif id=='lasso' then
    g.ellipse('line',-1,-2,9,6,30);line(2,2,9,9);cir('fill',9,9,2)
  elseif id=='filter' then
    cir('line',0,0,10);label('FX',-7,-7)
  elseif id=='smudge' then
    line(-9,8,-3,0,0,-5,4,-8,7,-5)
    line(-7,10,0,5,6,6,9,3)
  elseif id=='blur' then
    cir('line',0,0,3);cir('line',0,0,7);cir('line',0,0,10)
  elseif id=='bucket' then
    poly('line',-10,-2,-2,-10,8,0,0,8)
    line(-5,9,9,9);cir('fill',10,5,2)
  elseif id=='vector' then
    cir('line',-8,7,2.3);cir('line',1,-8,2.3);cir('line',9,5,2.3)
    line(-6,5,0,-6,7,4)
  elseif id=='text' then
    line(-9,-9,9,-9);line(0,-9,0,9);line(-5,9,5,9)
  elseif id=='frame' then
    box('line',-10,-8,20,16);line(0,-8,0,8);line(-10,0,0,0)
  elseif id=='picker' then
    line(-8,8,3,-3);poly('line',-2,-6,2,-10,9,-3,5,1,-2,-6)
    line(-10,9,-7,11)
  elseif id=='canvas' or id=='view' then
    box('line',-10,-9,20,18);line(-5,5,0,-3,5,5)
  elseif id=='tool-select' then
    box('line',-10,-9,8,8);box('line',2,-9,8,8)
    box('line',-10,3,8,8);box('line',2,3,8,8)
  elseif id=='properties' or id=='stabilizer' then
    for i=1,3 do local yy=-8+(i-1)*8
      line(-10,yy,10,yy)
      cir('fill',({-4,5,-1})[i],yy,2.4)
    end
  elseif id=='color' then
    cir('line',0,0,10);cir('fill',4,-3,3);cir('fill',-4,-1,2)
  elseif id=='fullscreen' then
    line(-10,-3,-10,-10,-3,-10);line(3,-10,10,-10,10,-3)
    line(-10,3,-10,10,-3,10);line(10,3,10,10,3,10)
  elseif id=='undo' then
    line(9,7,9,-2,5,-7,-3,-7,-8,-2)
    poly('line',-10,-9,-10,0,-1,0)
  elseif id=='redo' then
    line(-9,7,-9,-2,-5,-7,3,-7,8,-2)
    poly('line',10,-9,10,0,1,0)
  elseif id=='layers' then
    box('line',-10,-9,15,15);box('line',-5,-4,15,15)
  elseif id=='back' then
    line(-10,0,9,0);line(-10,0,-2,-8);line(-10,0,-2,8)
  elseif id=='selection' then
    g.setLineStyle('rough');box('line',-10,-9,20,18);cir('line',0,0,3)
  elseif id=='shape' then
    box('line',-9,-8,12,12);cir('line',5,5,5)
  elseif id=='ruler' then
    box('line',-10,-5,20,10);line(-6,-5,-6,0);line(-1,-5,-1,2);line(4,-5,4,0)
  elseif id=='material' then
    box('line',-10,-9,20,18);cir('fill',4,-4,2)
    line(-9,6,-3,0,0,3,5,-2,9,3)
  elseif id=='eye' then
    poly('line',-11,0,-5,-5,0,-7,5,-5,11,0,5,5,0,7,-5,5)
    cir('fill',0,0,2.8)
  elseif id=='plus' then line(-9,0,9,0);line(0,-9,0,9)
  elseif id=='menu' then line(-9,-6,9,-6);line(-9,0,9,0);line(-9,6,9,6)
  elseif id=='play' then poly('fill',-6,-9,9,0,-6,9)
  elseif id=='check' then line(-9,0,-2,7,9,-7)
  elseif id=='close' then line(-8,-8,8,8);line(-8,8,8,-8)
  elseif id=='settings' then
    cir('line',0,0,8);cir('line',0,0,3)
    for i=0,7 do local a=i*math.pi/4
      line(math.cos(a)*8,math.sin(a)*8,math.cos(a)*11,math.sin(a)*11)
    end
  elseif id=='search' then
    cir('line',-2,-2,7)
    line(3.5,3.5,10,10)
  elseif id=='globe' then
    cir('line',0,0,10)
    g.ellipse('line',0,0,4.5,10,28)
    line(-10,0,10,0)
    g.arc('line','open',0,0,10,math.pi*.18,math.pi*.82,20)
    g.arc('line','open',0,0,10,math.pi*1.18,math.pi*1.82,20)
  elseif id=='folder' then
    poly('line',-10,-5,-2,-5,1,-2,10,-2,10,8,-10,8)
  else cir('line',0,0,9) end
  g.pop()
end
return M
