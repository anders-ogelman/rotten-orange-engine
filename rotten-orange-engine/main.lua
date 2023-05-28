


--global helpers/constants
DIAGONAL_TRIG = math.sqrt(2)/2


--change this to enable/disable debugging tools
debugOn = false

globalData = {}


--level change helper function
undergoingLevelChange = false
function levelChange(newLevelName, passedAlongData)
  
  undergoingLevelChange = true
  love.audio.stop()
  
  globalData = passedAlongData
  
  require(newLevelName)
 
  
    
end


--stores the time based on DT
CURRENT_TIME = 0


--table to hold all state
state = {}

table.insert(state, collisions)

--stores all objects to be drawn in the current frame
currentFrameDrawables = {}

function love.load()
  
  Camera = require 'camera'
  

  
  require 'systemFuncs'
  
  --starting level
  require 'level1'
  --require 'level2'
  
  globalCam = Camera(love.graphics.getWidth()/2, love.graphics.getHeight()/2)

  
end



function love.update(dt)
  
  local updatedState = {} -- add on to this to reconstruct the state
  
  --functional modifications go in here
  for i,entity in ipairs(state) do
    
    --entities, not state itself, are directly modified, which i guess could have side effects but it's in the spirit of a functional approach
    --elements of the systems table are accessed as a set, not a simple table
    for s,t in pairs(entity.systems) do
      
      --format of all system functions
      if t then
        systemFuncs[s](entity, state, dt)
      end
      
    end
    table.insert(updatedState, entity)

    
  end
  
  if not undergoingLevelChange then
    state = updatedState
  else
    state = state
  end
    
  undergoingLevelChange = false
  
  CURRENT_TIME = CURRENT_TIME + dt
  
  
  --run debug operations if they're enabled
  if debugOn then
    debugOps()
  end
  
end


function love.draw()
  love.graphics.setBackgroundColor(0.75, 0.75, 0.75)
  
  

  for i, v in ipairs(currentFrameDrawables) do
      
    
    if v.opacity ~= nil then
      love.graphics.setColor(1,1,1,v.opacity)
      
    end
    
    --handles conversion of animation quads to drawables. this could cause a performance issue, as all animation frames get rendered twice every time the frame changes. However, this means that in effect all quads are now drawables.
    if v.visual:type() == "Quad" then
      
      local conversionCanvas = love.graphics.newCanvas(v.width, v.height)
      love.graphics.setCanvas(conversionCanvas)
      love.graphics.draw(v.spriteSheet, v.visual, 0, 0)
      love.graphics.setCanvas()
      v.visual = conversionCanvas
      
    end
        
    if v.rotation == nil then
      
      if not v.guiElement then globalCam:attach() end
      love.graphics.draw(v.visual, v.x, v.y)
      if not v.guiElement then globalCam:detach() end

    else
      --ensures all rotations happen about the center of a sprite
      if not v.guiElement then globalCam:attach() end
      love.graphics.push()
      love.graphics.translate(v.x + v.width/2, v.y + v.height/2)
      love.graphics.rotate(v.rotation)
      love.graphics.draw(v.visual, -v.width/2, -v.height/2) 
      love.graphics.pop()
      if not v.guiElement then globalCam:detach() end
    end
    
    love.graphics.setColor(1,1,1,1)

    
  end
  
  
  currentFrameDrawables = {}
  
end


--code debugging tools in here
function debugOps()
  
end






