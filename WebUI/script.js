const obj = document.getElementById('damage');
var root_damage = null

function DisplayHit(index, dmg, fadeOutTime, isHeadshot) {
    if (!root_damage) {
        root_damage = $("#root_damage")
    }
    var $new_hit
    if (isHeadshot === 1) {
        $new_hit = $("<div id='" + index + "' class='headshotHit'>" + dmg + "</div>")
    }
    else {
        $new_hit = $("<div id='" + index + "' class='hit'>" + dmg + "</div>")
    }

    // Append new div
    root_damage.append($new_hit)

    // Fade out and remove
    $new_hit.fadeOut(fadeOutTime * 1000, "linear", function() {
        $(this).remove()
    })
}

function UpdatePosition(index, y, x) {
    var hitElement = document.getElementById(index)
    if (hitElement) {
        hitElement.setAttribute('style', 'position:absolute; top:' + x + ";left:" + y)
    }
}

function SetDistancePlayerName(distance, player) {
    $("#distance_info .distance").text(distance + " m")
    $("#distance_info .player_name").text("(" + player + ")")
}

function ClearDistancePlayerName() {
    $("#distance_info .distance").text("")
    $("#distance_info .player_name").text("")
}