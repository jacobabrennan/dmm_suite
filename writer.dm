

//-- Writer for saving DMM files at runtime ------------------------------------

dmm_suite

	/*-- writeDimensions -----------------------------
	Generates DMM map text representing a rectangular region defined
	by the provided arguments. Generated map text is ready to be saved
	to file or read into another position on the map.
	*/
	write_map(turf/t1, turf/t2, flags as num)
		//Check for valid turfs.
		if(!isturf(t1) || !isturf(t2))
			CRASH("Invalid arguments supplied to proc write_map, arguments were not turfs.")
		var /turf/lowCorner  = locate(min(t1.x,t2.x), min(t1.y,t2.y), min(t1.z,t2.z))
		var /turf/highCorner = locate(max(t1.x,t2.x), max(t1.y,t2.y), max(t1.z,t2.z))
		var startZ = lowCorner.z
		var startY = lowCorner.y
		var startX = lowCorner.x
		var endZ   = highCorner.z
		var endY   = highCorner.y
		var endX   = highCorner.x
		var depth  = (endZ - startZ)+1 // Include first tile, x = 1
		var height = (endY - startY)+1
		var width  = (endX - startX)+1
		// Create dmm_suite comments to store in map file
		var /dmm_suite/comment/mapComment = new()
		mapComment.coordinates = "[startX],[startY],[startZ]"
		mapComment.dimensions = "[width],[height],[depth]"
		var commentModel = "[mapComment.type][checkAttributes(mapComment)]"
		// Identify all unique grid cells
		// Store template number for each grid cells
		var /list/templates = list(commentModel)
		var /list/templateBuffer = new(width*height*depth)
		for(var/posZ = 0 to depth-1)
			for(var/posY = 0 to height-1)
				for(var/posX = 0 to width-1)
					var /turf/saveTurf = locate(startX+posX, startY+posY, startZ+posZ)
					var testTemplate = makeTemplate(saveTurf, flags)
					var templateNumber = templates.Find(testTemplate)
					if(!templateNumber)
						templates.Add(testTemplate)
						templateNumber = templates.len
					var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
					templateBuffer[compoundIndex] = templateNumber
		// Compile List of Keys mapped to Models
		return writeDimensions(startX, startY, startZ, width, height, depth, templates, templateBuffer)

	/*-- writeDimensions -----------------------------
	Generates DMM map text representing a rectangular region defined
	by the provided arguments. Generated map text is ready to be saved
	to file or read into another position on the map.
	*/
	write_cube(startX as num, startY as num, startZ as num, width as num, height as num, depth as num, flags as num)
		// Create dmm_suite comments to store in map file
		var /dmm_suite/comment/mapComment = new()
		mapComment.coordinates = "[startX],[startY],[startZ]"
		mapComment.dimensions = "[width],[height],[depth]"
		var commentModel = "[mapComment.type][checkAttributes(mapComment)]"
		// Identify all unique grid cells
		// Store template number for each grid cells
		var /list/templates = list(commentModel)
		var /list/templateBuffer = new(width*height*depth)
		for(var/posZ = 0 to depth-1)
			for(var/posY = 0 to height-1)
				for(var/posX = 0 to width-1)
					var /turf/saveTurf = locate(startX+posX, startY+posY, startZ+posZ)
					var testTemplate = makeTemplate(saveTurf, flags)
					var templateNumber = templates.Find(testTemplate)
					if(!templateNumber)
						templates.Add(testTemplate)
						templateNumber = templates.len
					var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
					templateBuffer[compoundIndex] = templateNumber
		// Compile List of Keys mapped to Models
		return writeDimensions(startX, startY, startZ, width, height, depth, templates, templateBuffer)

