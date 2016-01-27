package atom;

import js.Browser.console;
import js.node.Fs;
import haxe.Timer;
import haxe.Hxml;
import haxe.compiler.ErrorMessage;
import atom.Disposable;
import atom.TextEditor;
import atom.CompositeDisposable;
import atom.haxe.ide.Build;
import atom.haxe.ide.Server;
import atom.haxe.ide.service.HaxeBuildService;
import atom.haxe.ide.service.HaxeServerService;
import atom.haxe.ide.view.BuildLogView;
import atom.haxe.ide.view.BuildStatsView;
import atom.haxe.ide.view.StatusBarView;
import atom.haxe.ide.view.ServerLogView;
import Atom.notifications;

using StringTools;
using haxe.io.Path;

@:keep
@:expose
@:native('haxe')
class HaxeIDE {

    static inline function __init__() untyped module.exports = atom.HaxeIDE;

    static var config = {
        haxe_path: {
            "title": "Haxe executable path",
            "description": "Path to haxe executable",
            "type": "string",
            "default": "haxe"
        },
        server_port: {
            "title": "Haxe server port",
            "description": "The port number the haxe server will wait on.",
            "type": "integer",
            "default": 7000
        },
        server_host: {
            "title": "Haxe server host name",
            "description": "The ip adress the haxe server will listen.",
            "type": "string",
            "default": "127.0.0.1"
        },
        server_startdelay:{
            "title": 'Activation start delay',
            "description": 'The delay in seconds before starting the haxe server.',
            "type": 'integer',
            "minimum": 0,
            "default": 3
        }
        /*
        build_server_enabled: {
            "title": "Enable/Disable haxe build server",
            "description": "Enables/Disables to start an internal build server",
            "type": "boolean",
            "default": true
        }
        log_show_number: {
            "title": "Show Line Numbers",
            "description": "Show line numbers in build log",
            "type": "boolean",
            "default": true
        }
        */
    };

    public static var state(default,null) : atom.haxe.ide.State;
    public static var server(default,null) : atom.haxe.ide.Server;
    //public static var hxmlFile(default,null) : String;

    static var subscriptions : CompositeDisposable;
    static var configChangeListener : Disposable;

    static var log : BuildLogView;
    static var statusbar : StatusBarView;
    static var serverLog : ServerLogView;

