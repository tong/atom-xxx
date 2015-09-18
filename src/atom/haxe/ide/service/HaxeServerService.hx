package atom.haxe.ide.service;

typedef HaxeServerStatus = {
    var exe : String;
    var host : String;
    var port : Int;
    var running : Bool;
}

typedef HaxeServerService = {
    var getStatus : Void->HaxeServerStatus;
    var start : Void->Void;
    var stop : Void->Void;
}
