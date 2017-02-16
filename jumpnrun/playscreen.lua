-- Copyright (c) 2017 Raihan Kibria
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local playscreen = {
        _VERSION     = 'playscreen v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
        }

local gamemath = require "gamemath"

local staticimgdrawable = require "staticimgdrawable"
local animimgdrawable = require "animimgdrawable"
local gradientdrawable = require "gradientdrawable"

local linearmover = require "linearmover"
local jumpmover = require "jumpmover"

local cron = require "cron"
local deathTimeout = nil
local returnToIntro = false
local gameWin = false

local smallFont
local largeFont

require "stringhelpers"

--=====================================
-- CONSTS

local COL_CLS_BLOCKED = "coll_class_blocked"
local COL_CLS_COLLECT = "coll_class_collect"
local COL_CLS_DEATH = "coll_class_death"
local COL_CLS_PLATFORM = "coll_class_platform"
local COL_CLS_WIN = "coll_class_win"

local STR_ACID = "acid"
local STR_BEE = "bee"
local STR_BLOOD = "blood"
local STR_BRICK = "brick"
local STR_CLOUD = "cloud"
local STR_COIN = "coin"
local STR_HEART = "heart"
local STR_PLAYER = "player"
local STR_GATE = "rainbow"
local STR_SPIKES = "spikes"
local STR_WAVES = "waves"

local N_ORDER_BACKGROUND = 1
--
local N_ORDER_BRICKS = 2
--
local N_ORDER_CLOUDS = 3
local N_ORDER_COINS = 3
local N_ORDER_BEES = 3
local N_ORDER_SPIKES = 3
local N_ORDER_RAINBOW = 3
--
local N_ORDER_PLAYER = 4
--
local N_ORDER_WAVES = 5

local GAME_STATE_ALIVE = 1
local GAME_STATE_DEAD = 2

--=====================================

local function checkJumpOnTop(game, otherSprite, playerSprite, vy, FRICTION_BOUNCE, otherX, otherY, otherVY, y, x, otherWidth)
        vy = math.abs(vy) * (-1) * FRICTION_BOUNCE
        if otherVY ~= 0 and otherVY < vy then
                vy = vy + otherVY
        end

        y = otherY - game.gVariables.playerHeight + vy * game.gFrameDelta

        return y, vy
end

local function getSpriteSpeeds(game, sprite)
        local vx = (sprite.x - sprite.oldX) / game.gFrameDelta
        local vy = (sprite.y - sprite.oldY) / game.gFrameDelta
        return vx, vy
end

