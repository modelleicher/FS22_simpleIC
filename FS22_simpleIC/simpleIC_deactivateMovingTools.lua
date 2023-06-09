-- by modelleicher 
-- part of SimpleIC
-- this disables movingTools according to the disableWhenSimpleICIsActive="true" entry in the XML if SimpleIC is active (e.g. when this script is called)


simpleIC_deactivateMovingTools = {}

-- prepend ourself to loadMovingToolFromXML and prevent loading of that movingTool if it has the disable entry 
function simpleIC_deactivateMovingTools.loadMovingToolFromXML(self, superFunc, xmlFile, key, entry)

	local returnValues = superFunc(self, xmlFile, key, entry)

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	if node ~= nil then
		local disable = getXMLBool(xmlFile.handle, key .. "#disableWhenSimpleICIsActive")
		
		if disable == nil or disable ==  false then
			return superFunc(self, xmlFile, key, entry)
		else
			return false
		end
	end
end
Cylindered.loadMovingToolFromXML = Utils.overwrittenFunction(Cylindered.loadMovingToolFromXML, simpleIC_deactivateMovingTools.loadMovingToolFromXML)