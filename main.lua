function love.load()
    camera = require 'libraries/camera'
    gameCamera = camera()

    animation = require 'libraries/anim8'
    love.graphics.setDefaultFilter("nearest", "nearest")

    sti = require 'libraries/sti'
    map = sti('maps/testMap.lua')

    wf = require 'libraries/windfield'
    
    --Changes gravity x=0 y=0
    wfWorld = wf.newWorld(0, 0)

    gameAudio = {}
    gameAudio.walking = love.audio.newSource("sounds/walking.mp3", "static")
    gameAudio.music = love.audio.newSource("sounds/background.mp3", "stream")
    gameAudio.diamond = love.audio.newSource("sounds/diamond.mp3", "static")

    gameAudio.music:play()

    sprite = {}
    sprite.collider = wfWorld:newBSGRectangleCollider(400, 250, 50, 100, 10)
    sprite.collider:setFixedRotation(true)
    sprite.x = 400
    sprite.y = 200
    sprite.speed = 300
    -- sprite.sprite = love.graphics.newImage('')
    sprite.spriteSheet = love.graphics.newImage('sprites/player-sheet.png')

    sprite.grid = animation.newGrid( 12, 18, sprite.spriteSheet:getWidth(),sprite.spriteSheet:getHeight())

    sprite.animations = {}
    sprite.animations.down = animation.newAnimation(sprite.grid('1-4', 1), 0.2)
    sprite.animations.left = animation.newAnimation(sprite.grid('1-4', 2), 0.2)
    sprite.animations.right = animation.newAnimation(sprite.grid('1-4', 3), 0.2)
    sprite.animations.up = animation.newAnimation(sprite.grid('1-4', 4), 0.2)

    sprite.anim = sprite.animations.left

    diamond = {}
    diamond.spriteSheet = love.graphics.newImage('sprites/diamond-sheet.png')

    diamond.grid = animation.newGrid( 32, 32, diamond.spriteSheet:getWidth(), diamond.spriteSheet:getHeight())

    diamond.animations = {}
    diamond.animations.default = animation.newAnimation(diamond.grid('1-8', 1), 0.2)

    diamondSpawnPoints = {
        {x = 155, y = 1700},
        {x = 1440, y = 922},
        {x = 1737, y = 250},
        {x = 381, y = 1714},
        {x = 790, y = 228},
        {x = 822, y = 1100}
    }

    -- Select a random spawn point for the diamond
    local randomIndex = love.math.random(1, #diamondSpawnPoints)
    diamond.x = diamondSpawnPoints[randomIndex].x
    diamond.y = diamondSpawnPoints[randomIndex].y

    walls = {}
    if map.layers["Walls"] then
        for i, obj in pairs(map.layers["Walls"].objects) do
            local wall = wfWorld:newRectangleCollider(obj.x, obj.y, obj.width, obj.height)
            wall:setType('static')
            table.insert(walls, wall)
        end
    end
end

function resetGame()
    -- Reset game state
    foundDiamond = false
    showMessage = false

    -- Reset diamond position to a new random spawn point
    local randomIndex = love.math.random(1, #diamondSpawnPoints)
    diamond.x = diamondSpawnPoints[randomIndex].x
    diamond.y = diamondSpawnPoints[randomIndex].y
end

function love.update(dt)
    local movement = false
    local foundDiamond = false

    local xVelocity = 0
    local yVelocity = 0

    diamond.animations.default:update(dt)

    local distance = math.sqrt((sprite.x - diamond.x)^2 + (sprite.y - diamond.y)^2)

    if not foundDiamond and distance < 100 then
        foundDiamond = true
        showMessage = true
    end

    if love.keyboard.isDown("return") then
        resetGame()
    end

    if love.keyboard.isDown("right") then
        xVelocity = sprite.speed
        sprite.anim = sprite.animations.right
        movement = true
    end

    if love.keyboard.isDown("left") then
        xVelocity = sprite.speed * -1
        sprite.anim = sprite.animations.left
        movement = true
    end

    if love.keyboard.isDown("down") then
        yVelocity = sprite.speed
        sprite.anim = sprite.animations.down
        movement = true
    end

    if love.keyboard.isDown("up") then
        yVelocity = sprite.speed * -1
        sprite.anim = sprite.animations.up
        movement = true
    end

    if movement then
        gameAudio.walking:play()
    else 
        gameAudio.walking:stop()
    end

    if foundDiamond then
        gameAudio.diamond:play()
    end


    sprite.collider:setLinearVelocity(xVelocity,yVelocity)

    if movement == false then
        sprite.anim:gotoFrame(2)
    end

    wfWorld:update(dt)
    sprite.x = sprite.collider:getX()
    sprite.y = sprite.collider:getY()


    sprite.anim:update(dt)

    gameCamera:lookAt(sprite.x, sprite.y)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    --Left border
    if gameCamera.x < width/2 then 
        gameCamera.x = width/2
    end

    --Top border
    if gameCamera.y < height/2 then 
        gameCamera.y = height/2
    end

    local mapW = map.width * map.tilewidth
    local mapH = map.height * map.tileheight

    --Right border
    if gameCamera.x > (mapW - width/2) then
        gameCamera.x = (mapW - width/2)
    end

    --Bottom border
    if gameCamera.y > (mapH - height/2) then
        gameCamera.y = (mapH - height/2)
    end
end

function love.draw()

    gameCamera:attach()
        map:drawLayer(map.layers["Ground"])
        map:drawLayer(map.layers["Trees"])
        --offset settings put at half the height and width of the sprite
        sprite.anim:draw(sprite.spriteSheet, sprite.x, sprite.y, nil, 6, nil, 6, 9)
        diamond.animations.default:draw(diamond.spriteSheet, diamond.x, diamond.y, nil, 4, nil, 6, 6)
        --wfWorld:draw()
    gameCamera:detach()
    
    -- This was used to find the x and y positions for the diamonds spawn locations
    -- love.graphics.print(sprite.x,10,10)
    -- love.graphics.print(sprite.y,10,50)

    if showMessage then
        -- Set font properties
        love.graphics.setFont(love.graphics.newFont(24)) -- Set the font size to 24
        love.graphics.setColor(1, 1, 1) -- Set text color to white

        -- Draw the message with better formatting
        love.graphics.printf("Well done! You found the hidden diamond.\nPress Enter to play again.", 0, 50, love.graphics.getWidth(), "center")
    end
end