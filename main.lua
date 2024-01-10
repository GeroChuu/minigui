require'minimal_widget'
local gui=require'minigui'()
gui.debug=true
local g=love.graphics

local run=gui.Button("CLICK ME if you can..!", 180,120,180,40)
function love.update(dt)
    gui:set_dt(dt)
    local runs=gui:add(run)
    if run.doubleClick then
        gui:debug_log("AH run")
    end
    if runs.focusLost then
        gui:debug_log("IH run")
    end
    local ners=gui:add(gui.Button("CLICK ME if you can..!", 280,120,180,40):setID(420))
    if ners.focusGained then
        gui:debug_log("AH ner")
    end
    if ners.focusLost then
        gui:debug_log("IH ner")
    end
end
function love.draw()
    gui:draw()
end
if love.system.getOS()=="Windows" then
function love.mousepressed(...) gui:mousepressed(...) end
function love.mousereleased(...)gui:mousereleased(...)end
else
function love.touchreleased(...)gui:touchreleased(...)end
end
