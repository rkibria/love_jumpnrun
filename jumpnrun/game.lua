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

local deque = require "deque"
local gamemath = require "gamemath"

--=====================================

local game = {
        _VERSION     = 'game v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],

        gVariables = {},
}

--=====================================
-- DRAWABLES

game.createDrawable = function(drawableName, drawFunc, w, h)
        game.gDrawables[drawableName] = {
                drawableName = drawableName,
                drawFunc = drawFunc,
                w = w,
                h = h,
                }
        return game.gDrawables[drawableName]
end

game.getDrawable = function(drawableName)
        return game.gDrawables[drawableName]
end

game.runDrawable = function(drawableName, x, y)
        local drawable = game.gDrawables[drawableName]
        if drawable.penR ~= nil then
                love.graphics.setColor(drawable.penR, drawable.penG, drawable.penB, drawable.penA)
        end
        drawable.drawFunc(game, drawable, x, y)
        if drawable.penR ~= nil then
                love.graphics.setColor(255, 255, 255, 255)
        end
end

--=====================================
-- SPRITES

game.getSprite = function(name)
        return game.gSprites.tbSprites[name]
end

game.drawSprites = function()
        local tbSprites = game.gSprites.tbSprites
        local tbDrawOrder = game.gSprites.tbDrawOrder
        local drawOffsetX = game.gSprites.drawOffset.x
        local drawOffsetY = game.gSprites.drawOffset.y
        local scrW = game.gScreen.width
        local scrH = game.gScreen.height

        for index1, tbDrawNames in ipairs(tbDrawOrder) do
                for spriteName, alwaysTrueValue in pairs(tbDrawNames) do
                        local sprite = tbSprites[spriteName]
                        local drawable = game.gDrawables[sprite.drawableName]

                        local x = sprite.x
                        local y = sprite.y
                        if not sprite.absolutePos then
                                x = x + drawOffsetX
                                y = y + drawOffsetY
                        end

                        if gamemath.isRectangleCollision(x, y, drawable.w, drawable.h, 0, 0, scrW, scrH) then
                                game.runDrawable(sprite.drawableName, x, y)
                        end
                end
        end
end

game.getSpriteRect = function(sprite)
        local drawable = game.gDrawables[sprite.drawableName]
        return sprite.x, sprite.y, drawable.w, drawable.h
end

game.getHashcode = function(bx, by)
        return bx .. "-" .. by
end

game.getBuckets = function(x, y, w, h)
        local bX1 = math.floor(x / game.HASH_BUCKET_SIZE)
        local bY1 = math.floor(y / game.HASH_BUCKET_SIZE)
        local bX2 = math.floor((x + w) / game.HASH_BUCKET_SIZE)
        local bY2 = math.floor((y + h) / game.HASH_BUCKET_SIZE)
        return bX1, bY1, bX2, bY2
end

game.getBucketAndHashcode = function(bx, by)
        local hashcode = game.getHashcode(bx, by)
        local bucket = game.gCollisions.tbHashes[hashcode]
        return bucket, hashcode
end

game.getNearbySprites = function(x, y, w, h)
        local bX1, bY1, bX2, bY2 = game.getBuckets(x, y, w, h)
        local nearbys = {}
        for bx = bX1, bX2 do
                for by = bY1, bY2 do
                        local bucket, hashcode = game.getBucketAndHashcode(bx, by)
                        if bucket ~= nil then
                                for index2, spriteName2 in ipairs(bucket) do
                                        nearbys[spriteName2] = true
                                end
                        end
                end
        end
        return nearbys
end

game.addHash = function(bx, by, spriteName)
        local hashcode = game.getHashcode(bx, by)

        local hashes = game.gCollisions.tbHashes
        if hashes[hashcode] == nil then
                hashes[hashcode] = {}
        end
        table.insert(hashes[hashcode], spriteName)
end

game.removeHash = function(bx, by, spriteName)
        local bucket, hashcode = game.getBucketAndHashcode(bx, by)
        if bucket ~= nil then
                local bSize = table.getn(bucket)
                for index, bname in ipairs(bucket) do
                        if bname == spriteName then
                                bucket[index] = bucket[bSize]
                                table.remove(bucket)
                                break
                        end
                end
        end
end

game.updateHash = function(sprite, x, y, removeOnly)
        local spriteName = sprite.name
        local x1, y1, w, h = game.getSpriteRect(sprite)

        local oldX = sprite.oldX
        local oldY = sprite.oldY
        if oldX ~= nil and oldY ~= nil then
                local bX1, bY1, bX2, bY2 = game.getBuckets(oldX, oldY, w, h)
                for bx = bX1,bX2 do
                        for by = bY1,bY2 do
                                game.removeHash(bx, by, spriteName)
                        end
                end
        end

        if not removeOnly then
                local bX1, bY1, bX2, bY2 = game.getBuckets(x, y, w, h)
                for bx = bX1,bX2 do
                        for by = bY1,bY2 do
                                game.addHash(bx, by, spriteName)
                        end
                end
        end
