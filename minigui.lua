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
local function circle(mx,my,x,y,m)
    return m.radius*m.radius>=math.abs(mx-x)+math.abs(my-y)
end
local function image_mask(mx,my,x,y,m)
    local u, v = math.floor(mx-x+.5), math.floor(my-y+.5)
	if u < 0 or u >= m.mask:getWidth() or v < 0 or v >= m.mask:getHeight() then
		return false
	end
	local _,_,_,a = m.mask:getPixel(u,v)
	return a > 0
end
local function minimal_logic(self,dt)
    local pr,rl,fg,fl=self.gui:getImmediateState(self,aabb)
    return {pressed=pr,released=rl,focusGained=fg,focusLost=fl}
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
    setID=setId,
    doubleClick=false,
    __dc_timer=0,__dc_delay=.3,__click_count=0, -- for Double Click event.
}

local function getTouches()
    if love.system.getOS()=="Windows" then
        if love.mouse.isDown(1) then return {1} end
        return {}
    end
    return love.touch.getTouches()
end
local function getPosition(id)
    if not id then return nil,nil end
    if love.system.getOS()=="Windows" then
        return love.mouse.getPosition()
    end
    return love.touch.getPosition(id)
end

local function isArrayInclude(t,value,eq_func)
    for _,t_val in ipairs(t) do
        if eq_func(t_val,value) then return true end
    end
    return false
end

