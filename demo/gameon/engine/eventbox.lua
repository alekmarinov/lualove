
EventBox = {}
EventBox.__index = EventBox

function EventBox.new(object)
    return setmetatable({ 
        object = object,
        listeners = {},
        triggered = {}
    }, EventBox)
end

function EventBox:registerListener(eventName, listener)
    self.listeners[eventName] = self.listeners[eventName] or {}
    self.listeners[eventName][listener] = listener
end

function EventBox:unregisterListener(eventName, listener)
    if not self.listeners[eventName] then
        return 
    end
    self.listeners[eventName][listener] = nil
    if not next(self.listeners[eventName]) then
        self.listeners[eventName] = nil
    end
end

function EventBox:removeListener(listener)
    for eventName, listeners in pairs(self.listeners) do
        self:unregisterListener(eventName, listener)
    end
end

function EventBox:triggerEvent(eventName, options)
    self.triggered[eventName] = self.triggered[eventName] or {}
    self.triggered[eventName] = options
end

function EventBox:update(dt)
    for eventName, options in pairs(self.triggered) do
        local listeners = self.listeners[eventName]
        if listeners then
            for _, listener in pairs(listeners) do
                listener:onEvent(self.object, eventName, options)
            end
        end
    end
    self.triggered = {}
end

return EventBox
