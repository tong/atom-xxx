package xxx;

import atom.autocomplete.*;
import om.haxe.CompletionParser;
import xxx.CompilerService;

using om.util.StringUtil;

class AutoCompleteProvider {

	static var EXPR_ALPHANUMERIC_END = ~/[^a-zA-Z0-9_\]\)]([\.0-9]+)$/;
	static var EXPR_PREFIX_FIELD = ~/\.([a-zA-Z_][a-zA-Z_0-9]*)$/;
	static var EXPR_PREFIX_CALL = ~/\(( *)$/;
	static var EXPR_TYPEPATH = ~/(import|using)\s+([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)(?:\s+(?:in|as)\s+([a-zA-Z0-9_]+))?/g;

	@:keep public var selector = '.source.haxe';
	@:keep public var disableForSelector = '.source.haxe .comment';
	@:keep public var suggestionPriority = 3;
	//@:keep public var inclusionPriority = 3;
	//@:keep public var excludeLowerPriority = true;
	//@:keep public var filterSuggestions = true;

	public var enabled : Bool;

	var disposables : CompositeDisposable;

	public function new() {
		var cfg = IDE.getConfig( 'autocomplete' );
		this.enabled = cfg.enabled;
		disposables = new CompositeDisposable();
		disposables.add( Atom.config.observe( 'xxx.autocomplete', function(n){
			enabled = n.enabled;
		} ) );
	}

	@:keep public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

		console.group( 'getSuggestions' );

		return new Promise( function(resolve,reject) {

			if( !enabled || IDE.hxml == null )
				return resolve( [] );

			var editor = req.editor;
			var position = editor.getCursorBufferPosition();
			var prefixPos = req.bufferPosition;
			var prefix = req.prefix;
			var replacementPrefix = '';
			//var line = editor.lineTextForBufferRow( req.bufferPosition.row );
			var line = editor.getTextInBufferRange(	new Range( new Point(prefixPos.row,0), prefixPos ) );

			if( EXPR_PREFIX_FIELD.match( line ) ) {
				prefix = '.';
				replacementPrefix = EXPR_PREFIX_FIELD.matched( 1 );
				prefixPos.column -= replacementPrefix.length;
			} else if( EXPR_PREFIX_CALL.match( line ) ) {
				prefix = '(';
				replacementPrefix = EXPR_PREFIX_CALL.matched( 1 );
				prefixPos.column -= replacementPrefix.length;
			}

			console.log( 'PREFIX = [$prefix][$replacementPrefix]' );

			var service = new CompilerService( editor );

			switch prefix {

			case '.':

				if( EXPR_ALPHANUMERIC_END.match( line ) ) {
					return resolve( [] );
				}

				///// Field access completion
				return cast service.fieldAccess( prefixPos ).then( function(items:Array<Item>) {
					var suggestions = new Array<Suggestion>();
					var isImportDecl = EXPR_TYPEPATH.match( line );
					for( item in items ) {
						if( replacementPrefix.length > 0 && !item.n.startsWith( replacementPrefix ) )
							continue;
						if( isImportDecl ) {
							var pack = EXPR_TYPEPATH.matched( 2 );
							var type = pack.split( '.' ).pop();
							if( type == item.n )
								continue;
						}
						var sug = createSuggestion( item, !isImportDecl );
						suggestions.push( sug );
					}
					return resolve( suggestions );
				});

			case '(':
				trace(">>>>>>>>>>>>>>>>>>");
				return cast service.callArgument( prefixPos ).then( function(items:Array<Item>) {
					trace(items);
					var suggestions = new Array<Suggestion>();
					var sug = createSuggestion( items[0] );
					trace(sug);
					suggestions.push( sug );
					return resolve( suggestions );
				});
				//TODO
				/*
				///// Call argument completion
				return cast service.callArgument( prefixPos ).then( function(xml:Xml) {
					var str = xml.firstChild().nodeValue.trim();
					var types : Array<String> = str.split( '->' );
					var ret = types.pop();
					var suggestion : Suggestion = { type: 'type', snippet: '' };
					var args = new Array<String>();
					for( i in 0...types.length ) {
						var type = types[i].trim();
						var parts = type.split( ' : ' );
						var tagA = '';
						var tagB = '';
						args.push( "${"+(i+1)+":"+tagA+parts[0]+":"+parts[1]+tagB+"}" );
					}
					suggestion.snippet = " "+args.join( ", " )+" )$0";
					return resolve( [suggestion] );
				});
				*/

			//case '',' ':

			default:

				// --- Toplevel completion
				return cast service.topLevel( prefixPos ).then( function(items:Array<Item>) {
					var suggestions = new Array<Suggestion>();
					for( item in items ) {
						item.n = item.p;
						if( item.n == null ) item.n = item.c;
						if( prefix.length > 0 && !item.n.startsWith( prefix ) )
							continue;
						var sug = createSuggestion( item );
						suggestions.push( sug );
					}
					return resolve( suggestions );
				});
			}
		} ).then( function(suggestions){
			console.groupEnd();
			return cast suggestions;
		} ).catchError( function(e:String){
			console.error( e );
			console.groupEnd();
			return Promise.resolve( [] );
		});
	}

	@:keep public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
		//trace("TODO onDidInsertSuggestion");
	}

	@:keep public function dispose() {
		disposables.dispose();
	}

	static function createSuggestion( item : Item, completeFunArgs = true ) : Suggestion {
		var sug : Suggestion = { type: item.k, text: item.n, description: formatDoc( item.d ) };
		switch item.k {
		case 'method':
			//sug.type = 'method';
			var displayText = item.n+'(';
			var snippet = item.n+'(';
			var funType = CompletionParser.parseFunType( item.t );
			sug.rightLabel = funType.ret;
			if( funType.args.length > 0 ) {
				displayText += ' ';
				snippet += ' ';
			}
			var argsDisplay = new Array<String>();
			var argsSnippets = new Array<String>();
			for( i in 0...funType.args.length ) {
				var arg = funType.args[i];
				argsDisplay.push( arg[0]+' : '+arg[1] );
				//var snippet = "${"+(i+1)+":"+arg[0]+" : "+arg[1]+"}";
				var snippet = "${"+(i+1)+":"+arg[0]+"}";
				argsSnippets.push( snippet );
			}
			displayText += argsDisplay.join( ', ' );
			snippet += argsSnippets.join( ', ' );
			if( funType.args.length > 0 ) {
				displayText += ' ';
				snippet += ' ';
			}
			displayText += ')';
			snippet += ")$0";
			sug.displayText = displayText;
			sug.snippet = if( completeFunArgs ) snippet else item.n;
			sug.text = null;
		case 'var':
			sug.rightLabel = item.t;
		case 'static':
			sug.type = 'method';
			sug.snippet = item.n+'()$0';
			sug.displayText = item.n+'()';
		case 'literal':
			sug.type = 'keyword';
		case null:
			//TODO
			sug.text = item.t;

		}
		return sug;
	}

	static function formatDoc( doc : String ) : String {
		if( doc == null )
			return '';
		doc = doc.trim();
		var r = new Array<String>();
		for( line in doc.split( '\n' ) ) {
			r.push( line.trim() );
		}
		return r.join( '\n' );
	}

}
