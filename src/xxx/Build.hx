package xxx;

import atom.File;
import om.haxe.ErrorMessage;

using StringTools;
using haxe.io.Path;

@:enum abstract EventType(String) to String {
	var start = "start";
	var message = "message";
	var error = "error";
	var end = "end";
}

class Build extends atom.Emitter {

	public var hxml(default,null) : File;
	public var args(default,null) : Array<String>;
    //public var active(default,null) : Bool;
    //public var time(default,null) : Float;

	public function new( hxml : File ) {
		super();
		this.hxml = hxml;
    }

	public inline function onStart( h : Void->Void )
		return on( EventType.start, h );

	public inline function onMessage( h : String->Void )
		return on( message, h );

	public inline function onError( h : String->Void )
		return on( EventType.error, h );

	public inline function onEnd( h : Int->Void )
		return on( EventType.end, h );

	public function start( verbose = false ) {

		//TODO really
		var parent = hxml.getParent();
		var cwd = parent.getPath();
		args = [ '--cwd', cwd ];
		if( verbose ) args.push( '-v' );
		args.push( hxml.getBaseName() );

		IDE.server.query( args,
			function(res){
				emit( end, 0 );
			},
			function(err){
				//var str : String = err.trim();
				//var err = ErrorMessage.parse( str );
				emit( EventType.error, err.trim() );
				emit( EventType.end, null );
			},
			function(msg){
				emit( EventType.message, msg );
			}
		);

		emit( EventType.start, null );
	}

}
