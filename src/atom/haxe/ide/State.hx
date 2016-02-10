package atom.haxe.ide;

import sys.io.File;
import haxe.Hxml;

using haxe.io.Path;
using sys.FileSystem;

private typedef TState = {
    var hxml : String;
    var dir : String;
}

@:keep
class State {

    public var hxml(default,null) : String;
    public var dir(default,null) : String;
    //public var tokens(default,null) : Array<String>;
    //public var isDebug(default,null) : Bool;

    public function new( state : TState ) {
        if( state != null && state.hxml.exists() && state.dir.exists() ) {
            set( state.hxml, state.dir );
        }
    }

    public inline function set( hxml : String, dir : String ) {
        this.hxml = hxml;
        this.dir = dir;
        //tokens = Hxml.parseTokens( File.getContent( hxml ) );
        //isDebug = hasToken( '-debug' );
    }

    public inline function setPath( hxmlFilePath : String ) {
        set( hxmlFilePath, hxmlFilePath.directory() );
    }

    public function serialize() {
        return {
            hxml: hxml,
            dir: dir
        };
    }

    /*
    public function hasToken( token : String ) : Bool {
        return Lambda.has( tokens, token );
    }
    */
}