local default_colors={
    normal={bg=color("#ff99ff"),fg=color("#181818")},
    hover ={bg=color("#ff18ff"),fg=color("#181818")},
    active={bg=color("#ffffff"),fg=color("#181818")},
    focus ={bg=color("#8090ff"),fg=color("#ffffff")},
    freeze={bg=color("#B5C6C5",.5),fg=color("#999999")},
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
    self.mouse.invalid_enter=false

    self.touch={}
    self.touch.actived={}
    self.touch.focused=nil
    self.touch.pressed={}
    self.touch.released={}

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
    self.last_focused=nil

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
function gui:getImmediateState(widget,hover) --> pressed,released,focusGained,focusLost
    if not widget.interactive then
        widget.state="freeze"
        self.mouse.focused=nil
        if widget.focused then
            widget.focused=false
            return false,false,false,true
        end

        return false,false,false,false
    end
    if false then --love.system.getOS()=="Windows" then
        return self:setStateWithMouse(widget,hover)
    else
        return self:setStateWithTouch(widget,hover)
    end
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
function gui:setStateWithMouse(widget,hover) --> pressed, released, focusGained, focusLost
    if widget.__click_count>0 then
        widget.__dc_timer=widget.__dc_timer+self.dt
        if widget.__dc_timer>widget.__dc_delay then
            widget.__click_count=0
            widget.__dc_timer=0
        end
    end
    if widget.state=="freeze" then widget.state="normal" end
    local mx,my=love.mouse.getPosition()
    self.mouse.x,self.mouse.y=mx,my
    if hover(mx,my,widget.x,widget.y,widget.matrix) then
        if self.mouse.invalid_enter then return false,false,false,false end
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
                    self.last_focused=self.mouse.focused
                    if self.widget_focused then self.widget_focused.focused=false end
                end
                self.widget_focused=widget
                self.mouse.focused=widget.id
                widget.focused=true
                -- PRESSED and FOCUS GAINED
                return true,false,true,false
            end
            -- Just PRESSED
            return true,false,false,false
        end
        if self.mouse.released and self.mouse.pushed==widget.id then
            self.mouse.pushed=nil
            widget.__click_count=widget.__click_count+1
            if widget.__click_count==2 and widget.__dc_timer<=widget.__dc_delay then
                widget.__dc_timer=0
                widget.__click_count=0
                -- DOUBLE CLICK event will returning the first click as normal click.
                widget.doubleClick=true
            end
            -- TOGGLE always toggled when mouse button released is left.
            if self.mouse.btn==1 then widget.toggle=not widget.toggle end
            return false,true,false,false
        end
    else
        if widget.state=="active" or widget.state=="hover" then
            if love.mouse.isDown(1) or
            love.mouse.isDown(2) or
            love.mouse.isDown(3) then
                widget.state="active"
            else
                widget.state="normal"
                self.mouse.actived=nil
            end
        end

        if self.mouse.released then
            widget.state="normal"
            self.mouse.actived=nil
            if widget.focused or self.last_focused==widget.id then
                self.mouse.focused=nil
                self.last_focused=nil
                widget.focused=false
                -- FOCUS LOST
                return false,false,false,true
            end
        end
    end
    return false,false,false,false
end
function gui:setStateWithTouch(widget,hover)
    if widget.__click_count>0 then
        widget.__dc_timer=widget.__dc_timer+self.dt
        if widget.__dc_timer>widget.__dc_delay then
            widget.__click_count=0
            widget.__dc_timer=0
        end
    end
    if widget.state=="freeze" then widget.state="normal" end
    local touches=getTouches()
    for _,id in ipairs(touches) do
        local x,y=getPosition(id)
        if hover(x,y, widget.x, widget.y, widget.matrix) then
            if self.mouse.invalid_enter then return false,false,false,false end
            if #self.touch.actived<#touches or isArrayInclude(self.touch.actived, widget.id, function(tval,val)
                return tval==val
            end) then
                widget.state="active"
                if not isArrayInclude(self.touch.actived, widget.id, function(tval,val)
                    return tval==val
                end) then
                    table.insert(self.touch.actived, widget.id)
                        widget.focused=true
                    if not widget.focused then
                        self.touch.focused=widget.id
                        if self.widget_focused then self.widget_focused.focused=false end
                        self.widget_focused=widget
                        return true,false,true,false
                    else
                        self.last_focused=self.last_focused or widget.id
                    end
                    if isArrayInclude(self.touch.pressed,widget,function(tval,val)
                        return hover(tval.x,tval.y, val.x,val.y, val.matrix)
                    end) then
                        return true,false,false,false
                    end
                end
            else
                widget.state="normal"
            end
        end
    end
    if #touches>0 and self.last_focused==widget.id then
        self.last_focused=nil
        widget.focused=false
        return false,false,false,true
    end
    if widget.state=="active" then
        if #touches>0 then
            widget.state="active"
        else
            widget.state="normal"
        end
        if isArrayInclude(self.touch.released,widget,function(tval,val)
            return hover(tval.x,tval.y, val.x,val.y, val.matrix)
        end) then
            widget.toggle=not widget.toggle
            widget.__click_count=widget.__click_count+1
            if widget.__click_count==2 and widget.__dc_timer<=widget.__dc_delay then
                widget.__dc_timer=0
                widget.__click_count=0
                -- DOUBLE CLICK event will returning the first click as normal click.
                widget.doubleClick=true
            end
            return false,true,false,false
        end
    end
    return false,false,false,false
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
    local outside=true
    self:WhileEachC(_,function(self,widget,_)
        widget.doubleClick=false
        if widget.state=="hover" or widget.state=="active" then
            outside=false
        end
    end)
    if outside then
        if love.mouse.isDown(1) or love.mouse.isDown(2) or love.mouse.isDown(3) then
            self.widget_focused=nil
            self.mouse.invalid_enter=true
        else
            self.mouse.invalid_enter=false
            self.mouse.pushed=nil
        end
    end

    self:clearWidgets()
    self:setMouse(_,_,nil,false,false)
    self.mouse.hovered=nil
    self.touch.released={}
    self.touch.pressed={}
    love.graphics.setColor(1,1,1)
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
    if self.debug then table.insert(self.touch.pressed,{x=x,y=y}) end
end
function gui:mousereleased(x,y,btn,...)
    self:setMouse(x,y,btn,false,true)
    if self.debug then
        table.insert(self.touch.released,{x=x,y=y})
        self.touch.actived={}
    end
end
function gui:touchpressed(id,x,y, ...)
    table.insert(self.touch.pressed,{x=x,y=y})
end
function gui:touchreleased(id,x,y,...)
    table.insert(self.touch.released,{x=x,y=y})
    self.touch.actived={}
end
function gui:setDT(dt)
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
function gui:registerWidgetClass(class,name, mt)
    for k in pairs(minimal_widget) do
        if class[k]==nil then class[k]=minimal_widget[k] end
    end
    class.name=name
    class.new=function(...)
        local o=copytable(class,true)
        o:init(...)
        return o
    end
    mt=mt or {}
    mt.__call=mt.__call or function(c,...)
        return c.new(...)
    end
    setmetatable(class, mt)
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

gui.hex2color=color
gui.isArrayInclude=isArrayInclude
gui.aabb=aabb
gui.circle=circle
gui.image_mask=image_mask

return gui
