-- SimpleIC Animations
-- This is for all animations functions 


simpleIC_animations = {};

function simpleIC_animations.prerequisitesPresent(specializations)
    return true;
end;

function simpleIC_animations.registerEventListeners(vehicleType)	
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", simpleIC_animations);
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", simpleIC_animations);
	SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", simpleIC_animations);	
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", simpleIC_animations);	
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", simpleIC_animations);		
end;

function simpleIC_animations.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateSoundAttributes", simpleIC_animations.updateSoundAttributes)
	SpecializationUtil.registerFunction(vehicleType, "addSoundChangeIndex", simpleIC_animations.addSoundChangeIndex)
	SpecializationUtil.registerFunction(vehicleType, "setICAnimation", simpleIC_animations.setICAnimation)
	SpecializationUtil.registerFunction(vehicleType, "loadICAnimation", simpleIC_animations.loadICAnimation)
end

function simpleIC_animations:onLoad(savegame)

    
end

-- load saved animation state from savegame
function simpleIC_animations:onPostLoad(savegame)
    local spec = self.spec_simpleIC;
    if  spec ~= nil and spec.hasIC then
        -- variables needed
		spec.soundVolumeIncreasePercentageAll = 1;
		spec.soundChangeIndexList = {};	

        -- back up samples if we are a motorized vehicle for later volume-change
		if self.spec_motorized ~= nil then 
			for i, sample in pairs(self.spec_motorized.samples) do
				sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;		
			end;
			for i, sample in pairs(self.spec_motorized.motorSamples) do
				sample.indoorAttributes.volumeBackup = sample.indoorAttributes.volume;
			end;	
		end;

        -- load stuff from savegame
        if savegame ~= nil then
		
            local xmlFile = savegame.xmlFile.handle;
            
            local i = 1;
            local key1 = savegame.key..".FS22_simpleIC.simpleIC.icFunctions"
            for _, icFunction in pairs(spec.icFunctions) do
                -- load animation state 
                if icFunction.animation ~= nil then
                    local state = getXMLBool(xmlFile, key1..".icFunction"..i.."#animationState");
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
		
		local i = 1;
		local key1 = key..".icFunctions";
		for _, icFunction in pairs(spec.icFunctions) do
			-- save animations state 
			if icFunction.animation ~= nil then
				setXMLBool(xmlFile, key1..".icFunction"..i.."#animationState", icFunction.animation.currentState);
			end;
			i = i+1;
		end;

	end;
end;

-- synch animation state during joining
function simpleIC_animations:onReadStream(streamId, connection)
	local spec = self.simpleIC
	if spec ~= nil and spec.hasIC then
		if connection:getIsServer() then
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				if icFunction.animation ~= nil then
					local state = streamReadBool(streamId)
					icFunction.animation.currentState = state;
				end;	
			end;	
		end;
	end;
end
-- synch animation state during joining
function simpleIC_animations:onWriteStream(streamId, connection)
	local spec = self.simpleIC;
	if spec ~= nil and spec.hasIC then
		if not connection:getIsServer() then
			for _, icFunction in pairs(self.spec_simpleIC.icFunctions) do
				if icFunction.animation ~= nil then
					streamWriteBool(streamId, icFunction.animation.currentState)
				end;
			end;
		end;
	end;
end

-- load animation specific values from XML
function simpleIC_animations:loadICAnimation(key, table)

    print("LOAD STUFF CALL THINGY")

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
		anim.soundVolumeIncreasePercentage = Utils.getNoNil(getXMLFloat(self.xmlFile.handle, key.."#soundVolumeIncreasePercentage"), false);
		
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
		self:addSoundChangeIndex(animationIndex);
    else    
        self:playAnimation(animation.animationName, -animation.animationSpeed, self:getAnimationTime(animation.animationName), true);
        animation.currentState = false;	
		self:addSoundChangeIndex(animationIndex);
    end;
	
	if self.spec_motorized ~= nil then
		spec.soundVolumeIncreasePercentageAll = math.max(1, spec.soundVolumeIncreasePercentageAll);
	end;

