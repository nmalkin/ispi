TARGET_COLOR = 'red'
TARGET_RADIUS = 40 # pixels

# Initialize "paper" under spotlight
# and "surface" above it
box = $('#frame')
paper = Raphael 'paper', box.width(), box.height()
surface = Raphael 'surface', box.width(), box.height()

# where should I put the target?
x = box.width() - TARGET_RADIUS
y = box.height() - TARGET_RADIUS

# Draw circle at desired location
target = paper.circle x, y, TARGET_RADIUS 
target.attr "fill", TARGET_COLOR
target.attr "stroke", TARGET_COLOR

# We want to attach a mouseover event to it,
# but the target wouldn't get it because it would
# be captured by the spotlight above it.
# So we create a new element, the "ghost", that lives above the spotlight
# and captures the needed mouseover event.
ghost = surface.circle x, y, TARGET_RADIUS 
ghost.attr "fill", 'transparent'
ghost.attr "stroke", "white"
$(ghost.node).css 'z-index', 60

#$(ghost.node).mouseenter () ->

ghost.mouseover () ->
    alert 'You found it!'

#$('#surface').mousedown (event) ->
    #console.log "Now at #{event.pageX}, #{event.pageY}"
