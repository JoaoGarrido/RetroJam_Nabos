-- title:  game title
-- author: game developer
-- desc:   short description
-- script: lua

----------------------------------------------------------------------------------------------------------------------------------------
--CODE FROM HERE------------------------------------------------------------------------------------------------------------------------
t = 0
UIENABLED = 1

palettTiles     = "0418205d275db13e53eec6beffcd75a7f07038b764257179c2711c3014104c28105089b6f4f4f494b0c2566c86000404"

palettSprites   = "0418205d275dde3e53eec6beffcd7500d60038b76400852829366f3b5dc9753c08d26d08f4f4f494b0c2596589000404"

runMusic = 1

function swapPalette(currPalett)
    paladr = 0x3FC0
    if(currPalett == 0) then
        for i=1, palettSprites:len() , 2 do
            poke(paladr,tonumber("0x"..palettSprites:sub(i,i)..palettSprites:sub(i+1,i+1)))
            paladr=paladr+1
        end
    else
        for i=1, palettTiles:len() , 2 do
            poke(paladr,tonumber("0x"..palettTiles:sub(i,i)..palettTiles:sub(i+1,i+1)))
            paladr=paladr+1
        end
    end
    
    currPalett = (currPalett + 1)%2
end

--Sky color offset----------------------------------------

original = {0x50, 0x89, 0xB6}
middayOffset = {-0x43, -0x5A, -0x0D}
sunsetOffset = {0xE5, 0x32, -0x14} --to F2 61 95
currDayStage = -8

