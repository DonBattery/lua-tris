-- Import modules

-- The Love2d Framework
_G.love  = require("love")

-- github.com/Ulydev/push (for scaling the window and fullscreen mode)
_G.push  = require("push")

-- Our Sound module
_G.sound = require("sound")

-- Our Game module
_G.model = require("game")


-- Automatically called by Löve once, when the game is loaded.
function love.load()
    -- Game table size
    _G.tableWidth = 10
    _G.tableHeight = 20

    -- Drawing constants
    _G.screenWidth = 640
    _G.screenHeight = 480
    _G.blockSize = math.floor(screenHeight / (tableHeight + 6))
    _G.lineWidth = 2
    _G.tableOffsetX = blockSize
    _G.tableOffsetY = math.floor((blockSize + lineWidth) * 3.5)

    -- Graphics options
    love.graphics.setLineWidth(lineWidth)
    love.graphics.setDefaultFilter("linear", "linear")
    love.graphics.setFont(love.graphics.newFont('assets/rishgulartry.ttf', 30))
    -- set up push for window scaling
    local windowWidth, windowHeight = love.graphics.getDimensions()
    windowWidth, windowHeight = windowWidth*.75, windowHeight*.75
    push:setupScreen(screenWidth, screenHeight, windowWidth, windowHeight, {
        fullscreen = false,
        resizable = true,
        highdpi = true,
        canvas = false,
    })

    -- Timers
    _G.blinkSpeed = 0.25
    _G.blinkStepper = 0

    _G.cleanSpeed = 1.5
    _G.cleanStepper = 0

    _G.barVerticalSpeed = 0.8
    _G.barVerticalStepper = 0

    _G.barHorizontalSpeed = 0.1
    _G.barHorizontalStepper = barHorizontalSpeed

    _G.barDownSpeed = 0.1
    _G.barDownStepper = barDownSpeed

    -- Switches
    _G.barColorShiftSwitch = true
    _G.blinkSwitch = true

    sound.ToggleBGM()

    -- The top level Game object
    _G.game = model.Game(tableWidth, tableHeight, true)
end

-- handle ESC and the F-keys separately (called by Löve on key pressed event)
function love.keypressed(key)
    -- ESC exits from the game
     if key == "escape" then
        love.event.quit()
     end

    -- F1 toggles fullscreen
     if key == "f1" then
        push:switchFullscreen()
     end

     -- F2 toggles the background music
     if key == "f2" then
        sound.ToggleBGM()
     end

     -- F3 toggles the sound effects
     if key == "f3" then
        if soundFXSwitch then
           soundFXSwitch = false
        else
            soundFXSwitch = true
        end
     end
end

