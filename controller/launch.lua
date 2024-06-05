CHANNEL = 2
local modem = peripheral.wrap("back") or error("No modem attached", 0)
modem.open(CHANNEL)

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

transmit({action="launch"}, 1)
receive()