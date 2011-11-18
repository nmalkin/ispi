mouseMoveHandler = (e) ->
    spot = $('#spot')
    box = $('#frame')

    boxPosition = box.position()

    clientX = e.pageX - boxPosition.left
    clientY = e.pageY - boxPosition.top

    xm = clientX - box.width() / 2
    ym = clientY - box.height() / 2
    d = Math.round(Math.sqrt(xm*xm + ym*ym) / 5)
    
    xm = clientX - box.width()
    ym = clientY - box.height()
    spot.css 'backgroundPosition', xm + 'px ' + ym + 'px'