    static function activate( savedState ) {

        trace( 'Atom-haxe-ide' );

        state = new atom.haxe.ide.State( savedState );
        if( state.hxml == null ) {
            searchHxmlFiles(function(found){
                if( found.length > 0 )
                    state.setPath( found[0] );
            });
        }

        statusbar = new StatusBarView();
        log = new BuildLogView();
        serverLog = new ServerLogView();

        /*
        if( savedState.hxmlFile != null ) {
            if( fileExists( savedState.hxmlFile ) ) {
                sta = savedState.hxmlFile;
                //trace(hxmlFile);
                /*
                var dir = new atom.Directory( hxmlFile.directory() );
                dir.onDidChange(function(){
                    trace("CHANGED");
                });
                * /
                //trace(new atom.Directory('/home/tong/dev/tool/atom-haxe-ide/'));
                statusbar.setBuildPath( hxmlFile );
            }
        }
        */

        server = new atom.haxe.ide.Server();
        server.onStart = function(){
            console.info( 'Haxe server started' );
            statusbar.setServerStatus( server.exe, server.host, server.port, server.running );
        }
        server.onStop = function( code : Int ){
            console.info( 'Haxe server stopped ($code)' );
        }
        server.onError = function(msg){
            console.warn( msg );
            //notifications.addError( msg );
        }
        server.onMessage = function(msg){
            //trace(msg);
            serverLog.add( msg );
            serverLog.scrollToBottom(); //TODO doesn't work
        }

        subscriptions = new CompositeDisposable();
        subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:build', build ) );
        subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(e) startServer() ) );
        subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:server-stop', function(e) stopServer() ) );
        subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe-ide:toggle-server-log', function(_) serverLog.toggle() ) );

        configChangeListener = Atom.config.onDidChange( 'haxe-ide', {}, function(e){
            //TODO check which option has changed
            server.stop();
            server.start( e.newValue.haxe_path, e.newValue.server_port, e.newValue.server_host );
        });

        Timer.delay(function(){
            server.start(
                Atom.config.get( 'haxe-ide.haxe_path' ),
                Atom.config.get( 'haxe-ide.server_port' ),
                Atom.config.get( 'haxe-ide.server_host' )
            );
        }, Atom.config.get( 'haxe-ide.server_startdelay' ) * 1000 );
    }

    static function deactivate() {

        subscriptions.dispose();
        configChangeListener.dispose();

        server.stop();

        log.destroy();
        statusbar.destroy();
        serverLog.destroy();
    }

    static function serialize() {
        return state.serialize();
    }

    ////////////////////////////////////////////////////////////////////////////

    static function startServer() {
        server.start(
            Atom.config.get( 'haxe-ide.haxe_path' ),
            Atom.config.get( 'haxe-ide.server_port' ),
            Atom.config.get( 'haxe-ide.server_host' )
        );
    }

    static function stopServer() {
        server.stop();
    }

    ////////////////////////////////////////////////////////////////////////////

    static function build(e) {

        log.clear();

        var treeViewFile = getTreeViewFile();
        if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
            state.setPath( treeViewFile );
        } else if( state.hxml == null ) {
            notifications.addWarning( 'No hxml file selected' );
            return;
        }

        Fs.readFile( state.hxml, {encoding:'utf8'}, function(e,r){

            if( e != null ) {
                notifications.addError( 'Failed to read hxml file: '+state.hxml );
                return;
            }

            statusbar.set( state.hxml, active );

            //var dirPath = state.dir;
            //var filePath = hxmlFile.withoutDirectory();

            var tokens = Hxml.parseTokens( r );
            var args = [ '--cwd', state.dir ];
            if( server.running ) {
                //TODO why not write directly to stdin of server process ?
                //server.stdin.write();
                args.push( '--connect' );
                args.push( Std.string( server.port ) );
            }
            //args.push('--times'); //TODO
            args = args.concat( tokens );
            //trace(args);

            var build = new Build( Atom.config.get( 'haxe-ide.haxe_path' ) );

            build.onMessage = function(msg){
                for( line in msg.split( '\n' ) )
                    log.message( line );
                log.show();
            }

            build.onError = function(msg){

                statusbar.setBuildStatus( error );

                if( msg != null ) {

                    var haxeErrors = new Array<ErrorMessage>();
                    for( line in msg.split( '\n' ) ) {
                        if( (line = line.trim()).length == 0 )
                            continue;
                        var err = ErrorMessage.parse( line );
                        if( err != null ) {
                            haxeErrors.push( err );
                        } else {
                            log.message( line, 'error' );
                        }
                    }
                    if( haxeErrors.length > 0 ) {

                        for( e in haxeErrors )
                            log.error( e );

                        var err = haxeErrors[0];

                        if( err.path != '--macro' ) {

                            var filePath = err.path.startsWith('/') ? err.path : state.dir+'/'+err.path;
                            var line = err.line - 1;
                            var column =
                                if( err.lines != null ) err.lines.start;
                                else if( err.characters != null ) err.characters.start;
                                else err.character;

                            //TODO check if error at std and avoid opening if configured

                            Atom.workspace.open( filePath, {
                                initialLine: line,
                                initialColumn: column,
                                activatePane: true,
                                searchAllPanes : true
                            }).then( function(editor:TextEditor){

                                editor.scrollToCursorPosition();
                                //editor.selectWordsContainingCursors();
                                //editor.selectToEndOfWord();
                                //editor.setSelectedScreenRange( [line,column] );

                                //TODO texteditor error decoration

                                //Atom.views.getView(Atom.workspace).focus();

                                //var range = editor.getSelectedBufferRange();
                                //var range = new atom.Range( [3,0],[4,5] );
                                //var range = new atom.Range( [0,0], [5,5] );
                                //trace(editor);
                                //var marker = editor.markBufferRange( range );

                                //var marker = editor.markBufferRange( range, { invalidate:'overlap' } );
                                //var params : Dynamic = {  type:'line' };
                                //Reflect.setField( params, 'class', 'haxe-error-decoration' );
                                // Why does the class fucking not apply ?????
                                //var decoration = editor.decorateMarker( marker, params );
                            });
                        }
                    }

                    log.show();
                }
            }

            build.onSuccess = function() {
                statusbar.setBuildStatus( success );
            }

            build.start( args );
        });
    }

    ////////////////////////////////////////////////////////////////////////////

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusbar.element, priority:-10 } );
    }

    ////////////////////////////////////////////////////////////////////////////

    static function provideServerService() : HaxeServerService {
        return {
            getStatus: function(){
                return { exe:server.exe, host:server.host, port:server.port, running:server.running };
            },
            start: function(){
                server.start(
                    Atom.config.get( 'haxe.haxe_path' ),
                    Atom.config.get( 'haxe.server_port' ),
                    Atom.config.get( 'haxe.server_host' ) );
            },
            stop: function(){
                server.stop();
            }
        };
    }

    static function provideBuildService() : HaxeBuildService {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {

                if( server.running ) {
                    args.push( '--connect' );
                    args.push( Std.string( server.port ) );
                }

                //TODO
                //_build();
                //log.clear();

                //var startTime = now();
                var build = new atom.haxe.ide.Build( Atom.config.get( 'haxe-ide.haxe_path' ) );
                build.onMessage = onMessage;
                build.onError = function(msg){
                    //log.scrollToBottom();
                    onError( msg );
                };
                build.onSuccess = function() {
                    //log.scrollToBottom();
                    onSuccess();
                }
                build.start( args );
            }
        };
    }

    static function provideAutoCompletion() {
        //if( hxml != null )
        //return new CompletionProvider();
        return null;
    }

    ////////////////////////////////////////////////////////////////////////////

    static function fileExists( path : String ) : Bool {
		return try { Fs.accessSync(path); true; } catch (_:Dynamic) false;
	}

    static function getTreeViewFile() : String {
        return Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
    }

    static function searchHxmlFiles( cb : Array<String>->Void ) {
        var paths = Atom.project.getPaths();
        (paths.length == 0) ? cb([]) : _searchHxmlFiles( paths, [], cb );
    }

    static function _searchHxmlFiles( paths : Array<String>, found : Array<String>, cb : Array<String>->Void ) {
        var path = paths.shift();
        Fs.readdir( path, function(err,files){
            for( f in files ) {
                if( f.extension() == 'hxml' )
                    found.push( '$path/$f' );
            }
            if( paths.length == 0 )
                cb( found );
            else
                _searchHxmlFiles( paths, found, cb );
        });
    }
}