local function runPlayerMover(game, collisions, spriteName, moverData)
        local MOVE_AX = 250
        local FALL_AY = 400
        local JUMP_VY = -100
        local JUMP_WHEN_NEAR = 10

        local FRICTION_X = 0.99
        local FRICTION_BOUNCE = 0.3

        -- READ STATE
        local playerSprite = game.getSprite(spriteName)
        local x = playerSprite.x
        local y = playerSprite.y
        local vx = moverData.vx
        local vy = moverData.vy

        -- COLLISIONS
        local isBlockedVert = false
        local isBlockedHorz = false

        if game.gVariables.gameState == GAME_STATE_ALIVE and collisions[spriteName] ~= nil then
                for index, otherSpriteName in ipairs(collisions[spriteName]) do
                        local otherSprite = game.getSprite(otherSpriteName)
                        if otherSprite ~= nil then
                                local collisionClass = otherSprite.class

                                local playerX = playerSprite.oldX
                                if playerX == nil then
                                        playerX = x
                                end
                                local playerY = playerSprite.oldY
                                if playerY == nil then
                                        playerY = y
                                end

                                local otherX, otherY, otherWidth, otherHeight = game.getSpriteRect(otherSprite)
                                local otherVX, otherVY = getSpriteSpeeds(game, otherSprite)
                                local otherRightEdge = otherX + otherWidth

                                if collisionClass == COL_CLS_BLOCKED then
                                        if playerY + game.gVariables.playerHeight < otherY then
                                                -- blocked below
                                                y, vy = checkJumpOnTop(game, otherSprite, playerSprite, vy, FRICTION_BOUNCE, otherX, otherY, otherVY, y, x, otherWidth)
                                                isBlockedVert = true
                                        elseif playerY > otherY + otherHeight then
                                                -- blocked above
                                                vy = math.abs(vy) * FRICTION_BOUNCE
                                                y = otherY + otherHeight + 1
                                                isBlockedVert = true
                                        elseif playerX + game.gVariables.playerWidth < otherX then
                                                -- blocked on the right
                                                vx = vx * (-1) * FRICTION_BOUNCE
                                                x = otherX - game.gVariables.playerWidth - 1
                                                isBlockedHorz = true
                                        elseif playerX > otherRightEdge then
                                                -- blocked on the left
                                                vx = vx * (-1) * FRICTION_BOUNCE
                                                x = otherRightEdge + 1
                                                isBlockedHorz = true
                                        end

                                elseif collisionClass == COL_CLS_PLATFORM then
                                        -- lift player to over platform if near enough
                                        if playerY + game.gVariables.playerHeight < otherY + JUMP_WHEN_NEAR then
                                                -- blocked below
                                                isBlockedVert = true
                                                y, vy = checkJumpOnTop(game, otherSprite, playerSprite, vy, FRICTION_BOUNCE, otherX, otherY, otherVY, y, x, otherWidth)
                                        end

                                elseif collisionClass == COL_CLS_COLLECT then
                                        game.gVariables.numCoins = game.gVariables.numCoins + 1
                                        game.removeSprite(otherSpriteName)

                                elseif collisionClass == COL_CLS_DEATH then
                                        deathTimeout = cron.after(1, function() returnToIntro = true end)
                                        game.gVariables.gameState = GAME_STATE_DEAD
                                        if string.starts(otherSpriteName, STR_WAVES) then
                                                playerSprite.drawableName = STR_ACID
                                        else
                                                playerSprite.drawableName = STR_BLOOD
                                        end
                                elseif collisionClass == COL_CLS_WIN then
                                        deathTimeout = cron.after(1, function() returnToIntro = true end)
                                        game.gVariables.gameState = GAME_STATE_DEAD
                                        gameWin = true
                                        playerSprite.drawableName = "stickfigureGrin"
                                end
                        end
                end
        end

        local jumpAndRunAllowed = false
        local footX = playerSprite.x
        local footY = playerSprite.y + game.gVariables.playerHeight
        local footW = game.gVariables.playerWidth
        local footH = 20

        local spritesBelow = game.getNearbySprites(footX, footY, footW, footH)
        for spriteName2, v in pairs(spritesBelow) do
                if spriteName2 ~= STR_PLAYER then
                        local sprite2 = game.getSprite(spriteName2)
                        if sprite2 ~= nil then
                                local x2, y2, w2, h2 = game.getSpriteRect(sprite2)
                                local collClass = sprite2.class
                                if (collClass == COL_CLS_PLATFORM or collClass == COL_CLS_BLOCKED) and gamemath.isRectangleCollision(footX,footY,footW,footH, x2,y2,w2,h2) then
                                        jumpAndRunAllowed = true
                                        break
                                end
                        end
                end
        end

        if not isBlockedHorz then
                -- HORIZONTAL MOVEMENT
                local ax = 0
                if game.gVariables.gameState == GAME_STATE_ALIVE then
                        if jumpAndRunAllowed and game.gInputs.left == true then
                                playerSprite.drawableName = "stickfigureLeft"
                                ax = -MOVE_AX
                        elseif jumpAndRunAllowed and game.gInputs.right == true then
                                playerSprite.drawableName = "stickfigureRight"
                                ax = MOVE_AX
                        else
                                if playerSprite.drawableName == "stickfigureLeft" then
                                        playerSprite.drawableName = "stickfigureLeft-static"
                                elseif playerSprite.drawableName == "stickfigureRight" then
                                        playerSprite.drawableName = "stickfigureRight-static"
                                end
                        end
                        vx = (vx + (game.gFrameDelta * ax)) * FRICTION_X
                        x = x + vx * game.gFrameDelta
                end
        end

        if not isBlockedVert then
                if game.gVariables.gameState == GAME_STATE_ALIVE then
                        -- VERTICAL MOVEMENT
                        vy = vy + (game.gFrameDelta * FALL_AY)
                        y = y + vy * game.gFrameDelta
                end
        end

        -- JUMP CHECK
        if jumpAndRunAllowed and game.gInputs.up == true and game.gVariables.gameState == GAME_STATE_ALIVE then
                vy = math.max(-math.abs(vy) + JUMP_VY, 2 * JUMP_VY)
        end

        -- WRITE BACK
        game.moveSprite(playerSprite, x, y)
        moverData.vx = vx
        moverData.vy = vy
