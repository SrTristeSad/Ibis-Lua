local Model=require("src.model")
local handle=assert(io.open("src/iconset.lua","rb"))
local source=handle:read("*a")
handle:close()
local function assertHas(name)
  assert(source:find('renderers["'..name..'"]',1,true),
    "No specific icon exists for: "..name)
end
for _,tool in ipairs(Model.tools) do assertHas(tool) end
for _,name in ipairs({
 "BrushEraser","Tool Select","Undo","Redo","Down","Layer","Back",
 "View","Selection","Stabilizer","Shape","Ruler","Material",
 "Camera","GalleryAdd","Info","Play","Share","More"
}) do assertHas(name) end
print("icon coverage: "..#Model.tools.." tools and navigation commands: OK")
