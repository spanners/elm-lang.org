var firebaseData = new Firebase('https://sweltering-fire-9141.firebaseio.com/dissertation');
var stamps = Elm.fullscreen(Elm.Moose, {});
var currentCount = document.getElementById('current-count'),
    totalCount   = document.getElementById('total-count'),
    total        = 0;
stamps.ports.count.subscribe(function(count) {
    currentCount.innerHTML = count;
    if (count > 0) {
        total += 1;
        totalCount.innerHTML = total;
    }
});
