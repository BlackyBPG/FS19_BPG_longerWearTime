-- 
-- Longer wear time for vehicles for FS19
-- by Blacky_BPG
-- 
-- Version: 1.9.0.8      |    19.07.2021    fix time calculation for extendet maintenance
-- Version: 1.9.0.7      |    08.07.2021    fix damage display for TSX_EnhancedVehicle mod
-- Version: 1.9.0.6      |    07.07.2021    rewrite code for simplified calculation
-- Version: 1.9.0.5      |    27.06.2021    delete log messages
-- Version: 1.9.0.4      |    13.06.2021    correct the calculation value
-- Version: 1.9.0.3      |    08.06.2021    fix ExtendedVehicleMaintenance calculation
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
		spec.LongerWearTimeEVMTimes = Utils.getNoNil(getXMLInt(savegame.xmlFile, savegame.key..".BPG_longerWearTime#maintenanceAmount"),  spec.LongerWearTimeEVMTimes)
		spec.LongerWearTimeNextRepair = Utils.getNoNil(getXMLFloat(savegame.xmlFile, savegame.key..".BPG_longerWearTime#nextRepairBackup"),  spec.LongerWearTimeNextRepair)
	end
end

function BPG_longerWearTime:onLoad(savegame)
	local spec = self.spec_BPG_longerWearTime
	spec.LongerWearTimeEVMTimes = -999
	spec.LongerWearTimeNextRepair = -999
	spec.checkTimer = 500
	spec.wearableNodesBackup = {}
end

function BPG_longerWearTime:saveToXMLFile(xmlFile, key)
	local spec = self.spec_BPG_longerWearTime
	setXMLInt(xmlFile, key.."#maintenanceAmount", spec.LongerWearTimeEVMTimes)
	setXMLFloat(xmlFile, key.."#nextRepairBackup", spec.LongerWearTimeNextRepair)
end

