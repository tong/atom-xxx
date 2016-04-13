package atom;

import js.Browser.console;
import js.node.Fs;
import js.node.ChildProcess.spawn;
import haxe.Timer;
import om.haxe.Hxml;
import om.haxe.ErrorMessage;
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
import atom.haxe.ide.view.OutlineView;
import Atom.notifications;
import om.Time;
import thx.semver.Version;
import atom.haxe.ide.ServerStatus;

using Lambda;
using StringTools;
using haxe.io.Path;

@:keep
@:expose
@:native('haxe')
@:build(atom.haxe.ide.macro.BuildHaxeIDE.build())
class HaxeIDE {

    static inline function __init__() untyped module.exports = atom.HaxeIDE;

    static var config = {

        haxe_path: {
            "title": "Haxe path",
            "description": "Path to the haxe executable",
            "type": "string",
            "default": "haxe"
        },
        haxe_server_port: {
            "title": "Haxe Server Port",
            "description": "The port number the haxe server will listen.",
            "type": "integer",
            "default": 7000
        },
        haxe_server_host: {
            "title": "Haxe Server Host Name",
            "description": "The ip adress the haxe server will listen.",
            "type": "string",
            "default": "127.0.0.1"
        },
        haxe_server_startdelay:{
            "title": 'Haxe Server Activation Delay',
            "description": 'The delay in seconds before starting the haxe server.',
            "type": 'integer',
            "minimum": 0,
            "default": 3
        },

        buildlog_numbers: {
            "title": "Message Numbers",
            "description": "Show message numbers in build log",
            "type": "boolean",
            "default": true
        },
        buildlog_ansi_colors: {
            "title": "ANSI Colors",
            "description": "Print colors from ANSI codes",
            "type": "boolean",
            "default": true
        },
        buildlog_print_command: {
            "title": "Print Haxe Build Command",
            "description": "",
            "type": "boolean",
            "default": true
        },

        serverlog_max_messages:{
            "title": 'Max ServerLog Messages',
            "description": 'Maximal messages to hold in serverlog history',
            "type": 'integer',
            "minimum": 0,
            "default": 1000
        }

        /*
        build_selectors: {
            "title": 'Build file scopes',
            "description": 'When triggering a build command, only file scope in this list will trigger.',
            "type": 'string',
            "default": 'source.haxe, source.hxml'
        },
        autocomplete_enabled: {
            "title": "Autocomplete",
            "description": "Enables/Disables haxe autocompletion",
            "type": "boolean",
            "default": false
        }
        hxml_template: {
            title: '.hxml template file',
            description: '',
            type: 'string',
            default:'haxe-ide/template/new.hxml'
        },
        */
    };

    public static var packagePath(default,null) : String;
    public static var state(default,null) : atom.haxe.ide.State;
    public static var server(default,null) : atom.haxe.ide.Server;

    public static var serverlog(default,null) : ServerLogView;
    public static var statusbar(default,null) : StatusBarView;
    public static var buildlog(default,null) : BuildLogView;
    //static var outline : OutlineView;

    //static var subscriptions : CompositeDisposable;
    static var configChangeListener : Disposable;

    static var commandServerStop : Disposable;
    static var commandServerStart : Disposable;
    static var commandBuild : Disposable;
    static var commandServerLogToggle : Disposable;

    static var opener : Disposable;

    static var completion : atom.haxe.ide.CompletionProvider;

