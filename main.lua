local utf8 = require("utf8")
local tserial = require 'tserial'

function love.load()
	-- Setup the window
	love.window.setTitle( "AudioMixer" )
	love.window.setMode( 750, 800, {resizable=true, vsync=false, minwidth=200, minheight=200} )
	--icon = love.image.newImageData("icon.png")
	--love.window.setIcon(icon)
	love.keyboard.setKeyRepeat(true)
	screenHeight = 800
	screenWidth = 750
	
	-- Setting RootDirectory
	rootDir = love.filesystem.getSourceBaseDirectory()
	success = love.filesystem.mount(rootDir, "Root")

	love.graphics.setBackgroundColor(0,0,0,0)	
	
	mode = "search"
	folders = {}
	tick = 0
	selected = 0
	choice = 0
	searchSpacing = 20
	currentDirectory = 1
	
	--Audio Panel Globals
	layout = {}
	panelWidth = 100
	panelHeight = 150
	volumeX = (panelWidth/4)
	volumeY = ((panelHeight/4)*1.8)
	playX = ((panelWidth/4)*3)
	playY = ((panelHeight/4)*1.8)
	panelSelected = 0
	offX = 0
	offY = 0
	buttonRadius = 20
	startangle = 200
	
	test = ""
	
	
	-- Only check for custom assets if release build
	if love.filesystem.isFused( ) then
		fused = 1
		loadFiles("Root/sounds")
	else
		fused = 0
		--recursiveLoad("sounds")
		loadFiles("sounds")
	end
	
end


function save()
	local randomFilename = "save-" ..os.time() ..".lua"
	local saveFile = love.filesystem.newFile("lastsave.lua")
	--local savetable = layout
	--love.filesystem.write("lastsave.lua",tostring(serialize(savetable)))
	local savetable = TSerial.pack(layout, drop, indent)
	love.filesystem.write(tostring(randomFilename),savetable)
end

function love.filedropped(file)
	mode = "mixer"
	file:open("r")
	local data = file:read()
	layout = TSerial.unpack(data, safe)
	for i = 1,#layout do
		local soundfile = folders[layout[i].folderID].sounds[layout[i].soundID]
		soundfile:setVolume(layout[i].vol/5.3)
	end
end


function love.resize(w,h)
	screenHeight = h
	screenWidth = w
end


function loadFiles(dir)
	loadFolders(dir)
	for i = 1,#folders do
		loadSounds(i)
	end
end

