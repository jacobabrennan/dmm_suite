

//-- Save Area - Saves anything in an /area instance. Can be any shape. --------

dmm_suite

	proc/write_area(area/saveArea, flags)
		//
		var startZ = saveArea.z
		var startY = saveArea.y
		var startX = saveArea.x
		var endZ = 0
		var endY = 0
		var endX = 0
		for(var/turf/containedTurf in saveArea.contents)
			if(     containedTurf.z >   endZ)   endZ = containedTurf.z
			else if(containedTurf.z < startZ) startZ = containedTurf.z
			if(     containedTurf.y >   endY)   endY = containedTurf.y
			else if(containedTurf.y < startY) startY = containedTurf.y
			if(     containedTurf.x >   endX)   endX = containedTurf.x
			else if(containedTurf.x < startX) startX = containedTurf.x
		var depth  = (endZ - startZ)+1 // Include first tile, x = 1
		var height = (endY - startY)+1
		var width  = (endX - startX)+1
		// Create dmm_suite comments to store in map file
		var /dmm_suite/comment/mapComment = new()
		mapComment.coordinates = "[startX],[startY],[startZ]"
		mapComment.dimensions = "[width],[height],[depth]"
		var commentModel = "[mapComment.type][checkAttributes(mapComment)]"
		// Create empty cell model
		var emptyCellModel = "[/dmm_suite/clear_turf],[/dmm_suite/clear_area]"
		// Identify all unique grid cells
		// Store template number for each grid cells
		var /list/templates = list(commentModel, emptyCellModel)
		var emptyCellIndex = 2
		var /list/templateBuffer = new(width*height*depth)
		for(var/posZ = 0 to depth-1)
			for(var/posY = 0 to height-1)
				for(var/posX = 0 to width-1)
					var /turf/saveTurf = locate(startX+posX, startY+posY, startZ+posZ)
					// Skip out if turf isn't in save area
					if(saveTurf.loc != saveArea)
						var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
						templateBuffer[compoundIndex] = emptyCellIndex
						continue
					//
					var testTemplate = makeTemplate(saveTurf, flags)
					var templateNumber = templates.Find(testTemplate)
					if(!templateNumber)
						templates.Add(testTemplate)
						templateNumber = templates.len
					var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
					templateBuffer[compoundIndex] = templateNumber
		// Compile List of Keys mapped to Models
		return writeDimensions(startX, startY, startZ, width, height, depth, templates, templateBuffer)