    static function activate( savedState : Dynamic ) {

        trace( 'Atom-haxe-ide $version ' );
        //trace( savedState );

        packagePath = Atom.packages.resolvePackagePath( 'haxe-ide' );

        //trace(Atom.getLoadSettings());

        //trace( Atom.deserializers.deserialize( savedState ) );

        state = new atom.haxe.ide.State( savedState.state );

        statusbar = new StatusBarView();
        buildlog = new BuildLogView();
        serverlog = new ServerLogView();
        //serverlog.show();
        //outline = new OutlineView();

        //var buildlog2 = new atom.haxe.ide.view.BuildLogView2();
        //Atom.deserializers.add( ServerLogView );

        if( savedState != null ) {
            if( savedState.serverLog != null && savedState.serverLog.visible ) {
                serverlog.show();
            }
        }

        server = new atom.haxe.ide.Server();
        server.onStart = function(){

            console.info( 'Haxe server started '+server.status );
            statusbar.setServerStatus( server.status, server.exe, server.host, server.port );

            if( commandServerStart != null ) commandServerStart.dispose();
            commandServerStop = Atom.commands.add( 'atom-workspace', 'haxe:server-stop', function(e) stopServer() );
            commandServerLogToggle = Atom.commands.add( 'atom-workspace', 'haxe:server-log-toggle', function(_) serverlog.toggle() );
        }
        server.onStop = function( code : Int ){

            console.info( 'Haxe server stopped ($code) '+server.status );
            statusbar.setServerStatus( server.status, server.exe, server.host, server.port );

            if( commandServerStop != null ) commandServerStop.dispose();
            if( commandServerLogToggle != null ) commandServerLogToggle.dispose();
            commandServerStart = Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(e) startServer() );
        }
        server.onError = function(msg){
            console.warn( msg );
            statusbar.setServerStatus( server.status, server.exe, server.host, server.port );
        }
        server.onMessage = function(msg){
            trace(msg);
            var lines = serverlog.add( msg );
            if( lines != null ) {
                var i = 0;
                for( line in lines ) {
                    if( line.startsWith( 'Time spent :' ) ) {
                        var info = line.substr(13);
                        if( lines[i-1] != null )  info += ', '+lines[i-1].substr(8);
                        statusbar.setMetaInfo( info );
                    } else {
                        statusbar.setMetaInfo( line );
                    }
                    i++;
                }
            }
        }

        //var parser = new atom.haxe.ide.HaxeParser();