function changePallette(targetDayStage)-- -8 is morning (regular colors) 0 midday 7 is sunset
    while currDayStage > targetDayStage and currDayStage > -7 do
        if currDayStage > 0 then --[0:7]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) - (sunsetOffset[1] // 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) - (sunsetOffset[2] // 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) - (sunsetOffset[3] // 8))
            currDayStage = currDayStage - 1
        elseif currDayStage > -8 then --[-8 : -1]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) - (middayOffset[1] // 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) - (middayOffset[2] // 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) - (middayOffset[3] // 8))
            currDayStage = currDayStage - 1
        end
        
    end

    while currDayStage < targetDayStage and currDayStage < 6 do
        if currDayStage < 0 then --[-8:-1]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) + (middayOffset[1] // 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) + (middayOffset[2] // 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) + (middayOffset[3] // 8))
            currDayStage = currDayStage + 1
        elseif currDayStage < 7 then --[0-7]
            poke(0x3fc0 + (11 * 3), peek(0x3fc0 + 11*3) + (sunsetOffset[1] // 8))
            poke(0x3fc0 + (11 * 3 + 1), peek(0x3fc0 + 11*3 + 1) + (sunsetOffset[2] // 8))
            poke(0x3fc0 + (11 * 3 + 2), peek(0x3fc0 + 11*3 + 2) + (sunsetOffset[3] // 8))
            currDayStage = currDayStage + 1
        end
    end

    targetDayStage = currDayStage
end

targetDayStage = -8
function SkyUpdate()
    if keyp(61) then --7
        targetDayStage = currDayStage + 1
        changePallette(targetDayStage)
    elseif keyp(60) then
        targetDayStage = currDayStage - 1
        changePallette(targetDayStage)
    end    
end

--Menu----------------------------------------

--scene:
	--ID | 	NAME			| MAP BLOCK
	--0 -> Game scene		| (1,level)
	--1 -> Shop				| (0,1)
	--2 -> Victory screen	| (0,2)
	--3 -> Lost screen		| (0,3)
	--4 -> Main Screen		| (0,0)
--running: 0->paused | 1->running
--level: level id
--battle:
	-- -1-> Show text
	-- 0 -> Waiting for battle
	-- 1 -> Won battle
	-- 2 -> Lost battle
MAX_LEVEL = 7
GameState = {scene = 4, running = 1, level = 0, battle = 0}

function GameState.init()
	resetGameScene()
	actionGameScene(0)
	GameState.scene = 4
	GameState.running = 1
	GameState.level = 0
	GameState.battle = -1
end

previous_battle = GameState.battle
previous_level = GameState.level
previous_scene = GameState.scene
function changeInMusic()
	if (GameState.battle ~= previous_battle) or (GameState.level ~= previous_level) or (GameState.scene ~= previous_scene) then
		runMusic = 1
	end
	previous_battle	= GameState.battle
	previous_level	= GameState.level
	previous_scene	= GameState.scene
end

timeout = 0
function GameState.update()
    swapPalette(1) --lazy af but idgaf
	if (GameState.scene == 0) then		--game scene
		if (GameState.battle == -1) then --Battle text
			GameState.scene_text_enabled = 1
			actionGameScene(0)
			--Press SPACE to skip text
			if(keyp(48)) then
				actionGameScene(1)
				GameState.scene_text_enabled = 0
				GameState.battle = 0
			end
		elseif (GameState.battle == 0) then	--Waiting for battle 
			--Run Duel Music
			if (runMusic == 1) then
				music(4, 0, 0, false) --duel start
				runMusic = 0
			end
			--Waits for pause
			if (keyp(16)) then 	--P for pause
				GameState.running = (GameState.running + 1) % 2
				if(GameState.running == 1) then
					sfx(4)
				else
					sfx(3)
				end
				actionGameScene(GameState.running)
			end
		elseif (GameState.battle == 1 and GameState.level < MAX_LEVEL) then			--won before last level
			if (runMusic == 1) then
				music(2, 0, 0, false) --duel win
				runMusic = 0
			end
			resetGameScene()
			actionGameScene(0)
			if(keyp(19)) then		--Press S to go to shop
				GameState.scene = 1
			end
			goToGameSceneIfKey(14)	--Press N to go to next level
		elseif (GameState.battle == 1 and GameState.level == MAX_LEVEL) then 	--won last level
			if (runMusic == 1) then
				music(2, 0, 0, false) --duel win
				runMusic = 0
			end
			resetGameScene()
			timeout = timeout + 1
			if(timeout == 300) then
				GameState.scene = 2
				timeout = 0
			end
		elseif (GameState.battle == 2) then										--lost
			if (runMusic == 1) then
				music(3, 0, 0, false) --duel win
				runMusic = 0
			end
			resetGameScene()
			timeout = timeout + 1
			if(timeout == 300) then
				GameState.scene = 3
				timeout = 0
			end
		end

	elseif (GameState.scene == 1)	then	--shop		
		--Add buy items logic
        swapPalette(0)
		shopMenu.enabled = 1
		goToGameSceneIfKey(14) --Press N to go to next level
	elseif (GameState.scene == 4)	then	--main
		if (runMusic == 1) then
			music(2, 0, 0, true) --main menu song
			runMusic = 0
		end
		if(keyp(48)) then --Press SPACE to start
			actionGameScene(1)
			GameState.scene = 0
		end
	else 									--victory/losing screen
		if (runMusic == 1) then
			if(GameState.scene == 2) then
				music(2, 0, 0, false) --PLACEHOLDER win game music
			elseif (GameState.scene == 3) then
				music(5, 0, 0, false) --game over
			end
		end
		actionGameScene(0)
		resetGameScene(0)
		if (keyp(19)) then --Press S to restart
			GameState.init()
		end
	end
end

function GameState.draw()
	print(GameState.scene)
	if(GameState.scene == 0) then
		--print("Game scene", 60, 100)

		map(30*(GameState.level % 8), 17+17*(math.floor(GameState.level/8)), 30, 17, 0, 0, -1, 1, nil) --colorkey 0 (sky stuff)

		--Debug map
		if (GameState.level == 0) then
		--	print("Level 0", 60, 60)
		elseif (GameState.level == 1) then
		--	print("Level 1", 60, 60)
		elseif (GameState.level == 2) then
		--	print("Level 2", 60, 60)
		elseif (GameState.level == 3) then
		--	print("Level 3", 60, 60)
		elseif (GameState.level == 4) then
		--	print("Level 4", 60, 60)
		end

    
        --cowboys here --yeehaw

        --sneaky (not so sneaky) space bar update
        if(Semaphore.wasActivated == 1 and GameState.battle == 0) then
            spacebarUIEnable = 1
        else
            spacebarUIEnable = 0
        end
		pressSpaceUI()

        local default_cowboy = {
			l_x = 30,
			r_x = 190,
			y = 100,
			colorkey = 0,
			scale = 1,
			l_flip = 0,
			r_flip = 1,
			rotate = 0,
			w = 2,
			h = 4,
		}
		id_cowboy_base_id = {256, 320, 326}
		if (GameState.battle == 0 and GameState.running == 1) then
			l_cowboy_id	= id_cowboy_base_id[1]
			r_cowboy_id	= id_cowboy_base_id[2+GameState.level%2]
		elseif (GameState.battle == 1) then
			l_cowboy_id	= id_cowboy_base_id[1] + 2
			r_cowboy_id	= id_cowboy_base_id[2+GameState.level%2]+4
			wonDuel()
		elseif (GameState.battle == 2) then
			l_cowboy_id	= id_cowboy_base_id[1] + 4
			r_cowboy_id	= id_cowboy_base_id[2+GameState.level%2]+2
		elseif(GameState.running == 0) then
			pauseMenu()
		end

		spr(l_cowboy_id,
			default_cowboy.l_x,
			default_cowboy.y, 
			default_cowboy.colorkey,
			default_cowboy.scale,
			default_cowboy.l_flip,
			default_cowboy.rotate,
			default_cowboy.w,
			default_cowboy.h
		)
		spr(r_cowboy_id,
			default_cowboy.r_x,
			default_cowboy.y, 
			default_cowboy.colorkey,
			default_cowboy.scale,
			default_cowboy.r_flip,
			default_cowboy.rotate,
			default_cowboy.w,
			default_cowboy.h
		)
		
		--draw guns
		if (GameState.battle == 0) then		--waiting battle
			drawGun(getGunSprite(Player.currWeapon), default_cowboy.l_x, default_cowboy.y + 20, 0, 1) --left cowboy
			drawGun(getGunSprite(opponents[GameState.level+1][4]), default_cowboy.r_x, default_cowboy.y + 20, 1, 1) --right cowboy
		elseif (GameState.battle == 1) then --won battle
			drawGun(getGunSprite(Player.currWeapon), default_cowboy.l_x + 5, default_cowboy.y + 15, 0, 0)	--left cowboy
			drawGun(getGunSprite(opponents[GameState.level+1][4]), default_cowboy.r_x, default_cowboy.y + 30, 1, 2) 		--right cowboy
		else								--lost battle	
			drawGun(getGunSprite(Player.currWeapon), default_cowboy.l_x, default_cowboy.y + 30, 0, 2)		--left cowboy
			drawGun(getGunSprite(opponents[GameState.level+1][4]), default_cowboy.r_x, default_cowboy.y + 15, 1, 0) 		--right cowboy
		end

	elseif (GameState.scene == 1) then
		map(30, 0, 30, 17, 0, 0, -1, 1, nil)
		--print("Shop", 60, 100)
	elseif (GameState.scene == 2) then
		map(60, 0, 30, 17, 0, 0, 11, 1, nil)
		print("", 40, 20, 12)
		local textA = "Winner Winner Chicken Dinner"
		local width = print(textA, 0, -6)
		print(textA, (240-width)//2, 10, 12, false, 1)
		local textB = "Press 'S' to restart"
		local width = print(textB, 0, -6)
		print(textB, (240-width)//2, 24, 12)
	elseif (GameState.scene == 3) then
		map(90, 0, 30, 17, 0, 0, -1, 1, nil)
		local textA = "GAME OVER"
		local width = print(textA, 0, -6)
		print(textA, (240-width*2)//2, 10, 2, false, 2)
		local textB = "Press 'S' to restart"
		local width = print(textB, 0, -6)
		print(textB, (240-width)//2, 24, 2)
	elseif (GameState.scene == 4) then
		map(0, 0, 30, 17, 0, 0, -1, 1, nil)
		--rect(0, 0, 240, 136, 2) --menu background -- brown?
		--rectb(60, 34, 120, 68, 4) --menu border --white
		local stringMainMenu = "Bang Bang"
		local width = print(stringMainMenu, 0, -6)
		print(stringMainMenu, (240-width*2)//2, (136-6)//2 - 50, 12, false, 2)
		stringStart = "Press SPACE to start!"
		local widthStart = print(stringStart, 0, -6)
		print(stringStart, (240-widthStart)//2, 112, 12, false, 1)
	end    
end

function drawGun(id, x, y, flip, rotate)
	spr(id,
		x,
		y, 
		0,
		1,
		flip,
		rotate
	)
end

function goToGameSceneIfKey(key)
	if(keyp(key)) then
		GameState.battle = -1
		GameState.scene = 0
		GameState.level = GameState.level + 1
		shopMenu.enabled = 0
		GameState.scene_text_enabled = 1
	end
end

spacebarUIEnable = 0
active = 0
function pressSpaceUI()
    x = 120 -25
    y = 120
    w = 50
    l = 10


    text = "SPACE"

    if(spacebarUIEnable == 1) then
        if t%4 == 0 then
            active = (active +1) %2
        end
    end

    if(active == 0) then
        rect(x, y, w, l, 14)
        rect(x, y+l, w, l/2, 15)
        print(text, x+w/2-(#text*3), y+1)
    else
        rect(x, y + l/2, w, l, 14)
        rect(x, y+l + 3*l/8, w, l/4, 15)
        print(text, x+w/2-(#text*3), y+1 + l/2)
    end
end

function pauseMenu()
    rect(60, 34, 120, 68, 3) --menu background -- brown?
    rectb(60, 34, 120, 68, 4) --menu border --white
    print("PAUSED", 102, 50)
    unpauseMess = "Press 'p' to unpause"
    print(unpauseMess, 120 - ((#unpauseMess-2) * 3), 78)
end

function wonDuel()
    rect(60, 34, 120, 80, 10) --menu background -- brown?
    rectb(60, 34, 120, 80, 4) --menu border --white
	
	local victoryText = "VICTORY!"
	local width = print(victoryText, 0, -6)
	print(victoryText, (240-width)//2, 40)
	
	local opp1Text = "Your opponent"
	width = print(opp1Text, 0, -6)
	print(opp1Text, (240-width)//2, 50)
	
	local opp2Text = "lies dead!"
	width = print(opp2Text, 0, -6)
	print(opp2Text, (240-width)//2, 58)
	
	local shop1Text = "Press 's'"
	width = print(shop1Text, 0, -6)
	print(shop1Text, (240-width)//2, 78)

	local shop2Text = "to go to shop"
	width = print(shop2Text, 0, -6)
	print(shop2Text, (240-width)//2, 86)

	local duel1Text = "Press 'n'"
	width = print(duel1Text, 0, -6)
	print(duel1Text, (240-width)//2, 98)

	local duel2Text = "to go to next duel"
	width = print(duel2Text, 0, -6)
	print(duel2Text, (240-width)//2, 106)
end

--Duel mechanics------------------------------------------------------
--Player----------------------------------------

function getGunSprite(shoppingListID) --from shopping list id
    if(shoppingListID >= 10 and shoppingListID <= #shoppingList) then
        return shoppingList[shoppingListID][4]
    else
        return 448
    end
end

opponents = { --may need overwritten visual options
    {"Old McDuff", 30, "In a quest to avenge your family from the silver rider, a lefty gunslinger, you stop at a bar to have a drink. The local drunkard threatens to kill you.", -1, 1},
    {"Senile Ms Johnson", 29, "A wild grandma wearing a fake beard blocks your path, your only choice is violence.", 10, 2},
    {"\"Not so old\" Jack", 27, "An old man wearing a colored wig demands you duel him after you tell him he looks too old. HE DOES LOOK OLD, WHAT'S HIS PROBLEM?!", -1, 5},
    {"Crooked John", 25, "A man with crooked back says you owe him money! Surely there must be a good way to solve this...", 11, 10},
    {"Doc Richard", 23, "The town doctor is looking for you for shooting his last patient. \"You can't go shooting my patients\" he says, \"Vengeance!\" you say.", 13, 20},
    {"\"Young\" Galen Young", 21, "An unusually tall man stumbles in the streets looking for you, are those stilts? Is that simply a kid on stilts???", 12, 35},
    {"\"Fastest gun in the west\"", 19, "A man pretending to be the Silver Rider approaches you! You know it not to be true as the Silver Rider doesn't have a triple chin.", 18, 50},
    {"The Silver Rider", 11, "Finally! The climax of this adventure! Will you succeed in avenging your family?", 19, 200}
}

function printBackStory(string, x, y, l) --l line width
    for i = 1, (#string // l + 1) do
        print(string:sub((i-1) * l, math.min(#string, (i-1)*l + l-1)), x, y + i*8)
    end
end

function displayCharacterStory()
    if(GameState.level >= 0 and GameState.level <= 7) then
        printBackStory(opponents[GameState.level + 1][3], 40, 50, 29)
    end
end

function displayBeforeDuel()
	if (GameState.scene_text_enabled == 1) then
		rect(30, 17, 180, 112, 10)
		rectb(30, 17, 180, 112, 4)
		rectb(32, 19, 176, 108, 4)

		print(opponents[GameState.level+1][1], 120-#opponents[GameState.level+1][1] *3 +2, 40)

		displayCharacterStory()

		strPressSpaceToDuel = "Press 'space' to duel"
		print(strPressSpaceToDuel, 120-#strPressSpaceToDuel*3, 110)
	end
end

--fireState: 0 (hasn't fired) / 1 (fired before time) / 2 (fired before opponent) / 3 (fired after opponent) / 4 shot at before shooting
Player = {enabled = 1, reactionSpeed = 0, fireState = 0, currWeapon = -1} 
Semaphore = {enabled = 1, initDelay = 120, wasActivated = 0, currTime = 0, opponentHasFired = 0, opponentTime = 25}

function Player.init()
    Player.reactionSpeed = 0
    Player.fireState = 0
end

function shotSFX(weapon)
    if(weapon == -1) then --default pistol
        sfx(0)
    elseif weapon == 10 then
        sfx(24)
    elseif weapon == 11 or weapon == 12 or weapon == 14 or weapon == 16 then
        sfx(20)
    elseif weapon == 13 then
        sfx(21)
    elseif weapon == 15 then
        sfx(22)
    elseif weapon == 17 then --grenade sound
        sfx(16)
    elseif weapon == 18 then 
        sfx(23)
    elseif weapon == 19 then
        sfx(19)
    else
        sfx(0)
    end
end

function Player.update()
    if Player.enabled == 1 then 
        if keyp(48) and Player.fireState == 0 then --spacebar
            if Semaphore.wasActivated == 1 then
                shotSFX(Player.currWeapon) --Shot sfx
                if Semaphore.opponentHasFired == 1 then
                    Player.fireState = 3 -- fired after opponent
					GameState.battle = 2
                else
                    Player.fireState = 2 -- fired before opponent
                    dollars = dollars + opponents[GameState.level+1][5]
					GameState.battle = 1
                end
            else
                Player.fireState = 1 --before time
				GameState.battle = 2
            end
        end
    end
end 

function Player.draw()
    if Player.enabled == 1 then
        --print("Fire state:", 0 , 0)
        
        if Player.fireState == 0 then        -- not yet
            --print("hasn't shot", 64, 0)
        elseif Player.fireState == 1 then        --early
            --print("shot before time!", 64, 0)
        elseif Player.fireState == 2 then   -- on time
            --print("shot on time!", 64, 0)
        elseif Player.fireState == 3 then  -- late (state 3)
            --print("shot too late...", 64, 0)
        else --shot timeout (state 4)
			GameState.battle = 2 --HOTFIX SPAGHETTI
            --print("Not quick enought!", 64, 0)
        end 

        --print(Player.reactionSpeed, 164, 0)

        --print(targetDayStage, 164, 64) --for sky debug --to remove
    end
end

--Semaphore----------------------------------------

soundPlayed = 1
function drawVisualQueues()
	if(GameState.scene == 0) then
		if(GameState.level == 0) then
			if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
				--not activated idle animations
			else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
				--queue activation
                --spr(388, 214, 70, -1, 1, 1, 0, 2, 2) --horse fart

			end
		elseif(GameState.level == 1) then
			if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
				--not activated idle animations
			else
                --trace(soundPlayed)
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
				--queue activation
			end
        elseif(GameState.level == 2) then
			if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
				--not activated idle animations
			else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
				--queue activation
				spr(388, 214, 70, -1, 1, 1, 0, 2, 2) --horse fart
			end
        elseif(GameState.level == 3) then
			if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
				--not activated idle animations
			else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
				--queue activation

			end
        elseif(GameState.level == 4) then
			if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
				--not activated idle animations
			else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
				--queue activation
            end
        elseif(GameState.level == 5) then
            if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
                --not activated idle animations
            else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
                --queue activation
            end
        elseif(GameState.level == 6) then
            if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
                --not activated idle animations
            else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
                --queue activation
            end
        elseif(GameState.level == 7) then
            if(GameState.battle == 0 and Semaphore.wasActivated == 0) then
                soundPlayed = 0
                --not activated idle animations
            else
                if(soundPlayed == 0) then
                    --play sound queue
                    sfx(2)--placeholder sound
                    soundPlayed = 1
                end
                --queue activation
            end
        end
    end
end

function Semaphore.init()
    Semaphore.initDelay = math.random(100, 500)
    Semaphore.wasActivated = 0
    Semaphore.currTime = 0
	Semaphore.opponentHasFired = 0
    if GameState.level > #opponents then
        Semaphore.opponentTime = 25 --default value
    else
        Semaphore.opponentTime = opponents[GameState.level+1][2]
    end 
end

function Semaphore.update()
    if Semaphore.enabled == 1 then --maybe only allow stopping if not in duel?
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
            --print("Don't", 0 , 24)
        else
            --print("Fire!", 0, 24)
        end
        --print(opponents[GameState.level+1][1], 128, 78)
        --print(opponents[GameState.level+1][2], 128, 88)
        --print(Semaphore.currTime, 128, 64)
    end
end

function resetGameScene()
	Semaphore.init()	
	Player.init()
end

function actionGameScene(p)
	Semaphore.enabled = p
	Player.enabled = p
end

dollars = 0
shoppingList = { --bought, name, price, sprite?
    --Consumables (?) --add lives?
    {0, "Watermelon", 5, 0464},
    {0, "Broccoli", 5, 0465},
    {0, "Cherries", 5, 0467},
    {0, "Eggplant", 5, 0468},
    {0, "Strawberry", 5, 0469},
    {0, "Wine", 20, 0470},
    {0, "Soda", 10, 0471},
    {0, "Sandwich", 10, 0472},
    {0, "Scotch", 30, 0473},
    --Weapons
    {0, "Duck Head", 20, 0432}, --10
    {0, "Crossbow", 30, 0434},
    {0, "SlingShot", 10, 452},
    {0, "Shiny Revolver", 50, 0448},
    {0, "Marble fade", 50, 0449},
    {0, "Thomson", 70, 0450}, --15
    {0, "Poison Kunai", 70, 0451},
    {0, "'Nade", 100, 0435},
    {0, "Uzi", 100, 436},
    {0, "Ray gun", 200, 0433}, --19
}

shopMenu = {capacity = 4, topmostIndex = 1, selectedIndex = 1, canScrollUp = 0, canScrollDown = 0, enabled = 0} 
--shopMenu
    --capacity: how many are shown at a time
    --selectedIndex: what item is currently selected 

function shopMenu.init()
	topmostIndex = 1
	selectedIndex = 1
	enabled = 0
end

function shopMenu.update()
	if (shopMenu.enabled == 1) then
		if keyp(2) then --b to buy
            if(dollars >= shoppingList[ shopMenu.selectedIndex][3] and shoppingList[ shopMenu.selectedIndex][1]==0) then
                dollars = dollars - shoppingList[shopMenu.selectedIndex][3]
                shoppingList[shopMenu.selectedIndex][1] = 1
                --insert item effects here
                if(shopMenu.selectedIndex < 10) then --if is food

                else -- change current weapon
                    Player.currWeapon = shopMenu.selectedIndex
                end
				sfx(7)
            elseif shoppingList[ shopMenu.selectedIndex][1]==1 and shopMenu.selectedIndex >= 10 then --if gun is already bought just swap
                Player.currWeapon = shopMenu.selectedIndex
                shotSFX(Player.currWeapon)
			else
				sfx(6)
            end
		elseif keyp(58) then --up scroll
			sfx(5)
			if(shopMenu.topmostIndex == shopMenu.selectedIndex and shopMenu.topmostIndex > 1) then--scroll up
				shopMenu.topmostIndex = shopMenu.topmostIndex - 1
				shopMenu.selectedIndex = shopMenu.selectedIndex - 1
			elseif shopMenu.selectedIndex > 1 then
				shopMenu.selectedIndex = shopMenu.selectedIndex - 1
			end
		elseif keyp(59) then --down scroll
			sfx(5)
			if((shopMenu.topmostIndex + shopMenu.capacity) == shopMenu.selectedIndex and  shopMenu.selectedIndex < #shoppingList) then
				shopMenu.topmostIndex = shopMenu.topmostIndex + 1
				shopMenu.selectedIndex = shopMenu.selectedIndex + 1
			elseif shopMenu.selectedIndex < #shoppingList then
				shopMenu.selectedIndex  = shopMenu.selectedIndex + 1;
			end
		end
	end
end

function shopMenu.draw()
	if (shopMenu.enabled == 1) then
		rect(50, 17, 140, 90, 3) --menu background -- brown?
		rectb(50, 17, 140, 90, 4) --menu border --white

		print("SHOP", 120 - #"SHOP" * 3 + 2, 25)
		if(shopMenu.topmostIndex > 1) then --if can be scrolled up
			print("/\\", 120-#"/\\"*3+2, 35)
		end

		for i = 0, shopMenu.capacity do
			if i + shopMenu.topmostIndex <= #shoppingList then
				print(shoppingList[i+shopMenu.topmostIndex][2], 120 - #shoppingList[i+shopMenu.topmostIndex][2] * 3 + 2, 45 + 10* i)
                if shoppingList[i + shopMenu.topmostIndex][4] ~= -1 then
                    spr(shoppingList[i + shopMenu.topmostIndex][4], 64, 44 + 10 * i, 0, 1, 0, 0, 1, 1)
                end

                print(shoppingList[i+shopMenu.topmostIndex][3], 160, 45 + 10* i)
                print("$", 180, 45 + 10* i)

                if(shoppingList[i+shopMenu.topmostIndex][1] == 1) then
                    line(50 + 35, 47 + 10*i, 50 + 140 - 35, 47 + 10 * i, 15)
                end
			end
		end

		print(">", 54, 45 + (shopMenu.selectedIndex - shopMenu.topmostIndex) * 10)

		if(shopMenu.topmostIndex < #shoppingList-shopMenu.capacity) then --if can be scrolled up
			print("\\/", 120-#"\\/"*3+2, 95)
		end

        rect(120 - 30, 136 - 28, 60, 10, 3)
        rectb(120 - 30, 136 - 28, 60, 10, 4)
        print("$", 120-25, 136 -25)
        print(dollars, 120 - 15, 136 - 25)
		print("'b' to buy", 186, 110)
		print("'n' to exit", 186, 120)
        --print(Player.currWeapon)
	end
end

--CODE UNTIL HERE-------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
Engine = {
	_init = {Semaphore.init, Player.init, shopMenu.init, GameState.init}, 
	_update = {SkyUpdate, Semaphore.update, Player.update, GameState.update, shopMenu.update, changeInMusic}, 
	_draw = {GameState.draw, Semaphore.draw, Player.draw, drawVisualQueues}, 
	_uidraw = {shopMenu.draw, displayBeforeDuel}
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
-- 001:44444444444444444444444a4a4444aa4444a44a4a444444444444444444444a
-- 002:4444444444444444444aaa444a4444444444a4444a44444444aaa4444444444a
-- 003:444aaa44444444a4a44444444a4444444444a4aa4a444444444aa44444a4444a
-- 004:bbbbbbbbbbbbcbbbbcccbbbbbbbbbbbbbbbbbbbbbbbbccbbbbbbbbcbbbbbbbbb
-- 005:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 006:bbbbbbccbbbbbbbbbcbbbbbbccbbbbbbbbbbbbbbbbbbccbbbbbbcccbbbccccbb
-- 007:4444444444444444444444444444444444444444444444444444444444444444
-- 008:9999999994444444944222229442222294422244944422449444222294442222
-- 009:99999999444444442224444422224444422244aa422444442224444424444444
-- 010:99999999444444444444444244444422a44444224a4444244444422444444224
-- 011:9999999944444444444444442444aa44224444a4224444494224444442244444
-- 012:999999994444444444422222a4422222aa422444444224444442244444422224
-- 013:99999999444444492244444922224a4944224449442244494a2244494a224449
-- 014:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 015:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
-- 016:aaaaaaaa99999999a9aaaaaaaaaaaaaa99999999aaaaaaaaaaaa9999999aaaaa
-- 017:499999994498898848988988489889884999999949aa9aaa999999999aaaa9aa
-- 018:9999999488988944889889848898898499999994aaa9aa9499999999aa9aaaa9
-- 019:8988989889889898898898988898889899999999aaaaaaaa99999999aaaaaaaa
-- 020:89aaaa948999999489aaaa9489aaaa9499999999a9aaaa9a999999999aaaaaa9
-- 021:49aaaa984999999849aaaa9849aaaa984999999849aaaa984999999849aaaa98
-- 022:8888888888888888999999998898888888888988999999998888888889888888
-- 023:444444444a4444a444444444444444444444444444a444444444444444444444
-- 024:94444222944442229444a224944a422494444224944444229444442299999999
-- 025:222222442222222444444224444442a442222224222222442244444499999999
-- 026:4444222244442222444422444442244444422444442244444444444499999999
-- 027:22224444222444444224aa444224444444244444a42244444444444499999999
-- 028:442222224422442244224422422444424224aaa44444444a4444444499999999
-- 029:22a4444944444449244444492444444922444a4922444449444444a999999999
-- 030:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
-- 031:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
-- 032:8888888988888889999999998888888988888889999999998888888988888889
-- 033:999999999888888888888888899999999a8aa88affffffffffffff99ffff9999
-- 034:999999998888888988888888999999988a88a8a9ffffffff99ffffff9999ffff
-- 035:9888888898888888999989999888888898888888999999999888888898888888
-- 036:8888888888888888999999998898888888888988999999998888888889888888
-- 037:999999999bbbbbb99bbbbbc99bbbccc99bbccbb99bccbbb99bcbbcb99bcbbbb9
-- 038:999999999bbbbbb99bbccbb99bccbbb99ccbbbb99bbbbbb99bbbccb99bbbbbb9
-- 039:5555555555555555999999995595555555555955999999995555555559555555
-- 040:b9aaaa98b9999998b9aaaa98b9aaaa98b9999998b9aaaa98b9999998b9aaaa98
-- 041:89aaaa948999999489aaaa9489aaaa948999999489aaaa948999999489aaaa94
-- 042:89aaaa9b8999999b89aaaa9b89aaaa9b8999999b89aaaa9b8999999b89aaaa9b
-- 043:499999994495595545955955459559554999999949aa9aaa999999999aaaa9aa
-- 044:5555557757555555557575555755755757775555555557557575555775557555
-- 045:5555555555555555555555555575555555555555555555555555555755555555
-- 046:44444444444444444444444a4a4444aa4546a46a466546645656655665556556
-- 047:5555555555555555555556555565555555556655565666566656565666665566
-- 048:8898888988888889889999998888888988888889999999998888888988888889
-- 049:fff99aa9f999aaa999aaaaa99aa999999aaaaaa99aaaaaa999999aa99aaaaaa9
-- 050:9aa99fff9aaa999f9aaaaa999aaaaaa99aa999999aaaaaa99aa999999aaaaaa9
-- 051:9888898898888888999999999888888898888888999999999888888898888888
-- 052:8888888888888888999999998898888888888988999999998888888889888888
-- 053:999999999bbbbbb99bbcccb99bbcbbb99bbbbbb99bbbcbb99bbbbbb999999999
-- 054:999999999cbbbcc99bbbbbb99bbcbbb99bccbbb99bbbbbb99bbbbbb999999999
-- 055:5955959559559595595595955595559599999999aaaaaaaa99999999aaaaaaaa
-- 056:9999999455955944559559545595595499999994aaa9aa9499999999aa9aaaa9
-- 057:49aaaa984999999849aaaa9849aaaa9899999999a9aaaa9a999999999aaaaaa9
-- 058:4a4448884a488444488448884844448888444884844448448444884484a48884
-- 059:4444444444888888888444448848844488448884484444884884448484484484
-- 060:bbbbbbbbbbbbbbb6bbbbbb65bbbbbb86bbbbb666bbbbb666bbbbbb68bbbbb566
-- 061:bbbbbbbb5bbbbbbb5bbbbbbb65bbbbbb65bbbbbb5bbbbbbb5bbbbbbb5bbb6555
-- 062:44444444444444464444446544444486a4444666444a4666444444684a444566
-- 063:44444444544444aa5444444465444444654a4a44544444445444444454446555
-- 064:8889888988888889999999998888888988888889999999998888888999999999
-- 065:9a9999a99aaaaa999aaaaaa9999999998fffffff8fffffff8fffffff88888888
-- 066:9a999aa99aaaaaa99aaaaaa999999999fffffff8fffffff8fffffff888888888
-- 067:9888988898888888999999999888888898888888999999999888888899999999
-- 068:8888888888888888999999998898888888888988999999998888888889888888
-- 069:8888888888888888999999998898888888888988999999998888888899999999
-- 071:59aaaa945999999459aaaa9459aaaa9499999999a9aaaa9a999999999aaaaaa9
-- 072:59aaaa945999999459aaaa9459aaaa945999999459aaaa945999999459aaaa94
-- 073:59aaaa9b5999999b59aaaa9b59aaaa9b5999999b59aaaa9b5999999b59aaaa9b
-- 074:844884444488488484844848848448444884488444884484a484888844884488
-- 075:84444484448448448888884488844488444444884aa448848844884484888444
-- 076:444446654a444685455446564654465648644655466556584666566544444656
-- 077:5444655565666555655555555555554465444444564464a45544854466556544
-- 080:44444444444444444aaa444444444444444444444444444a4444444a444444aa
-- 081:4444444444444444a44444a4a4f44aa4afffaaa4affaa4a4afaaaaafaaaaaaaf
-- 082:44444444444444444444a444444444444444444444444444a4444444f4444444
-- 083:44444444444444444444444444444444444aa4444444a444444444444444444a
-- 084:2222222222222222222222222222222222222222222222222222222222222222
-- 085:eeeeeeeeeeeeeeeeffffffffeefeeeeeeeeeefeeffffffffeeeeeeeeefeeeeee
-- 086:bbbbbbbbccccbccccfffccffbbcffffbbbcbfcbbcbcffcbbfcfcccbcbcbfffcf
-- 087:49aaaa954999999549aaaa9549aaaa9599999999a9aaaa9a999999999aaaaaa9
-- 088:49aaaa954999999549aaaa9549aaaa954999999549aaaa954999999549aaaa95
-- 089:b9aaaa95b9999995b9aaaa95b9aaaa95b9999995b9aaaa95b9999995b9aaaa95
-- 090:5555555555555555555555555575565556655655566565556666665765665666
-- 091:59aaa9555999a955599aaa5559aaaa555aaa99555a9a9a555aa9aa5559a9a955
-- 092:444445664a4445654a444665444486554aaa46584a44466544a4466544444665
-- 093:65444444556844445544444454444aaa5544444a554444445544444a56444444
-- 094:59aaa9555999a955599aaa5559aaaa555aaa99555a9a9a959aa9aa9995a9a959
-- 095:5555555555555555555555555557555567577566777777576777777777777776
-- 096:4444aaaf4444aaaa44aaaaaa44afaafa44aaaaaa444aaaa44444444444444444
-- 097:aafaaaafaaaaaaaaaaaaaaaaaaaaaaaaa9aaaaaa99aaaaaa9999aaaa4999aaaa
-- 098:ff44444afff44444fff44444fffa4444ffff4444afffa444afaaaaaaaaaaaaaa
-- 099:444444444444444444444444a44444444aaaa44444444444aa444444aaaaaff4
-- 101:e9aaaa98e9999998e9aaaa98e9aaaa98e9999998e9aaaa98e9999998e9aaaa98
-- 102:89aaaa9e8999999e89aaaa9e89aaaa9e8999999e89aaaa9e8999999e89aaaa9e
-- 103:bbbbbbbbbbbbccccbbbbbbbbbbbbbbbbbbccbbbbcccbbbbbbbbbbbbbbbbbbbbb
-- 104:bbbbbbbbbbbbbbbbbcbcbbbbbbbbbbbbbb6bbbc6bb6b56bbb65b565665556565
-- 105:bbbbbbbbbcbbbbbbbcbbbbbbbbbbbbbbbbbcbbbbcbbbbbbbbbbbbbccbbbbbbbb
-- 106:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
-- 107:9999999988988988889889888898898899999999a6aa956a9969965996566556
-- 108:776677777776777667aa77aaaa6a7aaaa7aaaaa677aaaaaa7aaaaaaa7aaaaa67
-- 109:7677677767777667777776777777777766777766777777776777777777777776
-- 110:5555677755777667557776775577777755577766557777775557777755555776
-- 111:7675555567777655777775557775555566757765777777556777775577777555
-- 112:444444444444444444444444444444444444a444444444444444444444444444
-- 113:49999aaa44999aaa44499aaa44499aaa44aa99aa444aa9aa444aa9aa444a999a
-- 114:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99aaaaaa999aaaaa9999999a9999999
-- 115:aaaaafffaaaaaaffaaaaaaafaaaaaaafaaaaaaaf99aaa99f999aaa4f9999aa4f
-- 116:5585555855885588558858885588888855888888588f88f8f888888888888888
-- 117:5555555555555555555555555575555588555555888885558888888788888888
-- 118:555555cc555558cc55558c8c5555888c58888888888888888888888588888555
-- 119:4444444444444444444444444444444444444444444444444444444444444444
-- 120:2222222222222222222222222222222222222222222222222222222222222222
-- 121:7777777777777777777777777777777777777777777777777777777777777777
-- 122:1111111111111111111111111111111111111111111111111111111111111111
-- 128:444a444444444444444444444444444444444aaa444444444444444444444444
-- 129:444aa44a444aa44a444aa44a444aa44a444aa44a444aa44a444a444a44444444
-- 130:a4444444a4444444a4444444a44444a4a444444aa44444444444444444444444
-- 131:44a9aa4f44a9aa4f44a4aaf444a4aa4444a4aa4444a4aa4444444a4444444444
-- 132:555cc888555555cc5555558c5555588855555885555558855555885555555555
-- 133:8888888888888888888cc8885888858858888588588555888855588755555555
-- 134:a5555555aa555555555555555555555555a555555555aa5555aa99a555555555
-- 135:8888888888888888888888888888888888888888888888888888888888888888
-- 136:5555555555555555555555555555555555555555555555555555555555555555
-- 137:6666666666666666666666666666666666666666666666666666666666666666
-- 138:3333333333333333333333333333333333333333333333333333333333333333
-- 144:44444444444444444444444444444444444aa444444a444444444444a4444444
-- 145:4444444444444444444a44444444444444444444444444444444444a4444444f
-- 146:44444444444444444a44444a4aa44f4a4aaafffa4a4aaffafaaaaafafaaaaaaa
-- 147:44444444444444444444aaa44444444444444444a4444444a4444444aa444444
-- 148:5555555555555555555555555555555555577555555755555555555575555555
-- 149:5555555555555555555755555555555555555555555555555555555a5555555f
-- 150:55555555555555555a55555a5aa55f5a5aaafffa5aaaaffafaaaaafafaaaaaaa
-- 151:5555555555555555555577755555555555555555a5555555a5555555aa555555
-- 160:4444444444444444444444444444444a444aaaa444444444444444aa4ffaaaaa
-- 161:a44444ff44444fff44444fff4444afff4444ffff444afffaaaaaaafaaaaaaaaa
-- 162:faaaafaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9aaaaaaa99aaaa9999aaaa9994
-- 163:faaa4444aaaa4444aaaaaa44afaafa44aaaaaa444aaaa4444444444444444444
-- 164:555555555555555555555555555775575557777555555555555555aa5ffaaaaa
-- 165:755555ff55555fff55555fff55557fff5555ffff5555fffaaaaaaafaaaaaaaaa
-- 166:faaaafaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9aaaaaaa99aaaa9999aaaa9995
-- 167:faaa5555aaaa5555aaaaaa55afaafa55aaaaaa555aaaa5555555555555555555
-- 176:fffaaaaaffaaaaaafaaaaaaafaaaaaaafaaaaaaaf99aaa99f4aaa999f4aa9999
-- 177:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99aaaaa999a9999999a9999999a
-- 178:aaa99994aaa99944aaa99444aaa99444aa99aa44aa9aa444aa9aa444a999a444
-- 179:44444444444444444444444444444444444a4444444444444444444444444444
-- 180:fffaaaaaffaaaaaafaaaaaaafaaaaaaafaaaaaaaf99aaa99f5aaa999f5aa9999
-- 181:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99aaaaa999a9999999a9999999a
-- 182:aaa99995aaa99955aaa99555aaa99555aa99a755aa9aa555aa9aa555a999a555
-- 183:5555555555555555555555555555555555575555555555555555555555555555
-- 192:f4aa9a44f4aa9a444faa4a4444aa4a4444aa4a4444aa4a4444a4444444444444
-- 193:4444444a4444444a4444444a4a44444aa444444a4444444a4444444444444444
-- 194:a44aa444a44aa444a44aa444a44aa444a44aa444a44aa444a444a44444444444
-- 195:4444a444444444444444444444444444aaa44444444444444444444444444444
-- 196:f5aa9a55f5aa9a555faa5a5555aa5a5555aa5a5555aa5a5555a5555555555555
-- 197:5555555a5555555a5555555a5755555a7555555a5555555a5555555555555555
-- 198:a55aa555a55aa555a55aa555a55aa555a55aa555a55aa555a555a55555555555
-- 199:5555755555555555555555555555555577755555555555555555555555555555
-- </TILES>

-- <SPRITES>
-- 000:000000000000022200002222200022220222222200001111000033330003333f
-- 001:000000002000000022000000222000022222222211100000333000003f300000
-- 002:000000000000022200002222000022220002222200022111002213330221333f
-- 003:000000002000020022000020222222002222200011100000333000003f300000
-- 004:000000000200022200002222000022220002222200021111022133f32213333f
-- 005:000002002000002022002220222222002222200011120000f3f000003f300000
-- 016:00033333000033330200233f0022222200021122002211120011111200111111
-- 017:3330000033300000ff3000002222000022220000222210002222110022221100
-- 018:22033333000033f30000233f0022222200021122002211120201111200111111
-- 019:3330000033300000ff3000002222000022220000222110002222210022221110
-- 020:002333f3000033330200233f0022222200021121012211120011111201111111
-- 021:f3f0000033300000ff3000002222001022222000212210001222211022221111
-- 032:0011111100111121001111210011112100111121001111210003331100033bbb
-- 033:12221110111112101111121011111210111113301111133011111000b7777000
-- 034:0011111100111111004111210001113100011133000141330000bb110000bb4b
-- 035:12211111111111111111101111111033311110333111100011111000b7777000
-- 036:0111111101111211011112110111121100111211000331110003331100033bbb
-- 037:12211211111110111f11203312111033221110001121100011111000b7777000
-- 048:00033bbb0000bbbb0000bbbb0000bbb00000bbb00000bbb0000bbbb0000bbbb0
-- 049:b7777000b7777700b77777000007770000077700000777000007770000077777
-- 050:0004bbbb0000bbbb0000bbbb0000bbb00000bbb00000bbb0000bbbb0000bbbb0
-- 051:b7777000b7777700b77777000007770000077700000777000007770000077777
-- 052:00003bbb0000bbbb0000bbbb0000bbbb000bbbb000bbbbb000bbbbb000bbbbbb
-- 053:b7777000b7777000b77770000007700000077000000777000007777000077770
-- 064:0000000000000eee0000eeeee00099990eeeeeee0000dddd0000d3330003d33f
-- 065:00000000e0000000ee0000009990000eeeeeeeeeddd00000333d00003f3d0000
-- 066:0000000000000eee0000eee90000e999000e9eee000eeddd00eed3330ee3d33f
-- 067:00000000e0000e00990000e09eeeee00eeeee000ddd00000333000003f300000
-- 068:000000000e000eee0000eee90000e999000e9eee000eddd20eed3323ee2d333f
-- 069:00000e00e00000e09900eee09eeeee00eeeee0002dde0000f3f000003f300000
-- 070:0000000000000ccc0000cccc0c00cccc00cccccc0000aaaa0000a3330003d33f
-- 071:00000000c0000000cc000000ccc00c00ccccc000aaa00000333000003f300000
-- 072:0000000000000ccc0000cccc0000cccc000ccccc000ccaaa00cca3330cc3d33f
-- 073:00000000c0000000cc000c00cccccc00ccccc000aaa00000333000003f300000
-- 074:0000000000000ccc0000cccc0000cccc000ccccc000caaa2ccca3323cc2d333f
-- 075:00000000c0000000cc000c00cccccc00ccccc0002aac0000f3f000003f300000
-- 080:0003d3330000dddd00000ddf00000ddd0000bbdd000bbbdd00bbbbdd00bbbbbd
-- 081:33300000dddd0000ffdd0000dddd0000dddb0000dddbb0008ddbbb00dbdbbb00
-- 082:ee03d3330000ddfd00000ddf00000ddd0000bbdd000bbbdd000bbbdd00bbbbbd
-- 083:33300000ddd00000ffd00000ddd00000dddb0000dddbb0008ddbbb00dbdbbbb0
-- 084:00ed33f3000ddddd0000dddf0000dd2200deeddd000ddddd20bbddd20bbbbbbb
-- 085:f3f00000ddd00000ffd00000ddd00000ddde00002ddddd0082dddbb02222bbbb
-- 086:0003d3330000dddd00000ddf00000ddd0000cccc000ccccc00333ccc00333ccc
-- 087:33300000dddd0000ffdd0000dddd0000cccc0000cccc3000c1cc3300ccccc300
-- 088:0003d3330000ddfd00000ddf00000ddd0000cccd000ccccc0003cccc00333ccc
-- 089:33300000ddd00000ffd00000ddd00000ddcc0000ccccc000c1ccc300ccccc330
-- 090:000d33f3000ddddd0000dddf0000dd2220000ddd000dcccc0233cccc0333cccc
-- 091:f3f00000ddd00000ffd00000ddd00000ddd00000ccc230001cccc330ccccc333
-- 096:00bbbbbb00bbbbfb00bbbbfb00bbbbfb00bbbbfb001111fb000333bb00033999
-- 097:bbbbbbb0bbbbbbb0bbbbbbb0bbbbb110bbbbb330bbbbb330bbbbb00094499000
-- 098:00bbbbbb00bbbbbb004bbbbb000bbb3b000bbb33000b4b33000099bb00009949
-- 099:bbbbbbbbbbbbbbbbbbbbb0bbbbbbb0333bbbb0333bbbb000bbbbb00094499000
-- 100:0bbbbbbb0bbbb2bb0bbbb2bb0bbbb2bb00bbb2bb00033bbb000333bb00033999
-- 101:b22bb2bbbbbbb0bbbfbb2033b2bbb03322bbb000bb2bb000bbbbb00044999000
-- 102:00333ccc00333ccc00333ccc00333ccc00333ccc00111ccc000333cc00033aaa
-- 103:ccccc330cc1ccc30ccccc330ccccc110ccccc330cc1cc330ccccc000accaa000
-- 104:00333ccc00333ccc00333ccc00333c3c00033133000331330000cccc0000aaaa
-- 105:ccccc333cc1cc333ccccc033ccccc0113cccc0333c1cc000ccccc000accaa000
-- 106:0332cccc0332cccc0323cccc0333cccc0033cccc00011ccc000333cc00033aaa
-- 107:ccccc333cfccc011c2cc203322cc2033c22cc000c1ccc000ccccc000ccaaa000
-- 112:00033999000099990000999900009990000099900000e990000eeee0000eeee0
-- 113:999990009999990099999900000999000009990000099e00000eee00000eeee0
-- 114:00049999000099990000999900009990000099900000e990000eeee0000eeee0
-- 115:999990009999990099999900000999000009990000099900000eee00000eeee0
-- 116:00003999000099990000999900009990000e999000eee99000eee99000eeeee0
-- 117:9999900099999000999990000009900000099000000eee00000eeee0000eeee0
-- 118:00033bbb0000bbbb0000bbbb0000bbb00000bbb000008bb00008888000088880
-- 119:bbbbb000bbbbbb00bbbbbb00000bbb00000bbb00000bb8000008880000088880
-- 120:0004bbbb0000bbbb0000bbbb0000bbb00000bbb000008bb00008888000088880
-- 121:bbbbb000bbbbbb00bbbbbb00000bbb00000bbb00000bbb000008880000088880
-- 122:00003bbb0000bbbb0000bbbb0000bbb00008bbb000888bb000888bb000888880
-- 123:bbbbb000bbbbb000bbbbb000000bb000000bb000000888000008888000088880
-- 128:000000000000044400000433000043f300004333000443320000443300004222
-- 129:0000000044000000344000003f40000033400000234000003440000022400000
-- 130:000000000000044400000433000043f300004233000443223000443333304222
-- 131:000000004400000034400000f340000033400000234000003440000322400333
-- 132:fff7ffff44f77744447777774747747747474744444747744447747444444774
-- 133:fffaaaaa4faaaaaa7aaaaaaa4aaaaaaa4aaaaaaa499aaa9944aaa99944aa9999
-- 134:5555555555555555555555555555555555555555555555555555555555555555
-- 135:a5555555aa555555555555555555555555a555555555aa5555aa99a555555555
-- 144:0033222200322222003222220032222200342222004322220002322200022322
-- 145:2223300022223000222230002222300022243000222340002232400023220000
-- 146:032222220032333f002333330443333f00031333000f33f30000ff3300002333
-- 147:3222323033322330333320003333400033134400f33f00003ff0000033200000
-- 148:4444444444444444444444444444444444444444444744744444444444444444
-- 149:44aa9a4444aa9a4444aa4a4444aa4a4444aa4a4444aa4a4444a4444444444444
-- 160:000222220022222200222222022222220222222200003300000033000000ff00
-- 161:222200002222200022222000222222002222220003300000033000000ff00000
-- 162:000222220022222200222222022222220222222200003300000033000000ff00
-- 163:222200002222200022222000222222002222220003300000033000000ff00000
-- 176:aaffa000aaaaa000acfcf000ac444440cc400000cc444440cc00000022000000
-- 177:e000000be6e66eebeeeeee000aa0e000aaaee000aa000000ad000000dd000000
-- 178:0aaaa0aa0e00aa0a00e00ba0000e0aba0000e00a00aa0e0a0aba00ea0ba00000
-- 179:0000000000ffff000f0df000f0077000f0766700007667000076670000077000
-- 180:b44bbbb0deeeeebbeeeeeeb00eede0000aa000000ad000000ad000000ad00000
-- 192:0e00000b8ee88eeeeeeeee000aa0ee00aaaee000aa000000aa00000088000000
-- 193:000000cd00000cdd0000cde00e0cde0000ede000098e00009810e00081000000
-- 194:00000000000d00d0088888880ddddddd08daaa00dd8bab00d800000080000000
-- 195:00000065000006560000656000f6560000ff6000aabff000a0a00000aaa00000
-- 196:00aa000000a0d00000a00d0000a000d000a0000a0aaaaaaaaba00000ba000000
-- 208:00000000c2f2222cc2222f2c522f22255c2222c565cccc567666666777777777
-- 209:0076650007655650765765656566565576767767070760700006500000075000
-- 210:0007600001176110117766111116611111111131111133110111111000111100
-- 211:00007770000707000070070000700220022022c222c202222222022002200000
-- 212:0000600600007667000011600011c17611cd1110111111101111110001111000
-- 213:0022500702c227500c2255702222262022422222222242222422222012221000
-- 214:c111111cc2c2222cc2c2222cc111111c0c1111c000c11c00000cc00000cccc00
-- 215:0000000000dded0002222220022223c00cc3cc30033222200222222000dded00
-- 216:00000a0acc444a4a02cc44440222cc44cc5522cc00cc22220000cc55000000cc
-- 217:000ff000000ee000000cc00000aaaa0000a33a0000c33c0000a33a0000aaaa00
-- 224:00999900999fcf00909444000999999009944990099449900c9009c000200200
-- </SPRITES>

-- <MAP>
-- 000:454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:4545454545454545454545454545f14545454545454545454545454545454545454545454545454545454545f1454545454545454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:4545454545454545454545454545f14545454545454545454545454545454545454545454545f14545454545f14545454545f1454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:4545454545454545454545454545f145454545454545454545454545454545454545454545f1f14545454545f14545454545f1f14545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:4545454545454545454545e045454545454545f04545454545454545454545454545454545e1e1f145454545e145454545f1e1e14545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:45454545454545454545f0e0e0e0e0f0f0e0e0e0f0f04545454545454545454545454545454545e145454545f145454545e145454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:45454545454545454545e0e0e0e0e0e0e0e0e04545454545454545454545454545454545454545454545f1f1f1f1f145454545454545454545454545000000000077777777777700000000000000007777777777770000000000f1f1f1f1f1f1f1f1e1e1f1f1f1f1f1f1f1f1f1e1e1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:454545454545454545454501010145e0e0e0454545454545454545454545454545454545454545454545f1454545f145454545454545454545454545000000000077e1e1777777000000000000000077e1e17777770000000000f1f1f1f1f1f1f1f1f1f1e1f1e1e1e1e1e1f1e1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:454545f1f1f1f1f1f14501010101e0e045454545f1f1f1f1f1f1f1454545454545f1f1f1f1f1f14545f1f145f145f1f14545f1f1f1f1f1f1f1454545000000777777e177777777777700000000777777e1777777777777000000f1f1f1f1f1f1f1f1f1f1f1e1e1e1e1e1e1e1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:454545454545454545450101014545454545454545454545454545454545454545e1e1e1e1e1e14545e1f1454545f1e14545e1e1e1e1e1e1e1454545000000770077777777777700780000000077007777777777770078000000f1f1f1f1f1f1f1f1f1f1f1e1f1f1e1f1f1e1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:454545454545454545450101014545454545454545454545454545454545454545454545454545454545f1f1f1f1f145454545454545454545454545000000007777777777777778000000000000777777777777777800000000f1f1f1f1f1f1f1f1f1f1f1e1f1e1e1e1f1e1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:454545454545454545450101014545454545454545454545454545454545454545454545454545454545e1e1f1e1e145454545454545454545454545000000000000777777780000000000000000000077777778000000000000f1f1f1f1f1f1f1f1f1f1f1e1e1e1f1e1e1e1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:45454545454545454545e0e0e045f1454545454545454545454545454545454545454545454545f145454545e145454545f145454545454545454545000000000000007778000000000000000000000000777800000000000000f1f1f1f1f1f1f1f1f1f1e1f1e1e1e1e1e1f1e1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:4545454545454545454545454545f145454545454545454545454545454545454545454545f1f1e145454545f145454545e1f1f14545454545454545000000000000007878000000000000000000000000787800000000000000f1f1f1f1f1f1f1f1e1e1f1f1e1f1e1f1e1f1f1e1e1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:4545454545454545454545454545f145454545454545454545454545454545454545454545e1f14545454545f14545454545f1e1454545454545454500000000000078787878d7d7000000000000000078787878d7d700000000f1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1e1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:4545454545454545454545454545f14545454545454545454545454545454545454545454545e14545454545f14545454545e1454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:4545454545454545454545454545454545454545454545454545454545454545454545454545454545454545e1454545454545454545454545454545000000000000000000000000000000000000000000000000000000000000f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 017:72729450505050505050414141414141414141415050505050505050505072729450505050505050414141414141414141415050505050505050505050505050505050505050505050505050505050505050505050505050505050505050505050826161616161616161616161616161a250505050505050d2d2d2d2d2d2d2d2d2d2d2d20101010101010101d2d2d2d2d2d2d2d2d2f2d2d6d6d6d6d6f6d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d6c6d2d2d2d2d25161021222326192d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2727285d2d2d2d2d2d2d241414141414141414141d2d2d2a6a6a6a6a6a6d2
-- 018:72729450505050505001010101010101010101010160405050505050505072729450505050505001010101010101010101010160405050505050505050505050505050505050505050505050505050505060405050505050505050505050505050826161616161616161616161616161a250505050505050f2d2d2d2d2d2d2d2d2d2d2010101010101010101d2010101d2d2d2c2d2d2d6d6d6d6c6d6f6d2a5a5a5a5a5a5a5a5a5a5a5a5a5d2d2d2d2f5f5f5d2b5d2d2d2c2d25161031323336192d2d2d2d2d2d2f2d2d2c2d2d2f2f2f2f2d2727285d2f2f2d2d2d2010101010101010101010101d2a5a6a6a6a68686d2
-- 019:727294406050504082313131313131313131313131a2505050605040010172729440605050409573737373737373737373737394505050605040010150504050605050405050505050505050505050505050505050605040505065656565656501010101010101010101010101010101010165656565656510f2f2f2f2d2c2d2d2d2010101010101010101010101010101d2d2d2d2d2d6d6d6c6b5d2a5a576505076507676765050765050a5d2d2e6d6d6d6f6e5c2d2d2c2d29361041424346141d2d2c2d2d2c210f2f2d2d2d2101030e2c2727285d2495969798431313131313131313131313185a6a6868686d20101
-- 020:0101010150405050508261618090a0b0c0d06161a25050504050500101010101010150405050509572728090a0b0c0d07272945050504050500101014050504050405050505050505050505050505050505050504050505050505550555055508261616161616161616161616161616161a25055505550551010051525f2f2d2d251616161616161616161619261f16161d2d2d2c2d2d6d6c6b5e5c276505096509650769696507650507686d2d2e6d6c6d6f6f5c2d2c2d2d21011b6b6b6b6b6e2c2d2d2d2d2d2103010f2c2f2103010c2d2010101014a5a6a7ad28461618090a0b0c0d0616185d28686d2d2d2010101
-- 021:7272729450505060508261618191a1b1c1d16161a26050504050826161617272729450505060509572728191a1b1c1d172729460505040509572727250505040505050605050505050505050505050505060505040505050505055555555555556615261536152616161615361526153616655555555555510100616263610d2d251615361021222326152619261f16161d2d2d2d2d2d6c6b5e5c2d2868650767650505050507650965086d2d2d2d2c2b5d6d6d6d2c2d2d2d2e2e2d2d2d2d2d2d2d2c2d2d2c2d2e2e2e210f23030e210d2d2727272854b5b6b7bf28461618191a1b1c1d1616185d2d2d2d2d284616161
-- 022:5262729460505040508201010101010101010101a250505050508261616152627294605050405095010101010101010101019450505050509572727250505050605050405050505050505050505050505050505050505050505055555555555556615361536153021222325361536153616655555555555510101017273710f2d251615361031323336153619231313121d2d2d2d2d2c6b5e5d2d2d2d2d2765050765096765050767686c2d2d2c2d2d2e5d6c6d6d2e5d2d2c2d2c2d2d2d210d2d2d2d2d2d2d2d2d2d2c2e2e210e2d2e2d2d2526272854c5c6c7cd2840101010101010101010185d2d2d2d2d284616161
-- 023:5363729450c3d350408261526202122232526261a2405050c3d3826161615363729450c3d3d340957252627212227252627294405050c3d3957272724040505050c3d3d340505050505050505050505050405050505050c3d35055555555555556615361536153031323336361636163616655555555555510e208182838e210f25161616104142434616161922020e2c2d2d2d2c2d2b5b5d2d2d2d2d2f28686868650765096768686d2f2d2d2d2d2c2d2d2b5d2d2d2d2d2d2d2d2d2d23010d2c2475767d2d2d2d2d2d2d2d2e2d2c2d2d2c253637285d2d2f2d2f2846152620212223252626185f2d2f2d2d284616161
-- 024:5363728410c4d4101051615363031323335363619210051525d5516161615363728410c4d4d41085725363721323725363728410e3f33030857272722939303010c4d4d41030303030303030302939303010e3f3051510c5d505555555555555566161616161610414243461616161616166555555555555e2c2e2e2e2e2d2e22011313131313131313131312120e2d2c2d2d2d2d2d2b5e5c2f2f2f2f210f2f2f2f28686868686f2f2f210f2f2f2f2f2d2d2e5d2d2f2d2d2d2c2d2d230d2d2d2d2485868d2d2d2c2d2d2d2d2d2d2d2d2d2d253637285f2d2d2f23084615363031323335363618530d2d2f2d284616161
-- 025:7272727410c5d510109354545404142434545454411006162636936161617272727410c5c4d51075727272721424727272727410c4d41010757272722a3a303010c5c4d510a3b3303030300a1a2a3a303010c4d4061626101006101030301010936161616161313131313131616161616141101010101010d2d2d2d2d2d2d2d2e2e2e2d2d220202010d2c2e22020d2d2d2c2d2d2d2d2e5c2f21010101010101010106161616161101010101010101010f2f2f2c2f210f2f2d2d2d2c2c2d2c2d2c2d2d2c2c2c2d2d220c2d2d2d2d2d2c2f5f57272727430d2c2e23093545454041424345454544130f2d2d2c293616161
-- 026:737373831010101010113131313131313131313121101017273711313131737373831010101010b2737373737373737373738310c5d51010b27373732b3030301010101010a4b4303030300b1b2b30303010c5d5101727371010101030301011313131313131313131313131313131313131211010101010d2c2d2c2f2f2f2f2f2f2f2f2f220202010f2f2f22020f2f2f2f2f2f2f2f2f2f2101010101010101010106161616161e21010101010101010101010f210303010d2d2c2d2d2d2d2d2d2d2d2d2d2102020d2d2d2d2c2d2d2e6d6d673737383e2d2d2d2e2113131313131313131313121e2e2c2c23011313131
-- 027:737383101020101010102010113131313121201010a3b318283810101010737383100515101010102010b27373737383201010a3b3101010101010102c30293905151010101020103030300c1c2c201010a3b310101828381010103010100510101010102010303030101010201010a3b310101028101010f2f2f2202020101020202020301010201010101020101010303071307130101010e2e2e21010e2e210e2b6b6b6b6b6d2e2e2e2e2e2e2e2e2e2101010303010e2d2d2d2d2d2d2d2c2d2d2d2d2d210101010d2d2d2c2c2c2e6d6d6737383e2d2d2d2d2d2e2e2e2113131313121e2e2e2d2d2d2d2d2e2e2e230
-- 028:101010101010101020101010101010101010102010a4b4102010e3f31010101010100616263620101010101010101010102010a4b4102010e3f310100a1a2a3a0616263620101010101010101010102010a4b4102010e3051510101010101010101010101010101010101010102010a4b4102010e30510103020102020202020202010101020101010201010102010713071307130711010e2d2d2d2e2e2d2c2e2a55040504040a5d2c2d2c2d2d2d2c2d2e2e210e2e2e2d2d2d2d2d2d2c2d2f2d2d2d2d2c2d2d2d2d2d2d2d2d2c2f5d6d6c630e2e2d2d2c2d2c2d2d2d2d2e230303030e2475767d2d2d2c2d2d2c2c230
-- 029:1010101010201010101020101020102010101010101010101010c4d410101010101010172737101020101020102010101010101010101010c4d410100b1b2b1010172737101020101020a3b310101010101010101010c40616261010101010101010101020101020a3b310101010101010101010c41010103020e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2717130303071e2e2d2d2d2d2d2d2a5a5a550505050505050a5d2d2d2d2d2d2d2c2d2d2e2c2d2d2c2d2d2c2d2d2f2f210c2d2d2d2d2d2d2d2d2d2d2f2d2e6d6d6d6b510f2f2f2f2f2f2f2f2f2f2f2f210101010f2485868f2f2f2f2f2f2f2f210
-- 030:1020a3b310301010201020201020201020201020201020203010c5d510201020a3b308182838201020201020201020201020201020e3e3f3c5e3f3200c1c2cb308182838201020201020a4b420201020201020e3e3f3c5e31727101010b308101010201020201020a4b420201020201020e3e3f3c5e3101020e2c2d2d2d2d2c2d2d2d2d2d2c2d2d2d2d2d2d2c2d2d2d2e23030713030d2d2c2c2d2d2c2a5a650767650504050405050a5a5d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2d2f2101010f2d2c2d2d2d2d2d2c2d2f210c2e6d6c6d6b5101010101010101010101010101010101010101010101010101010101010
-- 031:1010a4b430101020103010102010201010101010203010103010301020101010a4b430101020103010102010201010101010203010c4d4d430c4d4101010a4b430101020103010293910201010101010203010c4d4d430c418281010a4b430101020103010101010201010101010203010c4d4d430c41028e2d2d2d2c2d2d2d2d2d2c2d2c2d2d2d2c2c2d2d2d2d2c2d2d2e2e2e23071d2d2c2d2d2d2d2a550765040505076505050505050d2c2d2d2d2c2d2d2d2d2d2c2d2c2c2f2f21030301010f2d2d2c2c2d2d2d2d2101030d2d2b5d2e51010e2e2e2e2e2e2e2e2e2e2e2e21010e2e2e2e2e2e2e2e2e2e2e2e21010
-- 032:1010201030102020102010103010101030103020101030102010a3b310101010201030102020102010103010100515103020101030c5d5d5a3c5d510101020103010202010201a2a3a10100515103020101030c5d5d5a30515101010201030102020101010101010100510103020101030c5d5d5a3051010c2c2d2c2d2d2c2c2c2d2d2d2d2c2d2c2d2c2d2d2d2d2d2d2d2d2d2d2e2e2d2d2d2c2d2d2d25040505076505076505040504050a5c2d2d2d2c2d2d2d2c2d2d2a5a53010101030a3b31010f2c2d2d2d2f2f2f21010d2d2d2e5d24910e2d2d249596979d2d2d2d2d2d21010c2d2d2d2d2d2c2d2d2c2d2d2e210
-- 033:2030102030101010201010102010201030201010301010101010a4b430102030102030101010201010102010200616263610301010101010a4b430102030102030101010200b1b2b3910200616263610301010101010a40616262030102030101010201010101010201010101010301010101010a4101010d2d2d2d2d2d2d2d2d2d2d2c2c2d2d2d2d2d2d2d2c2d2d2d2c2d2d2d2d2d2d2d2d2d2d2d2d2505040505040505050504050764050d2d2d2d2d2d2d2d2d2c2d2303030a3b31010a4b4301010d2d2d2c21010101030d2d2d2d2d24a10c2d2c24a5a6a7ad2d2d2d2101010101010c2d2d2d2c2d2d2d2d2d2c210
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:779057c047e037f427f617f717f717f717d717c427b1278037606740773087209710a700b700c700c700d700e700f700f700f700f700f700f700f700307000000000
-- 001:f200f200f20042b502f602f702f722e732b68293e251e210f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200f200369000000000
-- 002:00e000d000d000d000c000b00090009000900090008000800070006000600050004010302020201030005000600070008000a000b000d000e000f000204000000000
-- 003:f000f000f000f000f000f000f000f000c010901060305030404040504050407040704080409040a050b050c060b070c090e0c0e0d0f0f000f000f000604000000000
-- 004:61e061e061e061e061e071e071c081b08190817091409110a100b100c100e100f100f100f100f100f100f100f100f100f100f100f100f100f100f100604000000000
-- 005:f000f000f01070207050707070a070c070c070907060c040d020e010f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000704000000000
-- 006:f300f300f3000300031003300350038003b003d003f003f003f003f003f003e003b00390036003400320f310f300f300f300f300f300f300f300f300105000000000
-- 007:f000f000e000e000d000d000c010c020b030b040a051806270726082509340a330b320c410d400e400f500f600f700f700f70007400740077007f00771b000000000
-- 008:200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000200020002000509000000000
-- 009:220222042204220322022200220d220a220a220c2200220322042204220422032200220d220a220a220c220022032205220522042202220e220b220b409000000000
-- 010:b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000b000107000000000
-- 011:03000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030020b000000000
-- 012:030003200350037003700380039003900380037003500330031003100310032003400360037003800370037003700360034003200300030003000300175000000000
-- 013:030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300030003000300308000000000
-- 016:03000300030003000300030003000300030003000300030003000300130023003300430053006300730083009300a300a300b300d300e300f300f300404000000000
-- 019:00f700f700e700e700e700d700d700c700c700b700a7009700870077006700671057204620363025402450146003700380029001a001c001d000f00042b000000000
-- 020:06e006e006e006e006e006e006e006e006d006c006b006a006a00690068006701660265026403630462056206610760086009600a600c600d600f600424000000000
-- 021:03070307030703070307030703070307030703070307030703070307130723073307430753076307730783079307a307a307b307d307e307f307f307304000000000
-- 022:6300632053405370438043a023c013d003e003e003e003d003c003b0139023703360434053306320731083009300a300b300c300d300e300f300f300309000000000
-- 023:6300632053405370438043a023c013d003e003e003e003d003c003b0139023703360434053306320731083009300a300b300c300d300e300f300f300500000000000
-- 024:1700070007100727073707570777077707a707c707d707d707e717d727c737b74797677777478737a727a717c700d700e700f700f700f700f700f700602000000000
-- </SFX>

-- <PATTERNS>
-- 000:60008a10008060008aa0008ad0008a100080a0008a100080d0008ad0008ad0008a100080000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:b00088100080b00088100080100080d00088100080100080d00088100080f0008810000010008040008a40008a100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:f00088e00088d00088e00088d00088c00088d00088c00088b00088c00088b00088a00088100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:b0008ad0008af0008a10008040008c10008060008c60008c100080000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:00000000000000000000000000000000000000000000000060008a90008ad0009ad0009ad0009ad0009ad0009ad0009ad0009ad0009ad0009a100090100090100080100080b0008a90008ad0008ab0009ab0009ab0009ab0009a60009a60009a60009a60009a60009a10008010008010008010008010008060008a80008a90009a90009a90009a90009a90009a90009a80008a60008a40009a40009a40009a40009ad00098d00098d00098d0009a40008a60009a60008a60009a60009a60009a
-- 005:6000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a86000a88000a8d000a64000a8
-- </PATTERNS>

-- <TRACKS>
-- 000:300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ec0000
-- 001:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000820000
-- 002:581700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ec0000
-- 003:300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:0418205d275db13e53eec6beffcd75a7f07038b764257179c2711c3014104c28105089b6f4f4f494b0c2566c86000404
-- </PALETTE>

