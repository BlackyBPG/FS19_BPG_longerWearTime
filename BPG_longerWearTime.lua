-- 
-- Longer wear time for vehicles for FS19
-- by Blacky_BPG
-- 
-- Version: 1.9.0.2      |    06.06.2021    add ExtendedVehicleMaintenance functionality
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
		spec.LongerWearTimeFixedA = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key..".BPG_longerWearTime#isAlreadyFixed"),  spec.LongerWearTimeFixedA)
		spec.LongerWearTimeFixedEVM = Utils.getNoNil(getXMLBool(savegame.xmlFile, savegame.key..".BPG_longerWearTime#isEVMFixed"),  spec.LongerWearTimeFixedEVM)
		spec.LongerWearTimeFixedEVMTimes = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key..".BPG_longerWearTime#timesEVM"),  spec.LongerWearTimeFixedEVMTimes)
	end
end

function BPG_longerWearTime:onLoad(savegame)
	local spec = self.spec_BPG_longerWearTime
	spec.LongerWearTimeCorrected = false
	spec.LongerWearTimeFixed = false
	spec.LongerWearTimeFixedA = false
	spec.LongerWearTimeFixedEVM = false
	spec.LongerWearTimeFixedEVMTimes = 0
	spec.checkTimer = 250
end

function BPG_longerWearTime:saveToXMLFile(xmlFile, key)
	local spec = self.spec_BPG_longerWearTime
	setXMLBool(xmlFile, key.."#isFixed", spec.LongerWearTimeFixed)
	setXMLBool(xmlFile, key.."#isAlreadyFixed", spec.LongerWearTimeFixedA)
	setXMLBool(xmlFile, key.."#isEVMFixed", spec.LongerWearTimeFixedEVM)
	setXMLInt(xmlFile, key.."#timesEVM", spec.LongerWearTimeFixedEVMTimes)
end

function BPG_longerWearTime:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_BPG_longerWearTime
	if self.isServer then
		if spec.checkTimer > 0 then
			spec.checkTimer = spec.checkTimer - dt
			return
		end
		if spec.LongerWearTimeCorrected == false then
			local specW = self.spec_wearable
			if specW ~= nil and specW.wearDuration ~= nil and specW.wearDuration ~= 0 then
				spec.LongerWearTimeCorrected = true
				specW.wearDuration = specW.wearDuration / 7.3 / 2
				if specW.wearableNodes ~= nil then
					if spec.LongerWearTimeFixed == false then
						spec.LongerWearTimeFixed = true
						for _, nodeData in ipairs(specW.wearableNodes) do
							self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) / 7.3)
						end
					end
					if spec.LongerWearTimeFixedA == false then
						spec.LongerWearTimeFixedA = true
						for _, nodeData in ipairs(specW.wearableNodes) do
							self:setNodeWearAmount(nodeData, self:getNodeWearAmount(nodeData) / 2)
						end
					end
				end
			end
			if self.spec_ExtendedVehicleMaintenance ~= nil and self.spec_ExtendedVehicleMaintenance.MaintenanceTimes ~= nil then
				if self.spec_ExtendedVehicleMaintenance.MaintenanceTimes == 0 then
					self.spec_ExtendedVehicleMaintenance.MaintenanceTimes = 1
				end
				self.spec_ExtendedVehicleMaintenance.MaintenanceTimes = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes * 3
				spec.LongerWearTimeFixedEVMTimes = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes
				spec.LongerWearTimeFixedEVM = true
			end
		end
		if self.spec_ExtendedVehicleMaintenance ~= nil and self.spec_ExtendedVehicleMaintenance.MaintenanceTimes ~= nil then
			if spec.LongerWearTimeFixedEVMTimes ~= self.spec_ExtendedVehicleMaintenance.MaintenanceTimes then
				local diff = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes - spec.LongerWearTimeFixedEVMTimes
				self.spec_ExtendedVehicleMaintenance.MaintenanceTimes = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes + (diff * 2)
				spec.LongerWearTimeFixedEVMTimes = self.spec_ExtendedVehicleMaintenance.MaintenanceTimes
			end
		end
	end
end

