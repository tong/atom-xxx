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
import atom.haxe.ide.view.OutlineView;
import Atom.notifications;
import om.Time;

using StringTools;
using haxe.io.Path;

@:keep
@:expose
@:native('haxe')
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
        serverlog_max_messages:{
        "title": 'Serverlog Max Messages',
        "description": '',
        "type": 'integer',
        "minimum": 0,
        "default": 1000
        },
        build_server_enabled: {
            "title": "Enable/Disable haxe build server",
            "description": "Enables/Disables to start an internal build server",
            "type": "boolean",
            "default": true
        }

        build_selectors: {
            "title": 'Build file scopes',
            "description": 'When triggering a build command, only file scope in this list will trigger.',
            "type": 'string',
            "default": 'source.haxe, source.hxml'
        },

        buildlog_ansi_colors: {
            "title": "ANSI Colors",
            "description": "Show line numbers in build log",
            "type": "boolean",
            "default": true
        }

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

    public static var state(default,null) : atom.haxe.ide.State;
    public static var server(default,null) : atom.haxe.ide.Server;

    //static var subscriptions : CompositeDisposable;
    static var configChangeListener : Disposable;

    static var statusBar : StatusBarView;
    static var buildLog : BuildLogView;
    static var serverLog : ServerLogView;
    //static var outline : OutlineView;

    static var commandServerStop : Disposable;
    static var commandServerStart : Disposable;
    static var commandBuild : Disposable;
    static var commandServerLogToggle : Disposable;

    static function activate( savedState : Dynamic ) {

        trace( 'Atom-haxe-ide '+savedState );

        state = new atom.haxe.ide.State( savedState.state );

        statusBar = new StatusBarView();
        buildLog = new BuildLogView();
        serverLog = new ServerLogView();
        //outline = new OutlineView();
        //outline.show();

        if( savedState.serverLogVisible ) {
            serverLog.show();
        }

        server = new atom.haxe.ide.Server();
        server.onStart = function(){
            console.info( 'Haxe server started '+server.status );
            statusBar.setServerStatus( server.status, server.exe, server.host, server.port );
            if( commandServerStart != null ) commandServerStart.dispose();
            commandServerStop = Atom.commands.add( 'atom-workspace', 'haxe:server-stop', function(e) stopServer() );
            commandBuild = Atom.commands.add( 'atom-workspace', 'haxe:build', function(_) build() );
        }
        server.onStop = function( code : Int ){
            console.info( 'Haxe server stopped ($code) '+server.status );
            statusBar.setServerStatus( server.status, server.exe, server.host, server.port );
            if( commandBuild != null ) commandBuild.dispose();
            if( commandServerStop != null ) commandServerStop.dispose();
            commandServerStart = Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(e) startServer() );
        }
        server.onError = function(msg){
            console.warn( msg );
            trace(server.status);
            statusBar.setServerStatus( server.status, server.exe, server.host, server.port );
        }
        server.onMessage = function(msg){
            var lines = serverLog.add( msg );
            if( lines != null ) {
                var i = 0;
                for( line in lines ) {
                    if( line.startsWith( 'Time spent :' ) ) {
                        var info = line.substr(13);
                        if( lines[i-1] != null )  info += lines[i-1].substr(8);
                        statusBar.setMetaInfo( info );
                    } else {
                        statusBar.setMetaInfo( line );
                    }
                    i++;
                }
            }
        }

        //var parser = new atom.haxe.ide.HaxeParser();

        //subscriptions = new CompositeDisposable();
        //subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:build', function(_) build() ) );
        //subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(e) startServer() ) );
        //subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe:server-stop', function(e) stopServer() ) );
        //subscriptions.add( Atom.commands.add( 'atom-workspace', 'haxe-ide:toggle-server-log', function(_) serverLog.toggle() ) );
        commandServerStart = Atom.commands.add( 'atom-workspace', 'haxe:server-start', function(_) startServer() );
        //commandServerStop = Atom.commands.add( 'atom-workspace', 'haxe:server-stop', function(_) stopServer() );
        //commandServerLogToggle = Atom.commands.add( 'atom-workspace', 'haxe:server-log-toggle', function(_) serverLog.toggle() );
        //commandBuild = Atom.commands.add( 'atom-workspace', 'haxe:build', function(_) build() );

        configChangeListener = Atom.config.onDidChange( 'haxe-ide', {}, function(e){

            //!TODO check which option has changed
            trace(e);

            server.stop();
            server.start( e.newValue.haxe_path, e.newValue.server_port, e.newValue.server_host, function(){

            });
        });

        Atom.workspace.observeTextEditors(function(editor){
            /*
            var path = editor.getPath();
            var ext = path.extension();
            if( ext == null )
                return;
            switch ext {
            case 'hx':
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
                * /
            }
            */
        });

        if( state.hxml == null ) {
            searchHxmlFiles( function(found){
                if( found.length > 0 )
                    state.setHxml( found[0] );
            });
        }

        Timer.delay( startServer, getConfigValue( 'server_startdelay' ) * 1000 );
    }

    static function deactivate() {

        //subscriptions.dispose();

        if( commandBuild != null ) commandBuild.dispose();
        if( commandServerStart != null ) commandServerStart.dispose();
        if( commandServerStop != null ) commandServerStop.dispose();
        if( commandServerLogToggle != null ) commandServerLogToggle.dispose();

        configChangeListener.dispose();

        server.stop();

        statusBar.destroy();
        buildLog.destroy();
        serverLog.destroy();
    }

    static function serialize() {
        return {
            state: state.serialize(),
            //server: server.serialize()
            serverLogVisible: serverLog.isVisible()
        };
    }

    public static function getConfigValue<T>( key : String ) : T {
        return Atom.config.get( 'haxe-ide.$key' );
    }

    public static function startServer() {
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

        buildLog.clear();

        var treeViewFile = getTreeViewFile();
        if( treeViewFile != null && treeViewFile.extension() == 'hxml' ) {
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

            statusBar.set( state.hxml, active );

            var args = [ '--cwd', state.cwd ];
            if( server.status != off ) {
                //TODO why not write directly to stdin of server process ?
                //server.stdin.write();
                args.push( '--connect' );
                args.push( Std.string( server.port ) );
            }
            //args.push('--times'); statusBar.setMetaInfo( line );//TODO
            //trace(args);

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
            args = args.concat( tokens );

            var build = new Build( Atom.config.get( 'haxe-ide.haxe_path' ) );

            build.onMessage = function(msg){
                buildLog.message( msg );
                buildLog.show();
            }

            build.onError = function(msg){

                statusBar.setBuildStatus( error );

                if( msg != null ) {

                    var haxeErrors = new Array<ErrorMessage>();
                    for( line in msg.split( '\n' ) ) {
                        if( (line = line.trim()).length == 0 )
                            continue;
                        var err = ErrorMessage.parse( line );
                        if( err != null ) {
                            haxeErrors.push( err );
                        } else {
                            buildLog.message( line, 'error' );
                        }
                    }
                    if( haxeErrors.length > 0 ) {

                        for( e in haxeErrors )
                            buildLog.error( e );

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

                    buildLog.show();
                }
            }

            build.onSuccess = function() {
                statusBar.setBuildStatus( success );
            }

            //if( Atom.config.get( 'haxe.haxe_path' ) )
            if( getConfigValue( 'buildlog_print_command' ) ) {
                buildLog.meta( args.join( ' ' ) );
            }

            build.start( args );
        });
    }

    ////////////////////////////////////////////////////////////////////////////

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusBar.element, priority:-10 } );
    }

    ////////////////////////////////////////////////////////////////////////////

    static function provideServerService() : HaxeServerService {
        return {
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
        return getConfigValue( 'autocomplete_enabled' ) ? new atom.haxe.ide.CompletionProvider() : null;
    }

    ////////////////////////////////////////////////////////////////////////////

    static inline function fileExists( path : String ) : Bool {
		return try { Fs.accessSync(path); true; } catch (_:Dynamic) false;
	}

    static inline function getTreeViewFile() : String {
        return Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
    }

    static function searchHxmlFiles( callback : Array<String>->Void ) {
        var paths = Atom.project.getPaths();
        (paths.length == 0) ? callback([]) : _searchHxmlFiles( paths, [], callback );
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
