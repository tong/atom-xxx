package xxx.atom.view;

import Atom.contextMenu;
import Atom.workspace;
import atom.Panel;
import js.Browser.document;
import js.Browser.window;
import js.html.Element;
import js.html.DivElement;
import js.html.LIElement;
import js.html.OListElement;
import js.html.SpanElement;
import js.html.TimeElement;
import om.haxe.ErrorMessage;

using haxe.io.Path;

class BuildLogView implements atom.Disposable {

    var panel : Panel;
    var element : DivElement;
    var messageContainer : OListElement;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'haxe-buildlog', 'resizer' );

        messageContainer = document.createOListElement();
        //messageContainer.classList.add( 'list-group', 'messages', 'scroller' );
        messageContainer.classList.add( 'messages', 'scroller' );
        element.appendChild( messageContainer );

        panel = workspace.addBottomPanel( { item: element, visible: true } );

        element.addEventListener( 'contextmenu', handleRightClick, false );
        //window.addEventListener( 'keydown', handleKeyDown, false );
    }

    public inline function isVisible() : Bool
        return panel.isVisible();

    public inline function toggle() : BuildLogView {
        isVisible() ? hide() : show();
        return this;
    }

    public inline function show() : BuildLogView {
        panel.show();
        return this;
    }

    public inline function hide() : BuildLogView {
        panel.hide();
        return this;
    }

    public function clear() : BuildLogView {
        while( messageContainer.firstChild != null )
            messageContainer.removeChild( messageContainer.firstChild );
        return this;
    }

    public function dispose() {
        panel.destroy();
    }

    public function log( text : String, level : String ) : BuildLogView {
        var msg = new MessageView( text, level );
        //messageContainer.appendChild( view.element );
        appendMessage( msg );
        return this;
    }

    public inline function info( text : String ) : BuildLogView
        return log( text, 'info' );

    public function error( text : String ) : BuildLogView
        return log( text, 'error' );

    public function errorMessage( error : ErrorMessage ) : BuildLogView {
        var msg = new ErrorMessageView( error );
        //messageContainer.appendChild( msg.element );
        appendMessage( msg );
        return this;
    }

    function appendMessage( msg : MessageView, printTime = true ) {
        /*
        var container = document.createDivElement();
        if( printTime ) {
            var now = Date.now();
            var time = document.createSpanElement();
            time.classList.add();
            time.textContent += now.getHours();
            time.textContent += ':'+now.getMinutes();
            time.textContent += ':'+now.getSeconds();
            container.appendChild( time );
        }
        container.appendChild( msg.element );
        */
        messageContainer.appendChild( msg.element );
        //messageContainer.appendChild( container );
    }

    function handleRightClick(e) {
        if( e.which != 1 ) {
            hide();
            //clear();
        }
    }

    /*
    function handleKeyDown(e) {
        trace(e.keyCode);
    }
    */
}

private class MessageView {

    public var element(default,null) : LIElement;

    var time : TimeElement;
    var content : DivElement;

    public function new( text : String, status : String, ?iconId : String ) {

        element = document.createLIElement();
        //element.classList.add( 'list-item', 'message', status );
        element.classList.add( 'message', status );

        /*
        var now = Date.now();
        time = cast document.createElement( 'time' );
        time.dateTime = now.toString();
        time.textContent = now.getHours() +':'+ now.getMinutes() +':'+ now.getSeconds();
        element.appendChild( time );
        */

        /*
        if( iconId != null ) {
            var i = document.createElement('i');
            i.classList.add( 'icon', 'icon-$iconId' );
            element.appendChild(i);
        }
        */

        content = document.createDivElement();
        content.classList.add( 'content', status );
        content.textContent = text;

        if( iconId != null ) {
            content.classList.add( 'icon', 'icon-$iconId' );
        }

        /*
        for( line in text.split( '\n' ) ) {
            var e = document.createDivElement();
            e.textContent = line;
            content.appendChild(e);
        }
        */

        switch status {
        case 'error':
            //var i = document.createElement('i');
            //i.classList.add( 'icon', 'icon-bug' );
            //element.appendChild(i);
        }

        element.appendChild( content );
    }

    public function destroy() {
        //..
    }
}

private class ErrorMessageView extends MessageView {

    public function new( error : ErrorMessage ) {
        super( error.toString(), 'error', 'bug' );
    }
}
