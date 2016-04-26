package xxx.atom;

import js.Browser.console;
import js.Error;
import js.Promise;
import js.node.Fs;
import js.node.Path;
import js.html.Element;
import atom.TextEditor;
import atom.autocomplete.Request;
import atom.autocomplete.Suggestion;
import atom.autocomplete.SuggestionInsert;
import sys.FileSystem;
import om.haxe.SourceCodeUtil;
import om.io.FileUtil;

using haxe.io.Path;
using StringTools;

private typedef CompletionTempFileInfo = {
    fp : String,
    cp : String,
    content : String
};

class CompletionProvider {

	@:keep @:expose public var selector(default,null) = '.source.haxe';
	@:keep @:expose public var disableForSelector(default,null) = '.source.haxe .comment';
	@:keep @:expose public var inclusionPriority = 2;
	@:keep @:expose public var excludeLowerPriority = false;
	@:keep @:expose public var prefixes = ['.','('];

	public var tmp(default,null) : String;

	public function new( tmp : String ) {

        this.tmp = tmp.removeTrailingSlashes();

        if( !FileSystem.exists( tmp ) ) FileUtil.createDirectory( tmp );

        //comp = new Completion();
    }

	public function dispose() {
		if( FileSystem.exists( tmp ) ) {
			try {
				FileUtil.deleteDirectory( tmp );
	        } catch(e:Dynamic) {
				trace(e);
			}
		}
	}

	@:keep
    public function getSuggestions( req : Request ) {

		trace( "getSuggestions "+req );

		var project = IDE.project;

		var editor = req.editor;
		var bufferFile = untyped editor.buffer.file;
		if( bufferFile == null )
			return untyped [];

		return new Promise( function(resolve,reject) {

			//console.profile( 'completion' );

			var bufpos = req.bufferPosition.toArray();
			var pretext = editor.getTextInBufferRange( [[0,0], bufpos] );
			var index = pretext.length;
			var path = editor.getPath();
			var cwd = IDE.project.hxml.directory();
			//var file = path.withoutDirectory();
			var mode = null;
			//var prefix = req.prefix;
			//var scopeDescriptor = req.scopeDescriptor;
			var content = editor.getText();
			//var pos = Buffer._byteLength( pretext.substr( 0, index ), 'utf8' );

			//var posInfo = getPositionInfo( pretext, index );
			var posInfo = getPositionInfo( editor, bufpos, index );
			if( posInfo == null )
				return resolve([]);
			if( posInfo.mode != null ) mode = posInfo.mode;

			//trace(posInfo);
			//trace(mode);

			var saveInfo = saveTempCompletionFile( path, content );

			//trace( saveInfo.content.slice( 0, index + saveInfo.content.length - content.length ) );

			//var extraArgs = HaxeIDE.server.getHaxeFlag().concat( ['-cp',saveInfo.cp] );
			var extraArgs = ['-cp',saveInfo.cp];

			Completion.fieldAccess( project.cwd, saveInfo.fp, posInfo.index, extraArgs, function(result) {
				if( result == null || result.length == 0 ) {
					resolve( null );
				} else {
					var xml = try new js.html.DOMParser().parseFromString( result, TEXT_XML ) catch(e:Dynamic) {
						console.error(e);
						resolve( null );
						return;
					}
					resolve( createFieldSuggestions( xml.firstElementChild ) );
				}
				//console.profileEnd( 'completion' );
			});
		});
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
            //trace( "DOT PREFIX #"+prefix+'#' );
            // Don't query when writing a number containing dots
            if( SourceCodeUtil.ENDS_WITH_DOT_NUMBER.match( ' '+line ) ) {
                return null;
            }
            // Don't query haxe when writing a package declaration
            if( SourceCodeUtil.ENDS_WITH_PARTIAL_PACKAGE_DECL.match( ' '+line ) ) {
                return null;
            }
            return {
                index:  index - prefix.length,
                prefix: prefix
            };
        }

        trace(line);

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

