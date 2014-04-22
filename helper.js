var firebaseData = new Firebase('http://sweltering-fire-9141.firebaseio.com/dissertation/elm/1');
var elm = Elm.fullscreen(Elm.StampTogether, {
	stamped: {
		t: 0,
		x: 0,
		y: 0
	}
});
firebaseData.on('child_added', function(snapshot) {
	elm.ports.stamped.send(snapshot.val());
});
