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
import xxx.view.ServerLogView;

using StringTools;
using haxe.io.Path;

typedef IDEState = {
	var hxml : String;
	//var serverlog : Bool;
}

//@:build(atom.macro.BuildPackage.build())
@:keep
@:expose
class IDE {

	static inline function __init__() {
		untyped module.exports = xxx.IDE;
	}

	public static var hxmlFiles(default,null) : Array<String>;
	public static var hxml(default,null) : File;
	public static var lang(default,null) : LanguageServer;
	//public static var server(default,null) : Server;

	static var disposables : CompositeDisposable;
	static var emitter : Emitter;

	//static var serverlog : ServerLogView;
	static var buildView : BuildView;

	static function activate( state : IDEState ) {

		trace( 'Atom-xxx' );

		disposables = new CompositeDisposable();

		emitter = new Emitter();

		lang = new LanguageServer();
		lang.start( function(){
			//trace( 'Haxe language server started' );
		});

		/*
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
		*/

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

			buildView = new xxx.view.BuildView();

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

		});

		//serverlog = new ServerLogView();

		/*
		Timer.delay( function(){

			//var checkRun = ChildProcess.spawnSync(context.displayServerConfig.haxePath, ["-version"], {env: env});

			om.net.PortUtil.isPortTaken( server.port, function(taken) {
				if( taken ) {
					trace( 'Port ${server.port} already in use' );
				} else {

					trace( 'Starting haxe server: '+server.port );

					server.start();

					if( state != null && state.serverlog ) {
						serverlog.show();
					}
				}
			});
		}, getConfig( 'haxe_server_startdelay' ) * 1000 );
		*/
	}

	static function serialize() : IDEState {
		return {
            hxml: (hxml != null) ? hxml.getPath() : null
			//serverlog: serverlog.isVisible()
        };
    }

	static function deactivate() {
		disposables.dispose();
		//server.stop();
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
		//trace(build);

		var build = new Build( hxml );
		//build.onError();
		//var view = new BuildView();

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

	static function searchHxmlFiles( ?paths : Array<String>, callback : Array<String>->Void ) {
		//TODO
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
