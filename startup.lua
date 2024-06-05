CHANNEL = 1
TURTLE = "turtle_8"
DRIVE = "drive_6"
CCTURTLE = "computercraft:turtle_normal"

local modem = peripheral.wrap("right") or error("No modem attached", 0)
modem.open(CHANNEL)

local chests = {peripheral.find("inventory")}

function locate()
    local x, z, y
    repeat
        x, z, y = gps.locate()
    until x and z and y
    -- compensem per l'altura del telèfon i la posició inicial
    x = math.floor(x)
    y = math.floor(y)
    z = math.floor(z)
    -- nether
    -- z = math.floor(z) - 1
    -- overworld
    return y, x, z
    -- nether
    -- return x, y, z
end

local position = {locate()}

function receive()
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == CHANNEL
    return message, replyChannel
end

function transmit(request, to)
    modem.transmit(to, CHANNEL, request)
end

function load(filename)
    if not fs.exists(filename) then
        save(filename, {})
    end
    local file = fs.open(filename, "r")
    local content = textutils.unserialize(file.readAll())
    file.close()
    return content
end

function delete(filename)
    if fs.exists(filename) then
        fs.delete(filename)
        return true
    end
    return false
end

function save(filename, content)
    local file = fs.open(filename, "w")
    file.write(textutils.serialize(content))
    file.close()
end

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function string.split(str, character)
    local result, index = {}, 1
    for s in string.gmatch(str, "[^"..character.."]+") do
      result[index] = s
      index = index + 1
    end
    return result
end

old_print = print
function print(text, ...)
    if type(text) == "string" then
        old_print(text:format(unpack(arg)))
    else
        old_print(text, unpack(arg))
    end
end

function waitEvent(event)
    local ev
    repeat
        ev = {os.pullEvent()}
    until ev[1] == event
    return unpack(ev)
end

local settings = load("app.config")

function turtle.list()
    local t = {}
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            t[i] = item
        end
    end
    return t
end

function find(name, p)
    for slot, item in pairs(p.list()) do
        if item and item.name == name then
            return slot
        end
    end
end

function findAny(name)
    for i = 1, #chests do
        local slot = find(name, chests[i])
        if slot then
            return slot, chests[i]
        end
    end
end

function returnItem(chest, slot)
    if turtle.getItemCount(slot) == 0 then
        return true
    end
    local result = chest.pullItems(TURTLE, slot) > 0
    sleep(0.05)
    return result
end

function start()
    local p1, p2 = settings.position1, settings.position2
    local width, depth, height = math.abs(p2[1] - p1[1]), math.abs(p2[2] - p1[2]), settings.height
    local area = (width + 1) * (depth + 1)
    -- overworld
    local x, y, z = position[1] - p1[1] - 1, p1[2] - position[2], 0
    -- nether
    --local x, y, z = p1[1] - position[1] - 1, p1[2] - position[2] + 1, 0
    for i = 0, width do
        for j = 0, depth do
            local t, f1 = findAny(CCTURTLE)
            if t then
                f1.pushItems(TURTLE, t, 1, 1)
                turtle.select(1)
                while not turtle.place() do
                    sleep(0.05)
                end
                local event, side = waitEvent("peripheral")
                local c = peripheral.wrap(side)
                local e, f2 = findAny("enderchests:ender_chest")
                f2.pushItems(TURTLE, e, 1, 1)
                turtle.drop()
                c.turnOn()
                receive()
                transmit({to={x + i, y + (depth - j), settings.height}}, 0)
            end
        end
    end
    transmit({action = "end"}, 0)
    for i = 1, area do
        local event, side = waitEvent("peripheral")
        turtle.dig()
        for i = 1, #chests do
            if returnItem(chests[i], 1) and returnItem(chests[i], 2) then
                break
            end
        end
    end
end

function getId()
    local file = fs.open(ID_FILE, "r")
    local contents = tonumber(file.readAll())
    file.close()
    file = fs.open(ID_FILE, "w")
    file.write(contents + 1)
    file.close()
    return contents
end

function copiar()
    local label = "AutoMiner"
    local clabel = disk.getLabel(DRIVE)
    if label and (not clabel or not clabel:starts(label)) then
        label = label .. "#" .. getId()
        disk.setLabel(DRIVE, label)
    end
    local files = fs.list("disk")
    for i, file in ipairs(files) do
        fs.delete("disk/" .. file)
    end
    files = fs.list("files")
    for i, file in ipairs(files) do
        fs.copy("files/" .. file, "disk/" .. file)
    end
end

function update(n)
    local max = 0
    for i, chest in ipairs(chests) do
        for slot, item in pairs(chest.list()) do
            if item.name == CCTURTLE then
                chest.pushItems(DRIVE, slot, 1, 1)
                sleep(0.05)
                copiar()
                chest.pullItems(DRIVE, 1, 1, slot)
                sleep(0.05)
                max = max + 1
                if n and max == n then
                    return
                end
            end
        end
    end
end

while true do
    local message, reply = receive()
    if type(message) == "table" then
        if message.action == "setup" then
            settings.position1 = message.position1
            settings.position2 = message.position2
            settings.height = message.height
            save("app.config", settings)
            transmit(true, reply)
        elseif message.action == "launch" then
            start()
            transmit(true, reply)
        elseif message.action == "update" then
            update(message.number)
            transmit(true, reply)
        elseif message.action == "data" then
            transmit(settings, reply)
        end
    end
end