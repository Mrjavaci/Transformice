--[[ Title ]]--
title = {
	[1] = "titre_Title name",
}

--[[ Translations ]]--
system.translation = {
	-- At least EN, BR, ES, FR are needed, complementarily AR, PL, TR, RO, DE, RU
	en = {
		dataTry = "Wait! Your data is loading...",
		dataFail = "Impossible to load your data :( Try again in the next map.",
		dataSuccess = "Data loaded!",
	},
	br = {
		dataTry = "Aguarde! Seus dados estão carregando...",
		dataFail = "Impossível carregar seus dados :( Tente novamente no próximo mapa.",
		dataSuccess = "Dados carregados!",
	},
	es = {
		dataTry = "¡Espera! Tus datos se están cargando...",
		dataFail = "No se pudieron cargar tus datos :( Prueba de nuevo en el siguiente mapa.",
		dataSuccess = "¡Datos cargados!",
	},
	fr = {
		dataTry = "Attends ! Tes données sont en train de charger...",
		dataFail = "Impossible de charger vos données :( Essayez encore lors de la prochaine map.",
		dataSuccess = "Données chargées !",
	},
}
system.translation.pt = system.translation.br

system.community = tfm.get.room.community
if not system.translation[system.community] then
	system.community = "en"
end
system.community = system.translation[system.community]

--[[ Thanks ]]--
system.staff = {
	dev = {"Developer 1"},
	translator = {"Translator 1"},
	artist = {"Artist 1"},
}
for k,v in next,system.staff do
	table.sort(v)
end

--[[ Functions ]]--
	--[[ Data ]]--
serialization = function(i,lastIndex)
	lastIndex = lastIndex or ""
	if type(i) == "table" then
		local out = ""
	
		for k,v in next,i do
			if type(v) == "string" then
				out = out .. string.format("@[%s]{%s}",string.format("%s[%s]",lastIndex,k),table.concat({string.byte(v,1,#v)},","))
			elseif type(v) == "number" then
				out = out .. string.format("#[%s]{%s}",string.format("%s[%s]",lastIndex,k),tostring(v))
			elseif type(v) == "boolean" then
				out = out .. string.format("![%s]{%s}",string.format("%s[%s]",lastIndex,k),tostring(v))
			elseif type(v) == "table" then
				out = out .. serialization(v,string.format("%s[%s]",lastIndex,k))
			end
		end

		return out
	elseif type(i) == "string" then
		local out = {}

		for t,k,v in string.gmatch(i,"([@#!])(%[.-%])%{(.-)%}") do
			print(string.format("%s %s %s",t,k,v))
			local value
			if t == "@" then
				value = string.char((function(bytes)
					local foo = {}
					for byte in string.gmatch(bytes,"[^,]+") do
						foo[#foo + 1] = tonumber(byte)
					end
					return table.unpack(foo)
				end)(v))
			elseif t == "#" then
				value = tonumber(v)
			elseif t == "!" then
				value = (v == "true")
			elseif t == "=" then
				value = serialization(v)
			end
			
			local index = {}
			for j in string.gmatch(k:sub(2,#k-1),"[^%[%]]") do
				index[#index + 1] = tonumber(j) or j
			end

			if #index == 1 then
				out[index[1]] = value
			else
				local m,n = 1
				while m <= #index do
					if not n then
						out[index[m]] = (out[index[m]] or {})
						n = out[index[m]]
						m = m + 1
					end

					n[index[m]] = (m ~= #index and (n[index[m]] or {}) or value)

					n = n[index[m]]
					m = m + 1
				end
			end
		end

		return out
	end
end
eventPlayerDataLoading = function(n,tentative)
	-- Avoids data replacement and error
	if tentative < 4 then
		local loadingData = system.loadPlayerData(n)
		if loadingData then
			tfm.exec.chatMessage("<G>" .. system.community.dataTry,n)
		else
			eventPlayerDataLoading(n,tentative + 1)
		end
	else
		tfm.exec.killPlayer(n)
		tfm.exec.chatMessage("<G>" .. system.community.dataFail,n)
	end
end
eventPlayerDataLoaded = function(n,data)
	if data ~= "" and data:find(":allowTitle") then -- ":allowTitle" refers to the info[playerName].db.allowTitle var
		info[n].db = serialization(data)
	else
		system.savePlayerData(n,serialization(info[n].db))
	end
	
	info[n].dataLoaded = true
	tfm.exec.chatMessage("<G>" .. system.community.dataSuccess,n)
	
	-- TODO Data Loaded
end
system.giveTitle = function(n,id)
	-- Use system.giveTitle instead of system.giveEventGift
	if title[id] and info[n] then
		if info[n].dataLoaded and info[n].db.allowTitle then
			system.giveEventGift(n,title[id])
			info[n].db.allowTitle = false
			system.savePlayerData(n,serialization(info[n].db))
			return true
		end
		return false
	end
	return false
end
			

	--[[ Others ]]--
os.normalizedTime = function(time)
	return math.floor(time) + ((time - math.floor(time)) >= .5 and .5 or 0)
end

--[[ New Game ]]--
info = {} -- Hosts the data of the players
eventNewGame = function()
	-- TODO New Game
	for k,v in next,tfm.get.room.playerList do
		info[k] = {
			-- TODO Data
			dataLoaded = false,

			db = {
				-- TODO Data to Save
				allowTitle = true,
			}
		}
		
		eventPlayerDataLoading(k,1)
	end
end

--[[ Loop ]]--
eventLoop = function(currentTime,timeLeft)
	_G.currentTime = os.normalizedTime(currentTime/1000) -- [Global] Current time in seconds; 0.5 by 0.5
	_G.timeLeft = os.normalizedTime(timeLeft/1000) -- [Global] Time left in seconds; 0.5 by 0.5
	-- TODO Loop
end

--[[ Left ]]--
eventPlayerLeft = function(n)
	if info[n] then
		system.savePlayerData(n,serialization(info[n].db))
	end
end

--[[ Init ]]--
for i,f in next,{"AutoShaman","AfkDeath","AutoTimeLeft","MortCommand","PhysicalConsumables","DebugCommand"} do
	-- Edit the functions
	tfm.exec["disable"..f]()
end

system.map = '<C><P /><Z><S /><D /><O /></Z></C>'
tfm.exec.newGame(system.map)
