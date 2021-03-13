-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

----------------------------------------------------------------------------------------------------------------------------------------
--CODE FROM HERE------------------------------------------------------------------------------------------------------------------------
t = 0
UIENABLED = 1


--Sky color offset----------------------------------------

middayOffset = {-0x43, -0x5A, -0x0D}
sunsetOffset = {0xCF, -0x40, -0xBA}
currDayStage = -8
function changePallette(targetDayStage)-- -8 is morning (regular colors) 0 midday 7 is sunset
    while currDayStage > targetDayStage and currDayStage > -7 do
        if currDayStage > 0 then --[0:7]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) - (sunsetOffset[1] / 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) - (sunsetOffset[2] / 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) - (sunsetOffset[3] / 8))
        elseif currDayStage > -8 then --[-8 : -1]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) - (middayOffset[1] / 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) - (middayOffset[2] / 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) - (middayOffset[3] / 8))
        end
        currDayStage = currDayStage - 1
    end

    while currDayStage < targetDayStage and currDayStage < 6 do
        if currDayStage < 0 then --[-8:-1]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) + (middayOffset[1] / 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) + (middayOffset[2] / 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) + (middayOffset[3] / 8))
        elseif currDayStage < 7 then --[0-7]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) + (sunsetOffset[1] / 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) + (sunsetOffset[2] / 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) + (sunsetOffset[3] / 8))
        end
        currDayStage = currDayStage + 1
    end

    targetDayStage = currDayStage
end

targetDayStage = -8
function skyUpdate()
    if keyp(61) then --7
        targetDayStage = currDayStage + 1
        changePallette(targetDayStage)
    elseif keyp(60) then
        targetDayStage = currDayStage - 1
        changePallette(targetDayStage)
    end    
end

--Menu----------------------------------------

-- game_state:
	--0 -> Game scene
	--1 -> Shop

	--2 -> Menu
--running_state: 0->paused | 1->running
--level: level-identifier
state_vars = {game_state = 0, running_state = 1, level = 0}

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

function PauseMenu()
    rect(60, 34, 120, 68, 3) --menu background -- brown?
    rectb(60, 34, 120, 68, 4) --menu border --white
    print("PAUSED", 102, 50)
    unpauseMess = "Press 'p' to unpause"
    print(unpauseMess, 120 - ((#unpauseMess-2) * 3), 78)
end

--Duel mechanics------------------------------------------------------
--Player----------------------------------------

Player = {enabled = 1, reactionSpeed = 0, fireState = 0} --fireState: 0 (hasn't fired) / 1 (fired before time) / 2 (fired before opponent) / 3 (fired after opponent) / 4 shot at before shooting
Semaphore = {enabled = 1, initDelay = 120, wasActivated = 0, currTime = 0, opponentHasFired = 0, opponentTime = 25}

function Player.init()
    Player.reactionSpeed = 0
    Player.fireState = 0
end

function Player.update()
    if Player.enabled == 1 and state_vars.running_state == 1 then 
        if keyp(48) and Player.fireState == 0 then --spacebar
            if Semaphore.wasActivated == 1 then
                if Semaphore.opponentHasFired == 1 then
                    Player.fireState = 3 -- fired after opponent
                else
                    Player.fireState = 2 -- fired before opponent
                end
            else
                Player.fireState = 1 --before time
            end
        end
    end
end 

function Player.draw()
    if Player.enabled == 1 then
        print("Fire state:", 0 , 0)
        
        if Player.fireState == 0 then        -- not yet
            print("hasn't shot", 64, 0)
        elseif Player.fireState == 1 then        --early
            print("shot before time!", 64, 0)
        elseif Player.fireState == 2 then   -- on time
            print("shot on time!", 64, 0)
        elseif Player.fireState == 3 then  -- late (state 3)
            print("shot too late...", 64, 0)
        else --shot timeout (state 4)
            print("Not quick enought!", 64, 0)
        end 

        print(Player.reactionSpeed, 164, 0)

        print(targetDayStage, 164, 64) --for sky debug --to remove
    end
end

--Semaphore----------------------------------------

function Semaphore.init()
    Semaphore.initDelay = math.random(60, 180)
    Semaphore.wasActivated = 0
    Semaphore.currTime = 0
end

function Semaphore.update()
    if Semaphore.enabled == 1 and state_vars.running_state == 1 then --maybe only allow stopping if not in duel?
        if Semaphore.wasActivated == 0 and Semaphore.initDelay < Semaphore.currTime then
            Semaphore.wasActivated = 1
            Semaphore.currTime = 0
            --also change visual queue
        else
            Semaphore.currTime = Semaphore.currTime + 1
        end

        if Semaphore.wasActivated == 1 and Player.fireState == 0 then
            Player.reactionSpeed = Player.reactionSpeed + 1
            if Player.reactionSpeed > Semaphore.opponentTime then
                Semaphore.opponentHasFired = 1
            end
            if(Player.reactionSpeed > Semaphore.opponentTime + 10) then --if player shot timed out --should be around 10
                Player.fireState = 4
            end
        end 
    end
end

function Semaphore.draw()
    if(Semaphore.enabled == 1) then
        --show visual queue
        if Semaphore.wasActivated == 0 then
            print("Don't", 0 , 24)
        else
            print("Fire!", 0, 24)
        end

        print(Semaphore.currTime, 128, 64)
    end
end

--CODE UNTIL HERE-------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------

Engine = {
	_init = {Semaphore.init, Player.init}, 
	_update = {skyUpdate, Semaphore.update, Player.update, Menu_enum.update}, 
	_draw = {Semaphore.draw, Player.draw}, 
	_uidraw = {Menu_enum.draw}
}

function Engine:init()
	if self._init == nil then
		return
	end
	for i=1, #self._init do
		self._init[i]()
	end
end

function Engine:update()
	if self._update == nil then
        return
    end
	for i = 1, #self._update do
		self._update[i]() 
    end
end

function Engine:draw()
	cls(11)
    
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
	Engine:uidraw()
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

-- <TRACKS>
-- 000:180000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:180301000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

