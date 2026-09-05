local factories, loaded = {}, {}
local function require(name)
    if loaded[name] ~= nil then return loaded[name] end
    assert(factories[name], "Unknown Lapo module: " .. tostring(name))
    loaded[name] = factories[name]()
    return loaded[name]
end

-- Module: Capabilities.lua
factories["Capabilities"] = function()
local Catalog = require("Catalog")
local Util = require("Util")
local Capabilities = {}
Capabilities.__index = Capabilities

local function resolve(environment, path, expectedType)
    local value = environment
    for segment in path:gmatch("[^%.]+") do
        local ok, result = pcall(function() return value[segment] end)
        if not ok or result == nil then return nil end
        value = result
    end
    return type(value) == (expectedType or "function") and value or nil
end

function Capabilities.new(environment)
    local self = setmetatable({ entries = {}, environment = environment or {}, catalog = Catalog.version }, Capabilities)
    for _, item in ipairs(Catalog.functions) do
        local fn, alias = resolve(self.environment, item.name, item.type), item.name
        if not fn then
            for _, candidate in ipairs(item.aliases or {}) do
                fn = resolve(self.environment, candidate, item.type)
                if fn then alias = candidate; break end
            end
        end
        self.entries[item.name] = { name = item.name, group = item.group, standards = Util.copy(item.standards),
            alias = fn and alias or nil, status = fn and "detected" or "unavailable", fn = fn,
            message = fn and "Present; behavior not tested" or "Function not provided" }
    end
    return self
end

function Capabilities:Get(name)
    local entry = self.entries[name]
    return entry and entry.fn or nil
end

function Capabilities:Has(name) return self:Get(name) ~= nil end

