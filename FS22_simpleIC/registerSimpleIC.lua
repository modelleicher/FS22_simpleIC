-- register SimpleIC specializations and add them to all vehicles 
-- add menu points 


-- different modes and settings (big thanks to Wopster for the Menu Attaching Code from ManualAttach)


registerSimpleIC = {};

local modName = g_currentModName;
local modDirectory = g_currentModDirectory;
registerSimpleIC.modDirectory = modDirectory;

-- GUI Stuff 
-- mostly code from ManualAttach by Wopster, thanks for the work & permission to use it! :) 
registerSimpleIC.icMode = 2
registerSimpleIC.icModeBackup = 2

registerSimpleIC.timerActivation = false;
registerSimpleIC.timerActivationState = 2;
registerSimpleIC.timerActivationTime = 2000;
registerSimpleIC.timerActivationTimeState = 4;

function registerSimpleIC.initSimpleICGui(self)
    if not self.initSimpleICGuiDone then
        local target = registerSimpleIC

		-- SimpleIC Mode Settings
        self.simpleIC = self.checkDirt:clone()
        self.simpleIC.target = target
        self.simpleIC.id = "simpleIC"
        self.simpleIC:setCallback("onClickCallback", "onsimpleICModeChanged")

        self.simpleIC.elements[4]:setText(g_i18n:getText("setting_simpleIC"))
        self.simpleIC.elements[6]:setText(g_i18n:getText("toolTip_simpleIC"))

        self.simpleIC:setState(registerSimpleIC.icMode)

        local title = TextElement.new()
        title:applyProfile("settingsMenuSubtitle", true)
        title:setText(g_i18n:getText("title_simpleIC"))

        self.boxLayout:addElement(title)
        self.boxLayout:addElement(self.simpleIC)

		self.simpleIC:setTexts({g_i18n:getText("selection_simpleIC_alwaysOn"), g_i18n:getText("selection_simpleIC_button"), g_i18n:getText("selection_simpleIC_hover"), g_i18n:getText("selection_simpleIC_alwaysOff")})


		-- SimpleIC TimerActivation On/Off
        self.simpleICTimerActivation = self.checkDirt:clone()
        self.simpleICTimerActivation.target = target
        self.simpleICTimerActivation.id = "simpleICTimerActivation"
        self.simpleICTimerActivation:setCallback("onClickCallback", "onsimpleICTimerActivationChanged")

        self.simpleICTimerActivation.elements[4]:setText(g_i18n:getText("setting_simpleICTimerActivation"))
        self.simpleICTimerActivation.elements[6]:setText(g_i18n:getText("toolTip_simpleICTimerActivation"))

        self.simpleICTimerActivation:setState(registerSimpleIC.timerActivationState)

		self.simpleICTimerActivation:setTexts({g_i18n:getText("selection_timerActivation_on"), g_i18n:getText("selection_timerActivation_off")})

        self.boxLayout:addElement(self.simpleICTimerActivation)

		-- SimpleIC TimerActivation On/Off
        self.simpleICTimerActivationTime = self.checkDirt:clone()
        self.simpleICTimerActivationTime.target = target
        self.simpleICTimerActivationTime.id = "simpleICTimerActivationTime"
        self.simpleICTimerActivationTime:setCallback("onClickCallback", "onsimpleICTimerActivationTimeChanged")

        self.simpleICTimerActivationTime.elements[4]:setText(g_i18n:getText("setting_simpleICTimerActivationTime"))
        self.simpleICTimerActivationTime.elements[6]:setText(g_i18n:getText("toolTip_simpleICTimerActivationTime"))

        self.simpleICTimerActivationTime:setState(registerSimpleIC.timerActivationTimeState)	
	
        self.boxLayout:addElement(self.simpleICTimerActivationTime)

		self.simpleICTimerActivationTime:setTexts({g_i18n:getText("selection_timerActivationTime_1"), g_i18n:getText("selection_timerActivationTime_2"), g_i18n:getText("selection_timerActivationTime_3"), g_i18n:getText("selection_timerActivationTime_4"), g_i18n:getText("selection_timerActivationTime_5"), g_i18n:getText("selection_timerActivationTime_6"), g_i18n:getText("selection_timerActivationTime_7")})
			
        self.initSimpleICGuiDone = true
    end
end

function registerSimpleIC.updateSimpleICGui(self)
    if self.initSimpleICGuiDone and self.simpleIC ~= nil then
        self.simpleIC:setState(registerSimpleIC.icMode)
		self.simpleICTimerActivation:setState(registerSimpleIC.timerActivationState)
		self.simpleICTimerActivationTime:setState(registerSimpleIC.timerActivationTimeState)
    end
end

function registerSimpleIC:onsimpleICModeChanged(state)
	self.icMode = state
end

function registerSimpleIC:onsimpleICTimerActivationChanged(state)
	self.timerActivationState = state;
	
	if state == 1 then
		self.timerActivation = true;
	else
		self.timerActivation = false;
	end;
end

function registerSimpleIC:onsimpleICTimerActivationTimeChanged(state)
	if state == 1 then
		self.timerActivationTime = 500;
	elseif state == 2 then
		self.timerActivationTime = 1000;
	elseif state == 3 then
		self.timerActivationTime = 1500;
	elseif state == 4 then
		self.timerActivationTime = 2000;
	elseif state == 5 then
		self.timerActivationTime = 2500;
	elseif state == 6 then
		self.timerActivationTime = 3000;
	elseif state == 7 then
		self.timerActivationTime = 4000;
	end	
	
