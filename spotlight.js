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
    
    onMouseMove({clientX: 0, clientY: 0});
});


function onMouseMove(e) {
    var xm = e.clientX - 300;
    var ym = e.clientY - 175;
    var d = Math.round(Math.sqrt(xm*xm + ym*ym) / 5);
    
    xm = e.clientX - 600;
    ym = e.clientY - 450;
    spot.css('backgroundPosition', xm + 'px ' + ym + 'px');
}
