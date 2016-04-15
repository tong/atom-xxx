package xxx.atom.view;

import js.Browser.console;
import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.SpanElement;
import Atom.workspace;

using StringTools;

@:keep
class ServerLogView {

    public var maxMessages(default,null) : Int;

    var element : DivElement;
    var messages : DivElement;
	var panel : atom.Panel;

    @:allow(xxx.atom.IDE) function new( ?visible : Dynamic ) {

        //maxMessages = IDE.getConfigValue( 'serverlog_max_messages' );
        maxMessages = 2000; //IDE.getConfigValue( 'serverlog_max_messages' );

        element = document.createDivElement();
        element.classList.add( 'haxe-serverlog', 'resizer' );

        messages = document.createDivElement();
        messages.classList.add( 'messages', 'scroller' );
        element.appendChild( messages );

        panel = Atom.workspace.addRightPanel( { item: element, visible: false } );

        element.addEventListener( 'click', handleClick, false  );
        //element.addEventListener( 'contextmenu', handleContextMenu, false  );
    }

    public inline function isVisible() : Bool {
        return panel.isVisible();
    }

    public inline function show() {
        panel.show();
    }

    public inline function hide() {
        panel.hide();
        //Atom.views.getView( Atom.workspace ).focus();
    }

    public inline function toggle() {
        isVisible() ? hide() : show();
    }

    public function add( text : String ) : Array<String> {

        //if( !panel.isVisible() )
        //    return [];

        //TODO completion fucks it up
        //return [];

        //trace(text);

        if( text.startsWith( 'Completion Response =' ) ) {
            text = text.substr( 19 );
            console.debug(text);
            return [];
        }

        var lines = new Array<String>();

        for( line in text.split( '\n' ) ) {

            if( (line = line.trim()).length == 0 )
                continue;

            if( messages.children.length == maxMessages ) {
                messages.removeChild( messages.firstChild );
            }

            var firstWord = line.substr( 0, line.indexOf(' ') ).toLowerCase();
            if( firstWord == '>' ) firstWord = 'error';
            else if( firstWord == null ) {
                var err = 'Unknown haxe build info token: '+firstWord;
                console.error(err);
                Atom.notifications.addWarning( 'Unknown haxe build info token: '+firstWord );
                return null;
            }

            var e = document.createDivElement();
            e.classList.add( 'message', firstWord );
            messages.appendChild( e );

            trace(firstWord);

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

            default:
                e.textContent = line;
            }

            lines.push( line );
        }

        return lines;
    }

	public inline function scrollToBottom() {
		element.scrollTop = messages.scrollHeight;
	}

    public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
    }

    public function destroy() {
        element.removeEventListener( 'click', handleClick );
        //element.removeEventListener( 'contextmenu', handleContextMenu );
        panel.destroy();
    }


    function handleClick(e) {
        if( e.ctrlKey ) {
            e.preventDefault();
            e.stopPropagation();
            clear();
        }
    }

	/*
    function handleContextMenu(e) {
        hide();
    }
	*/
}
