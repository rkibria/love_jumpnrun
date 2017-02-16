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

local P = {
        _VERSION     = 'gamemath v1.0.0',
        _DESCRIPTION = 'Library',
        _URL         = 'http://',
        _LICENSE     = [[
                ... (license text, or name/url for long licenses)
                ]],
}

local function getIntervalOverlap(ax1, aw, bx1, bw)
        if ax1 >= bx1 then
                local bx2 = bx1 + bw
                if bx2 >= ax1 then
                        return math.min(aw, bx2 - ax1)
                end
        else
                local ax2 = ax1 + aw
                if bx1 <= ax2 then
                        return math.min(bw, ax2 - bx1)
                end
        end
        return 0
end

local function isRectangleCollision(x1,y1,w1,h1, x2,y2,w2,h2)
        return x1 < x2+w2 and
                x2 < x1+w1 and
                y1 < y2+h2 and
                y2 < y1+h1
end

gamemath = {
        getIntervalOverlap = getIntervalOverlap,
        isRectangleCollision = isRectangleCollision,
        }

return gamemath
