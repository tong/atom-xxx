package xxx;

import js.node.Fs;
import Atom.commands;
import Atom.notifications;
import atom.CompositeDisposable;
import atom.Directory;
import atom.Disposable;
import atom.Emitter;
import atom.File;
import haxe.Timer.delay;
import xxx.view.BuildView;
import xxx.view.StatusbarView;
import om.haxe.LanguageServer;

using StringTools;
using haxe.io.Path;

@:keep
@:expose
class IDE {

	static inline function __init__() untyped module.exports = xxx.IDE;

	static inline var EVENT_SELECT_HXML = 'hxml_select';
	static inline var EVENT_BUILD = 'build';

	public static var server(default,null) : LanguageServer;
	public static var hxmlFiles(default,null) : Array<String>;
	public static var hxml(default,null) : File;

	static var disposables : CompositeDisposable;
	static var emitter : Emitter;
	static var statusbar : StatusbarView;
	static var projectPaths : Array<String>;

	static function activate( state ) {

		trace( 'Atom-xxx' );

		disposables = new CompositeDisposable();
		emitter = new Emitter();
		//disposables.add( emitter = new Emitter() );
		statusbar = new StatusbarView();
		server = new LanguageServer( getConfig( 'haxe_path' ) );
		projectPaths = Atom.project.getPaths();

		delay( function() {

			server.start( function(err) {

				if( err != null ) {
					notifications.addWarning( err );
				} else {

					disposables.add( commands.add( 'atom-workspace', 'xxx:build', function(e) {

						var treeViewFile = getTreeViewFile();
						if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
							if( hxml != null && treeViewFile != hxml.getPath() ) {
								selectHxml( treeViewFile );
							}
						}

						build();
					}));

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

			disposables.add( Atom.workspace.observeTextEditors( function(editor){
				var path = editor.getPath();
				if( path != null && haxe.io.Path.extension(path) == 'hx' ) {
					editor.onDidChange( function(e){

						/*
						var autoComplete = new AutoComplete( editor );

						autoComplete.topLevel( function(xml:Xml) {
							if( xml != null ) {
								trace(xml);
							}
						});
						*/


						/*

						autoComplete.fieldAccess( function(xml:Xml) {
							if( xml != null ) {
								trace(xml);
							}
						});
						*/

						/*
						autoComplete.usage( function(xml:Xml) {
							if( xml != null ) {
								trace(xml);
							}
						});
						*/

						/*
						autoComplete.position( function(xml:Xml) {
							if( xml != null ) {
								var str = xml.firstElement().firstChild().nodeValue;
								var reg = ~/^\s*(.+):([0-9]+):\s*(characters*|lines)\s([0-9]+)(-([0-9]+))$/i;
								if( reg.match( str ) ) {
									var path = reg.matched(1);
									var line = Std.parseInt( reg.matched(2) );
									var start = Std.parseInt( reg.matched(4) );
									var end = Std.parseInt( reg.matched(6) );
									statusbar.setMeta( path+':'+line );
									//trace( path );
									//trace( line );
									//trace( start+"-"+end );
								}
							}
						});
						*/

					});

					/*
					editor.observeSelections( function(selection) {
						trace(selection);
					});
					*/
				}
			}) );
		});
	}

	static function serialize() {
		return {
            hxml: (hxml != null) ? hxml.getPath() : null
        };
    }

	static function deactivate() {
		disposables.dispose();
		server.stop();
	}

	public static inline function onSelectHxml( h : File->Void )
		return emitter.on( EVENT_SELECT_HXML, h );

	public static inline function onBuild( h : Build->Void )
		return emitter.on( EVENT_BUILD, h );

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
		var view = new xxx.view.BuildView( build );
		emitter.emit( EVENT_BUILD, build );
		build.start();
		return build;
	}

	static function searchHxmlFiles( ?paths : Array<String>, maxDepth = 3, callback : Array<String>->Void ) {

		if( paths == null ) paths = Atom.project.getPaths();

		var walk : String->(Array<String>->Void)->?Int->Void;
		walk = function( dir : String, callback : Array<String>->Void, depth = 0 ) {
			var results = new Array<String>();
			Fs.readdir( dir, function(err,list){
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

	static function getTreeViewFile( ?ext : String ) : String {
		//TODO
		var treeView = Atom.packages.getLoadedPackage( 'tree-view' );
		var path = treeView.serialize();
		if( path == null )
			return null;
        var path : String = path.selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }

	static inline function getConfig<T>( id : String ) : T {
		return Atom.config.get( 'xxx.$id' );
	}

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
