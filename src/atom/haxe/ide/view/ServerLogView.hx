package atom.haxe.ide.view;

import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.SpanElement;

using StringTools;

class ServerLogView {

    var panel : atom.Panel;
    var dom : DivElement;
    var messages : DivElement;

    public function new() {

        dom = document.createDivElement();
        dom.classList.add( 'server-log', 'resizer' );

        messages = document.createDivElement();
        messages.classList.add( 'messages', 'scroller' );
        dom.appendChild( messages );

        panel = Atom.workspace.addRightPanel( { item:dom, visible:false } );

        dom.addEventListener( 'click', handleClick, false  );
        dom.addEventListener( 'contextmenu', handleContextMenu, false  );
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
        dom.removeEventListener( 'click', handleClick );
        dom.removeEventListener( 'contextmenu', handleContextMenu );
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
