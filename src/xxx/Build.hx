package xxx;

import atom.File;
import om.haxe.ErrorMessage;

using StringTools;
using haxe.io.Path;

class Build extends atom.Emitter {

	static inline var EVENT_START = 'start';
	static inline var EVENT_MESSAGE = 'message';
	static inline var EVENT_ERROR = 'error';
	static inline var EVENT_END = 'end';

	public var hxml(default,null) : File;
    //public var active(default,null) : Bool;
    //public var time(default,null) : Float;

	public function new( hxml : File ) {
		super();
		this.hxml = hxml;
    }

	public inline function onStart( h : Void->Void ) return on( EVENT_START, h );
	public inline function onMessage( h : String->Void ) return on( EVENT_MESSAGE, h );
	public inline function onError( h : String->Void ) return on( EVENT_ERROR, h );
	public inline function onEnd( h : Int->Void ) return on( EVENT_END, h );

	public function start( verbose = false ) {

		//TODO really
		var cwd = hxml.getParent().getPath();
		var args = [ '--cwd', cwd ];
		if( verbose ) args.push( '-v' );
		args.push( hxml.getBaseName() );

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
				//var str : String = err.trim();
				//var err = ErrorMessage.parse( str );
				emit( EVENT_ERROR, err.trim() );
				emit( EVENT_END );
			}
		);

		emit( EVENT_START );
	}

}