end

local function getDistanceAndSpeed(token)
        local restToken = string.sub(token, 2)
        local index = 1
        local dist = 0
        local speed = 0

        for strParam in string.gmatch(restToken, "[%d]+") do
                if index == 1 then
                        dist = tonumber(strParam)
                elseif index == 2 then
                        speed = tonumber(strParam)
                end
                index = index + 1
        end

        return dist, speed
end

local function moveSpriteBackForth(game, sprName, startX, startY, endX, endY, speed)
        local funcMove
        funcMove = function(collisions, spriteName, moverData)
                linearmover.create(game, sprName,
                        startX, startY,
                        endX, endY,
                        speed)
                linearmover.create(game, sprName,
                        endX, endY,
                        startX, startY,
                        speed)
                game.addMover(sprName, {moverFunc=funcMove})
                return true
        end
        funcMove()
end

local function createMovingCloud(game, cloudSprName, startCloudX, startCloudY, endCloudX, endCloudY, cloudSpeed)
        game.createSprite(cloudSprName, STR_CLOUD, COL_CLS_PLATFORM, startCloudX, startCloudY, N_ORDER_CLOUDS)
        game.setActiveCollision(cloudSprName, false)
        moveSpriteBackForth(game, cloudSprName,
                startCloudX, startCloudY,
                endCloudX, endCloudY,
                cloudSpeed)
end

