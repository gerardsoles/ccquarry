CHANNEL = 0
ENDER = "enderchests:ender_chest"
BLACKLIST = {
    ["forbidden_arcanus:stella_arcanum"] = true
}
COUNTER_N = 50

local modem = peripheral.find("modem") or error("No modem attached", 0)
modem.open(CHANNEL)

function clear()
    term.clear()
    term.setCursorPos(1,1)
end

function string.split(str, character)
    local result, index = {}, 1
    for s in string.gmatch(str, "[^"..character.."]+") do
        result[index] = s
        index = index + 1
    end
    return result
end

function waitEvent(event)
    local ev
    repeat
        ev = {os.pullEvent()}
    until ev[1] == event
    return unpack(ev)
end

function waitForKey(message, key)
    clear()
    print(message)
    print("Prem qualsevol tecla per a continuar...")
    waitEvent("key")
end

function receive()
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    until channel == CHANNEL
    return message
end

function waitForEnd()
    repeat
        message = receive()
    until message.action and message.action == "end"
    return true
end

function find(name)
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item and item.name == name then
            return i
        end
    end
    return 0
end

function repostar()
    local fuel = turtle.getFuelLevel()
    if fuel < 1000 then
        turtle.suckUp()
        local f = find("minecraft:coal")
        if f > 0 then
            turtle.select(f)
            turtle.refuel()
            turtle.select(1)
        end
    end
end

function move(n, direction)
    direction = direction or "forward"
    for i = 1, n do
        while not turtle[direction]() do
            sleep(0.05)
        end
    end
end

function checkBlock()
    local found, block = turtle.inspectDown()
    if found then
        if BLACKLIST[block.name] then 
            move(10, "up")
            waitForKey("Un bloc bloqueja el camí")
            move(10, "down")
            return checkBlock()
        end
    end
    return true
end

function empty()
    local index = find(ENDER)
    turtle.select(index)
    turtle.placeUp()
    for i = 1, 16 do
        while turtle.getItemCount(i) > 0 do
            turtle.select(i)
            turtle.dropUp()
            sleep(0.05)
        end
    end
    turtle.select(1)
    turtle.digUp()
end

local counter = 1
function add()
    counter = counter + 1
    if counter == COUNTER_N then
        empty()
        counter = 1
    end
end

function mine(z)
    for i = 1, z - 1 do
        if checkBlock() then
            turtle.digDown()
            turtle.down()
        end
        add()
    end
    empty()
end

repostar()

modem.transmit(1, CHANNEL, true)

local message = receive()
local x, y, z = unpack(message.to)
local back = false

if turtle.getFuelLevel() < ((x + y + z) * 2 + 50) then
    waitForKey("No hi ha combustible suficient")
end

parallel.waitForAll(
    function()
        move(x)
        if y > 0 then
            turtle.turnRight()
            move(y)
            turtle.turnLeft()
        end
        mine(z + 1)
    end,
    function()
        back = waitForEnd()
    end
)

if not back then
    waitForEnd()
end
turtle.turnLeft()
move(z, "up")
move(y)
turtle.turnLeft()
move(x)