	function saveTempCompletionFile( origFile : String, content : String ) : CompletionTempFileInfo {

        var packName = SourceCodeUtil.extractPackage( content );
        /*
        var newPackageName = '';
        if( packageName.length > 0 ) {
            newPackageName = packageName + '.' + newPackageName;
        }

        content = SourceCodeUtil.replacePackage( content, newPackageName );
        */

        var baseName = js.node.Path.basename( origFile );
        var relPath = js.node.Path.join( packName.split( '.' ).join( js.node.Path.sep ), baseName );

        /*
        var packageName = SourceCodeUtil.extractPackage( content );
        var newPackageName = '__atom_completion__';
        if( packageName.length > 0 ) {
            newPackageName = packageName + '.' + newPackageName;
        }

        content = SourceCodeUtil.replacePackage( content, newPackageName );

        var baseName = js.node.Path.basename( origFile );
        var relPath = js.node.Path.join( newPackageName.split( '.' ).join( js.node.Path.sep ), baseName );
        */

        return saveFileInTempPath( relPath, content );
    }

	function saveFileInTempPath( relPath : String, content : String ) : CompletionTempFileInfo {

        var hash = om.util.UUIDUtil.create();
        //var hash = haxe.crypto.Md5.make( sys.io.File.getBytes( relPath ) ).toString();
        var cp = Path.join( [tmp,hash] );
        var fp = Path.join( [cp,relPath] );
        var dir = fp.directory();

        if( !FileSystem.exists( dir ) ) FileUtil.createDirectory( dir );
        Fs.writeFileSync( fp, content );

        return {
            fp: fp,
            cp: cp,
            content: content
        };

        /*
        var tmp = '/tmp';
        var hash = om.util.UUIDUtil.create();
        var cpPath = Path.join( [tmp,'atom',hash] );
        var tempPath = Path.join( [cpPath,relPath] ).removeTrailingSlashes();

        //TODO Ensure this path is inside the temporary directory

        var tempPathParts = tempPath.split( '/' );
        var tempFile = tempPathParts.pop();
        var currentPath = '';
        for( part in tempPathParts ) {
            currentPath += '$part/';
            if( !FileSystem.exists( currentPath ) ) FileSystem.createDirectory( currentPath );
        }
        Fs.writeFileSync( tempPath, content );

        return {
            fp: tempPath,
            cp: cpPath,
            content: content
        };
        */
    }

	function createFieldSuggestions( xml : Element ) : Array<Suggestion> {
        var suggestions = new Array<Suggestion>();
        for( e in xml.children ) {
            var name =  e.getAttribute( 'n' );
            var isVar =  e.getAttribute( 'k' ) == 'var';
            var type : String = null;
            var doc : String = null;
            var ret : String = null;
            for( e in e.children ) {
                if( e.firstChild == null )
                    continue;
                switch e.nodeName {
                case 't': type = e.firstChild.nodeValue;
                case 'd': doc = e.firstChild.nodeValue;
                }
            }
    //        if( doc != null ) doc = Markdown.markdownToHtml( doc );
            var snippet = name;
            var displayName = name;
            if( isVar ) {
                displayName += ' : '+type;
            } else {
                var types = type.split( ' -> ' );
                ret = types.pop();
                if( types[0] == 'Void' ) {
                    snippet += '()$$0';
                    displayName += '()';
                } else {
                    snippet += '( ';
                    var i = 1;
                    var argSnippets = new Array<String>();
                    for( type in types ) {
                        var parts = type.split( ' : ' );
                        var name = parts[0];
                        argSnippets.push( '$${$i:$name}' );
                        i++;
                    }
                    snippet += argSnippets.join( ', ' )+' )$$0';
                    displayName += '( '+types.join( ', ' )+' ) : '+ret;
                }
            }

            suggestions.push( {
                type: isVar ? 'variable' : 'method',
                //text : name,
                snippet : snippet,
                displayText: displayName,
                //leftLabel: ret,
                //rightLabel: ret,
                description: doc,
                descriptionMoreURL: 'http://disktree.net',
                className: 'haxe-autocomplete-suggestion-type-hint'
            } );
        }
        return suggestions;
    }

}