local function loadLevel(game, levelData)
        local tokenFormat = "[%a%p%d]+"
        -- Determine total extent
        local cols = 0
        local rows = 0
        local iCols = 0
        for token in string.gmatch(levelData, tokenFormat) do
                iCols = iCols + 1
                if token == "EOL" then
                        rows = rows + 1
                        if iCols > cols then
                                cols = iCols - 1
                        end
                        iCols = 0
                end
        end

        game.gVariables.levelCols = cols
        game.gVariables.levelRows = rows

        game.gVariables.totalCoins = 0
        game.gVariables.numCoins = 0

        local playerStartX = 0
        local playerStartY = 0
        local c = 0
        local r = 0
        for token in string.gmatch(levelData, tokenFormat) do
                if token == "=" then
                        local spriteName = STR_BRICK .. "_" .. c .. "_" .. r
                        game.createSprite(spriteName, STR_BRICK, COL_CLS_BLOCKED,
                                c * game.gVariables.brickWidth,
                                r * game.gVariables.brickHeight,
                                N_ORDER_BRICKS
                                )
                        game.setActiveCollision(spriteName, false)
                elseif token == "c" then
                        game.gVariables.totalCoins = game.gVariables.totalCoins + 1
                        local spriteName = STR_COIN .. "_" .. c .. "_" .. r
                        game.createSprite(spriteName, STR_COIN, COL_CLS_COLLECT,
                                c * game.gVariables.brickWidth + (game.gVariables.brickWidth - game.gVariables.coinWidth) / 2,
                                r * game.gVariables.brickHeight + (game.gVariables.brickHeight - game.gVariables.coinHeight) / 2,
                                N_ORDER_COINS
                                )
                        game.setActiveCollision(spriteName, false)
                elseif token == "i" then
                        local spriteName = STR_SPIKES .. "_" .. c .. "_" .. r
                        game.createSprite(spriteName, STR_SPIKES, COL_CLS_DEATH,
                                c * game.gVariables.brickWidth,
                                r * game.gVariables.brickHeight + game.gVariables.brickHeight / 2,
                                N_ORDER_SPIKES
                                )
                        game.setActiveCollision(spriteName, false)
                elseif token == "G" then
                        game.createSprite(STR_GATE, STR_GATE, COL_CLS_WIN,
                                c * game.gVariables.brickWidth,
                                r * game.gVariables.brickHeight,
                                N_ORDER_RAINBOW
                                )
                        game.setActiveCollision(STR_GATE, false)
                elseif token == "P" then
                        if game.getSprite(STR_PLAYER) == nil then
                                playerStartX = c * game.gVariables.brickWidth
                                playerStartY = r * game.gVariables.brickHeight - game.gVariables.playerHeight
                                game.createSprite(STR_PLAYER, "stickfigureRight-static", STR_PLAYER,
                                        c * game.gVariables.brickWidth + 2,
                                        r * game.gVariables.brickHeight - game.gVariables.playerHeight - 2,
                                        N_ORDER_PLAYER
                                        )
                                game.setActiveCollision(STR_PLAYER, true)

                                game.addMover(STR_PLAYER,
                                                {
                                                moverFunc=runPlayerMover,
                                                vx = 0,
                                                vy = 0,
                                                }
                                        )
                        else
                                print("ERROR: more than one player token in map")
                                love.event.push('quit')
                        end
                elseif string.sub(token, 1, 1) == "V" then
                        local dist, speed = getDistanceAndSpeed(token)
                        local cloudSprName = STR_CLOUD .. "_" .. c .. "_" .. r
                        local startCloudX = c * game.gVariables.brickWidth
                        local startCloudY = r * game.gVariables.brickHeight
                        local endCloudX = startCloudX
                        local endCloudY = startCloudY - dist * game.gVariables.brickHeight
                        local cloudSpeed = speed
                        createMovingCloud(game, cloudSprName, startCloudX, startCloudY, endCloudX, endCloudY, cloudSpeed)
                elseif string.sub(token, 1, 1) == "H" then
                        local dist, speed = getDistanceAndSpeed(token)
                        local cloudSprName = STR_CLOUD .. "_" .. c .. "_" .. r
                        local startCloudX = c * game.gVariables.brickWidth
                        local startCloudY = r * game.gVariables.brickHeight
                        local endCloudX = startCloudX + dist * game.gVariables.brickWidth
                        local endCloudY = startCloudY
                        local cloudSpeed = speed
                        createMovingCloud(game, cloudSprName, startCloudX, startCloudY, endCloudX, endCloudY, cloudSpeed)
                elseif string.sub(token, 1, 1) == "B" then
                        local dist, speed = getDistanceAndSpeed(token)
                        local sprName = STR_BEE .. "_" .. c .. "_" .. r
                        local startX = c * game.gVariables.brickWidth
                        local startY = r * game.gVariables.brickHeight
                        local endX = startX
                        local endY = startY - dist * game.gVariables.brickHeight
                        game.createSprite(sprName, STR_BEE, COL_CLS_DEATH, startX, startY, N_ORDER_BEES)
                        game.setActiveCollision(sprName, false)
                        moveSpriteBackForth(game, sprName,
                                startX, startY,
                                endX, endY,
                                speed)
                end

                if token == "EOL" then
                        r = r + 1
                        c = 0
                else
                        c = c + 1
                end
        end

        game.gVariables.wavesTotal = game.gVariables.levelCols + 1
        game.gVariables.wavesDone = 0
        game.gVariables.waveY = (game.gVariables.levelRows - 1) * game.gVariables.brickHeight
        for i = -1, game.gVariables.levelCols - 1 do
                local waveName = STR_WAVES .. "_" .. i
                local startWaveX = i * game.gVariables.brickWidth
                game.createSprite(waveName, STR_WAVES, COL_CLS_DEATH,
                        startWaveX, game.gVariables.waveY,
                        N_ORDER_WAVES)
                game.setActiveCollision(waveName, false)

                local funcMoveWaves
                funcMoveWaves = function(collisions, spriteName, moverData)
                        linearmover.create(game, waveName,
                                startWaveX + game.gVariables.brickWidth, game.gVariables.waveY,
                                startWaveX, game.gVariables.waveY,
                                1)
                        jumpmover.create(game, waveName, startWaveX, game.gVariables.waveY)
                        game.addMover(waveName, {moverFunc=funcMoveWaves})

                        game.gVariables.wavesDone = game.gVariables.wavesDone + 1
                        if game.gVariables.wavesDone == game.gVariables.wavesTotal then
                                game.gVariables.wavesDone = 0
                                if game.gVariables.gameState == GAME_STATE_ALIVE then
                                        game.gVariables.waveY = game.gVariables.waveY - 15
                                end
                        end

                        return true
                end
                funcMoveWaves()
        end
