var spot = null;
var box = null;
var boxProperty = '';

$(document).ready(function () {
    spot = $('#tsb-spot');
    box = $('#tsb-box');
    
    // This is detecting the kind of box shadow support, to use the correct property name.
    // This can probably be replaced with a call to Modernizr or something similar.
    if (box.css('webkitBoxShadow')) {
        boxProperty = 'webkitBoxShadow';
    } else if (box.css('MozBoxShadow')) {
        boxProperty = 'MozBoxShadow';
    } else if (box.css('boxShadow')) {
        boxProperty = 'boxShadow';
    }

    if (spot && box) {
        $('#text-shadow-box').mousemove(onMouseMove);
        
        $('#text-shadow-box').bind('touchmove', function (e) {
            e = e.originalEvent;
            e.preventDefault();
            e.stopPropagation();
            onMouseMove({
                clientX: e.touches[0].clientX, 
                clientY: e.touches[0].clientY
            });
        });
    }
    
    onMouseMove({clientX: 300, clientY: 200});
});


function onMouseMove(e) {
    var xm = e.clientX - 300;
    var ym = e.clientY - 175;
    var d = Math.round(Math.sqrt(xm*xm + ym*ym) / 5);
    
    if (boxProperty) {
        box.css('boxProperty', '0 ' + -ym + 'px ' + (d + 30) + 'px black');
    }
    
    xm = e.clientX - 600;
    ym = e.clientY - 450;
    spot.css('backgroundPosition', xm + 'px ' + ym + 'px');
}
