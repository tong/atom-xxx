package xxx;

import js.Browser.console;
import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess as Process;

class Server {

    public dynamic function onStart() {}
    public dynamic function onData( str : String) {}
    public dynamic function onError( str : String ) {}
    public dynamic function onStop( code : Int ) {}

    public var exe(default,null) : String;
    public var port(default,null) : Int;
    public var host(default,null) : String;
    public var active(default,null) : Bool;

    var process : Process;

    public function new( exe = 'haxe', port : Int, host = '127.0.0.1' ) {
        this.exe = exe;
        this.port = port;
        this.host = host;
        active = false;
    }

    /*
    public function getHaxeFlag() : Array<String> {
        if( !isRunning() )
            return [];
        var str = Std.string( HaxeIDE.server.port );
        if( host != null ) str = host + ':' + str;
        return ['--connect',str];
    }
    */

    public function start( verbose = true ) {

        if( active )
            throw 'already active';

        var args = new Array<String>();
		if( verbose ) args.push( '-v' );
		args = args.concat( ['--wait','$host:$port'] );

        trace( 'Starting haxe server: $host:$port' );

		active = true;

        process = spawn( exe, args, {} );
        process.stdout.on( 'data', handleData );
        process.stderr.on( 'data', handleError );
        process.on( 'exit', handleExit );
        process.on( 'message', function(e) trace(e) );
        process.on( 'error', function(e) {
            trace(e); //TODO
        });
    }

    public function stop() {
        if( active ) {
            active = false;
			try {
				process.disconnect();
				process = null;
			} catch(e:Dynamic) {
				trace(e);
			}
            //process.stdout.end();
            //try process.kill() catch(e:Dynamic) trace(e);
            //try process = null catch(e:Dynamic) trace(e);
            //onStop(0);
        }
    }

    public function dispose() {
        stop();
    }

    function handleData(e) {
        onData( e.toString() );
    }

    function handleError(e) {
        onData( e.toString() );
        //onError( e.toString() );
    }

    function handleExit( code : Int ) {
        active = false;
        onStop( code );
    }

}
