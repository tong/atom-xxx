package atom.haxe.ide;

import js.Node;
import js.Node.process;
import js.node.Fs;
import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess;

class Build {

    public dynamic function onMessage( msg : String ) {}
    public dynamic function onError( msg : String ) {}
    public dynamic function onSuccess() {}

    var proc : ChildProcess;
    var error : String;

    public function new() {}

    public function start( args : Array<String> ) {
        proc = spawn( 'haxe', args );
        proc.stdout.on( 'data', handleData );
        proc.stderr.on( 'data', handleError );
        //proc.on( 'error', handleError );
        proc.on( 'exit', handleExit );
    }

    function handleData(e) {
        onMessage( e.toString() );
    }

    function handleError(e) {
        error = e.toString();
    }

    function handleExit( code : Int ) {
        switch code {
        case 0: onSuccess();
        default: onError( error );
        }
    }

    static function now() : Float {
        var hr = js.Node.process.hrtime();
		return ( hr[0] * 1e9 + hr[1] ) / 1e6;
    }
}
