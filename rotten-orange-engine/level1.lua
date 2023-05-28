

local level1 = {}




--minigames in starting room 
  local clockGame = {}
  clockGame.systems = {animation = true}
  clockGame.alarmTurnedOff = false
  clockGame.width = 400
  clockGame.height = 300
  --clock game animation data
  clockGame.animationData = {}
  clockGame.spriteSheet = love.graphics.newImage("alarmclockgame.png")
  clockGame.animationData.frametime = 0.1
  clockGame.animationData.triggers = {}
  clockGame.animationData.triggers[1] = function(entity, state) 
    return (not clockGame.clicked)
  end
  clockGame.animationData.playbackTypes = {}
  clockGame.animationData.playbackTypes[1] = animationHelpers.oneShot
  clockGame.animationData.animations = {}
  clockGame.animationData.animations[1] = animationHelpers.newAnimation(clockGame.spriteSheet, clockGame.width, clockGame.height, 1, 2)
  clockGame.animationData.defaultFrame = clockGame.animationData.animations[1][1]
  clockGame.visual = clockGame.animationData.animations[1][1]  
  clockGame.active = false
  clockGame.clicked = false
  --controls the operation of the minigame and drawing
  clockGame.updateMinigame = function (state, dt, mouseX, mouseY)
    
    local clockX = 135
    local clockY = 0
    
    
    --stating that the animation can be triggered again once the animation finishes
    if clockGame.visual == clockGame.animationData.defaultFrame then
      clockGame.clicked = false
    end
    
    --note how minigame functions are responsible for rendering their own respective minigames, even if they also exist as entities
    --within the scene. they do not use the rendering system
    love.graphics.draw(clockGame.spriteSheet, clockGame.visual, clockX, clockY)
   
    --this is how to get the mouse to click on game elements properly
    if love.mouse.isDown(1) and mouseX > 270 and mouseX < 390 and mouseY > 140 and mouseY < 168 then
      clockGame.alarmTurnedOff = true
      clockGame.clicked = true
    end
    
    
    
  end
  table.insert(level1, clockGame)
  
  
  --door opening
  local doorGame = {}
  doorGame.systems = {animation = true}
  doorGame.width = 710
  doorGame.height = 320
   --clock game animation data
  doorGame.animationData = {}
  doorGame.spriteSheet = love.graphics.newImage("doorgame.png")
  doorGame.animationData.frametime = 0.1
  doorGame.animationData.triggers = {}
  doorGame.animationData.triggers[1] = function(entity, state) 
    return (not doorGame.clicked)
  end
  doorGame.animationData.playbackTypes = {}
  doorGame.animationData.playbackTypes[1] = animationHelpers.oneShot
  doorGame.animationData.animations = {}
  doorGame.animationData.animations[1] = animationHelpers.newAnimation(doorGame.spriteSheet, doorGame.width, doorGame.height, 1, 2)
  doorGame.animationData.defaultFrame = doorGame.animationData.animations[1][1]
  doorGame.visual = clockGame.animationData.animations[1][1]  
  doorGame.active = false
  doorGame.clicked = false
  --controls the operation of the minigame and drawing
  doorGame.updateMinigame = function (state, dt, mouseX, mouseY)
    
    local doorX = 0
    local doorY = 0
    
    --note how minigame functions are responsible for rendering their own respective minigames, even if they also exist as entities
    --within the scene. they do not use the rendering system
    love.graphics.draw(doorGame.spriteSheet, doorGame.visual, doorX, doorY)
   
    --this is how to get the mouse to click on game elements properly
    if love.mouse.isDown(1) and mouseX > 284 and mouseX < 419 and mouseY > 57 and mouseY < 275 then
      doorGame.clicked = true
      doorGame.animationData.defaultFrame = doorGame.animationData.animations[1][2]
    end
    
  end
  
  table.insert(level1, doorGame)
  
  
  --music player entity
  local alarmSoundPlayer = {}
  alarmSoundPlayer.systems = {audioController = true}
  alarmSoundPlayer.audio = love.audio.newSource("hooverOutro.mp3", "stream")
  alarmSoundPlayer.startTrigger = function(entity, state)
    for i, e in ipairs(state) do
      if e.minigame == clockGame and (not e.minigame.alarmTurnedOff) then
        return true
      end
    end
    return false
  end
  alarmSoundPlayer.stopTrigger = function(entity, state)
    for i, e in ipairs(state) do
      if e.minigame == clockGame and e.minigame.alarmTurnedOff then
        return true
      end
    end
    return false
  end
  table.insert(level1, alarmSoundPlayer)
  
  local alarmOffSound = {}
  alarmOffSound.systems = {audioController = true}
  alarmOffSound.oneShot = true
  alarmOffSound.triggered = false
  alarmOffSound.audio = love.audio.newSource("alarmoff.wav", "static")
  alarmOffSound.trigger = function(entity, state)
    return clockGame.clicked
  end
  table.insert(level1, alarmOffSound)
  
  
  local doorOpenSound = {}
  doorOpenSound.systems = {audioController = true}
  doorOpenSound.oneShot = true
  doorOpenSound.triggered = false
  doorOpenSound.audio = love.audio.newSource("doorOpen.mp3", "static")
  doorOpenSound.trigger = function(entity, state) return doorGame.clicked end
  table.insert(level1, doorOpenSound)
  
  --building the starting room
  local bedsideTable = {}
  bedsideTable.systems = {render = true, collisionChecker = true, proximityChecker = true, minigameActivator = true}
  bedsideTable.x = 50
  bedsideTable.y = 200
  bedsideTable.width = 100
  bedsideTable.height = 100
  bedsideTable.proximityFieldRadius = 120
  bedsideTable.minigame = clockGame
  bedsideTable.visual = love.graphics.newImage("dresser.png")
  table.insert(level1, bedsideTable)
  
  --door (triggers minigame to enter next level)
  local door = {}
  door.systems = {render = true, collisionChecker = true, proximityChecker = true, minigameActivator = true}
  door.x = 525
  door.y = 0
  door.width = 200
  door.height = 25
  door.proximityFieldRadius = 120
  door.minigame = doorGame
  door.visual = love.graphics.newImage("door.png")
  table.insert(level1, door)
  
  local bed = {}
  bed.systems = {render = true, collisionChecker = true}
  bed.x = 50
  bed.y = 350
  bed.width = 345
  bed.height = 200
  bed.visual = love.graphics.newImage("bed.png")
  table.insert(level1, bed)
  
  local desk = {}
  desk.systems = {render = true, collisionChecker = true}
  desk.x = 150
  desk.y = 0
  desk.width = 250
  desk.height = 125
  desk.visual = love.graphics.newImage("desk.png")
  table.insert(level1, desk)
  
  local carpet = {}
  carpet.systems = {render = true}
  carpet.x = 500
  carpet.y = 150
  carpet.width = 250
  carpet.height = 400
  carpet.visual = love.graphics.newImage("carpet.png")
  table.insert(level1, carpet)
  
  
  local player = {}
  player.systems = {render = true, keyboardMovement = true, targetMovement = true, movementRotation = true, collisionChecker = true, unintersectCollisions = true, animation = true, proximityChecker = true}
  player.x = 400
  player.y = 400
  player.movementTargetX = 470
  player.movementTargetY = 450
  player.speed = 200
  player.width = 100
  player.height = 100
  player.rotation = math.pi
  player.spriteSheet = love.graphics.newImage("player.png")
  --player animation data
  player.animationData = {}
  player.animationData.frametime = 0.1
  player.animationData.triggers = {}
  player.animationData.triggers[1] = function(entity, state) 
    return (entity.x ~= entity.movementTargetX or entity.y ~= entity.movementTargetY) 
  end
  player.animationData.playbackTypes = {}
  player.animationData.playbackTypes[1] = animationHelpers.pingpong
  player.animationData.animations = {}
  player.animationData.animations[1] = animationHelpers.newAnimation(player.spriteSheet, player.width, player.height, 1, 5)
  player.animationData.defaultFrame = player.animationData.animations[1][3]
  
  player.visual = player.animationData.animations[1][3]
  table.insert(level1, player)
  
  local leftWall = {}
  leftWall.systems = {collisionChecker = true}
  leftWall.x = 0
  leftWall.y = 0
  leftWall.width = 1
  leftWall.height = love.graphics.getHeight()
  table.insert(level1,leftWall)
  
  local rightWall = {}
  rightWall.systems = {collisionChecker = true}
  rightWall.x = love.graphics.getWidth()
  rightWall.y = 0
  rightWall.width = 1
  rightWall.height = love.graphics.getHeight()
  table.insert(level1,rightWall)
  
  local bottomWall = {}
  bottomWall.systems = {collisionChecker = true}
  bottomWall.x = 0
  bottomWall.y = love.graphics.getHeight()
  bottomWall.width = love.graphics.getWidth()
  bottomWall.height = 1
  table.insert(level1,bottomWall)
  
  local topWall = {}
  topWall.systems = {collisionChecker = true}
  topWall.x = 0
  topWall.y = 0
  topWall.width = love.graphics.getWidth()
  topWall.height = 1
  table.insert(level1,topWall)
  
  
  local minigameWindow = {}
  minigameWindow.systems = {render = true, targetMovement = true, minigameController = true}
  minigameWindow.minigameActive = false
  minigameWindow.x = 50
  minigameWindow.y = -520
  minigameWindow.speed = 900
  minigameWindow.movementTargetX = 50
  minigameWindow.movementTargetY = -10
  minigameWindow.width = 710
  minigameWindow.height = 320 
  minigameWindow.minigameCanvas = love.graphics.newCanvas(minigameWindow.width, minigameWindow.height)
  minigameWindow.backgroundVisual = love.graphics.newImage("minigamewindow.png")
  minigameWindow.visual = minigameWindow.minigameCanvas
  minigameWindow.guiElement = true
  table.insert(level1,minigameWindow)
  
  
  
  --here as a reference for scripted sequences
  local npcTest = {}
  npcTest.systems = {render = true, targetMovement = true, movementRotation = true, animation = true, scriptedSequence = true}
  npcTest.x = 700
  npcTest.y = 400
  npcTest.movementTargetX = 0
  npcTest.movementTargetY = 0
  npcTest.speed = 200
  npcTest.width = 100
  npcTest.height = 100
  npcTest.rotation = math.pi
  npcTest.spriteSheet = love.graphics.newImage("player.png")
  --player animation data
  npcTest.animationData = {}
  npcTest.animationData.frametime = 0.1
  npcTest.animationData.triggers = {}
  npcTest.animationData.triggers[1] = function(entity, state) 
    return (entity.x ~= entity.movementTargetX or entity.y ~= entity.movementTargetY) 
  end
  npcTest.animationData.playbackTypes = {}
  npcTest.animationData.playbackTypes[1] = animationHelpers.pingpong
  npcTest.animationData.animations = {}
  npcTest.animationData.animations[1] = animationHelpers.newAnimation(npcTest.spriteSheet, npcTest.width, npcTest.height, 1, 5)
  npcTest.animationData.defaultFrame = npcTest.animationData.animations[1][3]
  
  npcTest.visual = npcTest.animationData.animations[1][3]
  
  --walking to 2 locations script
  npcTest.scriptTriggers = {
   function(entity, state)
     return CURRENT_TIME < 1
    end
  }
  
  npcTest.scripts = {
      
      {script = {{movementTargetX = 200, movementTargetY = 0}, {movementTargetX = 100, movementTargetY = 400}},
        advancementConditions = {
         function(entity, state) return (entity.movementTargetX == entity.x and entity.movementTargetY == entity.y) end, 
         function(entity, state) return (entity.movementTargetX == entity.x and entity.movementTargetY == entity.y) end
        }
      }
      
        
    
  }
  -- table.insert(state, npcTest)
  
  local levelChangeTrigger = function() return doorGame.clicked end
  local levelPassData = function() return {alarmTurnedOff = clockGame.alarmTurnedOff} end
  local levelTransition = newLevelTransition(levelChangeTrigger, "level2", levelPassData)
  table.insert(level1, levelTransition)
  
  
  local sceneCam = {}
  sceneCam.systems = {cameraController = true, scriptedSequence = true, targetMovement = true}
  sceneCam.zoom = 2.3
  sceneCam.x = player.x + 30
  sceneCam.y = player.y + 35
  sceneCam.speed = 100
  sceneCam.movementTargetX = sceneCam.x
  sceneCam.movementTargetY = sceneCam.y
  sceneCam.triggeredOpeningZoomScript = false
  
  --walking to 2 locations script
  sceneCam.scriptTriggers = {
   function(entity, state)
     return ((player.x > sceneCam.x + 50 or player.y < sceneCam.y - 70) and not sceneCam.triggeredOpeningZoomScript)
    end
  }
  
  sceneCam.scripts = {
      
      {script = {{movementTargetX = love.graphics.getWidth()/2, movementTargetY = love.graphics.getHeight()/2, targetZoom = 1, triggeredOpeningZoomScript = true}},
        advancementConditions = {
         function(entity, state) return (entity.movementTargetX == entity.x and entity.movementTargetY == entity.y) end
        }
      }
      
        
    
  }

  table.insert(level1, sceneCam)
  
  
state = level1
  