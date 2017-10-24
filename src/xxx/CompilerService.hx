package xxx;

import atom.autocomplete.*;

typedef Item = {
	@:optional var n : String;
	@:optional var k : String;
	@:optional var t : String;
	@:optional var d : String;
	@:optional var p : String;
	@:optional var c : String;
}

class CompilerService {

	public var editor : TextEditor;

	public function new( editor : TextEditor ) {
		this.editor = editor;
	}

	public inline function callArgument( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Item> {
		return query( pos, extraArgs ).then( function(xml:Element){
			var d = xml.getAttribute('d');
			return cast {
				d: (d == null) ? null : d.trim(),
				t: xml.childNodes[0].nodeValue.trim()
			};
		});
	}

	public inline function fieldAccess( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs ).then( function(xml:Element){
			var items : Array<Item> = [];
			for( i in 0...xml.children.length ) {
				var e = xml.children[i];
				var t = e.getElementsByTagName( 't' )[0].childNodes[0];
				var d = e.getElementsByTagName( 'd' )[0].childNodes[0];
				items.push( {
					n: e.getAttribute('n'),
					k: e.getAttribute('k'),
					t: (t == null) ? null : t.nodeValue,
					d: (d == null) ? null : d.nodeValue.trim()
				} );
			}
			return cast items;
		});
	}

	public inline function topLevel( pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'toplevel', extraArgs ).then( function(xml:Element){
			var items : Array<Item> = [];
			for( i in 0...xml.children.length ) {
				var e = xml.children[i];
				var d = e.getAttribute('d');
				items.push( {
					k: e.getAttribute('k'),
					n: e.getAttribute('n'),
					t: e.getAttribute('t'),
					d: (d == null) ? null : d.trim(),
					p: e.getAttribute('p'),
					c: e.childNodes[0].nodeValue
				} );
			}
			return cast items;
		});
	}

	/*
	public inline function position( ?pos : Point, ?extraArgs : Array<String> ) : Promise<om.haxe.Message> {
		return query( pos, 'position', extraArgs ).then( function(items) {
			var str = xml.elementsNamed( 'pos' ).next().firstChild().nodeValue;
			var msg = om.haxe.Message.parse( str );
			return Promise.resolve( msg );
		});
	}

	public inline function usage( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'usage', extraArgs );
	}
	*/

	//public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
	public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String> ) : Promise<Element> {

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
					var parser = new js.html.DOMParser();
					var xml = parser.parseFromString( r, APPLICATION_XML ).documentElement;
					resolve( xml );
				},
				function(e) {
					console.warn( e );
					//if( onError != null ) onError( e );
				},
				function(m) {

					console.warn(m);
					reject(m);
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
