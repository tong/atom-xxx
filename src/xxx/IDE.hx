package xxx;

import js.node.Fs;
import haxe.Timer;
import atom.CompositeDisposable;
import Atom.notifications;
import xxx.view.BuildView;

using StringTools;
using haxe.io.Path;

@:keep
@:expose
@:build(atom.macro.BuildPackage.build())
class IDE {

	public static var server(default,null) : Server;
	public static var build(default,null) : Build;
	public static var hxmlFiles(default,null) : Array<String>;

	static var disposables : CompositeDisposable;

	static var buildView : BuildView;

	static function activate( state ) {

		trace( 'Atom-xxx' );
		trace( state );

		disposables = new CompositeDisposable();

		server = new Server(
			getConfig( 'haxe_path' ),
			getConfig( 'haxe_server_port' ),
			getConfig( 'haxe_server_host' )
		);
		server.on( 'error', function(e) trace(e) );
		server.on( 'start', function() {
			//trace("SERVER STARTED");
			//Atom.commands.add( 'atom-workspace', 'haxe:stop-server', function(e) server.stop() );
		});
		server.on( 'stop', function(code) {
			//trace("SERVER STOPPED");
			trace(code);
			//Atom.commands.add( 'atom-workspace', 'haxe:start-server', function(e) server.start() );
		});

		Timer.delay( function(){
			trace( 'Starting haxe server: '+server.port );
			server.start();
		}, getConfig( 'haxe_server_startdelay' ) * 1000 );


		build = new Build();

		buildView = new BuildView();

		var serverLogView = new xxx.view.ServerLogView();

		build.on( 'start', function() serverLogView.clear() );
		//build.on( 'message', function(e) trace(e) );
		//build.on( 'error', function(e) trace(e) );
		build.on( 'exit', function(e) {
			trace(e);
		});


		Atom.commands.add( 'atom-workspace', 'haxe:start-server', function(e) server.start() );
		Atom.commands.add( 'atom-workspace', 'haxe:stop-server', function(e) server.stop() );
		Atom.commands.add( 'atom-workspace', 'haxe:build', function(e) {

			var treeViewFile = getTreeViewFile();
	        if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
				trace(treeViewFile);
				build.select( treeViewFile );
				//if( build.select( treeViewFile ) )
				/*
	            if( hxml != null && treeViewFile != hxml.getPath() ) {
	                selectHxml( treeViewFile );
	            }
				*/
	        }

			//var view = new xxx.view.BuildView();
			//view.show();
			buildView.show();
			try {
				build.start();
			} catch(e:Dynamic) {
				notifications.addWarning( e );
			}
		});

		//searchHxmlFiles( [Atom.project.getPaths()[0]], function( found:Array<String>){
		searchHxmlFiles( function( found:Array<String>){

			trace( found.length+' hxml files found' );

			hxmlFiles = found;

			if( state != null && state.hxml != null ) {
				var exists = false;
				for( f in found ) if( f == state.hxml ) {
					exists = true;
					break;
				}
				build.select( exists ? state.hxml : found[0] );
			} else {
				build.select( found[0] );
			}
		});
	}

	static function serialize() {
        return {
            hxml: (build.hxml != null) ? build.hxml.getPath() : null,
			//server: server.running
        };
    }

	static function deactivate() {
		disposables.dispose();
		server.stop();
	}

	static function provideAutoCompletion() {
        //return new Completion();
        return null;
    }

	static inline function searchHxmlFiles( ?paths : Array<String>, callback : Array<String>->Void ) {

		//_searchHxmlFiles( (paths == null) ? Atom.project.getPaths() : paths, [], callback );

		/*
		var task = atom.Task.once( 'task/find-hxml.js', function(){
			trace("ddd");
			} );
			*/

		//trace(om.Worker.createInlineURL(om.macro.File.getContent('res/task/find-hxml.js')));

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
		if( paths == null ) paths = Atom.project.getPaths();

		var search = function( path : String, callback : Array<String>->Void ) {


		}
		sear
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
        bar.addLeftTile( { item: new xxx.view.StatusbarView().element, priority: -100 } );
    }

	static function getTreeViewFile( ?ext : String ) : String {
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }

	static inline function getConfig<T>( id : String ) : T {
		return Atom.config.get( 'xxx.$id' );
	}

}