function BPG_longerWearTime:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_BPG_longerWearTime
	local repairValue = -1
	if self.isServer and spec.checkTimer <= 0 then
		spec.checkTimer = 5000
		if self.seasons_getSpecTable ~= nil and self:seasons_getSpecTable("seasonsVehicle") ~= nil then
			local specSS = self:seasons_getSpecTable("seasonsVehicle")
			if spec.LongerWearTimeNextRepair == -999 then
				specSS.nextRepair = specSS.nextRepair + 30 * 60 * 60
				spec.LongerWearTimeNextRepair = specSS.nextRepair
				self:raiseDirtyFlags(specSS.dirtyFlag)
			end
			if spec.LongerWearTimeNextRepair ~= specSS.nextRepair then
				if spec.LongerWearTimeNextRepair > specSS.nextRepair then
					local diff = (spec.LongerWearTimeNextRepair - specSS.nextRepair) / 7.3
					spec.LongerWearTimeNextRepair = spec.LongerWearTimeNextRepair - diff
					specSS.nextRepair = spec.LongerWearTimeNextRepair
				else
					specSS.nextRepair = specSS.nextRepair + 30 * 60 * 60
					spec.LongerWearTimeNextRepair = specSS.nextRepair
				end
				self:raiseDirtyFlags(specSS.dirtyFlag)
			end
			local lastRepair = math.max(0, specSS.nextRepair - (60 * 60 * 60))
			local lastRepairDiff = specSS.nextRepair - lastRepair
			local startOperatingTime = (self:getOperatingTime() / 1000) - lastRepair
			repairValue = math.min(1,startOperatingTime / lastRepairDiff)
		end

		local specEVM = self.spec_ExtendedVehicleMaintenance
		if specEVM ~= nil and specEVM.MaintenanceTimes ~= nil then
			local toHours = (30 * specEVM.MaintenanceTimes) - self:getFormattedOperatingTime() + specEVM.Differenz + specEVM.BackupOperatingTimeXML
			if spec.LongerWearTimeEVMTimes ~= specEVM.MaintenanceTimes then
				if specEVM.MaintenanceTimes > 0 then
					specEVM.MaintenanceTimes = specEVM.MaintenanceTimes + 1
					specEVM.Differenz = self:getFormattedOperatingTime() - (15 * (specEVM.MaintenanceTimes - 1))
					specEVM.DifferenzDays = self.age - (specEVM.SeasonsDays * (specEVM.MaintenanceTimes - 1))
					ExtendedVehicleMaintenenanceEventFinish.sendEvent(self, specEVM.BackupAgeXML, specEVM.BackupOperatingTimeXML, specEVM.MaintenanceTimes, specEVM.Differenz, specEVM.DifferenzDays)
					self:raiseDirtyFlags(specEVM.dirtyFlag)
				end
				toHours = (30 * specEVM.MaintenanceTimes) - self:getFormattedOperatingTime() + specEVM.Differenz + specEVM.BackupOperatingTimeXML
			end
			if toHours < 30 then
				repairValue = math.min(1,1 - (toHours / 30))
			else
				repairValue = 0
				local send = false
				while toHours > 121 do
					send = true
					specEVM.MaintenanceTimes = specEVM.MaintenanceTimes - 1
					specEVM.Differenz = self:getFormattedOperatingTime() - (15 * (specEVM.MaintenanceTimes - 1))
					specEVM.DifferenzDays = self.age - (specEVM.SeasonsDays * (specEVM.MaintenanceTimes - 1))
					toHours = (30 * specEVM.MaintenanceTimes) - self:getFormattedOperatingTime() + specEVM.Differenz + specEVM.BackupOperatingTimeXML
					if toHours < 0 then
						specEVM.MaintenanceTimes = specEVM.MaintenanceTimes + 1
						specEVM.Differenz = self:getFormattedOperatingTime() - (15 * (specEVM.MaintenanceTimes - 1))
						specEVM.DifferenzDays = self.age - (specEVM.SeasonsDays * (specEVM.MaintenanceTimes - 1))
					end
				end
				if send == true then
					ExtendedVehicleMaintenenanceEventFinish.sendEvent(self, specEVM.BackupAgeXML, specEVM.BackupOperatingTimeXML, specEVM.MaintenanceTimes, specEVM.Differenz, specEVM.DifferenzDays)
					self:raiseDirtyFlags(specEVM.dirtyFlag)
				end
				spec.LongerWearTimeEVMTimes = specEVM.MaintenanceTimes
			end
		end
	elseif self.isServer and spec.checkTimer > 0 then
		spec.checkTimer = spec.checkTimer - dt
	end

	local specW = self.spec_wearable
	if specW ~= nil then
		local nodeCount = 0
		local wearAmountAll = 0
		local changed = false
		if specW.wearableNodes ~= nil then
			for id, nodeData in ipairs(specW.wearableNodes) do
				local nodeWear = self:getNodeWearAmount(nodeData)
				if spec.wearableNodesBackup[id] == nil then
					if repairValue > -1 and nodeWear ~= repairValue then
						self:setNodeWearAmount(nodeData, repairValue, true)
						spec.wearableNodesBackup[id] = repairValue
						changed = true
					else
						spec.wearableNodesBackup[id] = nodeWear
					end
				else
					if spec.wearableNodesBackup[id] ~= nodeWear then
						if spec.wearableNodesBackup[id] > nodeWear then
							spec.wearableNodesBackup[id] = nodeWear
						else
							if repairValue > -1 and nodeWear ~= repairValue then
								self:setNodeWearAmount(nodeData, repairValue, true)
								changed = true
							else
								local diff = (nodeWear - spec.wearableNodesBackup[id]) / 7.3
								self:setNodeWearAmount(nodeData, spec.wearableNodesBackup[id] + diff, true)
								changed = true
							end
							spec.wearableNodesBackup[id] = self:getNodeWearAmount(nodeData)
						end
					end
				end
				wearAmountAll = wearAmountAll + self:getNodeWearAmount(nodeData)
				nodeCount = nodeCount + 1
			end
		end
		if nodeCount > 0 then
			local newTotal = wearAmountAll / nodeCount
			if specW.totalAmount ~= newTotal then
				changed = true
			end
			specW.totalAmount = newTotal
			if changed == true then
				self:raiseDirtyFlags(specW.dirtyFlag)
			end
		end
	end
end

