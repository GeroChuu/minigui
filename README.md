# MINIGUI
#### Minimal Gui library for LÖVE 2D with single file core and easy to extend (see minimal widget folder for example how to make it).
### MiniGUI support:
- Multitouch on mobile device
- Immediate Event, such: pressed,released,focusGained,focusLost
- Retain Event, such: focused,doubleClick,toggle
- Widget State, such: normal,hover(only destop),active,freeze(not interactive)
- Easy way to make new widget (just make a table and call registerWidgetClasset method)

### Hello world button:
```lua
require'minimal_widget' -- Add aditional widget (just an example, replace with your own widget extenssion)
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
require'minimal_widget' -- Add aditional widget
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
### Documentation
#### Create New instance of minigui
Before you can use minigui, you must make new instance of it, but here something
you must know about make new instance of minigui.
- If you want to add widgets to the current instance, just ```local minigui=require'minigui' ``` without creating a new instance and ```minigui:registerWidgetClass(Your_Widget, "Widget_name")```. Then create an instance in main.lua and your widget will be included in the new instance ```local gui=require'minigui'() gui.Widget_name()```.
- You can create a new instance from another instance and all the widgets that were in the old instance will be in the new instance. You can add new widgets to each instance and they will be independent.

#### Create New Widget
Basically you create deepcopy of minimal_widget that's provided by this library.
```lua
local minigui=require'minigui'
local function hoverFunction(mx,my,x,y,matrix)
    return mx>x and my>y and mx<x+m.width and my<y+m.height -- Basic hitbox function
end
local MyWidget={} -- Just make blank table
function MyWidget:init(x,y,w,h) -- Create initializer to set position and matrix
    self.x=x
    self.y=y
    self.matrix={width=w,height=h}
end
function MyWidget:update(dt)
    local pressed,released,focusGained,focusLost=self.gui:getImmediateState(self, hoverFunction)
    return {
        pressed=pressed,
        released=released,
        fucusGained=focusGained,
        focusLost=focusLost
    } -- Just forward the Immediat State result of this widget
end
function MyWidget:draw()
    love.graphics.setColor(self.gui.colors[self.state].bg)
    if self.mouse.focused then love.graphics.setColor(self.gui.colors.focus.bg) end
    love.graphics.rectangle("fill", self.x, self.y, self.matrix.width, self.matrix.height)
end
minigui:registerWidgetClass(MyWidget, "MyWidget") -- minigui will take care of the rest.
```
