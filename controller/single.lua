CHANNEL = 2
local modem = peripheral.wrap("back") or error("No modem attached", 0)
modem.open(CHANNEL)

local args = {...}

local launch = false
if #args > 0 then
    launch = args[1] == "true"
end

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

old_print = print
function print(text, ...)
    old_print(text:format(unpack(arg)))
end

function locate()
    local x, z, y = gps.locate()
    -- compensem per l'altura del telèfon i la posició inicial
    x = math.floor(x)
    y = math.floor(y)
    -- overworld
    z = math.floor(z) - 2 + 63
    -- nether
    -- z = math.floor(z) - 1
    -- overworld
    return y, x, z
    -- nether
    -- return x, y, z
end

function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

function calculate(p1, p2)
    clear()
    local w, h = math.abs(p1[1] - p2[1]) + 1, math.abs(p1[2] - p2[2]) + 1
    local area = w * h
    print(("Area (X/Y):\n%d/%d"), w, h)
    print(("Mining Area  (b²):\n%d"), area)
    print(("Height:\n%d"), p1[3])
    print("Pulsa [Enter]...")
    return w, h
end

local p1, p2 = {locate()}, {locate()}
local width, height = calculate(p1, p2)

transmit({action="setup", position1 = p1, position2 = p2, height = p1[3]}, 1)
receive()

if launch then
    transmit({action="launch"}, 1)
    receive()
end