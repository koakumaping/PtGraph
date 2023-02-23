local p = 10

local function create()
    return {
      name='Plese Config.',
      color=lcd.RGB(0xEA, 0x5E, 0x00),
      warningColor=lcd.RGB(0x80, 0x00, 0x00),
      source=nil,
      value=0,
      scale=1,
      switch=nil,
      switchValue=-1024,
      initSwitch=nil,
      lastTime=os.clock(),
      delay=1000,
      max=1000,
      autoMax=1,
      warningValue=500,
      min=0,
      autoMin=99990,
      lineColorPoints={},
      points={}
    }
end

local function configure(widget)
    -- Source choice
    line = form.addLine('Source')
    local source_slots = form.getFieldSlots(line, {0, 0})
    form.addSourceField(line, source_slots[1], function() return widget.source end, function(value) widget.source = value end)
    form.addColorField(line, source_slots[2], function() return widget.color end, function(color) widget.color = color end)
    line = form.addLine('Switch - Reset')
    local switch_slots = form.getFieldSlots(line, {0, 0})
    form.addSwitchField(line, switch_slots[1], function() return widget.switch end, function(value) widget.switch = value end)
    form.addSwitchField(line, switch_slots[2], function() return widget.initSwitch end, function(value) widget.initSwitch = value end)

    -- Type - Interval
    line = form.addLine('Type - Interval')
    local type_slots = form.getFieldSlots(line, {0, 0})

    form.addChoiceField(
        line,
        type_slots[1],
        {{'Normal', 0}, {'6S', 6}, {'5S', 5}, {'4S', 4}, {'3S', 3}, {'2S', 2}, {'1S', 1}, {'Range', 13}},
        function() return widget.cells end,
        function(newValue)
            widget.cells = newValue
            if newValue == 0 then
                widget.min = 0
                widget.max = 1000
                widget.warningValue = 500
            elseif newValue > 12 then
                widget.min = -10240
                widget.max = 10240
                widget.warningValue = 0
            else
                widget.min = 28 * newValue
                widget.max = 42 * newValue
                widget.warningValue = 35 * newValue
            end
        end
    )
    form.addChoiceField(
        line,
        type_slots[2],
        {{'2s', 2000}, {'1s', 1000}, {'0.5s', 500}, {'0.2s', 200}, {'0.1s', 100}, {'0.05s', 50}, {'0.02s', 20}, {'0.01s', 10}},
        function() return widget.delay end, function(value) widget.delay = value end
    )

    -- Min & Max
    line = form.addLine('Min - Max')
    local slots = form.getFieldSlots(line, {0, '-', 0})
    form.addNumberField(line, slots[1], -10240, 99990, function() return widget.min end, function(value) widget.min = value end):decimals(1)
    form.addStaticText(line, slots[2], '-')
    form.addNumberField(line, slots[3], -10240, 99990, function() return widget.max end, function(value) widget.max = value end):decimals(1)

    line = form.addLine('Warning')
    local warning_slots = form.getFieldSlots(line, {0, 0})
    form.addNumberField(line, source_slots[1], -10240, 99990, function() return widget.warningValue end, function(value) widget.warningValue = value end):decimals(1)
    form.addColorField(line, source_slots[2], function() return widget.warningColor end, function(color) widget.warningColor = color end)
end

local function read(widget)
    widget.source = storage.read('source')
    widget.switch = storage.read('switch')
    widget.initSwitch = storage.read('initSwitch')
    widget.delay = storage.read('delay')
    widget.color = storage.read('color')
    widget.cells = storage.read('cells')
    widget.autoCalc = storage.read('autoCalc')
    widget.min = storage.read('min')
    widget.max = storage.read('max')
    widget.warningValue = storage.read('warningValue')
    widget.warningColor = storage.read('warningColor')
end

