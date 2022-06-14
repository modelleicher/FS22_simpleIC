-- by modelleicher
-- 13.04.2019

-- Script for Interactive Control. Released on Github January 2020.

-- Version FS22, January 2022 -- First Implementation -- Rework -- First Release on Github April 2022
-- Addition of different modes and settings (big thanks to Wopster for the Menu Attaching Code from ManualAttach)

simpleIC = {};


simpleIC.functionsList = {"Animation"}

function simpleIC.prerequisitesPresent(specializations)
    return true;
end;

function simpleIC.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", simpleIC);	
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", simpleIC);
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", simpleIC);				
end;

function simpleIC.onRegisterActionEvents(self, isActiveForInput, isActiveForInputIgnoreSelection)

	if self.isClient then
		local spec = self.spec_simpleIC;
		
		spec.actionEvents = {}; 
		self:clearActionEventsTable(spec.actionEvents); 


		-- add action events for SimpleIC, only add when active and IC exists in vehicle
		if isActiveForInputIgnoreSelection and spec.hasIC then
		

			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_ONOFF, self, simpleIC.TOGGLE_ONOFF, true, true, false, true, nil);

			-- only add INTERACT_IC_VEHICLE if IC is turned on and inside currently
			if spec.icTurnedOn_inside then
				local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE, self, simpleIC.INTERACT, true, true, false, true, nil);
				g_inputBinding:setActionEventTextVisibility(actionEventId, false);
				spec.interactionButtonActive = true;
			end;

		end;	
	end;
end;

function simpleIC.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "outsideInteractionTriggerCallback", simpleIC.outsideInteractionTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "renderTextAtProjectedPosition", simpleIC.renderTextAtProjectedPosition)
	SpecializationUtil.registerFunction(vehicleType, "checkInteraction", simpleIC.checkInteraction)
	SpecializationUtil.registerFunction(vehicleType, "setICState", simpleIC.setICState)	
	SpecializationUtil.registerFunction(vehicleType, "resetCanBeTriggered", simpleIC.resetCanBeTriggered)
	SpecializationUtil.registerFunction(vehicleType, "doInteraction", simpleIC.doInteraction)
	SpecializationUtil.registerFunction(vehicleType, "isCameraInsideCheck", simpleIC.isCameraInsideCheck)
	SpecializationUtil.registerFunction(vehicleType, "loadICFunctions", simpleIC.loadICFunctions)
	SpecializationUtil.registerFunction(vehicleType, "getICIsActiveOutside", simpleIC.getICIsActiveOutside)
	SpecializationUtil.registerFunction(vehicleType, "getICIsActiveInside", simpleIC.getICIsActiveInside)		
end

