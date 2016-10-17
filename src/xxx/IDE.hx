package xxx;

import js.node.Fs;
import atom.CompositeDisposable;
import atom.Directory;
import atom.Disposable;
import atom.Emitter;
import atom.File;
import haxe.Timer.delay;
import Atom.commands;
import Atom.notifications;

using StringTools;
using haxe.io.Path;

private typedef IDEState = {
	var hxml : String;
}

@:keep
@:expose
class IDE {

	static inline function __init__() untyped module.exports = xxx.IDE;

	public static var server(default,null) : HaxeServer;
	public static var hxmlFiles(default,null) : Array<String>;
	public static var hxml(default,null) : File;

	static var disposables : CompositeDisposable;
	static var emitter : Emitter;

	static function activate( state : IDEState ) {

		trace( 'Atom-xxx' );

		disposables = new CompositeDisposable();
		emitter = new Emitter();

		server = new HaxeServer();

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

			server.start();

			disposables.add( commands.add( 'atom-workspace', 'xxx:build', function(e) {

				var treeViewFile = getTreeViewFile();
				if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
					if( hxml != null && treeViewFile != hxml.getPath() ) {
						selectHxml( treeViewFile );
					}
				}

				build();

			}) );
		});

		/*
		disposables.add( commands.add( 'atom-workspace', 'xxx:toggle-server-log', function(e) {
			if( serverLog == null ) serverLog = new ServerLogView();
			serverLog.toggle();
		}) );
		*/
	}

	static function serialize() : IDEState {
		return {
            hxml: (hxml != null) ? hxml.getPath() : null
        };
    }

	static function deactivate() {
		disposables.dispose();
		server.stop();
		//if( serverLog != null ) serverLog.dispose();
	}

	public static inline function onSelectHxml( h : File->Void )
		return emitter.on( 'select_hxml', h );

	public static inline function onBuild( h : Build->Void )
		return emitter.on( 'build', h );

	public static function selectHxml( path : String ) {
		if( path == null ) {
            hxml = null;
		} else {
			if( hxml != null && path == hxml.getPath() ) {
                return;
            }
			hxml = new File( path );
		}
		emitter.emit( 'select_hxml', hxml );
	}

	public static function build() {
		var build = new Build( hxml );
		//build.onError();
		var view = new xxx.view.BuildView( build );
		//buildView.show();
		/*
		build.onError( function(str){
			var err = om.haxe.ErrorMessage.parse(str);
			trace(str);
		});
		*/
		emitter.emit( 'build', build );
		build.start();
	}

	static function searchHxmlFiles( ?paths : Array<String>, maxDepth = 5, callback : Array<String>->Void ) {

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
							if( file.extension() == 'hxml' ) results.push( file );
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
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }

	static inline function getConfig<T>( id : String ) : T {
		return Atom.config.get( 'xxx.$id' );
	}

	static function consumeStatusBar( bar ) {
		bar.addLeftTile({
			item: new xxx.view.StatusbarView().element,
			priority: -100
		});
	}

	static function provideAutoCompletion() {
		return new AutoComplete();
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

	static function provideService() {
		//TODO
		return null;
	}
}
