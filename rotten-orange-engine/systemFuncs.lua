--note: came up with a possible optimization for proximity triggers: they could just call proximity detection for themselves



--all the functions we will be writing will go down here

systemFuncs = {}


--last resort system for hacking stuff in
function systemFuncs.miscFuncRunner(entity, state, dt)
  
  entity.miscFunc(entity, state, dt)
  
  return entity
  
end

function systemFuncs.fade(entity, state, dt)
  
  if entity.opacity ~= entity.fadeTarget then
    
    if entity.opacity < entity.fadeTarget then
      entity.opacity = entity.opacity + 0.025
    else
      entity.opacity = entity.opacity - 0.025
    end
  end
  return entity
  
end

--handles scripted sequences for entities
function systemFuncs.scriptedSequence(entity, state, dt)
  
  if  entity.scriptStep == nil then 
    
    
    --the script triggers are functions that return booleans, like other triggers in the engine
    for i,trigger in ipairs(entity.scriptTriggers) do 
    
      if trigger(entity, state) then
        
        entity.runningScript = entity.scripts[i]
        entity.scriptStep = 1
        
        for field, assignedValue in pairs(entity.runningScript.script[entity.scriptStep]) do
          
          if type(assignedValue) == 'function' then
            entity[field] = assignedValue()
          else 
            entity[field] = assignedValue
          end
          
        end
        
        
        --right now, only one script at a time may play, and the first trigger encountered will determine what script plays
        break
      end
      
    
    end
  
elseif entity.scriptStep < #entity.runningScript.script then
  
    --hack to break out of a script
    if entity.scriptStop then
      entity.scriptStep = nil
      entity.scriptStop = nil
      return nil
    end
    
    --advancement conditions are boolean-returning functions for advancing to the next step 
    if entity.runningScript.advancementConditions[entity.scriptStep](entity, state) then 
      entity.scriptStep = entity.scriptStep + 1
      
      for field, assignedValue in pairs(entity.runningScript.script[entity.scriptStep]) do
        if type(assignedValue) == 'function' then
          entity[field] = assignedValue()
        else 
          entity[field] = assignedValue
        end
      end
    
    --note that the script steps evaluate functional parameters and simply assign value parameters. Functional parameters, however
    --are updated continuously
    else
      
      for field, assignedValue in pairs(entity.runningScript.script[entity.scriptStep]) do
          if type(assignedValue) == 'function' then
            entity[field] = assignedValue()
          else 
            entity[field] = assignedValue
          end
      end
      
    end
    
  elseif entity.scriptStep == #entity.runningScript.script then
    
    for field, assignedValue in pairs(entity.runningScript.script[entity.scriptStep]) do
      if type(assignedValue) == 'function' then
        entity[field] = assignedValue()
      end
    end
    
    if entity.runningScript.advancementConditions[entity.scriptStep](entity, state) then 
      entity.scriptStep = entity.scriptStep + 1
    end
  
  else
  
    entity.scriptStep = nil
    
  end
  
end

--for controlling the camera, which also depends on the targeted movement and movement scripting(tbd) systems
function systemFuncs.cameraController(entity, state, dt)
  
  --references and updates the global camera variable
  globalCam:lookAt(entity.x, entity.y)
  
  
  local zoomRate = 0.01
  --smooth (but fixed rate) zooming for the camera
  if entity.targetZoom ~= nil then
    if entity.zoom < entity.targetZoom - zoomRate then
      entity.zoom = entity.zoom + zoomRate
    elseif entity.zoom > entity.targetZoom then
      entity.zoom = entity.zoom - zoomRate
    end
  end
  
  
  globalCam:zoomTo(entity.zoom)

  return entity
  
end

function systemFuncs.audioController(entity, state, dt)
  
  if entity.oneShot == true then
    if entity.trigger(entity, state) and (not entity.triggered) then
      love.audio.play(entity.audio)
      entity.triggered = true
    else
      if not entity.trigger(entity,state) then
        entity.triggered = false
      end
    end
    return entity
  end
  
  if not entity.audio:isPlaying() and entity.startTrigger(entity, state) then
    
    love.audio.play(entity.audio)
    
  end
  
  if entity.audio:isPlaying() and entity.stopTrigger(entity, state) then
    
    love.audio.stop(entity.audio)
    
  end
  
  return entity
  
