package xxx;

import atom.autocomplete.*;

class AutoComplete {

	public var editor(default,null) : TextEditor;

	//TODO cache
	//var lastQuery

	public function new( editor : TextEditor ) {
		this.editor = editor;
	}

	//public function setTextEditor()

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

}
