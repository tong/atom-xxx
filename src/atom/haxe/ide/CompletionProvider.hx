package atom.haxe.ide;

import js.Error;
import js.Promise;
import js.Node;
import js.Node.process;
import js.node.Buffer;
import js.node.ChildProcess;
import js.node.Fs;
import js.node.Path;
import sys.FileSystem;
import atom.TextEditor;
import atom.autocomplete.Request;
import atom.autocomplete.Suggestion;
import atom.autocomplete.SuggestionInsert;
import haxe.SourceCodeUtil;

using haxe.io.Path;
using StringTools;

private typedef TempFileSaveInfo = {
    var fp : String;
    var cp : String;
    var content : String;
};

class CompletionProvider {

    //public static inline var TMP = '.tmp';

    @:keep @:expose public var selector(default,null) = '.source.haxe';
    @:keep @:expose public var disableForSelector(default,null) = '.source.haxe .comment';
    @:keep @:expose public var inclusionPriority = 2;
    @:keep @:expose public var excludeLowerPriority = false;
    //@:keep @:expose public var prefixes = ['.','('];

    public function new() {}

    @:keep
    @:expose
    public function getSuggestions( req : Request ) {

        var state = HaxeIDE.state;

        if( state.hxml == null ) {
            return null;
        }

        return new Promise( function(resolve,reject) {

            /*
            var state = HaxeIDE.state;
            if( state.hxml == null ) {
                reject( 'no hxml file specified' );
                return;
            }
            */

            //trace(req.prefix);
            //var activatedManually = req.activatedManually;
            var editor = req.editor;
            var bufpos = req.bufferPosition.toArray();
            var pretext = editor.getTextInBufferRange( [[0,0], bufpos] );
            var index = pretext.length;
            var path = editor.getPath();
            var cwd = state.hxml.directory();
            //var file = path.withoutDirectory();
            var mode = null;
            //var prefix = req.prefix;
            //var scopeDescriptor = req.scopeDescriptor;
            //var text = editor.getText();
            //var pos = Buffer._byteLength( pretext.substr( 0, index ), 'utf8' );
            //trace(path);
            //trace(file);
            //trace(cwd);
            //trace(path);

            var posInfo = getPositionInfo( editor, bufpos, index );
            //var posInfo = getPositionInfo( pretext, index );
            if( posInfo == null )
                return resolve([]);
            if( posInfo.mode != null ) mode = posInfo.mode;

            trace(posInfo);

            /*
            var mode_saveForCompletion = true;

            if( mode_saveForCompletion ) {
                //TODO save temp file for completion
                var saveInfo = saveForCompletion( editor, path );
                //Completion.fetch(  hxmlFile, saveInfo.file, posInfo.index, mode, [],
                Completion.fetch( state.hxml.directory(), state.hxml.withoutDirectory(), saveInfo.file, posInfo.index, mode, [],
                    function(xml){
                        if( xml != null ) {
                            resolve( parseSuggestions( xml ) );
                        } else {
                            trace(xml);
                        }
                    },
                    function(e){
                        trace(e);
                    }
                );
            } else {
                //TODO
            }
            */

            //Sys.command( 'haxe', ['-cp',AtomPackage.path+'/src','--macro','atom.haxe.ide.HaxeCode.extractPackage()'] );

            //lastRequest = {};

            /*
            //var pack = code.extract_package( text );
            //trace(pack);
            var dirPath = cwd+'/'+TMP;
            var filePath = dirPath+'/'+path.withoutDirectory();
            if( !FileSystem.exists( dirPath ) ) Fs.mkdirSync( dirPath );
            Fs.writeFileSync( filePath, content );
            var classPath = null;
            return {
                fp: filePath,
                cp: classPath,
                content: content
            };
            */

            /*
            Completion.fetch( cwd, hxmlFile, file, posInfo.index, mode, [],
                function(xml){
                    var suggestions = new Array<Suggestion>();
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
                        suggestions.push( {
                            //iconHTML: '<i class="icon-bug"></i>',
                            type: isVar ? 'property' : 'method',
                            text : name,
                            displayText: displayName,
                            //replacementPrefix: 'F'
                            //leftLabel: type,
                            //description: 'DDDDDDDDDDDDD',
                            //rightLabel: type
                        } );
                    }
                    resolve( suggestions );
                },
                function(e){
                    trace(e);
                    reject(e);
                }
            );
            */
        });
    }

