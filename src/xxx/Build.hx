package xxx;

import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess as Process;
import atom.File;

using StringTools;
using haxe.io.Path;

class Build extends atom.Emitter {

	public var hxml(default,null) : File;
    public var running(default,null) : Bool;
    //public var time(default,null) : Float;

	var proc : Process;

	public function new() {
		super();
		running = false;
    }

	public function select( hxml : String ) {

		if( this.hxml != null && hxml == this.hxml.getPath() )
			return;

		//Atrom.project();

		emit( 'hxml_select', this.hxml = new File( hxml ) );
	}

	public function start( verbose = false ) {

		if( hxml == null )
			throw 'no hxml file selected';

		var cwd = hxml.getParent().getPath();

		var args = new Array<String>();
		if( verbose ) args.push( '-v' );
		args.push( hxml.getBaseName() );

		proc = spawn( 'haxe', args, { cwd : cwd } );
        proc.stdout.on( 'data', function(e) emit( 'message', e.toString() ) );
        proc.stderr.on( 'data', function(e) emit( 'error', e.toString() ) );
        proc.on( 'exit', function(code) emit( 'end', code ) );
        proc.on( 'message', function(e) trace(e) );
        proc.on( 'error', function(e) {
            trace(e); //TODO
        });

		running = true;

		emit( 'start' );
	}

	public function stop() {
		if( proc != null ) {
			try proc.kill() catch(e:Dynamic) trace(e);
		}
		running = false;
	}

}
