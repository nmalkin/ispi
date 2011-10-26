var box = null;
var spot = null;

$(document).ready(function () {
    spot = $('#spot');
    box = $('#frame');
    
    if (spot && box) {
        box.mousemove(onMouseMove);
        
        // This code handles touch events in Webkit browsers.
        // I don't have the facility for testing this ATM. (TODO)
        /*
        box.bind('touchmove', function (e) {
            e = e.originalEvent;
            e.preventDefault();
            e.stopPropagation();
            onMouseMove({
                clientX: e.touches[0].clientX, 
                clientY: e.touches[0].clientY
            });
        });
        */
    }
    
    onMouseMove({pageX: 0, pageY: 0});
});


function onMouseMove(e) {
    var boxPosition = box.position();

    var clientX = e.pageX - boxPosition.left;
    var clientY = e.pageY - boxPosition.top;

    var xm = clientX - box.width() / 2;
    var ym = clientY - box.height() / 2;
    var d = Math.round(Math.sqrt(xm*xm + ym*ym) / 5);
    
    xm = clientX - box.width();
    ym = clientY - box.height();
    spot.css('backgroundPosition', xm + 'px ' + ym + 'px');
}
