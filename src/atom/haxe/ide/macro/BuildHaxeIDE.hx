package atom.haxe.ide.macro;

import sys.FileSystem;
import sys.io.File;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.Json;

using Lambda;

class BuildHaxeIDE {

    static function build() : Array<Field> {
        var fields = Context.getBuildFields();
        var pos = Context.currentPos();
        var pkg = Json.parse( File.getContent( Sys.getCwd()+'package.json' ) );
        fields.push({
            access: [APublic,AStatic,AInline],
            name: 'version',
            kind: FVar( macro : String, macro $v{pkg.version} ),
            pos: pos,
            meta: [
                { name:':keep', pos: pos },
                { name:':expose', pos: pos }
            ]
        });
        return fields;
    }
}
