package xxx.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.OListElement;
import js.html.SpanElement;
import om.Time;
import atom.Disposable;
import atom.File;
import atom.Panel;
import atom.TextEditor;
import Atom.workspace;

using StringTools;
using haxe.io.Path;

class BuildView implements atom.Disposable {

	var panel : Panel;
    var element : DivElement;
    var messages : OListElement;

	public function new() {

        element = document.createDivElement();
        element.classList.add( 'xxx-build', 'inline-block' );

		messages = document.createOListElement();
		messages.classList.add( 'messages','scroller' );
		element.appendChild( messages );

		panel = workspace.addBottomPanel( { item: element, visible: true } );

		//IDE.build.onStart();

		IDE.onBuild( function(build){

			clear();

			build.onMessage( function(msg){
				var m = document.createLIElement();
				m.classList.add( 'message' );
				m.textContent = msg;
				messages.appendChild(m);
			});

			build.onError( function(str){

				str = str.trim();
				//trace(str);

				var err = om.haxe.ErrorMessage.parse( str );
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
				}

			});
		});

		/*
		IDE.build.on( 'start', function(msg){
			clear();
		});

		IDE.build.on( 'end', function(msg){
			if( messages.children.length == 0 )
				hide();
		});

		IDE.build.on( 'message', function(msg){
			var m = document.createLIElement();
			m.classList.add( 'message' );
			m.textContent = msg;
			messages.appendChild(m);
		});

		IDE.build.on( 'error', function(str:String){

			str = str.trim();
			//trace(str);

			var err = om.haxe.ErrorMessage.parse( str );
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
			}
		});
		*/

		element.addEventListener( 'click', handleClick, false );
	}

	public inline function isVisible() : Bool
        return panel.isVisible();

    public inline function show() {
        panel.show();
    }

    public inline function hide() {
        panel.hide();
    }

    public inline function toggle() {
        isVisible() ? hide() : show();
    }

	public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
    }

	public inline function dispose() {
        panel.destroy();
    }

	/*
	function openFile( err : om.haxe.ErrorMessage ) {
		Atom.workspace.open( err.path, {
            initialLine: err.line,
            initialColumn: err.character,
            activatePane: true,
            searchAllPanes : true
        }).then( function(editor:TextEditor){
            //editor.scrollToCursorPosition();
                editor.setSelectedBufferRange( new atom.Range(
                    [err.line,err.characters.start],
                    [err.line,err.characters.end]
                ) );
            //editor.selectToEndOfWord();
            //editor.selectWordsContainingCursors();
            //editor.setSelectedScreenRange( [line,column] );
        });
	}
	*/

	function handleClick(e) {
		hide();
		/*
		trace(e);
        if( e.which != 1 ) {
            //clear();
        }
		*/
    }

}
