

//-- Save Area - Saves anything in an /area instance. Can be any shape. --------

dmm_suite

	proc/write_area(area/save_area, flags)
		// Cancel out if the area isn't on the map
		if(!(locate(/turf) in save_area.contents))
			return FALSE
		//
		var startZ = save_area.z
		var startY = save_area.y
		var startX = save_area.x
		var endZ = 0
		var endY = 0
		var endX = 0
		for(var/turf/containedTurf in save_area.contents)
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
		var /dmm_suite/comment/mapComment = new(locate(startX, startY, startZ))
		mapComment.coordinates = "[startX],[startY],[startZ]"
		mapComment.dimensions = "[width],[height],[depth]"
		// Create empty cell model
		var emptyCellModel = "[/dmm_suite/clear_turf],[/dmm_suite/clear_area]"
		// Identify all unique grid cells
		// Store template number for each grid cells
		var /list/templates = list(emptyCellModel)
		var emptyCellIndex = templates.Find(emptyCellModel) // Magic numbers already bit me here once. Don't be tempted!
		var /list/templateBuffer = new(width*height*depth)
		for(var/posZ = 0 to depth-1)
			for(var/posY = 0 to height-1)
				for(var/posX = 0 to width-1)
					var /turf/saveTurf = locate(startX+posX, startY+posY, startZ+posZ)
					// Skip out if turf isn't in save area
					if(saveTurf.loc != save_area)
						// Unless it's the comment location
						if(!(posX+posY+posZ))
							var comment_model = "[mapComment.type][checkAttributes(mapComment)],[emptyCellModel]"
							templates.Add(comment_model)
							var compoundIndex = 1 + (posX) + (posY*width) + (posZ*width*height)
							templateBuffer[compoundIndex] = templates.Find(comment_model)
							continue
						//
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