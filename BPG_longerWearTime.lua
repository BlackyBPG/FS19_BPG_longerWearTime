-- 
-- Longer wear time for vehicles for FS19
-- by Blacky_BPG
-- 
-- Version: 1.9.0.1      |    24.05.2021    fix reload bug
-- Version: 1.9.0.0      |    23.05.2021    initial version for FS19
-- 


BPG_longerWearTime = {}
BPG_longerWearTime.modDir = g_currentModDirectory

function BPG_longerWearTime.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Wearable, specializations)
end

function BPG_longerWearTime.registerEventListeners(vehicleType)
	local specFunctions = {	"onPostLoad", "onLoad", "onUpdateTick", }
	for _, specFunction in ipairs(specFunctions) do
		SpecializationUtil.registerEventListener(vehicleType, specFunction, BPG_longerWearTime)
	end
end

function BPG_longerWearTime:onPostLoad(savegame)
	local spec = self.spec_BPG_longerWearTime
	if savegame ~= nil then
		spec.LongerWearTimeFixed = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key..".BPG_longerWearTime#isFixed"),  spec.LongerWearTimeFixed)
	end
end

function BPG_longerWearTime:onLoad(savegame)
	local spec = self.spec_BPG_longerWearTime
	spec.LongerWearTimeCorrected = false
	spec.LongerWearTimeFixed = false
	spec.checkTimer = 250
end

function BPG_longerWearTime:saveToXMLFile(xmlFile, key)
	local spec = self.spec_BPG_longerWearTime
	setXMLBool(xmlFile, key.."#isFixed", spec.LongerWearTimeFixed)
end

function BPG_longerWearTime:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_BPG_longerWearTime
	if self.isServer and spec.LongerWearTimeCorrected == false then
		if spec.checkTimer > 0 then
			spec.checkTimer = spec.checkTimer - dt
			return
		end
		local specW = self.spec_wearable
		if specW ~= nil and specW.wearDuration ~= nil and specW.wearDuration ~= 0 then
			spec.LongerWearTimeCorrected = true
			specW.wearDuration = specW.wearDuration / 7.3
			if specW.wearableNodes ~= nil and spec.LongerWearTimeFixed == false then
				spec.LongerWearTimeFixed = true
				for _, nodeData in ipairs(specW.wearableNodes) do
					self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) / 7.3)
				end
			end
		end
	end
end

