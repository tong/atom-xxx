package xxx;

import js.Browser.console;
import js.Promise;
import atom.Point;
import atom.Range;
import atom.TextEditor;
import atom.autocomplete.*;
//import om.haxe.SourceCodeUtil.*;

using StringTools;
using haxe.io.Path;

class AutoCompleteProvider {

	static var IMPORT_DECL = ~/import\s+([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)(?:\s+(?:in|as)\s+([a-zA-Z0-9_]+))?/g;
	//static var USING_DECL = ~/(using)\s+([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)(?:\s+(?:in|as)\s+([a-zA-Z0-9_]+))?/g;
	static var ENDS_WITH_DOT_NUMBER = ~/[^a-zA-Z0-9_\]\)]([\.0-9]+)$/;

	@:keep public var selector = '.source.haxe, .source.hx';
	@:keep public var disableForSelector = '.source.haxe .comment, .source.hx .comment';
	//@:keep public var prefixes = ['.','('];
	@:keep public var inclusionPriority = 2;
	@:keep public var excludeLowerPriority = false;
	//@:keep public var filterSuggestions = true;

	//var autoComplete
	//var lastCompletion

	public inline function new() {}

	@:keep public function dispose() {}

	@:keep public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

		return new Promise( function(resolve,reject) {

			return resolve( [] );

			if( IDE.hxml == null ) {
				return resolve( null ); //TODO really
			}

			var editor = req.editor;
			var prefix = req.prefix;
			var replacementPrefix = '';
			var complete = new AutoComplete( editor );
			var position = editor.getCursorBufferPosition();

			/*
			var expr = ~/([A-Za-z_]+[A-Za-z_0-9]*).*$/;
			if( expr.match( req.prefix ) ) {
				replacementPrefix = expr.matched(1);
				prefix = '.';
				//trace( editor.getTextInBufferRange( new Range( new Point(0,0), position ) ) );
				position.column -= replacementPrefix.length;
			}
			*/

			switch prefix {

			case '.':

				/*
				if( ENDS_WITH_DOT_NUMBER.match( line ) ) {
					return resolve( null );
				}
				*/

				complete.fieldAccess( position, function(xml:Xml) {

					if( xml == null )
						return resolve( null );

					var line = req.editor.lineTextForBufferRow( req.bufferPosition.row );

					if( IMPORT_DECL.match( line ) ) { ///// Type path completion

						var pkg = IMPORT_DECL.matched(1);
						var packageSuggestions = new Array<Suggestion>();
						var typeSuggestions = new Array<Suggestion>();
						var varSuggestions = new Array<Suggestion>();
						var methodSuggestions = new Array<Suggestion>();

						for( e in xml.elements() ) {
							var name = e.get( 'n' );
							if( replacementPrefix.length > 0 && !name.startsWith( replacementPrefix ) ) {
								trace(name,replacementPrefix);
								continue;
							}
							var type : String = null;
							var doc : String = null;
							for( e in e.elements() ) {
								var fc = e.firstChild();
								if( fc == null )
								continue;
								switch e.nodeName {
								case 't': type = fc.nodeValue;
								case 'd': doc = fc.nodeValue;
								}
							}
							var sug : Suggestion = {
								text: name,
								description: doc
							};
							switch e.get( 'k' ) {
							case 'var':
								sug.type = 'variable';
								sug.displayText = name+' : '+type;
								varSuggestions.push( sug );
							case 'method':
								sug.type = 'method';
								sug.displayText = name;
								//sug.replacementPrefix = name;
								var snippet = name;
								var types = type.split( ' -> ' );
								var ret = types.pop();
								if( types[0] == 'Void' ) {
									snippet += '()$$0';
									sug.displayText += '() : '+ret;
								} else {
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
									sug.displayText += '( '+types.join( ', ' )+' ) : '+ret;
								}
								varSuggestions.push( sug );
							case 'type':
								sug.type = 'type';
								//sug.displayText = pkg +'.'+ name;
								typeSuggestions.push( sug );
							case 'package':
								sug.iconHTML = '<i class="icon-package"></i>';
								//sug.displayText = pkg +'.'+ sug.text;
								packageSuggestions.push( sug );
							}
						}

						//var suggestions = new Array<Suggestion>();
						//if( )

						return resolve(
							packageSuggestions.concat(
							typeSuggestions.concat(
							varSuggestions.concat(
							methodSuggestions
						) ) ) );
					}


					var suggestions = new Array<Suggestion>();
					for( e in xml.elements() ) {
						var name = e.get( 'n' );
						if( replacementPrefix != null && !name.startsWith( replacementPrefix ) )
								continue;
						var isVar = e.get( 'k' ) == 'var';
						var type : String = null;
						var doc : String = null;
						var ret : String = null;
						for( e in e.elements() ) {
							var fc = e.firstChild();
							if( fc == null )
								continue;
							switch e.nodeName {
							case 't': type = fc.nodeValue;
							case 'd': doc = fc.nodeValue;
							}
						}
						//if( doc != null ) doc = Markdown.markdownToHtml( doc );
						var snippet = name;
						var displayName = name;
						if( isVar ) {
							displayName += ' : '+type;
						} else {
							var types = type.split( ' -> ' );
							ret = types.pop();
							if( types[0] == 'Void' ) {
								snippet += '()$$0';
								displayName += '()';
							} else {
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
							}
						}
						suggestions.push( {
							type: isVar ? 'variable' : 'method',
							//text : name,
							snippet : snippet,
							displayText: displayName,
							//replacementPrefix: replacementPrefix,
							//leftLabel: ret,
							//rightLabel: ret,
							description: doc,
							//descriptionMoreURL: 'http://disktree.net',
							//className: 'haxe-autocomplete-suggestion-type-hint'
						} );
					}
					return resolve( suggestions );

				});

				/*
				complete.fieldAccess( position, function(xml:Xml) {

					if( xml == null )
						return resolve([]);

					if( IMPORT_DECL.match( line ) ) {

						///// Type path completion

						var pkg = IMPORT_DECL.matched(1);
						var packageSuggestions = new Array<Suggestion>();
						var typeSuggestions = new Array<Suggestion>();
						var varSuggestions = new Array<Suggestion>();
						var methodSuggestions = new Array<Suggestion>();

						for( e in xml.elements() ) {
							var name = e.get( 'n' );
							var type : String = null;
							var doc : String = null;
							for( e in e.elements() ) {
								var fc = e.firstChild();
								if( fc == null )
									continue;
								switch e.nodeName {
								case 't': type = fc.nodeValue;
								case 'd': doc = fc.nodeValue;
								}
							}
							var sug : Suggestion = {
								text: name,
								description: doc
							};
							switch e.get( 'k' ) {
							case 'var':
								sug.type = 'variable';
								sug.displayText = name+' : '+type;
								varSuggestions.push( sug );
							case 'method':
								sug.type = 'method';
								sug.displayText = name;
								//sug.replacementPrefix = name;
								var snippet = name;
								var types = type.split( ' -> ' );
								var ret = types.pop();
								if( types[0] == 'Void' ) {
									snippet += '()$$0';
									sug.displayText += '() : '+ret;
								} else {
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
									sug.displayText += '( '+types.join( ', ' )+' ) : '+ret;
								}
								varSuggestions.push( sug );
							case 'type':
								sug.type = 'type';
								sug.displayText = pkg +'.'+ name;
								methodSuggestions.push( sug );
							case 'package':
								sug.iconHTML = '<i class="icon-package"></i>';
								sug.displayText = pkg +'.'+ sug.text;
								packageSuggestions.push( sug );
							}
						}

						return resolve(
							packageSuggestions.concat(
							typeSuggestions.concat(
							varSuggestions.concat(
							methodSuggestions
						) ) ) );
					}


					var suggestions = new Array<Suggestion>();
					for( e in xml.elements() ) {
						var name = e.get( 'n' );
						if( replacementPrefix != null ) {
							if( !name.startsWith( replacementPrefix ) )
								continue;
						}
						var isVar = e.get( 'k' ) == 'var';
						var type : String = null;
						var doc : String = null;
						var ret : String = null;
						for( e in e.elements() ) {
							var fc = e.firstChild();
							if( fc == null )
								continue;
							switch e.nodeName {
							case 't': type = fc.nodeValue;
							case 'd': doc = fc.nodeValue;
							}
						}
						//if( doc != null ) doc = Markdown.markdownToHtml( doc );
						var snippet = name;
						var displayName = name;
						if( isVar ) {
							displayName += ' : '+type;
						} else {
							var types = type.split( ' -> ' );
							ret = types.pop();
							if( types[0] == 'Void' ) {
								snippet += '()$$0';
								displayName += '()';
							} else {
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
							}
						}
						suggestions.push( {
							type: isVar ? 'variable' : 'method',
							//text : name,
							snippet : snippet,
							displayText: displayName,
							//replacementPrefix: replacementPrefix,
							//leftLabel: ret,
							//rightLabel: ret,
							description: doc,
							//descriptionMoreURL: 'http://disktree.net',
							//className: 'haxe-autocomplete-suggestion-type-hint'
						} );
					}
					return resolve( suggestions );
				});
				*/

			case '(':

				///// Call argument completion
				// TODO doesn't show up in editor (?)

				complete.callArgument( function(xml) {
					if( xml == null )
						return resolve( null );
					var str = xml.firstChild().nodeValue.trim();
					var types : Array<String> = str.split( '->' );
					var ret = types.pop();
					var suggestion : Suggestion = {
						type: 'type',
						snippet: ''
					};
					var args = new Array<String>();
					for( i in 0...types.length ) {
						var type = types[i].trim();
						var parts = type.split( ' : ' );
						var tagA = '';
						var tagB = '';
						/*
						if( parts[0].startsWith( '?' ) ) {
							tagA = '[';
							tagB = ']';
						}
						*/
						args.push( "${"+(i+1)+":"+tagA+parts[0]+":"+parts[1]+tagB+"}" );
					}
					suggestion.snippet = " "+args.join( ", " )+" $0";
					/*
					var displayText = ''+str;
					var snippet = ''+str+"$0";
					suggestions.push({
						type: 'variable',
						snippet : snippet,
						displayText: displayText
					});
					return resolve( suggestions );
					*/
					return resolve( [suggestion] );
				});

			}

		} );
	}

	/*
    @:keep public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

        return new Promise( function(resolve,reject) {

			//TODO really
			if( IDE.hxml == null ) {
				return resolve([]);
			}

			var line = req.editor.lineTextForBufferRow( req.bufferPosition.row );
			var prefix = req.prefix;
			var pos = req.editor.getCursorBufferPosition();


			if( prefix != '.' ) {
				trace(pos);
				//prefix = line.charAt( line.length - prefix.length - 1 );
			}

			//var c = line.charAt( line.length - prefix.length - 1 );
			//trace(c,c=='.');
			//trace( req.prefix );
			//trace( getPrefix( req.prefix ) );

			//trace(req.prefix);
			//trace(prefix);
			//return resolve( null );

			var autoComplete = new AutoComplete( req.editor );

			switch prefix {
			//switch c {

			case '.':

				if( ENDS_WITH_DOT_NUMBER.match( line ) ) {
					return resolve([]);
				}

				//autoComplete.position( function(xml:Xml) { trace(xml); });

				autoComplete.fieldAccess( pos, function(xml:Xml) {

					if( xml == null )
						return resolve([]);

					var line = req.editor.lineTextForBufferRow( req.bufferPosition.row );

					if( IMPORT_DECL.match( line ) ) {

						///// Type path completion

						var pkg = IMPORT_DECL.matched(1);
						var packageSuggestions = new Array<Suggestion>();
						var typeSuggestions = new Array<Suggestion>();
						var varSuggestions = new Array<Suggestion>();
						var methodSuggestions = new Array<Suggestion>();

						for( e in xml.elements() ) {
							var name = e.get( 'n' );
							var type : String = null;
							var doc : String = null;
							for( e in e.elements() ) {
								var fc = e.firstChild();
								if( fc == null )
									continue;
								switch e.nodeName {
								case 't': type = fc.nodeValue;
								case 'd': doc = fc.nodeValue;
								}
							}
							var sug : Suggestion = {
								text: name,
								description: doc
							};
							switch e.get( 'k' ) {
							case 'var':
								sug.type = 'variable';
								sug.displayText = name+' : '+type;
								varSuggestions.push( sug );
							case 'method':
								sug.type = 'method';
								sug.displayText = name;
								//sug.replacementPrefix = name;
								var snippet = name;
								var types = type.split( ' -> ' );
								var ret = types.pop();
								if( types[0] == 'Void' ) {
									snippet += '()$$0';
									sug.displayText += '() : '+ret;
								} else {
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
									sug.displayText += '( '+types.join( ', ' )+' ) : '+ret;
								}
								varSuggestions.push( sug );
							case 'type':
								sug.type = 'type';
								sug.displayText = pkg +'.'+ name;
								methodSuggestions.push( sug );
							case 'package':
								sug.iconHTML = '<i class="icon-package"></i>';
								sug.displayText = pkg +'.'+ sug.text;
								packageSuggestions.push( sug );
							}
						}

						return resolve(
							packageSuggestions.concat(
							typeSuggestions.concat(
							varSuggestions.concat(
							methodSuggestions
						) ) ) );

					} else {

						///// Field access completion

						var suggestions = new Array<Suggestion>();
						for( e in xml.elements() ) {
							var name = e.get( 'n' );
							var isVar = e.get( 'k' ) == 'var';
							var type : String = null;
							var doc : String = null;
							var ret : String = null;
							for( e in e.elements() ) {
								var fc = e.firstChild();
								if( fc == null )
									continue;
								switch e.nodeName {
								case 't': type = fc.nodeValue;
								case 'd': doc = fc.nodeValue;
								}
							}
							//if( doc != null ) doc = Markdown.markdownToHtml( doc );
							var snippet = name;
							var displayName = name;
							if( isVar ) {
								displayName += ' : '+type;
							} else {
								var types = type.split( ' -> ' );
								ret = types.pop();
								if( types[0] == 'Void' ) {
									snippet += '()$$0';
									displayName += '()';
								} else {
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
								}
							}
							suggestions.push( {
								type: isVar ? 'variable' : 'method',
								//text : name,
								snippet : snippet,
								displayText: displayName,
								//replacementPrefix: prefix,
								//leftLabel: ret,
								//rightLabel: ret,
								description: doc,
								//descriptionMoreURL: 'http://disktree.net',
								//className: 'haxe-autocomplete-suggestion-type-hint'
							} );
						}
						return resolve( suggestions );
					}

				});

			case '(':

				///// Call argument completion
				// TODO doesn't show up in editor (?)

				autoComplete.callArgument( function(xml) {
					if( xml == null )
						return resolve( null );
					var str = xml.firstChild().nodeValue.trim();
					var types = str.split( '->' );
					var retType = types.pop();
					var displayText = ''+str;
					var snippet = ''+str+"$0";
					trace({
						type: 'variable',
						snippet : snippet,
						displayText: displayText
					});
					return resolve( [
						{
							type: 'variable',
							snippet : snippet,
							displayText: displayText
						}
					] );
				});

            default:
				//trace("?? " );
				return resolve( [] );

			}
        });
	}
	*/

	/*
	@:keep
    public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
        //trace(suggestion);
        //TODO
    }
	*/

}
