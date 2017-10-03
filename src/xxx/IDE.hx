package xxx;

import Atom.commands;
import Atom.notifications;
import atom.Directory;
import atom.File;
import haxe.Timer.delay;
import js.node.Fs;
import om.haxe.LanguageServer;
import xxx.view.BuildView;
import xxx.view.StatusbarView;

using haxe.io.Path;

@:keep
@:expose
class IDE {

	static inline function __init__() {
		untyped module.exports = xxx.IDE;
	}

	static inline var EVENT_SELECT_HXML = 'hxml_select';
	static inline var EVENT_BUILD = 'build';

	public static var server(default,null) : LanguageServer;
	public static var hxmlFiles(default,null) : Array<String>;
	public static var hxml(default,null) : File;
	public static var statusbar(default,null) : StatusbarView;

	static var disposables : CompositeDisposable;
	static var emitter : Emitter;
	static var projectPaths : Array<String>;

	static function activate( state ) {

		trace( 'Atom-xxx' );

		disposables = new CompositeDisposable();

		emitter = new Emitter();
		//disposables.add( cast emitter );

		statusbar = new StatusbarView();

		projectPaths = Atom.project.getPaths();
		server = new LanguageServer( getConfig( 'haxe_path' ), #if debug true #else false #end );

		//var log = new xxx.view.ServerLogView();
		//log.show();

		//disposables.add( workspace.addOpener( openURI ) );

		delay( function() {

			server.start( function(err) {
				if( err != null ) {
					notifications.addWarning( err );
				} else {
					disposables.add( commands.add( 'atom-workspace', 'xxx:build', function(e) {
						var treeViewFile : String = e.target.getAttribute( 'data-path' );
						if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
							if( hxml != null && treeViewFile != hxml.getPath() ) {
								selectHxml( treeViewFile );
							}
						}
						build();
					}));
					disposables.add( commands.add( 'atom-workspace', 'xxx:goto', function(e) goto() ) );
					/*
					disposables.add( commands.add( 'atom-workspace', 'xxx:build-all', function(e) {
						var selectedHxmlFile = hxml.getPath();
						for( file in hxmlFiles ) {
							selectHxml( file );
							build();
						}
						if( selectedHxmlFile != null ) selectHxml( selectedHxmlFile );
					}));
					*/
				}
			});

		}, getConfig( 'haxe_server_startdelay' ) );

		searchHxmlFiles( function( found:Array<String> ) {

			trace( found.length+' hxml files found' );

			hxmlFiles = found;

			if( state != null && state.hxml != null ) {
				if( hxmlFiles.indexOf( state.hxml ) != -1 ) {
					selectHxml( state.hxml );
				}
			} else {
				selectHxml( found[0] );
			}

			build();

			//Atom.commands.add( 'atom-workspace', 'xxx:goto', goto );

			/*
			disposables.add( commands.add( 'atom-workspace', 'xxx:select-hxml', function(e) {
				trace(e);
				var path : String = e.target.getAttribute( 'data-path' );
				trace(path);
				if( path != null && path.extension() == 'hxml' ) {
					trace(">>");
					new File( path ).exists().then( function(exists:Bool){
						trace(exists);
						if( exists ) {
							trace(path);
							selectHxml( path );
						}
					});
				}
				//Fs.exists( path, function(){} )
				//trace(e.target.getAttribute('data-path'));
				//var view = new xxx.view.SelectHxmlView();
			}));
			*/

			disposables.add( Atom.project.onDidChangePaths( (paths:Array<String>)->{

				var added = new Array<String>();
				//var removed = new Array<String>();
				for( np in paths ) {
					var gotAdded = true;
					for( op in projectPaths ) {
						if( op == np ) {
							gotAdded = false;
							break;
						}
					}
					if( gotAdded ) added.push( np );
				}

				searchHxmlFiles( added, function(found:Array<String>){
					trace( found.length + ' new hxml files found' );
					//hxmlFiles = found;
					hxmlFiles = hxmlFiles.concat( found );
					//trace( hxmlFiles );
					//TODO report event (?)
				} );

				projectPaths = paths;
			}) );

			disposables.add( workspace.observeTextEditors( function(editor:TextEditor){
				var path = editor.getPath();
				if( path != null && haxe.io.Path.extension( path ) == 'hx' ) {

					/*
					function getPosition( pos : Point, callback : Dynamic->Void ) {
						var complete = new AutoComplete( editor );
						complete.position( pos,
							function(xml){
								for( e in xml.elements() ) {
									var str = e.firstChild().nodeValue;
									//var msg = om.haxe.ErrorMessage.parse( str );
									//callback(msg);
									var reg = ~/^\s*(.+):([0-9]+):\s*(characters*|lines)\s([0-9]+)(-([0-9]+))$/i;
									if( reg.match( str ) ) {
										var path = Atom.project.relativizePath( reg.matched(1) )[1];
										var line = Std.parseInt( reg.matched(2) );
										var start = Std.parseInt( reg.matched(4) );
										var end = Std.parseInt( reg.matched(6) );
										callback( { path: path, line: line, start: start, end: end } );
										//statusbar.setMeta( path+':'+line+' '+start+'-'+end );
									}
								}
							},
							function(err){
							}
						);
					}
					*/
					/*
					editor.onDidChangeCursorPosition( function(e){
						getPosition( e.newBufferPosition, function(pos){
							trace(pos);
						} );
					});
					*/
					/*
					editor.onDidChange( function(){
						getPosition( editor.getCursorBufferPosition(), function(pos){
							trace(pos);
						} );
					});
					*/

					//TODO usage completion -> highlight
					//editor.onDidChangeSelectionRange( function(e){
					//	trace( e.selection.getText() );
					//});
				}
			}));
		});
	}

