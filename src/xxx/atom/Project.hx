package xxx.atom;

import js.node.Fs;
import js.node.ChildProcess;
import atom.CompositeDisposable;
import atom.Disposable;
import atom.Emitter;
import atom.TextEditor;
import Atom.commands;
import Atom.notifications;
import Atom.workspace;
import om.haxe.Hxml;
import om.haxe.ErrorMessage;
import xxx.atom.IDE;

using Lambda;
using StringTools;
using haxe.io.Path;
using om.io.FileUtil;

@:keep
class Project  {

    public var paths(default,null) : Array<String>;
    public var hxmlFiles(default,null) : Array<String>;
    public var hxml(default,null) : String;
    public var cwd(default,null) : String;
    //public var errors(default,null) : Array<Error>;

    var disposables : CompositeDisposable;
    var emitter : Emitter;
    var cmdBuild : Disposable;
    var cmdSelect : Disposable;
    //var builds : Array<Build>;
    //var blockDecorations :

    function new( paths : Array<String>, hxmlFiles : Array<String> ) {

        //this.paths = Atom.project.getPaths();
        //this.hxmlFiles = [];
        this.paths = paths;
        this.hxmlFiles = hxmlFiles;

        disposables = new CompositeDisposable();

        emitter = new Emitter();
        disposables.add( emitter );

        cmdBuild = commands.add( 'atom-workspace', 'xxx:build', function(_) {
            build();
        } );
        disposables.add( cmdBuild );

        cmdSelect = commands.add( 'atom-workspace', 'xxx:select-hxml', function(e) {
            trace(e);
            if( e.target != null ) {
                var p = untyped e.target.getAttribute( 'data-path' );
                selectHxmlFile( p );
            }
        } );
        disposables.add( cmdSelect );

        disposables.add( Atom.project.onDidChangePaths( handleProjectPathsChanged ) );
    }

    public inline function onDidChangeHxml( callback : String->Void ) : Project {
        emitter.on( 'hxml-select', callback );
        return this;
    }

    public inline function onBuild( start : Void->Void, error : Array<ErrorMessage>->Void, message : String->Void, success : Void->Void ) : Project {
        emitter.on( 'build-start', untyped start );
        emitter.on( 'build-message', message );
        emitter.on( 'build-error', error );
        emitter.on( 'build-success', untyped success );
        return this;
    }

    public function dispose() {
        disposables.dispose();
        emitter.dispose();
    }

    public function serialize() {
        return {
            hxml : hxml
        };
    }

    public function selectHxmlFile( hxmlPath : String ) {

        hxml = hxmlPath;
        cwd = hxml.directory();

        emitter.emit( 'hxml-select', hxml );
    }

    public function build( ?extraParams : Array<String>, ?procOpts : ChildProcessSpawnOptions ) {

        if( hxml == null ) {
            notifications.addWarning( 'No hxml file selected' );
            return;
        }

        if( procOpts == null )
            procOpts = { cwd:cwd }
        else if( procOpts.cwd == null )
            procOpts.cwd = cwd;

        //this.errors = [];
        //this.blockDecorations.clear();
        //var tokens = Hxml.parseTokens( r );

        var hxmlPath = hxml.withoutDirectory();
        var args = [hxmlPath];
        if( extraParams != null ) args = args.concat( extraParams  );

        var build = new Build( Atom.config.get( 'xxx.haxe_path' ) );

        build.onError = function(e) {

            e = e.trim();

            var errors = new Array<BuildError>();
            for( line in e.split( '\n' ) ) {
                var e = om.haxe.ErrorMessage.parse( line );
                if( e == null ) {
                    trace( '??? error null line' );
                } else {
                    errors.push( new BuildError( e.content, e.path, e.line, e.characters.start, e.characters.end ) );
                }
            }

            emitter.emit( 'build-error', errors );
        }

        build.onData = function(e) {
            e = e.trim();
            //trace(e);
            //trace(e.split('\n'));
            emitter.emit( 'build-message', e );
        }

        build.onEnd = function( code : Int ) {
            switch code {
            case 0:
                emitter.emit( 'build-success' );
            case _:
                emitter.emit( 'build-error' );
            }
        }

        if( procOpts.cwd == null ) procOpts.cwd = cwd;

        trace( 'Building '+hxml );

        build.start( args, procOpts );

        emitter.emit( 'build-start' );
    }

    function handleProjectPathsChanged( changed : Array<String> ) {

        var added = new Array<String>();
        var removed = new Array<String>();
        for( path in changed ) {
            if( !paths.has( path ) )
                added.push( path );
        }
        for( path in paths ) {
            if( !changed.has( path ) )
                removed.push( path );
        }
        paths = changed;

        emitter.emit( 'did-change-paths', { added: added, removed: removed } );

        /*
        if( removed.has( hxmlFile ) ) {
            hxmlFile =
        }
        */
    }

    static inline function searchHxmlFiles( ?paths : Array<String>, callback : Array<String>->Void ) {
        _searchHxmlFiles( (paths == null) ? Atom.project.getPaths() : paths, [], callback );
    }

    static function _searchHxmlFiles( paths : Array<String>, found : Array<String>, callback : Array<String>->Void ) {
        if( paths.length == 0 ) callback( found ) else {
            var path = paths.shift();
            Fs.readdir( path, function(err,entries){
                for( e in entries ) {
                    if( e.charAt(0) == '.' )
                        continue;
                    var p = '$path/$e';
                    p.isDirectorySync() ? paths.push(p) : if( e.extension() == 'hxml' ) found.push(p);
                }
                _searchHxmlFiles( paths, found, callback );
            });
        }
    }

    public static function init( state : xxx.atom.IDE.State, callback : Project->Void ) {

        var paths = Atom.project.getPaths();

        searchHxmlFiles( function(found){

            var project = new Project( paths, found );

            var hxml : String = null;
            if( state != null && state.hxml != null && project.hxmlFiles.has( state.hxml ) ) {
                hxml = state.hxml;
            } else {
                hxml = found[0];
            }
            project.selectHxmlFile( hxml );

            callback( project );
        });
    }
}

@:allow(xxx.atom.Project) private class BuildError {

    public var message : String;
    public var file : String;
    public var line : Int;
    public var start : Int;
    public var end : Int;

    function new( message : String, file : String, line : Int, start : Int, end : Int ) {
        this.message = message;
        this.file = file;
        this.line = line;
        this.start = start;
        this.end = end;
    }
}