end

function systemFuncs.minigameController(entity, state, dt)
  
  entity.movementTargetY = -600
  
  local minigameActive = false
  
  for i,v in ipairs(state) do
    
    
    if v.minigameTriggered ~= nil and v.minigameTriggered then
      
      entity.movementTargetY = -10
      
      --drawing the minigame to its own canvas, which is then later rendered as the visual for the minigame window.
      love.graphics.setCanvas(entity.minigameCanvas)
        
        love.graphics.draw(entity.backgroundVisual, 0, 0)     
        
        local mouseX, mouseY = love.mouse.getPosition()
        local windowMouseX, windowMouseY = mouseX - entity.x, mouseY - entity.y
        
        v.minigame.updateMinigame(state, dt, windowMouseX, windowMouseY)
      
    end
    
    love.graphics.setCanvas()
    
  end
  
  return entity
  
end


function systemFuncs.minigameActivator(entity, state, dt)
  
  entity.minigameTriggered = false
  
  if entity.entitiesWithinProximity ~= nil then
    for i,v  in ipairs(entity.entitiesWithinProximity) do
      
      --kinda jank way to test if the entity being looked at is the player
      if v.systems['keyboardMovement'] ~= nil then
        entity.minigameTriggered = true
      end
      
    end
  end
  
  return entity
  
end