function Capabilities:Report()
    local report = { catalog = self.catalog, executor = "unidentified", functions = {},
        targets = { Real = "not-tested", Delta = "not-tested" } }
    local identify = self:Get("identifyexecutor")
    if identify then
        local ok, name, version = pcall(identify)
        if ok then report.executor = tostring(name); report.executorVersion = tostring(version or "") end
    end
    for _, entry in pairs(self.entries) do
        local copy = {}
        for key, value in pairs(entry) do if key ~= "fn" then copy[key] = Util.copy(value) end end
        report.functions[#report.functions + 1] = copy
    end
    table.sort(report.functions, function(a, b) return a.name < b.name end)
    return report
end

-- Explicit, narrow test. Never hooks functions, changes game objects or runs an executor test suite.
function Capabilities:ProbeDrawing()
    local entry = self.entries["Drawing.new"]
    if not entry or not entry.fn then return false, "Drawing.new unavailable" end
    local objects = {}
    local ok, err = pcall(function()
        for _, kind in ipairs({ "Square", "Text" }) do
            local object = entry.fn(kind)
            objects[#objects + 1] = object
            object.Visible = false
            object.Position = Vector2.new(0, 0)
            if kind == "Square" then object.Size = Vector2.new(1, 1) else object.Text = "Lapo" end
        end
    end)
    for _, object in ipairs(objects) do
        local removed, removeError = pcall(function() object:Remove() end)
        if not removed then ok, err = false, removeError end
    end
    entry.status = ok and "validated" or "failed"
    entry.message = ok and "Square/Text creation, properties and removal validated; no full conformance claim" or tostring(err)
    return ok, entry.message
end

function Capabilities:Clipboard(text)
    local fn = self:Get("setclipboard")
    if not fn then return false, "Clipboard unavailable" end
    return pcall(fn, tostring(text))
end

function Capabilities:GetText(url)
    if type(url) ~= "string" or not url:match("^https://") then return false, "Expected an HTTPS URL" end
    local request = self:Get("request")
    if request then
        local ok, response = pcall(request, { Url = url, Method = "GET" })
        if not ok then return false, tostring(response) end
        if type(response) ~= "table" or type(response.Body) ~= "string" then return false, "Invalid HTTP response" end
        local code = tonumber(response.StatusCode)
        if not code or code < 200 or code >= 300 then return false, "HTTP " .. tostring(code) end
        return true, response.Body
    end
    return pcall(function() return game:HttpGet(url) end)
end

function Capabilities:Asset(path)
    if type(path) ~= "string" then return false, "Expected an asset path" end
    if path:match("^rbxassetid://%d+$") or path:match("^rbxasset://") then return true, path end
    local fn = self:Get("getcustomasset")
    if not fn then return false, "Local assets unavailable; use rbxassetid://" end
    return pcall(fn, path)
end

return Capabilities

end

-- Module: Catalog.lua
factories["Catalog"] = function()
-- Generated from compatibility.json; do not hand edit.
return { ["version"] = "2026-09-05", ["coverage"] = "UNC test entries + sUNC documented function index; presence is not conformance", ["sources"] = { { ["url"] = "https://github.com/unified-naming-convention/NamingStandard/blob/main/UNCCheckEnv.lua", ["sha256"] = "068447242986b338036a4a80288762ea20be51e6b2d6e4c14530a83e33cbb1a9" }, { ["url"] = "https://docs.sunc.io/", ["sha256"] = "5652ab54740a6f9ab5cca65e413e19fddfd1128421d54413e2e6f832595a1e01" } }, ["functions"] = { { ["name"] = "Drawing", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "table" }, { ["name"] = "Drawing.Fonts", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Drawing", ["type"] = "table" }, { ["name"] = "Drawing.new", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Drawing", ["type"] = "function" }, { ["name"] = "WebSocket", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "table" }, { ["name"] = "WebSocket.connect", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "WebSocket", ["type"] = "function" }, { ["name"] = "appendfile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "base64decode", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Encoding", ["type"] = "function" }, { ["name"] = "base64encode", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Encoding", ["type"] = "function" }, { ["name"] = "cache.invalidate", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "cache", ["type"] = "function" }, { ["name"] = "cache.iscached", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "cache", ["type"] = "function" }, { ["name"] = "cache.replace", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "cache", ["type"] = "function" }, { ["name"] = "checkcaller", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "cleardrawcache", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Drawing", ["type"] = "function" }, { ["name"] = "clonefunction", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "cloneref", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "compareinstances", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "crypt.base64decode", ["aliases"] = { "crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode" }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.base64encode", ["aliases"] = { "crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode" }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.decrypt", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.encrypt", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.generatebytes", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.generatekey", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "crypt.hash", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "crypt", ["type"] = "function" }, { ["name"] = "debug.getconstant", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getconstants", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getinfo", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "debug", ["type"] = "function" }, { ["name"] = "debug.getproto", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getprotos", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getstack", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getupvalue", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.getupvalues", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.setconstant", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.setstack", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "debug.setupvalue", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Debug", ["type"] = "function" }, { ["name"] = "delfile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "delfolder", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "dofile", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "filtergc", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Environment", ["type"] = "function" }, { ["name"] = "fireclickdetector", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "fireproximityprompt", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "firesignal", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Signals", ["type"] = "function" }, { ["name"] = "firetouchinterest", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "getcallbackvalue", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "getcallingscript", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getconnections", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Signals", ["type"] = "function" }, { ["name"] = "getcustomasset", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "getfunctionhash", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "getgc", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Environment", ["type"] = "function" }, { ["name"] = "getgenv", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Environment", ["type"] = "function" }, { ["name"] = "gethiddenproperty", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "gethui", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "getinstances", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "getloadedmodules", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getnamecallmethod", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Metatable", ["type"] = "function" }, { ["name"] = "getnilinstances", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Instances", ["type"] = "function" }, { ["name"] = "getrawmetatable", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Metatable", ["type"] = "function" }, { ["name"] = "getreg", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Environment", ["type"] = "function" }, { ["name"] = "getrenderproperty", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Drawing", ["type"] = "function" }, { ["name"] = "getrenv", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Environment", ["type"] = "function" }, { ["name"] = "getrunningscripts", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getscriptbytecode", ["aliases"] = { "dumpstring" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getscriptclosure", ["aliases"] = { "getscriptfunction" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getscriptfromthread", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getscripthash", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getscripts", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getsenv", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Scripts", ["type"] = "function" }, { ["name"] = "getthreadidentity", ["aliases"] = { "getidentity", "getthreadcontext" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "hookfunction", ["aliases"] = { "replaceclosure" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "hookmetamethod", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "identifyexecutor", ["aliases"] = { "getexecutorname" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "iscclosure", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "isexecutorclosure", ["aliases"] = { "checkclosure", "isourclosure" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "isfile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "isfolder", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "islclosure", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "isrbxactive", ["aliases"] = { "isgameactive" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "isreadonly", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Metatable", ["type"] = "function" }, { ["name"] = "isrenderobj", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Drawing", ["type"] = "function" }, { ["name"] = "isscriptable", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "listfiles", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "loadfile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "loadstring", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "lz4compress", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Encoding", ["type"] = "function" }, { ["name"] = "lz4decompress", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Encoding", ["type"] = "function" }, { ["name"] = "makefolder", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "messagebox", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse1click", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse1press", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse1release", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse2click", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse2press", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mouse2release", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mousemoveabs", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mousemoverel", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "mousescroll", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "newcclosure", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "queue_on_teleport", ["aliases"] = { "queueonteleport" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsoleclear", ["aliases"] = { "consoleclear" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsolecreate", ["aliases"] = { "consolecreate" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsoledestroy", ["aliases"] = { "consoledestroy" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsoleinput", ["aliases"] = { "consoleinput" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsoleprint", ["aliases"] = { "consoleprint" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "rconsolesettitle", ["aliases"] = { "rconsolename", "consolesettitle" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "readfile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" }, { ["name"] = "replicatesignal", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Signals", ["type"] = "function" }, { ["name"] = "request", ["aliases"] = { "http.request", "http_request" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "restorefunction", ["aliases"] = {  }, ["standards"] = { "sUNC" }, ["group"] = "Closures", ["type"] = "function" }, { ["name"] = "setclipboard", ["aliases"] = { "toclipboard" }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "setfpscap", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "sethiddenproperty", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "setrawmetatable", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Metatable", ["type"] = "function" }, { ["name"] = "setrbxclipboard", ["aliases"] = {  }, ["standards"] = { "UNC" }, ["group"] = "Miscellaneous", ["type"] = "function" }, { ["name"] = "setreadonly", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Metatable", ["type"] = "function" }, { ["name"] = "setrenderproperty", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Drawing", ["type"] = "function" }, { ["name"] = "setscriptable", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "setthreadidentity", ["aliases"] = { "setidentity", "setthreadcontext" }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Reflection", ["type"] = "function" }, { ["name"] = "writefile", ["aliases"] = {  }, ["standards"] = { "UNC", "sUNC" }, ["group"] = "Filesystem", ["type"] = "function" } } }

end

-- Module: Drawing.lua
factories["Drawing"] = function()
-- Optional hybrid backend: native layout/input + Drawing visuals.
-- Requires a writable ScreenGui parent even when Drawing is selected.
local Scope = require("Scope")
local DrawingRenderer = {}
DrawingRenderer.__index = DrawingRenderer

local masked = { BackgroundTransparency = true, TextTransparency = true,
    ImageTransparency = true, ScrollBarImageTransparency = true, Transparency = true }

function DrawingRenderer.new(native, capabilities)
    return setmetatable({ native = native, capabilities = capabilities, scope = Scope.new(), entries = {}, destroyed = false }, DrawingRenderer)
end

function DrawingRenderer:Set(object, property, value)
    local entry = self.entries[object]
    if entry and entry.opacity[property] ~= nil then
        entry.opacity[property] = value
        object[property] = 1
        return
    end
    object[property] = value
end

function DrawingRenderer:Track(object)
    if self.entries[object] or self.destroyed then return end
    if not object:IsA("GuiObject") and not object:IsA("UIStroke") then return end
    local entry = { object = object, opacity = {}, drawings = {}, scope = Scope.new() }
    self.entries[object] = entry
    local create = self.capabilities:Get("Drawing.new")
    local function drawing(kind)
        local item = create(kind)
        item.Visible = false
        entry.drawings[#entry.drawings + 1] = item
        return item
    end
    if object:IsA("UIStroke") then
        entry.border = drawing("Square"); entry.border.Filled = false
    else
        entry.background = drawing("Square"); entry.background.Filled = true
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            entry.text = drawing("Text")
            entry.text.Center = false
            local env = self.capabilities.environment
            local ok, font = pcall(function() return env.Drawing.Fonts.UI end)
            if ok and font then pcall(function() entry.text.Font = font end) end
        end
    end
    for property in pairs(masked) do
        local ok, value = pcall(function() return object[property] end)
        if ok and type(value) == "number" then
            entry.opacity[property] = value
            object[property] = 1
        end
    end
    entry.scope:Add(object.Destroying:Connect(function() self:Remove(object, false) end))
end

function DrawingRenderer:Remove(object, restore)
    local entry = self.entries[object]
    if not entry then return end
    self.entries[object] = nil
    entry.scope:Destroy()
    if restore then for property, value in pairs(entry.opacity) do pcall(function() object[property] = value end) end end
    for _, item in ipairs(entry.drawings) do pcall(function() item:Remove() end) end
end

local function geometry(object, screen)
    local node = object:IsA("UIStroke") and object.Parent or object
    if not node or not node:IsA("GuiObject") then return end
    local position, size = node.AbsolutePosition, node.AbsoluteSize
    local x, y, x2, y2 = position.X, position.Y, position.X + size.X, position.Y + size.Y
    local z, depth, parent = node.ZIndex, 0, node
    while parent and parent ~= screen do
        if parent:IsA("GuiObject") then
            if not parent.Visible then return end
            if parent.ClipsDescendants then
                local p, s = parent.AbsolutePosition, parent.AbsoluteSize
                x, y, x2, y2 = math.max(x, p.X), math.max(y, p.Y), math.min(x2, p.X + s.X), math.min(y2, p.Y + s.Y)
            end
            z = math.max(z, parent.ZIndex)
            depth = depth + 1
        end
        parent = parent.Parent
    end
    if not parent or not screen.Enabled or x2 <= x or y2 <= y then return end
    return node, x, y, x2, y2, z * 100 + depth * 2
end

function DrawingRenderer:Render()
    for object, entry in pairs(self.entries) do
        for _, item in ipairs(entry.drawings) do item.Visible = false end
        local node, x, y, x2, y2, z = geometry(object, self.native.screen)
        if node then
            if entry.background and entry.opacity.BackgroundTransparency < 1 then
                local bg = entry.background
                bg.Position, bg.Size = Vector2.new(x, y), Vector2.new(x2 - x, y2 - y)
                bg.Color, bg.Transparency, bg.ZIndex = node.BackgroundColor3, 1 - entry.opacity.BackgroundTransparency, z
                bg.Visible = true
            end
            if entry.border and entry.opacity.Transparency < 1 then
                local border = entry.border
                border.Position, border.Size = Vector2.new(x, y), Vector2.new(x2 - x, y2 - y)
                border.Color, border.Thickness = object.Color, object.Thickness
                border.Transparency, border.ZIndex, border.Visible = 1 - entry.opacity.Transparency, z + 1, true
            end
            if entry.text and entry.opacity.TextTransparency < 1 then
                local text, content = entry.text, node.Text
                local color = node.TextColor3
                if node:IsA("TextBox") and content == "" then content, color = node.PlaceholderText, node.PlaceholderColor3 end
                text.Text, text.Size, text.Color = content, node.TextSize, color
                local bounds = text.TextBounds
                local position, size = node.AbsolutePosition, node.AbsoluteSize
                local left, top = position.X, position.Y
                local padding = node:FindFirstChildOfClass("UIPadding")
                local padL, padR = 0, 0
                if padding then
                    padL = padding.PaddingLeft.Offset + padding.PaddingLeft.Scale * size.X
                    padR = padding.PaddingRight.Offset + padding.PaddingRight.Scale * size.X
                end
                if node.TextXAlignment == Enum.TextXAlignment.Center then left = left + (size.X - bounds.X) / 2
                elseif node.TextXAlignment == Enum.TextXAlignment.Right then left = left + size.X - bounds.X - padR
                else left = left + padL end
                if node.TextYAlignment == Enum.TextYAlignment.Center then top = top + (size.Y - bounds.Y) / 2
                elseif node.TextYAlignment == Enum.TextYAlignment.Bottom then top = top + size.Y - bounds.Y end
                -- Drawing has no portable scissor. Hide clipped text rather than spilling into another control.
                if left >= x - 1 and top >= y - 1 and left + bounds.X <= x2 + 1 and top + bounds.Y <= y2 + 1 then
                    text.Position = Vector2.new(left, top)
                    text.Transparency, text.ZIndex, text.Visible = 1 - entry.opacity.TextTransparency, z + 1, true
                end
            end
        end
    end
end

function DrawingRenderer:Mount()
    self.native.drawBridge = self
    for _, object in ipairs(self.native.screen:GetDescendants()) do self:Track(object) end
    self.scope:Add(self.native.screen.DescendantAdded:Connect(function(object)
        local ok, err = pcall(self.Track, self, object)
        if not ok then self:Fail(err) end
    end))
    self.scope:Add(game:GetService("RunService").RenderStepped:Connect(function()
        if self.destroyed then return end
        local ok, err = pcall(self.Render, self)
        if not ok then self:Fail(err) end
    end))
end

function DrawingRenderer:Fail(err)
    self:Destroy()
    self.native.drawing = nil
    self.native.owner:Notify({ title = "UI nativa restaurada", content = "Drawing falhou: " .. tostring(err) })
end

function DrawingRenderer:Destroy()
    if self.destroyed then return end
    self.destroyed = true; self.scope:Destroy()
    self.native.drawBridge = nil
    local objects = {}
    for object in pairs(self.entries) do objects[#objects + 1] = object end
    for _, object in ipairs(objects) do self:Remove(object, true) end
end

return DrawingRenderer

end

-- Module: Layout.lua
factories["Layout"] = function()
local Util = require("Util")
local Layout = {}

-- All coordinates are local to the safe-area root. Touch targets never use UIScale.
function Layout.window(width, height, options)
    options = options or {}
    local margin = 8
    local availableW, availableH = math.max(1, width - margin * 2), math.max(1, height - margin * 2)
    local compact = width < 600 or height < 400
    local w = math.min(availableW, options.width or (compact and 540 or 660))
    local h = math.min(availableH, options.height or 460)
    if width < 600 then w = availableW end
    local x = Util.clamp(options.x or (width - w) / 2, margin, math.max(margin, width - w - margin))
    local y = Util.clamp(options.y or (height - h) / 2, margin, math.max(margin, height - h - margin))
    return { x = x, y = y, width = w, height = h, compact = compact,
        sidebar = compact and 0 or 156, header = 48, footer = 32 }
end

function Layout.gesture(dx, dy, threshold)
    threshold = threshold or 10
    if math.max(math.abs(dx), math.abs(dy)) < threshold then return "pending" end
    return math.abs(dx) > math.abs(dy) and "horizontal" or "vertical"
end

function Layout.visible(y, height, offset, viewport, overscan)
    overscan = overscan or 100
    return y + height >= offset - overscan and y <= offset + viewport + overscan
end

return Layout

end

-- Module: Library.lua
factories["Library"] = function()
local Util = require("Util")
local Scope = require("Scope")
local Model = require("Model")
local Capabilities = require("Capabilities")
local Profiles = require("Profiles")
local Library = {}
Library.__index = Library
Library.Version = "2.0.0-beta.1"

local function environment()
    local base = getfenv and getfenv(0) or _G
    local custom = {}
    local ok, result = pcall(function() return getgenv() end)
    if ok and type(result) == "table" then custom = result end
    return setmetatable({}, { __index = function(_, key)
        if custom[key] ~= nil then return custom[key] end
        return base[key]
    end })
end

function Library.new(options)
    options = options or {}
    return setmetatable({ id = Util.id(options.Id or "lapo-x"), tabs = {}, tabById = {}, models = {},
        currentTab = nil, initialized = false, destroyed = false, visible = true, batch = 0,
        scope = Scope.new(), capabilities = Capabilities.new(options.Environment or environment()),
        userName = "Lapo X", userRank = "", loading = nil, loadQueue = {}, autoSaveGeneration = 0,
        config = {}, _nextIds = {}, hasDependencies = false }, Library)
end

function Library:New(options) return Library.new(options) end
function Library:CreateWindow(config)
    local window = Library.new(config)
    window:Init(config)
    return window
end

function Library:_assertAlive() assert(not self.destroyed, "Window destroyed; create a new window with :New()") end

function Library:_tab(tab)
    if type(tab) == "number" then return assert(self.tabs[tab], "Unknown tab index") end
    if type(tab) == "table" and tab._tab then return tab._tab end
    return assert(self.tabById[tab] or self:_findTabName(tab), "Unknown tab: " .. tostring(tab))
end

function Library:_findTabName(name)
    for _, tab in ipairs(self.tabs) do if tab.name == name then return tab end end
end

function Library:AddTab(name, icon)
    self:_assertAlive()
    local config = type(name) == "table" and name or { name = name, icon = icon }
    local id = Util.id(config.id or Util.slug(config.name or "tab"))
    assert(not self.tabById[id], "Duplicate tab ID: " .. id)
    local tab = { id = id, name = tostring(config.name or id), icon = config.icon, widgets = {}, scroll = 0 }
    self.tabs[#self.tabs + 1], self.tabById[id] = tab, tab
    self.currentTab = self.currentTab or id
    self:_refresh()
    return self
end

function Library:Tab(config)
    self:AddTab(config)
    local tab = self.tabs[#self.tabs]
    local facade = { _tab = tab, Id = tab.id }
    for _, kind in ipairs({ "Button", "Toggle", "Slider", "Dropdown", "TextBox", "Label", "Paragraph", "Separator",
        "Section", "NumberInput", "Keybind", "ColorPicker", "Progress" }) do
        facade[kind] = function(_, cfg) return self["Add" .. kind](self, tab.id, cfg) end
    end
    function facade:Select() return tab.owner:SelectTab(tab.id) end
    tab.owner = self
    return facade
end

function Library:SelectTab(tab)
    self:_assertAlive()
    self.currentTab = self:_tab(tab).id
    self:_refresh()
    return self
end

function Library:_add(kind, tabRef, config)
    self:_assertAlive()
    config = config or {}
    local tab = self:_tab(tabRef)
    local stem = Util.slug(config.text or kind)
    local key = tab.id .. "." .. stem
    self._nextIds[key] = (self._nextIds[key] or 0) + 1
    local localId = config.id or (stem .. "-" .. self._nextIds[key])
    local id = tab.id .. "." .. Util.id(localId)
    assert(not self.models[id], "Duplicate component ID: " .. id)
    if config.section then
        local section = self.models[tab.id .. "." .. config.section] or self.models[config.section]
        assert(section and section.kind == "Section" and section.tab == tab, "Unknown section in this tab")
        config = Util.copy(config); config.section = section.id
    end
    local model = Model.new(self, tab, kind, config, id)
    self.models[id], tab.widgets[#tab.widgets + 1] = model, model
    if config.dependsOn then self.hasDependencies = true end
    self.scope:Add(model.updated:Connect(function(reason)
        if reason == "layout" or reason == "destroy" then self:_refresh() end
    end))
    self:_refresh()
    return model
end

for _, kind in ipairs({ "Button", "Toggle", "Slider", "Dropdown", "TextBox", "Label", "Paragraph", "Separator",
    "Section", "NumberInput", "Keybind", "ColorPicker", "Progress" }) do
    Library["Add" .. kind] = function(self, tab, config) return self:_add(kind, tab, config) end
end

function Library:Get(id) return self.models[id] end

function Library:IsVisible(model)
    if not model.visible or model.destroyed then return false end
    if model.section then
        local section = self.models[model.section]
        if not section or not section.value or not section.visible then return false end
    end
    local dependency = model.config.dependsOn
    if dependency then
        local source = self.models[dependency.id] or self.models[model.tab.id .. "." .. dependency.id]
        if not source then return false end
        local expected = dependency.equals
        if expected == nil then expected = true end
        if not Util.equal(source.value, expected) then return false end
    end
    return true
end

function Library:_remove(model)
    self.models[model.id] = nil
    for i, entry in ipairs(model.tab.widgets) do if entry == model then table.remove(model.tab.widgets, i); break end end
    self:_refresh()
end

function Library:_changed(model)
    if self.hasDependencies or model.kind == "Section" then self:_refresh() end
    if self.config.AutoSave and self.profiles and model.persist then
        self.autoSaveGeneration = self.autoSaveGeneration + 1
        local generation = self.autoSaveGeneration
        self.scope:Delay(0.6, function()
            if generation == self.autoSaveGeneration then self:SaveProfile(self.config.Profile or "default") end
        end)
    end
end

function Library:_refresh()
    if self.renderer and self.batch == 0 and not self.destroyed then self.renderer:Refresh() end
end
function Library:BeginBatch() self:_assertAlive(); self.batch = self.batch + 1; return self end
function Library:EndBatch()
    self:_assertAlive(); self.batch = math.max(0, self.batch - 1)
    if self.batch == 0 then self:_refresh() end
    return self
end

function Library:Init(config)
    self:_assertAlive()
    if self.initialized then return self end
    config = config or {}
    self.config = config
    self.id = Util.id(config.Id or self.id)
    local Native = require("Native")
    local renderer = Native.new(self)
    self.renderer = renderer
    local ok, err = pcall(renderer.Mount, renderer, config)
    if not ok then renderer:Destroy(); self.renderer = nil; error("Lapo X initialization failed: " .. tostring(err), 2) end
    self.scope:Add(renderer)
    self.initialized = true
    self.profiles = Profiles.new(self, self.capabilities, game:GetService("HttpService"), config.ProfileFolder)
    if config.Renderer == "Drawing" then
        local supported, message = self.capabilities:ProbeDrawing()
        if supported then
            local DrawingRenderer = require("Drawing")
            local overlay = DrawingRenderer.new(renderer, self.capabilities)
            local attached, attachError = pcall(overlay.Mount, overlay)
            if attached then renderer.drawing = overlay; renderer.scope:Add(overlay)
            else overlay:Destroy(); self:Notify({ title = "Drawing indisponível", content = tostring(attachError) }) end
        else self:Notify({ title = "Usando UI nativa", content = message }) end
    elseif config.Renderer and config.Renderer ~= "Native" and config.Renderer ~= "Auto" then
        warn("[Lapo X] Unknown Renderer; using Native")
    end
    self:_refresh()
    if config.AutoLoad then
        local loaded, loadError = self:LoadProfile(config.Profile or "default")
        if not loaded then warn("[Lapo X] " .. tostring(loadError)) end
    end
    if self.loading then renderer:Loading(self.loading) end
    return self
end

function Library:ToggleVisibility()
    self:_assertAlive(); self.visible = not self.visible
    if self.renderer then self.renderer:SetVisible(self.visible) end
    return self
end
function Library:SetUser(name, rank)
    self.userName, self.userRank = tostring(name or ""), tostring(rank or "")
    if self.renderer then self.renderer:UpdateUser() end
    return self
end
function Library:SetUserCallback(callback) self.userCallback = callback; return self end
function Library:SetTheme(theme)
    self:_assertAlive()
    if self.renderer then self.renderer:SetTheme(theme) else self.config.Theme = theme end
    return self
end
function Library:Notify(config)
    if self.destroyed then return self end
    if self.renderer then self.renderer:Notify(config or {}) else warn("[Lapo X] " .. tostring((config or {}).content or "")) end
    return self
end
function Library:Dialog(config)
    self:_assertAlive(); assert(self.renderer, "Call Init before Dialog")
    return self.renderer:Dialog(config or {})
end
function Library:GetCapabilities() return self.capabilities:Report() end
function Library:GetCapability(name) return self.capabilities:Get(name) end
function Library:Copy(text) return self.capabilities:Clipboard(text) end
function Library:ExportProfile() assert(self.profiles, "Call Init first"); return self.profiles:Export() end
function Library:ImportProfile(data) assert(self.profiles, "Call Init first"); return self.profiles:Import(data) end
function Library:SaveProfile(name) assert(self.profiles, "Call Init first"); return self.profiles:Save(name) end
function Library:LoadProfile(name) assert(self.profiles, "Call Init first"); return self.profiles:Load(name) end

function Library:ShowLoading(config)
    self:_assertAlive(); config = config or {}
    self.loading = { title = config.Title or "Lapo X", message = config.Message or "Preparando interface…",
        subtitle = config.Subtitle or "", progress = 0, image = config.Image }
    if self.renderer then self.renderer:Loading(self.loading) end
    return self
end
function Library:SetLoadingProgress(progress, message)
    if self.destroyed or not self.loading then return self end
    assert(Util.finite(progress), "Progress must be finite")
    self.loading.progress = Util.clamp(progress, 0, 1)
    if message then self.loading.message = tostring(message) end
    if self.renderer then self.renderer:Loading(self.loading) end
    return self
end
function Library:SetLoadingMessage(message)
    return self:SetLoadingProgress(self.loading and self.loading.progress or 0, message)
end
function Library:QueueLoad(label, callback)
    self:_assertAlive(); assert(type(callback) == "function", "Load task must be a function")
    self.loadQueue[#self.loadQueue + 1] = { label = tostring(label), callback = callback }
    return self
end
function Library:RunLoadQueue(onComplete)
    self:_assertAlive()
    if self.runningQueue then return false, "Load queue already running" end
    self.runningQueue = true
    local queue = self.loadQueue; self.loadQueue = {}
    self.scope:Spawn(function()
        for index, entry in ipairs(queue) do
            if self.destroyed then return end
            self:SetLoadingMessage(entry.label)
            local ok, err = Util.call(entry.callback)
            if self.destroyed then return end
            if not ok then
                self.runningQueue = false
                self:SetLoadingMessage("Falha: " .. entry.label)
                Util.call(onComplete, false, err)
                return
            end
            self:SetLoadingProgress(index / #queue)
        end
        self.runningQueue = false
        self:FinishLoading(function() Util.call(onComplete, true) end)
    end)
    return true
end
function Library:FinishLoading(onComplete)
    if self.destroyed then return self end
    self.loading = nil
    if self.renderer then self.renderer:Loading(nil) end
    Util.call(onComplete)
    return self
end

function Library:GetStats()
    local count = 0
    for _ in pairs(self.models) do count = count + 1 end
    return { components = count, mounted = self.renderer and self.renderer:MountedCount() or 0,
        renderer = self.renderer and (self.renderer.drawing and "DrawingHybrid" or "Native") or "none",
        destroyed = self.destroyed, version = self.Version }
end

function Library:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    self.scope:Destroy()
    for _, model in pairs(self.models) do model.destroyed = true; model.changed:Destroy(); model.updated:Destroy() end
    self.models, self.tabs, self.tabById, self.loadQueue = {}, {}, {}, {}
    self.renderer, self.profiles, self.loading = nil, nil, nil
    self.initialized = false
end

return Library.new()

end

-- Module: Model.lua
factories["Model"] = function()
local Util = require("Util")
local Signal = require("Signal")
local Model = {}
Model.__index = Model

local valueKinds = { Toggle = true, Slider = true, Dropdown = true, TextBox = true,
    NumberInput = true, Keybind = true, ColorPicker = true, Progress = true, Section = true }

function Model.options(options)
    assert(Util.array(options), "options must be an array")
    local result, seen = {}, {}
    for _, option in ipairs(options) do
        local value = type(option) == "table" and option.value or option
        local label = type(option) == "table" and option.label or tostring(option)
        assert(type(value) == "string" or Util.finite(value), "Option values must be strings or finite numbers")
        assert(not seen[value], "Duplicate dropdown value: " .. tostring(value))
        seen[value] = true
        result[#result + 1] = { value = value, label = tostring(label or value) }
    end
    return result
end

function Model.new(owner, tab, kind, config, id)
    config = config or {}
    local self = setmetatable({ owner = owner, tab = tab, kind = kind, id = id,
        config = Util.copy(config), text = tostring(config.text or kind),
        description = tostring(config.description or ""), visible = config.visible ~= false,
        disabled = config.disabled == true, busy = false, destroyed = false,
        changed = Signal.new(), updated = Signal.new(), error = nil,
        persist = config.persist ~= false and valueKinds[kind] and kind ~= "Progress" }, Model)
    self.callback = config.callback
    self.section = config.section
    self.multiple = config.multiple == true
    self.options = kind == "Dropdown" and Model.options(config.options or {}) or {}
    self.min, self.max = config.min or 0, config.max or (kind == "Progress" and 1 or 100)
    self.step = config.step or (kind == "Progress" and 0.01 or 1)
    if kind == "Slider" or kind == "NumberInput" or kind == "Progress" then
        assert(Util.finite(self.min) and Util.finite(self.max) and self.min <= self.max, "Invalid numeric range")
        assert(Util.finite(self.step) and self.step > 0, "step must be positive")
    end
    local default = config.default
    if default == nil then
        if kind == "Toggle" then default = false
        elseif kind == "Section" then default = config.expanded ~= false
        elseif kind == "Slider" or kind == "NumberInput" or kind == "Progress" then default = self.min
        elseif kind == "Dropdown" then
            default = self.multiple and {} or (self.options[1] and self.options[1].value)
        elseif kind == "ColorPicker" then default = "#83C9AA"
        elseif kind == "Keybind" then default = "None"
        else default = "" end
    elseif kind == "Dropdown" and not self.multiple and type(default) == "number" and not config.valueDefault then
        -- v1 defaults are option indices; v2 numeric values opt in with valueDefault.
        assert(self.options[default], "Dropdown default index is out of range")
        default = self.options[default].value
    end
    local ok, normalized = self:Normalize(default)
    assert(ok, normalized)
    self.value = normalized
    return self
end

function Model:Normalize(value)
    local kind = self.kind
    if kind == "Toggle" or kind == "Section" then
        if type(value) ~= "boolean" then return false, "Expected a boolean" end
    elseif kind == "Slider" or kind == "NumberInput" or kind == "Progress" then
        if not Util.finite(value) then return false, "Expected a finite number" end
        value = Util.clamp(value, self.min, self.max)
        value = Util.clamp(self.min + math.floor((value - self.min) / self.step + 0.5) * self.step, self.min, self.max)
        value = tonumber(string.format("%.10g", value))
    elseif kind == "Dropdown" then
        local available = {}
        for _, option in ipairs(self.options) do available[option.value] = true end
        if self.multiple then
            if not Util.array(value) then return false, "Expected an array of option values" end
            local seen, normalized = {}, {}
            for _, item in ipairs(value) do
                if not available[item] then return false, "Unknown dropdown value: " .. tostring(item) end
                if not seen[item] then normalized[#normalized + 1], seen[item] = item, true end
            end
            value = normalized
        elseif value == nil and #self.options == 0 then return true, nil
        elseif not available[value] then return false, "Unknown dropdown value: " .. tostring(value) end
    elseif kind == "ColorPicker" then
        if type(value) ~= "string" or not value:match("^#%x%x%x%x%x%x$") then return false, "Use #RRGGBB" end
        value = value:upper()
    elseif kind == "Keybind" then
        if type(value) ~= "string" or not value:match("^[%w]+$") then return false, "Expected a key name" end
    else
        if type(value) ~= "string" then return false, "Expected text" end
    end
    if type(self.config.validate) == "function" then
        local ok, valid, message = pcall(self.config.validate, Util.copy(value))
        if not ok or valid == false then return false, tostring(message or (not ok and valid) or "Invalid value") end
    end
    return true, Util.copy(value)
end

function Model:Get() return Util.copy(self.value) end

function Model:Set(value, options)
    if self.destroyed then return false, "Component destroyed" end
    if self.kind == "Dropdown" and type(value) == "table" and not self.multiple then
        return self:SetOptions(value, options)
    end
    if self.kind == "Label" or self.kind == "Paragraph" or self.kind == "Button" then
        self.text = tostring(value)
        self.updated:Fire("layout")
        return true
    end
    local ok, result = self:Normalize(value)
    if not ok then self.error = result; self.updated:Fire("value"); return false, result end
    local hadError = self.error ~= nil
    self.error = nil
    if Util.equal(self.value, result) then
        if hadError then self.updated:Fire("value") end
        return true
    end
    self.value = result
    self.updated:Fire(self.kind == "Section" and "layout" or "value")
    self.owner:_changed(self)
    if not (options and options.silent) then
        self.changed:Fire(self:Get())
        if self.kind == "Dropdown" and not self.multiple then
            local index
            for i, option in ipairs(self.options) do if option.value == result then index = i; break end end
            Util.call(self.callback, index, result)
        else Util.call(self.callback, self:Get()) end
    end
    return true
end

function Model:SetIndex(index, options)
    if self.kind ~= "Dropdown" or self.multiple or not self.options[index] then return false, "Invalid option index" end
    return self:Set(self.options[index].value, options)
end

function Model:SetOptions(options, settings)
    if self.kind ~= "Dropdown" or self.destroyed then return false, "Not an active dropdown" end
    local ok, result = pcall(Model.options, options)
    if not ok then return false, result end
    self.options = result
    local valid = {}
    for _, option in ipairs(result) do valid[option.value] = true end
    local nextValue
    if self.multiple then
        nextValue = {}
        for _, v in ipairs(self.value) do if valid[v] then nextValue[#nextValue + 1] = v end end
    else nextValue = valid[self.value] and self.value or (result[1] and result[1].value) end
    self:Set(nextValue, settings)
    self.updated:Fire("options")
    return true
end

function Model:OnChanged(callback) return self.changed:Connect(callback) end
function Model:SetVisible(visible)
    if self.destroyed then return false end
    self.visible = visible == true; self.updated:Fire("layout"); return true
end
function Model:SetDisabled(disabled)
    if self.destroyed then return false end
    self.disabled = disabled == true; self.updated:Fire("value"); return true
end
function Model:SetText(text)
    if self.destroyed then return false end
    self.text = tostring(text); self.updated:Fire("layout"); return true
end
Model.updateText = Model.SetText

function Model:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    self.updated:Fire("destroy")
    self.changed:Destroy(); self.updated:Destroy()
    self.owner:_remove(self)
end

return Model

end

-- Module: Native.lua
factories["Native"] = function()
local Scope = require("Scope")
local Util = require("Util")
local Theme = require("Theme")
local Layout = require("Layout")
local Pointer = require("Pointer")
local Widgets = require("NativeWidgets")
local Popups = require("NativePopups")
local Native = {}
Native.__index = Native

function Native.new(owner)
    return setmetatable({ owner = owner, scope = Scope.new(), views = {}, theme = Theme.resolve(),
        bindings = setmetatable({}, { __mode = "k" }), focusables = setmetatable({}, { __mode = "k" }),
        focusSerial = 0, navOpen = false, popup = nil, notifications = {}, destroyed = false }, Native)
end

function Native:Color(object, property, token)
    local binding = self.bindings[object] or {}
    binding[property] = token; self.bindings[object] = binding
    object[property] = self.theme[token]
end

function Native:Set(object, property, value)
    if self.drawBridge then self.drawBridge:Set(object, property, value)
    else object[property] = value end
end

function Native:Make(class, props, parent)
    local object = Instance.new(class)
    if object:IsA("GuiObject") then
        object.BorderSizePixel = 0
        object.BackgroundTransparency = 1
    end
    if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
        object.Font = Enum.Font.Gotham
        object.TextSize = 14
        object.Text = ""
        object.TextXAlignment = Enum.TextXAlignment.Left
        self:Color(object, "TextColor3", "Text")
    end
    for property, value in pairs(props or {}) do
        if type(value) == "string" and value:sub(1, 1) == "$" and self.theme[value:sub(2)] then
            self:Color(object, property, value:sub(2))
        else object[property] = value end
    end
    object.Parent = parent
    return object
end

function Native:Round(object, radius)
    return self:Make("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, object)
end

function Native:Button(parent, label, props, callback, scope)
    props = props or {}; scope = scope or self.scope
    props.Text, props.AutoButtonColor, props.Selectable, props.Active = label, false, true, true
    local button = self:Make("TextButton", props, parent)
    local stroke = self:Make("UIStroke", { Color = "$Focus", Thickness = 1, Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
    self.focusSerial = self.focusSerial + 1
    self.focusables[button] = self.focusSerial
    scope:Add(button.SelectionGained:Connect(function() self:Set(stroke, "Transparency", 0) end))
    scope:Add(button.SelectionLost:Connect(function() self:Set(stroke, "Transparency", 1) end))
    if callback then
        -- Match one pointer and cancel activation after scrolling, even if release is inside the button.
        local press
        scope:Add(button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not press then press = { input = input, start = input.Position, moved = false } end
            end
        end))
        scope:Add(self.uis.InputChanged:Connect(function(input)
            if press and (input == press.input or (press.input.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseMovement)) then
                local delta = input.Position - press.start
                if math.max(math.abs(delta.X), math.abs(delta.Y)) > 10 then press.moved = true end
            end
        end))
        scope:Add(button.Activated:Connect(function(input)
            local pointerInput = input and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)
            if pointerInput and (not press or press.input ~= input or press.moved) then return end
            press = nil
            Util.call(callback)
        end))
        scope:Add(self.uis.InputEnded:Connect(function(input)
            if press and press.input == input then
                local ending = press
                scope:Spawn(function() if press == ending then press = nil end end)
            end
        end))
        scope:Add(self.uis.WindowFocusReleased:Connect(function() press = nil end))
    end
    return button
end

function Native:Mount(config)
    self.config = config
    self.theme = Theme.resolve(config.Theme)
    self.uis = game:GetService("UserInputService")
    self.guiService = game:GetService("GuiService")
    self.textService = game:GetService("TextService")
    self.pointer = Pointer.new(self.uis, self.scope)
    local parent = config.Parent
    local candidates = {}
    if parent then candidates[#candidates + 1] = parent end
    local gethui = self.owner.capabilities:Get("gethui")
    if not parent and gethui then
        local ok, candidate = pcall(gethui)
        if ok and candidate then candidates[#candidates + 1] = candidate end
    end
    if not parent then
        local player = game:GetService("Players").LocalPlayer
        if player then
            local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
            if pg then candidates[#candidates + 1] = pg end
        end
        local ok, core = pcall(function() return game:GetService("CoreGui") end)
        if ok then candidates[#candidates + 1] = core end
    end
    local screen = self.scope:Add(self:Make("ScreenGui", { Name = "LapoX_" .. self.owner.id,
        ResetOnSpawn = false, DisplayOrder = config.DisplayOrder or 50,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling }))
    pcall(function() screen.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets end)
    pcall(function() screen.ClipToDeviceSafeArea = true end)
    for _, candidate in ipairs(candidates) do
        local ok = pcall(function() screen.Parent = candidate end)
        if ok and screen.Parent then break end
    end
    assert(screen.Parent, "No writable GUI parent; supply Init({ Parent = yourPlayerGui })")
    self.screen = screen
    self.root = self:Make("Frame", { Name = "SafeArea", Size = UDim2.fromScale(1, 1) }, screen)
    self.window = self:Make("Frame", { Name = "Window", BackgroundTransparency = 0, BackgroundColor3 = "$Background",
        Active = true, ClipsDescendants = true }, self.root)
    self:Round(self.window, 10)
    self:Make("UIStroke", { Color = "$Border", Thickness = 1 }, self.window)
    self.header = self:Make("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = "$Panel", BackgroundTransparency = 0, Active = true }, self.window)
    self.menu = self:Button(self.header, "≡", { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(2, 2),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 24 }, function()
        self.navOpen = not self.navOpen; self:Position()
    end)
    self.title = self:Make("TextLabel", { Text = config.Title or "Lapo X", TextSize = 15, Font = Enum.Font.GothamMedium,
        Position = UDim2.fromOffset(48, 0), Size = UDim2.new(1, -140, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd }, self.header)
    self.minimize = self:Button(self.header, "−", { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -90, 0, 2),
        TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center }, function()
        self.minimized = not self.minimized; self:ClosePopup(); self.pointer:Cancel(); self:Position()
    end)
    self.close = self:Button(self.header, "×", { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -46, 0, 2),
        TextSize = 23, TextXAlignment = Enum.TextXAlignment.Center }, function() self.owner:ToggleVisibility() end)
    self.content = self:Make("ScrollingFrame", { Name = "Content", CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Border", ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true, Active = true, ZIndex = 1 }, self.window)
    self.empty = self:Make("TextLabel", { Text = "Adicione uma aba para começar.", TextColor3 = "$Muted",
        TextWrapped = true, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center }, self.content)
    self.drawerBlock = self:Button(self.window, "", { BackgroundTransparency = 0.45, BackgroundColor3 = "$Background",
        ZIndex = 4, Visible = false }, function() self.navOpen = false; self:Position() end)
    self.sidebar = self:Make("ScrollingFrame", { Name = "Tabs", BackgroundTransparency = 0, BackgroundColor3 = "$Panel",
        ScrollBarThickness = 2, CanvasSize = UDim2.fromOffset(0, 0), ClipsDescendants = true, ZIndex = 5 }, self.window)
    self.footer = self:Button(self.window, "", { TextColor3 = "$Muted", TextSize = 12,
        Position = UDim2.new(0, 14, 1, -32), Size = UDim2.new(1, -52, 0, 32), TextTruncate = Enum.TextTruncate.AtEnd }, function()
        Util.call(self.owner.userCallback, self.owner.userName, self.owner.userRank)
    end)
    self.reopen = self:Button(self.root, "LX", { Name = "Reopen", AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -10, 1, -10), Size = UDim2.fromOffset(48, 48), BackgroundTransparency = 0,
        BackgroundColor3 = "$Accent", TextColor3 = "$OnAccent", Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center, Visible = false, ZIndex = 10 }, function() self.owner:ToggleVisibility() end)
    self:Round(self.reopen, 12)
    self.resize = self:Button(self.window, "⌟", { Size = UDim2.fromOffset(32, 32), Position = UDim2.new(1, -32, 1, -32),
        TextColor3 = "$Muted", TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center })
    self.toastRoot = self:Make("Frame", { Size = UDim2.new(1, -16, 0, 0), Position = UDim2.fromOffset(8, 8), ZIndex = 30 }, self.root)
    self.scope:Add(self.header.InputBegan:Connect(function(input)
        if not self.geometry or self.geometry.compact then return end
        local localX = input.Position.X - self.header.AbsolutePosition.X
        if localX < 48 or localX > self.header.AbsoluteSize.X - 92 then return end
        local x, y = self.geometry.x, self.geometry.y
        self.pointer:Start(input, function(_, delta)
            self.windowX, self.windowY = x + delta.X, y + delta.Y; self:Position()
        end)
    end))
    self.scope:Add(self.resize.InputBegan:Connect(function(input)
        if not self.geometry or self.geometry.compact then return end
        local w, h = self.geometry.width, self.geometry.height
        self.pointer:Start(input, function(_, delta)
            self.windowWidth, self.windowHeight = math.max(420, w + delta.X), math.max(260, h + delta.Y)
            self:Position(); self:RenderRows()
        end)
    end))
    self.scope:Add(self.root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        self.pointer:Cancel(); self:ClosePopup(); self:Refresh()
    end))
    self.scope:Add(self.content:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local tab = self.owner.tabById[self.owner.currentTab]
        if tab then tab.scroll = self.content.CanvasPosition.Y end
        self:RenderRows()
    end))
    for _, property in ipairs({ "OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize" }) do
        pcall(function() self.scope:Add(self.uis:GetPropertyChangedSignal(property):Connect(function()
            self:Position(); self:RenderRows(); self:PositionPopup()
        end)) end)
    end
    self.scope:Add(self.uis.InputBegan:Connect(function(input, processed)
        if self.captureKey then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local model = self.captureKey; self.captureKey = nil
                if input.KeyCode ~= Enum.KeyCode.Escape then model:Set(input.KeyCode.Name) end
                model.updated:Fire("value")
            end
            return
        end
        if self.uis:GetFocusedTextBox() then return end
        if input.KeyCode == Enum.KeyCode.Escape and self.popup then self:ClosePopup(); return end
        if input.KeyCode.Name == (self.config.ToggleKey or "End") and not processed then self.owner:ToggleVisibility(); return end
        if not self.owner.visible then return end
        if input.KeyCode == Enum.KeyCode.Tab then self:FocusNext(self.uis:IsKeyDown(Enum.KeyCode.LeftShift)); return end
        if not processed and not self.popup then
            for _, model in pairs(self.owner.models) do
                if model.kind == "Keybind" and model.value == input.KeyCode.Name and not model.disabled and self.owner:IsVisible(model) then
                    self.owner.scope:Spawn(function() if not model.destroyed then Util.call(model.config.onPressed, model.value) end end)
                end
            end
        end
    end))
    self:UpdateUser(); self:Position()
end

function Native:FocusNext(reverse)
    local entries = {}
    for object, serial in pairs(self.focusables) do
        local parent, visible = object, object.Parent ~= nil and object.Active and object.Selectable
        while parent and parent ~= self.screen do
            if parent:IsA("GuiObject") and not parent.Visible then visible = false; break end
            parent = parent.Parent
        end
        if self.popup and not object:IsDescendantOf(self.popup.panel) then visible = false end
        if visible then entries[#entries + 1] = { object = object, serial = serial } end
    end
    table.sort(entries, function(a, b)
        if math.abs(a.object.AbsolutePosition.Y - b.object.AbsolutePosition.Y) > 2 then
            return a.object.AbsolutePosition.Y < b.object.AbsolutePosition.Y
        end
        if a.object.AbsolutePosition.X ~= b.object.AbsolutePosition.X then return a.object.AbsolutePosition.X < b.object.AbsolutePosition.X end
        return a.serial < b.serial
    end)
    if #entries == 0 then return end
    local index = reverse and 1 or 0
    for i, entry in ipairs(entries) do if entry.object == self.guiService.SelectedObject then index = i end end
    index = ((index - 1 + (reverse and -1 or 1)) % #entries) + 1
    self.guiService.SelectedObject = entries[index].object
end

function Native:Position()
    if self.destroyed then return end
    local size = self.root.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then return end
    local height = size.Y
    pcall(function()
        if self.uis.OnScreenKeyboardVisible then
            height = math.min(height, math.max(100, self.uis.OnScreenKeyboardPosition.Y - self.root.AbsolutePosition.Y))
        end
    end)
    local geometry = Layout.window(size.X, height, { width = self.windowWidth, height = self.windowHeight,
        x = self.windowX, y = self.windowY })
    self.geometry = geometry
    self.window.Position = UDim2.fromOffset(geometry.x, geometry.y)
    self.window.Size = UDim2.fromOffset(geometry.width, self.minimized and geometry.header or geometry.height)
    self.menu.Visible = geometry.compact
    self.title.Position = UDim2.fromOffset(geometry.compact and 48 or 16, 0)
    self.title.Size = UDim2.new(1, geometry.compact and -140 or -110, 1, 0)
    self.content.Position = UDim2.fromOffset(geometry.sidebar + 12, 56)
    self.content.Size = UDim2.new(1, -geometry.sidebar - 24, 1, -96)
    self.content.Visible, self.footer.Visible = not self.minimized, not self.minimized
    self.resize.Visible = not geometry.compact and not self.minimized
    self.sidebar.Position = UDim2.fromOffset(0, 48)
    self.sidebar.Size = UDim2.new(0, math.min(156, geometry.width), 1, -80)
    self.sidebar.Visible = not self.minimized and (not geometry.compact or self.navOpen)
    self.drawerBlock.Visible = geometry.compact and self.navOpen and not self.minimized
    self.drawerBlock.Position, self.drawerBlock.Size = UDim2.fromOffset(0, 48), UDim2.new(1, 0, 1, -48)
    self.reopen.Position = UDim2.fromOffset(size.X - 10, height - 10)
end

function Native:BuildTabs()
    local signature = tostring(self.owner.currentTab) .. ":" .. #self.owner.tabs
    if self.tabSignature == signature then return end
    self.tabSignature = signature
    if self.tabsScope then self.tabsScope:Destroy() end
    self.tabsScope = Scope.new()
    for index, tab in ipairs(self.owner.tabs) do
        local selected = tab.id == self.owner.currentTab
        local button = self:Button(self.sidebar, tab.name, { Name = tab.id, Position = UDim2.fromOffset(8, 8 + (index - 1) * 48),
            Size = UDim2.new(1, -16, 0, 44), TextSize = 13, BackgroundTransparency = selected and 0 or 1,
            BackgroundColor3 = "$Surface", TextColor3 = selected and "$Accent" or "$Muted", TextTruncate = Enum.TextTruncate.AtEnd },
            function() self.navOpen = false; self:ClosePopup(); self.owner:SelectTab(tab.id) end, self.tabsScope)
        self.tabsScope:Add(button); self:Round(button, 6)
        self:Make("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 8) }, button)
    end
    self.sidebar.CanvasSize = UDim2.fromOffset(0, #self.owner.tabs * 48 + 16)
end

function Native:Height(model, width)
    local base = ({ Button = 44, Toggle = 48, Slider = 82, Dropdown = 72, TextBox = 76,
        NumberInput = 76, Keybind = 48, ColorPicker = 48, Progress = 58, Section = 40, Separator = 16, Label = 30 })[model.kind] or 48
    if model.kind == "Paragraph" or model.kind == "Label" then
        local measured = self.textService:GetTextSize(model.text, 14, Enum.Font.Gotham, Vector2.new(math.max(20, width - 24), 100000))
        base = math.max(base, measured.Y + 20)
    end
    if model.description ~= "" and model.kind ~= "Paragraph" then base = base + 20 end
    if model.error then base = base + 20 end
    return base
end

function Native:RenderRows()
    if self.destroyed or not self.geometry or self.rendering then return end
    self.rendering = true
    local tab = self.owner.tabById[self.owner.currentTab]
    local width, viewport = math.max(1, self.geometry.width - self.geometry.sidebar - 24), math.max(1, self.geometry.height - 96)
    local offset = self.content.CanvasPosition.Y
    local required, y, visibleCount = {}, 0, 0
    if tab then
        for _, model in ipairs(tab.widgets) do
            if self.owner:IsVisible(model) then
                visibleCount = visibleCount + 1
                local h = self:Height(model, width)
                if Layout.visible(y, h, offset, viewport) and self.owner.visible and not self.minimized then
                    required[model.id] = true
                    local view = self.views[model.id]
                    if not view then view = Widgets.mount(self, model); self.views[model.id] = view end
                    view.root.Position, view.root.Size = UDim2.fromOffset(0, y), UDim2.new(1, -5, 0, h)
                end
                y = y + h + 6
            end
        end
    end
    for id, view in pairs(self.views) do
        if not required[id] then view.scope:Destroy(); self.views[id] = nil end
    end
    self.content.CanvasSize = UDim2.fromOffset(0, math.max(0, y - 6))
    self.empty.Visible = visibleCount == 0
    self.empty.Text = tab and "Nenhuma opção nesta aba." or "Adicione uma aba para começar."
    self.rendering = false
end

function Native:Refresh()
    if self.destroyed or self.scheduled then return end
    self.scheduled = true
    self.scope:Spawn(function()
        self.scheduled = false
        self:Position(); self:BuildTabs()
        if self.renderedTab ~= self.owner.currentTab then
            self:ClosePopup(); self.pointer:Cancel()
            for id, view in pairs(self.views) do view.scope:Destroy(); self.views[id] = nil end
            self.renderedTab = self.owner.currentTab
            local tab = self.owner.tabById[self.owner.currentTab]
            self.content.CanvasPosition = Vector2.new(0, tab and tab.scroll or 0)
        end
        self:RenderRows()
    end)
end

function Native:UpdateUser()
    self.footer.Text = self.owner.userName .. (self.owner.userRank ~= "" and "  /  " .. self.owner.userRank or "")
end
function Native:SetVisible(visible)
    self:ClosePopup(); self.pointer:Cancel(); self.captureKey = nil
    local focused = self.uis:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(self.root) then focused:ReleaseFocus() end
    self.window.Visible, self.reopen.Visible = visible, not visible
    self:RenderRows()
end
function Native:SetTheme(overrides)
    self.theme = Theme.resolve(overrides)
    for object, bindings in pairs(self.bindings) do
        if object.Parent then for property, token in pairs(bindings) do object[property] = self.theme[token] end end
    end
end
function Native:MountedCount() local count = 0; for _ in pairs(self.views) do count = count + 1 end; return count end
function Native:Destroy()
    if self.destroyed then return end
    self.destroyed = true; self:ClosePopup()
    if self.loader then self.loader.scope:Destroy(); self.loader = nil end
    for _, toast in ipairs(self.notifications) do toast.scope:Destroy() end
    self.notifications = {}
    if self.tabsScope then self.tabsScope:Destroy() end
    for _, view in pairs(self.views) do view.scope:Destroy() end
    self.views = {}; self.scope:Destroy()
end

Native.ClosePopup = Popups.close
Native.PositionPopup = Popups.position
Native.Dropdown = Popups.dropdown
Native.ColorPicker = Popups.color
Native.Dialog = Popups.dialog
Native.Notify = Popups.notify
Native.Loading = Popups.loading

return Native

end

-- Module: NativePopups.lua
factories["NativePopups"] = function()
local Scope = require("Scope")
local Util = require("Util")
local Theme = require("Theme")
local Popups = {}

local function open(r, title, height)
    r:ClosePopup(); r.pointer:Cancel()
    local scope = Scope.new()
    local backdrop = scope:Add(r:Button(r.root, "", { Name = "ModalBackdrop", Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 0.25, BackgroundColor3 = "$Background", ZIndex = 20 }, function() r:ClosePopup() end, scope))
    local panel = r:Make("Frame", { Name = "Modal", BackgroundTransparency = 0, BackgroundColor3 = "$Panel",
        Active = true, ClipsDescendants = true, ZIndex = 21 }, backdrop)
    r:Round(panel, 10)
    r:Make("UIStroke", { Color = "$Border", Thickness = 1 }, panel)
    r:Make("TextLabel", { Text = title, Font = Enum.Font.GothamMedium, TextSize = 15,
        Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -64, 0, 48), TextTruncate = Enum.TextTruncate.AtEnd }, panel)
    local close = r:Button(panel, "×", { Position = UDim2.new(1, -48, 0, 0), Size = UDim2.fromOffset(48, 48),
        TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center }, function() r:ClosePopup() end, scope)
    local popup = { scope = scope, backdrop = backdrop, panel = panel, height = height,
        previousFocus = r.guiService.SelectedObject }
    r.popup = popup
    r:PositionPopup()
    r.guiService.SelectedObject = close
    return popup
end

function Popups.close(r)
    local popup = r.popup
    if not popup then return end
    r.popup = nil
    local focused = r.uis and r.uis:GetFocusedTextBox()
    if focused and focused:IsDescendantOf(popup.panel) then focused:ReleaseFocus() end
    popup.scope:Destroy()
    if popup.previousFocus and popup.previousFocus.Parent then r.guiService.SelectedObject = popup.previousFocus
    elseif r.guiService then r.guiService.SelectedObject = nil end
end

function Popups.position(r)
    if not r.popup then return end
    local size = r.root.AbsoluteSize
    local height = size.Y
    pcall(function()
        if r.uis.OnScreenKeyboardVisible then height = math.min(height, r.uis.OnScreenKeyboardPosition.Y - r.root.AbsolutePosition.Y) end
    end)
    local w, h = math.min(420, math.max(1, size.X - 16)), math.min(r.popup.height, math.max(96, height - 16))
    r.popup.panel.Size = UDim2.fromOffset(w, h)
    r.popup.panel.Position = UDim2.fromOffset((size.X - w) / 2, size.X < 600 and math.max(8, height - h - 8) or math.max(8, (height - h) / 2))
end

local function footer(r, popup, text, callback)
    local button = r:Button(popup.panel, text, { Position = UDim2.new(0, 12, 1, -56), Size = UDim2.new(1, -24, 0, 44),
        TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0, BackgroundColor3 = "$Accent",
        TextColor3 = "$OnAccent", Font = Enum.Font.GothamMedium }, callback, popup.scope)
    r:Round(button, 6)
    return button
end

function Popups.dropdown(r, model)
    if model.destroyed or model.disabled then return end
    local popup = open(r, model.text, 416)
    popup.model = model
    local searchable = model.config.search ~= false
    local search = r:Make("TextBox", { PlaceholderText = "Buscar opção…", PlaceholderColor3 = "$Muted", Text = "",
        ClearTextOnFocus = false, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 0, 44),
        BackgroundTransparency = 0, BackgroundColor3 = "$Surface", Visible = searchable }, popup.panel)
    r:Round(search, 6)
    r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)
    local top = searchable and 100 or 48
    local list = r:Make("ScrollingFrame", { Name = "Options", Position = UDim2.fromOffset(12, top),
        Size = UDim2.new(1, -24, 1, -top - 64), CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true, Active = true }, popup.panel)
    local empty = r:Make("TextLabel", { Text = "Nenhum resultado", TextColor3 = "$Muted", Size = UDim2.new(1, 0, 0, 44) }, list)
    local filtered, slots = {}, {}
    local function selected(value)
        if not model.multiple then return model.value == value end
        for _, item in ipairs(model.value) do if item == value then return true end end
        return false
    end
    local function draw()
        if r.popup ~= popup then return end
        local start = math.max(1, math.floor(list.CanvasPosition.Y / 44) + 1)
        local count = math.min(12, math.ceil(math.max(44, list.AbsoluteSize.Y) / 44) + 1)
        for index = 1, count do
            local slot = slots[index]
            if not slot then
                slot = {}; slots[index] = slot
                slot.button = r:Button(list, "", { Size = UDim2.new(1, -5, 0, 44), TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundColor3 = "$Surface" }, function()
                    local option = slot.option
                    if not option or model.destroyed or model.disabled then return end
                    if model.multiple then
                        local values = model:Get()
                        if selected(option.value) then
                            for i, value in ipairs(values) do if value == option.value then table.remove(values, i); break end end
                        else values[#values + 1] = option.value end
                        model:Set(values)
                        draw()
                    else model:Set(option.value); r:ClosePopup() end
                end, popup.scope)
                r:Round(slot.button, 5)
                r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, slot.button)
            end
            local itemIndex = start + index - 1
            slot.option = filtered[itemIndex]
            slot.button.Visible = slot.option ~= nil
            if slot.option then
                local active = selected(slot.option.value)
                slot.button.Position = UDim2.fromOffset(0, (itemIndex - 1) * 44)
                slot.button.Text = (active and "✓  " or "    ") .. slot.option.label
                r:Set(slot.button, "BackgroundTransparency", active and 0 or 1)
                r:Color(slot.button, "TextColor3", active and "Accent" or "Text")
            end
        end
        for index = count + 1, #slots do slots[index].button.Visible = false end
    end
    local function filter()
        filtered = {}
        local query = search.Text:lower()
        for _, option in ipairs(model.options) do
            if query == "" or option.label:lower():find(query, 1, true) then filtered[#filtered + 1] = option end
        end
        list.CanvasPosition, list.CanvasSize = Vector2.new(0, 0), UDim2.fromOffset(0, #filtered * 44)
        empty.Visible = #filtered == 0
        draw()
    end
    popup.scope:Add(search:GetPropertyChangedSignal("Text"):Connect(filter))
    popup.scope:Add(list:GetPropertyChangedSignal("CanvasPosition"):Connect(draw))
    popup.scope:Add(list:GetPropertyChangedSignal("AbsoluteSize"):Connect(draw))
    popup.scope:Add(model.updated:Connect(function(reason)
        if reason == "destroy" then r:ClosePopup()
        elseif reason == "options" then filter() else draw() end
    end))
    footer(r, popup, model.multiple and "Concluir seleção" or "Fechar", function() r:ClosePopup() end)
    filter()
end

function Popups.dialog(r, config)
    local popup = open(r, config.title or "Confirmar", 300)
    local content = r:Make("ScrollingFrame", { Position = UDim2.fromOffset(16, 52), Size = UDim2.new(1, -32, 1, -120),
        CanvasSize = UDim2.fromOffset(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y }, popup.panel)
    local message = r:Make("TextLabel", { Text = tostring(config.content or ""), TextWrapped = true,
        TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = "$Muted", Size = UDim2.new(1, -4, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y }, content)
    local confirm
    confirm = footer(r, popup, config.confirmText or "Confirmar", function()
        if popup.busy then return end
        popup.busy = true; confirm.Text = "Aguarde…"
        r.owner.scope:Spawn(function()
            local ok, err = Util.call(config.callback or config.onConfirm)
            if r.popup ~= popup then return end
            if ok then r:ClosePopup()
            else message.Text = tostring(err); popup.busy = false; confirm.Text = config.confirmText or "Tentar novamente" end
        end)
    end)
    return { Close = function() if r.popup == popup then r:ClosePopup() end end }
end

function Popups.color(r, model)
    local popup = open(r, model.text, 316)
    popup.model = model
    local body = r:Make("ScrollingFrame", { Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 1, -112),
        CanvasSize = UDim2.fromOffset(0, 170), ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y }, popup.panel)
    local swatch = r:Make("Frame", { BackgroundTransparency = 0, BackgroundColor3 = Theme.color(model.value),
        Size = UDim2.new(1, -4, 0, 34) }, body)
    r:Round(swatch, 6)
    local hex = r:Make("TextBox", { Text = model.value, ClearTextOnFocus = false,
        Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, -4, 0, 44), BackgroundTransparency = 0,
        BackgroundColor3 = "$Surface", TextXAlignment = Enum.TextXAlignment.Center }, body)
    r:Round(hex, 6)
    local channels = {}
    for index, label in ipairs({ "R", "G", "B" }) do
        local field = r:Make("TextBox", { Text = tostring(tonumber(model.value:sub(index * 2, index * 2 + 1), 16)),
            PlaceholderText = label, ClearTextOnFocus = false, Position = UDim2.new((index - 1) / 3, 0, 0, 100),
            Size = UDim2.new(1 / 3, -8, 0, 44), BackgroundTransparency = 0, BackgroundColor3 = "$Surface",
            TextXAlignment = Enum.TextXAlignment.Center }, body)
        r:Round(field, 6); channels[index] = field
    end
    local errorText = r:Make("TextLabel", { TextSize = 12, TextColor3 = "$Danger", Position = UDim2.fromOffset(0, 146),
        Size = UDim2.new(1, 0, 0, 24) }, body)
    local function syncHex()
        local ok = hex.Text:match("^#%x%x%x%x%x%x$")
        errorText.Text = ok and "" or "Use uma cor no formato #RRGGBB."
        if ok then
            swatch.BackgroundColor3 = Theme.color(hex.Text)
            for index, field in ipairs(channels) do field.Text = tostring(tonumber(hex.Text:sub(index * 2, index * 2 + 1), 16)) end
        end
        return ok
    end
    popup.scope:Add(hex.FocusLost:Connect(syncHex))
    for _, field in ipairs(channels) do
        popup.scope:Add(field.FocusLost:Connect(function()
            local values = {}
            for index, channel in ipairs(channels) do
                local value = tonumber(channel.Text)
                if not Util.finite(value) or value < 0 or value > 255 or value % 1 ~= 0 then
                    errorText.Text = "RGB deve conter inteiros entre 0 e 255."; return
                end
                values[index] = value
            end
            hex.Text = string.format("#%02X%02X%02X", values[1], values[2], values[3]); syncHex()
        end))
    end
    footer(r, popup, "Aplicar cor", function()
        if syncHex() then
            local ok, err = model:Set(hex.Text)
            if ok then r:ClosePopup() else errorText.Text = tostring(err) end
        end
    end)
    popup.scope:Add(model.updated:Connect(function(reason) if reason == "destroy" then r:ClosePopup() end end))
end

local function positionToasts(r)
    local y = 0
    for _, toast in ipairs(r.notifications) do
        toast.frame.Position = UDim2.new(1, 0, 0, y)
        y = y + toast.height + 8
    end
end

function Popups.notify(r, config)
    local scope = Scope.new()
    local width = math.min(340, math.max(120, r.root.AbsoluteSize.X - 16))
    local content = tostring(config.content or "")
    local bounds = r.textService:GetTextSize(content, 12, Enum.Font.Gotham, Vector2.new(width - 52, 10000))
    local height = math.min(148, math.max(72, bounds.Y + 44))
    local frame = scope:Add(r:Make("Frame", { AnchorPoint = Vector2.new(1, 0), Size = UDim2.fromOffset(width, height),
        BackgroundTransparency = 0, BackgroundColor3 = "$Surface", ZIndex = 30 }, r.toastRoot))
    r:Round(frame, 8)
    r:Make("TextLabel", { Text = tostring(config.title or "Lapo X"), Font = Enum.Font.GothamMedium, TextSize = 13,
        Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -60, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd }, frame)
    local body = r:Make("ScrollingFrame", { Position = UDim2.fromOffset(12, 34), Size = UDim2.new(1, -24, 1, -42),
        CanvasSize = UDim2.fromOffset(0, bounds.Y), ScrollBarThickness = 2 }, frame)
    r:Make("TextLabel", { Text = content, TextColor3 = "$Muted", TextWrapped = true, TextSize = 12,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -8, 0, bounds.Y) }, body)
    local toast = { frame = frame, scope = scope, height = height }
    local function dismiss()
        for index, item in ipairs(r.notifications) do if item == toast then table.remove(r.notifications, index); break end end
        scope:Destroy(); positionToasts(r)
    end
    toast.dismiss = dismiss
    r:Button(frame, "×", { Position = UDim2.new(1, -44, 0, 0), Size = UDim2.fromOffset(44, 44),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 20 }, dismiss, scope)
    r.notifications[#r.notifications + 1] = toast
    while #r.notifications > 3 do r.notifications[1].dismiss() end
    positionToasts(r)
    local duration = tonumber(config.duration) or 4
    scope:Delay(Util.clamp(duration, 1, 60), dismiss)
end

function Popups.loading(r, state)
    if not state then
        if r.loader then r.loader.scope:Destroy(); r.loader = nil end
        return
    end
    if not r.loader then
        local scope = Scope.new()
        local cover = scope:Add(r:Make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.08,
            BackgroundColor3 = "$Background", Active = true, ZIndex = 40 }, r.window))
        local body = r:Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, -40, 0, 140) }, cover)
        local title = r:Make("TextLabel", { TextSize = 18, Font = Enum.Font.GothamMedium,
            Size = UDim2.new(1, 0, 0, 30), TextTruncate = Enum.TextTruncate.AtEnd }, body)
        local subtitle = r:Make("TextLabel", { TextColor3 = "$Muted", TextSize = 12,
            Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 20) }, body)
        local message = r:Make("TextLabel", { TextColor3 = "$Muted", TextSize = 13,
            Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd }, body)
        local track = r:Make("Frame", { Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 4),
            BackgroundColor3 = "$Border", BackgroundTransparency = 0 }, body)
        local fill = r:Make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = "$Accent", BackgroundTransparency = 0 }, track)
        local percent = r:Make("TextLabel", { TextColor3 = "$Accent", TextSize = 12,
            Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 20), TextXAlignment = Enum.TextXAlignment.Right }, body)
        r.loader = { scope = scope, title = title, subtitle = subtitle, message = message, fill = fill, percent = percent }
    end
    r.loader.title.Text, r.loader.subtitle.Text = state.title, state.subtitle
    r.loader.message.Text, r.loader.percent.Text = state.message, math.floor(state.progress * 100) .. "%"
    r.loader.fill.Size = UDim2.fromScale(state.progress, 1)
end

return Popups

end

-- Module: NativeWidgets.lua
factories["NativeWidgets"] = function()
local Scope = require("Scope")
local Util = require("Util")
local Theme = require("Theme")
local Widgets = {}

function Widgets.mount(r, model)
    local scope = Scope.new()
    local root = scope:Add(r:Make("Frame", { Name = model.id }, r.content))
    local view = { scope = scope, root = root }
    local title = r:Make("TextLabel", { Text = model.text, Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -24, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd }, root)
    local description = r:Make("TextLabel", { Text = model.description, TextColor3 = "$Muted", TextSize = 12,
        Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -20, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd, Visible = model.description ~= "" }, root)
    local errorLabel = r:Make("TextLabel", { TextColor3 = "$Danger", TextSize = 12,
        Position = UDim2.new(0, 10, 1, -20), Size = UDim2.new(1, -20, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd }, root)
    local inputY = model.description ~= "" and 46 or 26
    local controls, update = {}, function() end
    local function enabled() return not model.destroyed and not model.disabled and not model.busy end
    local function button(label, props, callback)
        local control = r:Button(root, label, props, function() if enabled() then callback() end end, scope)
        controls[#controls + 1] = control
        return control
    end
    local function box(props)
        props.ClearTextOnFocus = false
        props.BackgroundTransparency, props.BackgroundColor3 = 0, "$Surface"
        local input = r:Make("TextBox", props, root)
        r:Round(input, 6)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, input)
        local stroke = r:Make("UIStroke", { Color = "$Focus", Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, input)
        scope:Add(input.Focused:Connect(function()
            r:Set(stroke, "Transparency", 0)
            r.scope:Delay(0.15, function()
                if input.Parent and input:IsFocused() then
                    r:Position()
                    local delta = input.AbsolutePosition.Y + input.AbsoluteSize.Y - (r.content.AbsolutePosition.Y + r.content.AbsoluteSize.Y)
                    if delta > 0 then r.content.CanvasPosition = r.content.CanvasPosition + Vector2.new(0, delta + 12) end
                end
            end)
        end))
        scope:Add(input.FocusLost:Connect(function() r:Set(stroke, "Transparency", 1) end))
        r.focusSerial = r.focusSerial + 1; r.focusables[input] = r.focusSerial
        controls[#controls + 1] = input
        return input
    end

    if model.kind == "Button" then
        title.Visible = false
        local action = button(model.text, { Size = UDim2.new(1, -4, 0, 44), BackgroundTransparency = 0,
            BackgroundColor3 = model.config.variant == "primary" and "$Accent" or "$Surface",
            TextColor3 = model.config.variant == "primary" and "$OnAccent" or "$Text",
            TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamMedium }, function()
            model.busy = true; model.updated:Fire("value")
            r.owner.scope:Spawn(function()
                if model.destroyed then return end
                local ok, err = Util.call(model.callback)
                if model.destroyed then return end
                model.busy = false; model.error = not ok and tostring(err) or nil
                model.updated:Fire("value")
            end)
        end)
        r:Round(action, 6)
        description.Position = UDim2.fromOffset(10, 44)
        update = function() action.Text = model.busy and "Aguarde…" or model.text end
        scope:Add(action.MouseEnter:Connect(function()
            if enabled() and model.config.variant ~= "primary" then r:Color(action, "BackgroundColor3", "Hover") end
        end))
        scope:Add(action.MouseLeave:Connect(function()
            r:Color(action, "BackgroundColor3", model.config.variant == "primary" and "Accent" or "Surface")
        end))
    elseif model.kind == "Toggle" then
        title.Position, title.Size = UDim2.fromOffset(10, 10), UDim2.new(1, -90, 0, 24)
        description.Position = UDim2.fromOffset(10, 40)
        local hit = button("", { Position = UDim2.new(1, -66, 0, 0), Size = UDim2.fromOffset(60, 48) }, function() model:Set(not model.value) end)
        local track = r:Make("Frame", { Position = UDim2.fromOffset(10, 14), Size = UDim2.fromOffset(38, 22),
            BackgroundTransparency = 0, BackgroundColor3 = "$Border" }, hit)
        r:Round(track, 11)
        local knob = r:Make("Frame", { Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 0, BackgroundColor3 = "$Text" }, track)
        r:Round(knob, 8)
        update = function()
            r:Color(track, "BackgroundColor3", model.value and "Accent" or "Border")
            r:Color(knob, "BackgroundColor3", model.value and "OnAccent" or "Text")
            knob.Position = UDim2.fromOffset(model.value and 19 or 3, 3)
        end
    elseif model.kind == "Slider" or model.kind == "Progress" then
        title.Size = UDim2.new(1, -104, 0, 24)
        local number
        if model.kind == "Slider" then
            number = box({ Text = tostring(model.value), Position = UDim2.new(1, -90, 0, 0), Size = UDim2.fromOffset(84, 26),
                TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right })
            scope:Add(number.FocusLost:Connect(function()
                if enabled() then model:Set(tonumber(number.Text)) end
                number.Text = tostring(model.value)
            end))
        else
            number = r:Make("TextLabel", { Position = UDim2.new(1, -70, 0, 0), Size = UDim2.fromOffset(64, 24),
                TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$Accent", TextSize = 12 }, root)
        end
        local hit = r:Make("TextButton", { Text = "", AutoButtonColor = false, Active = true, Selectable = true,
            Position = UDim2.fromOffset(10, inputY), Size = UDim2.new(1, -20, 0, 44) }, root)
        controls[#controls + 1] = hit
        local track = r:Make("Frame", { Position = UDim2.new(0, 0, 0.5, -2), Size = UDim2.new(1, 0, 0, 4),
            BackgroundTransparency = 0, BackgroundColor3 = "$Border" }, hit)
        r:Round(track, 2)
        local fill = r:Make("Frame", { Size = UDim2.fromScale(0, 1), BackgroundTransparency = 0, BackgroundColor3 = "$Accent" }, track)
        r:Round(fill, 2)
        local thumb = r:Make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14),
            Position = UDim2.fromScale(0, 0.5), BackgroundTransparency = 0, BackgroundColor3 = "$Accent",
            Visible = model.kind == "Slider" }, track)
        r:Round(thumb, 7)
        local function setPosition(position)
            if not enabled() or hit.AbsoluteSize.X <= 0 then return end
            model:Set(model.min + Util.clamp((position.X - hit.AbsolutePosition.X) / hit.AbsoluteSize.X, 0, 1) * (model.max - model.min))
        end
        if model.kind == "Slider" then
            scope:Add(hit.InputBegan:Connect(function(input)
                if not enabled() then return end
                local scrolling = r.content.ScrollingEnabled
                local function restore() if r.content.Parent then r.content.ScrollingEnabled = scrolling end end
                local started = r.pointer:Start(input, function(position)
                    r.content.ScrollingEnabled = false; setPosition(position)
                end, function(position, mode)
                    restore()
                    if mode == "pending" then setPosition(position) end
                end, "horizontal", restore)
                if started and input.UserInputType == Enum.UserInputType.MouseButton1 then setPosition(input.Position) end
            end))
            scope:Add(hit.InputBegan:Connect(function(input)
                if enabled() and (input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.Right) then
                    model:Set(model.value + (input.KeyCode == Enum.KeyCode.Left and -model.step or model.step))
                end
            end))
            r.focusSerial = r.focusSerial + 1; r.focusables[hit] = r.focusSerial
            local stroke = r:Make("UIStroke", { Color = "$Focus", Transparency = 1 }, thumb)
            scope:Add(hit.SelectionGained:Connect(function() r:Set(stroke, "Transparency", 0) end))
            scope:Add(hit.SelectionLost:Connect(function() r:Set(stroke, "Transparency", 1) end))
        else hit.Active, hit.Selectable = false, false end
        update = function()
            local ratio = model.max == model.min and 0 or (model.value - model.min) / (model.max - model.min)
            fill.Size, thumb.Position = UDim2.fromScale(ratio, 1), UDim2.fromScale(ratio, 0.5)
            if not number:IsA("TextBox") or not number:IsFocused() then
                number.Text = model.kind == "Progress" and (math.floor(ratio * 100 + 0.5) .. "%") or tostring(model.value)
            end
        end
    elseif model.kind == "Dropdown" then
        local select = button("", { Position = UDim2.fromOffset(6, inputY), Size = UDim2.new(1, -12, 0, 44),
            BackgroundColor3 = "$Surface", BackgroundTransparency = 0, TextTruncate = Enum.TextTruncate.AtEnd }, function() r:Dropdown(model) end)
        r:Round(select, 6)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 30) }, select)
        r:Make("TextLabel", { Text = "⌄", TextSize = 18, Position = UDim2.new(1, -16, 0, 0), Size = UDim2.fromOffset(16, 40),
            TextColor3 = "$Muted" }, select)
        update = function()
            if model.multiple then select.Text = #model.value == 0 and "Selecione…" or (#model.value .. " selecionados")
            else
                select.Text = "Nenhuma opção"
                for _, option in ipairs(model.options) do if option.value == model.value then select.Text = option.label; break end end
            end
        end
    elseif model.kind == "TextBox" or model.kind == "NumberInput" then
        local input = box({ Text = tostring(model.value), PlaceholderText = model.config.placeholder or "Digite…",
            PlaceholderColor3 = "$Muted", Position = UDim2.fromOffset(6, inputY), Size = UDim2.new(1, -12, 0, 44),
            TextTruncate = Enum.TextTruncate.AtEnd })
        scope:Add(input.FocusLost:Connect(function()
            if enabled() then model:Set(model.kind == "NumberInput" and tonumber(input.Text) or input.Text) end
        end))
        update = function() if not input:IsFocused() then input.Text = tostring(model.value) end end
    elseif model.kind == "Keybind" or model.kind == "ColorPicker" then
        title.Position, title.Size = UDim2.fromOffset(10, 10), UDim2.new(1, -112, 0, 24)
        description.Position = UDim2.fromOffset(10, 44)
        local control = button("", { Position = UDim2.new(1, -104, 0, 2), Size = UDim2.fromOffset(98, 44),
            BackgroundTransparency = 0, BackgroundColor3 = "$Surface", TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center }, function()
            if model.kind == "ColorPicker" then r:ColorPicker(model)
            else
                if r.captureKey then r.captureKey.updated:Fire("value") end
                r.captureKey = model; model.updated:Fire("value")
            end
        end)
        r:Round(control, 6)
        update = function()
            control.Text = r.captureKey == model and "Tecla… (Esc)" or tostring(model.value)
            if model.kind == "ColorPicker" then
                control.TextColor3 = Theme.color(model.value)
                local color = Theme.color(model.value)
                if color.R + color.G + color.B < 0.65 then r:Color(control, "TextColor3", "Text") end
            end
        end
    elseif model.kind == "Section" then
        title.Visible = false
        local section = button("", { Size = UDim2.new(1, 0, 0, 40), TextSize = 12, Font = Enum.Font.GothamMedium,
            TextColor3 = "$Muted" }, function() model:Set(not model.value) end)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10) }, section)
        update = function() section.Text = (model.value and "−  " or "+  ") .. model.text end
    elseif model.kind == "Separator" then
        title.Visible = false
        r:Make("Frame", { Position = UDim2.fromOffset(10, 7), Size = UDim2.new(1, -20, 0, 1),
            BackgroundTransparency = 0, BackgroundColor3 = "$Border" }, root)
    else
        title.TextWrapped, title.TextTruncate = true, Enum.TextTruncate.None
        title.Size, title.Position = UDim2.new(1, -20, 1, -16), UDim2.fromOffset(10, 8)
        title.TextYAlignment = Enum.TextYAlignment.Top
        if model.kind == "Paragraph" then r:Color(title, "TextColor3", "Muted") end
    end

    if model.config.tooltip then
        title.Size = UDim2.new(title.Size.X.Scale, title.Size.X.Offset - 28, title.Size.Y.Scale, title.Size.Y.Offset)
        local info = button("?", { Position = UDim2.new(1, -44, 0, 0), Size = UDim2.fromOffset(44, 44),
            TextColor3 = "$Muted", TextXAlignment = Enum.TextXAlignment.Center }, function()
            r:Dialog({ title = model.text, content = tostring(model.config.tooltip), confirmText = "Entendi" })
        end)
        -- A native tooltip on mouse/focus, with an explicit touch action for the same information.
        local tip
        local function hideTip() if tip then tip:Destroy(); tip = nil end end
        scope:Add(hideTip)
        scope:Add(info.MouseEnter:Connect(function()
            hideTip()
            tip = r:Make("TextLabel", { Text = tostring(model.config.tooltip), TextWrapped = true, TextSize = 12,
                Size = UDim2.fromOffset(math.min(250, r.root.AbsoluteSize.X - 24), 64),
                Position = UDim2.fromOffset(12, 12), BackgroundTransparency = 0, BackgroundColor3 = "$Surface", ZIndex = 25 }, r.root)
            r:Round(tip, 6)
            r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, tip)
        end))
        scope:Add(info.MouseLeave:Connect(hideTip))
    end

    local lastError = model.error
    local function refresh(reason)
        if model.destroyed or not root.Parent then return end
        title.Text = model.text
        errorLabel.Text, errorLabel.Visible = tostring(model.error or ""), model.error ~= nil
        for _, control in ipairs(controls) do
            control.Active, control.Selectable = enabled(), enabled()
            if control:IsA("TextBox") then control.TextEditable = enabled() end
        end
        r:Color(title, "TextColor3", model.disabled and "Muted" or (model.kind == "Paragraph" and "Muted" or "Text"))
        update()
        if lastError ~= model.error then lastError = model.error; r:Refresh() end
        if reason == "options" and r.popup and r.popup.model == model then r:Dropdown(model) end
    end
    scope:Add(model.updated:Connect(refresh))
    refresh()
    return view
end

return Widgets

end

-- Module: Pointer.lua
factories["Pointer"] = function()
local Layout = require("Layout")
local Pointer = {}
Pointer.__index = Pointer

function Pointer.new(uis, scope)
    local self = setmetatable({ uis = uis, active = nil }, Pointer)
    scope:Add(uis.InputChanged:Connect(function(input)
        local active = self.active
        if not active then return end
        local mouse = active.input.UserInputType == Enum.UserInputType.MouseButton1
        if input ~= active.input and not (mouse and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
        local delta = input.Position - active.start
        if active.axis == "horizontal" and active.mode == "pending" then
            active.mode = Layout.gesture(delta.X, delta.Y)
            if active.mode == "vertical" then self:Cancel(); return end
        end
        if active.mode ~= "pending" then active.move(input.Position, delta) end
    end))
    scope:Add(uis.InputEnded:Connect(function(input)
        local active = self.active
        if not active or input ~= active.input then return end
        self.active = nil
        if active.finish then active.finish(input.Position, active.mode) end
    end))
    scope:Add(uis.WindowFocusReleased:Connect(function() self:Cancel() end))
    scope:Add(function() self:Cancel() end)
    return self
end

function Pointer:Start(input, move, finish, axis, cancel)
    if self.active then return false end
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return false end
    self.active = { input = input, start = input.Position, move = move, finish = finish, axis = axis,
        cancel = cancel, mode = axis == "horizontal" and input.UserInputType == Enum.UserInputType.Touch and "pending" or "dragging" }
    return true
end

function Pointer:Cancel()
    local active = self.active
    self.active = nil
    if active and active.cancel then active.cancel() end
end

return Pointer

end

-- Module: Profiles.lua
factories["Profiles"] = function()
local Util = require("Util")
local Profiles = {}
Profiles.__index = Profiles

function Profiles.new(owner, capabilities, codec, folder)
    return setmetatable({ owner = owner, capabilities = capabilities, codec = codec,
        folder = folder or "LapoX", memory = {}, maxBytes = 1024 * 1024 }, Profiles)
end

function Profiles:Export()
    local values = {}
    for id, model in pairs(self.owner.models) do
        if model.persist and not model.destroyed then values[id] = { kind = model.kind, value = model:Get() } end
    end
    return { version = 2, window = self.owner.id, tab = self.owner.currentTab, values = values }
end

function Profiles:Import(data)
    if type(data) ~= "table" then return false, "Invalid profile" end
    if data.version == nil and type(data.currentTab) == "number" then
        local tab = self.owner.tabs[data.currentTab]
        if tab then self.owner:SelectTab(tab.id) end
        return true, "Migrated v1 tab; v1 did not persist component values"
    end
    if data.version ~= 2 or type(data.values) ~= "table" then return false, "Unsupported profile version" end
    if data.window ~= self.owner.id then return false, "Profile belongs to another window" end
    local pending = {}
    for id, entry in pairs(data.values) do
        local model = self.owner.models[id]
        if model and model.persist then
            if type(entry) ~= "table" or entry.kind ~= model.kind then return false, "Component type mismatch: " .. id end
            local ok, value = model:Normalize(entry.value)
            if not ok then return false, id .. ": " .. tostring(value) end
            pending[#pending + 1] = { model = model, value = value }
        end
    end
    -- Validate the entire profile first; malformed data never partially changes the UI.
    self.owner:BeginBatch()
    for _, entry in ipairs(pending) do entry.model:Set(entry.value, { silent = true }) end
    if self.owner.tabById[data.tab] then self.owner:SelectTab(data.tab) end
    self.owner:EndBatch()
    return true
end

function Profiles:Path(name)
    Util.id(name)
    assert(self.folder:match("^[%w_%-]+$"), "Profile folder must be a simple folder name")
    return self.folder .. "/" .. self.owner.id .. "." .. name .. ".json"
end

function Profiles:Save(name)
    local ok, path = pcall(self.Path, self, name or "default")
    if not ok then return false, path end
    local data = self:Export()
    self.memory[path] = Util.copy(data)
    local write, mkdir, isfolder = self.capabilities:Get("writefile"), self.capabilities:Get("makefolder"), self.capabilities:Get("isfolder")
    if not write or not mkdir or not isfolder then return true, "memory" end
    local saved, err = pcall(function()
        if not isfolder(self.folder) then mkdir(self.folder) end
        local encoded = self.codec:JSONEncode(data)
        assert(#encoded <= self.maxBytes, "Profile exceeds 1 MiB")
        -- Retain the previous valid file before replacement. Executor filesystems have no portable atomic rename.
        local read = self.capabilities:Get("readfile")
        if read then
            local readOK, previous = pcall(read, path)
            if readOK and type(previous) == "string" and #previous <= self.maxBytes then
                local decodedOK, previousData = pcall(self.codec.JSONDecode, self.codec, previous)
                if decodedOK and type(previousData) == "table" and previousData.version == 2 then write(path .. ".bak", previous) end
            end
        end
        write(path, encoded)
    end)
    if not saved then return true, "memory", tostring(err) end
    return true, "disk"
end

function Profiles:Load(name)
    local ok, path = pcall(self.Path, self, name or "default")
    if not ok then return false, path end
    local read = self.capabilities:Get("readfile")
    if read then
        local readOK, raw = pcall(read, path)
        if readOK then
            if type(raw) ~= "string" or #raw > self.maxBytes then return false, "Invalid profile size" end
            local decoded, data = pcall(self.codec.JSONDecode, self.codec, raw)
            if not decoded then return false, "Invalid JSON; previous profile retained in .bak when available" end
            return self:Import(data)
        end
    end
    if self.memory[path] then return self:Import(Util.copy(self.memory[path])) end
    return false, "Profile not found"
end

return Profiles

end

-- Module: Scope.lua
factories["Scope"] = function()
local Scope = {}
Scope.__index = Scope

local function cleanup(item)
    if type(item) == "function" then pcall(item)
    elseif type(item) == "thread" then pcall(task.cancel, item)
    elseif item then
        pcall(function()
            if item.Disconnect then item:Disconnect() else item:Destroy() end
        end)
    end
end

function Scope.new()
    return setmetatable({ items = {}, jobs = {}, destroyed = false }, Scope)
end

function Scope:Add(item)
    if self.destroyed then cleanup(item) else self.items[#self.items + 1] = item end
    return item
end

function Scope:Delay(seconds, callback)
    if self.destroyed then return end
    local job
    job = task.delay(seconds, function()
        if not self.destroyed then callback() end
        self.jobs[job] = nil
    end)
    self.jobs[job] = true
    return job
end

function Scope:Spawn(callback)
    return self:Delay(0, callback)
end

function Scope:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    local current = coroutine.running()
    for job in pairs(self.jobs) do if job ~= current then cleanup(job) end end
    self.jobs = {}
    for i = #self.items, 1, -1 do cleanup(self.items[i]) end
    self.items = {}
end

return Scope

end

-- Module: Signal.lua
factories["Signal"] = function()
local Util = require("Util")
local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ listeners = {}, destroyed = false }, Signal)
end

function Signal:Connect(callback)
    assert(not self.destroyed, "Signal destroyed")
    assert(type(callback) == "function", "Callback must be a function")
    local connection = { Connected = true }
    self.listeners[connection] = callback
    local listeners = self.listeners
    function connection:Disconnect()
        self.Connected = false
        listeners[self] = nil
    end
    return connection
end

function Signal:Fire(...)
    if self.destroyed then return end
    local snapshot = {}
    for connection, callback in pairs(self.listeners) do snapshot[connection] = callback end
    for connection, callback in pairs(snapshot) do
        if connection.Connected and not self.destroyed then Util.call(callback, ...) end
    end
end

function Signal:Destroy()
    self.destroyed = true
    for connection in pairs(self.listeners) do connection:Disconnect() end
end

return Signal

end

-- Module: Theme.lua
factories["Theme"] = function()
local Theme = {}
Theme.defaults = {
    Background = "#181B1E", Panel = "#1E2226", Surface = "#272D32", Hover = "#313A40",
    Border = "#3B454D", Text = "#E8EDEE", Muted = "#A5B0B6", Accent = "#83C9AA",
    OnAccent = "#152B22", Danger = "#F0A29A", Focus = "#B8E4CF",
}

function Theme.color(hex)
    assert(type(hex) == "string" and hex:match("^#%x%x%x%x%x%x$"), "Theme colors must use #RRGGBB")
    return Color3.fromRGB(tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16))
end

function Theme.resolve(overrides)
    local result = {}
    for name, hex in pairs(Theme.defaults) do result[name] = Theme.color((overrides or {})[name] or hex) end
    return result
end

return Theme

end

-- Module: Util.lua
factories["Util"] = function()
local Util = {}

function Util.copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = Util.copy(item) end
    return result
end

function Util.equal(a, b)
    if type(a) ~= type(b) then return false end
    if type(a) ~= "table" then return a == b end
    for k, v in pairs(a) do if not Util.equal(v, b[k]) then return false end end
    for k in pairs(b) do if a[k] == nil then return false end end
    return true
end

function Util.finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Util.clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function Util.call(fn, ...)
    if type(fn) ~= "function" then return true end
    local ok, err = pcall(fn, ...)
    if not ok then warn("[Lapo X] " .. tostring(err)) end
    return ok, err
end

function Util.id(value)
    assert(type(value) == "string" and value:match("^[%w_%-%.]+$") and #value <= 96,
        "ID must contain 1–96 letters, numbers, underscores, dots or hyphens")
    return value
end

function Util.slug(value)
    local result = tostring(value):lower():gsub("[^%w_%-]", "-"):gsub("%-+", "-"):sub(1, 70)
    return result ~= "" and result or "item"
end

function Util.array(value)
    if type(value) ~= "table" then return false end
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        count = count + 1
    end
    return count == #value
end

return Util

end

return require("Library")