end;

-- sound volume needs to change dynamically while the animation is playing 
-- sound volume needs to change globally with multiple animations playing at the same time 
-- so when we activate an animation we add that animation index to a sound update index list 
function simpleIC_animations:addSoundChangeIndex(index)
	if self.spec_motorized ~= nil then
		local animation =  self.spec_simpleIC.icFunctions[index].animation;
		if animation.soundVolumeIncreasePercentage ~= false then -- check if this even has sound change effects 
			-- now add it to the table 
			self.spec_simpleIC.soundChangeIndexList[index] = animation; -- we add it at the index of the animation that way if we try adding the same animation twice it does overwrite itself 
		end;
	end;
end;

-- next we want to run through that list, get the current animation status of that animation and update the sound volume value 
-- if the animation stopped playing, remove it from the list 
function simpleIC_animations:updateSoundAttributes()
	local spec = self.spec_simpleIC;
	local soundVolumeIncreaseAll = 0;
	local updateSound = false;
	for _, animation in pairs(spec.soundChangeIndexList) do
		-- get time
		local animationTime = self:getAnimationTime(animation.animationName);
		-- get current sound volume increase 
		local soundVolumeIncrease = animation.soundVolumeIncreasePercentage * (animationTime ^ 0.5);
		soundVolumeIncreaseAll = soundVolumeIncreaseAll + soundVolumeIncrease;
		if animationTime == 1 or animationTime == 0 then
			animation = nil; -- delete animation from index table if we reached max pos or min pos 
		end;
		updateSound = true;
	end;
	
	if updateSound then
		for i, sample in pairs(self.spec_motorized.samples) do
			sample.indoorAttributes.volume = math.min(sample.indoorAttributes.volumeBackup * (1 + soundVolumeIncreaseAll), sample.outdoorAttributes.volume);
		end;
		for i, sample in pairs(self.spec_motorized.motorSamples) do
			sample.indoorAttributes.volume =  math.min(sample.indoorAttributes.volumeBackup * (1 + soundVolumeIncreaseAll), sample.outdoorAttributes.volume);
		end;	
	end;
end;



setICAnimationEvent = {};
setICAnimationEvent_mt = Class(setICAnimationEvent, Event);
InitEventClass(setICAnimationEvent, "setICAnimationEvent");

function setICAnimationEvent:emptyNew()  
    local self = Event:new(setICAnimationEvent_mt );
    self.className="setICAnimationEvent";
    return self;
end;
function setICAnimationEvent:new(vehicle, wantedState, animationIndex) 
    self.vehicle = vehicle;
	self.wantedState = wantedState;
	self.animationIndex = animationIndex;
    return self;
end;
function setICAnimationEvent:readStream(streamId, connection)  
    self.vehicle = NetworkUtil.readNodeObject(streamId); 
	self.wantedState = streamReadBool(streamId); 
	self.animationIndex = streamReadUIntN(streamId, 6);
    self:run(connection);  
end;
function setICAnimationEvent:writeStream(streamId, connection)   
	NetworkUtil.writeNodeObject(streamId, self.vehicle);   
	streamWriteBool(streamId, self.wantedState ); 
	streamWriteUIntN(streamId, self.animationIndex, 6); 
end;
function setICAnimationEvent:run(connection) 
    self.vehicle:setICAnimation(self.wantedState, self.animationIndex, true);
    if not connection:getIsServer() then  
        g_server:broadcastEvent(setICAnimationEvent:new(self.vehicle, self.wantedState, self.animationIndex), nil, connection, self.object);
    end;
end;
function setICAnimationEvent.sendEvent(vehicle, wantedState, animationIndex, noEventSend) 
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then   
            g_server:broadcastEvent(setICAnimationEvent:new(vehicle, wantedState, animationIndex), nil, nil, vehicle);
        else 
            g_client:getServerConnection():sendEvent(setICAnimationEvent:new(vehicle, wantedState, animationIndex));
        end;
    end;
end;
