package xxx.view;

import om.haxe.ErrorMessage;

private class ErrorMessageView {

	public var element(default,null) : LIElement;
	public var error(default,null) : ErrorMessage;

	public function new( n : Int, err : ErrorMessage ) {

		this.error = err;

		element = document.createLIElement();
		element.classList.add( 'message', 'error' );

		var index = document.createElement('i');
		index.textContent = Std.string( n+1 );
		element.appendChild( index );

		var path = document.createSpanElement();
		path.classList.add( 'path' );
		path.textContent = err.path;
		element.appendChild( path );

		var line = document.createSpanElement();
		line.classList.add( 'line' );
		line.textContent = Std.string( err.line );
		element.appendChild( line );

		if( err.characters != null ) {

			var start = document.createSpanElement();
			start.classList.add( 'start' );
			start.textContent = Std.string( err.characters.start );
			element.appendChild( start );

			var end = document.createSpanElement();
			end.classList.add( 'end' );
			end.textContent = Std.string( err.characters.end );
			element.appendChild( end );
		}

		var content = document.createSpanElement();
		//var content = document.createPreElement();
		content.classList.add( 'content' );
		content.textContent = err.content;
		//content.setAttribute( 'tabindex', '0' );
		element.appendChild( content );

		//var btn = document.createSpanElement();
		//btn.classList.add( 'icon', 'icon-clippy' );
		//element.appendChild( btn );

		//element.onclick = function()
	}

	public function select() {
		//element.classList.add( 'selected' );
	}

	public function unselect() {
		//element.classList.remove( 'selected' );
	}
}

class BuildView {

	static var current : BuildView;

	var panel : Panel;
    var element : DivElement;
	var messages : OListElement;

	var timeStart : Float;

	public function new( build : Build ) {

		if( current != null ) {
			current.destroy();
		}

		current = this;

		element = document.createDivElement();
        element.classList.add( 'xxx-build', 'resizer', 'native-key-bindings' );
		element.setAttribute( 'tabindex', '-1' );

		messages = document.createOListElement();
		messages.classList.add( 'messages', 'scroller' );
		element.appendChild( messages );

		panel = workspace.addBottomPanel( { item: element, visible: true } );

		var errors = new Array<ErrorMessage>();

		build.onStart( function(){
			timeStart = Time.stamp();
			errors = [];
			//log( build.args.join( ' ' ) );
		});
		build.onMessage( function(msg){
			log( msg );
		});
		build.onError( function(err){

			for( line in err.split( '\n' ) ) {

				var error = ErrorMessage.parse( line );

				if( error == null ) {
					log( err, 'error' );

				} else {

					errors.push( error );

					var view = new ErrorMessageView( messages.children.length, error );
					view.element.onclick = function(e) {
						view.select();
						if( e.ctrlKey ) openErrorPosition( error );
					}
					messages.appendChild( view.element );
				}
			}
		});
		build.onEnd( function(code){
			switch code {
			case 0:
				if( messages.children.length == 0 )
					hide();
			case _:
				if( errors.length > 0 ) {

					//TODO
					var err = errors[0];

					// Get absolute file path
					var hxmlPath = build.hxml.getPath();
					var filePath = haxe.io.Path.directory( hxmlPath ) + '/' + err.path;
					var file = new File( filePath, false );
					if( file.existsSync() ) {
	//TODO					openErrorPosition( err );
					} else {
						var rel = Atom.project.relativizePath( hxmlPath );
						err.path = rel[0] + '/'+ err.path;
					}

					//openErrorPosition( err );
				}
			}
		});

		element.addEventListener( 'click', handleClick, false );
	}

	public inline function isVisible() {
		return panel.isVisible();
	}

    public inline function show() {
        panel.show();
    }

    public inline function hide() {
        panel.hide();
    }

    public inline function toggle() {
        isVisible() ? hide() : show();
    }

	function destroy() {
		panel.destroy();
	}

	function log( msg : String, ?status : String ) {

		//for( line in msg.split( '\n' ) ) {

		msg = msg.trim();
		if( msg.length == 0 )
			return;

		var message = document.createLIElement();
		message.classList.add( 'message' );
		if( status != null ) message.classList.add( status );
		//message.textContent = msg;

		var time = document.createSpanElement();
		time.classList.add( 'time' );
		time.textContent = Std.string( Std.int( Time.stamp() - timeStart ) );
		message.appendChild( time );

		var content = document.createSpanElement();
		content.classList.add( 'content' );
		content.textContent = msg;
		message.appendChild( content );

		messages.appendChild( message );
		//}
	}

	function handleClick(e) {
		if( e.ctrlKey ) {
			hide();
		}
	}

	static function openPosition( path : String, line : Int, column : Int, activatePane = true, searchAllPanes = true, ?callback : TextEditor->Void ) {
		workspace.open( path, {
			initialLine: line,
			initialColumn: column,
			activatePane: activatePane,
			searchAllPanes : searchAllPanes
		}).then( function(editor:TextEditor) {
			if( callback != null ) callback( editor );
		});
	}

	static function openErrorPosition( err : ErrorMessage ) {

		var line = err.line - 1;

		trace("openErrorPosition");
		trace(err);

		openPosition( err.path, line, err.character, function( editor : TextEditor ) {

			if( err.characters != null ) {
				//editor.selectToEndOfWord();
				//editor.selectWordsContainingCursors();
				//editor.setSelectedScreenRange( [line,column] );
				/*
				editor.setSelectedBufferRange( new Range(
					[ line, err.characters.start ],
					[ line, err.characters.end ]
				) );
				*/
				editor.setSelectedBufferRange( new Range(
					new Point( line, err.characters.start ),
					new Point( line, err.characters.end )
				) );
			}

			/*
			var marker = untyped editor.markBufferPosition( new Point( line, 0 ) );
			trace(marker);

			var item = js.Browser.document.createDivElement();
			item.textContent = err.toString();
			item.classList.add( 'haxe-error-block-marker' );

			editor.decorateMarker( marker, { type:block, position:after, item: item } );

			editor.scrollToCursorPosition();
			*/

			/*1
			for( gutter in editor.getGutters() ) {
				trace( gutter );
			}
			*/

			/*
			var item = document.createDivElement();
			item.textContent = err.toString();
			item.classList.add( 'haxe-error-block-marker' );

			var range = editor.getSelectedBufferRange();
			//var marker = editor.markBufferRange( range );
			var marker = editor.markBufferPosition( new Point( line, 0 ) );

			var decoration = editor.decorateMarker( marker, {
				type: 'line',
				position: after,
				item: item
			});
			*/

			//var gutter = editor.addGutter( { name:'DDD' });
			//gutter.show();

		});

		/*
		workspace.open( err.path, {
			initialLine: line,
			initialColumn: err.character,
			activatePane: true,
			searchAllPanes : true

		}).then( function(editor:TextEditor) {

			if( err.characters != null ) {
				//editor.selectToEndOfWord();
				//editor.selectWordsContainingCursors();
				//editor.setSelectedScreenRange( [line,column] );
				editor.setSelectedBufferRange( new Range(
					[ line, err.characters.start ],
					[ line, err.characters.end ]
				) );
			}

			/*
			var marker = untyped editor.markBufferPosition( new Point( line, 0 ) );
			trace(marker);

			var block = js.Browser.document.createDivElement();
			block.textContent = 'TTTTTTTTTTTTTTTTTTTTTTTTTTTTT';
			block.classList.add( 'haxe-trace-block-marker' );

			untyped editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );
			* /

			editor.scrollToCursorPosition();

		});
		*/
	}
}
