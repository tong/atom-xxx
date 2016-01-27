package atom.haxe.ide;

using haxe.io.Path;
using sys.FileSystem;

private typedef TState = {
    var hxml : String;
    var dir : String;
}

@:keep
class State {

    public var hxml : String;
    public var dir : String;

    public function new( state : TState ) {
        if( state != null && state.hxml.exists() && state.dir.exists() ) {
            set( state.hxml, state.dir );
        }
    }

    public inline function set( hxml : String, dir : String ) {
        this.hxml = hxml;
        this.dir = dir;
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
}
