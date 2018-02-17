

//-- Demo ----------------------------------------------------------------------

mob

	verb/write()
		/*
		The write() verb creates a text string of the map in dmm format
		and displays it in the client's browser.
		*/
		var /dmm_suite/suite = new()
		// Write map text from two corners:
		var mapText = suite.write_map(
			locate(1, 1, 1),
			locate(world.maxx, world.maxy, world.maxz),
			DMM_IGNORE_PLAYERS
		)
		// Write map from coordinates and dimensions:
		/*var mapText = suite.write_cube(
			2, 2, 1,
			world.maxx-2, world.maxy-2, 1,
			DMM_IGNORE_PLAYERS
		)*/
		// Write map from area, can be irregularly shaped:
		/*var mapText = suite.write_area(
			locate(/demo/area),
			DMM_IGNORE_PLAYERS
		)*/
		usr << browse("<pre>[mapText]</pre>")

	verb/load(dmm_file as file)
		/*
		The load() verb will ask a player for a dmm file (usually found in the demo
		directory) which it will then load.
		*/
		//Test if dmm_map is a .dmm file.
		var file_name = "[dmm_file]"
		var file_extension = copytext(file_name,length(file_name)-2,0)
		if(file_extension != "dmm")
			usr << "Supplied file must be a .dmm file."
			return
		var /dmm_suite/suite = new()
		var map_text = file2text(dmm_file)
		suite.read_map(map_text, 1, 1, 1)


//-- The rest of this file defines a demo world of uninteresting nonsense ------

world
	mob = /demo/mob
	turf = /demo/turf/water
	maxx = 13
	maxy = 13
	maxz = 1
	New()
		.=..()

demo
	area
		parent_type = /area
		New()
			. = ..()
			tag = "demo_area"

	turf
		parent_type = /turf
		icon = 'demo.dmi'
		icon_state = "grass"
		ledge
			icon_state = "ledge"
			density = 1
		circle
			icon_state = "circle"
			density = 0
		water
			icon_state = "water"

	obj
		parent_type = /obj
		icon = 'demo.dmi'
		var
			test_num = 1
			test_txt = "Test"
		New()
			.=..()
			spawn(1)
				dir = dir
				test_num = rand(0,255)
				test_txt = ascii2text(rand(97,122)) + ascii2text(rand(65,90))
		icon_state = "flowers_yellow"
		red_flowers
			icon_state = "flowers_red"

	mob
		parent_type = /mob
		icon = 'demo.dmi'
		icon_state = "mob_flower"
		var/test_file as file
		New()
			.=..()
			dir = pick(1,4)
			if(rand(0,5) == 5)
				test_file = 'demo.txt'
			var /icon/I = icon(icon)
			I *= rgb(128+rand(0,255), 128+rand(0,255), 128+rand(0,255))
			icon = I
		Login()
			.=..()
			tag = key
			icon_state = "clams"
			icon = initial(icon)
