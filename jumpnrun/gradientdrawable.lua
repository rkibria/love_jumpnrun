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

local gradientdrawable = {
        _VERSION     = 'gradientdrawable v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
}

gradientdrawable.draw = function(game, drawable, x, y)
        local rStep = (drawable.r2 - drawable.r1) / drawable.nSteps
        local gStep = (drawable.g2 - drawable.g1) / drawable.nSteps
        local bStep = (drawable.b2 - drawable.b1) / drawable.nSteps
        local aStep = (drawable.a2 - drawable.a1) / drawable.nSteps
        local hStep = drawable.h / drawable.nSteps
        for i=0,drawable.nSteps - 1 do
                love.graphics.setColor(
                        drawable.r1 + i * rStep,
                        drawable.g1 + i * gStep,
                        drawable.b1 + i * bStep,
                        drawable.a1 + i * aStep)
                love.graphics.rectangle('fill', x, y + i * hStep, drawable.w, hStep)
        end
        love.graphics.setColor(255, 255, 255, 255)
end

gradientdrawable.create = function(game, drawableName, w, h, r1, g1, b1, a1, r2, g2, b2, a2, nSteps)
        local drawable = game.createDrawable(drawableName, gradientdrawable.draw, w, h)
        drawable.r1 = r1
        drawable.g1 = g1
        drawable.b1 = b1
        drawable.a1 = a1

        drawable.r2 = r2
        drawable.g2 = g2
        drawable.b2 = b2
        drawable.a2 = a2

        drawable.nSteps = nSteps

        return drawable
end

return gradientdrawable