function simpleIC:onLoad(savegame)


	-- why this is needed no idea
    --self.setICAnimation = simpleIC_animations.setICAnimation;   	

	self.spec_simpleIC = {};
	
	local spec = self.spec_simpleIC; 
	
	-- for now all we have is animations, no other types of functions 
	spec.icFunctions = {};
	
	-- load IC functions from XML
	for i = 1, #simpleIC.functionsList do
		local path = "vehicle.simpleIC."..string.lower(simpleIC.functionsList[i])
		local func = "loadIC"..simpleIC.functionsList[i]
		self:loadICFunctions(path, self[func])
	end;

	-- only continue if there are any valid IC Functions loaded
	if #spec.icFunctions > 0 then
		spec.hasIC = true;

		-- disable Triggerpoints if invisible, default false
		spec.disableInvisibleTriggers = Utils.getNoNil(getXMLBool(self.xmlFile.handle, "vehicle.simpleIC#disableInvisibleTriggers"), false);

		-- outside interaction trigger, this is used for all outside interactions. On non-drivable this is the only method
		spec.outsideInteractionTrigger = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, "vehicle.simpleIC#outsideInteractionTrigger"), self.i3dMappings);
		spec.playerInOutsideInteractionTrigger = false;
		if spec.outsideInteractionTrigger ~= nil then
			spec.outsideInteractionTriggerId = addTrigger(spec.outsideInteractionTrigger, "outsideInteractionTriggerCallback", self);   
		end;		
		
		-- not used currently
		--spec.interactionMarker = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, "vehicle.simpleIC#interactionMarker"), self.i3dMappings)

		-- max distance from camera to triggerpoint where triggerpoint can be reached
		spec.reachDistance = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, "vehicle.simpleIC#reachDistance"), 1.8)

		-- 
		spec.icTurnedOn_inside = false; 
		spec.icTurnedOn_outside = false;

		spec.icActive_inside = false;
		spec.icActive_outside = false;

		spec.icTurnedOn_inside_backup = false;	
		
		spec.interact_present = false;
		spec.interact_default = false;

		-- timer activation
		spec.timerActivation = false;
		spec.timerActivationTime = 1000; --ms

	end;

	spec.cylinderAnimations = {};
	local c = 0;
	while true do
		local node1 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, "vehicle.simpleIC.cylinderAnimations.cylinder("..c..")#node1"), self.i3dMappings)
		local node2 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, "vehicle.simpleIC.cylinderAnimations.cylinder("..c..")#node2"), self.i3dMappings)
		if node1 ~= nil and node2 ~= nil then
			spec.cylinderAnimations[c+1] = {node1 = node1, node2 = node2}
		else	
			break;
		end;

		c = c + 1;
	end;
end;

function simpleIC:loadICFunctions(keyOrig, loadFunc)
	local spec = self.spec_simpleIC;
	local i = 0;
	while true do
		local icFunction = {};
		local hasFunction = false;
		local key = keyOrig.."("..i..")"

		hasFunction = loadFunc(self, key, icFunction);

		if hasFunction then
			icFunction.currentState = false;
			
			icFunction.inTP = {};
			icFunction.inTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".insideTrigger#triggerPoint"), self.i3dMappings);
			icFunction.inTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key..".insideTrigger#triggerPointSize"), 0.04);
			icFunction.inTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key..".insideTrigger#triggerDistance"), 1);
			
			if icFunction.inTP.triggerPoint == nil then
				icFunction.inTP.triggerPoint_ON = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".insideTrigger#triggerPoint_ON"), self.i3dMappings);
				icFunction.inTP.triggerPoint_OFF = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".insideTrigger#triggerPoint_OFF"), self.i3dMappings);
			end;
			
			icFunction.outTP = {};
			icFunction.outTP.triggerPoint = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".outsideTrigger#triggerPoint"), self.i3dMappings);
			icFunction.outTP.triggerPointRadius = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key..".outsideTrigger#triggerPointSize"), 0.04);
			icFunction.outTP.triggerDistance = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key..".outsideTrigger#triggerDistance"), 1);
		
			if icFunction.outTP.triggerPoint == nil then
				icFunction.outTP.triggerPoint_ON = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".outsideTrigger#triggerPoint_ON"), self.i3dMappings);
				icFunction.outTP.triggerPoint_OFF = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile.handle, key..".outsideTrigger#triggerPoint_OFF"), self.i3dMappings);
			end;
			
			table.insert(spec.icFunctions, icFunction);
		else
			break;
		end;
		i = i+1;
	end;

end;


function simpleIC:onEnterVehicle(isControlling, playerStyle, farmId)
	

	local spec = self.spec_simpleIC;
	if self.spec_enterable ~= nil and spec.hasIC and isControlling then

		-- check if we are currently in an inside camera
		local inside = self:isCameraInsideCheck();
		if inside then
			-- if IC Mode is 1 (always on) or 3 (always on, hover) or 4 (always on, no display) then turn on IC
			local mode = registerSimpleIC.icMode
			if mode == 1 or mode == 3 or mode == 4 then
				-- set IC state, inside, outside, activate
				self:setICState(true, nil, true);
			end;
			-- if IC Mode is 2 (Toggle) set the state to whatever last state was
			if mode == 2 then
				self:setICState(spec.icTurnedOn_inside, false);
			end

		else
			-- if we are not inside, set outside state to last state
			self:setICState(false, spec.icTurnedOn_outside);
		end

		-- also save last camera state regardless
		spec.lastCameraInside = Utils.getNoNil(inside, false);
	end;
