local function copytable(t, deep)
    local o={} for k in pairs(t) do
        if deep and type(t[k])=="table" then
            o[k]=copytable(t[k])
            setmetatable(o[k],getmetatable(t[k]))
        else
            o[k]=t[k]
        end
        setmetatable(o,getmetatable(t))
    end return o
end
local function color(hex, alpha)
    return {tonumber(hex:sub(2,3),16)/255, tonumber(hex:sub(4,5),16)/255, tonumber(hex:sub(6,7),16)/255, alpha or 1}
end

local function aabb(mx,my,x,y,m)
    return mx>x and my>y and mx<x+m.width and my<y+m.height
end
local function minimal_logic(self,dt)
    local pr,rl,fg,fl,dc=self.gui:getImmediateState(self,aabb)
    return {pressed=pr,released=rl,focusGained=fg,focusLost=fl,doubleClick=dc,toggle=self.toggle}
end
local function minimal_draw(self)
    love.graphics.setColor(self.gui.colors[self.state].bg)
    if self.mouse.focused then love.graphics.setColor(self.gui.colors.focus.bg) end
    love.graphics.rectangle("fill", self.x, self.y, self.matrix.width, self.matrix.height)
end
local function setId(self,id)
    self.id=id
    return self
end

local minimal_widget={
    state="normal", -- "normal", "hover", "active", "freeze"
    focused=false,toggle=false,
    matrix={},inner={},
    x=0,y=0,
    visible=true,interactive=true,
    update=minimal_logic,
    draw=minimal_draw,
    setId=setId,
    __dc_timer=0,__dc_delay=.3,__click_count=0, -- for Double Click event.
}

local default_colors={
    normal={bg=color("#ff99ff"),fg=color("#181818")},
    hover ={bg=color("#ff18ff"),fg=color("#181818")},
    active={bg=color("#ffffff"),fg=color("#181818")},
    focus ={bg=color("#8090ff"),fg=color("#ffffff")},
    freeze={bg=color("#B5C6C5"),fg=color("#999999")},
    cursor=color("#ff0099"),
}

local gui,gui_mt={debug=false},{}
setmetatable(gui, gui_mt)
function gui_mt:__call(...)
    local o=copytable(self)
    return self:new(...)
end

function gui:init(colors, font)

    self.mouse={btn=nil,pressed=false,released=false}
    self.mouse.hovered=nil
    self.mouse.actived=nil
    self.mouse.focused=nil
    self.mouse.pushed =nil
    self.mouse.last_focused=nil
    self.mouse.invalid_enter=false

    self.touch={touches={}}
    self.touch.actived={}
    self.touch.focused={}
    self.touch.pushed ={}
    self.touch.last_focused={}
    self.touch.invalid_enter={}

    self.debug_state={
        frame_limit=nil,
        frame_count=0,
        widgets={},
        debug_str="",
    }

    self.colors=colors or default_colors
    self.font=font or love.graphics.getFont()
    self.dt=0

    self.widgets={}
    self.widget_focused=nil

    return self
end
function gui:setMouse(x,y,btn,pressed,released)
    self.mouse.x,self.mouse.y=x or self.mouse.x,y or self.mouse.y
    self.mouse.btn,self.mouse.pressed,self.mouse.released=btn,pressed,released
end
function gui:clearWidgets()
    for id in ipairs(self.widgets) do
        table.remove(self.widgets,id)
    end
end
function gui:getImmediateState(widget,hover) --> pressed,released,focusGained,focusLost,double click
    if not widget.interactive then
        widget.state="freeze"
        self.mouse.focused=nil
        if widget.focused then
            widget.focused=false
            return false,false,false,true,false
        end

        return false,false,false,false,false
    end
    return self:setStateWithMouse(widget,hover)
end
function gui:setActiveWidgetWhenMouseDown(widget, num)
    if love.mouse.isDown(num) then
        if self.mouse.actived==nil or self.mouse.actived==widget.id then
            self.mouse.btn=num
            self.mouse.actived=widget.id
            widget.state="active"
            return true
        end
    end
    return false
end
function gui:setStateWithMouse(widget,hover) --> pressed, released, focusGained, focusLost, double click
    if widget.__click_count>0 then
        widget.__dc_timer=widget.__dc_timer+self.dt
        if widget.__dc_timer>widget.__dc_delay then
            widget.__click_count=0
            widget.__dc_timer=0
        end
    end
    local mx,my=love.mouse.getPosition()
    self.mouse.x,self.mouse.y=mx,my
    if hover(mx,my,widget.x,widget.y,widget.matrix) then
        if self.mouse.invalid_enter then return false,false,false,false,false end
        if self.mouse.hovered==nil then
            self.mouse.hovered=widget.id
            widget.state="hover"
        else
            widget.state="normal"
        end
        local num=1
        while num<=3 do
            if self:setActiveWidgetWhenMouseDown(widget,num) then break end
            num=num+1
        end
        if self.mouse.pressed and self.mouse.pushed==nil then
            self.mouse.pushed=widget.id
            if self.mouse.focused~=widget.id then
                if self.mouse.focused~=nil then
                    self.mouse.last_focused=self.mouse.focused
                    if self.widget_focused then self.widget_focused.focused=false end
                end
                self.widget_focused=widget
                self.mouse.focused=widget.id
                widget.focused=true
                -- PRESSED and FOCUS GAINED
                return true,false,true,false,false
            end
            -- Just PRESSED
            return true,false,false,false,false
        end
        if self.mouse.released and self.mouse.pushed==widget.id then
            self.mouse.pushed=nil
            widget.__click_count=widget.__click_count+1
            if widget.__click_count==2 and widget.__dc_timer<=widget.__dc_delay then
                widget.__dc_timer=0
                widget.__click_count=0
                -- DOUBLE CLICK event will returning the first click as normal click.
                return false,false,false,false,true
            end
            -- TOGGLE always toggled when mouse button released is left.
            if self.mouse.btn==1 then widget.toggle=not widget.toggle end
            return false,true,false,false,false
        end
    else
        widget.state="normal"
        self.mouse.actived=nil
        if self.mouse.released then
            if widget.focused or self.mouse.last_focused==widget.id then
                self.mouse.focused=nil
                self.mouse.last_focused=nil
                widget.focused=false
                -- FOCUS LOST
                return false,false,false,true,false
            end
        end
    end
    return false,false,false,false,false
