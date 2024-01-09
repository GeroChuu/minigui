# MINIGUI
#### Minimal Gui library for LÖVE 2D with single file core and easy to extend (see minimal widget folder).

### Hello world button:
```lua
require'minimal_widget' -- Add aditional widget (just Button there)
local gui=require'minigui'() -- Create instance of minigui
function love.update(dt)
    if gui:add(gui.Button("Hello, World!", 10, 10, 100, 40):setId(69)).released then -- You must provide id when you are in full immediate mode
        print("Hello, World in console")
    end
end
-- BOILER PLATE --
function love.draw() gui:draw() end
function love.mousepressed(...) gui:mousepressed(...) end
function love.mousereleased(...)gui.mousereleased(...)end
```
### Combined with retained-mode:
```lua
require'minimal_widget' -- Add aditional widget (just Button there)
local gui=require'minigui'() -- Create instance of minigui

local hello=gui.Button("Hello, World!", 10, 10, 100, 40)
function love.update(dt)
    if gui:add(hello).released then -- You don't need to provide id when you are not in full immediate mode
        print("Hello, World in console")
    end
end
-- BOILER PLATE --
function love.draw() gui:draw() end
function love.mousepressed(...) gui:mousepressed(...) end
function love.mousereleased(...)gui.mousereleased(...)end
```
### (Documentation TDB)
