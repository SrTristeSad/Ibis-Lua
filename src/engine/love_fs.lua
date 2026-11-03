-- Adaptador portavel do Store RBD2 para o diretorio save do LOVE.
-- Nunca acessa arquivos arbitrarios. Gravacao: temporario + replace atomico.
-- Windows usa a mesma MoveFileExW (substituicao atomica) do rebuild.
local ffi=require('ffi')
local FS={}
FS.__index=FS
local serial=0
local processSalt=love.math.random(1,2147483647)
local function parts(input,empty)
    assert(type(input)=='string' and not input:find('[%z\1-\31:]')
        and not input:match('^[/\\]'),'Caminho relativo invalido')
    local result={}
    for p in input:gmatch('[^/\\]+') do
        assert(p~='.' and p~='..' and not p:match('[ .]$')
            and not p:find('[<>"|?*]'),'Caminho inseguro')
        local stem=p:match('^[^.]+'):upper()
        assert(stem~='CON' and stem~='PRN' and stem~='AUX'
            and stem~='NUL' and not stem:match('^COM[1-9]$')
            and not stem:match('^LPT[1-9]$'),'Nome reservado')
        result[#result+1]=p
    end
    assert(empty or #result>0,'Caminho vazio')
    return result
end
function FS.new(root)
    local name=table.concat(parts(root),'/')
    local ok=love.filesystem.createDirectory(name)
    assert(ok,'Nao foi possivel criar raiz de projetos RBD2')
    return setmetatable({root=name},FS)
end
function FS:relative(path)
    local pathParts=parts(path or '',true)
    if #pathParts==0 then return self.root end
    return self.root..'/'..table.concat(pathParts,'/')
end
function FS:mkdir(relative)
    local path=self:relative(relative)
    assert(love.filesystem.createDirectory(path),'Falha ao criar pasta RBD2')
    return path
end
function FS:exists(relative)
    return love.filesystem.getInfo(self:relative(relative))~=nil
end
function FS:size(relative)
    local info=love.filesystem.getInfo(self:relative(relative))
    assert(info and info.type=='file' and type(info.size)=='number',
        'Arquivo RBD2 inexistente')
    return info.size
end
function FS:read(relative,maxBytes)
    local path=self:relative(relative)
    local info=love.filesystem.getInfo(path)
    assert(info and info.type=='file' and
        info.size<=(maxBytes or 67108864),'Arquivo RBD2 grande ou ausente')
    local data,err=love.filesystem.read(path)
    assert(type(data)=='string' and #data==info.size,
        'Leitura RBD2 incompleta: '..tostring(err))
    return data
end
function FS:readRange(relative,offset,count,maxFileBytes)
    assert(type(offset)=='number' and offset%1==0 and offset>=0
        and type(count)=='number' and count%1==0 and
        count>=0 and count<=67108864,'Intervalo RBD2 invalido')
    local size=self:size(relative)
    assert(size<=(maxFileBytes or 67108864)
        and offset+count<=size,'Arquivo RBD2 truncado')
    if count==0 then return '' end
    local file=love.filesystem.newFile(self:relative(relative))
    local ok,err=file:open('r')
    assert(ok,'Nao foi possivel abrir RBD2: '..tostring(err))
    local success,data=pcall(function()
        assert(file:seek(offset),'Seek RBD2 falhou')
        return file:read(count)
    end)
    file:close()
    assert(success and type(data)=='string' and #data==count,
        'Leitura parcial de RBD2 falhou')
    return data
end
local function windowsReplace(source,target)
    ffi.cdef[[
    int MultiByteToWideChar(unsigned int,unsigned long,
        const char*,int,unsigned short*,int);
    int MoveFileExW(const unsigned short*,const unsigned short*,
        unsigned long);
    unsigned long GetLastError(void);
    ]]
    local k=ffi.load('kernel32')
    local function wide(text)
        local n=k.MultiByteToWideChar(65001,8,text,#text,nil,0)
        assert(n>0,'Caminho UTF-8 invalido')
        local out=ffi.new('unsigned short[?]',n+1)
        assert(k.MultiByteToWideChar(65001,8,text,#text,out,n)==n)
        return out
    end
    local ok=k.MoveFileExW(wide(source),wide(target),9)
    assert(ok~=0,'Replace RBD2 Windows falhou: '..tonumber(k.GetLastError()))
end
function FS:writeAtomic(relative,data)
    assert(type(data)=='string' and #data<=67108864,
        'Escrita RBD2 excede 64 MiB ou tipo invalido')
    local p=parts(relative)
    if #p>1 then self:mkdir(table.concat(p,'/',1,#p-1)) end
    local target=self:relative(relative)
    serial=serial+1
    local temp=target..('.tmp-%08x-%08x'):format(processSalt,serial)
    local ok,err=love.filesystem.write(temp,data)
    assert(ok,'Falha ao escrever temporario RBD2: '..tostring(err))
    local root=love.filesystem.getSaveDirectory()
    local from=root..'/'..temp
    local to=root..'/'..target
    local moved,reason=pcall(function()
        if love.system.getOS()=='Windows' then
            windowsReplace(from,to)
        else
            assert(os.rename(from,to),'Rename atomico RBD2 falhou')
        end
    end)
    if not moved then
        love.filesystem.remove(temp)
        error('Falha ao publicar RBD2: '..tostring(reason),2)
    end
    return true
end
function FS:list(relative)
    local dir=self:relative(relative)
    local info=love.filesystem.getInfo(dir)
    assert(info and info.type=='directory','Pasta RBD2 nao existe')
    local rows={}
    for _,name in ipairs(love.filesystem.getDirectoryItems(dir)) do
        local info=love.filesystem.getInfo(dir..'/'..name)
        if info then
            rows[#rows+1]={name=name,isDirectory=info.type=='directory',
                bytes=info.size or 0}
        end
    end
    table.sort(rows,function(a,b)return a.name<b.name end)
    return rows
end
function FS:delete(relative)
    local path=self:relative(relative)
    local info=love.filesystem.getInfo(path)
    if not info then return false end
    assert(info.type=='file','Recusa excluir diretorio RBD2')
    assert(love.filesystem.remove(path),'Exclusao RBD2 falhou')
    return true
end
function FS.processId()return processSalt end
return FS
