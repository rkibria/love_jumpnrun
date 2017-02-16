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

local linearmover = {
        _VERSION     = 'linearmover v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
}

linearmover.run = function(game, collisions, spriteName, moverData)
        local thisSprite = game.getSprite(spriteName)

        local startX = moverData.startX
        local endX = moverData.endX
        local startY = moverData.startY
        local endY = moverData.endY
        local travelTime = moverData.travelTime

        local totalDistX = endX - startX
        local totalDistY = endY - startY
        local totalDistance = math.sqrt(totalDistX * totalDistX + totalDistY * totalDistY)

        if moverData.firstRun == true then
                game.moveSprite(thisSprite, startX, startY)
                moverData.vx = totalDistX / travelTime
                moverData.vy = totalDistY / travelTime
                moverData.firstRun = false
        end

        local x = thisSprite.x
        local y = thisSprite.y
        local doRemove = false

        x = x + moverData.vx * game.gFrameDelta
        y = y + moverData.vy * game.gFrameDelta

        local distX = x - startX
        local distY = y - startY
        local distance = math.sqrt(distX * distX + distY * distY)
        if distance >= totalDistance then
                x = endX
                y = endY
                doRemove = true
        end

        game.moveSprite(thisSprite, x, y)
        return doRemove
end

linearmover.create = function(game, spriteName, sx, sy, ex, ey, travelTime)
        game.addMover(spriteName, {
                        moverFunc=linearmover.run,
                        startX = sx,
                        startY = sy,
                        endX = ex,
                        endY = ey,
                        travelTime = travelTime,
                        firstRun = true
                        }
                )
end

return linearmover
