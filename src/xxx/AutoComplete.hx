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

	@:keep public var selector = '.source.haxe, .source.hx';
	@:keep public var disableForSelector = '.source.haxe .comment, .source.hx .comment';
	@:keep public var prefixes = ['.','('];
	@:keep public var inclusionPriority = 2;
	@:keep public var excludeLowerPriority = false;

	public inline function new() {}

	@:keep public function dispose() {}

    @:keep public function getSuggestions( req : Request ) {

        return new Promise( function(resolve,reject) {

			//TODO really
			if( IDE.hxml == null ) {
				return resolve( null );
			}

            var editor = req.editor;
			var bufpos = req.bufferPosition;
			var path = editor.getPath();
            var content = editor.getText();
            var pretext = editor.getTextInBufferRange( new Range( new Point(0,0), new Point(bufpos.row,bufpos.column) ) );
			var line = editor.lineTextForBufferRow( bufpos.row );
            var index = pretext.length;

			//trace(":::: "+path );

            //HACK
			/*
			var rel = Atom.project.relativizePath( path );
			var _cwd = rel[0];
			var _path = rel[1];
			var _pathParts = _path.split( '/' );
			/*
			//if( _pathParts[0] == 'src' ) {}
			*/
			//console.debug(_cwd,_path);

			var extraArgs = new Array<String>();

			//TODO really
			extraArgs.push( IDE.hxml.getPath() );


            switch req.prefix {

            case '.':

				if( ENDS_WITH_DOT_NUMBER.match( line ) ) {
					return resolve( null );
				}

				if( IMPORT_DECL.match( line ) ) {

					///// Type path completion

					var pkg = IMPORT_DECL.matched(1);

					query( path, index, content, extraArgs,

						function(xml:Xml){

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
						},
						function(err){
							trace(err);
							return resolve( null );
						}
					);

				} else {

					///// Field completion

					query( path, index, content, extraArgs,
						function(xml:Xml){
							return resolve( createFieldSuggestions( xml ) );
						},
						function(err){
							trace(err);
						}
					);

				}

				///// Position completion

				/*
				query( path, index, content, 'position',
					function(xml){
						trace(xml);
					}
				);
				*/

            case '(':

				// TODO doesn't show up in editor (?)
				///// Call argument completion

				query( path, index, content,
					function(xml:Xml){
						//trace(xml);
						var suggestions = new Array<Suggestion>();
						suggestions.push({
							type: 'method',
							text: 'RRRRRRRRRRRRRRR',
							displayText: 'RRRRRRRRRRRRRRR',
							snippet: 'dddddddddddd$0'
						});
						return resolve( suggestions );
					},
					function(err){
						trace(err);
					}
				);

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

	function query( file : String, index = 0, content : String, ?mode : String, ?extraArgs : Array<String>, onResult : Xml->Void, onError : String->Void ) {

		var haxePos = '$file@$index';
		if( mode != null ) haxePos += '@'+mode;

		var args = [ '--display', haxePos ];
		if( extraArgs != null ) {
			args = extraArgs.concat( args );
		}

		IDE.server.query( args, content,
			function(msg){
			},
			function(result){
				var xml = Xml.parse( result ).firstElement();
				onResult( xml );
			},
			function(e){
				onError(e);
			}
		);

		/*
		IDE.lang.query( args, content,
			function(result){
				var xml = Xml.parse( result ).firstElement();
				onResult( xml );
			},
			function(e){
				onError(e);
			}
		);
		*/
	}

    static function createFieldSuggestions( xml : Xml ) : Array<Suggestion> {

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

        return suggestions;
    }

}
