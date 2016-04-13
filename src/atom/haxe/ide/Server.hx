package atom.haxe.ide;

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
    //public var status(default,null) : ServerStatus;

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

    public function start( verbose = true, callback : Void->Void ) {

        if( active )
            throw 'already active';

        var args = ['--wait','$host:$port'];
        if( verbose ) args.push( '-v' );

        trace( 'Starting haxe server: '+args.join(' ') );

        process = spawn( exe, args, {} );
        process.stdout.on( 'data', handleData );
        process.stderr.on( 'data', handleError );
        process.on( 'exit', handleExit );
        process.on( 'message', function(e) trace(e) );
        process.on( 'error', function(e) {
            trace(e); //TODO
        });

        //TODO
        status = idle;
        //trace(proc.connected);
        onStart();
    }

    public function stop() {
        if( active ) {
            active = false;
            process.stdin.end();
            process.stdout.end();
            //try process.kill() catch(e:Dynamic) trace(e);
            //try process = null catch(e:Dynamic) trace(e);
            //onStop(0);
        }
    }

    public function dispose() {
        stop();
    }

    function handleData(e) {
        trace(e);
        onMessage( e.toString() );
    }

    function handleError(e) {
        trace(e);
        onError( e.toString() );
    }

    function handleExit( code : Int ) {
        status = off;
        onStop( code );
    }

}
