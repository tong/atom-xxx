package xxx.atom;

import js.Browser.console;
import js.Error;
import js.node.Fs;
import atom.CompositeDisposable;
import atom.Disposable;
import atom.File;
import atom.TextEditor;
import haxe.Timer;
import om.Time.now;
import om.haxe.ErrorMessage;
import om.util.StringUtil;
import xxx.Server;
//import xxx.atom.CompletionProvider;
import xxx.atom.view.BuildLogView;
import xxx.atom.view.OutlineView;
import xxx.atom.view.StatusBarView;
import xxx.atom.view.ServerLogView;
import Atom.config;
import Atom.notifications;
import Atom.workspace;

using Lambda;
using haxe.io.Path;
using om.io.FileUtil;

typedef State = {
    hxml : String,
    serverlog : Bool,
}

@:keep
class IDE implements om.atom.Package {

    static inline function __init__() untyped module.exports = xxx.atom.IDE;

    public static var hxmlFiles(default,null) : Array<String>;
    public static var hxml(default,null) : File;

    static var statusbar : StatusBarView;
    static var buildlog : BuildLogView;
    //static var outline : OutlineView;
    static var serverlog : ServerLogView;

    //static var server : Server;

    static var cmdBuild : Disposable;
    static var cmdSelectHxml : Disposable;
    static var cmdStartServer : Disposable;
    static var cmdStopServer : Disposable;

    static var disposables : CompositeDisposable;
    static var opener : Disposable;
    static var configChangeListener : Disposable;
    //static var completion : CompletionProvider;

