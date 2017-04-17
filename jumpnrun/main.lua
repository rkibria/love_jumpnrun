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

-- c:\Python27\python.exe ../emscripten/tools/file_packager.py game.data --preload c:\programming\jumpnrun@/ --js-output=game.js

debug = true

require "stringhelpers"

local game = require "game"
local gamemath = require "gamemath"

local introscreen = require "introscreen"
local currentScreen = introscreen

----------------------------------------------------------------
function love.load(arg)
        math.randomseed(os.time())

        currentScreen.load(game)
end

----------------------------------------------------------------
local updateTimeSum = 0
local updateCount = 0

function love.update(dt)
        local start = love.timer.getTime()

        if dt > 0.1 then
                dt = 0.1
        end

        if love.keyboard.isDown('escape') then
                love.event.push('quit')
        end

        currentScreen = currentScreen.update(currentScreen, game, dt)

        local result = love.timer.getTime() - start
        updateCount = updateCount + 1
        updateTimeSum = updateTimeSum + result
        if updateCount == 100 then
                -- print(string.format("game.update: %.3f ms", (updateTimeSum / updateCount) * 1000 ))
                updateCount = 0
                updateTimeSum = 0
        end
end

----------------------------------------------------------------
local drawTimeSum = 0
local drawCount = 0

function love.draw()
        local start = love.timer.getTime()

        currentScreen = currentScreen.draw(currentScreen, game)

        local result = love.timer.getTime() - start
        drawCount = drawCount + 1
        drawTimeSum = drawTimeSum + result
        if drawCount == 100 then
                -- print(string.format("# game.draw: %.3f ms", (drawTimeSum / drawCount) * 1000 ))
                -- print(string.format("# gFrameDelta: %.3f", game.gFrameDelta))
                drawCount = 0
                drawTimeSum = 0
        end
end
