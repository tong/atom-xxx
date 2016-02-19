package atom.haxe.ide;

import js.node.Net;
import js.node.net.Socket;
import js.node.ChildProcess.spawn;

using StringTools;

class Completion {

    static var NEWLINE = "\n";
    /*

    var socket : Socket;

    public function new() {
    }

    public function fieldAccess( cwd : String, file : String, pos : Int, ?mode : String, ?extraArgs : Array<String>, callback : String->Void ) {

        //if( socket == null ) {

            socket = Net.createConnection( 7000, function(){

                socket.on( 'data', function(e) {
                    var r : String = e.toString();
                    /*
                    for( line in r.split( NEWLINE ) ) {
                        //trace(line.charCodeAt(0));
                        switch line.charCodeAt(0) {
                        case 0x01:
                            Sys.print( line.substr(1).split( "\x01" ).join( NEWLINE ) );
                        case 0x02:
                            Sys.print( line+NEWLINE );
                        }
                    }
                    * /
                    callback(r);
                });

                request( cwd, file, pos, mode, extraArgs );
            });

        //} else {
        ////    request( cwd, file, pos, mode, extraArgs );
        //}
    }

    function request( cwd : String, file : String, pos : Int, ?mode : String, ?extraArgs : Array<String> ) {

        var args = new Array<String>();

        args.push( '--cwd' );
        args.push( cwd );

        args.push( '--no-output' );

        args.push( '--display' );
        var posArg = '$file@$pos';
        if( mode != null ) posArg += '@$mode';
        args.push( posArg );

        args.push( '-D' );
        args.push( 'display-details' );

        if( extraArgs != null ) args = args.concat( extraArgs );

        //args.push( String.fromCharCode(0) );
        //trace( args.join(" ") );

        var cmd = '';
        for( arg in args ) {
            cmd += (arg.startsWith('-') ? NEWLINE : ' ') + arg;
        }
        trace(cmd);
//
        socket.write( cmd + String.fromCharCode(0) );
        //socket.write( cmd );
    }
    */

    public static function fieldAccess( cwd : String, file : String, pos : Int, ?mode : String, ?extraArgs : Array<String>, callback : String->Void ) {
        run( cwd , file, pos,  null, extraArgs, callback );
    }

    public static function callArgument( cwd : String, file : String, pos : Int, ?mode : String, ?extraArgs : Array<String>, callback : String->Void ) {
        run( cwd , file, pos,  null, extraArgs, callback );
    }

    static function run( cwd : String, file : String, pos : Int, ?mode : String, ?extraArgs : Array<String>, callback : String->Void ) {

        //var args = ['--connect','7000']; // HaxeIDE.server.getHaxeFlag(); //new Array<String>();
        var args = new Array<String>();

        args.push( '--cwd' );
        args.push( cwd );

        args.push( '--no-output' );

        args.push( '--display' );
        var posArg = '$file@$pos';
        if( mode != null ) posArg += '@$mode';
        args.push( posArg );

        args.push( '-D' );
        args.push( 'display-details' );

        if( extraArgs != null ) args = args.concat( extraArgs );

        trace( args.join(" ") );

        var out : String = '';
        var err : String = '';
        //var proc = spawn( 'haxe', args, { cwd: cwd } );

        var proc = spawn( 'haxe', args );
        proc.stdout.on( 'data', function(e) out += e.toString() );
        proc.stderr.on( 'data', function(e) err += e.toString() );
        proc.on( 'exit', function(code:Int) {
            //trace(out.length+":"+err.length);
            //trace(code+":   "+out.length);
            //trace(err);
            switch code {
            case 0:
                callback( err );
            case 1:
                trace( err );
                //callback( err );
                //var xml = Xml.parse( xml ).firstElement();
            default:
                trace("? "+code );
                //onError( error );
            }
        });
    }
}
