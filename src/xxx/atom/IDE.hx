package xxx.atom;

import js.Browser.console;
import js.Error;
import js.node.Fs;
import atom.CompositeDisposable;
import atom.Disposable;
import atom.File;
import atom.Point;
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
import xxx.atom.view.BlockDecorationView;
import Atom.config;
import Atom.notifications;
import Atom.workspace;

using Lambda;
using StringTools;
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

    static var server : Server;

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
        //haxe.Log.trace = __trace;
        #end

        //trace( 'Atom-xxx '+state );

        disposables = new CompositeDisposable();

        disposables.add( statusbar = new StatusBarView() );
        disposables.add( buildlog = new BuildLogView() );
        disposables.add( serverlog = new ServerLogView() );
        //outline = new OutlineView();

        /*
        server = new Server( getConfigValue( 'haxe_path' ), getConfigValue( 'haxe_server_port' ) );
        server.onStart = function(){
            trace( 'haxe server stared: '+server.port, 'info' );
            statusbar.setServerInfo( server.port );
            disposeCommand( cmdStartServer );
            cmdStopServer = Atom.commands.add( 'atom-workspace', 'xxx:stop-server', function(_) server.stop() );
        }
        server.onData = function(str){
            trace(str);
            serverlog.add( str );
        }
        server.onError = function(e){
            trace( e, 'error' );
            notifications.addWarning( e );
        }
        server.onStop = function(code){
            trace(code);
            switch code {
            case 0:
                trace( 'haxe server stopped '+code, 'debug' );
            default:
                trace( 'haxe server stopped '+code, 'debug' );
            }
            disposeCommand( cmdStopServer );
            cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(_) server.start() );
        }

        if( getConfigValue( 'haxe_server_autostart' ) ) {
            Timer.delay( function(){
                //trace( 'Starting haxe server ...' );
                trace( 'Starting haxe server '+server.port );
                server.start();
            }, getConfigValue( 'haxe_server_startdelay' ) * 1000 );
        }
        */

        cmdStartServer = Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(_) server.start() );

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
                */
            });

            if( state != null && state.serverlog ) {
                serverlog.show();
            }
        });

        /*
        //var packagePath = Atom.packages.resolvePackagePath( 'xxx' );

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
        if( buildlog != null ) buildlog.dispose();
        if( serverlog != null ) serverlog.dispose();

        disposables.dispose();
        server.dispose();
        //completion.dispose();
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
        statusbar.setStatus();
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
        //args.push('-v');
        var build = new Build();
        //builds.push( build );
        //var log = new BuildLogView();
        var timeStart = now();
        build.start( args, { cwd: cwd },
            function(error){

                var prevLine : String = null;

                for( line in error.split( '\n' ) ) {

                    if( line.length == 0 )
                        continue;
                    if( line == prevLine )
                        continue;
                    prevLine = line;
                    var msg = ErrorMessage.parse( line );
                    if( msg == null ) {
                        trace( 'failed to parse compiler error message : '+line, 'warn' );
                        buildlog.error( line );
                    } else {

                        var filePath = msg.path;
                        //if( !filePath.isAbsolute( filePath ) ) filePath = ''
                        //var filePath = msg.path.startsWith( '/' ) ? msg.path : cwd + '/' + msg.path;
                        if( !new File(filePath).existsSync() ) {
                            filePath = cwd+'/'+filePath;
                            /*
                            if( !new File(filePath).existsSync() ) {
                                filePath = cwd+'/src/'+filePath;
                            }
                            */
                        }
                        if( !new File( filePath ).existsSync() ) {
                            trace( "file not found: "+filePath );
                            return;
                        }
                        msg.path = filePath;

                        buildlog.errorMessage( msg );

                        var lineNumber = msg.line - 1;
                        var column = if( msg.lines != null ) msg.lines.start;
                        else if( msg.characters != null ) msg.characters.start;
                        else msg.character;

                        trace(">>>> "+filePath );

                        workspace.open( filePath, {
                            initialLine: lineNumber,
                            initialColumn: column,
                            activatePane: true,
                            searchAllPanes : true
                        }).then( function(editor:TextEditor){

                            //editor.scrollToCursorPosition();
                            //TODO mark gutter

                            //var marker = editor.markBufferPosition( [lineNumber,0] );
                            //var marker = editor.markRange( editor.characterIndexForPosition( [lineNumber,0] ) );

                            /*
                            var gutter = editor.addGutter({
                                name: "haxe-error-1"
                            });
                            var deco = gutter.decorateMarker( marker, { type: 'gutter' } );
                            trace(gutter.isVisible());
                            */

                            /*
                            //TODO decorate erroposition
                            var lineText = editor.lineTextForBufferRow( msg.line-1 );
                            trace(lineText);

                            var blockDecoration = new BlockDecorationView( 'error', msg.content );
                            var marker = editor.markBufferPosition( new Point( lineNumber, 0 ) );
                            editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: blockDecoration.element } );
                            */

                        });
                    }
                }
            },
            function(str){

                var msg = om.haxe.Message.parse( str );
                buildlog.info( str ).show();

                /*
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
                */

                //editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );

                buildlog.info( str );
                //serverlog.add(r);
            },
            function(code){
                switch code {
                case 0:
                    statusbar.setStatus( 'success' );
                    var timeTotal = (now() - timeStart) / 1000;
                    var timeTotalStr = StringUtil.parseFloat( timeTotal, 1 ) + 's';
                    statusbar.setMetaInfo( timeTotalStr );

                    buildlog.scrollToBottom();

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

    /*
    #if debug

    static function __trace( v : Dynamic, ?pos : haxe.PosInfos ) {
        var posString = pos.fileName + ':' + pos.lineNumber + ': ';
        var posStyle = 'color:#777;';
        var style = 'color:#000;';
        var out = posString+v;//'$posString$v';
        if( pos.customParams != null && pos.customParams.length > 0 ) {
            var param = pos.customParams[0];
            switch param {
                case 'log': console.debug( out );
                case 'debug': console.debug( out );
                case 'info': console.info( out );
                case 'warn': console.warn( out );
                case 'error': console.error( out );
                case _: //console.log( out, posStyle, style );
                case _: console.log( out );
            }
        } else {
            console.log( out, posStyle, style );
        }
    }

    #end
    */
}
