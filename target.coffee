TARGET_COLOR = 'red'
TARGET_RADIUS = 40 # pixels

# Initialize "paper" under spotlight
# and "surface" above it
box = $('#frame')
paper = Raphael 'paper', box.width(), box.height()

# where should I put the target?
x = box.width() - TARGET_RADIUS
y = box.height() - TARGET_RADIUS

# Draw circle at desired location
drawCircle = (canvas, x, y, radius, color) ->
    circle = canvas.circle x, y, TARGET_RADIUS 
    circle.attr "fill", color
    circle.attr "stroke", color
    circle

# Draw the target circle
target = drawCircle paper, x, y, TARGET_RADIUS, TARGET_COLOR

# We would like to attach a mouseover event to the target
# (so we know when people reach it),
# but the target wouldn't receive it because the event would
# be captured by the spotlight layer above it.
# So we create a new element, the "ghost", that lives above the spotlight
# and captures the needed mouseover event.
surface = Raphael 'surface', box.width(), box.height() # note that #surface has z-index > spot > paper
ghost = drawCircle surface, x, y, TARGET_RADIUS, 'transparent'

# Moves the target (and its ghost) to the specified position
moveTarget = (newX, newY) ->
    b = target.getBBox()

    dx = x - b.x
    dy = y - b.y

    target.translate dx, dy
    ghost.translate dx, dy

    console.log "Currently at #{b.x}, #{b.y}"
    console.log "New position #{x}, #{y}"
    console.log "Translating #{dx}, #{dy}"


ghost.mouseover () ->
    console.log 'Acquired target'
    #alert 'You found it!'
    
    randint = (max) ->
        Math.floor(Math.random()*max)

    x = randint(box.width())
    y = randint(box.height())

    moveTarget x,y