	static function serialize() {
		return {
            hxml: (hxml != null) ? hxml.getPath() : null
        };
    }

	/*
	static function deserialize( state ) {
		return new xxx.view.DebugView( state );
	}
	*/

	static function deactivate() {
		disposables.dispose();
		server.stop();
	}

	/*
	static function openURI( uri : String ) {
		var ext = uri.extension();
		if( ext == 'hxml' ) {
			var debugger = new xxx.view.DebugView( { path: uri } );
            //disposables.add( untyped preview );
            return debugger;
		}
		return null;
	}
	*/

	static function goto() {
		var editor : TextEditor = workspace.getActiveTextEditor();
		if( editor == null )
			return;
		var cursorPos = editor.getCursorBufferPosition();
		var line = editor.getTextInBufferRange(	new Range( new Point(cursorPos.row,0), cursorPos ) );
		//TODO
		/*
		trace(line);
		var REGEX_ENDS_WITH_DOT_IDENTIFIER = ~/\.([a-zA-Z_0-9]*)$/;
		if( !REGEX_ENDS_WITH_DOT_IDENTIFIER.match( line ) ) {
			return;
		}
		var postPrefix = REGEX_ENDS_WITH_DOT_IDENTIFIER.matched(1);
		var pos = cursorPos.copy();
		pos.column -= (postPrefix.length-1);
		var service = new AutoComplete( editor );
		service.position( pos ).then( function(e:om.haxe.Message){
			trace(e);
			workspace.open( e.path, {
				initialLine: e.line,
				initialColumn: e.start,
				activatePane: true,
			} );


		});
		*/
		/*
		var prefix : String;
		var prefixPosition = cursorPos.copy();
		var replacementPrefix : String;
		var EXPR_PREFIX_FIELD = ~/\.([a-zA-Z_][a-zA-Z_0-9]*)$/;
		if( EXPR_PREFIX_FIELD.match( line ) ) {
			prefix = '.';
			replacementPrefix = EXPR_PREFIX_FIELD.matched( 1 );
			prefixPosition.column -= replacementPrefix.length;

			trace(prefix);
		}
		*/
	}

	public static inline function onSelectHxml( h : File->Void )
		return emitter.on( EVENT_SELECT_HXML, h );

	public static inline function onBuild( h : Build->Void )
		return emitter.on( EVENT_BUILD, h );

	public static inline function getConfig<T>( id : String ) : T
		return Atom.config.get( 'xxx.$id' );

	public static function selectHxml( path : String ) {
		if( path == null ) {
            hxml = null;
		} else {
			if( hxml != null && path == hxml.getPath() ) {
                return;
            }
			hxml = new File( path );
		}
		emitter.emit( EVENT_SELECT_HXML, hxml );
		/*
		hxml.read(true).then(function(str){
			trace(om.haxe.Hxml.parseTokens(str));
		});
		*/
	}

	public static function build() : Build {
		if( hxml == null ) {
			notifications.addWarning( 'No hxml file selected' );
			return null;
		}
		var build = new Build( hxml );
		var view = new BuildView( build );
		emitter.emit( EVENT_BUILD, build );
		build.start();
		return build;
	}

	static function searchHxmlFiles( ?paths : Array<String>, maxDepth = 2, callback : Array<String>->Void ) {
		if( paths == null ) paths = Atom.project.getPaths();
		var walk : String->(Array<String>->Void)->?Int->Void;
		walk = function( dir : String, callback : Array<String>->Void, depth = 0 ) {
			var results = new Array<String>();
			Fs.readdir( dir, function(err,list){
				if( err != null ) {
					callback( results ); //TODO silently ignore errors ?
				} else {
					var pending = list.length;
					if( pending == 0 )
						return callback( results );
					for( file in list ) {
						file = js.node.Path.resolve( dir, file );
						Fs.stat( file, function(err,stat){
							if( stat != null && stat.isDirectory() ) {
								if( depth < maxDepth ) {
									walk( file, function(res) {
										results = results.concat( res );
										if( --pending == 0 ) callback( results );
									}, depth+1 );
								} else {
									if( --pending == 0 ) callback( results );
								}
							} else {
								if( file.extension() == 'hxml' && file.withoutDirectory() != 'extraParams.hxml' ) {
									results.push( file );
								}
								if( --pending == 0 ) callback( results );
							}
						});
					}
				}
			});
		}
		var found = new Array<String>();
		var pathsSearched = 0;
		for( path in paths ) {
			walk( path, function(list){
				found = found.concat( list );
				if( ++pathsSearched == paths.length ) {
					callback( found );
				}
			} );
		}
	}

	/*
	static function getTreeViewFile( ?ext : String ) : String {
		//TODO
		var treeView = Atom.packages.getLoadedPackage( 'tree-view' );
		trace( treeView );
		var path = treeView.serialize();
		if( path == null )
			return null;
        var path : String = path.selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }
	*/

	static function consumeStatusBar( bar ) {
		bar.addLeftTile( { item: statusbar.element, priority: -100 } );
	}

	static function provideAutoCompletion() {
		return new AutoCompleteProvider();
	}

	static function provideService() {
		return {
			getHxml: function()
				return IDE.hxml,
			selectHxml: IDE.selectHxml,
			build: IDE.build,
			/*
			usage: function( file : String, index : Int ) {
				//AutoComplete.usage( file, index );
			}
			*/
		};
	}

	/*
	static function provideFileIcons() {
		return {
			iconClassForPath: function(path){
				trace(path);
			},
			onWillDeactivate: function() {

			}
		};
	}
	*/
}