end;

function simpleIC:onDelete()
	local spec = self.spec_simpleIC;
	if spec.outsideInteractionTrigger ~= nil then
		removeTrigger(spec.outsideInteractionTrigger)
	end;
end;

function simpleIC:INTERACT(actionName, inputValue)
	if inputValue > 0.5 then
		self.spec_simpleIC.interact_default = true;
		if not self.spec_simpleIC.interact_present then 
			self:doInteraction()
		end;	
	else
		self.spec_simpleIC.interact_default = false;
	end;
end;

function simpleIC:doInteraction()
	local spec = self.spec_simpleIC;

	if spec ~= nil and spec.hasIC then
		local insideActive = self:getICIsActiveInside();
		local outsideActive = self:getICIsActiveOutside();

		if insideActive or outsideActive then
			local i = 1;
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				local state =  nil;
				if icFunction.canBeTriggered_ON then
					state = true;																												
				end;			
				if icFunction.canBeTriggered_OFF then
					state = false;																												
				end;				
				if icFunction.canBeTriggered or state ~= nil then
					for x=1, #simpleIC.functionsList do
						local lower = string.lower(simpleIC.functionsList[x])
						if icFunction[lower] ~= nil then
							local func = "setIC"..simpleIC.functionsList[x];
							if state ~= nil then
								self[func](self, state, i)
							else 
								self[func](self, not icFunction[lower].currentState, i);
							end;
						end
					end;
			
				end;
				i = i+1;
			end;	
		end;
	end;

	-- implement balls
	if self.spec_implementBalls ~= nil then
		local spec1 = self.spec_implementBalls;
		for index, implementJoint in pairs(spec1.implementJoints) do
			if implementJoint.canBeClicked then
				self:setImplementBalls(index)
			end;
		end;
	end;
end

-- returns true if camera is inside, returns false if camera is not inside, returns nil if active camera is nil
function simpleIC:isCameraInsideCheck()
	if self.spec_enterable ~= nil and self.getActiveCamera ~= nil then
		local activeCamera = self:getActiveCamera();
		if activeCamera ~= nil then
			return activeCamera.isInside;
		end;
	end;
	return nil;
end;

function simpleIC:TOGGLE_ONOFF(actionName, inputValue)
	local spec = self.spec_simpleIC;
	if spec ~= nil and spec.hasIC and self.getAttacherVehicle == nil then 

		local inside = self:isCameraInsideCheck();

		-- allow inside toggle only if ic-mode is 2 (toggle)
		if inside and registerSimpleIC.icMode == 2 then 
			if inputValue == 1 then
				self:setICState(not spec.icTurnedOn_inside, nil, true);
			end;
		end;

		-- if camera is not inside, turn outside IC on while button is pressed
		if not inside then
			if inputValue > 0.5 then
				self:setICState(nil, true, true);
			else
				self:setICState(nil, false, true);
			end
		end;

	end;
end;


