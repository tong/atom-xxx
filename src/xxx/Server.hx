package xxx;

import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess as Process;

class Server extends atom.Emitter {

	public var path(default,null) : String;
    public var port(default,null) : Int;
    public var host(default,null) : String;
	public var verbose : Bool;
    public var running(default,null) : Bool;

	var proc : Process;

	public function new( path = 'haxe', port : Int, host = '127.0.0.1', verbose = true ) {
		super();
		this.path = path;
		this.port = port;
		this.host = host;
		this.verbose = verbose;
		running = false;
    }

	public inline function onStart( h : Void->Void ) on( 'start', h );
	public inline function onError( h : String->Void ) on( 'error', h );
	public inline function onMessage( h : String->Void ) on( 'message', h );
	public inline function onStop( h : Int->Void ) on( 'stop', h );

	//public function start( verbose = true, onData : String->Void, onError : String->Void, onExit : Int->Void ) {
	public function start() {

		var args = new Array<String>();
		if( verbose ) args.push( '-v' );
		args.push( '--wait' );
		args.push( '$host:$port' );

		proc = spawn( path, args, {} );
        proc.stdout.on( 'data', function(e) emit( 'message', e.toString() ) );
        proc.stderr.on( 'data', function(e) emit( 'error', e.toString() ) );
        //proc.on( 'exit', function(code) emit( 'stop', code ) );
        proc.on( 'close', function(code) emit( 'stop', code ) );
        proc.on( 'message', function(e) trace(e) );
        proc.on( 'error', function(e) {
            trace(e); //TODO
        });

		running = true;

		/*
		haxe.Timer.delay(function(){
			trace(proc.connected);
		},500);
		*/

		emit( 'start' );
	}

	public function stop() {

		trace("STOP SERVER");

		if( proc != null ) {
			proc.removeAllListeners();
			try proc.kill() catch(e:Dynamic) trace(e);
			proc = null;
			emit( 'stop', 0 );
		}
		running = false;
	}

}
