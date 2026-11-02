-- Catalogo demonstrativo da interface 14.x. Nao implementa pinceladas.
-- Entradas/rotulos sao aproximacoes visuais independentes, nao assets do APK.
local M={}
M.categories={
  {'Todos','tool-select'}, {'Simples','brush'}, {'Esboco','special'},
  {'Quadrinhos','frame'}, {'Tinta','picker'}, {'Vetor','vector'},
  {'Aerografo','blur'}, {'Aquarela','smudge'}, {'Marcador','eraser'},
  {'Pastel','brush'}, {'Tela','canvas'}
}
M.entries={
  {'Caneta G (Suave)','Simples',3},
  {'Caneta G (Dura)','Simples',3},
  {'Caneta G (Tinta)','Tinta',11},
  {'Caneta (Suave)','Simples',3},
  {'Caneta (Dura)','Simples',8},
  {'Caneta (Dissolver)','Tinta',48},
  {'Caneta Digital','Simples',8},
  {'Caneta (Desvanecer)','Simples',80},
  {'Lapis (Grafite)','Esboco',4},
  {'Lapis (Esboco)','Esboco',7},
  {'Lapis (Mecanico)','Esboco',3},
  {'Caneta para Mangas','Quadrinhos',4},
  {'Caneta de Contorno','Quadrinhos',7},
  {'Caneta de Tinta','Tinta',6},
  {'Caneta com Sangramento','Tinta',8},
  {'Caneta Vetorial','Vetor',3},
  {'Caneta de Bezier','Vetor',5},
  {'Aerografo (Normal)','Aerografo',48},
  {'Aerografo (Triangulo)','Aerografo',50},
  {'Aquarela (Opaca)','Aquarela',12},
  {'Aquarela (Mistura)','Aquarela',14},
  {'Marcador (Quadrado)','Marcador',11},
  {'Marcador (Redondo)','Marcador',9},
  {'Pastel Matte','Pastel',18},
  {'Pastel Expressivo','Pastel',16},
  {'Pincel de Tela','Tela',21}
}
function M.filter(category,search)
  local found={}
  local text=type(search)=='string' and string.lower(search) or ''
  for _,entry in ipairs(M.entries) do
    if (not category or category=='Todos' or category==entry[2])
      and (text=='' or string.lower(entry[1]):find(text,1,true)) then
      found[#found+1]=entry
    end
  end
  return found
end
function M.find(name)
  for _,entry in ipairs(M.entries) do
    if entry[1]==name then return entry end
  end
end
return M