end

game.setActiveCollision = function(spriteName, isActive)
        game.gCollisions.tbIsActiveCollision[spriteName] = isActive
end

game.removeCollision = function(spriteName)
        game.gCollisions.tbIsActiveCollision[spriteName] = nil
end

game.addSpriteDrawOrder = function(name, drawOrder)
        if game.gSprites.tbDrawOrder[drawOrder] == nil then
                game.gSprites.tbDrawOrder[drawOrder] = {}
        end
        game.gSprites.tbDrawOrder[drawOrder][name] = true
end

game.removeSpriteDrawOrder = function(name, drawOrder)
        local orderList = game.gSprites.tbDrawOrder[drawOrder]
        orderList[name] = nil
end

game.createSprite = function(name, drawableName, class, x, y, drawOrder)
        game.gSprites.tbSprites[name] = {
                drawableName = drawableName,
                x = x,
                y = y,
                class = class,
                oldX = x,
                oldY = y,
                name = name,
                drawOrder = drawOrder
                }

        game.addSpriteDrawOrder(name, drawOrder)

        game.updateHash(game.getSprite(name), x, y, false)

        return game.gSprites.tbSprites[name]
end

game.removeSprite = function(name)
        sprite = game.gSprites.tbSprites[name]
        game.updateHash(sprite, sprite.x, sprite.y, true)
        game.removeSpriteDrawOrder(name, sprite.drawOrder)
        game.removeMover(name)
        game.removeCollision(name)

        game.gSprites.tbSprites[name] = nil
end

game.moveSprite = function(sprite, x, y)
        game.updateHash(sprite, x, y, false)
        sprite.oldX = sprite.x
        sprite.oldY = sprite.y
        sprite.x = x
        sprite.y = y
end

game.getCollisions = function()
        local tbActColl = game.gCollisions.tbIsActiveCollision
        local colls = {}

        for spriteName1, isActive1 in pairs(tbActColl) do
                if isActive1 == true then
                        local sprite1 = game.getSprite(spriteName1)
                        local x1, y1, w1, h1 = game.getSpriteRect(sprite1)

                        local collisionCandidates = game.getNearbySprites(x1, y1, w1, h1)
                        for spriteName2, v in pairs(collisionCandidates) do
                                if spriteName1 ~= spriteName2 and tbActColl[spriteName2] ~= nil then
                                        local sprite2 = game.getSprite(spriteName2)
                                        local x2, y2, w2, h2 = game.getSpriteRect(sprite2)
                                        if gamemath.isRectangleCollision(x1,y1,w1,h1, x2,y2,w2,h2) then
                                                if colls[spriteName1] == nil then
                                                        colls[spriteName1] = {}
                                                end
                                                table.insert(colls[spriteName1], spriteName2)
                                        end
                                end
                        end
                end
        end
        return colls
end

--=====================================
-- MOVERS
game.addMover = function(spriteName, moverData)
        if game.gMovers[spriteName] == nil then
                game.gMovers[spriteName] = deque.new()
        end
        game.gMovers[spriteName]:push_right(moverData)
end

game.removeMover = function (spriteName)
        game.gMovers[spriteName] = nil
end

game.runMovers = function()
        local colls = game.getCollisions()
        for spriteName, moverDeque in pairs(game.gMovers) do
                local moverData = moverDeque:peek_left()
                if moverData ~= nil then
                        local doRemove = moverData.moverFunc(game, colls, spriteName, moverData)
                        if doRemove == true then
                                moverDeque:pop_left()
                        end
                end
        end
end

--=====================================
-- GAME METHODS
game.gameInit = function()
        game.HASH_BUCKET_SIZE = 40

        game.gScreen = {}

        game.gCollisions = {
                tbIsActiveCollision={},
                tbHashes={}
                }

        game.gImages = {}

        game.gDrawables = {}

        game.gSprites = {
                tbDrawOrder={},         -- int draw order -> list of sprites to draw
                tbSprites={},           -- string sprite name -> sprite object {drawOrder: int, everything else...}
                drawOffset={x=0, y=0}
                }

        game.gMovers = {}

        game.gInputs = {
                left=false,
                right=false,
                up=false,
                lastUp=false
                }

        game.gFrameDelta = 0

        game.gDrawing = {}

        local width, height, flags = love.window.getMode()
        game.gScreen.width = width
        game.gScreen.height = height
end

game.gameUpdate = function(dt)
        game.gFrameDelta = dt

        if love.keyboard.isDown('left','a') then
                game.gInputs.left = true
        else
                game.gInputs.left = false
        end

        if love.keyboard.isDown('right','d') then
                game.gInputs.right = true
        else
                game.gInputs.right = false
        end

        game.gInputs.lastUp = game.gInputs.up
        if love.keyboard.isDown('up','w') then
                game.gInputs.up = true
        else
                game.gInputs.up = false
        end

        game.runMovers()
end

game.gameDraw = function()
        game.gDrawing = {}
        game.drawSprites()
end

--=====================================
return game
