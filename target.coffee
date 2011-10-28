CIRCLE_COLOR = 'red'
CIRCLE_RADIUS = 40 # pixels

# initialize Raphael "paper" on top of spotlight frame
box = $('#frame')
paper = Raphael 'paper', box.width(), box.height()

# draw circle at desired location
x = box.width() - CIRCLE_RADIUS
y = box.height() - CIRCLE_RADIUS

circle = paper.circle x, y, CIRCLE_RADIUS 
circle.attr "fill", CIRCLE_COLOR
circle.attr "stroke", CIRCLE_COLOR
