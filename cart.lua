-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

----------------
--CODE FROM HERE
t=0


Player = {reactionSpeed = 0, fireState = 0} --fireState: 0 (hasn't fired) / 1 (fired before time) / 2 (fired before opponent) / 3 (fired after opponent)
Semaphore = {initDelay = 120, wasActivated = 0, currTime = 0, opponentHasFired = 0, opponentTime = 25}

function Player.init()
    Player.reactionSpeed = 0
    Player.fireState = 0
end

function Player.update()
    if btn(2) and Player.fireState == 0 then --spacebar
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

function Player.draw()
    print("Fire state:", 0 , 0)
    
    if Player.fireState == 0 then        -- not yet
        print("hasn't shot", 64, 0)
    elseif Player.fireState == 1 then        --early
        print("shot before time!", 64, 0)
    elseif Player.fireState == 2 then   -- on time
        print("shot on time!", 64, 0)
    else                                -- late
        print("shot too late...", 64, 0)
    end 

    print(Player.reactionSpeed, 148, 0)
end

function Semaphore.init()
    Semaphore.initDelay = math.random(60, 180)
    Semaphore.wasActivated = 0
    Semaphore.currTime = 0
end

function Semaphore.update()
    if Semaphore.wasActivated == 0 and Semaphore.initDelay < Semaphore.currTime then
        Semaphore.wasActivated = 1
        Semaphore.currTime = 0
    else
        Semaphore.currTime = Semaphore.currTime + 1
    end



    if Semaphore.wasActivated == 1 and Player.fireState == 0 then
        Player.reactionSpeed = Player.reactionSpeed + 1
        if Player.reactionSpeed > Semaphore.opponentTime then
            Semaphore.opponentHasFired = 1
        end
    end
end

function Semaphore.draw()
    if Semaphore.wasActivated == 0 then
        print("Don't", 0 , 24)
    else
        print("Fire!", 0, 24)
    end

    print(Semaphore.currTime, 128, 64)
end

--CODE UNTIL HERE
------------------------

Engine = {_init = {Semaphore.init, Player.init}, _update = {Semaphore.update, Player.update}, _draw = {Semaphore.draw, Player.draw}, _uidraw = {}}

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

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