end

playscreen.load = function(game)
        deathTimeout = nil
        returnToIntro = false
        gameWin = false

        smallFont = love.graphics.newFont(15)
        smallFont:setFilter("nearest", "nearest")
        love.graphics.setFont(smallFont)

        largeFont = love.graphics.newFont(30)
        largeFont:setFilter("nearest", "nearest")

        game.gameInit()

        gradientdrawable.create(game, "background", game.gScreen.width, game.gScreen.height,
                216, 230, 255, 255,
                0, 182, 255, 255,
                64)
        backgroundSprite = game.createSprite("background", "background", "none", 0, 0, N_ORDER_BACKGROUND)
        backgroundSprite.absolutePos = true

        staticimgdrawable.create(game, "stickfigureLeft-static", "img/stickfigure-L-1.png")
        staticimgdrawable.create(game, "stickfigureRight-static", "img/stickfigure-R-1.png")
        staticimgdrawable.create(game, STR_BRICK, "img/brick.png")
        staticimgdrawable.create(game, STR_SPIKES, "img/spikes.png")

        staticimgdrawable.create(game, STR_GATE, "img/rainbow-1.png")

        local deathDrawable = animimgdrawable.create(game, STR_ACID,
                {
                "img/skeleton-0.png",
                "img/skeleton-1.png",
                "img/skeleton-2.png",
                },
                0.2)
        deathDrawable.playOnce = true

        local bloodDrawable = animimgdrawable.create(game, STR_BLOOD,
                {
                "img/blood-1.png",
                "img/blood-2.png",
                "img/blood-3.png",
                }, 0.1)
        bloodDrawable.playOnce = true

        staticimgdrawable.create(game, "stickfigureGrin", "img/stickfigure-grin.png")
        animimgdrawable.create(game, "stickfigureLeft",
                {
                "img/stickfigure-L-1.png",
                "img/stickfigure-L-2.png",
                "img/stickfigure-L-3.png",
                "img/stickfigure-L-2.png"
                }, 0.1)
        animimgdrawable.create(game, "stickfigureRight",
                {
                "img/stickfigure-R-1.png",
                "img/stickfigure-R-2.png",
                "img/stickfigure-R-3.png",
                "img/stickfigure-R-2.png"
                }, 0.1)

        local wavesDrawable = animimgdrawable.create(game, STR_WAVES, {"img/waves-1.png", "img/waves-2.png", "img/waves-3.png", "img/waves-2.png"}, 0.2)
        wavesDrawable.penR = 255
        wavesDrawable.penG = 255
        wavesDrawable.penB = 255
        wavesDrawable.penA = 164

        animimgdrawable.create(game, STR_CLOUD,
                {
                "img/cloud_1.png",
                "img/cloud_2.png",
                "img/cloud_3.png",
                "img/cloud_2.png"
                }, 0.333)

        animimgdrawable.create(game, STR_COIN,
                {
                "img/coin_1.png",
                "img/coin_2.png",
                "img/coin_3.png",
                "img/coin_2.png"
                }, 0.1)

        animimgdrawable.create(game, STR_BEE,
                {
                "img/bee-1.png",
                "img/bee-2.png",
                }, 0.05)

        game.gVariables.playerWidth = game.gImages["img/stickfigure-L-1.png"]:getWidth()
        game.gVariables.playerHeight = game.gImages["img/stickfigure-L-1.png"]:getHeight()

        game.gVariables.brickWidth = game.gImages["img/brick.png"]:getWidth()
        game.gVariables.brickHeight = game.gImages["img/brick.png"]:getHeight()

        game.gVariables.cloudWidth = game.gImages["img/cloud_1.png"]:getWidth()
        game.gVariables.cloudHeight = game.gImages["img/cloud_1.png"]:getHeight()

        game.gVariables.coinWidth = game.gImages["img/coin_1.png"]:getWidth()
        game.gVariables.coinHeight = game.gImages["img/coin_1.png"]:getHeight()

        strLevel = love.filesystem.read("level.txt")
        loadLevel(game, strLevel)

        game.gVariables.gameState = GAME_STATE_ALIVE
