
local makeSimulation = require("simulation")
local ffi = require("ffi")




math.randomseed(os.time());
--Tis an old wives tale
math.random();
math.random();
math.random();

local sizeX = 5;
local sizeY = 5;

local simulations = {
	makeSimulation(3, {
		--First function, 2nd state times 2nd param, goesfrom state 2 to state 3
		{{1,2,2},{2,3}},
		--Second function (more complex), (idx3 * idx2 * idx1) / Num
		--First two states (SI) then first param. goes from S to I (1 to 2) 
		{{2,1,2,1},{1,2}}
	}, {0.5, 0.1}, Algorithms.Gillespie, sizeX, sizeY, function(x,y)
		return 1000
	end),
	makeSimulation(3, {
		--First function, 2nd state times 2nd param, goesfrom state 2 to state 3
		{{1,2,2},{2,3}},
		--Second function (more complex), (idx3 * idx2 * idx1) / Num
		--First two states (SI) then first param. goes from S to I (1 to 2) 
		{{2,1,2,1},{1,2}}
	}, {0.5, 0.1}, Algorithms.DeterministicWithMovement, sizeX, sizeY + 5, function(x,y)
		return 1000
	end)
}

--loggers[###].filename, cellX, cellY, simulation
local loggers = {};


local function getCellState(x,y, sim)
	if x == -1 or y == -1 then return {-1,-1,-1} end
	return sim.board[x][y];
end

local imgui = require "cimgui" -- cimgui is the folder containing the Lua module (the "src" folder in the github repository)

love.load = function()
	love.window.setMode(800* 2,600*2)
	imgui.love.Init() -- or imgui.love.Init("RGBA32") or imgui.love.Init("Alpha8")
end


--Copied a lot of the rest of this from some example to that's why it's the mildy different format

local drawBoxSize = 70;
local drawBoxGap = 3;

local currentCellX = -1
local currentCellY = -1
local currentSim = simulations[1]


local function drawSim(sim, currXStart, currYStart)
	local mouseX, mouseY = love.mouse.getPosition()

	--Draw the board
	local currX = currXStart or 800;
	for x = 1, sim.boardSizeX do
		local currY =  currYStart or 400;
		for y = 1, sim.boardSizeY do
			--Check if the mouse is hovering on this cell
			if mouseX > currX and mouseX < currX + drawBoxSize and mouseY > currY and mouseY < currY + drawBoxSize then
				currentCellX = x;
				currentCellY = y;
				currentSim = sim;
			end
			--Draw the cell
			local cell = sim.board[x][y];
			local sum = 0; for q = 1, #cell do sum = sum + cell[q]; end
			local n = 1 - (cell[2] / (sum/1.2));
			love.graphics.setColor(1, n,n)
			love.graphics.rectangle("fill", currX,currY,drawBoxSize, drawBoxSize)
			love.graphics.setColor(0,0,0)
			love.graphics.print(string.format("%.1f", cell[2]), currX, currY)
			currY = currY + drawBoxSize + drawBoxGap
		end
		currX = currX + drawBoxSize + drawBoxGap
	end
end


local csvNameBuf = ffi.new("char[256]");

love.draw = function()
	love.graphics.setBackgroundColor(88/255, 130/255, 114/255)

	drawSim(simulations[1])
	drawSim(simulations[2], 300, 400)

	--ImGui messes up without this
	love.graphics.setColor(1,1,1)
	imgui.Begin("Window")

	imgui.SetWindowFontScale(1.8)
	imgui.Text("Current Cell: " .. currentCellX .. ", " .. currentCellY)
	local state = getCellState(currentCellX, currentCellY, currentSim);
	imgui.Text("State: " .. table.concat(state, ", "))
	imgui.Text("SimTime: " .. tostring(currentSim.time))
	imgui.InputText("Csv filename", csvNameBuf, 256)
	print(ffi.string(csvNameBuf))
	imgui.Text("Press 'c' to begin output file writing on the current cell")
	

	--Done like this because vscode is silly and turning 'end' into 'End'
	imgui["E" .. "nd"]()
	
	-- code to render imgui
	imgui.Render()
	imgui.love.RenderDrawLists()
end

local wantTickSim = false;


love.update = function(dt)
	imgui.love.Update(dt)
	imgui.NewFrame()

	if wantTickSim then
		for q = 1, #loggers do
			local logger = loggers[q];
			if not logger.initialized then
				
				logger.file = io.open(logger.filename, "w");
				logger.file:write("S,I,R")
				logger.initialized = true;
			end
			local cell = logger.simulation.board[logger.cellX][logger.cellY]
			logger.file:write(string.format("%f,%f,%f\n", cell[1], cell[2], cell[3]))
		end
		currentSim:tick()
		wantTickSim = false;
	end
end

love.mousemoved = function(x, y, ...)
	imgui.love.MouseMoved(x, y)
	if not imgui.love.GetWantCaptureMouse() then
		-- your code here
	end
end

love.mousepressed = function(x, y, button, ...)
	imgui.love.MousePressed(button)
	if not imgui.love.GetWantCaptureMouse() then
		-- your code here 
	end
end

love.mousereleased = function(x, y, button, ...)
	imgui.love.MouseReleased(button)
	if not imgui.love.GetWantCaptureMouse() then
		-- your code here 
	end
end

love.wheelmoved = function(x, y)
	imgui.love.WheelMoved(x, y)
	if not imgui.love.GetWantCaptureMouse() then
		-- your code here 
	end
end

love.keypressed = function(key, ...)
	imgui.love.KeyPressed(key)
	if not imgui.love.GetWantCaptureKeyboard() then
		-- your code here 
		if key == "space" then
			wantTickSim = true;
		elseif key == "i" then
			if currentCellX >= 0 then
				currentSim.board[currentCellX][currentCellY][2] = currentSim.board[currentCellX][currentCellY][2] + 10
				currentSim.board[currentCellX][currentCellY][1] = currentSim.board[currentCellX][currentCellY][1] - 10
			end
		elseif key == "c" then
			if currentCellX >= 0 then
				local logger = {}
				logger.filename = ffi.string(csvNameBuf);
				logger.cellX = currentCellX;
				logger.cellY = currentCellY;
				logger.simulation = currentSim;
				loggers[#loggers+1] = logger;
			end
		end

	end
end

love.keyreleased = function(key, ...)
	imgui.love.KeyReleased(key)
	if not imgui.love.GetWantCaptureKeyboard() then
		-- your code here 
	end
end

love.textinput = function(t)
	imgui.love.TextInput(t)
	if imgui.love.GetWantCaptureKeyboard() then
		-- your code here 
	end
end

love.quit = function()
	return imgui.love.Shutdown()
end

-- for gamepad support also add the following:

love.joystickadded = function(joystick)
	imgui.love.JoystickAdded(joystick)
	-- your code here 
end

love.joystickremoved = function(joystick)
	imgui.love.JoystickRemoved()
	-- your code here 
end

love.gamepadpressed = function(joystick, button)
	imgui.love.GamepadPressed(button)
	-- your code here 
end

love.gamepadreleased = function(joystick, button)
	imgui.love.GamepadReleased(button)
	-- your code here 
end

-- choose threshold for considering analog controllers active, defaults to 0 if unspecified
local threshold = 0.2 

love.gamepadaxis = function(joystick, axis, value)
	imgui.love.GamepadAxis(axis, value, threshold)
	-- your code here 
end