    public function dispose() {
        trace("DISPOSE");
        //TODO
    }

    @:keep
    @:expose
    public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
        //trace(suggestion);
        //TODO
    }

    function getPositionInfo( editor : TextEditor, pos : Array<Int>, index : Int ) : { index : Int, prefix : String, ?mode : String } {

        var line = editor.getTextInBufferRange( [[pos[0],0], pos] );

        //TODO check for comments and strings
        //TODO use haxeparser for this ?

        if( SourceCodeUtil.ENDS_WITH_DOT_IDENTIFIER.match( line ) ) {
            var prefix = SourceCodeUtil.ENDS_WITH_DOT_IDENTIFIER.matched(1);
            trace( "DOT PREFIX #"+prefix+'#' );
            /*
            // Don't query when writing a number containing dots
            if( REGEX_ENDS_WITH_DOT_NUMBER.match( ' '+line ) ) {
                trace("REGEX_ENDS_WITH_DOT_NUMBER");
                return null;
            }
            // Don't query haxe when writing a package declaration
            if( REGEX_ENDS_WITH_PARTIAL_PACKAGE_DECL.match( ' '+line ) ) {
                trace("REGEX_ENDS_WITH_PARTIAL_PACKAGE_DECL");
                return null;
            }
            */
            return {
                index:  index - prefix.length,
                prefix: prefix
            };
        }

        if( SourceCodeUtil.ENDS_WITH_ALPHANUMERIC.match( line ) ) {
            var prefix = SourceCodeUtil.ENDS_WITH_ALPHANUMERIC.matched(1);
            return {
                index: index - prefix.length,
                prefix: prefix,
                mode: 'toplevel'
            };
        }
        return null;
    }

    function saveForCompletion( editor : TextEditor, file : String ) {

        var filePath = js.node.Path.dirname( file );
        var fileName = js.node.Path.basename( file );
        var tmpName = '.' + fileName;
        var tempFile = Path.join( [filePath,tmpName] );

        sys.io.File.copy( file, tempFile );

        var buf = new Buffer( editor.getText(), 'utf8' );
        var freal = Fs.openSync( file, 'w' );
        Fs.writeSync( freal, buf, 0, buf.length, 0);
        Fs.closeSync( freal );
        freal = null;

        return {
            tempfile: tempFile,
            file: file
        }
        /*
        var path = editor.getPath();
        var filePath = Path.dirname( path );
        var fileName = Path.basename( path );
        var tmpFileName = '.' + fileName;
        var tmpFilePath = Path.join( filePath, tmpFileName );
        //trace(path);
        //trace(tmpFilePath);
        Fs.createReadStream( path ).pipe( Fs.createWriteStream( tmpFilePath ) );
        */
    }

    /*
    function saveTempCompletionFile( path : String, content : String ) : TempFileSaveInfo {

        //var pack = code.extract_package( text );
        //trace(pack);

        var dirPath = cwd+'/'+TMP;
        var filePath = dirPath+'/'+path.withoutDirectory();

        if( !FileSystem.exists( dirPath ) ) Fs.mkdirSync( dirPath );
        Fs.writeFileSync( filePath, content );

        var classPath = null;

        return {
            fp: filePath,
            cp: classPath,
            content: content
        };
    }
    */

    function parseSuggestions( xml : Xml ) : Array<Suggestion> {
        var suggestions = new Array<Suggestion>();
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

        return suggestions;
    }

}
