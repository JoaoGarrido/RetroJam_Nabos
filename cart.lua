-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

----------------
--CODE FROM HERE
t=0

-- game_state:
	--0 -> Game scene
	--1 -> Shop

	--2 -> Menu
--running_state: 0->paused | 1->running
--level: level-identifier

state_vars = {game_state = 0, running_state = 1, level = 0}


--Menu 
Menu_enum = {"Game scene", "Shop", "New game"}

function Menu_enum.update()	
	if (state_vars.game_state == 0) then
		
		if(keyp(49))	then --TAB to change to Shop
			state_vars.game_state = 1
		elseif (keyp(16)) then --P for pause
			state_vars.running_state = (state_vars.running_state + 1) % 2
		end
	
	elseif (state_vars.game_state == 1) then

		if(keyp(49)) then --TAB to change to GameScene 
			state_vars.game_state = 0
		end

	end
end

function Menu_enum.draw()
	if (state_vars.game_state == 0) then

		print(Menu_enum[1],20, 5)
		if(state_vars.running_state == 0) then
			print("PAUSED", 30, 20)
		end
	elseif (state_vars.game_state == 1) then
	
		print(Menu_enum[2],20, 5)

	end
end


--CODE UNTIL HERE
------------------------

Engine = {_init = {}, _update = {Menu_enum.update}, _draw = {Menu_enum.draw}, _uidraw = {}}

function Engine:init()
	if self._init == nil then
		return
	end
	for i=1,#self._init do
		self._init[i]()
	end
end

function Engine:update()
	if self._update == nil then return end
	
	for i = 1, #self._update do
		self._update[i]() 
	end
end

function Engine:draw()
	cls(13)
	--map((Level.LevelNumber%8)*30,  Level.reflected*17 + Level.LevelNumber//8*34)
	if self._draw == nil then
		return
	end
	for i = 1, #self._draw do
		self._draw[i]()
	end
end

function Engine:uidraw()
	if UIENABLED then
		if self._uidraw == nil then
			return
		end
		for i = 1, #self._uidraw do
			self._uidraw[i]()
		end
	end
end

function Engine:onCicleEnd()
	--debug()
	--Atualização de variáveis
	t=t+1
end

function TIC()
	if(t == 0) then
		Engine:init()
	end	
	Engine:update()
	Engine:draw()
	--Engine:uidraw()
	Engine:onCicleEnd()
end

-- <TILES>
-- 001:eccccccccc888888caaaaaaaca888888cacccccccacc2ccccacc2ccccacc2ccc
-- 002:ccccceee8888cceeaaaa0cee888a0ceeccca0ccc2cca0c0c2cca0c0c2cca0c0c
-- 003:eccccccccc888888caaaaaaaca888888cacccccccacccccccacc0ccccacc0ccc
-- 004:ccccceee8888cceeaaaa0cee888a0ceeccca0cccccca0c0c0cca0c0c0cca0c0c
-- 017:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 018:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- 019:cacccccccaaaaaaacaaacaaacaaaaccccaaaaaaac8888888cc000cccecccccec
-- 020:ccca00ccaaaa0ccecaaa0ceeaaaa0ceeaaaa0cee8888ccee000cceeecccceeee
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

