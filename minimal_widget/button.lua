local BASE=(...):match('(.-)[^%.]+$')
local minigui=require"minigui"
local g=love.graphics

local Minimal_Button={} -- Just make a blank table for new widget
function Minimal_Button:init(text,x,y,w,h, opt)
    opt=opt or {}
    self.inner={text=text, font=opt.font or g.getFont(), segment=opt.segment or 16}
    self.x,self.y=x,y
    self.matrix={width=w,height=h}
    return self
end
function Minimal_Button:draw() -- override the draw method
    love.graphics.setColor(self.colors and self.colors[self.state] and
    self.colors[self.state].bg or self.gui.colors[self.state].bg)
    
    if self.focused then g.setColor(self.gui.colors.focus.bg) end
    love.graphics.rectangle("fill", self.x, self.y, self.matrix.width, self.matrix.height,
    self.inner.segment)

    love.graphics.setColor(self.colors and self.colors[self.state] and
    self.colors[self.state].fg or self.gui.colors[self.state].fg)
    local offx,offy=self.matrix.width/2-self.inner.font:getWidth(self.inner.text)/2,
    self.matrix.height/2-self.inner.font:getHeight()/2
    g.print(self.inner.text,self.x+offx,self.y+offy)
end
minigui:registerWidgetClass(Minimal_Button, "Button") -- minigui will take care of the rest.
