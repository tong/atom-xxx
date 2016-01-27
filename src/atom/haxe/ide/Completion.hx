package atom.haxe.ide;

import js.node.ChildProcess.spawn;

class Completion {

    public static function fetch( cwd : String, hxml : String, file : String, pos : Int, mode : String, extraArgs : Array<String>,
    //public static function fetch( hxml : String, file : String, pos : Int, mode : String, extraArgs : Array<String>,
                                  onResult : Xml->Void, onError : String->Void ) {

        var args = new Array<String>();

        args.push( '--cwd' );
        args.push( cwd );

        args.push( hxml );

        args.push( '--no-output' );

        args.push( '--display' );
        var posArg = '$file@$pos';
        if( mode != null ) posArg += '@$mode';
        args.push( posArg );

        args.push( '-D' );
        args.push( 'display-details' );

        //args.push('--connect');
        //args.push(''+port);

        if( extraArgs != null ) args = args.concat( extraArgs );

        trace(args);

        var result : String = null;
        var error : String = null;
        //var proc = spawn( 'haxe', args, { cwd: cwd } );
        var proc = spawn( 'haxe', args );
        proc.stdout.on( 'data', function(e) result = e.toString() );
        proc.stderr.on( 'data', function(e) error = e.toString() );
        proc.on( 'exit', function(code) {
            switch code {
            case 0:
                var xml = Xml.parse( error ).firstElement();
                onResult( xml );
            default:
                onError( error );
            }
        });
    }
}
