_G.love = require("love")

function _G.Color(red, green, blue)
    return {
        red / 255,
        green / 255,
        blue / 255,
    }
end

_G.Colors = {
    -- 1 "black",
    Color(0, 0, 0),

    -- 2 "red",
    Color(255, 0 ,0),

    -- 3 "green",
    Color(0, 255 ,0),

    -- 4 "blue",
    Color(0, 0 ,255),

    -- 5 "cyan",
    Color(0, 255 ,255),

    -- 6 "purple",
    Color(255, 0 ,255),

    -- 7 "yellow",
    Color(255, 255 ,0),

    -- 8 "white",
    -- Color(255, 255 ,255),
}

_G.Levels = {
    {
        requiredScore = 0,
        speed = 1,
    },
    {
        requiredScore = 33,
        speed = 0.9,
    },
    {
        requiredScore = 100,
        speed = 0.8,
    },
    {
        requiredScore = 200,
        speed = 0.7,
    },
    {
        requiredScore = 400,
        speed = 0.6,
    },
    {
        requiredScore = 1000,
        speed = 0.5,
    },
    {
        requiredScore = 2000,
        speed = 0.4,
    },
    {
        requiredScore = 3500,
        speed = 0.3,
    },
    {
        requiredScore = 7000,
        speed = 0.2,
    },
    {
        requiredScore = 10000,
        speed = 0.1,
    },
    {
        requiredScore = 20000,
        speed = 0.05,
    },
}

function _G.Block(colorIndex)
    return {
        colorIndex = colorIndex or 1,

        color = Colors[colorIndex or 1],

        isBlinking = false,
    }
end

