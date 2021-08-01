package.path = package.path .. ";/NIDAS/lib/utils/?.lua"
local renderer = require("renderer")
local graphics = require("graphics")
local component = require("component")
local colors    = require("colors")
local event = require("event")
local uc = require("unicode")
local parser = require("parser")
local gui = {}

local borderColor = colors.darkGray
local primaryColor = colors.electricBlue
local accentColor = colors.magenta

function gui.configurationMenu(objects)

end

function gui.textInput(x, y, maxWidth, startValue)
    x = x or 1
    y = y or 1
    maxWidth = maxWidth or 15
    startValue = startValue or ""
    local context = graphics.context()
    local gpu = context.gpu
    local returnString = startValue
    graphics.text(x, -1+2*y, returnString.."_", accentColor)
    local value = 0
    local function checkExit(_, _, X, Y)
        if X < x or X > x+maxWidth or Y ~= y then
            value = -1
        end
    end
    local focusListener = event.listen("touch", checkExit)
    while value ~= 13 and value ~= -1 do
        local _, _, key, _, _ = event.pull(0.05, "key_down")
        if key ~= nil then
            value = key
            if #returnString < maxWidth then
                if key >= 32 and key <= 126 then
                    returnString = returnString..uc.char(key)
                end
            end
            if key == 8 then
                returnString = returnString:sub(1, -2)
            end
            local padded = returnString
            if #returnString ~= maxWidth then
                padded = returnString.."_"
                for i = 2, maxWidth-#returnString+1 do padded = padded.." " end
            end
            graphics.text(x, -1+2*y, padded, accentColor)
        end
    end
    event.cancel(focusListener)
    if value == 13 then
        graphics.text(x, -1+2*y, returnString.." ", primaryColor)
        return returnString
    else
        local padded = startValue
        for i = 1, maxWidth-#padded+1 do padded = padded.." " end
        graphics.text(x, -1+2*y, padded, primaryColor)
        return nil
    end
end

function gui.numberInput(x, y, maxWidth, startValue, startLeft)
    x = x or 1
    y = y or 1
    maxWidth = maxWidth or 15
    startValue = startValue or 0
    startLeft = startLeft or false
    local number = startValue
    local padded = parser.splitNumber(tonumber(number), " ")
    if startLeft then
        graphics.text(x, -1+2*y, padded.."_", accentColor)
    else
        for i = 1, maxWidth-#padded do padded = " "..padded end
        padded = padded.."_"
    end
    graphics.text(x, -1+2*y, padded, accentColor)
    local value = 0
    local function checkExit(_, _, X, Y)
        if X < x or X > x+maxWidth or Y ~= y then
            value = -1
        end
    end
    local focusListener = event.listen("touch", checkExit)
    while value ~= 13 and value ~= -1 do
        local _, _, key, _, _ = event.pull(0.05, "key_down")
        if key ~= nil then
            value = key
            if #parser.splitNumber(tonumber(number), " ") < maxWidth then
                if (key >= 48 and key <= 57) or key == 45 then
                    if key == 45 then
                        number = -number
                    else
                        number = tonumber(tostring(number)..uc.char(key))
                    end
                end
            end
            if key == 8 then
                if number > 9 or number < -9 then
                    number = tonumber(tostring(number):sub(1, -2))
                else
                    number = 0
                end
            end
            padded = parser.splitNumber(tonumber(number), " ")
            if #padded ~= maxWidth then
                if startLeft then
                    for i = 1, maxWidth-#padded do padded = padded.." " end
                else
                    for i = 1, maxWidth-#padded do padded = " "..padded end
                end
                padded = padded.."_"
            end
            graphics.text(x, -1+2*y, padded, accentColor)
        end
    end
    print("Ending loop")
    event.cancel(focusListener)
    if value == 13 then
        padded = parser.splitNumber(tonumber(number), " ")
        if not startLeft then
            for i = 1, maxWidth-#padded do padded = " "..padded end
        end
        graphics.text(x, -1+2*y, padded.." ", primaryColor)
        return number
    else
        padded = parser.splitNumber(tonumber(startValue), " ")
        if not startLeft then
            for i = 1, maxWidth-#padded do padded = " "..padded end
        end
        graphics.text(x, -1+2*y, padded.." ", primaryColor)
        return nil
    end
