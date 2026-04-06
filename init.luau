--!strict
--@author: vynxz777

-- Services:
local CollectionService = game:GetService("CollectionService")

-- Variables:
local Started: boolean = false

local loadedModules: Dictionary<any> = {}

local loadedComponents: Dictionary<any> = {}
local componentsToCreate: { PathParams } = {}

local componentObjects: { [Instance]: any } = {}

-- Structure:
local Loader = {}

-- Types:
export type Loader = typeof(Loader)

export type PathParams = Folder | ModuleScript

type Dictionary<T> = { [string]: T }

-- Functionality:
-- Public:
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

function Loader.AddComponents(...: PathParams)
	assert(Started == false, "Cannot add components after starting")
	assert(next(loadedComponents) == nil, "Components already Created")

	componentsToCreate = { ... }
end

--Private:
function Loader._load(module: ModuleScript)
	assert(module:IsA("ModuleScript"), "Object is not a ModuleScript")

	loadedModules[module.Name] = require(module) :: any
end

function Loader._initializeLoaded(modules: Dictionary<ModuleScript>)
	for _, module in modules do
		if type(module) == "table" and type(module.Init) == "function" then
			module:Init()
		end
	end
end

function Loader._startLoaded(modules: Dictionary<ModuleScript>)
	for _, module in modules do
		if type(module) == "table" and type(module.Start) == "function" then
			task.spawn(function()
				module:Start()
			end)
		end
	end
end

function Loader._addComponents(args: { PathParams })
	Loader._deepSearchCallback(args, function(component: ModuleScript)
		loadedComponents[component.Name] = require(component) :: any
		Loader._initializeComponent(loadedComponents[component.Name])
	end)
end

function Loader._initializeComponent(component: any)
	if type(component) ~= "table" then
		warn("Component has to be a table")
		return
	end

	if type(component.Tag) ~= "string" then
		warn("Component has to have a Tag")
		return
	end

	if type(component.new) ~= "function" then
		warn("Component does not have a constructor")
		return
	end

	local tag: string = component.Tag

	for _, existing: Instance in CollectionService:GetTagged(tag) do
		componentObjects[existing] = component.new(existing)
	end

	CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance: Instance)
		componentObjects[instance] = component.new(instance)
	end)

	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance: Instance)
		if componentObjects[instance] and type(componentObjects[instance].Destroy) == "function" then
			componentObjects[instance]:Destroy()
		end
	end)
end

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
