package xxx;

import atom.autocomplete.*;

/*
private typedef I = {
	var n : String;
	var k : String;
	var t : String;
	var d : String;
}
*/

class CompilerService {

	public var editor(default,null) : TextEditor;

	public function new( editor : TextEditor ) {
		this.editor = editor;
	}

	public inline function callArgument( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Xml> {
		return query( pos, extraArgs );
	}

	public inline function fieldAccess( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Xml> {
		return query( pos, extraArgs ).then( function(xml:Xml){
			return Promise.resolve( xml );
		});
	}

	public inline function position( ?pos : Point, ?extraArgs : Array<String> ) : Promise<om.haxe.Message> {
		return query( pos, 'position', extraArgs ).then( function(xml:Xml) {
			var str = xml.elementsNamed( 'pos' ).next().firstChild().nodeValue;
			var msg = om.haxe.Message.parse( str );
			return Promise.resolve( msg );
		});
	}

	public inline function topLevel( pos : Point, ?extraArgs : Array<String> ) : Promise<Xml> {
		return query( pos, 'toplevel', extraArgs );
	}

	public inline function usage( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Xml> {
		return query( pos, 'usage', extraArgs );
	}

	public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String> ) : Promise<Xml> {

		return new Promise( function(resolve,reject){

			if( pos == null ) pos = editor.getCursorBufferPosition();

			var preText = editor.getTextInBufferRange( new Range( new Point(0,0), pos ) );
			var index = preText.length;
			//	var displayPos = editor.getPath() + '@' + index;
			var displayPos = '${editor.getPath()}@$index';
			if( mode != null ) displayPos += '@$mode';
			var args = [ IDE.hxml.getPath(), '--display', displayPos ];
			if( extraArgs != null ) args = args.concat( extraArgs );

			IDE.server.query( args, preText,
				function(r) {
					var xml = Xml.parse( r ).firstElement();
					resolve( xml );
					//onResult( xml );
				},
				function(e) {
					console.warn( e );
					//if( onError != null ) onError( e );
				},
				function(m) {
					console.warn(m);
					//reject( m );
				}
			);
		});
	}

	/*
	public inline function fieldAccess( ?pos : Point, onResult : Xml->Void, ?onError : String->Void ) {
		query( pos, onResult, onError );
	}

	public inline function callArgument( ?pos : Point, onResult : Xml->Void, ?onError : String->Void ) {
		query( pos, onResult, onError );
	}

	public inline function usage( ?pos : Point, onResult : Xml->Void, ?onError : String->Void ) {
		query( pos, 'usage', onResult, onError );
	}

	public inline function position( ?pos : Point, onResult : Xml->Void, ?onError : String->Void ) {
		query( pos, 'position', onResult, onError );
	}

	public inline function topLevel( pos : Point, onResult : Xml->Void, ?onError : String->Void ) {
		query( pos, 'toplevel', onResult, onError );
	}

	public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String>, onResult : Xml->Void, ?onError : String->Void ) {

		if( pos == null ) pos = editor.getCursorBufferPosition();

		var preText = editor.getTextInBufferRange( new Range( new Point(0,0), pos ) );
		var index = preText.length;
	//	var displayPos = editor.getPath() + '@' + index;
		var displayPos = '${editor.getPath()}@$index';
		if( mode != null ) displayPos += '@$mode';
		var args = [ IDE.hxml.getPath(), '--display', displayPos ];
		if( extraArgs != null ) args = args.concat( extraArgs );

		IDE.server.query( args, preText,
			function(r) {
				onResult( Xml.parse( r ).firstElement() );
			},
			function(e) {
				if( onError != null ) onError( e );
			},
			function(m) {
				console.log(m);
			}
		);
	}
	*/

}
