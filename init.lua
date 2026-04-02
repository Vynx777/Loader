--!strict
--@author: vynxz777
-- @Variables:

local Loader = {}

local Started: boolean = false

local loadedModules: Dictionary<ModuleScript> = {}

local loadedComponents: Dictionary<ModuleScript> = {}
local componentsToCreate: { PathParams } = {}

-- @Types:

export type Loader = typeof(Loader)

export type PathParams = Folder | ModuleScript

type Dictionary<T> = { [string]: T }

--@Init
--@public
function Loader.Init(...: PathParams)
	assert(Started == false, "Loader already initialized")
	assert(next(loadedModules) == nil, "Loader already initialized")

	Started = true

	local args: { PathParams } = { ... }

	Loader._deepSearchCallback(args, Loader._load)

	Loader._initializeLoaded(loadedModules)

	Loader._startLoaded(loadedModules)

	if next(componentsToCreate) ~= nil then
		Loader._addComponents(componentsToCreate)
	end
end

--@_load
--@private
function Loader._load(module: ModuleScript)
	assert(module:IsA("ModuleScript"), "Object is not a ModuleScript")

	loadedModules[module.Name] = require(module) :: ModuleScript
end

--@_initializeLoaded
--@private
function Loader._initializeLoaded(modules: Dictionary<ModuleScript>)
	for _, module in modules do
		if type(module) == "table" and type(module.Init) == "function" then
			module:Init()
		end
	end
end

--@_startLoaded
--@private
function Loader._startLoaded(modules: Dictionary<ModuleScript>)
	for _, module in modules do
		if type(module) == "table" and type(module.Start) == "function" then
			task.spawn(function()
				module:Start()
			end)
		end
	end
end

--@AddComponents
--@public
function Loader.AddComponents(...: PathParams)
	assert(Started == false, "Cannot add components after starting")
	assert(next(loadedComponents) == nil, "Components already Created")

	componentsToCreate = { ... }
end

--@_addComponents
--@private
function Loader._addComponents(args: { PathParams })
	Loader._deepSearchCallback(args, require)
end

--@_deepSearchCallback
--@private
function Loader._deepSearchCallback(array: { PathParams }, callback: (ModuleScript) -> ())
	for _, object in array do
		if object:IsA("ModuleScript") then
			callback(object)
		end

		local descendants = object:GetDescendants()
		for _, descendant in descendants do
			if descendant:IsA("ModuleScript") then
				callback(descendant)
			end
		end
	end
end

return Loader :: Loader