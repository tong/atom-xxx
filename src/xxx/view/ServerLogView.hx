package xxx.view;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.OListElement;
import js.html.SpanElement;
import Atom.workspace;

using StringTools;

class ServerLogView implements atom.Disposable {

	var panel : atom.Panel;
    var element : DivElement;
    var messages : OListElement;
	//var maxMessages = 100;

	public function new( ) {

		element = document.createDivElement();
        element.classList.add( 'haxe-serverlog', 'resizer' );

		messages = document.createOListElement();
		messages.classList.add( 'messages', 'scroller' );
		element.appendChild( messages );

		panel = Atom.workspace.addRightPanel( { item: element, visible: false } );

		/*
		IDE.build.on( 'start', function(msg){
			clear();
		});
		*/

		var isComplete = false;

		IDE.server.onMessage( function(msg){

			//var prevFirstWord : string = null;

			if( msg.startsWith( 'Completion Response =' ) ) {
	            msg = msg.substr( 19 );
	            console.debug( msg );
	            return;
	        }

			if( isComplete ) {
				trace("COMPLETE");
				isComplete = false;
				clear();
			}

			//var lines = new Array<String>();

			for( line in msg.split( '\n' ) ) {

				if( (line = line.trim()).length == 0 )
                	continue;

				/*
				if( messages.children.length == maxMessages ) {
	                messages.removeChild( messages.firstChild );
	            }
				*/

				var firstWord = line.substr( 0, line.indexOf(' ') ).toLowerCase();
				if( firstWord == '>' ) firstWord = 'error';
				else if( firstWord == null ) {
	                var err = 'Unknown haxe build info token: '+firstWord;
	                console.error(err);
	                Atom.notifications.addWarning( 'Unknown haxe build info token: '+firstWord );
	                return;
	            }

				var e = document.createLIElement();
				e.classList.add( 'message', firstWord );
				e.textContent = line;
				messages.appendChild( e );

				switch firstWord {

            	case 'parsed':

					var title = document.createSpanElement();
	                title.textContent = 'Parsed';
	                e.appendChild( title );

	                var link = document.createSpanElement();
	                link.classList.add( 'link' );
	                link.onclick = function(e){
	                    if( !e.ctrlKey ) workspace.open( line.substr(7) );
	                }
	                link.textContent = line.substr(7);
	                e.appendChild( link );

				case 'processing':

	                var title = document.createDivElement();
	                title.textContent = 'Processing Arguments';
	                e.appendChild( title );

	                var str = line.substring( line.indexOf('[')+1, line.length-1 );
	                var args = str.split( ',' );
	                var i = 0;
	                while( i < args.length ) {
	                    var text = args[i];
	                    var next = args[i+1];
	                    if( next != null && !next.startsWith( '-' ) ) {
	                        text += ' $next';
	                        i++;
	                    }
	                    var child = document.createDivElement();
	                    child.textContent = text;
	                    child.classList.add( 'param' );
	                    e.appendChild( child );
	                    i++;
	                }

				case 'time':
	                e.textContent = line;
	                scrollToBottom();
					isComplete = true;

	            default:
	                e.textContent = line;

				}
			}
		});

		Atom.commands.add( 'atom-workspace', 'haxe:toggle-server-log', function(e) toggle() );

		element.addEventListener( 'click', handleClick, false  );
	}

	public function dispose() {
		element.removeEventListener( 'click', handleClick );
		panel.destroy();
	}

    public inline function isVisible()
		return panel.isVisible();

    public inline function show()
        panel.show();

    public inline function hide()
        panel.hide();

    public inline function toggle()
        isVisible() ? hide() : show();

	public function clear() {
		while( messages.firstChild != null )
			messages.removeChild( messages.firstChild );
	}

	public inline function scrollToBottom() {
		element.scrollTop = messages.scrollHeight;
	}

	function handleClick(e) {
        if( e.ctrlKey ) {
            //e.preventDefault();
            //e.stopPropagation();
            //clear();
			toggle();
        }
    }
}
