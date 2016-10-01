package xxx;

import js.node.Fs;
import haxe.Timer;
import atom.CompositeDisposable;
import atom.Disposable;
import atom.Emitter;
import atom.File;
import Atom.commands;
import Atom.notifications;
import xxx.view.BuildView;

using StringTools;
using haxe.io.Path;

@:keep
@:expose
@:build(atom.macro.BuildPackage.build())
class IDE {

	public static var server(default,null) : Server;
	public static var hxml(default,null) : File;
	public static var hxmlFiles(default,null) : Array<String>;

	static var disposables : CompositeDisposable;
	static var emitter : Emitter;

	static function activate( state ) {

		trace( 'Atom-xxx' );
		trace( state );

		disposables = new CompositeDisposable();
		emitter = new Emitter();

		var cmdStartServer = commands.add( 'atom-workspace', 'haxe:start-server', function(e) server.start() );
		var cmdStopServer : Disposable = null;

		server = new Server(
			getConfig( 'haxe_path' ),
			getConfig( 'haxe_server_port' ),
			getConfig( 'haxe_server_host' )
		);
		server.on( 'error', function(e) {
			trace(e);
			//notifications.addError( e );
		});
		server.on( 'start', function() {
			trace( 'Haxe server started' );
			cmdStartServer.dispose();
			cmdStopServer = commands.add( 'atom-workspace', 'haxe:stop-server', function(e) server.stop() );
		});
		server.on( 'stop', function(code) {
			trace( 'Haxe server stopped' );
			cmdStopServer.dispose();
			cmdStartServer = commands.add( 'atom-workspace', 'haxe:start-server', function(e) server.start() );
			//Atom.commands.add( 'atom-workspace', 'haxe:start-server', function(e) server.start() );
		});

		new xxx.view.ServerLogView();

		searchHxmlFiles( function( found:Array<String> ) {

			trace( found.length+' hxml files found' );

			hxmlFiles = found;

			if( state != null && state.hxml != null ) {
				var exists = false;
				for( f in found ) if( f == state.hxml ) {
					exists = true;
					break;
				}
				selectHxml( exists ? state.hxml : found[0] );
			} else {
				selectHxml( found[0] );
			}
		});

		Atom.commands.add( 'atom-workspace', 'haxe:build', function(e) {
			var treeViewFile = getTreeViewFile();
	        if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
	            if( hxml != null && treeViewFile != hxml.getPath() ) {
	                selectHxml( treeViewFile );
	            }
	        }
			build();
		});

		/*
		Atom.commands.add( 'atom-workspace', 'haxe:select', function(e) {
			var view = new xxx.view.SelectHxmlView();
		});
		*/

		Timer.delay( function(){
			trace( 'Starting haxe server: '+server.port );
			server.start();
		}, getConfig( 'haxe_server_startdelay' ) * 1000 );
	}

	static function serialize() {
		return {
            //hxml: (build.hxml != null) ? build.hxml.getPath() : null,
			//server: server.running
        };
    }

	static function deactivate() {
		disposables.dispose();
		server.stop();
	}

	public static inline function onSelectHxml( h : File->Void ) emitter.on( 'select_hxml', h );
	public static inline function onBuild( h : Build->Void ) emitter.on( 'build', h );

	public static function selectHxml( path : String ) {
		if( path == null ) {
            hxml = null;
			emitter.emit( 'select_hxml', hxml );
		} else {
			if( hxml != null && path == hxml.getPath() ) {
                return;
            }
			hxml = new File( path );
			emitter.emit( 'select_hxml', hxml );
		}
	}

	public static function build() {
		var build = new Build( hxml );
		var view = new BuildView();
		emitter.emit( 'build', build );
		build.start();
	}

	static function searchHxmlFiles( ?paths : Array<String>, callback : Array<String>->Void ) {

		if( paths == null ) paths = Atom.project.getPaths();
		var found = new Array<String>();
		for( path in paths ) {
			for( f in sys.FileSystem.readDirectory( path ) ) {
				if( f.charAt(0) == '.' )
					continue;
				var p = '$path/$f';
				if( f.extension() == 'hxml' ) {
					found.push( '$path/$f' );
				}
			}
		}
		callback( found );

		/*
		//var w = om.Worker.fromScript( om.macro.File.getContent('res/task/find-hxml.js') );
		var w = new om.Worker('atom://xxx/lib/task/find-hxml.js' );
		w.postMessage( paths );
		*/

		/*
		var found = new Array<String>();
		for( path in paths ) {
			Fs.readdir( path, function(e,entries){
				for( e in entries ) {
					if( e.charAt(0) == '.' )
						continue;
					var p = '$path/$e';
					if( e.extension() == '.hxml' )
						found.push();
					else {

					}
				}
			});
		}
		*/

		/*
		var rootPathsSearched = 0;
		var found = new Array<String>();
		var search : String->Void = null;
		search = function( path : String ) {
			Fs.readdir( path, function(e,entries){
				for( e in entries ) {
					if( e.charAt(0) == '.' )
						continue;
					if( e.extension() == '.hxml' ) {
						trace(e);
						found.push( e );
					}
					var p = '$path/$e';
					//if( p.isDirectorySync() ? search(p) : if( e.extension() == 'hxml' ) found.push(p);)
					if( om.io.FileUtil.isDirectorySync(p) ) search(p); // : if( e.extension() == 'hxml' ) found.push(p);)
				}
			});
			trace(found);
		}
		search( paths[0] );
		*/
	}

	/*
	static function _searchHxmlFiles( paths : Array<String>, found : Array<String>, callback : Array<String>->Void ) {
        if( paths.length == 0 ) callback( found ) else {
            var path = paths.shift();
            Fs.readdir( path, function(err,entries){
                if( err != null ) notifications.addError( Std.string(err), null ) else {
                    for( e in entries ) {
                        if( e.charAt(0) == '.' )
                            continue;
                        var p = '$path/$e';
						Fs.stat( p, function(err,stat){
							if( stat.isDirectory() ) {
								paths.push(p);
							} else {
								if( e.extension() == 'hxml' ) found.push(p);
							}
							//stat.isDirectory() ? paths.push(p) : if( e.extension() == 'hxml' ) found.push(p);
						});
                        //p.isDirectorySync() ? paths.push(p) : if( e.extension() == 'hxml' ) found.push(p);
                    }
                    _searchHxmlFiles( paths, found, callback );
                }
            });
        }
    }
	*/

	static function consumeStatusBar( bar ) {
        bar.addLeftTile({
			item: new xxx.view.StatusbarView().element,
			priority: -100
		});
    }

	static function provideAutoCompletion() {
		//return new Completion();
		return null;
	}

	static function provideService() {
		return null;
	}

	static function getTreeViewFile( ?ext : String ) : String {
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }

	static inline function getConfig<T>( id : String ) : T {
		return Atom.config.get( 'xxx.$id' );
	}

}
