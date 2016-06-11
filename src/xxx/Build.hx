package xxx;

import js.Node;
import js.node.ChildProcess;
import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess;

/*
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
*/

class Build {

    public var exe(default,null) : String;
    public var active(default,null) = false;

    var process : ChildProcess;
    var onError : String->Void;
    var onResult : String->Void;
    var onEnd : Int->Void;

    public function new( exe = 'haxe' ) {
        this.exe = exe;
    }

    public function start( args : Array<String>, ?opts : ChildProcessSpawnOptions, onError : String->Void, onResult : String->Void, onEnd : Int->Void ) {

        if( active )
            throw 'build already active';

        if( opts == null ) opts = {};

        this.onError = onError;
        this.onResult = onResult;
        this.onEnd = onEnd;

        active = true;

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
        onResult( e.toString() );
    }

    function handleError(e) {
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
