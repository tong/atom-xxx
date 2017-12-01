package xxx;

import atom.autocomplete.*;
import js.html.DOMParser;

typedef Item = {
	@:optional var n : String;
	@:optional var k : String;
	@:optional var t : String;
	@:optional var d : String;
	@:optional var p : String;
	@:optional var c : String;
}

class CompletionService {

	@:allow(xxx.AutoCompleteProvider)
	var editor : TextEditor;

	var parser : DOMParser;
	var lastQuery : Array<String>;
	var lastQueryXml : Element;

	public function new( editor : TextEditor ) {
		this.editor = editor;
		parser = new DOMParser();
	}

	public function callArgument( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Item> {
		return query( pos, extraArgs ).then( function(xml:Element){
			var d = xml.getAttribute('d');
			return cast {
				d: (d == null) ? null : d.trim(),
				t: xml.childNodes[0].nodeValue.trim()
			};
		});
	}

	public function fieldAccess( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs ).then( function(xml:Element){
			if( xml == null )
				return [];
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

	public function topLevel( pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'toplevel', extraArgs ).then( function(xml:Element){
			if( xml == null )
				return [];
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

	public function usage( pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'usage', extraArgs ).then( function(xml:Element){
			if( xml == null )
				return [];
			for( i in 0...xml.children.length ) {
				var e = xml.children[i];
				trace(e);
				//TODO
			}
			return cast [];
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
	*/

	public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String> ) : Promise<Element> {

		return new Promise( function(resolve,reject){

			if( pos == null ) pos = editor.getCursorBufferPosition();

			var preText = editor.getTextInBufferRange( new Range( new Point(0,0), pos ) );
			var index = preText.length;
			//	var displayPos = editor.getPath() + '@' + index;
			var displayPos = '${editor.getPath()}@$index';
			if( mode != null ) displayPos += '@$mode';
			//var args = [ IDE.hxml.getPath(), '--display', displayPos ];
			var args = [ '--display', displayPos ];
			if( IDE.hxml != null ) args = [IDE.hxml.getPath()].concat( args );
			if( extraArgs != null ) args = args.concat( extraArgs );

			if( lastQuery != null  && ArrayTools.equals( lastQuery, args, function(a,b) return a == b ) ) {
				return resolve( lastQueryXml );
			}

			IDE.server.query( args, preText,
				function(r) {
					parser = new DOMParser();
					var xml = parser.parseFromString( r, APPLICATION_XML ).documentElement;
					lastQuery = args;
					lastQueryXml = xml;
					resolve( xml );
				},
				function(e) {
					console.warn( e );
					resolve( null );
					//reject( e );
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

}