--currently supports looping and pingponging animations
function systemFuncs.animation(entity, state, dt)
  
  local frameCount = math.floor(CURRENT_TIME/entity.animationData.frametime)
  
  local animationChosen = false
  
  
  
  --picking using the animation data format
  for i,v in ipairs(entity.animationData.triggers) do
    
    if v(entity, state) then
            
      --checking if the animation has changed, and resetting the start frame accordingly
      if entity.currentAnimation ~= entity.animationData.animations[i] then
        entity.currentAnimationStartFrame = frameCount
      end
      
      --a frame return value of -1 indicates the default frame
      if entity.animationData.playbackTypes[i](frameCount,#entity.animationData.animations[i], entity.currentAnimationStartFrame) == -1 then 
        entity.visual = entity.animationData.defaultFrame
      else
        --chooses the animation frame to display based on the supplied playback type function of the same index
        entity.visual = entity.animationData.animations[i][entity.animationData.playbackTypes[i](frameCount,#entity.animationData.animations[i], entity.currentAnimationStartFrame)]
      end
      
      animationChosen = true
      
      --storing persistent information in the animated entity to know when animation changes occur
      entity.currentAnimation = entity.animationData.animations[i]
    end
        
  end
  
  if not animationChosen then 
    entity.currentAnimationStartFrame = nil
    entity.currentAnimation = nil
    entity.visual = entity.animationData.defaultFrame 
    
  end
  
  return entity
  
end

function systemFuncs.targetMovement(entity, state, dt)
  
  local directionVectorX = entity.movementTargetX - entity.x
  local directionVectorY = entity.movementTargetY - entity.y
  local directionVectorMagnitude = math.sqrt(directionVectorX*directionVectorX + directionVectorY*directionVectorY)
  local directionVectorNormalX = directionVectorX/directionVectorMagnitude
  local directionVectorNormalY = directionVectorY/directionVectorMagnitude
  
  if not (entity.x >= entity.movementTargetX - entity.speed/2*dt and entity.x <= entity.movementTargetX + entity.speed/2*dt and entity.y >= entity.movementTargetY - entity.speed/2*dt and entity.y <= entity.movementTargetY + entity.speed/2*dt) then
    entity.x = entity.x + directionVectorNormalX*entity.speed*dt
    entity.y = entity.y + directionVectorNormalY*entity.speed*dt
  else 
    entity.x = entity.movementTargetX
    entity.y = entity.movementTargetY
  end
  
  --hacky ass way to stop collision bouncing on edges for the player charachter hrrmmph
  if entity.systems['keyboardMovement'] == true and entity.systems['unintersectCollisions'] == true then
    systemFuncs.collisionChecker(entity, state, dt)
    systemFuncs.unintersectCollisions(entity, state, dt)
  end
  
  return entity
  
end

function systemFuncs.keyboardMovement(entity, state, dt)
  
  --cancels out other movement targets
  entity.movementTargetX = entity.x
  entity.movementTargetY = entity.y
  
  if love.keyboard.isDown("w") then
    
    entity.movementTargetY = entity.y - entity.speed*dt-1
    
  end
  
  if love.keyboard.isDown("s") then
    
    entity.movementTargetY = entity.y + entity.speed*dt+1
    
  end
  
  if love.keyboard.isDown("a") then
    
    entity.movementTargetX = entity.x - entity.speed*dt-1
    
    if love.keyboard.isDown("w") then
      
      local vect = entity.speed*(DIAGONAL_TRIG)
      
      entity.movementTargetX = entity.x - vect*dt - 1
      entity.movementTargetY = entity.y - vect*dt - 1
      
    end
    
    if love.keyboard.isDown("s") then
      
      local vect = entity.speed*(DIAGONAL_TRIG)
      
      entity.movementTargetX = entity.x - vect*dt - 1
      entity.movementTargetY = entity.y + vect*dt + 1
      
    end
    
  end
  
  if love.keyboard.isDown("d") then
    
    entity.movementTargetX = entity.x + entity.speed*dt+1
    
    if love.keyboard.isDown("w") then
      
      local vect = entity.speed*(DIAGONAL_TRIG)
      
      entity.movementTargetX = entity.x + vect*dt + 1
      entity.movementTargetY = entity.y - vect*dt - 1
      
    end
    
    if love.keyboard.isDown("s") then
      
      local vect = entity.speed*(DIAGONAL_TRIG)
      
      entity.movementTargetX = entity.x + vect*dt + 1
      entity.movementTargetY = entity.y + vect*dt + 1
      
    end
    
  end
  
  
  return entity
  
end


function systemFuncs.movementRotation(entity, state, dt)

  if not (entity.movementTargetX == entity.x and entity.movementTargetY == entity.y) then
    entity.rotation = math.atan((entity.movementTargetY - entity.y)/(entity.movementTargetX - entity.x))
    
    if entity.movementTargetX - entity.x < 0 then
      entity.rotation = entity.rotation + math.pi
    end
    
  else
    
    if entity.restingTargetX ~= nil and entity.restingTargetY ~= nil then
      entity.rotation = math.atan((entity.restingTargetY - entity.y)/(entity.restingTargetX - entity.x))
     -- if entity.restingTargetX - entity.x < 0 then
     --   entity.rotation = entity.rotation + math.pi
     -- end
    end
  
  end
  
  return entity
  
end

function systemFuncs.proximityChecker(entity, state, dt)
  
  entity.entitiesWithinProximity = {}
  
  for i,v in ipairs(state) do
    
    if v ~= entity and v.systems['proximityChecker'] ~= nil then
      local xDist = v.x - entity.x
      local yDist = v.y - entity.y
      local dist = math.sqrt(xDist*xDist + yDist*yDist)
      
      if entity.proximityFieldRadius ~= nil and dist < entity.proximityFieldRadius then
        table.insert(entity.entitiesWithinProximity, v)
        
      end
    end
    
  end
  
  return entity
  
end

function systemFuncs.collisionChecker(entity, state, dt)
  
  --table of multiple collided entities, in case there are multiple collisions
  entity.collidedWith = {}
  
  for i,v in ipairs(state) do
    
    if v ~= entity and v.systems["collisionChecker"] == true and v.x + v.width > entity.x and v.x < entity.x + entity.width and v.y + v.height > entity.y and v.y < entity.y + entity.height then
      
      table.insert(entity.collidedWith, v)
    end
    
  end
  
  return entity
  
end


function systemFuncs.unintersectCollisions(entity, state, dt)
  
  
  if entity.collidedWith ~= nil then
    
    
    for i,v in ipairs(entity.collidedWith) do
            
            
      local leftSideDepth = entity.x+entity.width - v.x
      local rightSideDepth = v.x+v.width - entity.x
      local topDepth = entity.y+entity.height - v.y
      local bottomDepth = v.y+v.height-entity.y
      
      local findArr = {leftSideDepth, rightSideDepth, topDepth, bottomDepth}
      
      local smallest = 1
      
      --finding which side is most shallow
      
      for tempidx, tempval in ipairs(findArr) do
              
        if tempval < findArr[smallest] then
          
          smallest = tempidx
          
        end
        
      end
      
      
      if smallest == 1 then
        entity.x = entity.x - (findArr[smallest])
      elseif smallest == 2   then
        entity.x = entity.x + (findArr[smallest])
      elseif smallest == 3 then
        entity.y = entity.y - (findArr[smallest])
      elseif smallest == 4 then
        entity.y = entity.y + (findArr[smallest])
      end
      
    end
    
  end
    
  return entity
  
end


--rendering systems are the only functions that can have side effects
function systemFuncs.render(entity, state, dt)

  table.insert(currentFrameDrawables, entity)
  
  return entity
  
end


--2d physics
function systemFuncs.physics2D(entity, state, dt)
  
  local netForce = {x = 0, y = 0}
  
  --compute net force from all active forces
  for i,v in ipairs(entity.forces) do
    
    netForce.x = netForce.x + v.x
    netForce.y = netForce.y + v.y
    
  end
  
  --if there's no "velocity", make it
  if entity.velocity == nil then entity.velocity = {x = 0, y = 0} end
  
  --if there's no "acceleration", make it
  if entity.acceleration == nil then entity.acceleration = {x = 0, y = 0} end
  
  --no check for mass, entity must have mass or an error will be thrown
  entity.acceleration.x = netForce.x/entity.mass
  entity.acceleration.y = netForce.y/entity.mass
  
  entity.velocity.x = entity.velocity.x + entity.acceleration.x
  entity.velocity.y = entity.velocity.y + entity.acceleration.y
  
  entity.x = entity.x + entity.velocity.x*dt
  entity.y = entity.y + entity.velocity.y*dt
  
  return entity
  
end


--seperate helper functions


--animation helper functions (constructors and whatnot)
animationHelpers = {}
function animationHelpers.newAnimation(sheet, width, height, startframe, endframe)
  
  local spritesheet = sheet
  local frames = {}
  
  for i = startframe-1, endframe-1, 1 do
    table.insert(frames, love.graphics.newQuad(i*width, 0, width, height, spritesheet:getDimensions()))
    
  end
  
  return frames
end

function animationHelpers.oneShot(framecount, animationLength, startframe)
  if (framecount-startframe)+1 <= animationLength then
    return (framecount - startframe)+1
  else 
    return (-1)
  end
  
end

function animationHelpers.looping(framecount, animationLength, startframe)
  
  return math.fmod(framecount, animationLength)+1
  
end

function animationHelpers.pingpong(framecount, animationLength, startframe)
  
  local evenOdd = math.fmod(framecount, animationLength*2)
  
  if evenOdd >= animationLength then
    return animationLength - (math.fmod(framecount, animationLength))
  end
  
  return math.fmod(framecount, animationLength)+1
  
end



--helper function to abstract away the creation of level transitions
--trigger is a boolean level change condition housed in a function (because lua won't let me pass by reference otherwise), nextlevel is the name of the next level file, passVals is a function that returns a table of values to carry over between levels
function newLevelTransition(trigger, nextLevel, passVals)
  local levelTransition = {}
  levelTransition.systems = {render = true, scriptedSequence = true, fade = true}
  levelTransition.visual = love.graphics.newImage("blackbackdrop.png")
  levelTransition.x = 0
  levelTransition.y = 0
  levelTransition.opacity = 0
  levelTransition.fadeTarget = 0
  levelTransition.triggeredTransition = false
  levelTransition.guiElement = true
  levelTransition.scriptTriggers = {
    
    function(entity,state)
      return trigger()
    end
    
  }  
  
  levelTransition.scripts = {
    {
      script = {{fadeTarget = 1}, {opacity = 1}, {opacity = 1}},
      advancementConditions = {function(entity, state) return entity.opacity >= 1 end, 
        function(entity,state)
          levelChange(nextLevel, passVals())
          return true
        end }
    }
  }
  
  return levelTransition
  
end


