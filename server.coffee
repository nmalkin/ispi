connect = require 'connect'
server = connect.createServer()
server.use connect.favicon()
server.use connect.logger()
server.use connect.static __dirname
server.listen(80)

io = require('socket.io').listen server 

io.sockets.on 'connection', (socket) ->
    console.log 'Opened new connection'
   
    socket.on 'begin', (name) ->
        console.log "#{name} initiated connection"
        
        console.log 'Setting name'
        socket.set 'name', name, () ->
            console.log 'Sending welcome message'
            socket.emit 'welcome', {}

    socket.on 'initialization done', () ->
        console.log 'Initiating trial'
        socket.emit 'trial', {targetX: 400, targetY: 300}

    socket.on 'position', (data) ->
        x = data.x
        y = data.y

        socket.get 'name', (err, name) ->
            if err?
                console.log err
            else
                console.log "#{name} is at #{x},#{y}"

    socket.on 'success', (data) ->
        socket.get 'name', (err, name) ->
            if err?
                console.log err
            else
                console.log "#{name} reports finding target"

                randint = (max) ->
                    Math.floor(Math.random()*max)
                
                # Pick out a random location for the target
                x = randint 600
                y = randint 300

                console.log "New trial with target at #{x}, #{y}"

                socket.emit 'trial', {targetX: x, targetY: y}
