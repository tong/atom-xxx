package atom.haxe.ide;

@:enum abstract BuildStatus(String) from String to String {
    //var off = 'off';
    //var wait = 'wait';
    var active = 'active';
    var success = 'success';
    var error = 'error';
}