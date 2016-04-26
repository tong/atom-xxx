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

@:enum abstract ProjectEvent(Int) from Int to Int {
    var hxml_select = 0;
}

@:keep
class Project  {

    public var paths(default,null) : Array<String>;
    public var hxmlFiles(default,null) : Array<String>;
    public var hxml(default,null) : String;
    public var cwd(default,null) : String;
    //public var errors(default,null) : Array<Error>;

    //var disposables : CompositeDisposable;
    var emitter : Emitter;
    var builds : Map<String,Build>;

    public function new( paths : Array<String> ) {
        this.paths = paths;
        emitter = new Emitter();
        builds = new Map();
    }

    public inline function on<T>( eventName : String, callback : T->Void ) : Project {
        emitter.on( eventName, callback );
        return this;
    }

    public function dispose() {
        emitter.dispose();
        //disposables.dispose();
    }

    public function selectHxml( file : String ) {
        trace( 'Select hxml: $file' );
        hxml = file;
        cwd = hxml.directory();
        emitter.emit( 'hxml-select', hxml );
    }

    public function build( ?extraParams : Array<String>, ?procOpts : ChildProcessSpawnOptions ) {

        if( hxml == null )
            throw 'no hxml file selected';

        var hxmlFile = hxml;
        var args = [hxmlFile];
        if( extraParams != null ) args = args.concat( extraParams  );

        var cwd = hxmlFile.directory();
        if( procOpts == null ) procOpts = { cwd: cwd };
        else if( procOpts.cwd == null )  procOpts.cwd = cwd;

        var build = new Build( Atom.config.get( 'xxx.haxe_path' ) );
        builds.set( hxmlFile, build );
        build.start( args, procOpts,
            function(error){
                emit( 'build-error', error );
            },
            function(result){
                emit( 'build-result', result );
            },
            function(code){
                builds.remove( hxmlFile );
                switch code {
                case 0:
                default:
                }
                emit( 'build-end', code );

            }
        );
        emit( 'build-start', hxml );
    }

    inline function emit<T>( eventName : String, data : T )
        emitter.emit( eventName, data );

    /*
    function handleProjectPathsChanged( changed : Array<String> ) {
        var added = new Array<String>();
        var removed = new Array<String>();
        for( path in changed ) if( !paths.has( path ) ) added.push( path );
        for( path in paths ) if( !changed.has( path ) ) removed.push( path );
        paths = changed;
        */
        //emitter.emit( 'did-change-paths', { added: added, removed: removed } );
        /*
        if( removed.has( hxmlFile ) ) {
            hxmlFile =
        }
    }
    */
}
