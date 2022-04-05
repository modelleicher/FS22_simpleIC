-- SimpleIC Animations
-- This is for all animations functions 


simpleIC_animations = {};

function simpleIC_animations.prerequisitesPresent(specializations)
    return true;
end;

function simpleIC_animations.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", simpleIC_animations);
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", simpleIC_animations);	
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", simpleIC_animations);	
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", simpleIC_animations);		
end;

function simpleIC_animations.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setICAnimation", simpleIC_animations.setICAnimation)
	SpecializationUtil.registerFunction(vehicleType, "loadICAnimation", simpleIC_animations.loadICAnimation)
end


-- load saved animation state from savegame
function simpleIC_animations:onPostLoad(savegame)
    local spec = self.spec_simpleIC;
    if  spec ~= nil and spec.hasIC then
      
        -- load stuff from savegame
        if savegame ~= nil then
		
            local xmlFile = savegame.xmlFile.handle;
            
            local i = 1;
            local key1 = savegame.key..".FS22_simpleIC.simpleIC_animations"
            for _, icFunction in pairs(spec.icFunctions) do
                -- load animation state 
                if icFunction.animation ~= nil then
                    local state = getXMLBool(xmlFile, key1..".animation"..i.."#animationState");
                    if state ~= nil then
                        self:setICAnimation(state, i, true)
                    end;
                end;
                i = i+1;
            end;
        end;       
	end;   

end;

-- save current animation state to savegame
function simpleIC_animations:saveToXMLFile(xmlFile, key)
	if self.spec_simpleIC ~= nil and self.spec_simpleIC.hasIC then
		local spec = self.spec_simpleIC;
		
		-- key = ...FS22_simpleIC.simpleIC_animations
		
		local i = 1;
		for _, icFunction in pairs(spec.icFunctions) do
			-- save animations state 
			if icFunction.animation ~= nil then
				setXMLBool(xmlFile.handle, key..".animation"..i.."#animationState", icFunction.animation.currentState);
			end;
			i = i+1;
		end;

	end;
end;

-- synch animation state during joining
function simpleIC_animations:onReadStream(streamId, connection)
	local spec = self.spec_simpleIC
	if spec ~= nil and spec.hasIC then
		if connection:getIsServer() then
			local i = 1
			for _, icFunction in pairs(spec.icFunctions) do
				if icFunction.animation ~= nil then
					local state = streamReadBool(streamId)
					icFunction.animation.currentState = state;
					self:setICAnimation(state, i, true)
				end;	
				i = i+1;
			end;	
		end;
	end;
end
-- synch animation state during joining
function simpleIC_animations:onWriteStream(streamId, connection)
	local spec = self.spec_simpleIC;
	if spec ~= nil and spec.hasIC then
		if not connection:getIsServer() then
			for _, icFunction in pairs(spec.icFunctions) do
				if icFunction.animation ~= nil then
					streamWriteBool(streamId, icFunction.animation.currentState)
				end;
			end;
		end;
	end;
end

-- load animation specific values from XML
function simpleIC_animations:loadICAnimation(key, table)

	local anim = {};
	anim.animationName = getXMLString(self.xmlFile.handle, key.."#animationName");
	if anim.animationName ~= "" and anim.animationName ~= nil then
		
		anim.animationSpeed = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key.."#animationSpeed"), 1);
		anim.sharedAnimation = Utils.getNoNil(getXMLBool(self.xmlFile.handle, key.."#sharedAnimation"), false);
		anim.currentState = false;
		
		if not anim.sharedAnimation then
			self:playAnimation(anim.animationName, -anim.animationSpeed, self:getAnimationTime(anim.animationName), true);
		end;
		
		anim.duration = self:getAnimationDuration(anim.animationName);
		--anim.soundVolumeIncreasePercentage = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key.."#soundVolumeIncreasePercentage"), false);
		
		table.animation = anim;
		return true;
	end;

	return false;
end;

function simpleIC_animations:setICAnimation(wantedState, animationIndex, noEventSend)
    setICAnimationEvent.sendEvent(self, wantedState, animationIndex, noEventSend);
	local animation = self.spec_simpleIC.icFunctions[animationIndex].animation;
	local spec = self.spec_simpleIC;
	
    if wantedState then -- if currentState is true (max) then play animation to min
        self:playAnimation(animation.animationName, animation.animationSpeed, self:getAnimationTime(animation.animationName), true);
        animation.currentState = true;
    else    
        self:playAnimation(animation.animationName, -animation.animationSpeed, self:getAnimationTime(animation.animationName), true);
        animation.currentState = false;	
    end;
	
end;




setICAnimationEvent = {}
local setICAnimationEvent_mt = Class(setICAnimationEvent, Event)

InitEventClass(setICAnimationEvent, "setICAnimationEvent")

function setICAnimationEvent.emptyNew()
	local self = Event.new(setICAnimationEvent_mt)
    self.className = "setICAnimationEvent";
	return self
end

function setICAnimationEvent.new(vehicle, wantedState, animationIndex)
	local self = setICAnimationEvent.emptyNew()
	self.vehicle = vehicle
	self.wantedState = wantedState
	self.animationIndex = animationIndex
	
	return self
end

function setICAnimationEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.wantedState = streamReadBool(streamId)
	self.animationIndex = streamReadUIntN(streamId, 6);

	self:run(connection)
end

function setICAnimationEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.wantedState)
	streamWriteUIntN(streamId, self.animationIndex, 6)	
	
end

function setICAnimationEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setICAnimation(self.wantedState, self.animationIndex, true);
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(setICAnimationEvent.new(self.vehicle, self.wantedState, self.animationIndex), nil, connection, self.vehicle)
	end
end

function setICAnimationEvent.sendEvent(vehicle, wantedState, animationIndex, noEventSend)
	if (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(setICAnimationEvent.new(vehicle, wantedState, animationIndex), nil, nil, vehicle)
		else
			g_client:getServerConnection():sendEvent(setICAnimationEvent.new(vehicle, wantedState, animationIndex))
		end
	end
end


