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

local introscreen = {
        _VERSION     = 'introscreen v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
        }

local staticimgdrawable = require "staticimgdrawable"
local gradientdrawable = require "gradientdrawable"

local linearmover = require "linearmover"

local playscreen = require "playscreen"

local cron = require "cron"
local waitDone = false
local waitTimeout = nil

local gradDirection = 2

introscreen.load = function(game)
        game.gameInit()

        waitDone = false
        waitTimeout = cron.after(1, function() waitDone = true end)

        font = love.graphics.newFont(15)
        love.graphics.setFont(font)
        font:setFilter("nearest", "nearest")

        gradientdrawable.create(game, "background", game.gScreen.width, game.gScreen.height,
                216, 230, 255, 255,
                0, 182, 255, 255,
                64)
        game.createSprite("background", "background", "none", 0, 0, 1)

        staticimgdrawable.create(game, "logo", "img/titlescreen.png")
        game.createSprite("logo", "logo", "none", 0, 0, 3)

        staticimgdrawable.create(game, "heart", "img/heart.png")

        local heartW = game.gImages["img/heart.png"]:getWidth()
        local heartH = game.gImages["img/heart.png"]:getHeight()

        for i = 1, 5 do
                local heartName = "heart" .. "_" .. i
                game.createSprite(heartName, "heart", "none", 0, 0, 2)
                local funcMove
                funcMove = function(collisions, spriteName, moverData)
                        local startX = math.random(-heartW, game.gScreen.width)
                        local startY = game.gScreen.height
                        local endX = startX + math.random(-200, 200)
                        local endY = -heartH
                        local speed = 1 + math.random() * 3

                        linearmover.create(game, heartName,
                                startX, startY,
                                endX, endY,
                                speed)
                        game.addMover(heartName, {moverFunc=funcMove})
                        return true
                end
                funcMove()
        end

        staticimgdrawable.create(game, "cloud", "img/cloud_1.png")

        local cloudW = game.gImages["img/cloud_1.png"]:getWidth()
        local cloudH = game.gImages["img/cloud_1.png"]:getHeight()

        for i = 1, 2 do
                local cloudName = "cloud" .. "_" .. i
                game.createSprite(cloudName, "cloud", "none", 0, 0, 2)
                local funcMove
                funcMove = function(collisions, spriteName, moverData)
                        local startX = math.random(-cloudW, game.gScreen.width)
                        local startY = game.gScreen.height
                        local endX = startX + math.random(-200, 200)
                        local endY = -cloudH
                        local speed = 5 + math.random() * 5

                        linearmover.create(game, cloudName,
                                startX, startY,
                                endX, endY,
                                speed)
                        game.addMover(cloudName, {moverFunc=funcMove})
                        return true
                end
                funcMove()
        end

end

introscreen.update = function(self, game, dt)
        if waitTimeout ~= nil then
                waitTimeout:update(dt)
        end

        if waitDone and (game.gInputs.left or game.gInputs.right or game.gInputs.up) then
                playscreen.load(game)
                return playscreen
        else
                local backgroundDrawable = game.getDrawable("background")
                if gradDirection > 0 then
                        if backgroundDrawable.r1 <= 255 then
                                backgroundDrawable.r1 = backgroundDrawable.r1 + gradDirection
                        else
                                backgroundDrawable.r1 = 255
                                gradDirection = gradDirection * -1
                        end
                else
                        if backgroundDrawable.r1 > 0 then
                                backgroundDrawable.r1 = backgroundDrawable.r1 + gradDirection
                        else
                                backgroundDrawable.r1 = 0
                                gradDirection = gradDirection * -1
                        end
                end
                backgroundDrawable.r2 = 255 - backgroundDrawable.r1

                game.gameUpdate(dt)
                return self
        end
end

local function drawShadowedText(str, y)
        love.graphics.setColor(0, 0, 0, 255)
        love.graphics.printf(str, 0, y, 320, "center", 0, 2)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.printf(str, 2, y + 2, 320, "center", 0, 2)
end

introscreen.draw = function(self, game)
        game.gameDraw()

        drawShadowedText("MOVEMENT:\nA / D = left / right\nW = jump", 280)

        if waitDone then
                drawShadowedText("PRESS A MOVEMENT KEY TO START", 420)
        end

        return self
end

return introscreen
