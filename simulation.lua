Algorithms = {
	Gillespie = 1,
	Deterministic = 2
}

local function sumArray(arr)
	local sum = 0;
	for q = 1, #arr do
		sum = sum + arr[q];
	end
	return sum;
end

local propensityFuncs = {
	--Basic type, state (idx 2) * param (idx 3)
	function(state, sim, args)
		return state[args[2]] * sim.params[args[3]];
	end,
	function(state,sim,args)
		--Grey arrow, page 16 of the book, thing that depends on the density of infected
		-- (param * state1 * state2) / NumberOfPeopleInState
		-- (idx4 * idx3 * idx2) / Num
		return sim.params[args[4]] * ((state[args[3]] * state[args[2]]) / sumArray(state));
	end
}

local function makeSimulation(stateCount, reactions, params, algorithm, boardSizeX, boardSizeY, populationStartFunc)
	local sim = {}

	sim.stateCount = stateCount;
	sim.reactions = reactions;
	sim.params = params;

	function sim.makeDiseaseState(self,x,y)
		local ret = {};
		for q = 1, self.stateCount do
			ret[q] = 0;
		end
		ret[1] = populationStartFunc(x,y)
		return ret;
	end


	--Initialize the board
	sim.board = {}
	for x = 1, boardSizeX do
		sim.board[x] = {};
		for y = 1, boardSizeY do
			sim.board[x][y] = sim:makeDiseaseState(x,y)
		end
	end

	if algorithm == Algorithms.Deterministic then
		function sim.tick(self)
			if not self then error("Call this function with ':' please") end
			--test firstly on only one cell
			local cell = self.board[1][1];
			local newState = {}
			for q = 1, #cell do
				newState[q] = cell[q]
			end
			for i, v in pairs(self.reactions) do
				local stoichiometry = v[2];
				local magicNumbers = v[1];
				local number = propensityFuncs[magicNumbers[1]](cell, self, magicNumbers);
				newState[stoichiometry[2]] = newState[stoichiometry[2]] + number;
				newState[stoichiometry[1]] = newState[stoichiometry[1]] - number;
			end
			self.board[1][1] = newState;
 
		end
	elseif sim.algorithm == Algorithms.Gillespie then
		function sim.tick(self)
			if not self then error("Call this function with ':' please") end

		end
	end

	return sim;
end

--[[


	--test firstly on only one cell
	local cell = board[1][1];

	local propensity = {
		--Susceptible to infected
		function(state)
			return (infectRate * state[2] * state[1]) / (state[1] + state[2] + state[3]);
		end,
		--infected to recovered
		function()
			return recoveryRate * state[2];
		end,
	}
	--This doesn't need to be so complex, this isn't a chemical simulation people only go from one state to one other state in a 1 to 1 ratio
	--Could just be {1,2},{2,3} read as state 1 goes to state 2
	--stoichiometry[reaction][state]
	local stoichiometry = {
		{-1, 1, 0}, --sus to infected
		{0, -1, 1} -- infected to recoved
	}

	local function normalTick(state)
		local dt = 1;
		local newState = {state[1],state[2],state[3]}
		for i, v in pairs(propensity) do
			local number = v();
			for i2, v2 in pairs(stoichiometry[i]) do
				newState[i2] = newState[i2] + (number * dt * v2);
			end
		end
		return newState;
	end
	board[1][1] = normalTick(board[1][1])
]]

return makeSimulation;