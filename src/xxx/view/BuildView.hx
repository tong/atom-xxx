package xxx.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.LIElement;
import js.html.OListElement;
import js.html.SpanElement;
import om.Time;
import atom.Disposable;
import atom.File;
import atom.Panel;
import atom.Point;
import atom.Range;
import atom.TextEditor;
import Atom.workspace;

import om.haxe.ErrorMessage;

using StringTools;
using haxe.io.Path;

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
		content.classList.add( 'content' );
		content.textContent = err.content;
		element.appendChild( content );

		//var btn = document.createSpanElement();
		//btn.classList.add( 'icon', 'icon-clippy' );
		//element.appendChild( btn );

		//element.onclick = function()
	}

	public function select() {
		element.classList.add( 'selected' );
	}

	public function unselect() {
		element.classList.remove( 'selected' );
	}
}

class BuildView {

	static var current : BuildView;

	var panel : Panel;
    var element : DivElement;
	var messages : OListElement;

	public function new( build : Build ) {

		if( current != null ) {
			current.destroy();
		}

		current = this;

		element = document.createDivElement();
        element.classList.add( 'xxx-build', 'resizer' );

		messages = document.createOListElement();
		messages.classList.add( 'messages', 'scroller' );
		element.appendChild( messages );

		panel = workspace.addBottomPanel( { item: element, visible: true } );

		var errors = new Array<ErrorMessage>();

		build.onStart( function(){
			errors = [];
		});
		build.onMessage( function(msg){
			trace(msg);
			var e = document.createLIElement();
			e.classList.add( 'message' );
			e.textContent = msg;
			messages.appendChild(e);
		});
		build.onError( function(err){

			errors.push( err );

			var view = new ErrorMessageView( messages.children.length, err );
			view.element.onclick = function() {
				view.select();
				openErrorPosition( err );
			}
			messages.appendChild( view.element );

		});
		build.onEnd( function(code){
			switch code {
			case 0:
				if( messages.children.length == 0 )
					hide();
			case _:
				if( errors.length > 0 ) {

					var err = errors[0];

					//TODO

					var file = new File( err.path );
					var rel = Atom.project.relativizePath( build.hxml.getPath() );
					trace(rel);
					/*

					var path = rel[0] +'/'+ err.path;
					err.path = path;
					trace(err.path);
					openErrorPosition( err );
					*/
				}
			}
		});
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

		openPosition( err.path, line, err.character, function(editor){

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
			block.textContent = err.toString();
			block.classList.add( 'haxe-error-block-marker' );

			untyped editor.decorateMarker( marker, { type:DecorationType.block, position:after, item: block } );
			*/

			editor.scrollToCursorPosition();

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

	/*
	var panel : Panel;
    var element : DivElement;
    var messages : OListElement;
	var errors : Array<ErrorMessage>;

	public function new() {

        element = document.createDivElement();
        element.classList.add( 'xxx-build', 'resizer' );

		messages = document.createOListElement();
		messages.classList.add( 'messages', 'scroller' );
		element.appendChild( messages );

		panel = workspace.addBottomPanel( { item: element, visible: false } );

		//IDE.build.onStart();

		IDE.onBuild( function(build){

			errors = [];

			clear();
			show();

			build.onMessage( function(msg){

				trace(msg);

				var m = document.createLIElement();
				m.classList.add( 'message' );
				m.textContent = msg;
				messages.appendChild(m);

				//scrollToBottom();
			});

			build.onError( function(str){

				var err = ErrorMessage.parse( str );
				errors.push(err);

				if( err == null ) {
					//TODO
					trace('??????????????');
					var m = document.createLIElement();
					m.classList.add( 'message', 'error' );
					m.textContent = str;
					messages.appendChild(m);

				} else {

					var msg = document.createLIElement();
					msg.classList.add( 'message', 'error' );

					var path = document.createSpanElement();
					path.classList.add( 'path' );
					path.textContent = err.path;
					msg.appendChild( path );

					var line = document.createSpanElement();
					line.classList.add( 'line' );
					line.textContent = Std.string( err.line );
					msg.appendChild( line );

					if( err.characters != null ) {

						var start = document.createSpanElement();
						start.classList.add( 'start' );
						start.textContent = Std.string( err.characters.start );
						msg.appendChild( start );

						var end = document.createSpanElement();
						end.classList.add( 'end' );
						end.textContent = Std.string( err.characters.end );
						msg.appendChild( end );
					}

					var content = document.createSpanElement();
					content.classList.add( 'content' );
					content.textContent = err.content;
					msg.appendChild( content );

					msg.onclick = function() {
						//TODO
					}
						//openFile( err );

					messages.appendChild( msg );

					//scrollToBottom();
				}
			});

			build.onEnd( function(code){

				switch code {

				case 0:
					//hide();

				default:

					var err = errors[0];
					var line = err.line - 1;

					Atom.workspace.open( err.path, {
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
				}
			});
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

	public inline function scrollToBottom() {
        //messages.scrollTop = 200; //messages.scrollHeight;
        //element.scrollTop = messages.scrollHeight;
        //element.scrollTop = 200;
    }

	public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
    }

	public inline function dispose() {
        panel.destroy();
    }

	function handleClick(e) {
		hide();
		/*
		trace(e);
        if( e.which != 1 ) {
            //clear();
        }
		* /
    }
	*/

}
