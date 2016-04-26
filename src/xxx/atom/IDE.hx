package xxx.atom;

import js.Browser.console;
import js.Error;
import js.node.Fs;
import haxe.Timer;
import atom.Disposable;
import atom.TextEditor;
import om.Time.now;
import om.haxe.ErrorMessage;
import xxx.Server;
import xxx.atom.view.BuildLogView;
import xxx.atom.view.OutlineView;
import xxx.atom.view.StatusBarView;
import xxx.atom.view.ServerLogView;
import xxx.atom.CompletionProvider;
import Atom.config;
import Atom.notifications;
import Atom.workspace;

using Lambda;
using haxe.io.Path;
using om.io.FileUtil;

typedef State = {
    var hxml : String;
    //var server : String;
}

@:keep
@:access(xxx.atom.Project)
class IDE implements om.atom.Package {

    static inline function __init__() untyped module.exports = xxx.atom.IDE;

    public static var server(default,null) : Server;
    public static var project(default,null) : Project;

    static var statusbar : StatusBarView;
    static var buildlog : BuildLogView;
    static var outline : OutlineView;
    static var serverlog : ServerLogView;

    static var cmdBuild : Disposable;
    static var cmdSelectHxml : Disposable;
    static var cmdStartServer : Disposable;
    static var cmdStopServer : Disposable;

    static var configChangeListener : Disposable;
    static var opener : Disposable;
    static var completion : CompletionProvider;

    static function activate( state : xxx.atom.IDE.State ) {

        #if debug
        haxe.Log.trace = __trace;
        trace( 'Atom-xxx '+state );
        #end

        statusbar = new StatusBarView();
        buildlog = new BuildLogView();
        outline = new OutlineView();
        serverlog = new ServerLogView();

        server = new Server( config.get( 'xxx.haxe_path' ), config.get( 'xxx.haxe_server_port' ) );
        server.onStart = function(){

            trace( 'haxe server stared: '+server.port, 'info' );

            disposeCommand( cmdStartServer );
            cmdStopServer = Atom.commands.add( 'atom-workspace', 'xxx:stop-server', function(_) server.stop() );

        }
        server.onData = function(str){
            trace(str);
            serverlog.add(str);
        }
        server.onError = function(msg){
            trace( msg, 'error' );
            notifications.addWarning( msg );
        }
        server.onStop = function(code){
            trace( 'haxe server stopped: $code', (code == 0) ? 'info' : 'error' );
            disposeCommand( cmdStopServer );
            cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(_) server.start() );
        }

        cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(e) {
            server.start();
        });

        var packagePath = Atom.packages.resolvePackagePath( 'xxx' );
        completion = new CompletionProvider( packagePath+'/cache' );

        var buildStartTime : Float;

        project = new Project( Atom.project.getPaths() );

        project.on( 'hxml-select', function(hxml){
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
            statusbar.setStatus( 'active' );
            buildlog.clear().show();
            buildStartTime = now();
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
            var time = Std.string( (now() - buildStartTime ) );
            time = time.substr( 0, time.indexOf('.') );
            statusbar.setMeta( time );
        });

        configChangeListener = Atom.config.onDidChange( 'xxx', {}, function(e){
            /*
            var nv = e.newValue;
            var ov = e.oldValue;
            if( nv.haxe_path != ov.haxe_path ||
                nv.haxe_server_port != ov.haxe_server_port ||
                nv.haxe_server_host != ov.haxe_server_host ) {
                    server.stop();
                    Timer.delay( startServer, getConfigValue( 'server_startdelay' ) * 1000 );
                }
                */
        });

        initProject( state.hxml );

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
            hxml: project.hxml,
            //server:
        }
    }

    static function deactivate() {
        if( statusbar != null ) statusbar.destroy();
        if( buildlog != null ) buildlog.destroy();
        if( serverlog != null ) serverlog.destroy();
        server.dispose();
        completion.dispose();
    }

    static function initProject( ?hxmlFile : String ) {
        searchHxmlFiles( project.paths, function(e,found){
            if( e != null ) {
                trace( e, 'error' );
                notifications.addError( Std.string( e ) );
            } else {
                project.hxmlFiles = found;
                if( found.length > 0 ) {
                    project.selectHxml(
                        if( hxmlFile != null && project.hxmlFiles.has( hxmlFile ) )
                            hxmlFile
                        else
                            found[0]
                    );
                    if( cmdSelectHxml == null ) {
                        cmdSelectHxml = Atom.commands.add( 'atom-workspace', 'xxx:select-hxml', function(e) {
                            trace(e);
                            trace(e.target);
                            //TODO workspace.addModalPanel();
                            var treeViewFile = getTreeViewFile( 'hxml' );
                            if( treeViewFile != null ) {
                                project.selectHxml( treeViewFile );
                            }
                        });
                    }
                }
            }
        });
    }

    /*
    static function provideService() {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {
            }
        };
    }
    */

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusbar.element, priority:-100 } );
    }


    static function provideAutoCompletion() {
        //return getConfigValue( 'autocomplete_enabled' ) ? new atom.haxe.ide.CompletionProvider() : null;
        return completion;
    }

    public static inline function getConfigValue<T>( id : String ) : T
        return Atom.config.get( 'xxx.$id' );

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

    static function searchHxmlFiles( ?paths : Array<String>, callback : Error->Array<String>->Void )
        __searchHxmlFiles( (paths == null) ? Atom.project.getPaths() : paths, [], callback );

    static function __searchHxmlFiles( paths : Array<String>, found : Array<String>, callback : Error->Array<String>->Void ) {
        if( paths.length == 0 ) callback( null, found ) else {
            var path = paths.shift();
            Fs.readdir( path, function(err,entries){
                if( err != null ) callback( err, null ) else {
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
