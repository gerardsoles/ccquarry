CHANNEL = 2
local modem = peripheral.wrap("back") or error("No modem attached", 0)
modem.open(CHANNEL)

local args = {...}

local x = tonumber(args[1])
local y = tonumber(args[2])
local launch = false
if #args >= 3 then
    launch = args[3] == "true"
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

transmit({action="data"}, 1)
local settings = receive()
local p1, p2 = settings.position1, settings.position2
-- overworld
p1[1], p1[2] = p1[1] - x, p1[2] + y
p2[1], p2[2] = p2[1] - x, p2[2] + y
local width, height = calculate(p1, p2)

transmit({action="setup", position1 = p1, position2 = p2, height = p1[3]}, 1)
receive()

if launch then
    transmit({action="launch"}, 1)
    receive()
end