        //subscriptions = new CompositeDisposable();
        //subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:build', function(_) build() ) );
        commandServerStart = Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(_) startServer() );
        commandBuild = Atom.commands.add( 'atom-workspace', 'haxe:build', function(_) build() );

        configChangeListener = Atom.config.onDidChange( 'haxe-ide', {}, function(e){
            var nv = e.newValue;
            var ov = e.oldValue;
            if( nv.haxe_path != ov.haxe_path ||
                nv.haxe_server_port != ov.haxe_server_port ||
                nv.haxe_server_host != ov.haxe_server_host ) {
                    server.stop();
                    Timer.delay( startServer, getConfigValue( 'server_startdelay' ) * 1000 );
                }
        });

        opener = Atom.workspace.addOpener( function(uri){
            var ext = uri.extension();
            switch ext {
            case 'hx':
                trace( Atom.workspace.getActiveTextEditor() );
            case 'hxml':
            }
            return null;
            //return uri.startsWith( Manager.PREFIX ) ? new Manager() : null;
        });

        /*
        Atom.workspace.observeTextEditors(function(editor){
            var path = editor.getPath();
            var ext = path.extension();
            if( ext == null )
                return;
            switch ext {
            case 'hx':
                trace("HAXEFILE");
                //TODO
                /*
                editor.onDidChange(function(){
                    console.time("haxeparse");
                    parser.parse( editor.getText(), editor.getPath(), function(e){
                        console.timeEnd( "haxeparse" );
                        console.debug( e.pack.join('.')+';' );
                        for( decl in e.decls ) trace(decl);
                    });
                });
                * /
                editor.onDidSave(function(e){
                    if( editor.getText().trim().length == 0 ) {
                        var projectPath = Atom.project.getPaths()[0];
                        var path = e.path;
                        var relPath = path.substr( projectPath.length + 1 );
                        var parts = relPath.split('/');
                        if( parts[0] == 'src' ) parts.shift(); //TODO
                        var file = parts.pop().split('.')[0];
                        var pack = parts.join('.');
                        var tpl = 'package $pack;\n\nclass $file {\n\n\tpublic function new() {\n\t}\n}\n';
                        editor.setText( tpl );
                        editor.moveUp(2);
                        editor.moveToEndOfLine();
                        editor.save();
                    }
                });
            case 'hxml':
                //TODO insert empty hxml snippet
                /*
                if( editor.getText().trim().length == 0 ) {
                }
            }
            *
        });
        */

        if( state.hxml == null ) {
            searchHxmlFiles( function(found){
                if( found.length > 0 ) state.setHxml( found[0] );
            });
        }

        Timer.delay( function(){

            /*
            var minPort = getConfigValue( 'haxe_server_port' );
            var maxServerInstances = 10;
            var i = 0;
            var haxeVersion : String = null;
            while( i < maxServerInstances ) {
                try {
                    haxeVersion = om.HaxeProcess.getServerVersionSync( minPort + i );
                } catch(e:Dynamic) {
                    trace(e);
                    break;
                }
                i++;
            }
            if( haxeVersion != null ) {
                trace(haxeVersion);
                //server.status = ServerStatus.idle;
            } else {
                var nPort = minPort + 1;
                trace("TRY PORT: "+nPort );
                startServer();
            }
            */

            //TODO try to kill process ?
            /*
            getHaxeVersion(function(e:String,v:String){
                if( e != null ) {
                    startServer();
                } else {
                    console.info( 'haxe version $v' );
                }
            });
            */


            startServer();

        }, getConfigValue( 'server_startdelay' ) * 1000 );

        //trace( Atom.project.getPaths() );

        /*
        var editor = Atom.workspace.getActiveTextEditor();
        var line = 319;
        var column = 9;
        //var range = new atom.Range( [3,0],[4,5] );
        //var range = new atom.Range( [0,0], [5,5] );
        //var range = new atom.Range( [line,column], [line,column+3] );
        //var marker = editor.markBufferRange( range );
        var marker = editor.markBufferPosition( [line,column] );
        //var marker = editor.markBufferRange( range, { invalidate:'overlap' } );
        var params : Dynamic = {  type:'line' };
        Reflect.setField( params, 'class', 'line-haxe-error' );
        var decoration = editor.decorateMarker( marker, params );
        trace(decoration);
        */

        completion = new atom.haxe.ide.CompletionProvider( packagePath+'/cache' );
    }

    static function deactivate() {

        //subscriptions.dispose();
        if( commandBuild != null ) commandBuild.dispose();
        if( commandServerStart != null ) commandServerStart.dispose();
        if( commandServerStop != null ) commandServerStop.dispose();
        if( commandServerLogToggle != null ) commandServerLogToggle.dispose();

        server.stop();

        configChangeListener.dispose();
        opener.dispose();

        statusbar.destroy();
        buildlog.destroy();
        serverlog.destroy();

        completion.dispose();
    }

    static function serialize() {
        return {
            state: state.serialize(),
            //server: server.serialize()
            serverlog: serverlog.serialize()
        };
    }

    public static inline function getConfigValue<T>( key : String ) : T {
        return Atom.config.get( 'haxe-ide.$key' );
    }

    public static function searchHxmlFiles( callback : Array<String>->Void ) {
        var paths = Atom.project.getPaths();
        if( paths.length == 0 )  callback([]) else _searchHxmlFiles( paths, [], callback );
    }

    public static function getHaxeVersion( ?exePath : String, callback : String->String->Void ) {
        if( exePath == null ) exePath = getConfigValue( 'haxe_path' );
        var res : String = '';
        var proc = spawn( exePath, ['-version'] );
        proc.stderr.on( 'data', function(e) res += e.toString() );
        proc.on( 'exit', function(code) {
            switch code {
            case 0:
                if( res != null ) res = res.trim();
                callback( null, res );
            default:
                callback( res, null );
            }
        });
    }

    public static function startServer() {
        if( server.status != off )
            server.stop();
        server.start(
            getConfigValue( 'haxe_path' ),
            getConfigValue( 'haxe_server_port' ),
            getConfigValue( 'haxe_server_host' ),
            function(){}
        );
    }

    public static inline function stopServer() {
        server.stop();
    }

    public static function build() {

        //TODO test if (re)build is required

        buildlog.clear();

        var treeViewFile = getTreeViewFile( 'hxml' );
        if( treeViewFile != null ) {
            state.setHxml( treeViewFile );
        } else if( state.hxml == null ) {
            notifications.addWarning( 'No hxml file selected' );
            return;
        }

        Fs.readFile( state.hxml, {encoding:'utf8'}, function(e,r){

            if( e != null ) {
                notifications.addWarning( 'Invalid hxml file: '+state.hxml );
                return;
            }

            statusbar.set( state.hxml, active );

            // HACK
            var tokens = Hxml.parseTokens( r );
            for( i in 0...tokens.length ) {
                var token = tokens[i];
                if( i < tokens.length-1 && !token.startsWith('-') ) {
                    var next =  tokens[i+1];
                    if( !next.startsWith( '-' ) ) {
                        tokens[i] = '$token $next';
                        tokens.splice( i+1, 1 );
                    }
                }
            }

            var args = [ '--cwd', state.cwd ].concat( tokens );

            if( server.status != off ) {
                //TODO why not write directly to stdin of server process ?
                //server.stdin.write();
                if( args.has( '--connect' ) ) {
                    notifications.addWarning( '"--connect" should not be set if building with atom' );
                } else {
                    args = ['--connect', Std.string( server.port )].concat( args );
                }
            }
            //args.push('--times'); statusBar.setMetaInfo( line );//TODO
            //trace(args);

            var build = new Build( getConfigValue( 'haxe_path' ) );

            build.onMessage = function(msg){
                buildlog.message( msg );
                buildlog.show();
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
                            buildlog.message( line, 'error' );
                        }
                    }
                    if( haxeErrors.length > 0 ) {

                        for( e in haxeErrors )
                            buildlog.error( e );

                        var err = haxeErrors[0];

                        if( err.path != '--macro' ) {

                            var filePath = err.path.startsWith('/') ? err.path : state.cwd+'/'+err.path;

                            //TODO check if error at std and avoid opening if configured
                            //TODO .. better check against a custom blacklist
                            //trace(filePath);

                            var line = err.line - 1;
                            var column =
                                if( err.lines != null ) err.lines.start;
                                else if( err.characters != null ) err.characters.start;
                                else err.character;

                            trace(line+":"+column);

                            Atom.workspace.open( filePath, {
                                initialLine: line,
                                initialColumn: column,
                                activatePane: true,
                                searchAllPanes : true
                            }).then( function(editor:TextEditor){
                                editor.scrollToCursorPosition();
                                //TODO decorate error position
                            });
                        }
                    }

                    buildlog.show();
                }
            }

            build.onSuccess = function() {
                statusbar.setBuildStatus( success );
            }

            if( getConfigValue( 'buildlog_print_command' ) ) {
                buildlog.meta( args.join( ' ' ) );
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
            /*
            getVersion: function(){
                //return { exe:server.exe, host:server.host, port:server.port, status:server.status };
            },
            */
            getStatus: function(){
                return { exe:server.exe, host:server.host, port:server.port, status:server.status };
            },
            start: function(){
                startServer();
            },
            stop: function(){
                server.stop();
            }
        };
    }

    static function provideBuildService() : HaxeBuildService {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {
                if( server.status != off ) {
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
        //return getConfigValue( 'autocomplete_enabled' ) ? new atom.haxe.ide.CompletionProvider() : null;
        return null; //completion; //new atom.haxe.ide.CompletionProvider();
    }

    ////////////////////////////////////////////////////////////////////////////

    static inline function fileExists( path : String ) : Bool {
		return try { Fs.accessSync(path); true; } catch (_:Dynamic) false;
	}

    static inline function getTreeViewFile( ext : String ) : String {
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return if( path != null && path.extension() == ext ) path else null;
    }

    static function _searchHxmlFiles( paths : Array<String>, found : Array<String>, callback : Array<String>->Void ) {
        var path = paths.shift();
        Fs.readdir( path, function(err,files){
            for( f in files ) {
                if( f.extension() == 'hxml' )
                    found.push( '$path/$f' );
            }
            if( paths.length == 0 )
                callback( found );
            else
                _searchHxmlFiles( paths, found, callback );
        });
    }
}
