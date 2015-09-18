package atom.haxe.ide;

private typedef Position = {
    var start : Int;
    var end : Int;
}

class ErrorMessage {

    static var EXP = ~/^(.+):([0-9]+): characters ([0-9]+\-[0-9]+) : (.+)$/i;

    public var path : String;
    public var line : Int;
    public var pos : Position;
    public var content : String;

    public function new() {}

    public function toString() : String {
        return '$path:$line: characters ${pos.start}-${pos.end} : $content';
    }

    public static function parse( str : String ) : ErrorMessage {
        if( EXP.match( str ) ) {
            var e = new ErrorMessage();
            e.path = EXP.matched(1);
            e.line = Std.parseInt( EXP.matched(2) );
            var _pos = EXP.matched(3).split( '-' );
            e.pos = { start: Std.parseInt(_pos[0]), end: Std.parseInt(_pos[1]) };
            e.content = EXP.matched(4);
            return e;
        }
        return null;
    }
}
