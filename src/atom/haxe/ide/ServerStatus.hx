package atom.haxe.ide;

@:enum abstract ServerStatus(String) from String to String {
    var off = "off";
    var idle = "idle";
    var active = "active";
    var error = "error";
}
