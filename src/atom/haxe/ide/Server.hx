package atom.haxe.ide;

import js.Browser.console;
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
    public var status(default,null) : ServerStatus;

    var proc : Process;

    public function new() {
        status = off;
    }

    public function start( exe : String, port : Int, host : String, verbose = true, callback : Void->Void ) {

        this.exe = exe;
        this.port = port;
        this.host = host;

        status = off;

        var args = new Array<String>();
        if( verbose ) args.push( '-v' );
        args.push( '--wait' );
        args.push( '$host:$port' );

        console.log( 'Starting haxe server: '+args.join(' ') );

        proc = spawn( exe, args, {} );
        proc.stdout.on( 'data', handleData );
        proc.stderr.on( 'data', handleError );
        proc.on( 'exit', handleExit );
        proc.on( 'message', function(e) trace(e) );
        proc.on( 'error', function(e) {
            trace(e); //TODO
        });

        //TODO
        status = idle;
        //trace(proc.connected);
        onStart();
    }

    public function stop() {
        if( status != off ) {
            status = off;
            try proc.kill() catch(e:Dynamic) trace(e);
            try proc = null catch(e:Dynamic) trace(e);
            //onStop(0);
        }
    }

    function handleData(e) {
        onMessage( e.toString() );
    }

    function handleError(e) {
        onError( e.toString() );
    }

    function handleExit( code : Int ) {
        status = off;
        onStop( code );
    }

}
