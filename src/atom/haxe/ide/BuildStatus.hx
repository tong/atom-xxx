package atom.haxe.ide;

@:enum abstract BuildStatus(String) from String to String {
    var idle = 'idle';
    //var wait = 'wait';
    var active = 'active';
    var success = 'success';
    var error = 'error';
}