end

playscreen.update = function(self, game, dt)
        if deathTimeout ~= nil then
                deathTimeout:update(dt)
        end

        game.gameUpdate(dt)

        local playerSprite = game.getSprite(STR_PLAYER)
        local x, y, w, h = game.getSpriteRect(playerSprite)
        local drawOffset = game.gSprites.drawOffset

        local highestX = game.gVariables.levelCols * game.gVariables.brickWidth
        drawOffset.x = math.min(game.gScreen.width / 2 - x, 0)
        drawOffset.x = math.max(drawOffset.x, game.gScreen.width - highestX)

        local highestY = game.gVariables.levelRows * game.gVariables.brickHeight
        drawOffset.y = math.max(game.gScreen.height / 2 - y, game.gScreen.height - highestY)

        return self
end

local function drawLargeShadowedText(game, str, y)
        love.graphics.setFont(largeFont)
        love.graphics.setColor(128, 0, 0, 255)
        love.graphics.printf(str, 0, y, 320, "center", 0, 2)
        love.graphics.setColor(255, 0, 0, 255)
        love.graphics.printf(str, 3, y + 3, 320, "center", 0, 2)
        love.graphics.setColor(255, 255, 255, 255)
end

local function drawShadowedText(game, str, x, y)
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0, 128, 0, 255)
        love.graphics.printf(str, x, y, game.gScreen.width / 2, "left", 0, 2)
        love.graphics.setColor(0, 255, 0, 255)
        love.graphics.printf(str, x + 2, y + 2, game.gScreen.width / 2, "left", 0, 2)
end

playscreen.draw = function(self, game)
        game.gameDraw()

        drawShadowedText(game,
                "Coins: " .. game.gVariables.numCoins,
                0, 0)

        if gameWin then
                drawLargeShadowedText(game, "Congratulations!\nPress key", 160)
        end

        if returnToIntro then
                if not gameWin then
                        drawLargeShadowedText(game, "GAME OVER\nPress key", 160)
                end

                if game.gInputs.left or game.gInputs.right or game.gInputs.up then
                        local introscreen = require "introscreen"
                        introscreen.load(game)
                        return introscreen
                end
        end

        return self
end

return playscreen
