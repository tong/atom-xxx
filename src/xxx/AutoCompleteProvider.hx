package xxx;

import atom.autocomplete.*;

using om.util.StringUtil;

class AutoCompleteProvider {

	static var EXPR_TYPEPATH = ~/(import|using)\s+([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)(?:\s+(?:in|as)\s+([a-zA-Z0-9_]+))?/g;
	static var EXPR_ALPHANUMERIC_END = ~/[^a-zA-Z0-9_\]\)]([\.0-9]+)$/;

	static var EXPR_PREFIX_FIELD = ~/\.([a-zA-Z_][a-zA-Z_0-9]*)$/;
	static var EXPR_PREFIX_CALL = ~/\(( *)$/;

	//http://api.haxe.org/haxe/Unserializer.html#new

	@:keep public var selector = '.source.haxe, .source.hx';
	@:keep public var disableForSelector = '.source.haxe .comment, .source.hx .comment';
	@:keep public var suggestionPriority = 2;
	//@:keep public var inclusionPriority = 2;
	//@:keep public var excludeLowerPriority = true;
	//@:keep public var filterSuggestions = true;

	public var enabled : Bool;

	public function new( enabled = true ) {
		var config = IDE.getConfig( 'autocomplete' );
		enabled = config.enabled;
		Atom.config.observe( 'xxx.autocomplete', function(n){
			enabled = n.enabled;
		} );
	}

	@:keep public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

		return new Promise( function(resolve,reject) {

			if( !enabled || IDE.hxml == null )
				return resolve( [] );

			var editor = req.editor;
			var position = editor.getCursorBufferPosition();
			//var line = editor.lineTextForBufferRow( req.bufferPosition.row );
			var prefixPosition = req.bufferPosition;
			var prefix = req.prefix;
			var replacementPrefix = '';
			var line = editor.getTextInBufferRange(	new Range( new Point(prefixPosition.row,0), prefixPosition ) );

			if( EXPR_PREFIX_FIELD.match( line ) ) {
				prefix = '.';
				replacementPrefix = EXPR_PREFIX_FIELD.matched( 1 );
				prefixPosition.column -= replacementPrefix.length;
			} else if( EXPR_PREFIX_CALL.match( line ) ) {
				prefix = '(';
				replacementPrefix = EXPR_PREFIX_CALL.matched( 1 );
				prefixPosition.column -= replacementPrefix.length;
			}

			//trace( 'PREFIX = ['+prefix+']' );

			var complete = new AutoComplete( editor );

			switch prefix {

			case '.':

				if( EXPR_ALPHANUMERIC_END.match( line ) ) {
					return resolve( [] );
				}

				if( EXPR_TYPEPATH.match( line ) ) {
					var pack = EXPR_TYPEPATH.matched( 2 );
					//var isType = pack.split( '.' ).pop().charAt(0).isUpperCase(); //hmmm
					//trace("TYPEPATH", pack);
					complete.fieldAccess( prefixPosition,
						function(xml) {
							var typeSuggestions = new Array<Suggestion>();
							var packSuggestions = new Array<Suggestion>();
							var varSuggestions = new Array<Suggestion>();
							var methodSuggestions = new Array<Suggestion>();
							for( e in xml.elements() ) {
								var name = e.get( 'n' );
								if( replacementPrefix != null && !name.startsWith( replacementPrefix ) )
									continue;
								var k = e.get( 'k' );
								var doc = e.elementsNamed( 'd' ).next().firstChild().nodeValue;
								switch k {
								case 'method':
									//TODO parse args
									//value : Dynamic -> ?replacer : Null<Dynamic -> Dynamic -> Dynamic> -> ?space : Null<String> -> String
									var text = name;
									var displayText = name;
									//var snippet = name;
									var argsTypesStr = e.elementsNamed( 't' ).next().firstChild().nodeValue.htmlUnescape();
									displayText += '( $argsTypesStr )';
									//snippet = "( "+argsTypesStr+" )$0";
									methodSuggestions.push( {
										type: 'method',
										text: text,
								        //snippet : snippet,
								        displayText: displayText,
										description: doc,
										leftLabel: 'static'
									} );
								case 'package':
									packSuggestions.push( { type: k, text: name, description: doc } );
								case 'type':
									var lastPackPart = pack.split( '.' ).pop();
									var isTypeCompletion = lastPackPart.charAt(0).isUpperCase(); //hmmm
									if( !isTypeCompletion ) {
										typeSuggestions.push( { type: k, text: name, description: doc } );
									}
								case 'var':
									var type = e.elementsNamed( 't' ).next().firstChild().nodeValue.htmlUnescape();
									trace( type );
									varSuggestions.push( {
										type: k,
										text: name,
										leftLabel: 'static',
										rightLabel: type,
										description: doc
									} );
								}
							}
							return resolve(
								typeSuggestions
								.concat( packSuggestions )
								.concat( varSuggestions )
								.concat( methodSuggestions )
							);
						}
					);

				} else {

					///// Field access completion
					complete.fieldAccess( prefixPosition,
						function(xml) {
							var suggestions = new Array<Suggestion>();
							for( e in xml.elements() ) {
								var name = e.get( 'n' );
								if( replacementPrefix != null && !name.startsWith( replacementPrefix ) )
									continue;
								var type = e.get( 'k' );
								var doc : String = null;
								var doc = e.elementsNamed( 'd' ).next().firstChild().nodeValue;
								switch type {
								case 'package':
									suggestions.push( { type: 'package', text: name, description: doc } );
								case 'type':
									suggestions.push( { type: 'type', text: name, description: doc } );
								case 'method':
									var sug = getMethodSuggestion( name, e.elementsNamed( 't' ).next().firstChild().nodeValue );
									sug.description = doc;
									suggestions.push( sug );
								case 'var':
									//trace("VARVARVARVARVARVARVARVARVARVARVAR "+name );
									//if( replacementPrefix.length > 0 ) {
									//	if( )
									//}
									type = e.elementsNamed( 't' ).next().firstChild().nodeValue;
									suggestions.push( {
										type: 'variable',
										text: name,
										displayText: name,
										rightLabel: type,
										description: doc,
										//descriptionMoreURL: 'http://api.haxe.org/String.html#length'
									} );
								}
							}
							return resolve( suggestions );
						},
						function(err) {
							//TODO
							//return resolve( [{type: 'error', text: 'RRRR', displayText: err }] );
						}
					);
				}

			case '(':
				///// Call argument completion
				complete.callArgument( prefixPosition,
					function(xml) {
						var str = xml.firstChild().nodeValue.trim();
						var types : Array<String> = str.split( '->' );
						var ret = types.pop();
						var suggestion : Suggestion = { type: 'type', snippet: '' };
						var args = new Array<String>();
						for( i in 0...types.length ) {
							var type = types[i].trim();
							var parts = type.split( ' : ' );
							var tagA = '';
							var tagB = '';
							args.push( "${"+(i+1)+":"+tagA+parts[0]+":"+parts[1]+tagB+"}" );
						}
						suggestion.snippet = " "+args.join( ", " )+" )$0";
						return resolve( [suggestion] );
					},
					function(err) {
						//TODO
						//return resolve( [{type: 'error', text: 'RRRR', displayText: err }] );
					}
				);

			default:
				///// Top level completion
				complete.topLevel( prefixPosition,
					function(xml) {
						if( xml == null )
							return resolve( [] );
						var suggestions = new Array<Suggestion>();
						for( e in xml.elements() ) {
							var name = e.firstChild().nodeValue;
							if( prefix.length > 0 && !name.startsWith( prefix ) )
								continue;
							var k = e.get( 'k' );
							switch k {
							case 'local':
								suggestions.push( { type: k, text: name } );
							case 'static':
								suggestions.push( { type: 'method', text: name } );
							case 'literal':
								suggestions.push( { type: 'keyword', text: name } );
							case 'package':
								suggestions.push( { type: k, text: name } );
							case 'type':
								suggestions.push( { type: k, text: name } );
							}
						}
						return resolve( suggestions );
					},
					function(err) {
						//TODO
						//return resolve( [{type: 'error', text: err }] );
					}
				);
			}
		} );
	}

	@:keep public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
		//trace("TODO onDidInsertSuggestion");
	}

	@:keep public function dispose() {
		//trace( "TODO DISPOSE" );
	}

	//TODO args parsing
	function getMethodSuggestion( name : String, type : String ) : Suggestion {
		var types = type.split( ' -> ' );
		var snippet = name;
		var displayName = name;
		var ret = types.pop();
		if( types[0] == 'Void' ) {
			snippet += "()$0";
			displayName += '()';
		} else {
			var args = new Array<String>();
			for( i in 0...types.length ) {
				var type = types[i].trim();
				var parts = type.split( ' : ' );
				var tagA = '';
				var tagB = '';
				args.push( "${"+(i+1)+":"+tagA+parts[0]+":"+parts[1]+tagB+"}" );
			}
			snippet = "( "+args.join( ", " )+" )$0";
			/*
			snippet += '( ';
			var i = 1;
			var argSnippets = new Array<String>();
			for( type in types ) {
				var parts = type.split( ' : ' );
				var name = parts[0];
				argSnippets.push( '$${$i:$name}' );
				i++;
			}
			snippet += argSnippets.join( ', ' )+' )$$0';
			displayName += '( '+types.join( ', ' )+' ) : '+ret;
			*/
		}
		return {
			type: 'method',
			snippet : snippet,
			displayText: displayName
		};
	}

}