function loadFolders(dir)
	local directoryItems = love.filesystem.getDirectoryItems(dir)
	for i, item in ipairs(directoryItems) do
		local itemInfo = love.filesystem.getInfo(dir .."/" ..item)
		--test = itemInfo.type
		if itemInfo.type == "directory" then
			folders[#folders+1] = {path=dir .."/" ..item,sounds={},soundNames={}}
			loadFolders(dir .."/" ..item)
		end
	end
end

function loadSounds(folderID)
	local folderpath = folders[folderID].path
	local directoryItems = love.filesystem.getDirectoryItems(folderpath)
	for i, item in ipairs(directoryItems) do
		local itemInfo = love.filesystem.getInfo(folderpath .."/" ..item)
		if itemInfo.type == "file" then
			folders[folderID].sounds[#folders[folderID].sounds+1] = love.audio.newSource(folderpath .."/" ..item, "stream")
			folders[folderID].soundNames[#folders[folderID].soundNames+1] = item
		end
	end
end

--old loading code
--[[function loadSounds(folderID)
	local dir = "Root/sounds"
	--assuming that our path is full of lovely files
	local files = love.filesystem.getDirectoryItems(dir)
	for k, file in ipairs(files) do
		sounds[#sounds+1] = love.audio.newSource(dir .."/" ..file, "stream")
		soundNames[#soundNames+1] = file
	end
end

function recursiveLoad(folder)
	local files = love.filesystem.getDirectoryItems(folder)
	for k, fold in ipairs(files) do
		folders[#folders+1] = {path=folder .."/" ..fold,sounds={},soundNames={}}
	end
	for i = 1,#folders do
		testSounds(i)
	end
end


--]]

function randomTick()
	if #layout > 0 then
		for i = 1,#layout do
			local soundfile = folders[layout[i].folderID].sounds[layout[i].soundID]
			--for every panel with Random turned on
			if layout[i].randomToggle == 1 then
				if layout[i].randomSeconds <= 0 then
					layout[i].randomSeconds = math.random(layout[i].randomMin,layout[i].randomMax)
				else
					layout[i].playing = 0
					layout[i].randomSeconds = layout[i].randomSeconds - 1
					if layout[i].randomSeconds <= 0 then
						if layout[i].pitchToggle == 1 then
							local pitch = (math.random(80,120)/100)
							soundfile:setPitch(pitch)
						else
							soundfile:setPitch(1)
						end
						soundfile:stop()
						soundfile:play()
						layout[i].playing = 1
					end
				end
			end
		end
	end
end

function loopMusic()
	if #layout > 0 then
		for i = 1,#layout do
			local source = folders[layout[i].folderID].sounds[layout[i].soundID]
			if layout[i].playing == 1 and layout[i].randomToggle == 0 then
				if not source:isPlaying( ) then
					love.audio.play( source )
				end
			end
		end
	end
end



function love.update(dt)
	tick = tick + dt
	if tick > 1 then
		tick = tick - 1
		randomTick()
		loopMusic()
	end
	if fused == 1 then
		if success then
			--Sounds
			fused = 0
		else 
			fused = 2
		end
	end
	
	local down = love.mouse.isDown(1)
	local x,y = love.mouse.getPosition()
	if down then
		if panelSelected == 0 then
			
		else
			if layout[panelSelected].heavy == 0 then
				layout[panelSelected].posX = x-offX
				layout[panelSelected].posY = y-offY
			else
				--If manipulating Volume Knob
				layout[panelSelected].angle = math.atan2((y-(layout[panelSelected].posY+volumeY)),(x-(layout[panelSelected].posX+volumeX)))
			end
			if layout[panelSelected].angle+3 < 0.2 then
				layout[panelSelected].angle= -3
			end
			if layout[panelSelected].angle+3 > 5.5 then
				layout[panelSelected].angle= 2.5
			end
			local soundfile = folders[layout[panelSelected].folderID].sounds[layout[panelSelected].soundID]
			layout[panelSelected].vol = ((layout[panelSelected].angle+3))
			soundfile:setVolume(layout[panelSelected].vol/5.3)
		end
	end
end

function love.draw()
	if test ~= nil then
		love.graphics.print(test,0,screenHeight-25)
	end
	local entriesPerColumn = math.floor(screenHeight/searchSpacing)-1
	if mode == "search" then
		love.graphics.setColor(1,1,1,1)
		if #folders > 0 then
			for i = 1,(#folders[currentDirectory].sounds) do
				if i < entriesPerColumn then
					love.graphics.print(folders[currentDirectory].soundNames[i],5,(i*searchSpacing)-searchSpacing)
				else
					love.graphics.print(folders[currentDirectory].soundNames[i],(screenWidth/2)+5,((i-entriesPerColumn)*searchSpacing))
				end
			end
			love.graphics.setColor(0.9,0.9,0,1)
			local x,y = love.mouse.getPosition( )
			local highlighted = 0
			--left column
			if x>5 and x<(screenWidth/2)-5 and y<screenHeight-searchSpacing then
				highlighted = math.floor(y/searchSpacing)+1
				if highlighted > #folders[currentDirectory].sounds then
					highlighted = 0
				end
			end
			--right column
			if x>(screenWidth/2)+5 and x<(screenWidth-5) then
				highlighted = math.floor(y/searchSpacing)+entriesPerColumn+1
				if highlighted > #folders[currentDirectory].sounds+1 then
					highlighted = 0
				end
			end
			if highlighted > entriesPerColumn then
				love.graphics.rectangle("line",(screenWidth/2)-5,((highlighted-entriesPerColumn)*searchSpacing)-searchSpacing,(screenWidth/2)-10,searchSpacing)
			end
			if highlighted > 0 and highlighted < entriesPerColumn then
				love.graphics.rectangle("line",5,(highlighted*searchSpacing)-searchSpacing,(screenWidth/2)-10,searchSpacing)
			end
			--Folder Name
			love.graphics.printf(folders[currentDirectory].path,0,screenHeight-searchSpacing,screenWidth,"center")
			--Folder Buttons
			love.graphics.polygon("line",(screenWidth/5)*1,screenHeight-15,((screenWidth/5)*1)+15,(screenHeight-15)-10,((screenWidth/5)*1)+15,(screenHeight-15)+10)
			love.graphics.polygon("line",((screenWidth/5)*4)+15,screenHeight-15,(screenWidth/5)*4,(screenHeight-15)-10,(screenWidth/5)*4,(screenHeight-15)+10)
		end
	end
	if mode == "mixer" then
		if #layout > 0 then
			for i = 1,#layout do
				drawPanel(i)
			end
		end
	end
end

function drawPanel(pNum)
	local nameLength = math.floor(panelWidth / 8)
	local x = layout[pNum].posX
	local y = layout[pNum].posY
	love.graphics.setColor(0.2,0.2,0.2)
	love.graphics.rectangle("fill",x,y,panelWidth,panelHeight)
	love.graphics.setColor(0.4,0.4,0.4)
	love.graphics.rectangle("line",x,y,panelWidth,panelHeight)
	love.graphics.setColor(0.8,0.8,0.8)
	love.graphics.print(string.sub(layout[pNum].name,1,nameLength),x+6,y+12)
	love.graphics.rectangle("line",x+(panelWidth-11),y+1,10,10)
	love.graphics.print("x",x+(panelWidth-9.5),y-2.5)
	
	--red pip
	love.graphics.setColor(0.5,0.0,0.0)
	love.graphics.circle("fill",x+volumeX+(buttonRadius*1.1)*math.cos(((180*math.pi)/180)),y+volumeY+(buttonRadius*1.1)*math.sin(((180*math.pi)/180)),buttonRadius*0.1)
	--Volume button
	love.graphics.setColor(0.8,0.8,0.8)
	love.graphics.circle("line",x+volumeX,y+volumeY,buttonRadius)
	--white volume pip
	local volX = x+volumeX+(buttonRadius*0.8)*math.cos(layout[pNum].angle)
	local volY = y+volumeY+(buttonRadius*0.8)*math.sin(layout[pNum].angle)
	love.graphics.circle("fill",volX,volY,buttonRadius*0.2)
	--volume label
	love.graphics.print("Vol: " ..math.ceil((layout[pNum].vol/5.3)*100),x+6,y+30)
	--play button
	love.graphics.circle("line",x+playX,y+playY,buttonRadius*0.90)
	if layout[pNum].playing == 0 then
		love.graphics.polygon("line", x+playX-6,y+playY-8, x+playX-6,y+playY+8, x+playX+panelWidth*0.08,y+playY)
	else
		love.graphics.rectangle("line", x+playX-8,y+playY-10,5,searchSpacing)
		love.graphics.rectangle("line", x+playX+2.5,y+playY-10,5,searchSpacing)
	end
	--Randomizer
	love.graphics.setColor(0.8,0.8,0.8)
	--button
	love.graphics.circle("line",x+((panelWidth/5)*4),y+((panelHeight/8)*7.2),buttonRadius*0.5)
	--pitch button
	love.graphics.circle("line",x+((panelWidth/5)*4),y+((panelHeight/8)*6),buttonRadius*0.5)
	--textboxes
	love.graphics.print("Rando",x+5,y+(panelHeight/6)*4)
	love.graphics.rectangle("line",x+(panelWidth/10),y+(panelHeight/5)*4.2,(panelWidth/5),searchSpacing)
	love.graphics.rectangle("line",x+(panelWidth/5)*2,y+(panelHeight/5)*4.2,(panelWidth/5),searchSpacing)
	--Text
	love.graphics.print(layout[pNum].randomMin,x+(panelWidth/10)+2,y+(panelHeight/5)*4.2+2)
	love.graphics.print(layout[pNum].randomMax,x+((panelWidth/5)*2)+2,y+((panelHeight/5)*4.2)+2)
	--button
	if layout[pNum].randomToggle == 0 then
		love.graphics.setColor(0.8,0.8,0.8)
	else
		love.graphics.setColor(0.5,0.0,0.0)
	end
	love.graphics.print("R",x+(panelWidth/5)*4-4,y+(panelHeight/7)*6.2-5)
	if layout[pNum].pitchToggle == 0 then
		love.graphics.setColor(0.8,0.8,0.8)
	else
		love.graphics.setColor(0.0,0.0,0.5)
	end
	love.graphics.print("P",x+(panelWidth/5)*4-4,y+(panelHeight/7)*5.1-5)
end

function love.mousepressed(x,y,button)
	if mode == "search" then
		--Folder Controls
		if #folders > 1 then
			if button == 1 then
				if x > (screenWidth/5)*1 and x < ((screenWidth/5)*1)+15 and y > (screenHeight-15)-10 and y < (screenHeight-15)+10 then
					if currentDirectory == 1 then
						currentDirectory = #folders
					else
						currentDirectory = currentDirectory - 1
					end
				end
				if x > (screenWidth/5)*4 and x < ((screenWidth/5)*4)+15 and y > (screenHeight-15)-10 and y < (screenHeight-15)+10 then
					if currentDirectory == #folders then
						currentDirectory = 1
					else
						currentDirectory = currentDirectory + 1
					end
				end
			end
		end
		
		if #folders > 0 then
			local entriesPerColumn = math.floor(screenHeight/searchSpacing)-1
			
			--left column
			if x>5 and x<(screenWidth/2)-5 then
				choice = math.floor(y/searchSpacing)+1
				if choice > #folders[currentDirectory].sounds then
					choice = 0
				end
				if choice > entriesPerColumn-1 then
					choice = 0
				end
			end
			--right column
			if x>(screenWidth/2)+5 and x<(screenWidth-5) then
				choice = math.floor(y/searchSpacing)+entriesPerColumn
				if choice > #folders[currentDirectory].sounds then
					choice = 0
				end
				if choice < entriesPerColumn then
					choice = 0
				end
			end
			
			if choice > 0 and button == 1 then
				if #layout > 0 then
					local matched = 0
					for i = 1,#layout do
						if layout[1].name == folders[currentDirectory].soundNames[i] then
							matched = 1
						end
					end
					if matched == 0 then
						layout[#layout+1] = {name=folders[currentDirectory].soundNames[choice],folderID=currentDirectory,soundID=choice,posX=0,posY=0,vol=0,angle=-3,mute=0,pitchToggle=0,randomToggle=0,randomMin=1,randomMax=3,randomMinSelected=0,randomMaxSelected=0,randomSeconds=0,playing=0,heavy=0}
					end
				else
					layout[#layout+1] = {name=folders[currentDirectory].soundNames[choice],folderID=currentDirectory,soundID=choice,posX=0,posY=0,vol=0,angle=-3,mute=0,pitchToggle=0,randomToggle=0,randomMin=1,randomMax=3,randomMinSelected=0,randomMaxSelected=0,randomSeconds=0,playing=0,heavy=0}
				end
				love.audio.stop()
				mode = "mixer"
				choice = 0
			end
			
			if choice > 0 and button == 2 then
				if folders[currentDirectory].sounds[choice]:isPlaying() then
					love.audio.stop()
				else
					love.audio.play(folders[currentDirectory].sounds[choice])
				end
			end
		end
		
	end
	if mode == "mixer" then
		if #layout > 0 then
			for i = 1,#layout do
				local soundfile = folders[layout[i].folderID].sounds[layout[i].soundID]
				if button == 1 then
					--Check if within a panel's area
					if x >= layout[i].posX and x <= layout[i].posX+panelWidth and y >= layout[i].posY and y <= layout[i].posY+panelHeight then
						panelSelected = i
						offX = x-layout[i].posX
						offY = y-layout[i].posY
						--play/pause button
						--play button
						local distanceCheck = math.sqrt((((x-(layout[i].posX+(playX)))^2)+((y-(layout[i].posY+playY))^2)))
						if distanceCheck <= buttonRadius then
							if layout[i].playing == 1 then
								love.audio.pause(soundfile)
								layout[i].playing = 0
							else
								love.audio.play(soundfile)
								layout[i].playing = 1
							end
						end
						--Volume Button
						local distanceCheck = math.sqrt(((x-(layout[i].posX+volumeX))^2)+((y-(layout[i].posY+volumeY))^2))
						if distanceCheck <= buttonRadius then
							layout[i].heavy = 1
							layout[panelSelected].vol = math.atan2((y-(layout[i].posY+volumeY)),(x-(layout[i].posX+volumeX)))
						else
							layout[i].heavy = 0
						end
						--Pitch Randomizer Button
						local distanceCheck = math.sqrt(((x-(layout[i].posX+((panelWidth/5)*4)))^2)+((y-(layout[i].posY+((panelHeight/8)*6)))^2))
						if distanceCheck <= buttonRadius*0.5 then
							if layout[i].pitchToggle == 1 then
								layout[i].pitchToggle = 0
								layout[i].playing = 0
								soundfile:stop()
							else
								layout[i].pitchToggle = 1
							end
						end
						--Randomizer Button
						local distanceCheck = math.sqrt(((x-(layout[i].posX+((panelWidth/5)*4)))^2)+((y-(layout[i].posY+((panelHeight/8)*7.2)))^2))
						if distanceCheck <= buttonRadius*0.5 then
							if layout[i].randomToggle == 1 then
								layout[i].randomToggle = 0
								layout[i].playing = 0
								soundfile:stop()
							else
								layout[i].randomToggle = 1
							end
						end
						--Randomizer Minimum
						if offY > ((panelHeight/5)*4) and offY < ((panelHeight/5)*4)+searchSpacing and offX > (panelWidth/10) and offX < (panelWidth/10)+(panelWidth/5)then
							layout[i].randomMinSelected = 1
							layout[i].randomToggle = 0
						else
							layout[i].randomMinSelected = 0
						end
							
							--Randomizer Maximum
						if offY > ((panelHeight/5)*4) and offY < ((panelHeight/5)*4)+searchSpacing and offX > (panelWidth/5)*2 and offX < (panelWidth/5)*2+(panelWidth/5) then
							layout[i].randomMaxSelected = 1
							layout[i].randomToggle = 0
						else
							layout[i].randomMaxSelected = 0
						end
						
						--exit button
						if offX > panelWidth-10 and offX < panelWidth and offY <= panelHeight/15 then
							love.audio.stop(soundfile)
							table.remove(layout,i)
							panelSelected = 0
							break
						end
					else
						layout[i].randomMaxSelected = 0
						layout[i].randomMinSelected = 0
					end
				end
			end
		end
	end				
end

function love.mousereleased( x, y, button)
	if mode == "mixer" then
		panelSelected = 0
		offX = 0
		offY = 0
	end
end

function love.textinput(t)
    if #layout > 0 then
		for i = 1,#layout do
			if layout[i].randomMinSelected == 1 then
				layout[i].randomMin = layout[i].randomMin ..t
			end
			if layout[i].randomMaxSelected == 1 then
				layout[i].randomMax = layout[i].randomMax ..t
			end
		end
	end
end

function love.keypressed(key)
	if key == "escape" or key == "tab" then
		if mode == "mixer" then
			mode = "search"
			if #layout > 0 then
				for i = 1,#layout do
					local soundfile = folders[layout[i].folderID].sounds[layout[i].soundID]
					if layout[i].playing == 1 then
						layout[i].playing = 0
						soundfile:stop()
					end		
				end
			end
		end
	end
	if key == "backspace" then
		if #layout > 0 then
			for i = 1,#layout do
				if layout[i].randomMinSelected == 1 then
					-- get the byte offset to the last UTF-8 character in the string.
					local byteoffset = utf8.offset(layout[i].randomMin, -1)

					if byteoffset then
						-- remove the last UTF-8 character.
						-- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
						layout[i].randomMin = string.sub(layout[i].randomMin, 1, byteoffset - 1)
					end
				end
				if layout[i].randomMaxSelected == 1 then
					-- get the byte offset to the last UTF-8 character in the string.
					local byteoffset = utf8.offset(layout[i].randomMax, -1)

					if byteoffset then
						-- remove the last UTF-8 character.
						-- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
						layout[i].randomMax = string.sub(layout[i].randomMax, 1, byteoffset - 1)
					end
				end
			end
		end
	end
	if key == "s" then
		save()
	end
end