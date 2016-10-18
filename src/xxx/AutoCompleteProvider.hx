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

class AutoCompleteProvider {

	@:keep public var selector = '.source.haxe, .source.hx';
	@:keep public var disableForSelector = '.source.haxe .comment, .source.hx .comment';
	@:keep public var prefixes = ['.','('];
	@:keep public var inclusionPriority = 2;
	@:keep public var excludeLowerPriority = false;

	public inline function new() {}

	@:keep public function dispose() {}

    @:keep public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

        return new Promise( function(resolve,reject) {

			//TODO really
			if( IDE.hxml == null ) {
				return resolve( null );
			}

			var autoComplete = new AutoComplete( req.editor );

			switch req.prefix {

			case '.':

				if( ENDS_WITH_DOT_NUMBER.match( line ) ) {
					return resolve( null );
				}

				/*
				autoComplete.position( function(xml:Xml) {
					trace(xml);
				});
				*/

				autoComplete.fieldAccess( function(xml:Xml) {

					if( xml == null )
						return resolve( null );

					var line = req.editor.lineTextForBufferRow( req.bufferPosition.row );

					if( IMPORT_DECL.match( line ) ) {

						///// Type path completion

						var pkg = IMPORT_DECL.matched(1);

						var suggestions = new Array<Suggestion>();

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
							case 'method':
								sug.type = 'method';
								sug.displayText = name;
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
							case 'type':
								sug.type = 'type';
								sug.displayText = pkg +'.'+ name;
							case 'package':
								sug.iconHTML = '<i class="icon-package"></i>';
								sug.displayText = pkg +'.'+ sug.text;

							}

							suggestions.push( sug );
						}

						return resolve( suggestions );

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
				return resolve( null );

			}

        });
	}

	/*
	@:keep
    public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
        //trace(suggestion);
        //TODO
    }
	*/

}