end

function gui.tableView(x, y)

end

function gui.selectionBox(x, y, choices)
    local context = graphics.context()
    local maxX = context.width
    local maxY = context.heigth
    local gpu = context.gpu
    local longestName = 0
    for i = 1, #choices do
        if #choices[i].displayName > longestName then longestName = #choices[i].displayName end
    end
    longestName = longestName + 2
    local heigth = #choices + 2
    if maxX <= (x+longestName+5) then x = maxX-(longestName+4) end
    if maxY <= (y+heigth) then y = maxY-(heigth-1) end
    local page = gpu.allocateBuffer(longestName+2, heigth)
    gpu.setActiveBuffer(page)
    graphics.rectangle(1, 1, 2+longestName, 1, borderColor)
    graphics.rectangle(1, 4+2*#choices, 2+longestName, 1, borderColor)
    graphics.rectangle(1, 1, 1, 4+2*#choices, borderColor)
    graphics.rectangle(2+longestName, 1, 1, 4+2*#choices, borderColor)
    graphics.rectangle(2, 3, longestName, 2*#choices, colors.black)
    for i = 1, #choices do
        graphics.text(3, 1+2*i, choices[i].displayName, accentColor)
    end
    gpu.setActiveBuffer(0)
    local background = gpu.allocateBuffer(longestName+2, heigth)
    gpu.bitblt(background, 1, 1, maxY, maxX, 0, y, x)
    gpu.bitblt(_, x, y, maxX, maxY, page)
    local _, _, touchX, touchY, button, _ = event.pull(_, "touch")
    gpu.bitblt(0, x, y, maxX, maxY, background)
    if touchX > x and touchX < x+longestName+1 and touchY > y and touchY < y+heigth then
        return choices[touchY-y].value
    else
        return nil
    end
end

local function compareColors(a,b)
    return a[2] < b[2]
  end
function gui.colorSelection(x, y, colorList)
    local context = graphics.context()
    local maxX = context.width
    local maxY = context.heigth
    local gpu = context.gpu
    local colorTable = {}
    local longestName = 0
    for name, value in pairs(colorList) do
        if #name > longestName then longestName = #name end
        table.insert(colorTable, {name, value})
    end
    table.sort(colorTable, compareColors)
    local heigth = #colorTable + 2
    if maxX <= (x+longestName+5) then x = maxX-(longestName+4) end
    if maxY <= (y+heigth) then y = maxY-(heigth-1) end
    local page = gpu.allocateBuffer(longestName+5, heigth)
    gpu.setActiveBuffer(page)
    graphics.rectangle(1, 1, 5+longestName, 4+2*#colorTable, borderColor)
    graphics.rectangle(5, 3, longestName, 2*#colorTable, colors.black)
    for i = 1, #colorTable do
        graphics.text(5, 1+2*i, colorTable[i][1], colorTable[i][2])
        graphics.rectangle(2, 1+2*i, 2, 2, colorTable[i][2])
    end
    gpu.setActiveBuffer(0)
    local background = gpu.allocateBuffer(longestName+5, heigth)
    gpu.bitblt(background, 1, 1, maxY, maxX, 0, y, x)
    gpu.bitblt(_, x, y, maxX, maxY, page)
    local _, _, touchX, touchY, button, _ = event.pull(_, "touch")
    gpu.bitblt(0, x, y, maxX, maxY, background)
    if touchX > x and touchX < x+longestName+4 and touchY > y and touchY < y+heigth then
        return colorTable[touchY-y][2]
    else
        return nil
    end
end

return gui