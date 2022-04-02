-- by modelleicher
-- www.ls-modcompany.com
-- Part of SimpleIC global script. Global script that adds the ability to right-click on a implement attacher to add balls.

simpleIC_implementBalls = {};


function simpleIC_implementBalls.prerequisitesPresent(specializations)
    return true;
end;

function simpleIC_implementBalls.registerEventListeners(vehicleType)	
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", simpleIC_implementBalls);	
    SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", simpleIC_implementBalls);		  	
    SpecializationUtil.registerEventListener(vehicleType, "onDelete", simpleIC_implementBalls);	
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", simpleIC_implementBalls);	      
    SpecializationUtil.registerEventListener(vehicleType, "saveToXMLFile", simpleIC_implementBalls);	 
    SpecializationUtil.registerEventListener(vehicleType, "onReadStream", simpleIC_implementBalls);	
    SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", simpleIC_implementBalls);	       	 	
end;

function simpleIC_implementBalls:onLoad(savegame)
    self.setImplementBalls = simpleIC_implementBalls.setImplementBalls
    if  g_currentMission.simpleIC_implementBalls == nil then   
        g_currentMission.simpleIC_implementBalls = {};
    end;

    self.spec_implementBalls = {}
    local spec = self.spec_implementBalls;
    local i3dFilename = registerSimpleIC.modDirectory.."data/weightSetBall.i3d"

    local ballI3d = g_i3DManager:loadSharedI3DFile(i3dFilename, self.baseDirectory, false, false, false)

    spec.leftNode = I3DUtil.indexToObject(ballI3d, "0", self.i3dMappings)
    spec.rightNode = I3DUtil.indexToObject(ballI3d, "1", self.i3dMappings)

    spec.maxDistance = 1.4;
    -- check if we have a implement attacher joint 
    if self.spec_attachable.inputAttacherJoints ~= nil then
        local jointTypeWant = AttacherJoints.jointTypeNameToInt["implement"]
        spec.implementJoints = {};
        for _ , inputAttacherJoint in pairs(self.spec_attachable.inputAttacherJoints) do
            if inputAttacherJoint.jointType == jointTypeWant and inputAttacherJoint.node ~= nil then 
                inputAttacherJoint.showBalls = false;
                spec.implementJoints[#spec.implementJoints+1] = inputAttacherJoint;
            end;
        end;
        if #spec.implementJoints < 1 then
            spec = nil;
        else
            spec.vehicle = self;
            table.insert(g_currentMission.simpleIC_implementBalls, spec)
        end;
    end;

end;

function simpleIC_implementBalls:onDelete()
	local spec = self.spec_implementBalls;
    if spec ~= nil then
        for index, specFind in pairs(g_currentMission.simpleIC_implementBalls) do
            if specFind == spec then
                table.remove(g_currentMission.simpleIC_implementBalls, index)
            end;
        end;
		spec = nil;
	end;
end;


function simpleIC_implementBalls:onUpdateTick(dt)
    local spec = self.spec_implementBalls;
    for _, implementJoint in pairs(spec.implementJoints) do
        if implementJoint.showX then
            local aX, aY, aZ = getWorldTranslation(implementJoint.node)
            local x, y, z = project(aX, aY, aZ);

            cameraNode = g_currentMission.player.cameraNode

            local cX, cY, cZ = getWorldTranslation(cameraNode);
            local dist = MathUtil.vector3Length(aX-cX, aY-cY, aZ-cZ); 
            local size = 0.028 / dist;

            local posX, posY, posZ = 0.5, 0.5, 0.5;
            local radius = 0.03;

            if posX < (x + radius) and posX > (x - radius) then
                if posY < (y + radius) and posY > (y - radius) then
                    self:renderTextAtProjectedPosition(x ,y ,z, "X", size, 1, 0, 0)
                    implementJoint.canBeClicked = true;
                end;
            else
                self:renderTextAtProjectedPosition(x ,y ,z, "X", size, 1, 1, 1)
                implementJoint.canBeClicked = false;
            end;
        end;
    end;
end;

function simpleIC_implementBalls:setImplementBalls(index, forceState, noEventSend)
    local spec = self.spec_implementBalls;
    if spec.implementJoints[index] ~= nil then
        spec.implementJoints[index].showBalls = Utils.getNoNil(forceState, not spec.implementJoints[index].showBalls);
        setICImplementBallsEvent.sendEvent(self, spec.implementJoints[index].showBalls, index, noEventSend);

        if spec.implementJoints[index].showBalls then
            link(spec.implementJoints[index].node, spec.leftNode)
            link(spec.implementJoints[index].node, spec.rightNode)
            setTranslation(spec.leftNode, 0, 0, -0.432)
            setTranslation(spec.rightNode, 0, 0, 0.432)
            setRotation(spec.leftNode, 0, math.rad(90), 0)
            setRotation(spec.rightNode, 0, math.rad(90), 0)
        else
            unlink(spec.leftNode)
            unlink(spec.rightNode)
        end;
    end;
end;

function simpleIC_implementBalls:onPostLoad(savegame)
	if self.spec_implementBalls ~= nil and savegame ~= nil then
		local spec = self.spec_implementBalls;
		local xmlFile = savegame.xmlFile.handle;
		

        local key1 = savegame.key..".FS19_simpleIC.simpleIC_implementBalls"
		for i, implementJoint in pairs(spec.implementJoints) do
			-- load ball state
			if implementJoint.showBalls ~= nil then
				local state = getXMLBool(xmlFile, key1..".implementBall"..i.."#state");
				if state ~= nil then
					self:setImplementBalls(i, state)
				end;
			end;
		end;
	end;
end;

function simpleIC_implementBalls:saveToXMLFile(xmlFile, key)
	if self.spec_implementBalls ~= nil then
		local spec = self.spec_implementBalls;
		
		for i, implementJoint in pairs(spec.implementJoints) do
			-- save ball state
			if implementJoint.showBalls ~= nil then
				setXMLBool(xmlFile.handle, key..".implementBall"..i.."#state", implementJoint.showBalls);
			end;
		end;

	end;
end;

function simpleIC_implementBalls:onReadStream(streamId, connection)
	local spec = self.spec_implementBalls
	if spec ~= nil then
        if connection:getIsServer() then
			for i, implementJoint in pairs(spec.implementJoints) do
                local state = streamReadBool(streamId, implementJoint.showBalls)
                if state ~= nil then
                    self:setImplementBalls(i, state)
                end;
			end;	
		end;
	end;
end

function simpleIC_implementBalls:onWriteStream(streamId, connection)
	local spec = self.spec_implementBalls;
	if spec ~= nil then
		if not connection:getIsServer() then
			for _, implementJoint in pairs(spec.implementJoints) do
				streamWriteBool(streamId, implementJoint.showBalls)
			end;
		end;
	end;
end



setICImplementBallsEvent = {};
setICImplementBallsEvent_mt = Class(setICImplementBallsEvent, Event);
InitEventClass(setICImplementBallsEvent, "setICImplementBallsEvent");

function setICImplementBallsEvent:emptyNew()  
    local self = Event:new(setICImplementBallsEvent_mt );
    self.className="setICImplementBallsEvent";
    return self;
end;
function setICImplementBallsEvent:new(vehicle, state, ballIndex, animationIndex) 
    self.vehicle = vehicle;
    self.state = state;
    self.ballIndex = Utils.getNoNil(ballIndex, 1);
    return self;
end;
function setICImplementBallsEvent:readStream(streamId, connection)  
    self.vehicle = NetworkUtil.readNodeObject(streamId); 
	self.state = streamReadBool(streamId); 
	self.ballIndex = streamReadUIntN(streamId, 6);
    self:run(connection);  
end;
function setICImplementBallsEvent:writeStream(streamId, connection)   
	NetworkUtil.writeNodeObject(streamId, self.vehicle);   
    streamWriteBool(streamId, self.state ); 
    streamWriteUIntN(streamId, self.ballIndex, 6); 
end;
function setICImplementBallsEvent:run(connection) 
    if self.vehicle ~= nil then
        self.vehicle:setImplementBalls(self.ballIndex, self.state, true);
    end;
    if not connection:getIsServer() then  
        g_server:broadcastEvent(setICImplementBallsEvent:new(self.vehicle, self.state, self.ballIndex), nil, connection, self.object);
    end;
end;
function setICImplementBallsEvent.sendEvent(vehicle, state, ballIndex, noEventSend) 
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then   
            g_server:broadcastEvent(setICImplementBallsEvent:new(vehicle, state, ballIndex), nil, nil, vehicle);
        else 
            g_client:getServerConnection():sendEvent(setICImplementBallsEvent:new(vehicle, state, ballIndex));
        end;
    end;
end;