function simpleIC:setICState(insideStateWanted, outsideStateWanted, turnOnOff)
	local spec = self.spec_simpleIC;
	

	-- turnedOn state only changes if turnOnOff is true, meaning we force a state change via button or other means
	if insideStateWanted ~= nil and turnOnOff then
		spec.icTurnedOn_inside = insideStateWanted;
	end;
	if outsideStateWanted ~= nil and turnOnOff then
		spec.icTurnedOn_outside = outsideStateWanted;
	end;

	-- otherwise we only activate inside or outside depending on turnedOn Values
	spec.icActive_inside = insideStateWanted and spec.icTurnedOn_inside;
	spec.icActive_outside = outsideStateWanted and spec.icTurnedOn_outside;

	-- if inside or outside is active, add INTERACT_IC_VEHICLE, otherwise remove
	if spec.icActive_inside or spec.icActive_outside then
		if not spec.interactionButtonActive then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE, self, simpleIC.INTERACT, true, false, false, true, nil);
			g_inputBinding:setActionEventTextVisibility(actionEventId, false);
			spec.interactionButtonActive = true;
		end;	
	else
		if spec.interactionButtonActive then
			self:removeActionEvent(spec.actionEvents, InputAction.INTERACT_IC_VEHICLE);
			spec.interactionButtonActive = false;
		end;
	end;

	-- if outside is active, deactivate camera
	if spec.icActive_outside then
		g_inputBinding:setShowMouseCursor(true)
		self.spec_enterable.cameras[self.spec_enterable.camIndex].isActivated = false;
	else
		g_inputBinding:setShowMouseCursor(false)
		self.spec_enterable.cameras[self.spec_enterable.camIndex].isActivated = true;		
	end;

end;

function simpleIC:onUpdate(dt)

	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then

		local spec = self.spec_simpleIC;

		if registerSimpleIC.timerActivation ~= spec.timerActivation then
			spec.timerActivation = registerSimpleIC.timerActivation;
		end;
		if registerSimpleIC.timerActivationTime ~= spec.timerActivationTime then
			spec.timerActivationTime = registerSimpleIC.timerActivationTime;
		end;


		if self.spec_simpleIC.playerInOutsideInteractionTrigger then
			self:checkInteraction()
			self:raiseActive() -- keep vehicle awake as long as player is in trigger 
		end;
		
        -- we need to track camera changes from inside to outside and adjust IC accordingly 
		if self:getIsActiveForInput(true) then
			-- if isInside is true and outside turned on or vice versa we changed camera 
			local inside = self:isCameraInsideCheck()

			-- if we toggled from inside to outside, toggle IC active from inside to outside and vice versa
			if inside ~= nil and inside ~= spec.lastCameraInside then 

				-- we set the IC state but we do not force turn on/off so it just gets set to whatever previous state is was
				if not inside then
                    self:setICState(false, spec.icTurnedOn_outside, false);
                else 
                    self:setICState(spec.icTurnedOn_inside, false, false);
				end;

				-- reset inside value
				spec.lastCameraInside = inside;
				-- reset triggerpoints
				self:resetCanBeTriggered();
			end;

			if inside then
				if spec.timerActivation then
					for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
						if icFunction.timerTime ~= nil then
							icFunction.timerTime = icFunction.timerTime - dt;
							if icFunction.timerTime <= 0 then
								self:doInteraction()
								icFunction.timerTime = nil;
							end;
						end;
					end;
				end;
			end;
		end;


		-- cylinder animations
		if #spec.cylinderAnimations > 0 then
			for i=1, #spec.cylinderAnimations do
				local node1 = spec.cylinderAnimations[i].node1;
				local node2 = spec.cylinderAnimations[i].node2;

				local ax, ay, az = getWorldTranslation(node1);
				local bx, by, bz = getWorldTranslation(node2);	
				x, y, z = worldDirectionToLocal(getParent(node1), bx-ax, by-ay, bz-az);

				local ux, uy, uz = localDirectionToWorld(node1, 0,1,0)
				ux, uy, uz = worldDirectionToLocal(getParent(node1), ux, uy, uz)

				setDirection(node1, x, y, z, ux, uy, uz);

				local ax2, ay2, az2 = getWorldTranslation(node2);
				local bx2, by2, bz2 = getWorldTranslation(node1);
				x2, y2, z2 = worldDirectionToLocal(getParent(node2), bx2-ax2, by2-ay2, bz2-az2);
				
				local ux2, uy2, uz2 = localDirectionToWorld(node2, 0,1,0)
				ux2, uy2, uz2 = worldDirectionToLocal(getParent(node2), ux2, uy2, uz2)		
				
				setDirection(node2, x2, y2, z2, ux2, uy2, uz2); 				
			end;
		end;
	end;
