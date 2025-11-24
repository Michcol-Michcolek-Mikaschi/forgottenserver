function onUpdateDatabase()
	print(">> Updating database to version 38 (rename skill_fist to skill_strength)")
	
	-- Check if columns exist
	local result = db.storeQuery("SHOW COLUMNS FROM `players` LIKE 'skill_fist'")
	if result then
		result.free(result)
		
		-- Rename skill_fist to skill_strength
		db.query("ALTER TABLE `players` CHANGE `skill_fist` `skill_strength` int unsigned NOT NULL DEFAULT 10")
		db.query("ALTER TABLE `players` CHANGE `skill_fist_tries` `skill_strength_tries` bigint unsigned NOT NULL DEFAULT 0")
		
		print(">> Database updated successfully to version 38")
	else
		print(">> Columns already renamed or don't exist")
	end
	
	return true
end
