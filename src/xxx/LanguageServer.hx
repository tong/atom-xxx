package xxx;

import js.Browser.console;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.child_process.ChildProcess as Process;
import js.node.child_process.ChildProcess.ChildProcessEvent;
import js.node.stream.Readable;

using StringTools;

class LanguageServer {

	public var haxePath(default,null) : String;
	public var verbose : Bool;

	var proc : Process;
	var buffer : MessageBuffer;
	var nextMessageLength : Int;
	var currentRequest : DisplayRequest;
	var requestsHead:DisplayRequest;
    var requestsTail:DisplayRequest;

	public function new( haxePath = 'haxe', verbose = true ) {
		this.haxePath = haxePath;
		this.verbose = verbose;
	}

	public function start( callback : Void->Void ) {

		stop();

		buffer = new MessageBuffer();
		nextMessageLength = -1;

		var args = ['-v','--wait','stdio'];

		// TODO
		// HACK
		var cwd = Atom.project.getPaths()[0];
		if( sys.FileSystem.exists( '$cwd/src' ) ) cwd += '/src';

		proc = ChildProcess.spawn( haxePath, args, { cwd: cwd } );
		proc.on( ChildProcessEvent.Exit, handleExit );
		proc.stderr.on( ReadableEvent.Data, handleData );
		proc.stdout.on( ReadableEvent.Data, function(buf:Buffer) {
			//console.debug( buf.toString() );
        });

		callback();
	}

	public function stop() {
		if( proc != null ) {
            proc.removeAllListeners();
            proc.kill();
            proc = null;
        }
		var req = requestsHead;
        while( req != null ) {
            req.processResult( null );
            req = req.next;
        }
        requestsHead = requestsTail = currentRequest = null;
	}

	public function query( args : Array<String>, content : String, onResult : String->Void, onError : String->Void ) {

		trace(args);

		var req = new DisplayRequest( args, content, onResult, onError );
		if( requestsHead == null ) {
            requestsHead = requestsTail = req;
		} else {
			requestsTail.next = req;
            req.prev = requestsTail;
            requestsTail = req;
		}
		checkQueue();
	}

	function checkQueue() {
        if( currentRequest != null )
            return;
        if( requestsHead != null ) {
            currentRequest = requestsHead;
            requestsHead = currentRequest.next;
            proc.stdin.write( currentRequest.prepareBody() );
        }
    }

	function handleData( buf : Buffer ) {
		buffer.append( buf );
		while( true ) {
			if( nextMessageLength == -1 ) {
				var length = buffer.tryReadLength();
				if( length == -1 )
					return;
				nextMessageLength = length;
			}
			var msg = buffer.tryReadContent( nextMessageLength );
			if( msg == null )
				return;
			nextMessageLength = -1;
			if( currentRequest != null ) {
				var request = currentRequest;
                currentRequest = null;
				request.processResult( msg );
                checkQueue();
			}
		}
	}

	function handleExit(a,b) {
		//TODO
	   trace("Haxe process was killed");
	   trace(a);
	   trace(b);
	}
}

private class MessageBuffer {

	var size : Int;
	var buffer : Buffer;
	var index : Int;

	public function new( size = 8192 ) {
		this.size = size;
		this.buffer = new Buffer( size );
		this.index = 0;
	}

	public function append( chunk : Buffer ) {
		if( buffer.length - index >= chunk.length ) {
            chunk.copy( buffer, index, 0, chunk.length );
        } else {
            var nsize = (Math.ceil((index + chunk.length) / size) + 1) * size;
            if( index == 0 ) {
                buffer = new Buffer( nsize );
                chunk.copy( buffer, 0, 0, chunk.length );
            } else {
                buffer = Buffer.concat( [buffer.slice( 0, index ), chunk], nsize );
            }
        }
        index += chunk.length;
	}

	public function tryReadLength() : Int {
		if( index < 4 )
            return -1;
        var len = buffer.readInt32LE( 0 );
        buffer = buffer.slice( 4 );
        index -= 4;
        return len;
	}

	public function tryReadContent( length : Int ) : String {
        if( index < length )
            return null;
        var res = buffer.toString( "utf-8", 0, length );
        var nstart = length;
        buffer.copy( buffer, 0, nstart );
        index -= nstart;
        return res;
    }
}

private class DisplayRequest {

	@:allow(xxx.LanguageServer) var prev : DisplayRequest;
    @:allow(xxx.LanguageServer) var next : DisplayRequest;

    var args : Array<String>;
    var stdin : String;
    var onResult : String->Void;
    var onError : String->Void;

	public function new( args : Array<String>, stdin : String, onResult : String->Void, onError : String->Void ) {
        this.args = args;
        this.stdin = stdin;
        this.onResult = onResult;
        this.onError = onError;
    }

	public function prepareBody() : Buffer {

        if( stdin != null )
			args = args.concat( ['-D','display-stdin'] );
		//args = args.concat( ['-D','display-details'] );

        var lbuf = new Buffer(4);
        var chunks = [lbuf];
        var length = 0;

        for( arg in args ) {
            var buf = new Buffer( '$arg\n' );
            chunks.push( buf );
            length += buf.length;
        }

        if( stdin != null ) {
			var sbuf = new Buffer( [1] );
            chunks.push( sbuf );
            var buf = new Buffer( stdin );
            chunks.push( buf );
            length += buf.length + sbuf.length;
        }

        lbuf.writeInt32LE( length, 0 );

        return Buffer.concat( chunks, length + 4 );
    }

    public function processResult( data : String ) {

        if( data == null ) {
			onResult( null );
			return;
		}

        var buf = new StringBuf();
        var hasError = false;
        for( line in data.split( "\n" ) ) {
            switch line.fastCodeAt( 0 ) {
                case 0x01: // print
                    var line = line.substring(1).replace( "\x01", "\n" );
                    trace("Haxe print:\n" + line);
                case 0x02: // error
                    hasError = true;
                default:
                    buf.add( line );
                    buf.addChar( "\n".code );
            }
        }

        var data = buf.toString().trim();
		/*
        if( hasError )
            return onError( "Error from Haxe server: " + data );
        try {
            onResult( data );
        } catch (e:Any) {
			trace(e);
			onError(e);
            //errback(jsonrpc.ErrorUtils.errorToString(e, "Exception while handling Haxe completion response: "));
        }
		*/
		if( hasError ) {
			onError( "Error from Haxe server: " + data );
			return;
		}

		onResult( data );
    }

}
