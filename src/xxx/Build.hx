package xxx;

import js.Node;
import js.node.ChildProcess;
import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess;

class BuildError {

    public var message : String;
    public var file : String;
    public var line : Int;
    public var start : Int;
    public var end : Int;

    @:allow(xxx.Build) function new( message : String, file : String, line : Int, start : Int, end : Int ) {
        this.message = message;
        this.file = file;
        this.line = line;
        this.start = start;
        this.end = end;
    }

    public function toString() {
    }
}

class Build {

    //public dynamic function onError( str : String ) {}
    //public dynamic function onResult( str : String ) {}
    //public dynamic function onEnd( code : Int ) {}

    public var exe(default,null) : String;
    public var active(default,null) : Bool;
    //public var errors(default,null) : Array<Error>;

    var process : ChildProcess;

    var onError : String->Void;
    var onResult : String->Void;
    var onEnd : Int->Void;

    public function new( exe = 'haxe' ) {
        this.exe = exe;
        active = false;
    }

    public function start( args : Array<String>, ?opts : ChildProcessSpawnOptions, onError : String->Void, onResult : String->Void, onEnd : Int->Void ) {

        //trace( 'haxe '+args.join(' ') );

        if( active )
            throw 'build already active';

        this.onError = onError;
        this.onResult = onResult;
        this.onEnd = onEnd;

        active = true;
        //error = '';

        process = spawn( exe, args, opts );
        process.stdout.on( 'data', handleData );
        process.stderr.on( 'data', handleError );
        process.on( 'close', handleClose );
    }

    public function cancel() {
        active = false;
        killProcess();
    }

    function handleData(e) {
        //trace(e.toString());
        onResult( e.toString() );
    }

    function handleError(e) {
        //trace(e.toString());
        onError( e.toString() );
    }

    function handleClose( code : Int ) {
        process = null;
        switch code {
        case 0:
        default:
        }
        onEnd( code );
    }

    function killProcess() {
        if( process != null ) {
			try {
                process.kill();
                process = null;
            } catch(e:Dynamic) {
                trace(e);
            }
		}
    }

}
