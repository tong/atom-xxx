package atom.haxe.ide.view;

import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.SpanElement;

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
            if( line.length == 0 )
                continue;
            var e = document.createDivElement();
            e.classList.add( 'message' );
            e.textContent = line;
            if( line.startsWith( 'Parsed ' ) ) {
                e.classList.add( 'link' );
                e.onclick = function(e){
                    if( !e.ctrlKey )
                        Atom.workspace.open( line.substr(7) );
                }
            }
            messages.appendChild( e );
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
        messages.scrollTop = messages.scrollHeight;
    }

    public function destroy() {
        element.removeEventListener( 'click', handleClick );
        element.removeEventListener( 'contextmenu', handleContextMenu );
    }

    function handleClick(e) {
        if( e.ctrlKey ) {
            e.preventDefault();
            e.stopPropagation();
            hide();
        }
    }

    function handleContextMenu(e) {
        hide();
    }

}
