local M = {}

M.tools = {
  "Transform", "Magic Wand", "Lasso", "Filter", "Brush",
  "Eraser", "Smudge", "Blur", "Special", "Bucket",
  "Vector", "Text", "Frame Divider", "Eyedropper", "Canvas"
}
M.brushes = {
  "Dip Pen (Hard)", "Dip Pen (Soft)", "Digital Pen", "Felt Tip Pen",
  "G Pen (Hard)", "G Pen (Soft)", "G Pen (Bleed)", "Airbrush (Normal)",
  "Airbrush (Triangle)", "Pencil (#2)", "Flat Brush", "Watercolor (Opaque)"
}
M.presets = {
  {"SD (Speed)",1024,768}, {"1:1 (SD)",1280,1280},
  {"3:4 (SD)",1024,768}, {"9:16 (SD)",720,1280},
  {"Twitter Header",1500,500}, {"Chat Stamp",370,320},
  {"Vertical",690,4096}, {"A4 (150 dpi)",1240,1754},
  {"A5 (150 dpi)",874,1240}, {"B4 (150 dpi)",1476,2085}
}

function M.new()
  return {
    page = "title", panel = nil, modal = nil, menu = nil,
    tool = "Brush", brush = 5, brushTab = "Basic", brushSize = 17,
    brushOpacity = 100, hue = 0.01, color = {0,0,0},
    brushParamTab = "Basic", brushAdvanced = false,
    brushParams = {startThickness=100,endThickness=100,startOpacity=100,
      endOpacity=100,fadeStrength=0},
    w = 1800, h = 2400, preset = 0, workName = "Untitled",
    works = {}, activeWork = nil, galleryMenu = false,
    layers = {}, selectedLayer = 1, blend = "Normal",
    layerOpacity = 100, zoom = 100, panX = 0, panY = 0,
    settings = {reference=false, invertWheel=false, showGrid=false, darkCanvas=false},
    focus = nil, notification = nil
  }
end

function M.openGallery(s)
  s.page = "gallery"; s.panel=nil; s.modal=nil; s.menu=nil
end
function M.openNewCanvas(s)
  s.page = "gallery"; s.modal="newCanvas"; s.panel=nil; s.menu=nil
end
function M.createCanvas(s)
  local width, height = math.floor(tonumber(s.w) or 1800), math.floor(tonumber(s.h) or 2400)
  if width < 1 or height < 1 or width > 16000 or height > 16000 then
    s.notification="Canvas size must be between 1 and 16000."; return false
  end
  s.w, s.h = width, height
  s.workName = "Untitled " .. tostring(#s.works + 1)
  local work = {title=s.workName,w=width,h=height}
  table.insert(s.works,1,work)
  s.activeWork=work
  s.layers={{name="1",visible=true,opacity=100,blend="Normal",kind="raster"}}
  s.selectedLayer=1
  s.page="editor";s.panel=nil;s.modal=nil;s.menu=nil
  s.zoom=100;s.panX=0;s.panY=0
  return true
end
function M.openWork(s, index)
  local work=s.works[index]
  if not work then return false end
  s.activeWork=work;s.w=work.w;s.h=work.h;s.workName=work.title
  s.page="editor";s.panel=nil;s.modal=nil;s.menu=nil
  s.layers={{name="1",visible=true,opacity=100,blend="Normal",kind="raster"}}
  s.selectedLayer=1;s.zoom=100;s.panX=0;s.panY=0
  return true
end
function M.setTool(s, tool)
  for _,value in ipairs(M.tools) do
    if value==tool then
      s.tool=tool;s.menu=nil
      if tool=="Brush" or tool=="Eraser" then s.panel="brush"
      elseif tool=="Text" then s.panel="text"
      elseif tool=="Filter" then s.panel="filter"
      elseif tool=="Transform" then s.panel="transform"
      else s.panel=nil end
      return true
    end
  end
  return false
end
function M.togglePanel(s, panel)
  s.modal=nil;s.menu=nil
  if s.panel==panel then s.panel=nil else s.panel=panel end
end
function M.setBrush(s,index)
  if M.brushes[index] then s.brush=index;return true end
  return false
end
function M.setBrushSize(s, n)
  s.brushSize=math.max(1,math.min(1000,math.floor(n+0.5)))
end
function M.setBrushOpacity(s,n)
  s.brushOpacity=math.max(0,math.min(100,math.floor(n+0.5)))
end
function M.setZoom(s,n)
  s.zoom=math.max(10,math.min(800,math.floor(n+0.5)))
end
function M.setColor(s,r,g,b)
  s.color={math.max(0,math.min(1,r)),math.max(0,math.min(1,g)),math.max(0,math.min(1,b))}
end
function M.addLayer(s,kind)
  local n=#s.layers+1
  table.insert(s.layers,1,{name=tostring(n),visible=true,opacity=100,blend="Normal",kind=kind or "raster"})
  s.selectedLayer=1
end
function M.duplicateLayer(s)
  local layer=s.layers[s.selectedLayer]
  if not layer then return end
  table.insert(s.layers,s.selectedLayer,{name=layer.name.." Copy",visible=layer.visible,
    opacity=layer.opacity,blend=layer.blend,kind=layer.kind})
end
function M.deleteLayer(s)
  if #s.layers<=1 then s.notification="At least one layer is required.";return end
  table.remove(s.layers,s.selectedLayer)
  s.selectedLayer=math.min(s.selectedLayer,#s.layers)
end
function M.selectLayer(s,index)
  if s.layers[index] then
    s.selectedLayer=index;s.layerOpacity=s.layers[index].opacity
    s.blend=s.layers[index].blend
  end
end
function M.setBlend(s,blend)
  local layer=s.layers[s.selectedLayer]
  if layer then layer.blend=blend;s.blend=blend end
end
function M.setLayerOpacity(s,v)
  local layer=s.layers[s.selectedLayer]
  if layer then
    layer.opacity=math.max(0,math.min(100,math.floor(v+0.5)))
    s.layerOpacity=layer.opacity
  end
end
function M.back(s)
  if s.menu then s.menu=nil
  elseif s.modal then s.modal=nil
  elseif s.panel then s.panel=nil
  elseif s.page=="editor" then M.openGallery(s)
  elseif s.page~="title" then s.page="title"
  end
end
return M
