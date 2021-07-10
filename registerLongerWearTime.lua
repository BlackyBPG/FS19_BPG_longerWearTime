-- 
-- Drive distance Vehicle Specilaization
-- by Blacky_BPG
-- 
-- Version: 1.9.0.7      |    08.07.2021    fix damage display for TSX_EnhancedVehicle mod
-- Version: 1.9.0.6      |    07.07.2021    rewrite code for simplified calculation
-- Version: 1.9.0.5      |    27.06.2021    delete log messages
-- Version: 1.9.0.4      |    13.06.2021    correct the calculation value
-- Version: 1.9.0.3      |    08.06.2021    fix ExtendedVehicleMaintenance calculation
-- Version: 1.9.0.2      |    06.06.2021    add ExtendedVehicleMaintenance functionality
-- Version: 1.9.0.1      |    24.05.2021    fix reload bug
-- Version: 1.9.0.0      |    23.05.2021    initial version for FS19
-- 

registerLongerWearTime = {}
registerLongerWearTime.userDir = getUserProfileAppPath()
registerLongerWearTime.version = "1.9.0.7  -  08.07.2021"

if g_specializationManager:getSpecializationByName("BPG_longerWearTime") == nil then
	g_specializationManager:addSpecialization("BPG_longerWearTime", "BPG_longerWearTime", Utils.getFilename("BPG_longerWearTime.lua",  g_currentModDirectory),true , nil)

	local numVehT = 0
	for typeName, typeEntry in pairs(g_vehicleTypeManager:getVehicleTypes()) do
		if SpecializationUtil.hasSpecialization(Wearable, typeEntry.specializations) then
			g_vehicleTypeManager:addSpecialization(typeName, "BPG_longerWearTime")
			numVehT = numVehT + 1
		end
	end
	print(" ++ loading LongerWearTime V "..tostring(registerLongerWearTime.version).." for "..tostring(numVehT).." wearable Vehicletypes")
end