end;

function simpleIC:resetCanBeTriggered()
	for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do -- reset all the IC-Functions so they can't be triggered 
		icFunction.canBeTriggered = false;
		icFunction.canBeTriggered_ON = false;
		icFunction.canBeTriggered_OFF = false;
	end;
end;

function simpleIC:onLeaveVehicle(wasControlled)

	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC and wasControlled then
		self:resetCanBeTriggered();
		self.spec_simpleIC.interactionButtonActive = false;
		self:setICState(false, false);
	end;
end;


function simpleIC:outsideInteractionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local spec = self.spec_simpleIC;

	if onEnter and g_currentMission.controlPlayer and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		spec.playerInOutsideInteractionTrigger = true;	
		self:raiseActive()
		spec.actionEvents = {}; -- create actionEvents table since in case we didn't enter the vehicle yet it does not exist 
		self:clearActionEventsTable(spec.actionEvents); -- also clear it for good measure 
		local _ , eventId = self:addActionEvent(spec.actionEvents, InputAction.INTERACT_IC_ONFOOT, self, simpleIC.INTERACT, false, true, false, true);	-- now add the actionEvent 	
	elseif onLeave and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		spec.playerInOutsideInteractionTrigger = false;
		self:removeActionEvent(spec.actionEvents, InputAction.INTERACT_IC_ONFOOT);	-- remove the actionEvent again once we leave the trigger 
	end;
end;

function simpleIC:onDraw()
	self:checkInteraction()
end;

-- returns if IC inside is active depending on if vehicle is active, ic is turned on and ic being active
function simpleIC:getICIsActiveInside()
	local spec = self.spec_simpleIC
	if self:getIsActive() and spec.icTurnedOn_inside and spec.icActive_inside then
		return true;
	end;
	return false;
end;

-- returns if IC outside is active depending on if vehicle and outside IC is active and turned on, or a player is in trigger
function simpleIC:getICIsActiveOutside()
	local spec = self.spec_simpleIC;
	if (self:getIsActive() and spec.icTurnedOn_outside and spec.icActive_outside) or spec.playerInOutsideInteractionTrigger  then
		return true;
	end;
	return false;
end;