local function write(widget)
    storage.write('source', widget.source)
    storage.write('switch', widget.switch)
    storage.write('initSwitch', widget.initSwitch)
    storage.write('delay', widget.delay)
    storage.write('color', widget.color)
    storage.write('cells', widget.cells)
    storage.write('autoCalc', widget.autoCalc)
    storage.write('min', widget.min)
    storage.write('max', widget.max)
    storage.write('warningValue', widget.warningValue)
    storage.write('warningColor', widget.warningColor)
end

local function init(widget)
    widget.autoMax = 1
    widget.autoMin = 99990
    widget.points = {}
    lcd.invalidate()
end

local function updatePoints(widget, w, h)
    -- local w, h = lcd.getWindowSize()
    local time = os.clock()
    local delay = widget.delay / 1000

    local value = widget.value
    local isWarning = value * p <= widget.warningValue and 1 or 0
    -- print(string.format('range=%f, v=%f', (widget.autoMax - widget.autoMin) / h, h - math.floor(value * (widget.autoMax - widget.autoMin) / h)))
    -- print(string.format('p=%f, h=%d, v=%f, max=%d, warning=%d', widget.scale, h, value, widget.max, isWarning))
    -- local value = h - math.floor(widget.value * widget.scale)

    value = value > 1 and value - 1 or 0
    value = h - math.floor(value * widget.scale)

    local currentLength = #widget.points
    if time > widget.lastTime + delay then
        widget.lastTime = time
        if currentLength < w then
            widget.points[currentLength + 1] = value
            widget.lineColorPoints[currentLength + 1] = string.format("%#x", isWarning == 1 and widget.warningColor or widget.color) - 0xC000000
        else
            for i = 1, w do
                widget.points[i - 1] = widget.points[i]
            end
			widget.points[w] = value
            for i = 1, w do
                widget.lineColorPoints[i - 1] = lineColorPoints.points[i]
            end
            widget.lineColorPoints[w] = string.format("%#x", isWarning == 1 and widget.warningColor or widget.color) - 0xC000000
        end
        lcd.invalidate()
    end
end

local function wakeup(widget)
    if widget.switch and widget.source then
        local newName = widget.source:name()
        local newValue = widget.source:value()
        local switchValue = widget.switch:value()
        if widget.name ~= newName then
            widget.name = newName
            lcd.invalidate()
        end
        if widget.value ~= newValue then
            widget.value = newValue
            lcd.invalidate()
        end
        if widget.switchValue ~= switchValue then
            widget.switchValue = switchValue
            lcd.invalidate()
        end
        if widget.switch:value() > 0 then
            -- 按比例缩放
            local w, h = lcd.getWindowSize()
            widget.scale = h * p / widget.max
            updatePoints(widget, w, h)
        end
    end

    if widget.initSwitch and widget.initSwitch:value() > 0 then init(widget) end
end

local function paint(widget)
    local w, h = lcd.getWindowSize()

    for x = 1, #widget.points do
        local y = widget.points[x]
        lcd.color(widget.color)
		lcd.drawPoint(x, y + 1)
        lcd.color(widget.lineColorPoints[x])
		lcd.drawLine(x, h, x, y, SOLID)
	end

    lcd.color(widget.color)
    if h < 50 then
        lcd.font(FONT_XS)
    elseif h < 80 then
        lcd.font(FONT_XS)
    elseif h > 170 then
        lcd.font(FONT_s)
    else
        lcd.font(FONT_STD)
    end

    lcd.color(lcd.RGB(255,255,255, 0.2))
    local text_w, text_h = lcd.getTextSize('')
    lcd.drawText(8, h - text_h, widget.name)
    lcd.drawText(w - 8, h - text_h, widget.value..widget.source:stringUnit(), RIGHT)

    if widget.switchValue < 0 then
        lcd.drawText(w / 2, (h - text_h) / 2, 'Pause' , CENTERED)
    end
end

local function init()
    system.registerWidget({key="graph", name="Graph", create=create, configure=configure, read=read, write=write, wakeup=wakeup, paint=paint})
end

return {init=init}