end
function gui:clearTouches()
    for i=0,#self.touch.touches do
        table.remove(self.touch.touches,i)
    end
end
function gui:setTouch(touches)
    self:clearTouches()
    for _,touch in ipairs(touches) do
        local x,y=love.touch.getPosition(touch)
        table.insert(self.touch.touches,{id=touch,x=x,y=y})
    end
end
function gui:setStateWithTouch(widget,hover)
    self:setTouch(love.touch.getTouches())
    local index,inside=0,false

    local tcs=self.touch.touches
    while index<=#tcs do
        index=index+1
        local tx,ty,wx,wy=tcs[index].x,tcs[index].y,widget.x,widget.y
        if hover(tx,ty,wx,wy,widget.matrix) then
            hovered=true
            break
        end
    end

    if inside then
        if #self.touch.actived<#tcs or self.mouse.actived[tcs[index].id]==widget then
            self.mouse.actived[tcs[index].id]=widget
            widget.state="active"
        else
            widget.state="normal"
        end
    else

    end
end
function gui:WhileEachC(callbacks, cond, ...)
    local i=1
    while i<=#self.widgets do
        local widget=self.widgets[i]
        if cond(self, widget, i) then
            if widget[callbacks] then widget[callbacks](widget, ...) end
        end
        i=i+1
    end
end
function gui:WhileEachCRev(callbacks, cond, ...)
    local i=#self.widgets
    while i>=1 do
        local widget=self.widgets[i]
        if cond(self, widget, i) then
            if widget[callbacks] then widget[callbacks](widget, ...) end
        end
        i=i-1
    end
end
function gui:draw()
    self:WhileEachCRev("draw", function(_,widget,_) return widget.visible end)
    self:WhileEachC(_,function(self,widget,_)
        if self.mouse.hovered~=nil or self.mouse.actived~=nil then
            return
        end
        if love.mouse.isDown(1) or love.mouse.isDown(2) or love.mouse.isDown(3) then
            self.widget_focused=nil
            self.mouse.invalid_enter=true
        else
            self.mouse.invalid_enter=false
            self.mouse.pushed=nil
        end
    end)

    self:clearWidgets()
    self:setMouse(_,_,nil,false,false)
    love.graphics.setColor(1,1,1)
    self.mouse.hovered=nil
    if self.debug then
        self.debug_state.frame_count=self.debug_state.frame_count+1
        self:checkMemoryUsageOn(self.debug_state.frame_limit)
        if love.system.getOS()~="Windows" then
            love.graphics.print(self.debug_state.debug_str, 10, 10)
        end
    end
end
function gui:mousepressed(x,y,btn, ...)
    self:setMouse(x,y,btn,true,false)
end
function gui:mousereleased(x,y,btn,...)
    self:setMouse(x,y,btn,false,true)
end
function gui:touchpressed(x,y,btn, ...)
    self:setMouse(x,y,btn,true,false)
end
function gui:touchreleased(x,y,btn,...)
    self:setMouse(x,y,btn,false,true)
end
function gui:set_dt(dt)
    self.dt=dt
end
function gui:add(widget)
    widget.gui=self
    widget.id=widget.id or widget
    if self.widget_focused and (self.widget_focused.id==widget.id) then
        widget.focused=true
    end
    table.insert(self.widgets, widget)
    return widget.update(widget, self.dt)
end
function gui:getColors()
    return copytable(self.colors or default_colors, true)
end
gui.hex2color=color
function gui:debug_log(str)
    if love.system.getOS()~="Windows" then
        self.debug_state.debug_str=self.debug_state.debug_str..tostring(str).."\n"
    else
        print(str)
    end
end
function gui:checkMemoryUsageOn(frame_limit)
    frame_limit=frame_limit or math.huge
    assert(self.debug_state.frame_count<frame_limit, tostring(collectgarbage("count")))
end
function gui:registerWidgetClass(class,name)
    for k in pairs(minimal_widget) do
        if class[k]==nil then class[k]=minimal_widget[k] end
    end
    class.name=name
    class.new=function(...)
        local o=copytable(class,true)
        o:init(...)
        return o
    end
    setmetatable(class, {__call=function(c,...)
        return c.new(...)
    end})
    self[name]=class
end
function gui:new(...)
    local o=copytable(self,true)
    setmetatable(o, {__call=function(c,...)
        return o:new(...)
    end})
    o:init(...)
    return o
end
return gui