function simpleIC:checkInteraction()
	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
		local spec = self.spec_simpleIC;
		
		
		local insideActive = self:getICIsActiveInside();
		local outsideActive = self:getICIsActiveOutside();

		if insideActive or outsideActive then

			-- current render mode
			local mode = registerSimpleIC.icMode
			
			-- render crosshair on the inside only
			if insideActive then 
				renderText(0.5, 0.5, 0.02, "+");
			end;
			
			-- go through all the functions 
			local index = 0;
			for _, icFunction in pairs(spec.icFunctions) do
				index = index + 1;

				-- get inside or outside trigger points depending on if we're inside or outside 
				local tp = icFunction.inTP;
				if outsideActive then
					tp = icFunction.outTP;
				end;
				
				-- check if Triggerpoints aren't nil
				if tp ~= nil and (tp.triggerPoint ~= nil or tp.triggerPoint_ON ~= nil or tp.triggerPoint_OFF ~= nil) then

					-- get current Triggerpoint
					local triggerPoint = {};
					triggerPoint[1] = tp.triggerPoint;

					-- May have multiple TriggerPoints
					if tp.triggerPoint_OFF ~= nil and tp.triggerPoint_ON ~= nil then  
						triggerPoint[2] = tp.triggerPoint_ON;
						triggerPoint[3] = tp.triggerPoint_OFF;
					end;

					-- set it to false by default 
					icFunction.canBeTriggered = false;
					icFunction.canBeTriggered_ON = false;
					icFunction.canBeTriggered_OFF = false;					

					-- cycle through all TriggerPoints
					for index , triggerPoint in pairs(triggerPoint) do 

						-- get visibility of our trigger-point, if it is invisible its deactivated 
						if not spec.disableInvisibleTriggers or (getVisibility(triggerPoint) and spec.disableInvisibleTriggers)  then

							-- get world translation of our trigger point, then project it to the screen 
							local wX, wY, wZ = getWorldTranslation(triggerPoint);
							local cameraNode = 0;
							if spec.playerInOutsideInteractionTrigger then
								cameraNode = g_currentMission.player.cameraNode
							else
								cameraNode = self:getActiveCamera().cameraNode
							end;
							local cX, cY, cZ = getWorldTranslation(cameraNode);
							local x, y, z = project(wX, wY, wZ);
							
							local dist = MathUtil.vector3Length(wX-cX, wY-cY, wZ-cZ); 
							

							if x > 0 and y > 0 and z > 0 then
							
								-- the higher the number the smaller the text should be to keep it the same size in 3d space 
								-- base size is 0.025 
								-- if the number is higher than 1, make smaller
								-- if the number is smaller than 1, make bigger
					
								local size = 0.028 / dist;
									
								-- default posX and posY is 0.5 e.g. middle of the screen for selection 
								local posX, posY, posZ = 0.5, 0.5, 0.5;
								
								-- if we are outside, use mouse position instead
								if outsideActive then
									posX, posY, posZ = g_lastMousePosX, g_lastMousePosY, 0;				
								end;

								-- check if our position is within the position of the triggerRadius
								if posX < (x + tp.triggerPointRadius) and posX > (x - tp.triggerPointRadius) then
									if posY < (y + tp.triggerPointRadius) and posY > (y - tp.triggerPointRadius) then
										if dist < spec.reachDistance or (outsideActive and not spec.playerInOutsideInteractionTrigger) then

											-- can be clicked 
											if index == 1 then -- toggle mark 
												icFunction.canBeTriggered = true;
											elseif index == 2 then -- on mark 
												icFunction.canBeTriggered_ON = true;
											elseif index == 3 then -- off mark 
												icFunction.canBeTriggered_OFF = true;
											end;

											-- only show points in mode 1-3 (always on, button, hover) in inside Mode
											local doRender = true;
											if mode == 4 and insideActive then
												doRender = false;
											end;
											if doRender then
												self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 0, 0)
											end

											-- timer activation
											if spec.timerActivation and icFunction.timerTime == nil then
												icFunction.timerTime = spec.timerActivationTime;
											end;
										end;
									end;
								end;	
								if (index == 1 and not icFunction.canBeTriggered) or (index == 2 and not icFunction.canBeTriggered_ON) or (index == 3 and not icFunction.canBeTriggered_OFF) then

									if spec.timerActivation then
										icFunction.timerTime = nil;
									end;
									
									-- don't render if we are in inside mode and IC-Mode 3 (hover) or 4 (off)
									local doRender = true
									if insideActive and (mode == 3 or mode == 4) then
										doRender = false
									end
									if doRender then
										self:renderTextAtProjectedPosition(x,y,z, "X", size, 1, 1, 1)
									end
								end;
							end;
						end;
					end;
				end;
			end;
		end;
	end;

end;

function simpleIC:renderTextAtProjectedPosition(projectX,projectY,projectZ, text, textSize, r, g, b) 
    if projectX > -1 and projectX < 2 and projectY > -1 and projectY < 2 and projectZ <= 1 then
        setTextAlignment(RenderText.ALIGN_CENTER);
        setTextBold(false);
        setTextColor(r, g, b, 1.0);
        renderText(projectX, projectY, textSize, text);
        setTextAlignment(RenderText.ALIGN_LEFT);
    end
end