    static function activate( state : xxx.atom.IDE.State ) {

        #if debug
        haxe.Log.trace = __trace;
        #end

        trace( 'Atom-xxx '+state );

        disposables = new CompositeDisposable();

        disposables.add( statusbar = new StatusBarView() );
        disposables.add( buildlog = new BuildLogView() );
        disposables.add( serverlog = new ServerLogView() );
        //outline = new OutlineView();

        searchHxmlFiles(function(files:Array<String>){

            hxmlFiles = files;

            if( state != null && state.hxml != null ) {
                Fs.access( state.hxml, function(e){
                    selectHxml( (e == null) ? state.hxml : hxmlFiles[0] );
                });
            } else {
                selectHxml( hxmlFiles[0] );
            }

            cmdBuild = Atom.commands.add( 'atom-workspace', 'xxx:build', function(e) build() );
            cmdSelectHxml = Atom.commands.add( 'atom-workspace', 'xxx:select-hxml', function(e) {
                //TODO workspace.addModalPanel();
                var treeViewFile = getTreeViewFile( 'hxml' );
                if( treeViewFile != null ) {
                    selectHxml( treeViewFile );
                }
            });

            /*
            //TODO

            for( dir in Atom.project.getDirectories() ) {
                disposables.add( dir.onDidChange(function(){
                    trace("content changed");
                }) );
            }

            //Atom.project.getPaths()
            Atom.project.onDidChangePaths(function(paths){
                for( dir in paths ) {
                    trace(dir);
                }
            });
            */

            if( state != null && state.serverlog ) {
                serverlog.show();
            }
        });

        /*
        server = new Server( getConfigValue( 'haxe_path' ), getConfigValue( 'haxe_server_port' ) );
        server.onStart = function(){
            trace( 'haxe server stared: '+server.port, 'info' );
            disposeCommand( cmdStartServer );
            cmdStopServer = Atom.commands.add( 'atom-workspace', 'xxx:stop-server', function(_) server.stop() );
        }
        server.onData = function(str){
            //trace(str);
            serverlog.add( str );
        }
        server.onError = function(e){
            trace( e, 'error' );
            notifications.addWarning( e );
        }
        server.onStop = function(code){
            trace( 'haxe server stopped: $code', (code == 0) ? 'info' : 'error' );
            disposeCommand( cmdStopServer );
            cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(_) server.start() );
        }

        Timer.delay( function(){
            //trace( 'Starting haxe server ...' );
            //server.start();
        }, getConfigValue( 'haxe_server_startdelay' ) * 1000 );

        cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(e) {
            server.start();
        });
        */

        /*
        var packagePath = Atom.packages.resolvePackagePath( 'xxx' );
        completion = new CompletionProvider( packagePath+'/cache' );

        var buildStartTimestamp : Float;
        project = new Project( Atom.project.getPaths() );
        project.on( 'hxml-select', function(hxml){
            trace(hxml);
            if( hxml == null ) {
                disposeCommand( cmdBuild );
            } else {
                statusbar.setHxml( hxml );
                buildlog.clear();
                if( cmdBuild == null ) {
                    cmdBuild = Atom.commands.add( 'atom-workspace', 'xxx:build', function(e) {
                        if( project.hxml == null ) notifications.addWarning( 'No hxml file selected' ) else {
                            project.build();
                        }
                    });
                }
            }
        });
        project.on( 'build-start', function(hxml:String){
            buildStartTimestamp = now();
            statusbar.setStatus( 'active' );
            buildlog.clear().show();
        });
        project.on( 'build-error', function(error:String){
            statusbar.setStatus( 'error' );
            for( line in error.split( '\n' ) ) {

                if( line.length == 0 )
                    continue;

                var err = ErrorMessage.parse( line );
                if( err == null ) {
                    buildlog.error( line );
                } else {

                    buildlog.errorMessage( err );

                    var lineNumber = err.line - 1;
                    var column = if( err.lines != null )
                        err.lines.start;
                    else if( err.characters != null )
                        err.characters.start;
                    else
                        err.character;

                    workspace.open( err.path, {
                        initialLine: lineNumber,
                        initialColumn: column,
                        activatePane: true,
                        searchAllPanes : true
                    }).then( function(editor:TextEditor){
                        editor.scrollToCursorPosition();
                        //TODO decorate erroposition
                    });
                }
            }
        });

        project.on( 'build-result', function(result:String){
            buildlog.info( result );
        });

        project.on( 'build-end', function(code:Int){

            switch code {
            case 0:
                statusbar.setStatus( 'success' );
            case _:
                statusbar.setStatus( 'error' );
            }

            var buildTime = (now() - buildStartTimestamp) / 1000;
            var buildTimeString = Std.string( buildTime );
            buildTimeString = buildTimeString.substr( 0, buildTimeString.indexOf( '.' )+2 );
            statusbar.setMetaInfo( buildTimeString+'s' );
        });

        initProject( state.hxml );

        configChangeListener = config.onDidChange( 'xxx', {}, function(e){
            /*
            var nv = e.newValue;
            var ov = e.oldValue;
            if( nv.haxe_path != ov.haxe_path ||
            nv.haxe_server_port != ov.haxe_server_port ||
            nv.haxe_server_host != ov.haxe_server_host ) {
            server.stop();
            Timer.delay( startServer, getConfigValue( 'server_startdelay' ) * 1000 );
            }
            * /
        });

        /*
            project.onBuild(

                function(){
                    builStartTime = now();
                    statusbar.setStatus( 'active' );
                    buildlog.clear();
                },

                function(errors:Array<om.haxe.ErrorMessage>){

                    trace("WTF");
                    //trace(errors);

                    /*
                    statusbar.setStatus( 'error' );

                    if( errors == null || errors.length == 0 ) {
                        js.Browser.console.warn( '0 errors ?' );
                        buildlog.show();
                        return;
                    }

                    buildlog.errors( errors ).show();

                    var err = errors[0];
                    var lineNumber = err.line - 1;
                    var column = if( err.lines != null ) err.lines.start;
                        else if( err.characters != null ) err.characters.start;
                        else err.character;

                    workspace.open( err.path, {
                        initialLine: lineNumber,
                        initialColumn: column,
                        activatePane: true,
                        searchAllPanes : true
                    }).then( function(editor:TextEditor){
                        editor.scrollToCursorPosition();
                        //TODO decorate erroposition
                    });

                    //TODO open all errors files
                },

                function(str){

                    var msg = om.haxe.Message.parse( str );
                    buildlog.info( str ).show();

                    //var editor = workspace.getActiveTextEditor();
                    //var lineNumber = msg.line - 1;
                    //var lineText = editor.lineTextForBufferRow( msg.line-1 );

                    //var blockDecoration = new atom.haxe.ide.view.BlockDecorationView( msg.content );
                    //var marker = editor.markBufferPosition( new Point( lineNumber, 0 ) );
                    //editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: blockDecoration.element } );

                    /*
                    var lineNumber = msg.line - 1;
                    var lineText = editor.lineTextForBufferRow( msg.line-1 );
                    var col = lineText.indexOf( 'trace' );
                    var preText = lineText.substr( 0, col );

                    var block = js.Browser.document.createDivElement();
                    block.textContent = preText + ' ' + msg.content;
                    block.classList.add( 'haxe-trace-block-marker' );

                    var marker = editor.markBufferPosition( new Point( lineNumber, 0 ) );
                    editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );
                    * /

                    //editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );
                },

                function(){
                    statusbar.setStatus( 'success' );
                    trace( (now() - builStartTime)/1000 );
                }
            );
        });
        */
    }

    static function serialize() : State {
        return {
            hxml: (hxml == null) ? null : hxml.getPath(),
            serverlog: serverlog.isVisible()
        }
    }

    static function deactivate() {

        if( statusbar != null ) statusbar.dispose();
        //if( buildlog != null ) buildlog.dispose();
        //if( serverlog != null ) serverlog.dispose();

        disposables.dispose();
        //server.dispose();
//        completion.dispose();
    }

