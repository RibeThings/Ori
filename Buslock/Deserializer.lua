-- Deserializer
local dr = {}

function dr:convertToString(str)
	-- Converts a string, into other string!
	
	-- Example:
	--    "hi" -> "hi"
	--    "hello world" -> "hello world"
	--    "hello\\\"world" -> "hello\\\\\\\"world"
	
	local out = ""
	
	for i = 1, #str do
		local letter = str:sub(i, i)
		
		out = out .. (letter:match('["\\]') and "\\" or "") .. letter
	end
	
	return out
end

function dr:checkForIndex(str)
	-- Checks if a string like "hi" can be used to index tables
	
	-- Example:
	--    "hi" -> true
	--    "15hi lol" -> false
	
	local firstLetter = str:sub(1, 1)
	if not firstLetter:match("[A-Za-z_]") then
		return false
	end
	
	if not str:match("[^0-9A-Za-z]", 2) then
		return false
	end
	
	return true
end

function dr:getInstanceName(obj)
	-- You give him an Instance and it returns a name you can use (used by dr:getPath())
	
	-- Example:
	--   Instance with name "Hello world" -> ["Hello World"], true
	--   Workspace -> workspace
	--   ReplicatedStorage -> game:GetService("ReplicatedStorage")
	
	if self:checkForIndex(obj.Name) then
		return ("[%s]"):format(self:convertToString(obj.Name)), true
	elseif obj.Parent == game then
		return obj == workspace and "workspace" or ('game:GetService("%s")'):format(obj.ClassName)
	else
		return obj.Name
	end
end

function dr:getPath(obj)
	-- You give him an Instance and it returns a path you can use to get that object
	
	-- Example:
	--   Part in workspace -> workspace.Part
	
	local out = {}
	
	while obj do
		local name, nonIndexable = self:getInstanceName(obj)
		table.insert(out, 1, {name = name, nonIndexable = nonIndexable})
		obj = obj.Parent ~= game and obj.Parent
	end
	
	local path = ""
	for i, v in ipairs(out) do
		path = path .. ("%s%s"):format(v.name, ((not v.nonIndexable) and (i ~= #out)) and "." or "")
	end
	
	return path
end

function dr:convertArg(arg, identation)
	-- Converts something into a string
	
	-- Example:
	--   {hi = 3} -> '{["hi"] = 3}'
	
	local argType = (typeof or type)(arg)
	
	identation = identation or 0
	
	-- table
	if argType == "table" then
		-- This uses recursion
		local out = ""
		
		local idenText = ""
		for i = 1, identation + 1 do
			idenText = idenText .. "	"
		end
		
		local argInd = 0
		for i, v in pairs(arg) do
			argInd = argInd + 1
			
			out = out .. ("%s[%s] = %s"):format(
				(argInd ~= 1) and (",\n" .. idenText) or "",	-- 1
				self:convertArg(i),						-- 2
				self:convertArg(v, identation + 1)		-- 3
			)
		end
		
		-- Add the brackets (because 'out' currently has no "{}")
		local big = (argInd > 1 and ("\n"..idenText) or "")
		out = "{" .. big .. out .. big .. "}"
		
		return out
	-- number, boolean, string, nil
	elseif argType == "number" then
		return tostring(arg)
	elseif argType == "boolean" then
		return arg and "true" or "false"
	elseif argType == "string" then
		return '"' .. self:convertToString(arg) .. '"'
	elseif argType == "nil" then
		return "nil"
	-- Instance
	elseif argType == "Instance" then
		return self:getPath(arg)
	-- Color3
	elseif argType == "Color3" then
		return ("Color3.fromRGB(%d, %d, %d)"):format(arg.R * 255, arg.G * 255, arg.B * 255)
	-- Vector3
	elseif argType == "Vector3" then
		return ("Vector3.new(%d, %d, %d)"):format(arg.X, arg.Y, arg.Z)
	-- CFrame
	elseif argType == "CFrame" then
	-- default:
	else
		return ("--[[Unknown '%s': %s]]"):format(argType, tostring(arg))
	end
end

--
return dr
