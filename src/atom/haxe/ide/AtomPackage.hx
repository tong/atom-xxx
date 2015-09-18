package atom.haxe.ide;

import js.node.Fs;
import atom.CompositeDisposable;
import atom.haxe.ide.view.BuildLogView;
import atom.haxe.ide.view.StatusBarView;
import atom.haxe.ide.view.ServerLogView;

using StringTools;
using haxe.io.Path;

@:keep
class AtomPackage {

    static inline function __init__() untyped module.exports = atom.haxe.ide.AtomPackage;

    static var config = {
        server_port: {
            "title": "Server port",
            "description": "The port number the haxe server will wait on.",
            "type": "integer",
            "default": 7000
        },
        server_host: {
            "title": "Server host name",
            "description": "The ip adress the haxe server will listen.",
            "type": "string",
            "default": "127.0.0.1"
        },
        haxe_path: {
            "title": "Haxe executable path",
            "description": "Path to haxe",
            "type": "string",
            "default": "haxe"
        }
    };

    static var server : atom.haxe.ide.Server;
    static var subscriptions : CompositeDisposable;
    static var hxmlFile : String;

    static var log : BuildLogView;
    static var statusbar : StatusBarView;
    static var serverLog : ServerLogView;

    static var configChangeListener : Disposable;

    static function activate( savedState ) {

        trace( 'Atom-haxe-ide' );

        statusbar = new StatusBarView();
        log = new BuildLogView();
        serverLog = new ServerLogView();

        if( savedState.hxmlFile != null ) {
            if( fileExists( savedState.hxmlFile ) ) {
                hxmlFile = savedState.hxmlFile;
                statusbar.setBuildPath( hxmlFile );
            }
        }
        if( hxmlFile == null ) {
            searchHxmlFiles(function(found){
                if( found.length > 0 ) {
                    hxmlFile = found[0];
                }
            });
        }

        server = new atom.haxe.ide.Server();
        server.onStart = function(){
            trace( 'Haxe server started' );
            statusbar.setServerStatus( server.exe, server.host, server.port, server.running );
        }
        server.onStop = function( code : Int ){
            trace( 'Haxe server stopped ($code)' );
        }
        server.onError = function(msg){
            trace( 'Haxe server error: $msg' );
            //Atom.notifications.addError( msg );
        }
        server.onMessage = function(msg){
            serverLog.add( msg );
            serverLog.scrollToBottom(); //TODO doesn't work
        }
        server.start(
            Atom.config.get( 'haxe-ide.haxe_path' ),
            Atom.config.get( 'haxe-ide.server_port' ),
            Atom.config.get( 'haxe-ide.server_host' ) );


        subscriptions = new CompositeDisposable();
        subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:build', build ) );

        configChangeListener = Atom.config.onDidChange( 'haxe-c', {}, function(e){
            server.stop();
            server.start( e.newValue.haxe_path, e.newValue.server_port, e.newValue.server_host );
        });

        //Atom.commands.add( 'atom-workspace', 'haxe-c:toggle-server-log', toggleServerLog );
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
        return {
            hxmlFile: hxmlFile
        };
    }

    ////////////////////////////////////////////////////////////////////////////

    static function build(e) {

        var selectedFile = getTreeViewFile();
        if( selectedFile != null && selectedFile.extension() == 'hxml' ) {
            hxmlFile = selectedFile;
        } else {
            if( hxmlFile == null ) {
                Atom.notifications.addWarning( 'No hxml file selected' );
                return;
            }
        }

        var dirPath = hxmlFile.directory();
        var filePath = hxmlFile.withoutDirectory();

        log.clear();
        statusbar.setBuildPath( hxmlFile );
        statusbar.setBuildStatus( active );

        var args = [ '--cwd', dirPath, filePath ];

        if( server.running ) {
            args.push( '--connect' );
            args.push( Std.string( server.port ) );
        }

        //args.push('--times'); //TODO

        //trace(args);

        var build = new Build();
        build.onMessage = function(msg){
            log.message( msg ).show();
        }
        build.onError = function(msg){

            statusbar.setBuildStatus( error );

            var errors = new Array<ErrorMessage>();
            for( line in msg.split( '\n' ) ) {
                line = line.trim();
                if( line.length == 0 )
                    continue;
                var err = ErrorMessage.parse( line );
                if( err != null ) {
                    errors.push( err );
                } else {
                    trace( 'Failed to parse error message: '+line );
                }
            }

            if( errors.length > 0 ) {

                for( err in errors )
                    log.error( err );
                log.show();

                var err0 = errors[0];
                Atom.workspace.open( dirPath+'/'+err0.path, {
                    initialLine: err0.line - 1,
                    initialColumn: err0.pos.start,
                    activatePane: true,
                    searchAllPanes : true
                });
            }
        }
        build.onSuccess = function() {
            statusbar.setBuildStatus( success );
        }
        build.start( args );

        /*
        haxeBuildService.build( args,
            function(msg){
                log.message( msg ).show();
            },
            function(msg){

                statusbar.setBuildStatus( error );

                if( msg.length == 0 )
                    return;

                var errors = new Array<ErrorMessage>();
                var plainTextErrors = new Array<String>();
                for( line in msg.split( '\n' ) ) {
                    line = line.trim();
                    if( line.length == 0 )
                        continue;
                    var err = ErrorMessage.parse( line );
                    if( err == null ) {
                        plainTextErrors.push( line );
                    } else {
                        errors.push( err );
                    }
                }
                for( err in errors ) log.error( err );
                for( err in plainTextErrors ) log.message( err, 'error' );
                log.show();


                /*
                var errPath = err0.path;
                while( errPath.startsWith('../') ) {
                    errPath = errPath.substr(3);
                }
                * /

                //trace(dirPath);
                //trace(errPath);
                //trace( Atom.project.relativizePath( err0.path ) );

                if( errors.length > 0 ) {
                    var err0 = errors[0];
                    Atom.workspace.open( dirPath+'/'+err0.path, {
                        initialLine: err0.line - 1,
                        initialColumn: err0.pos.start,
                        activatePane: true,
                        searchAllPanes : true
                    });
                }

                /*
                Atom.workspace.observeTextEditors(function(e){
                    if( untyped e.buffer.file.path.endsWith( errPath ) ) {
                        trace(e);
                    }
                });
                * /
                //var editor = Atom.workspace.getActiveTextEditor();
                //editor.selectAll();

            },
            function(){
                statusbar.setBuildStatus( success );
            }
        );
        */
    }

    ////////////////////////////////////////////////////////////////////////////

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusbar.dom, priority:-10 } );
    }

    ////////////////////////////////////////////////////////////////////////////

    public static function provideServerService() {
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

    public static function provideBuildService() {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {

                if( server.running ) {
                    args.push( '--connect' );
                    args.push( Std.string( server.port ) );
                }

                //log.clear();

                //var startTime = now();
                var build = new atom.haxe.Build();
                build.onMessage = onMessage;
                build.onError = function(msg){
                    //log.scrollToBottom();
                    onError( msg );
                };
                build.onSuccess = function() {
                    //trace(now()-startTime);
                    //log.scrollToBottom();
                    onSuccess();
                }
                build.start( args );
            }
        };
    }

    static function provideAutoCompletion() {
        //trace("provideAutoCompletion");
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
