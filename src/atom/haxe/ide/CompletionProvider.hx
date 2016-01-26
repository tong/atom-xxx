package atom.haxe.ide;

import js.Promise;
import js.Node;
import js.node.ChildProcess;
import js.node.Fs;
import js.node.Path;
import atom.TextEditor;

using StringTools;

/**
    https://github.com/atom/autocomplete-plus/wiki/Provider-API
    https://github.com/atom/autocomplete-plus/pull/334

    https://github.com/snowkit/atom-haxe/tree/e9ccee9a61fd39d4a761afd13b3841f3dbcd66db/lib/completion

*/
@:keep
@:expose
class CompletionProvider {

    static var completionRegex = ~/[A-Z_0-9]+$/i;

    public var selector = '.source.haxe';
    public var disableForSelector = '.source.haxe .comment';

    public var inclusionPriority = 1;
    public var excludeLowerPriority = true;

    //public var hxml : String;
    var editor : TextEditor;

    public var path = '/home/tong/dev/temp/';
    public var hxml = 'build.hxml';

    public function new() {}

    public function getSuggestions( req ) {

        //trace(req);
        //var activatedManually = req.activatedManually;

        editor = req.editor;

        var bufferPosition = req.bufferPosition;
        var prefix = req.prefix;
        var scopeDescriptor = req.scopeDescriptor;
        var pretext = editor.getTextInBufferRange( [ [0,0], bufferPosition ] );
        var pos = pretext.length;
        //var mode
        //var filePath = editor.getPath();

        return new Promise( function(resolve,reject) {

            //reject( 'reason' );
            //resolve( null );

            if( pretext.charAt( pretext.length-1 ) == '.' ) {

                trace( 'fieldCompletion '+pos );

                saveForCompletion();

                fieldCompletion( pos, function(xml){

                    if( xml == null ) {
                        resolve( null );
                        return;
                    }

                    var suggestions = new Array<Dynamic>();

                    for( e in xml.elements() ) {

                        var isVar = e.get( 'k' ) == 'var';
                        var name = e.get( 'n' );
                        var type : String = null;
                        var doc : String = null;
                        var displayName = name;

                        for( e in e.elements() ) {
                            switch e.nodeName {
                            case 't': type = e.firstChild().nodeValue;
                            case 'd': doc = e.firstChild().nodeValue;
                            }
                        }

                        if( isVar ) {
                            displayName += ' : '+type;
                        } else {
                            var parts = type.split( '->' );
                            var args = new Array<String>();
                            var returnType = parts.pop();
                            for( p in parts ) {
                                //name += p.trim();
                                args.push( p.trim() );
                            }
                            displayName += '( '+args.join(', ')+' ) : '+returnType;
                        }

                        var suggestion = {
                            //iconHTML: '<i class="icon-bug"></i>',
                            type: isVar ? 'property' : 'method',
                            text : name,
                            displayText: displayName,
                            //replacementPrefix: 'F'
                            //leftLabel: type,
                            //description: 'DDDDDDDDDDDDD',
                            //rightLabel: type
                        };

                        suggestions.push( suggestion );
                    }

                    resolve( suggestions );
                });
            }
        });
    }

    public function dispose() {
        trace("DISPOSE");
    }

    public function onDidInsertSuggestion( opt ) : Array<Dynamic> {
        trace(opt);
        return null;
    }

    function saveForCompletion() {
        var path = editor.getPath();
        var filePath = Path.dirname( path );
        var fileName = Path.basename( path );
        var tmpFileName = '.' + fileName;
        var tmpFilePath = Path.join( filePath, tmpFileName );
        //trace(path);
        //trace(tmpFilePath);
        Fs.createReadStream( path ).pipe( Fs.createWriteStream( tmpFilePath ) );
    }

    function fieldCompletion( pos : Int, callback : Xml->Void ) {

        var args = [
            '--cwd', path,
            //'--connect', Std.string(7000),
            '--display', 'App.hx@$pos', '-D', 'display-details'
        ];
        //trace(args);

        var options = {
            //cwd: path,
        };
        var result = '';
        var hx = ChildProcess.spawn( 'haxe', args, options );
        /*
        hx.stdout.on( 'data', function(data) {
            trace( 'stdout: ' +  data.toString('utf-8') );
        });
        */
        hx.stderr.on( 'data', function(data) {
            //trace('#####################################');
            result += ''+data.toString();
        });
        hx.on( 'close', function(code:Int) {
            //trace( 'child process exited with code ' + code );
            //trace(result);
            switch code {
            case 0:
            //var xml = try Xml.parse( result ).firstElement() catch(e:Dynamic) {
                var xml = try haxe.xml.Parser.parse( result ).firstElement() catch(e:Dynamic) {
                    trace(e);
                    //trace(result);
                    callback( null );
                    return;
                }
                callback( xml );
            default:
                callback( null );
            }
        });
    }

}
