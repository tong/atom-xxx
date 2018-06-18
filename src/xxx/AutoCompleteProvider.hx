package xxx;

import atom.autocomplete.*;
import om.haxe.CompletionParser;
import xxx.CompletionService;

class AutoCompleteProvider {

	static var EXPR_ALPHANUMERIC_END = ~/[^a-zA-Z0-9_\]\)]([\.0-9]+)$/;
	static var EXPR_PREFIX_FIELD = ~/\.([a-zA-Z_][a-zA-Z_0-9]*)$/;
	static var EXPR_PREFIX_CALL = ~/\(( *)$/;
	static var EXPR_TYPEPATH = ~/(import|using)\s+([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)*)(?:\s+(?:in|as)\s+([a-zA-Z0-9_]+))?/g;

	public dynamic function onError( error : String ) {}

	@:keep public var selector = '.source.hx';
	@:keep public var disableForSelector = '.source.hx .comment';
	@:keep public var excludeLowerPriority = false;
	//@:keep public var suggestionPriority = 3;
	//@:keep public var inclusionPriority = 1;
	//@:keep public var filterSuggestions = true;

	public var enabled : Bool;
	public var service(default,null) : CompletionService;

	var disposables : CompositeDisposable;

	public function new() {

		var cfg = IDE.getConfig( 'autocomplete' );
		this.enabled = cfg.enabled;

		disposables = new CompositeDisposable();

		Atom.config.observe( 'xxx.autocomplete', {}, function(n){
			enabled = n.enabled;
		});

		/*
		disposables.add( Atom.config.observe( 'xxx.autocomplete', function(n){
			enabled = n.enabled;
		} ) );
		*/
	}

	@:keep
	public function getSuggestions( req : Request ) : Promise<Array<Suggestion>> {

		return new Promise( function(resolve,reject) {

			if( !enabled )
				return resolve( [] );

			var editor = req.editor;
			var position = editor.getCursorBufferPosition();
			var prefixPos = req.bufferPosition;
			var prefix = req.prefix;
			var replacementPrefix = '';
			var line = editor.getTextInBufferRange(	new Range( new Point( prefixPos.row, 0 ), prefixPos ) );
			//var line = editor.lineTextForBufferRow( req.bufferPosition.row );

			if( EXPR_PREFIX_FIELD.match( line ) ) {
				prefix = '.';
				replacementPrefix = EXPR_PREFIX_FIELD.matched( 1 );
				prefixPos.column -= replacementPrefix.length;
			} else if( EXPR_PREFIX_CALL.match( line ) ) {
				prefix = '(';
				replacementPrefix = EXPR_PREFIX_CALL.matched( 1 );
				prefixPos.column -= replacementPrefix.length;
			}

			trace( 'PREFIX = [$prefix][$replacementPrefix]' );

			if( service == null ) service = new CompletionService( editor );
			else service.editor = editor;
			//var suggestions = new Array<Suggestion>();

			/*
			service.usage( prefixPos ).then( function(item) {
				trace( item );
			});
			*/

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

				/*
				service.usage( prefixPos ).then( function(items:Array<om.haxe.Message>) {
					for( item in items ) {
						trace(item);
					}
				});
				*/

			case '(':
				return cast service.callArgument( prefixPos ).then( function(item:Item) {
					//TODO
					/*
					trace( item );
					var sug : Suggestion = {
						displayText: item.t,
						description: item.d,
						snippet: item.t,
					};
					return resolve( [sug] );
					*/
					/*
					var sug = createSuggestion( items[0] );
					suggestions.push( sug );
					return resolve( suggestions );
					*/
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
					var suggestions = new Map<String,Array<Suggestion>>();
					for( item in items ) {
						//trace( item );
						var name = switch item.k {
						case 'enum','enumabstract','literal','local','member','package','static': item.c;
						case 'type': item.p;
						case 'method': item.n;
						default: null;
						}
						if( prefix.length > 0 &&
							prefix.trim().length != 0 &&
							name != null && !name.startsWith( prefix ) )
							continue;
						var sug : Suggestion = {
							text: name,
							type: item.k,
							description: formatDoc( item.d )
						};
						switch item.k {
						case 'enumabstract':
							sug.type = 'enum';
							sug.rightLabel = item.t;
						case 'enum':
							sug.type = 'enum';
							sug.rightLabel = item.t;
						case 'global':
							sug.type = 'global';
						case 'literal':
							sug.type = 'keyword';
						case 'local':
							sug.type = 'value';
							sug.rightLabel = item.t;
						case 'member':
							sug.type = 'member';
							sug.rightLabel = item.t;
						case 'method':
							sug.snippet = 'function ' + item.n;
						case 'package':
							sug.type = 'package';
						case 'static':
							//var funType = CompletionParser.parseFunType( item.t );
							sug.displayText = item.c+'()';
							sug.rightLabel = item.t;
							sug.snippet = item.c+'()$0';
							sug.type = 'method';
						case 'type':
							sug.type = 'type';
							sug.text = item.p;
						default:
							console.warn( "TODO: "+item );
						}
						if( !suggestions.exists( item.k ) ) suggestions.set( item.k, [] );
						suggestions.get( item.k ).push( sug );
					}
					var result = new Array<Suggestion>();
					for( list in suggestions ) {
						list.sort( (a,b) -> return (a.text > b.text) ? 1 : (a.text < b.text) ? -1 : 0  );
					}
					if( suggestions.exists( 'local' ) ) result = result.concat( suggestions.get( 'local' ) );
					if( suggestions.exists( 'static' ) ) result = result.concat( suggestions.get( 'static' ) );
					if( suggestions.exists( 'global' ) ) result = result.concat( suggestions.get( 'global' ) );
					if( suggestions.exists( 'literal' ) ) result = result.concat( suggestions.get( 'literal' ) );
					if( suggestions.exists( 'type' ) ) result = result.concat( suggestions.get( 'type' ) );
					if( suggestions.exists( 'package' ) ) result = result.concat( suggestions.get( 'package' ) );
					if( suggestions.exists( 'enum' ) ) result = result.concat( suggestions.get( 'enum' ) );
					if( suggestions.exists( 'method' ) ) result = result.concat( suggestions.get( 'method' ) );
					return resolve( result );
				}).catchError( function(e){
					//TODO
					onError( e );
					//trace(e);
				} );
			}
		//} ).then( function(suggestions){
		//	return cast suggestions;
		} ).catchError( function(e){
			console.error( e );
			//return resolve( [] );
			return Promise.resolve( [] );
		});
	}

	@:keep
	public function onDidInsertSuggestion( suggestion : SuggestionInsert ) {
		//trace("TODO onDidInsertSuggestion");
	}

	@:keep
	public function dispose() {
		disposables.dispose();
	}

	// field access
	static function createSuggestion( item : Item, completeFunArgs = true ) : Suggestion {
		var sug : Suggestion = { type: item.k, text: item.n, description: formatDoc( item.d ) };
		switch item.k {
		case 'literal':
			sug.type = 'keyword';
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
		case 'static':
			sug.type = 'method';
			sug.snippet = item.n+'()$0';
			sug.displayText = item.n+'()';
		case 'var':
			sug.type = 'variable';
			sug.rightLabel = item.t;
		case null:
			//TODO
			trace("TODO");
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
