package xxx;

import js.Browser.console;
import js.Promise;
import atom.Point;
import atom.Range;
import atom.TextEditor;
import atom.autocomplete.*;
import om.haxe.SourceCodeUtil.*;

using StringTools;
using haxe.io.Path;

class AutoComplete {

	var editor : TextEditor;

	public function new( editor : TextEditor ) {
		this.editor = editor;
	}

	//public function setTextEditor()

	public inline function fieldAccess( ?pos : Point, callback : Xml->Void ) {
		query( pos, callback );
	}

	public inline function callArgument( ?pos : Point, callback : Xml->Void ) {
		query( pos, callback );
	}

	public inline function usage( ?pos : Point, callback : Xml->Void ) {
		query( pos, 'usage', callback );
	}

	public inline function position( ?pos : Point, callback : Xml->Void ) {
		query( pos, 'position', callback );
	}

	function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String>, onResult : Xml->Void, ?onError : String->Void ) {

		if( pos == null ) pos = editor.getCursorBufferPosition();

		var index = editor.getTextInBufferRange( new Range( new Point(0,0), pos ) ).length;

		var displayPos = editor.getPath() + '@' + index;
		if( mode != null ) displayPos += '@$mode';

		var args = [ IDE.hxml.getPath(), '--display', displayPos ];
		//if( extraArgs != null ) {
		//	args = extraArgs.concat( args );

		IDE.server.query( args, editor.getText(),
			function(res){
				//trace(res);
				//var xml = Xml.parse( result ).firstElement();
				onResult( Xml.parse( res ).firstElement() );
			},
			function(err){
				trace(err);
			},
			function(msg){
				trace(msg);
			}
		);
	}

}
