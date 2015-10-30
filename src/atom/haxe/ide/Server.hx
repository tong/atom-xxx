package atom.haxe.ide;

import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess as Process;

class Server {

    public dynamic function onStart() {}
    public dynamic function onStop( code : Int ) {}
    public dynamic function onError( msg : String) {}
    public dynamic function onMessage( msg : String ) {}

    public var exe(default,null) : String;
    public var port(default,null) : Int;
    public var host(default,null) : String;
    public var running(default,null) : Bool;

    var proc : Process;

    public function new() {
        running = false;
    }

    public function start( exe : String, port : Int, host : String, verbose = true ) {

        trace( 'Starting haxe server $host:$port' );

        this.exe = exe;
        this.port = port;
        this.host = host;

        var args = new Array<String>();
        if( verbose ) args.push( '-v' );
        args.push( '--wait' );
        args.push( '$host:$port' );

        proc = spawn( exe, args, {} );
        proc.stdout.on( 'data', handleData );
        proc.stderr.on( 'data', handleError );
        proc.on( 'error', function(e) trace(e) );

        running = true;
        onStart();
    }

    public function stop() {
        if( running ) {
            try proc.kill() catch(e:Dynamic) trace(e);
            onStop(0);
        }
    }

    function handleData(e) {
        //trace(e.toString());
        onMessage( e.toString() );
    }

    function handleError(e) {
        //trace(e.toString());
        onError( e.toString() );
    }

}