-- Automatically called by Löve in every iteration of the game lööp, dt is the Delta Time between iterations.
function love.update(dt)
    -- Handle other keyboard input and automatic falling of the bar if the game is in running state
    if game.state == "running" then
        -- Left <-
        if love.keyboard.isDown("left") then
            if barHorizontalStepper < barHorizontalSpeed then
                barHorizontalStepper = barHorizontalStepper + dt
            else
                barHorizontalStepper = 0
                game:moveHorizontally(-1)
            end
        end

        -- Right ->
        if love.keyboard.isDown("right") then
            if barHorizontalStepper < barHorizontalSpeed then
                barHorizontalStepper = barHorizontalStepper + dt
            else
                barHorizontalStepper = 0
                game:moveHorizontally(1)
            end
        end

        if not love.keyboard.isDown("left") and not love.keyboard.isDown("right") then
            barHorizontalStepper = barHorizontalSpeed
        end

        -- Down |
        --      V
        if  love.keyboard.isDown("down") then
            if barDownStepper < barDownSpeed then
                barDownStepper = barDownStepper + dt
            else
                barDownStepper = 0
                if not game:moveDown() then
                    sound.Effects.select:play()
                end
            end
        else
            barDownStepper = barDownSpeed
        end

        -- Up   ^
        --      |
        if  love.keyboard.isDown("up") then
            if barColorShiftSwitch then
                barColorShiftSwitch = false
                game.bar:shift()
            end
        else
            barColorShiftSwitch = true
        end

        -- Move the bar down automatically when the barVerticalStepper exceeds the barVerticalSpeed
        if barVerticalStepper < game:getSpeed() then
            barVerticalStepper = barVerticalStepper + dt
        else
            barVerticalStepper = 0
            if not game:moveDown() then
                sound.Effects.select:play()
            end
        end
    end

    if game.state == "matching" then
        local matchingBlocks = game:markBlinking()
        if matchingBlocks > 0 then
            sound.Effects.whoosh:play()
            game:addBonus(matchingBlocks)
            game:changeState("cleaning")
        else
            game:flushBonus()
            game:changeState("running")
        end
    end

    if game.state == "cleaning" then
        if cleanStepper < cleanSpeed then
            cleanStepper = cleanStepper + dt
        else
            cleanStepper = 0
            game:cleanTable()
            game:changeState("matching")
        end
    end

    -- Increment the blinkStepper and reset it when exceeds the blinkSpeed
    if blinkStepper < blinkSpeed then
        blinkStepper = blinkStepper + dt
    else
        blinkStepper = 0
        blinkSwitch = not(blinkSwitch)
    end
end

-- when the window is resized we pass the new dimensions to push so it knows how to scale
-- called by Löve on window resized event
function love.resize(w, h)
    push:resize(w, h)
end

-- draw a single block of the table
local function drawBlock(x, y, color)
    love.graphics.setColor(color)
    love.graphics.rectangle(
        "fill",
        ((x - 1) * (blockSize + lineWidth)) + tableOffsetX + lineWidth,
        ((y - 1) * (blockSize + lineWidth)) + tableOffsetY + lineWidth,
        blockSize,
        blockSize)
end

-- Automatically called by Löve in every iteration of the game lööp after love.update is called. First it cleans the screen
-- with the background color, then draws the current frame of the game stage. (should draw ~60 frames per second)
function love.draw()
    -- start the auto-scaler
    push:apply("start")

    -- draw the UI
    love.graphics.setColor(0.66, 0.85, 0.33)
    love.graphics.print("Next:", 24, 17)
    love.graphics.print("Level: " .. tostring(game.level), 125, 17)
    love.graphics.print("Score: " .. tostring(game.score), 245, 17)
    if game.bonus > 0 then
        love.graphics.print("Bonus: " .. tostring(game.bonus), 245, 47)
    end
    love.graphics.rectangle("line", 0, 0, screenWidth, screenHeight)

    -- draw the table
    love.graphics.setColor(model.Colors[3])
    love.graphics.rectangle("line", tableOffsetX, tableOffsetY, (blockSize + lineWidth) * tableWidth + lineWidth, (blockSize + lineWidth) * tableHeight + lineWidth)
    for x = 1, tableWidth, 1 do
        for y = 1, tableHeight, 1 do
            local block = game.table[x][y]
            if not block.isBlinking or blinkSwitch then
                drawBlock(x, y, block.color)
            end
        end
    end

    -- draw the next bar
    for i = 1, 3 do
        love.graphics.setColor(game.nextBar.blocks[i].color)
        love.graphics.rectangle("fill", math.ceil((tableWidth * (blockSize + lineWidth)) / 2) - blockSize + tableOffsetX, (blockSize * (i - 1)) + (lineWidth * (i + 2)), blockSize, blockSize)
    end

    -- draw the current bar if the state is running or over.
    if game.state == "running" or game.state == "over" then
        for i = 1, 3 do
            drawBlock(game.bar.x, game.bar.y + i - 1, game.bar.blocks[i].color)
        end
    end

    -- stop the auto-scaler
    push:apply("end")
end
