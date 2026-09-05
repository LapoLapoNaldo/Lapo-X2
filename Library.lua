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
        object[property] = self.suspended and value or 1
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
        if object:IsA("ScrollingFrame") then entry.scrollbar = drawing("Square"); entry.scrollbar.Filled = true end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            entry.text = drawing("Text")
            entry.texts = { entry.text }
            entry.text.Center = false
            local env = self.capabilities.environment
            local ok, font = pcall(function() return env.Drawing.Fonts.UI end)
            if ok and font then pcall(function() entry.text.Font = font end) end
        end
    end
    for property in pairs(masked) do
        local ok, value = pcall(function() return object[property] end)
        if ok and type(value) == "number" and (property ~= "Transparency" or object:IsA("UIStroke")) then
            entry.opacity[property] = value
            object[property] = self.suspended and value or 1
        end
    end
    entry.scope:Add(object.Destroying:Connect(function() self:Remove(object, false) end))
end

local function fitLines(content, width, wrapped, measure)
    local lines = {}
    for paragraph in (content .. "\n"):gmatch("(.-)\n") do
        if not wrapped then
            local line = paragraph
            if measure(line) > width then
                local chars = {}
                for _, code in utf8.codes(line) do chars[#chars + 1] = utf8.char(code) end
                while #chars > 0 and measure(table.concat(chars) .. "…") > width do table.remove(chars) end
                line = #chars > 0 and table.concat(chars) .. "…" or ""
            end
            lines[#lines + 1] = line
        else
            local line = ""
            for word in paragraph:gmatch("%S+%s*") do
                if line ~= "" and measure(line .. word) > width then lines[#lines + 1] = line; line = "" end
                if measure(word) > width then
                    for _, code in utf8.codes(word) do
                        local char = utf8.char(code)
                        if line ~= "" and measure(line .. char) > width then lines[#lines + 1] = line; line = "" end
                        line = line .. char
                    end
                else line = line .. word end
            end
            lines[#lines + 1] = line
        end
    end
    return lines
end

function DrawingRenderer:Text(entry, node, x, y, x2, y2, z)
    local content, color = node.Text, node.TextColor3
    if node:IsA("TextBox") and content == "" then content, color = node.PlaceholderText, node.PlaceholderColor3 end
    local position, size = node.AbsolutePosition, node.AbsoluteSize
    local padding = node:FindFirstChildOfClass("UIPadding")
    local padL, padR = 0, 0
    if padding then
        padL = padding.PaddingLeft.Offset + padding.PaddingLeft.Scale * size.X
        padR = padding.PaddingRight.Offset + padding.PaddingRight.Scale * size.X
    end
    local width = math.max(1, size.X - padL - padR)
    local key = content .. "|" .. tostring(width) .. "|" .. node.TextSize .. "|" .. tostring(node.TextWrapped)
    if entry.textKey ~= key then
        entry.text.Size = node.TextSize
        entry.lines = fitLines(content, width, node.TextWrapped, function(value)
            entry.text.Text = value; return entry.text.TextBounds.X
        end)
        entry.textKey = key
    end
    local lineHeight = node.TextSize * 1.2
    local top = position.Y
    if node.TextYAlignment == Enum.TextYAlignment.Center then top = top + (size.Y - #entry.lines * lineHeight) / 2
    elseif node.TextYAlignment == Enum.TextYAlignment.Bottom then top = top + size.Y - #entry.lines * lineHeight end
    local first = math.max(1, math.floor((y - top) / lineHeight) + 1)
    local last = math.min(#entry.lines, math.ceil((y2 - top) / lineHeight))
    local slot = 0
    for index = first, last do
        slot = slot + 1
        local text = entry.texts[slot]
        if not text then
            text = self.capabilities:Get("Drawing.new")("Text")
            text.Visible, text.Center = false, false
            pcall(function() text.Font = entry.text.Font end)
            entry.texts[slot], entry.drawings[#entry.drawings + 1] = text, text
        end
        text.Text, text.Size, text.Color = entry.lines[index], node.TextSize, color
        local bounds = text.TextBounds
        local left = position.X + padL
        if node.TextXAlignment == Enum.TextXAlignment.Center then left = position.X + (size.X - bounds.X) / 2
        elseif node.TextXAlignment == Enum.TextXAlignment.Right then left = position.X + size.X - bounds.X - padR end
        local lineY = top + (index - 1) * lineHeight
        if left >= x - 1 and lineY >= y - 1 and left + bounds.X <= x2 + 1 and lineY + bounds.Y <= y2 + 1 then
            text.Position = Vector2.new(left, lineY)
            text.Transparency, text.ZIndex, text.Visible = 1 - entry.opacity.TextTransparency, z + 1, true
        end
    end
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
    -- Drawing cannot display Roblox's text caret, IME or native image assets.
    -- Keep the complete native UI visible while those are in use.
    local focused = self.native.uis:GetFocusedTextBox()
    local suspend = focused ~= nil and focused:IsDescendantOf(self.native.root)
    for object in pairs(self.entries) do
        if not object:IsDescendantOf(self.native.screen) then
            self:Remove(object, false)
        elseif object:IsA("ImageLabel") and object.Image ~= "" and geometry(object, self.native.screen) then
            suspend = true
        end
    end
    if suspend ~= self.suspended then
        self.suspended = suspend
        for object, entry in pairs(self.entries) do
            for property, value in pairs(entry.opacity) do object[property] = suspend and value or 1 end
        end
    end
    for object, entry in pairs(self.entries) do
        for _, item in ipairs(entry.drawings) do item.Visible = false end
        local node, x, y, x2, y2, z = geometry(object, self.native.screen)
        if node and not suspend then
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
                self:Text(entry, node, x, y, x2, y2, z)
            end
            if entry.scrollbar and entry.opacity.ScrollBarImageTransparency < 1 and node.ScrollBarThickness > 0 then
                local viewport, canvas = node.AbsoluteWindowSize.Y, node.AbsoluteCanvasSize.Y
                if canvas > viewport and viewport > 0 then
                    local thumbHeight = math.min(viewport, math.max(12, viewport * viewport / canvas))
                    local top = node.AbsolutePosition.Y + math.clamp(node.CanvasPosition.Y / (canvas - viewport), 0, 1) * (viewport - thumbHeight)
                    local left = node.AbsolutePosition.X + node.AbsoluteSize.X - node.ScrollBarThickness
                    local sx, sy = math.max(x, left), math.max(y, top)
                    local ex, ey = math.min(x2, left + node.ScrollBarThickness), math.min(y2, top + thumbHeight)
                    if ex > sx and ey > sy then
                        local scrollbar = entry.scrollbar
                        scrollbar.Position, scrollbar.Size = Vector2.new(sx, sy), Vector2.new(ex - sx, ey - sy)
                        scrollbar.Color = node.ScrollBarImageColor3
                        scrollbar.Transparency, scrollbar.ZIndex, scrollbar.Visible = 1 - entry.opacity.ScrollBarImageTransparency, z + 99, true
                    end
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

-- Module: Keys.lua
factories["Keys"] = function()
local Keys = {}
local mouse = { MouseButton1 = true, MouseButton2 = true, MouseButton3 = true }

function Keys.normalize(value)
    if typeof(value) == "EnumItem" then
        if value.EnumType ~= Enum.KeyCode and value.EnumType ~= Enum.UserInputType then
            return false, "Expected a keyboard or mouse key"
        end
        value = value.Name
    end
    if type(value) ~= "string" then return false, "Expected a key name or Enum.KeyCode" end
    if value == "None" or mouse[value] then return true, value end
    local ok, key = pcall(function() return Enum.KeyCode[value] end)
    if not ok or not key or key == Enum.KeyCode.Unknown then return false, "Unknown key: " .. value end
    return true, key.Name
end

function Keys.input(input)
    if (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType.Name:match("^Gamepad[1-8]$"))
        and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end
    if mouse[input.UserInputType.Name] then return input.UserInputType.Name end
    return nil
end

return Keys

end

-- Module: Layout.lua
factories["Layout"] = function()
local Util = require("Util")
local Layout = {}
Layout.metrics = { inset = 6, gap = 6, field = 44, label = 24, radius = 5, header = 48, footer = 30, sidebar = 130 }

function Layout.tabRow(touch) return touch and 44 or 36 end

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
        sidebar = compact and 0 or Layout.metrics.sidebar, header = Layout.metrics.header, footer = Layout.metrics.footer }
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
Library.Version = "2.0.0-beta.5"

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
    if type(tab) == "table" and tab._tab then
        assert(self.tabById[tab._tab.id] == tab._tab, "Tab belongs to another window")
        return tab._tab
    end
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
    local id = self:_tab(tab).id
    if id ~= self.currentTab and self.renderer then self.renderer:ResetInteraction() end
    self.currentTab = id
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
    model.updated:Connect(function(reason)
        if reason == "layout" or reason == "destroy" then self:_refresh() end
    end)
    self:_refresh()
    return model
end

for _, kind in ipairs({ "Button", "Toggle", "Slider", "Dropdown", "TextBox", "Label", "Paragraph", "Separator",
    "Section", "NumberInput", "Keybind", "ColorPicker", "Progress" }) do
    Library["Add" .. kind] = function(self, tab, config) return self:_add(kind, tab, config) end
end

function Library:Get(id) return self.models[id] end

function Library:IsVisible(model, seen)
    if not model.visible or model.destroyed then return false end
    seen = seen or {}
    if seen[model] then return false end
    seen[model] = true
    if model.section then
        local section = self.models[model.section]
        if not section or not section.value or not self:IsVisible(section, seen) then return false end
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
    if self.config.AutoSave and self.profiles and model.persist and not self.importingProfile then
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
    config = Util.copy(config)
    config.Theme = config.Theme or self.pendingTheme
    self.config = config
    self.id = Util.id(config.Id or self.id)
    local Native = require("Native")
    local renderer = Native.new(self)
    self.renderer = renderer
    local ok, err = pcall(renderer.Mount, renderer, config)
    if not ok then renderer:Destroy(); self.renderer = nil; error("Lapo X initialization failed: " .. tostring(err), 2) end
    self.scope:Add(renderer)
    self.initialized = true
    renderer:SetVisible(self.visible)
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
    if self.renderer then self.renderer:SetTheme(theme) else self.pendingTheme = Util.copy(theme) end
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
local Keys = require("Keys")
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
    local text = config.text
    if text == nil then text = kind == "Separator" and "" or kind end
    local self = setmetatable({ owner = owner, tab = tab, kind = kind, id = id,
        config = Util.copy(config), text = tostring(text),
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
        elseif value == nil and #self.options == 0 then
            -- An empty dropdown is valid, but must still run custom validation below.
        elseif not available[value] then return false, "Unknown dropdown value: " .. tostring(value) end
    elseif kind == "ColorPicker" then
        if type(value) ~= "string" or not value:match("^#%x%x%x%x%x%x$") then return false, "Use #RRGGBB" end
        value = value:upper()
    elseif kind == "Keybind" then
        local ok, normalized = Keys.normalize(value)
        if not ok then return false, normalized end
        value = normalized
    else
        if type(value) ~= "string" then return false, "Expected text" end
    end
    if type(self.config.validate) == "function" then
        local ok, valid, message = pcall(self.config.validate, Util.copy(value))
        if not ok or valid == false then return false, tostring(message or (not ok and valid) or "Invalid value") end
    end
    return true, Util.copy(value)
end

function Model:Get()
    if self.kind == "Label" or self.kind == "Paragraph" or self.kind == "Button" or self.kind == "Separator" then return self.text end
    return Util.copy(self.value)
end

function Model:Set(value, options)
    if self.destroyed then return false, "Component destroyed" end
    if self.kind == "Dropdown" and type(value) == "table" and not self.multiple then
        return self:SetOptions(value, options)
    end
    if self.kind == "Label" or self.kind == "Paragraph" or self.kind == "Button" or self.kind == "Separator" then
        self.text = tostring(value)
        self.updated:Fire("layout")
        return true
    end
    local ok, result = self:Normalize(value)
    if not ok then self.error = result; self.updated:Fire("value"); return false, result end
    return self:_apply(result, options)
end

-- Internal commit for values already validated by SetOptions/profile transactions.
function Model:_apply(result, options)
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
    local previous = self.options
    self.options = result
    local valid = {}
    for _, option in ipairs(result) do valid[option.value] = true end
    local nextValue
    if self.multiple then
        nextValue = {}
        for _, v in ipairs(self.value) do if valid[v] then nextValue[#nextValue + 1] = v end end
    else nextValue = valid[self.value] and self.value or (result[1] and result[1].value) end
    local validValue, normalized = self:Normalize(nextValue)
    if not validValue then self.options = previous; return false, normalized end
    self:_apply(normalized, settings)
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
local Keys = require("Keys")
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
    local ok, err = pcall(function()
        if object:IsA("GuiObject") then
            object.BorderSizePixel = 0
            object.BackgroundTransparency = 1
        end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            object.Font = Enum.Font.Gotham
            object.TextSize = 13
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
    end)
    if not ok then object:Destroy(); error(err, 0) end
    if self.drawBridge then
        local bridge = self.drawBridge
        local ok, err = pcall(bridge.Track, bridge, object)
        if not ok then bridge:Fail(err) end
    end
    return object
end

function Native:Round(object, radius)
    return self:Make("UICorner", { CornerRadius = UDim.new(0, radius or Layout.metrics.radius) }, object)
end

function Native:Button(parent, label, props, callback, scope)
    props = props or {}; scope = scope or self.scope
    props.Text, props.AutoButtonColor, props.Selectable, props.Active = label, false, true, true
    local button = self:Make("TextButton", props, parent)
    button.SelectionImageObject = self.selectionImage
    local stroke = self:Make("UIStroke", { Color = "$Focus", Thickness = 1, Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
    self.focusSerial = self.focusSerial + 1
    self.focusables[button] = self.focusSerial
    scope:Add(button.SelectionGained:Connect(function() self:Set(stroke, "Transparency", 0) end))
    scope:Add(button.SelectionLost:Connect(function() self:Set(stroke, "Transparency", 1) end))
    if callback then
        -- Match one pointer and cancel activation after scrolling, even if release is inside the button.
        local press, released
        scope:Add(button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if not press then
                    released = nil
                    press = { input = input, start = input.Position, moved = false }
                end
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
            if self.destroyed or not button.Parent or not button.Active then return end
            local ancestor = button
            while ancestor and ancestor ~= self.screen do
                if ancestor:IsA("GuiObject") and not ancestor.Visible then return end
                ancestor = ancestor.Parent
            end
            local pointerInput = input and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)
            local activation = press or released
            if pointerInput and (not activation or activation.input ~= input or activation.moved) then return end
            press, released = nil, nil
            Util.call(callback)
        end))
        scope:Add(self.uis.InputEnded:Connect(function(input)
            if press and press.input == input then
                released, press = press, nil
            end
        end))
        scope:Add(self.uis.WindowFocusReleased:Connect(function() press, released = nil, nil end))
    end
    return button
end

function Native:Mount(config)
    self.config = config
    for _, dimension in ipairs({ "Width", "Height" }) do
        assert(config[dimension] == nil or (Util.finite(config[dimension]) and config[dimension] > 0), dimension .. " must be positive")
    end
    self.windowWidth, self.windowHeight = config.Width, config.Height
    local validKey, toggleKey = Keys.normalize(config.ToggleKey or "End")
    assert(validKey, toggleKey)
    self.toggleKey = toggleKey
    self.theme = Theme.resolve(config.Theme)
    self.uis = game:GetService("UserInputService")
    self.guiService = game:GetService("GuiService")
    self.textService = game:GetService("TextService")
    self.selectionImage = self.scope:Add(self:Make("Frame", { Name = "SelectionAdornment", Size = UDim2.fromScale(1, 1) }))
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
    self.header = self:Make("Frame", { Name = "Header", Position = UDim2.fromOffset(1, 1), Size = UDim2.new(1, -2, 0, 47),
        BackgroundColor3 = "$Panel", BackgroundTransparency = 0, Active = true }, self.window)
    self:Round(self.header, 9)
    self:Make("Frame", { Name = "HeaderBase", Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 23),
        BackgroundColor3 = "$Panel", BackgroundTransparency = 0 }, self.header)
    self:Make("Frame", { Name = "HeaderDivider", Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = "$Line", BackgroundTransparency = 0 }, self.header)
    self.menu = self:Button(self.header, "≡", { Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(2, 2),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 24 }, function()
        self.navOpen = not self.navOpen; self:Position()
    end)
    self.brand = self:Make("TextLabel", { Text = "Lapo", TextSize = 15, Size = UDim2.fromOffset(34, 47) }, self.header)
    self.brandX = self:Make("TextLabel", { Text = "X", TextSize = 15, TextColor3 = "$Accent", Size = UDim2.fromOffset(12, 47) }, self.header)
    self.titleDivider = self:Make("Frame", { Size = UDim2.fromOffset(1, 16), BackgroundColor3 = "$Border", BackgroundTransparency = 0 }, self.header)
    self.title = self:Make("TextLabel", { Text = config.Title or "Meu workspace", TextSize = 11, TextColor3 = "$Subtle",
        Size = UDim2.new(1, -200, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd }, self.header)
    self.minimize = self:Button(self.header, "−", { Size = UDim2.fromOffset(44, 44), Position = UDim2.new(1, -90, 0, 2),
        TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center }, function()
        self:ResetInteraction(); self.minimized = not self.minimized
        self:Position(); self:RenderRows()
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
    self.sidebarPanel = self:Make("Frame", { Name = "Sidebar", BackgroundTransparency = 0, BackgroundColor3 = "$Panel", ZIndex = 5 }, self.window)
    self.workspaceLabel = self:Make("TextLabel", { Text = "WORKSPACE", TextSize = 9, TextColor3 = "$Subtle",
        Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -24, 0, 20) }, self.sidebarPanel)
    self:Make("Frame", { Name = "SidebarDivider", Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = "$Line", BackgroundTransparency = 0 }, self.sidebarPanel)
    self.sidebar = self:Make("ScrollingFrame", { Name = "Tabs", Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, -1, 1, -96), ScrollBarThickness = 2, ScrollBarImageColor3 = "$Border",
        CanvasSize = UDim2.fromOffset(0, 0), ClipsDescendants = true, ZIndex = 5 }, self.sidebarPanel)
    self.userButton = self:Button(self.sidebarPanel, "", { Name = "User", Position = UDim2.new(0, 8, 1, -58),
        Size = UDim2.new(1, -16, 0, 52) }, function() Util.call(self.owner.userCallback, self.owner.userName, self.owner.userRank) end)
    self:Make("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundTransparency = 0, BackgroundColor3 = "$Line" }, self.userButton)
    self.avatar = self:Make("TextLabel", { Position = UDim2.fromOffset(6, 17), Size = UDim2.fromOffset(24, 24),
        BackgroundTransparency = 0, BackgroundColor3 = "$Surface", TextColor3 = "$Accent", TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Center }, self.userButton)
    self:Round(self.avatar, 5)
    self.userLabel = self:Make("TextLabel", { Position = UDim2.fromOffset(38, 13), Size = UDim2.new(1, -38, 0, 20),
        TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd }, self.userButton)
    self.rankLabel = self:Make("TextLabel", { Position = UDim2.fromOffset(38, 32), Size = UDim2.new(1, -38, 0, 14),
        TextSize = 9, TextColor3 = "$Subtle", TextTruncate = Enum.TextTruncate.AtEnd }, self.userButton)
    self.footer = self:Make("TextLabel", { TextColor3 = "$Subtle", TextSize = 9,
        Position = UDim2.new(0, 14, 1, -30), Size = UDim2.new(1, -100, 0, 30), TextTruncate = Enum.TextTruncate.AtEnd }, self.window)
    self.footerLine = self:Make("Frame", { Name = "FooterDivider", Position = UDim2.new(0, 1, 1, -30), Size = UDim2.new(1, -2, 0, 1),
        BackgroundColor3 = "$Line", BackgroundTransparency = 0 }, self.window)
    self.versionLabel = self:Make("TextLabel", { Text = "v" .. self.owner.Version:match("^%d+%.%d+"), TextColor3 = "$Subtle", TextSize = 9,
        Position = UDim2.new(1, -80, 1, -30), Size = UDim2.fromOffset(48, 30), TextXAlignment = Enum.TextXAlignment.Right }, self.window)
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
        if localX > self.header.AbsoluteSize.X - 92 then return end
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
        local tab = self.owner.tabById[self.renderedTab]
        if tab and not self.rendering then tab.scroll = self.content.CanvasPosition.Y end
        self:RenderRows()
        self:PositionPopup()
    end))
    for _, property in ipairs({ "OnScreenKeyboardVisible", "OnScreenKeyboardPosition", "OnScreenKeyboardSize" }) do
        pcall(function() self.scope:Add(self.uis:GetPropertyChangedSignal(property):Connect(function()
            self:Position(); self:RenderRows(); self:PositionPopup()
        end)) end)
    end
    self.scope:Add(self.uis.WindowFocusReleased:Connect(function() self:SetCaptureKey(nil) end))
    self.scope:Add(self.uis.InputBegan:Connect(function(input, processed)
        local key = Keys.input(input)
        if self.captureKey then
            local model = self.captureKey
            if model.destroyed or model.disabled or not self.owner:IsVisible(model) then self:SetCaptureKey(nil); return end
            if self.uis:GetFocusedTextBox() then return end
            if key then
                self:SetCaptureKey(nil)
                if key ~= "Escape" then model:Set((key == "Backspace" or key == "Delete") and "None" or key) end
            end
            return
        end
        local focused = self.uis:GetFocusedTextBox()
        if key == "Escape" and self.popup and (not focused or focused:IsDescendantOf(self.popup.panel)) then self:ClosePopup(); return end
        if focused then return end
        if key and key == self.toggleKey and not processed then self.owner:ToggleVisibility(); return end
        if self.owner.loading then return end
        if key == "Tab" and self.owner.visible and not processed then
            self:FocusNext(self.uis:IsKeyDown(Enum.KeyCode.LeftShift) or self.uis:IsKeyDown(Enum.KeyCode.RightShift)); return
        end
        if key and not processed and not self.popup then
            for _, model in pairs(self.owner.models) do
                if model.kind == "Keybind" and model.value == key and not model.disabled and self.owner:IsVisible(model) then
                    self.owner.scope:Spawn(function()
                        if not model.destroyed and not model.disabled and self.owner:IsVisible(model) then
                            Util.call(model.config.onPressed, key)
                        end
                    end)
                end
            end
        end
    end))
    self:UpdateUser(); self:Position()
end

function Native:SetCaptureKey(model)
    local previous = self.captureKey
    self.captureKey = model
    if previous and not previous.destroyed then previous.updated:Fire("value") end
    if model and not model.destroyed then model.updated:Fire("value") end
end

function Native:ResetInteraction()
    self:ClosePopup()
    if self.pointer then self.pointer:Cancel() end
    self:SetCaptureKey(nil)
    local focused = self.uis and self.uis:GetFocusedTextBox()
    if focused and self.root and focused:IsDescendantOf(self.root) then focused:ReleaseFocus() end
    if self.guiService and self.guiService.SelectedObject and self.root
        and self.guiService.SelectedObject:IsDescendantOf(self.root) then self.guiService.SelectedObject = nil end
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
    local brandX = geometry.compact and 44 or 15
    self.brand.Position = UDim2.fromOffset(brandX, 0)
    self.brandX.Position = UDim2.fromOffset(brandX + 35, 0)
    self.titleDivider.Position = UDim2.fromOffset(brandX + 55, 15)
    self.title.Position = UDim2.fromOffset(brandX + 66, 0)
    self.title.Size = UDim2.new(1, -brandX - 160, 1, 0)
    self.content.Position = UDim2.fromOffset(geometry.sidebar + 12, geometry.header + 12)
    self.content.Size = UDim2.new(1, -geometry.sidebar - 24, 1, -geometry.header - geometry.footer - 24)
    self.content.Visible, self.footer.Visible = not self.minimized, not self.minimized
    self.footerLine.Visible, self.versionLabel.Visible = not self.minimized, not self.minimized
    self.resize.Visible = not geometry.compact and not self.minimized
    self.sidebarPanel.Position = UDim2.fromOffset(1, geometry.header)
    self.sidebarPanel.Size = UDim2.new(0, geometry.compact and 156 or geometry.sidebar - 1, 1, -geometry.header - geometry.footer)
    self.sidebarPanel.Visible = not self.minimized and (not geometry.compact or self.navOpen)
    self.drawerBlock.Visible = geometry.compact and self.navOpen and not self.minimized
    self.drawerBlock.Position, self.drawerBlock.Size = UDim2.fromOffset(0, 48), UDim2.new(1, 0, 1, -48)
    self.reopen.Position = UDim2.fromOffset(size.X - 10, height - 10)
    self:PositionToasts()
    self:PositionPopup()
end

function Native:BuildTabs()
    local tabHeight = Layout.tabRow(self.uis.TouchEnabled or (self.geometry and self.geometry.compact))
    local signature = tostring(self.owner.currentTab) .. ":" .. #self.owner.tabs .. ":" .. tabHeight
    if self.tabSignature == signature then return end
    self.tabSignature = signature
    if self.tabsScope then self.tabsScope:Destroy() end
    self.tabsScope = Scope.new()
    for index, tab in ipairs(self.owner.tabs) do
        local selected = tab.id == self.owner.currentTab
        local icon = tab.icon and tostring(tab.icon) or ""
        local assetIcon = icon:match("^rbxassetid://%d+$")
        local label = icon ~= "" and not assetIcon and (icon .. "  " .. tab.name) or tab.name
        local button = self:Button(self.sidebar, label, { Name = tab.id, Position = UDim2.fromOffset(8, 2 + (index - 1) * (tabHeight + 2)),
            Size = UDim2.new(1, -16, 0, tabHeight), TextSize = 12, BackgroundTransparency = selected and 0 or 1,
            BackgroundColor3 = "$Surface", TextColor3 = selected and "$Accent" or "$Muted", TextTruncate = Enum.TextTruncate.AtEnd },
            function() self.navOpen = false; self:ClosePopup(); self.owner:SelectTab(tab.id) end, self.tabsScope)
        self.tabsScope:Add(button); self:Round(button, Layout.metrics.radius)
        self:Make("UIPadding", { PaddingLeft = UDim.new(0, assetIcon and 34 or 12), PaddingRight = UDim.new(0, 8) }, button)
        if assetIcon then
            self:Make("ImageLabel", { Image = icon, Position = UDim2.fromOffset(-24, 14), Size = UDim2.fromOffset(16, 16) }, button)
        end
    end
    self.sidebar.CanvasSize = UDim2.fromOffset(0, #self.owner.tabs * (tabHeight + 2) + 4)
end

function Native:Height(model, width)
    local touch = self.uis.TouchEnabled or (self.geometry and self.geometry.compact)
    local cacheKey = tostring(width) .. "|" .. model.text .. "|" .. model.description .. "|" .. tostring(model.error) .. "|" .. tostring(touch)
    if model._heightKey == cacheKey then return model._height end
    local base = ({ Button = 44, Toggle = 44, Slider = 60, Dropdown = 68, TextBox = 68,
        NumberInput = 68, Keybind = 48, ColorPicker = 48, Progress = 60, Section = 30, Separator = 12, Label = 30 })[model.kind] or 48
    if model.kind == "Separator" and model.text ~= "" then base = 30 end
    if touch then
        if model.kind == "Slider" then base = 88
        elseif model.kind == "Progress" then base = 68
        elseif model.kind == "Section" then base = 44 end
    end
    if model.kind == "Paragraph" or model.kind == "Label" then
        local measured = self.textService:GetTextSize(model.text, 13, Enum.Font.Gotham, Vector2.new(math.max(20, width - 12), 100000))
        base = math.max(base, measured.Y + 20)
    end
    if model.description ~= "" then base = base + 20 end
    if model.error then base = base + 20 end
    if model.config.tooltip then base = base + 44 end
    model._heightKey, model._height = cacheKey, base
    return base
end

function Native:_renderRows()
    if self.popup and self.popup.model and (self.popup.model.disabled or not self.owner:IsVisible(self.popup.model)) then
        self:ClosePopup()
    end
    local tab = self.owner.tabById[self.owner.currentTab]
    local width, viewport = math.max(1, self.geometry.width - self.geometry.sidebar - 24), math.max(1, self.geometry.height - self.geometry.header - self.geometry.footer - 24)
    local rows, required, y = {}, {}, 0
    if tab then
        for _, model in ipairs(tab.widgets) do
            if self.owner:IsVisible(model) then
                local h = self:Height(model, width)
                rows[#rows + 1] = { model = model, y = y, height = h }
                y = y + h + 6
            end
        end
    end
    local canvasHeight = math.max(0, y - 6)
    local offset = Util.clamp(self.pendingScroll or self.content.CanvasPosition.Y, 0, math.max(0, canvasHeight - viewport))
    self.pendingScroll = nil
    self.content.CanvasSize = UDim2.fromOffset(0, canvasHeight)
    if self.content.CanvasPosition.Y ~= offset then self.content.CanvasPosition = Vector2.new(0, offset) end
    if tab then tab.scroll = offset end
    local focused = self.uis:GetFocusedTextBox()
    for _, row in ipairs(rows) do
        local model = row.model
        local view = self.views[model.id]
        local ownsFocus = view and focused and focused:IsDescendantOf(view.root)
        if (Layout.visible(row.y, row.height, offset, viewport) or ownsFocus) and self.owner.visible and not self.minimized then
            required[model.id] = true
            if view and view.touch ~= (self.uis.TouchEnabled or self.geometry.compact) then
                view.scope:Destroy(); self.views[model.id], view = nil, nil
            end
            if not view then view = Widgets.mount(self, model); self.views[model.id] = view end
            view.root.Position, view.root.Size = UDim2.fromOffset(0, row.y), UDim2.new(1, 0, 0, row.height)
        end
    end
    for id, view in pairs(self.views) do
        if not required[id] then view.scope:Destroy(); self.views[id] = nil end
    end
    self.empty.Visible = #rows == 0
    self.empty.Text = tab and "Nenhuma opção nesta aba." or "Adicione uma aba para começar."
end

function Native:RenderRows()
    if self.destroyed or not self.geometry or self.rendering then return end
    self.rendering = true
    local ok, err = pcall(self._renderRows, self)
    self.rendering = false
    if not ok then error(err, 0) end
end

function Native:Refresh()
    if self.destroyed or self.scheduled then return end
    self.scheduled = true
    self.scope:Spawn(function()
        self.scheduled = false
        self:Position(); self:BuildTabs()
        if self.renderedTab ~= self.owner.currentTab then
            if self.renderedTab ~= nil then self:ResetInteraction() end
            for id, view in pairs(self.views) do view.scope:Destroy(); self.views[id] = nil end
            self.renderedTab = self.owner.currentTab
            local tab = self.owner.tabById[self.owner.currentTab]
            self.pendingScroll = tab and tab.scroll or 0
        end
        self:RenderRows()
    end)
end

function Native:UpdateUser()
    self.footer.Text = "Pronto para usar"
    self.userLabel.Text, self.rankLabel.Text = self.owner.userName, self.owner.userRank ~= "" and self.owner.userRank or "Local"
    local ok, finish = pcall(utf8.offset, self.owner.userName, 2)
    self.avatar.Text = ok and self.owner.userName:sub(1, (finish or (#self.owner.userName + 1)) - 1):upper() or "L"
end
function Native:SetVisible(visible)
    self:ResetInteraction()
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
    self.destroyed = true; self:ResetInteraction()
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
Native.PositionToasts = Popups.positionToasts
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
    local previousFocus = r.popup and r.popup.previousFocus or r.guiService.SelectedObject
    r:ResetInteraction()
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
        previousFocus = previousFocus }
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
    if popup.kind == "dropdown" and not popup.model.destroyed then popup.model.updated:Fire("value") end
    if not r.destroyed and popup.previousFocus and popup.previousFocus.Parent then r.guiService.SelectedObject = popup.previousFocus
    elseif r.guiService then r.guiService.SelectedObject = nil end
end

function Popups.position(r)
    if not r.popup then return end
    local size = r.root.AbsoluteSize
    local height = size.Y
    pcall(function()
        if r.uis.OnScreenKeyboardVisible then height = math.min(height, r.uis.OnScreenKeyboardPosition.Y - r.root.AbsolutePosition.Y) end
    end)
    if r.popup.kind == "dropdown" then
        local popup, anchor = r.popup, r.popup.anchor
        if not anchor.Parent or not r.owner.visible or r.minimized then r:ClosePopup(); return end
        local pos, extent, rootPos = anchor.AbsolutePosition, anchor.AbsoluteSize, r.root.AbsolutePosition
        local contentPos, contentSize = r.content.AbsolutePosition, r.content.AbsoluteSize
        if pos.Y + extent.Y <= contentPos.Y or pos.Y >= contentPos.Y + contentSize.Y then r:ClosePopup(); return end
        local left, top = pos.X - rootPos.X, pos.Y - rootPos.Y
        local bottom = math.min(height - 8, r.window.AbsolutePosition.Y - rootPos.Y + r.window.AbsoluteSize.Y - r.geometry.footer - 4)
        local ceiling = math.max(8, r.window.AbsolutePosition.Y - rootPos.Y + r.geometry.header + 4)
        local below, above = math.max(0, bottom - top - extent.Y - 4), math.max(0, top - ceiling - 4)
        local upward = below < popup.height and above > below
        local h = math.min(popup.height, upward and above or below)
        if h < popup.rowHeight then r:ClosePopup(); return end
        local w = math.min(extent.X, size.X - 16)
        popup.panel.Size = UDim2.fromOffset(w, h)
        popup.panel.Position = UDim2.fromOffset(Util.clamp(left, 8, math.max(8, size.X - w - 8)), upward and (top - h - 4) or (top + extent.Y + 4))
        if popup.search then
            local searchHeight = popup.searchable and h >= popup.rowHeight * 2 + 12 and popup.rowHeight or 0
            popup.search.Visible = searchHeight > 0
            popup.search.Size = UDim2.new(1, -8, 0, searchHeight)
            local listTop = searchHeight > 0 and searchHeight + 8 or 4
            popup.list.Position = UDim2.fromOffset(4, listTop)
            popup.list.Size = UDim2.new(1, -8, 1, -listTop - 4)
        end
        return
    end
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

function Popups.dropdown(r, model, anchor)
    if model.destroyed or model.disabled or not r.owner:IsVisible(model) then return end
    if r.popup and r.popup.kind == "dropdown" and r.popup.model == model then r:ClosePopup(); return end
    local view = r.views[model.id]
    anchor = anchor or (view and view.dropdownAnchor)
    if not anchor or not anchor.Parent then return end
    local previousFocus = r.guiService.SelectedObject
    r:ResetInteraction()
    local scope = Scope.new()
    local panel = scope:Add(r:Make("Frame", { Name = "DropdownList", BackgroundTransparency = 0,
        BackgroundColor3 = "$Panel", Active = true, ClipsDescendants = true, ZIndex = 20 }, r.root))
    r:Round(panel, 5)
    r:Make("UIStroke", { Color = "$Border", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, panel)
    local rowHeight = (r.uis.TouchEnabled or r.geometry.compact) and 44 or 36
    local popup = { kind = "dropdown", scope = scope, panel = panel, model = model, anchor = anchor,
        previousFocus = previousFocus, rowHeight = rowHeight, height = 0 }
    r.popup = popup
    local searchable = model.config.search ~= false
    local search = r:Make("TextBox", { PlaceholderText = "Buscar opção…", PlaceholderColor3 = "$Muted", Text = "",
        Name = "Search", ClearTextOnFocus = false, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, rowHeight),
        BackgroundTransparency = 0, BackgroundColor3 = "$Surface", Visible = searchable }, popup.panel)
    r:Round(search, 4)
    r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)
    local list = r:Make("ScrollingFrame", { Name = "Options", CanvasSize = UDim2.fromOffset(0, 0),
        ScrollBarThickness = 3, ScrollBarImageColor3 = "$Border", ScrollingDirection = Enum.ScrollingDirection.Y,
        ClipsDescendants = true, Active = true }, popup.panel)
    popup.search, popup.searchable, popup.list = search, searchable, list
    r.focusSerial = r.focusSerial + 1; r.focusables[search] = r.focusSerial
    local empty = r:Make("TextLabel", { Text = "Nenhum resultado", TextColor3 = "$Muted", Size = UDim2.new(1, 0, 0, rowHeight) }, list)
    local filtered, slots = {}, {}
    local function selected(value)
        if not model.multiple then return model.value == value end
        for _, item in ipairs(model.value) do if item == value then return true end end
        return false
    end
    local function draw()
        if r.popup ~= popup then return end
        local start = math.max(1, math.floor(list.CanvasPosition.Y / rowHeight) + 1)
        local count = math.min(8, math.ceil(math.max(rowHeight, list.AbsoluteSize.Y) / rowHeight) + 1)
        for index = 1, count do
            local slot = slots[index]
            if not slot then
                slot = {}; slots[index] = slot
                slot.button = r:Button(list, "", { Position = UDim2.fromOffset(2, 0), Size = UDim2.new(1, -6, 0, rowHeight), TextTruncate = Enum.TextTruncate.AtEnd,
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
                    else
                        local ok = model:Set(option.value)
                        if ok and r.popup == popup then r:ClosePopup() end
                    end
                end, popup.scope)
                r:Round(slot.button, 5)
                r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, slot.button)
            end
            local itemIndex = start + index - 1
            slot.option = filtered[itemIndex]
            slot.button.Visible = slot.option ~= nil
            if slot.option then
                local active = selected(slot.option.value)
                slot.button.Position = UDim2.fromOffset(2, (itemIndex - 1) * rowHeight)
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
        popup.height = 8 + math.min(6, math.max(1, #filtered)) * rowHeight + (searchable and (rowHeight + 4) or 0)
        r:PositionPopup()
        if r.popup ~= popup then return end
        list.CanvasPosition, list.CanvasSize = Vector2.new(0, 0), UDim2.fromOffset(0, #filtered * rowHeight)
        empty.Visible = #filtered == 0
        draw()
    end
    popup.scope:Add(search:GetPropertyChangedSignal("Text"):Connect(filter))
    popup.scope:Add(list:GetPropertyChangedSignal("CanvasPosition"):Connect(draw))
    popup.scope:Add(list:GetPropertyChangedSignal("AbsoluteSize"):Connect(draw))
    popup.scope:Add(model.updated:Connect(function(reason)
        if reason == "destroy" or model.disabled or not r.owner:IsVisible(model) then r:ClosePopup()
        elseif reason == "options" then filter() else draw() end
    end))
    popup.scope:Add(r.uis.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local function inside(object)
            local p, s, point = object.AbsolutePosition, object.AbsoluteSize, input.Position
            return point.X >= p.X and point.X <= p.X + s.X and point.Y >= p.Y and point.Y <= p.Y + s.Y
        end
        if not inside(panel) and not inside(anchor) then r:ClosePopup() end
    end))
    filter()
    model.updated:Fire("value")
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
            if r.popup ~= popup then return end
            local ok, err = Util.call(config.callback or config.onConfirm)
            if r.popup ~= popup then return end
            if ok then r:ClosePopup()
            else message.Text = tostring(err); popup.busy = false; confirm.Text = config.confirmText or "Tentar novamente" end
        end)
    end)
    return { Close = function() if r.popup == popup then r:ClosePopup() end end }
end

function Popups.color(r, model)
    if model.destroyed or model.disabled then return end
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
    local invalidRGB = false
    local function syncHex()
        local ok = hex.Text:match("^#%x%x%x%x%x%x$")
        errorText.Text = ok and "" or "Use uma cor no formato #RRGGBB."
        if ok then
            invalidRGB = false
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
                    invalidRGB = true; errorText.Text = "RGB deve conter inteiros entre 0 e 255."; return
                end
                values[index] = value
            end
            hex.Text = string.format("#%02X%02X%02X", values[1], values[2], values[3]); syncHex()
        end))
    end
    footer(r, popup, "Aplicar cor", function()
        if invalidRGB then return end
        if syncHex() then
            local ok, err = model:Set(hex.Text)
            if ok then
                if r.popup == popup then r:ClosePopup() end
            elseif r.popup == popup then errorText.Text = tostring(err) end
        end
    end)
    popup.scope:Add(model.updated:Connect(function(reason)
        if reason == "destroy" or model.disabled or not r.owner:IsVisible(model) then r:ClosePopup() end
    end))
end

function Popups.positionToasts(r)
    local y = 0
    local size = r.root.AbsoluteSize
    local width = math.min(340, math.max(1, size.X - 16))
    local limit = math.max(64, (size.Y - 16 - math.max(0, #r.notifications - 1) * 8) / math.max(1, #r.notifications))
    for _, toast in ipairs(r.notifications) do
        local bounds = r.textService:GetTextSize(toast.content, 12, Enum.Font.Gotham, Vector2.new(math.max(1, width - 32), 10000))
        toast.height = math.min(limit, 148, math.max(72, bounds.Y + 44))
        toast.frame.Size = UDim2.fromOffset(width, toast.height)
        toast.body.CanvasSize = UDim2.fromOffset(0, bounds.Y)
        toast.label.Size = UDim2.new(1, -8, 0, bounds.Y)
        toast.frame.Position = UDim2.new(1, 0, 0, y)
        y = y + toast.height + 8
    end
end

function Popups.notify(r, config)
    if r.destroyed then return end
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
    local label = r:Make("TextLabel", { Text = content, TextColor3 = "$Muted", TextWrapped = true, TextSize = 12,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -8, 0, bounds.Y) }, body)
    local toast = { frame = frame, scope = scope, height = height, content = content, body = body, label = label }
    local function dismiss()
        if scope.destroyed then return end
        for index, item in ipairs(r.notifications) do if item == toast then table.remove(r.notifications, index); break end end
        scope:Destroy(); r:PositionToasts()
    end
    toast.dismiss = dismiss
    r:Button(frame, "×", { Position = UDim2.new(1, -44, 0, 0), Size = UDim2.fromOffset(44, 44),
        TextXAlignment = Enum.TextXAlignment.Center, TextSize = 20 }, dismiss, scope)
    r.notifications[#r.notifications + 1] = toast
    while #r.notifications > 3 do r.notifications[1].dismiss() end
    r:PositionToasts()
    local duration = tonumber(config.duration)
    if not Util.finite(duration) then duration = 4 end
    scope:Delay(Util.clamp(duration, 1, 60), dismiss)
end

function Popups.loading(r, state)
    if not state then
        if r.loader then r.loader.scope:Destroy(); r.loader = nil end
        for _, view in pairs(r.views) do view.refresh() end
        return
    end
    if not r.loader then
        r:ResetInteraction()
        for _, view in pairs(r.views) do view.refresh() end
        local scope = Scope.new()
        local cover = scope:Add(r:Make("TextButton", { Text = "", AutoButtonColor = false, Selectable = false,
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.08,
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
        if state.image then
            local ok, asset = r.owner.capabilities:Asset(state.image)
            if ok then
                r:Make("ImageLabel", { Image = asset, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(0, 0) }, body)
                title.Position, title.Size = UDim2.fromOffset(48, 0), UDim2.new(1, -48, 0, 30)
            else warn("[Lapo X] Loading image skipped: " .. tostring(asset)) end
        end
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
local Layout = require("Layout")
local Widgets = {}

local function mount(r, model, scope)
    local root = scope:Add(r:Make("Frame", { Name = model.id }, r.content))
    local touch = r.uis.TouchEnabled or r.geometry.compact
    local view = { scope = scope, root = root, touch = touch }
    local ownedPointer
    scope:Add(function()
        if ownedPointer and r.pointer.active == ownedPointer then r.pointer:Cancel() end
        if r.captureKey == model then r:SetCaptureKey(nil) end
        local focused = r.uis:GetFocusedTextBox()
        if focused and focused:IsDescendantOf(root) then focused:ReleaseFocus() end
    end)
    local inset, field = Layout.metrics.inset, Layout.metrics.field
    local title = r:Make("TextLabel", { Name = "Label", Text = model.text, Position = UDim2.fromOffset(inset, 0),
        Size = UDim2.new(1, -inset * 2, 0, 24), TextTruncate = Enum.TextTruncate.AtEnd }, root)
    local description = r:Make("TextLabel", { Text = model.description, TextColor3 = "$Muted", TextSize = 12,
        Position = UDim2.fromOffset(inset, 24), Size = UDim2.new(1, -inset * 2, 0, 20),
        TextTruncate = Enum.TextTruncate.AtEnd, Visible = model.description ~= "" }, root)
    local errorLabel = r:Make("TextLabel", { TextColor3 = "$Danger", TextSize = 12,
        Position = UDim2.new(0, inset, 1, -20), Size = UDim2.new(1, -inset * 2, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd }, root)
    local inputY = model.description ~= "" and 44 or 24
    local controls, update, info = {}, function() end, nil
    local function editable()
        return not r.owner.destroyed and not model.destroyed and not model.disabled and not model.busy
    end
    local function enabled()
        return editable() and r.owner.visible and not r.owner.loading and not r.minimized
            and r.owner.currentTab == model.tab.id and r.owner:IsVisible(model)
    end
    local function button(label, props, callback)
        local control = r:Button(root, label, props, function() if enabled() then callback() end end, scope)
        controls[#controls + 1] = control
        return control
    end
    local function box(props)
        props.ClearTextOnFocus = false
        props.BackgroundTransparency, props.BackgroundColor3 = 0, "$Surface"
        local input = r:Make("TextBox", props, root)
        input.SelectionImageObject = r.selectionImage
        r:Round(input, Layout.metrics.radius)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, input)
        local stroke = r:Make("UIStroke", { Color = "$Focus", Transparency = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, input)
        scope:Add(input.Focused:Connect(function()
            r:Set(stroke, "Transparency", 0)
            scope:Delay(0.15, function()
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
        local action = button(model.text, { Name = "Control", Position = UDim2.fromOffset(inset, 0),
            Size = UDim2.new(1, -inset * 2, 0, field), BackgroundTransparency = 0,
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
        r:Round(action, Layout.metrics.radius)
        description.Position = UDim2.fromOffset(inset, 44)
        update = function() action.Text = model.busy and "Aguarde…" or model.text end
        scope:Add(action.MouseEnter:Connect(function()
            if enabled() and model.config.variant ~= "primary" then r:Color(action, "BackgroundColor3", "Hover") end
        end))
        scope:Add(action.MouseLeave:Connect(function()
            r:Color(action, "BackgroundColor3", model.config.variant == "primary" and "Accent" or "Surface")
        end))
    elseif model.kind == "Toggle" then
        title.Position, title.Size = UDim2.fromOffset(inset, 10), UDim2.new(1, -78, 0, 24)
        description.Position = UDim2.fromOffset(inset, 44)
        local hit = button("", { Position = UDim2.new(1, -60, 0, 0), Size = UDim2.fromOffset(54, 44) }, function() model:Set(not model.value) end)
        local track = r:Make("Frame", { Position = UDim2.fromOffset(8, 11), Size = UDim2.fromOffset(38, 22),
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
        if touch and model.kind == "Slider" then title.Position = UDim2.fromOffset(inset, 10); inputY = inputY + 20 end
        local number
        if model.kind == "Slider" then
            number = box({ Name = "Value", Text = tostring(model.value), Position = UDim2.new(1, -56, 0, 0), Size = UDim2.fromOffset(50, touch and 44 or 27),
                TextColor3 = "$Accent", TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center })
            r:Make("UIStroke", { Color = "$Border", Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, number)
            scope:Add(number.FocusLost:Connect(function()
                if editable() then model:Set(tonumber(number.Text)) end
                number.Text = tostring(model.value)
            end))
        else
            number = r:Make("TextLabel", { Position = UDim2.new(1, -70, 0, 0), Size = UDim2.fromOffset(64, 24),
                TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = "$Accent", TextSize = 12 }, root)
        end
        local hit = r:Make("TextButton", { Text = "", AutoButtonColor = false, Active = true, Selectable = true,
            SelectionImageObject = r.selectionImage, Position = UDim2.fromOffset(inset, inputY), Size = UDim2.new(1, -inset * 2, 0, touch and 44 or 36) }, root)
        if model.kind == "Slider" then controls[#controls + 1] = hit end
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
                if started then ownedPointer = r.pointer.active end
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
        local select
        select = button("", { Name = "Control", Position = UDim2.fromOffset(inset, inputY), Size = UDim2.new(1, -inset * 2, 0, field),
            BackgroundColor3 = "$Surface", BackgroundTransparency = 0, TextTruncate = Enum.TextTruncate.AtEnd }, function() r:Dropdown(model, select) end)
        view.dropdownAnchor = select
        scope:Add(function() if r.popup and r.popup.anchor == select then r:ClosePopup() end end)
        r:Round(select, Layout.metrics.radius)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 30) }, select)
        local arrow = r:Make("TextLabel", { Name = "Chevron", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(1, -22, 0, inputY + 22), Size = UDim2.fromOffset(12, 16), TextColor3 = "$Muted",
            TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, Text = "v" }, root)
        update = function()
            arrow.Text = r.popup and r.popup.model == model and "^" or "v"
            if model.multiple then select.Text = #model.value == 0 and "Selecione…" or (#model.value .. " selecionados")
            else
                select.Text = "Nenhuma opção"
                for _, option in ipairs(model.options) do if option.value == model.value then select.Text = option.label; break end end
            end
        end
    elseif model.kind == "TextBox" or model.kind == "NumberInput" then
        local input = box({ Name = "Control", Text = tostring(model.value), PlaceholderText = model.config.placeholder or "Digite…",
            PlaceholderColor3 = "$Muted", Position = UDim2.fromOffset(inset, inputY), Size = UDim2.new(1, -inset * 2, 0, field),
            TextTruncate = Enum.TextTruncate.AtEnd })
        scope:Add(input.FocusLost:Connect(function()
            if editable() then
                local value = input.Text
                if model.kind == "NumberInput" then value = tonumber(value) end
                model:Set(value)
            end
            input.Text = tostring(model.value)
        end))
        update = function() if not input:IsFocused() then input.Text = tostring(model.value) end end
    elseif model.kind == "Keybind" or model.kind == "ColorPicker" then
        title.Position, title.Size = UDim2.fromOffset(inset, 10), UDim2.new(1, -112, 0, 24)
        description.Position = UDim2.fromOffset(inset, 44)
        local control = button("", { Position = UDim2.new(1, -104, 0, 2), Size = UDim2.fromOffset(98, 44),
            BackgroundTransparency = 0, BackgroundColor3 = "$Surface", TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center }, function()
            if model.kind == "ColorPicker" then r:ColorPicker(model)
            else
                r:SetCaptureKey(r.captureKey ~= model and model or nil)
            end
        end)
        r:Round(control, Layout.metrics.radius)
        update = function()
            control.Text = r.captureKey == model and "Tecla… (Esc)" or tostring(model.value)
            if model.kind == "ColorPicker" then
                r.bindings[control].TextColor3 = nil
                control.TextColor3 = Theme.color(model.value)
                local color = Theme.color(model.value)
                if color.R + color.G + color.B < 0.65 then r:Color(control, "TextColor3", "Text") end
            end
        end
    elseif model.kind == "Section" then
        title.Visible = false
        local section = button("", { Position = UDim2.fromOffset(inset, 0), Size = UDim2.new(1, -inset * 2, 0, touch and 44 or 30), TextSize = 11, Font = Enum.Font.GothamMedium,
            TextColor3 = "$Muted" }, function() model:Set(not model.value) end)
        r:Make("UIPadding", { PaddingLeft = UDim.new(0, 0) }, section)
        update = function() section.Text = (model.value and "−  " or "+  ") .. model.text end
    elseif model.kind == "Separator" then
        title.Visible = false
        local line = r:Make("Frame", { Name = "SeparatorLine", Position = UDim2.fromOffset(inset, 6),
            Size = UDim2.new(1, -inset * 2, 0, 1), BackgroundTransparency = 0,
            BackgroundColor3 = "$Line" }, root)
        local lead = r:Make("Frame", { Name = "SeparatorLead", Position = UDim2.fromOffset(inset, 14),
            Size = UDim2.fromOffset(8, 1), BackgroundTransparency = 0, BackgroundColor3 = "$Line" }, root)
        local separatorLabel = r:Make("TextLabel", { Name = "SeparatorLabel", Position = UDim2.fromOffset(inset + 14, 2),
            Size = UDim2.fromOffset(0, 24), TextSize = 10, Font = Enum.Font.GothamMedium,
            TextColor3 = "$Subtle", TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd }, root)
        local tail = r:Make("Frame", { Name = "SeparatorTail", Position = UDim2.fromOffset(inset + 20, 14),
            Size = UDim2.new(1, -inset * 2 - 20, 0, 1), BackgroundTransparency = 0,
            BackgroundColor3 = "$Line" }, root)
        update = function()
            local labeled = model.text ~= ""
            line.Visible, lead.Visible, separatorLabel.Visible, tail.Visible = not labeled, labeled, labeled, labeled
            if not labeled then return end
            -- The row receives its final size immediately after mounting. Measuring against
            -- root.AbsoluteSize here used to clamp the label to 1 px on its first render.
            local labelWidth = r.textService:GetTextSize(model.text, 10,
                Enum.Font.GothamMedium, Vector2.new(160, 24)).X
            separatorLabel.Text, separatorLabel.Size = model.text, UDim2.fromOffset(labelWidth, 24)
            tail.Position = UDim2.fromOffset(inset + 20 + labelWidth, 14)
            tail.Size = UDim2.new(1, -inset * 2 - 20 - labelWidth, 0, 1)
        end
    else
        title.TextWrapped, title.TextTruncate = true, Enum.TextTruncate.None
        title.Size, title.Position = UDim2.new(1, -inset * 2, 1, -16), UDim2.fromOffset(inset, 8)
        title.TextYAlignment = Enum.TextYAlignment.Top
        if model.kind == "Paragraph" then r:Color(title, "TextColor3", "Muted") end
    end

    if model.config.tooltip then
        info = button("?", { Name = "Help", Position = UDim2.new(1, -44, 1, -44), Size = UDim2.fromOffset(44, 44),
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
        local extra = (model.error and 20 or 0) + (model.config.tooltip and 44 or 0)
        if info then info.Position = UDim2.new(1, -44, 1, -44 - (model.error and 20 or 0)) end
        if model.kind == "Label" or model.kind == "Paragraph" then
            title.Size = UDim2.new(1, -inset * 2, 1, -16 - extra - (model.description ~= "" and 20 or 0))
            description.Position = UDim2.new(0, inset, 1, -20 - extra)
        end
        for _, control in ipairs(controls) do
            control.Active, control.Selectable = enabled(), enabled()
            if control:IsA("TextBox") then control.TextEditable = enabled() end
        end
        if not enabled() then
            if ownedPointer and r.pointer.active == ownedPointer then r.pointer:Cancel() end
            if r.captureKey == model then r:SetCaptureKey(nil) end
        end
        r:Color(title, "TextColor3", model.disabled and "Muted" or (model.kind == "Paragraph" and "Muted" or "Text"))
        update()
        if lastError ~= model.error then lastError = model.error; r:Refresh() end
    end
    scope:Add(model.updated:Connect(refresh))
    view.refresh = refresh
    refresh()
    return view
end

function Widgets.mount(r, model)
    local scope = Scope.new()
    local ok, view = pcall(mount, r, model, scope)
    if not ok then scope:Destroy(); error(view, 0) end
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
        folder = folder or "LapoX", memory = {}, memoryOnly = {}, maxBytes = 1024 * 1024 }, Profiles)
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
    self.owner.autoSaveGeneration = self.owner.autoSaveGeneration + 1
    self.owner:BeginBatch()
    self.owner.importingProfile = true
    for _, entry in ipairs(pending) do entry.model:_apply(entry.value, { silent = true }) end
    self.owner.importingProfile = false
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
    self.memoryOnly[path] = true
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
    self.memoryOnly[path] = nil
    return true, "disk"
end

function Profiles:Load(name)
    local ok, path = pcall(self.Path, self, name or "default")
    if not ok then return false, path end
    if self.memoryOnly[path] then return self:Import(Util.copy(self.memory[path])) end
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
    if item == nil then return end
    local ok, err = pcall(function()
        local kind = typeof(item)
        if kind == "function" then item()
        elseif kind == "thread" then
            if coroutine.status(item) ~= "dead" then task.cancel(item) end
        elseif kind == "RBXScriptConnection" then item:Disconnect()
        elseif kind == "Instance" then item:Destroy()
        elseif type(item) == "table" then
            if type(item.Disconnect) == "function" then item:Disconnect()
            elseif type(item.Destroy) == "function" then item:Destroy() end
        end
    end)
    if not ok then warn("[Lapo X] Cleanup failed: " .. tostring(err)) end
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
        local ok, err = true, nil
        if not self.destroyed then ok, err = pcall(callback) end
        self.jobs[job] = nil
        if not ok then error(err, 0) end
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
    Line = "#2C343A", Subtle = "#819098",
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

function Util.copy(value, seen)
    if typeof(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do result[key] = Util.copy(item, seen) end
    return result
end

function Util.equal(a, b, seen)
    if a == b then return true end
    if typeof(a) ~= "table" or typeof(b) ~= "table" then return false end
    seen = seen or {}
    if seen[a] and seen[a][b] then return true end
    seen[a] = seen[a] or {}; seen[a][b] = true
    for k, v in pairs(a) do if not Util.equal(v, b[k], seen) then return false end end
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
