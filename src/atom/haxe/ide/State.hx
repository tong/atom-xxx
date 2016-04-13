package atom.haxe.ide;

import sys.io.File;
import om.haxe.Hxml;

using haxe.io.Path;
using sys.FileSystem;

private typedef TState = {
    var cwd : String;
    var hxml : String;
}

@:keep
class State {

    public var cwd(default,null) : String;
    public var hxml(default,null) : String;
    public var args(default,null) : Array<String>;
    public var isDebug(get,null) : Bool;

    public function new( state : TState ) {
        trace(state);
        if( state != null && state.cwd.exists() && state.hxml.exists() ) {
            set( state.cwd, state.hxml );
        }
    }

    inline function get_isDebug() : Bool return hasToken( '-debug' );

    public inline function set( cwd : String, hxml : String ) {

        this.cwd = cwd;
        this.hxml = hxml;

        args = Hxml.parseTokens( File.getContent( hxml ) );
        //isDebug = hasToken( '-debug' );
    }

    public inline function setHxml( path : String ) {
        set( path.directory(), path );
    }

    public inline function hasToken( token : String ) : Bool {
        return Lambda.has( args, token );
    }

    public inline function getDefine( token : String ) : Bool {
        return Lambda.has( args, token );
    }

    public function serialize() {
        return {
            cwd: cwd,
            hxml: hxml
        };
    }
}
