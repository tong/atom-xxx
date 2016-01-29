package atom.haxe.ide.view;

import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.SpanElement;
import Atom.workspace;

using StringTools;

class ServerLogView {

    var panel : atom.Panel;
    var element : DivElement;
    var messages : DivElement;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'server-log', 'resizer' );

        messages = document.createDivElement();
        messages.classList.add( 'messages', 'scroller' );
        element.appendChild( messages );

        panel = Atom.workspace.addRightPanel( { item: element, visible: false } );

        element.addEventListener( 'click', handleClick, false  );
        element.addEventListener( 'contextmenu', handleContextMenu, false  );
    }

    public function add( text : String ) {

        for( line in text.split( '\n' ) ) {

            if( (line = line.trim()).length == 0 )
                continue;

            var firstWord = line.substr( 0, line.indexOf(' ') ).toLowerCase();
            if( firstWord == '>' ) firstWord = 'error';

            var e = document.createDivElement();
            e.classList.add( 'message', firstWord );
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

            default:
                e.textContent = line;
            }
        }
    }

    public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
    }

    public function show() {
        panel.show();
    }

    public function hide() {
        panel.hide();
        Atom.views.getView( Atom.workspace ).focus();
    }

    public function toggle() {
        panel.isVisible() ? hide() : show();
    }

    public inline function scrollToBottom() {
        element.scrollTop = messages.scrollHeight;
    }

    public function destroy() {
        element.removeEventListener( 'click', handleClick );
        element.removeEventListener( 'contextmenu', handleContextMenu );
    }

    function handleClick(e) {
        if( e.ctrlKey ) {
            e.preventDefault();
            e.stopPropagation();
            clear();
        }
    }

    function handleContextMenu(e) {
        hide();
    }
}
