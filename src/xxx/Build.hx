package xxx;

import js.node.ChildProcess.spawn;
import js.node.child_process.ChildProcess as Process;
import atom.File;
import om.haxe.ErrorMessage;

using StringTools;
using haxe.io.Path;

class Build extends atom.Emitter {

	static inline var EVENT_START = 'start';
	static inline var EVENT_MESSAGE = 'message';
	static inline var EVENT_ERROR = 'error';
	static inline var EVENT_END = 'end';

	public var haxePath(default,null) : String;
	public var hxml(default,null) : File;
    //public var active(default,null) : Bool;
    //public var time(default,null) : Float;

	//var proc : Process;

	public function new( haxePath = 'haxe', hxml : File ) {
		super();
		this.haxePath = haxePath;
		this.hxml = hxml;
		//active = false;
    }

	public inline function onStart( h : Void->Void ) return on( EVENT_START, h );
	public inline function onMessage( h : String->Void ) return on( EVENT_MESSAGE, h );
	public inline function onError( h : ErrorMessage->Void ) return on( EVENT_ERROR, h );
	public inline function onEnd( h : Int->Void ) return on( EVENT_END, h );

	public function start( verbose = false ) {

		var cwd = hxml.getParent().getPath();

		var args = ['--cwd',cwd];
		if( verbose ) args.push( '-v' );
		args.push( hxml.getBaseName() );

		if( IDE.server.isActive() ) {

			IDE.server.query( args,
			 	function(msg){
					trace(msg);
					emit( EVENT_MESSAGE, msg );
				},
			 	function(res){
					trace(res);
					emit( EVENT_END, 0 );
				},
				function(err){
					trace(err);
					var str : String = err.trim();
					var err = ErrorMessage.parse( str );
					emit( EVENT_ERROR, err );
					emit( EVENT_END );
				}
			);

			emit( EVENT_START );

		} else {

		}

		/*
		proc = spawn( haxe, args, { cwd : cwd } );
        proc.stdout.on( 'data', function(e) {
			emit( EVENT_MESSAGE, e.toString() );
		});
        proc.stderr.on( 'data', function(e) {

			var str : String = e.toString().trim();
			//trace(str);

			var err = ErrorMessage.parse( str );
			//trace(error);
			emit( EVENT_ERROR, err );

			/*
			for( line in str.split( '\n' ) ) {
				line = line.trim();
				if( line.length == 0 )
					continue;
				emit( 'error', line );
			}
			* /
		});
        proc.on( 'exit', function(code) {
			emit( EVENT_END, code );
		});
        proc.on( 'message', function(e) {
			trace(e);
		});
        proc.on( 'error', function(e) {
            trace(e); //TODO
        });

		active = true;

		emit( EVENT_START );
		*/
	}

	/*
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

		proc = spawn( path, args, { cwd : cwd } );
        proc.stdout.on( 'data', function(e) emit( 'message', e.toString() ) );
        proc.stderr.on( 'data', function(e) emit( 'error', e.toString() ) );
        proc.on( 'exit', function(code) emit( 'end', code ) );
        proc.on( 'message', function(e) trace(e) );
        proc.on( 'error', function(e) {
            trace(e); //TODO
        });

		active = true;

		emit( 'start' );
	}

	public function stop() {
		if( proc != null ) {
			try proc.kill() catch(e:Dynamic) trace(e);
		}
		active = false;
	}
	*/

}
