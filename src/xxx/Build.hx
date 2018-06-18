package xxx;

import om.haxe.ErrorMessage;

using haxe.io.Path;

@:enum private abstract EventType(String) to String {
	var start = "start";
	var message = "message";
	var error = "error";
	var end = "end";
}

class Build extends Emitter {

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
	//	args.push( '--times' );

		//trace(args);

		console.group( '%c'+'haxe '+args.join(' '), 'color:${IDE.COLOR_HAXE_3};' );
		//console.log( '%c'+'haxe '+args.join(' '), 'color:${IDE.COLOR_HAXE_3};' );

		IDE.server.query( args,
			function( res : String ) {
				//if( res.length > 0 ) log( res );
				console.groupEnd();
				trace("END");
				emit( EventType.end, 0 );
			},
			function( err : String ) {

				//trace(err);
				//var str : String = err.trim();
				//var err = ErrorMessage.parse( str );
				var str = err.trim();
				//if( str.length > 0 )

				console.log( str );

				emit( EventType.error, str );
				emit( EventType.end, null );
			},
			function( msg : String ) {
				//trace(msg);
				/*
				log( msg );
				*/
				emit( EventType.message, msg );
			}
		);

		emit( EventType.start, null );

		return this;
	}

	static inline function log( data ) {
		console.log( '%c'+data, 'color:${IDE.COLOR_HAXE_3};' );
	}

}