-- Create a new block with a random color from the Colors list, but not black.
local function getRandomBlock()
    return Block(love.math.random(#Colors - 1) + 1)
end

-- Create the game table with optional width and height and black blocks.
function _G.GameTable(width, height)
    local gameTable = {}
    for x = 1, width do
      for y = 1, height do
        if gameTable[x] == nil then
            gameTable[x] = {}
        end
        gameTable[x][y] = Block()
      end
    end
    return gameTable
end

-- Create a new game bar with 3 random blocks, positioned to the "top-center" of the table.
function _G.Bar(tableWidth)
    return {
        x = math.ceil(tableWidth / 2),
        y = 1,
        blocks = {
            getRandomBlock(),
            getRandomBlock(),
            getRandomBlock(),
        },
        -- shift the colors of the bar by one block
        shift = function (self)
            local temp = self.blocks[1]
            self.blocks[1] = self.blocks[2]
            self.blocks[2] = self.blocks[3]
            self.blocks[3] = temp
        end
    }
end

-- Game is the top level 'god' class. It knows about the table, the current and the next bar,
-- and it has a state which can be "running" "matching" "cleaning" or "over".
function _G.Game(width, height, debug)
    return {
        debug = debug,
        table = GameTable(width, height),
        bar = Bar(width),
        nextBar = Bar(width),


        level = 1,
        score = 0,
        bonus = 0,
        bonusRound = 1,
        state = "running",

        changeState = function(self, newState)
            if self.debug then
                print("Changing state from: " .. self.state .. " to: " .. newState)
            end
            self.state = newState
        end,

        -- Check if a bar can be put at x y coordinates on the table
        canPutBar = function (self, x, y)
            -- If it would "fall out" at the bottom of the table
            if y > height - 2 then
                return false
            end
            -- If it would "fall out" sideways
            if x < 1 or x > width then
                return false
            end
            for i = 0, 2 do
                -- If the block is not black
                if self.table[x][y + i].colorIndex ~= 1 then
                    return false
                end
            end
            return true
        end,

        -- Move the bar down by one step. If it cannot be moved, it will be
        -- written into the table, and the next bar will be the actual bar (a new next bar will also be created).
        -- After that we check if the actual bar can be put on the board, if not the game is over, else we enter into the cleaning state.
        moveDown = function (self)
            if not self:canPutBar(self.bar.x, self.bar.y + 1) then
                for i = 0, 2 do
                    local block = self.bar.blocks[i + 1]
                    self.table[self.bar.x][self.bar.y + i] = block
                end
                self.bar = self.nextBar
                self.nextBar = Bar(width)
                if not self:canPutBar(self.bar.x, self.bar.y) then
                    self:changeState("over")
                else
                    self:changeState("matching")
                end
            else
                self.bar.y = self.bar.y + 1
                return true
            end
            return false
        end,

        -- Move the bar horizontally if it would not hit any already occupied block, or the side of the table.
        -- if direction is -1 the bar will be moved to the left, if it is 1 then the bar will be moved to the right.
        moveHorizontally = function (self, direction)
            if self:canPutBar(self.bar.x + direction, self.bar.y) then
                self.bar.x = self.bar.x + direction
            end
        end,

        -- Check one position on the table, if it is the center of either a horizontal a vertical or cross match.
        -- Mark the matching blocks with isBlinking and return the number of newly marked blocks.
        checkPosition = function(self, x, y)
            local found = 0

            -- Skip black blocks
            if self.table[x][y].colorIndex == 1 then
                return found
            end

            local checkMatrix = {
                {
                    dx = {-1, 1},
                    dy = {0, 0},
                },
                {
                    dx = {0, 0},
                    dy = {-1, 1},
                },
                {
                    dx = {-1, 1},
                    dy = {1, -1},
                },
                {
                    dx = {-1, 1},
                    dy = {-1, 1},
                },
            }

            for _, check in ipairs(checkMatrix) do
                local stepOneX = x + check.dx[1]
                local stepOneY = y + check.dy[1]
                local stepTwoX = x + check.dx[2]
                local stepTwoY = y + check.dy[2]
                if not(
                    stepOneX < 1 or stepOneX > width or
                    stepOneY < 1 or stepOneY > height or
                    stepTwoX < 1 or stepTwoX > width or
                    stepTwoY < 1 or stepTwoY > height
                ) then
                    if self.table[x][y].colorIndex == self.table[stepOneX][stepOneY].colorIndex and
                        self.table[x][y].colorIndex == self.table[stepTwoX][stepTwoY].colorIndex then
                            if not self.table[x][y].isBlinking then
                                found = found + 1
                                self.table[x][y].isBlinking = true
                            end
                            if not self.table[stepOneX][stepOneY].isBlinking then
                                found = found + 1
                                self.table[stepOneX][stepOneY].isBlinking = true
                            end
                            if not self.table[stepTwoX][stepTwoY].isBlinking then
                                found = found + 1
                                self.table[stepTwoX][stepTwoY].isBlinking = true
                            end
                        end
                end
            end

            return found
        end,

        -- Check the whole table for matching colors, mark them with isBlinking and return the number of found matching blocks.
        markBlinking = function (self)
            local markedBlocks = 0
            for x = 1, width do
                for y = 1, height do
                    markedBlocks = markedBlocks + self:checkPosition(x, y)
                end
            end
            return markedBlocks
        end,

        -- Clear the table from blinking blocks, by building up a new table from bottom to top, skipping the currently blinking blocks.
        cleanTable = function (self)
            local newTable = GameTable(width, height)
            for x = 1, width do
                local newY = height
                for y = height, 1, -1 do
                    local block = self.table[x][y]
                    -- Add the block to the new table if it isn't black or marked for deletion 'isBlinking'
                    if not(block.colorIndex == 1 or block.isBlinking) then
                        newTable[x][newY] = block
                        newY = newY - 1
                    end
                end
            end
            self.table = newTable
        end,

        -- Increment the bonus with the bonusScore, every 3 score is one multiplier (e.g.: bonusScore 3 = bonus 3, bonusScore 4 = bonus 8, bonusScore 7 = bonus 21)
        -- and also every bonusRound is one multiplier (allowing combos). After adding the bonus the bonusRound will be incremented.
        addBonus = function (self, bonusScore)
            self.bonus = self.bonus + (bonusScore * math.ceil(bonusScore / 3) * self.bonusRound)
            self.bonusRound = self.bonusRound + 1
        end,

        -- Add bonus to the score and reset the bonus and bonusRound. Also make level up(s).
        flushBonus = function (self)
            self.score = self.score + self.bonus
            self.bonus = 0
            self.bonusRound = 1
            -- set the current level
            for levelIndex, levelData in ipairs(Levels) do
                if self.score >= levelData.requiredScore then
                    self.level = levelIndex
                end
            end
        end,

        -- Get the current game speed according to the level
        getSpeed = function (self)
            return Levels[self.level].speed
        end,
    }
end

return {
    Colors = Colors,
    Game   = Game,
}
