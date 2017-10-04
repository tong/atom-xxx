package xxx;

import atom.autocomplete.*;

typedef Item = {
	//var type : ItemType; //list|type
	var n : String;
	var k : String;
	@:optional var t : String;
	@:optional var d : String;
	@:optional var p : String;
	@:optional var c : String;
}

class CompilerService {

	public var editor(default,null) : TextEditor;

	public function new( editor : TextEditor ) {
		this.editor = editor;
	}

	public inline function callArgument( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs ).then( function(items){
			trace(items);
			return cast items;
		});
	}

	public inline function fieldAccess( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs ).then( function(items){
			//return Promise.resolve( items );
			return cast items;
		});
	}

	public inline function topLevel( pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'toplevel', extraArgs ).then( function(items){
			return cast items;
		});
	}

	/*
	public inline function callArgument( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs );
	}

	public inline function fieldAccess( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, extraArgs ).then( function(items){
			return Promise.resolve( items );
		});
	}

	public inline function position( ?pos : Point, ?extraArgs : Array<String> ) : Promise<om.haxe.Message> {
		return query( pos, 'position', extraArgs ).then( function(items) {
			var str = xml.elementsNamed( 'pos' ).next().firstChild().nodeValue;
			var msg = om.haxe.Message.parse( str );
			return Promise.resolve( msg );
		});
	}

	public inline function topLevel( pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'toplevel', extraArgs );
	}

	public inline function usage( ?pos : Point, ?extraArgs : Array<String> ) : Promise<Array<Item>> {
		return query( pos, 'usage', extraArgs );
	}
	*/

	public function query( ?pos : Point, ?mode : String, ?extraArgs : Array<String> ) : Promise<Array<Item>> {

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

					//var ts = Time.stamp();
					var xml = Xml.parse( r ).firstElement();
					var items = new Array<Item>();
					switch xml.nodeName {
					case 'list':
						//trace(Time.stamp()-ts);
						for( e in xml.elements() ) {
							var fc = e.firstChild();
							var item : Item = {
								n: e.get('n'),
								k: e.get('k'),
								p: e.get('p'),
								c: (fc != null &&
									(fc.nodeType == Document || fc.nodeType != Element )) ? fc.nodeValue : null
								};
								for( e in e.elements() ) {
									var fc = e.firstChild();
									switch e.nodeName {
										case 'd': item.d = (fc != null) ? fc.nodeValue : null;
										case 't': item.t = (fc != null) ? fc.nodeValue : null;
									}
								}
								items.push( item );
							}
					case 'type':
						items.push({
							d: xml.get( 'd' ),
							t: xml.firstChild().nodeValue.trim(),
							n: null,
							k: null
						});
					}

					/*
					var ts = Time.stamp();
					var parser = new js.html.DOMParser();
					var xml = parser.parseFromString( r, APPLICATION_XML ).documentElement;
					trace( xml );
					trace( xml.children );
					for( e in xml.children ) trace( e.nodeName );
					trace(Time.stamp()-ts);
					*/

					resolve( items );
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
