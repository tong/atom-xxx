package atom.haxe.ide;

private typedef Position = {
    var start : Int;
    var end : Int;
}

//TODO move this class to lib/haxe-tools project

class ErrorMessage {

    public static var EXP(default,null) = ~/^\s*(.+):([0-9]+):\s*(characters*|lines)\s([0-9]+)(-([0-9]+))?\s:\s(.+)$/i;

    public var path : String;
    public var line : Int;
    public var lines : Position;
    public var character : Int;
    public var characters : Position;
    public var content : String;

    public function new() {}

    public function toString() : String {
        var str = '$path:$line: ';
        if( lines != null )
            str += 'lines ${lines.start}-${lines.end}';
        else if( character != null )
            str += 'character $character';
        else if( characters != null )
            str += 'characters ${characters.start}-${characters.end}';
        str += ' : $content';
        return str;
    }

    public static function parse( str : String ) : ErrorMessage {
        if( EXP.match( str ) ) {
            var e = new ErrorMessage();
            e.path = EXP.matched(1);
            e.line = Std.parseInt( EXP.matched(2) );
            var posType = EXP.matched(3);
            switch posType {
            case 'character':
                e.character = Std.parseInt( EXP.matched(4) );
                e.content = EXP.matched(7);
            case 'characters':
                e.characters = {
                    start: Std.parseInt(EXP.matched(4)),
                    end: Std.parseInt(EXP.matched(6))
                };
                e.content = EXP.matched(7);
            case 'lines':
                e.lines = {
                    start: Std.parseInt(EXP.matched(4)),
                    end: Std.parseInt(EXP.matched(6))
                };
                e.content = EXP.matched(7);
            }
            return e;
        }
        return null;
    }
}
