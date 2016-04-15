package xxx.atom;

import js.Browser.console;
import Atom.config;
import Atom.workspace;
import atom.TextEditor;
import haxe.Timer;
import om.Time.now;
import xxx.Server;
import xxx.atom.Project;
import xxx.atom.view.BuildLogView;
import xxx.atom.view.OutlineView;
import xxx.atom.view.StatusBarView;
import xxx.atom.view.ServerLogView;

using haxe.io.Path;

typedef State = {
    var hxml : String;
}

@:keep
class IDE implements om.atom.Package {

    static inline function __init__() untyped module.exports = xxx.atom.IDE;

    public static var server(default,null) : Server;
    public static var project(default,null) : Project;

    static var statusbar : StatusBarView;
    static var buildlog : BuildLogView;
    static var outline : OutlineView;
    static var serverlog : ServerLogView;

    static function activate( state : State ) {

        #if debug
        haxe.Log.trace = __trace;
        trace( 'Atom-xxx '+state );
        #end

        statusbar = new StatusBarView();
        buildlog = new BuildLogView();
        outline = new OutlineView();
        serverlog = new ServerLogView();

        Project.init( state, function(p){

            project = p;

            if( project.hxml != null ) {
                statusbar.setHxmlPath( project.hxml );
            }

            project.onDidChangeHxml(function(hxml){
                statusbar.setHxmlPath( hxml );
            });

            var builStartTime : Float;

            project.onBuild(

                function(){
                    builStartTime = now();
                    statusbar.setStatus( 'active' );
                    buildlog.clear();
                },

                function(errors){

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
                    */

                    //editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );
                },

                function(){
                    statusbar.setStatus( 'success' );
                    trace( (now() - builStartTime)/1000 );
                }
            );

            server = new Server( config.get( 'xxx.haxe_path' ), config.get( 'xxx.haxe_server_port' ) );
            server.onStart = function(){
                trace("server stared");
            }
            server.onError = function(str){
                trace(str);
            }
            server.onData = function(str){
                trace(str);
                serverlog.add(str);
            }

            Atom.commands.add( 'atom-workspace', 'xxx:start-server', function(e) {
                if( server != null && !server.active ) {
                    trace(">>");
                    server.start();
                }
            });
            Atom.commands.add( 'atom-workspace', 'xxx:stop-server', function(e) {
                if( server != null && server.active ) {
                    server.stop();
                }
            });
        });
    }

    static function serialize() {
        if( project == null )
            return {};
        return {
            project.serialize();
        }
    }

    static function deactivate() {
        if( statusbar != null ) statusbar.destroy();
        if( buildlog != null ) buildlog.destroy();
        server.dispose();
    }

    static function provideService() {
        return {
            build : function( args:Array<String>, onMessage : String->Void, onError : String->Void, onSuccess : Void->Void ) {
                //var build = new Build( Atom.config.get( 'haxe.exe' ) );
            }
        };
    }

    static function consumeStatusBar( bar ) {
        bar.addLeftTile( { item: statusbar.element, priority:-10 } );
    }

    public static inline function getConfigValue<T>( id : String ) : T {
        return Atom.config.get( 'xxx.'+id );
    }

    public static function getTreeViewFile( ?ext : String ) : String {
        var path : String = Atom.packages.getLoadedPackage( 'tree-view' ).serialize().selectedPath;
        return (ext == null || (path != null && path.extension() == ext)) ? path : null;
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
