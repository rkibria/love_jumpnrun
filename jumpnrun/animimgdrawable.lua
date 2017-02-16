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

local animimgdrawable = {
        _VERSION     = 'animimgdrawable v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
}

animimgdrawable.draw = function(game, drawable, x, y)
        love.graphics.draw(game.gImages[drawable.imgFiles[drawable.curFrame]], x, y)

        if game.gDrawing[drawable.drawableName] == nil then
                game.gDrawing[drawable.drawableName] = true
                drawable.curTimeSum = drawable.curTimeSum + game.gFrameDelta
                if drawable.curTimeSum > drawable.timePerFrame then
                        drawable.curFrame = drawable.curFrame + math.floor(drawable.curTimeSum / drawable.timePerFrame)
                        drawable.curTimeSum = 0
                        if drawable.curFrame > drawable.frameCount then
                                if not drawable.playOnce then
                                        drawable.curFrame = 1
                                else
                                        drawable.curFrame = drawable.frameCount
                                end
                        end
                end
        end
end

animimgdrawable.create = function(game, drawableName, imgFiles, timePerFrame)
        for i,imgFile in ipairs(imgFiles) do
                if game.gImages[imgFile] == nil then
                        game.gImages[imgFile] = love.graphics.newImage(imgFile)
                end
        end

        local img = game.gImages[imgFiles[1]]
        local drawable = game.createDrawable(drawableName, animimgdrawable.draw, img:getWidth(), img:getHeight())
        drawable.imgFiles = imgFiles
        drawable.curFrame = 1
        drawable.curTimeSum = 0
        drawable.frameCount = table.getn(imgFiles)
        drawable.timePerFrame = timePerFrame
        return drawable
end

return animimgdrawable