    public static inline function getConfigValue<T>( id : String ) : T {
        return Atom.config.get( 'xxx.$id' );
    }

    public static function selectHxml( path : String ) {
        if( path == null ) {
            hxml = null;
        } else {
            if( hxml != null && path == hxml.getPath() ) {
                return;
            }
            trace(":: "+path );
            hxml = new File( path );
            hxml.onDidChange(function(){
                //TODO
            });
            hxml.onDidRename(function(){
                //TODO
                trace("RENAME");
                statusbar.setHxml( hxml );
            });
            hxml.onDidDelete(function(){
                //TODO
                trace("DELETE");
                hxmlFiles.remove( path );
                selectHxml( hxmlFiles[0] );
            });
        }
        statusbar.setHxml( hxml );
    }

    public static function build() {

        if( hxml == null ) {
            trace( 'no hxml file selected', 'warn' );
            return;
        }

        /*
        if( build != null ) {
            trace( 'build already active', 'warn' );
            return;
        }
        */

        //trace( 'Build '+hxml.getPath() );

        buildlog.clear().show();
        statusbar.setStatus( 'active' );

        var cwd = hxml.getParent().getPath();
        var args = [hxml.getBaseName()];
        var build = new Build();
        //builds.push( build );
        //var log = new BuildLogView();
        var timeStart = now();
        build.start( args, { cwd: cwd },
            function(error){
                //buildlog.error( e );
                for( line in error.split( '\n' ) ) {
                    if( line.length == 0 )
                        continue;
                    var err = ErrorMessage.parse( line );
                    if( err == null ) {
                        buildlog.error( line );
                    } else {

                        buildlog.errorMessage( err );

                        var lineNumber = err.line - 1;
                        var column = if( err.lines != null ) err.lines.start;
                        else if( err.characters != null ) err.characters.start;
                        else err.character;

                        workspace.open( err.path, {
                            initialLine: lineNumber,
                            initialColumn: column,
                            activatePane: true,
                            searchAllPanes : true
                        }).then( function(editor:TextEditor){
                            editor.scrollToCursorPosition();
                            //TODO decorate erroposition
                        });
                    }
                }
            },
            function(r){
                buildlog.info( r );
            },
            function(code){
                switch code {
                case 0:
                    statusbar.setStatus( 'success' );
                    var timeTotal = (now() - timeStart) / 1000;
                    var timeTotalStr = StringUtil.parseFloat( timeTotal, 1 ) + 's';
                    statusbar.setMetaInfo( timeTotalStr );
                default:
                    statusbar.setStatus( 'error' );
                }
                build = null;
            }
        );
    }

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusbar.element, priority: -100 } );
    }

    static function provideAutoCompletion() {
        //return getConfigValue( 'autocomplete_enabled' ) ? new atom.haxe.ide.CompletionProvider() : null;
        //return completion;
        return null;
    }

    /*
    static function provideService() {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {
            }
        };
    }
    */

    public static function getTreeViewFile( ?ext : String ) : String {
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
    }

    static inline function disposeCommand( cmd : Disposable ) {
        if( cmd != null ) {
            cmd.dispose();
            cmd = null;
        }
    }

    static function searchHxmlFiles( ?paths : Array<String>, callback : Array<String>->Void )
        __searchHxmlFiles( (paths == null) ? Atom.project.getPaths() : paths, [], callback );

    static function __searchHxmlFiles( paths : Array<String>, found : Array<String>, callback : Array<String>->Void ) {
        if( paths.length == 0 ) callback( found ) else {
            var path = paths.shift();
            Fs.readdir( path, function(err,entries){
                if( err != null ) notifications.addError( Std.string(err), null ) else {
                    for( e in entries ) {
                        if( e.charAt(0) == '.' )
                            continue;
                        var p = '$path/$e';
                        p.isDirectorySync() ? paths.push(p) : if( e.extension() == 'hxml' ) found.push(p);
                    }
                    __searchHxmlFiles( paths, found, callback );
                }
            });
        }
    }

    #if debug

    static function __trace( v : Dynamic, ?pos : haxe.PosInfos ) {
        var posString = pos.fileName + ':' + pos.lineNumber + ': ';
        var posStyle = 'color:#777;';
        var style = 'color:#000;';
        var out = '%c$posString%c$v';
        if( pos.customParams != null && pos.customParams.length > 0 ) {
            var param = pos.customParams[0];
            switch param {
                case 'log': console.debug( out );
                case 'debug': console.debug( out );
                case 'info': console.info( out );
                case 'warn': console.warn( out );
                case 'error': console.error( out );
                case _: console.log( out, posStyle, style );
            }
        } else {
            console.log( out, posStyle, style );
        }
    }

    #end
}