end
-- GUI End

function init()
	-- GUI Buttons stuff
    InGameMenuGameSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuGameSettingsFrame.onFrameOpen, registerSimpleIC.initSimpleICGui)
    InGameMenuGameSettingsFrame.updateGameSettings = Utils.appendedFunction(InGameMenuGameSettingsFrame.updateGameSettings, registerSimpleIC.updateSimpleICGui)	
end

-- add specializations to vehicleTypes 
function registerSimpleIC:register(name)
	
	-- make sure this only runs once since typeManager runce twice (vehicle and placeables)
    if registerSimpleIC.installed == nil then
	
		-- add/register specializations 
		g_specializationManager:addSpecialization("simpleIC_animations", "simpleIC_animations", modDirectory.."simpleIC_animations.lua", nil)
		g_specializationManager:addSpecialization("simpleIC", "simpleIC", modDirectory.."simpleIC.lua", nil)
		g_specializationManager:addSpecialization("simpleIC_implementBalls", "simpleIC_implementBalls", modDirectory.."simpleIC_implementBalls.lua", nil)
		
		-- cycle vehicleTypes, add specs 
		for _, vehicle in pairs(g_vehicleTypeManager:getTypes()) do
			
			local simpleIC = false;
			local attachable = false;
			
			for _, spec in pairs(vehicle.specializationNames) do
				if spec == "FS22_simpleIC.simpleIC" then 
					simpleIC = true;
				end
				if spec == "attachable" then
					attachable = true;
				end;
			end    
			if not simpleIC then
				g_vehicleTypeManager:addSpecialization(vehicle.name, "FS22_simpleIC.simpleIC_animations")
				g_vehicleTypeManager:addSpecialization(vehicle.name, "FS22_simpleIC.simpleIC")
			end
			if attachable then
				g_vehicleTypeManager:addSpecialization(vehicle.name, "FS22_simpleIC.simpleIC_implementBalls")
			end

		end
		registerSimpleIC.installed = true
	end
end

TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, registerSimpleIC.register)

init()
-- TO DO:: I'm not sure if this does anything in FS22. The Issue with double mapping seems to persist though so I leave this in for now.
-- FIX for double-mapping of mouse buttons by Stephan-S
function registerSimpleIC:mouseEvent(posX, posY, isDown, isUp, button)
	if isUp or isDown then
		--Check if this is the key assigned to INTERACT
		local action = g_inputBinding:getActionByName("INTERACT_IC_VEHICLE");
		for _, binding in ipairs(action.bindings) do
			if binding.axisNames[1] ~= nil and binding.axisNames[1] == Input.mouseButtonIdToIdName[button] then
				local vehicle = g_currentMission.controlledVehicle
				if vehicle ~= nil and vehicle.spec_simpleIC ~= nil then
					if isDown then
						vehicle.spec_simpleIC.interact_present = true;
						if not vehicle.spec_simpleIC.interact_default then
							vehicle:doInteraction()
						end;
					elseif isUp then
						vehicle.spec_simpleIC.interact_present = false;
					end
				end			
			end
		end	
	end;
end;

-- Implement Balls Player finding stuff 
function registerSimpleIC:update(dt)
	if g_currentMission.simpleIC_implementBalls ~= nil then -- check if we have implementBalls active 
		--print("simpleIC_implementBalls not nil")
		if g_currentMission.controlPlayer and g_currentMission.player ~= nil and not g_gui:getIsGuiVisible() then -- check if we are the player and no GUI is open
			--print("run player")
			local x, y, z = getWorldTranslation(g_currentMission.player.rootNode); -- get player pos 
			for index, spec in pairs(g_currentMission.simpleIC_implementBalls) do -- run through all implementBalls specs
				for _, implementJoint in pairs(spec.implementJoints) do -- run through all inputAttachers with implement type of this spec 
					local aX, aY, aZ = getWorldTranslation(implementJoint.node) -- get pos of implement joint node 

					local distance = MathUtil.vector3Length(x - aX, y - aY, z - aZ); -- get distance to player 

					--print("distance: "..tostring(distance))
					
					if distance < spec.maxDistance then -- if we're close enough activate stuffs 
						-- if we're in distance, show the X and activate inputBinding
						implementJoint.showX = true;
						spec.vehicle:raiseActive()

						if not spec.isInputActive then
							local specSIC = spec.vehicle.spec_simpleIC;
							specSIC.actionEvents = {}; -- create actionEvents table since in case we didn't enter the vehicle yet it does not exist 
							spec.vehicle:clearActionEventsTable(specSIC.actionEvents); -- also clear it for good measure 
							local _ , eventId = spec.vehicle:addActionEvent(specSIC.actionEvents, InputAction.INTERACT_IC_ONFOOT, spec.vehicle, simpleIC.INTERACT, false, true, false, true);	-- now add the actionEvent 	
							spec.isInputActive = true;
						end;					
					else
						if spec.isInputActive then
							spec.vehicle:removeActionEvent(spec.vehicle.spec_simpleIC.actionEvents, InputAction.INTERACT_IC_ONFOOT);
							spec.isInputActive = false;
							implementJoint.showX = false;
						end;
					end;	
				end;	
			end;
		end;
	end;

end;

addModEventListener(registerSimpleIC)