//-- Text Generating Functions -------------------
dmm_suite/proc

	/*-- writeDimensions -----------------------------
	Generates DMM map text representing a rectangular region defined
	by the provided arguments. Generated map text is ready to be saved
	to file or read into another position on the map.
	*/
	writeDimensions(startX, startY, startZ, width, height, depth, list/templates, list/templateBuffer)
		var dmmText = ""
		// Compile List of Keys mapped to Models
		var keyLength = round/*floor*/(
			1 + log(
				letterDigits.len, max(1, templates.len-1)
			)
		)
		var /list/keys[templates.len]
		for(var/keyPos = 1 to templates.len)
			keys[keyPos] = computeKeyIndex(keyPos, keyLength)
			dmmText += {""[keys[keyPos]]" = ([templates[keyPos]])\n"}
		// Compile Level Grid Text
		for(var/posZ = 0 to depth-1)
			if(posZ)
				dmmText += "\n"
			dmmText += "\n(1,1,[posZ+1]) = {\""
			for(var/posY = height-1 to 0 step -1)
				dmmText += "\n"
				for(var/posX = 0 to width-1)
					var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
					var keyNumber = templateBuffer[compoundIndex]
					var tempKey = keys[keyNumber]
					dmmText += "[tempKey]"
					sleep(-1)
				sleep(-1)
			dmmText += "\n\"}"
			sleep(-1)
		//
		return dmmText

	/*-- makeTemplate --------------------------------
	Generates a DMM model string from all contents of
	a map location. Return value is of the form:
		/mob{name = "value"; name2 = 2},/etc,/turf,/turf,/area
	*/
	makeTemplate(turf/model as turf, flags as num)
		// Add Obj Templates
		var objTemplate = ""
		if(!(flags & DMM_IGNORE_OBJS))
			for(var/obj/O in model.contents)
				if(O.loc != model) continue
				objTemplate += "[O.type][checkAttributes(O)],"
		// Add Mob
		var mobTemplate = ""
		for(var/mob/M in model.contents)
			if(M.loc != model) continue
			if(M.client)
				if(!(flags & DMM_IGNORE_PLAYERS))
					mobTemplate += "[M.type][checkAttributes(M)],"
			else
				if(!(flags & DMM_IGNORE_NPCS))
					mobTemplate += "[M.type][checkAttributes(M)],"
		// Add Turf Template
		var turfTemplate = ""
		if(!(flags & DMM_IGNORE_TURFS))
			for(var/appearance in model.underlays)
				var /mutable_appearance/underlay = new(appearance)
				turfTemplate = "[/dmm_suite/underlay][checkAttributes(underlay)],[turfTemplate]"
			turfTemplate += "[model.type][checkAttributes(model)],"
		else
			turfTemplate = "[/dmm_suite/clear_turf],"
		// Add Area Template
		var areaTemplate = ""
		if(!(flags & DMM_IGNORE_AREAS))
			var /area/mArea = model.loc
			areaTemplate = "[mArea.type][checkAttributes(mArea)]"
		else
			areaTemplate = "[/dmm_suite/clear_area]"
		//
		var template = "[objTemplate][mobTemplate][turfTemplate][areaTemplate]"
		return template

	/*-- checkAttributes -----------------------------
	Generates a DMM string from all the attributes of
	a given atom. Return value is of the form:
		{name = "value"; name2 = 2}
	*/
	checkAttributes(atom/A, underlay)
		var attributesText = ""
		var saving = FALSE
		for(var/V in A.vars)
			sleep(-1)
			// If the Variable isn't changed, or is marked as non-saving
			if(!issaved(A.vars[V]) || A.vars[V] == initial(A.vars[V]))
				continue
			// Format different types of values
			if(istext(A.vars[V])) // Text
				if(saving) attributesText += "; "
				attributesText += {"[V] = "[A.vars[V]]""}
			else if(isnum(A.vars[V]) || ispath(A.vars[V])) // Numbers & Type Paths
				if(saving) attributesText += "; "
				attributesText += {"[V] = [A.vars[V]]"}
			else if(isicon(A.vars[V]) || isfile(A.vars[V])) // Icons & Files
				var filePath = "[A.vars[V]]"
				if(!length(filePath)) continue // Bail on dynamic icons
				if(saving) attributesText += "; "
				attributesText += {"[V] = '[A.vars[V]]'"}
			else // Otherwise, Bail
				continue
			// Add to Attributes
			saving = TRUE
		//
		if(!saving)
			return
		return "{[attributesText]}"

	/*-- computeKeyIndex -----------------------------
	Generates a DMM model index string of given length
	and given index value. Return value is of the form:
		aHc
	*/
	computeKeyIndex(keyIndex, keyLength)
		var key = ""
		var workingDigit = keyIndex-1
		for(var/digitPos = keyLength to 1 step -1)
			var placeValue = round/*floor*/(workingDigit/(letterDigits.len**(digitPos-1)))
			workingDigit-=placeValue*(letterDigits.len**(digitPos-1))
			key += letterDigits[placeValue+1]
		return key
dmm_suite/var
	list/letterDigits = list(
		"a","b","c","d","e",
		"f","g","h","i","j",
		"k","l","m","n","o",
		"p","q","r","s","t",
		"u","v","w","x","y",
		"z",
		"A","B","C","D","E",
		"F","G","H","I","J",
		"K","L","M","N","O",
		"P","Q","R","S","T",
		"U","V","W","X","Y",
		"Z"
	)

//-- Supplemental Writing Objects ----------------------------------------------
