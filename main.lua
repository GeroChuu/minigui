require'minimal_widget'
local gui=require'minigui'()
local g=love.graphics

local vel=500
local runner=gui.Button("CLICK ME if you can..!", -180,120,180,40)
function love.update(dt)
    if runner.x>g.getWidth() or runner.x<-180 then vel=vel*-1 end
    gui:set_dt(dt)
    if not gui:add(runner).toggle then
        runner.x=runner.x+vel*dt
    end
end
function love.draw()
    gui:draw()
end
function love.mousepressed(...) gui:mousepressed(...) end
function love.mousereleased(...)gui:mousereleased(...)end
