package xxx.atom.view;

import Atom.contextMenu;
import Atom.workspace;
import atom.Panel;
import atom.TextEditor;
import js.Browser.document;
import js.Browser.window;
import js.html.AnchorElement;
import js.html.Element;
import js.html.DivElement;
import js.html.LIElement;
import js.html.OListElement;
import js.html.SpanElement;
import js.html.TimeElement;
import om.haxe.ErrorMessage;

using haxe.io.Path;
using om.util.ArrayUtil;

class BuildLogView implements atom.Disposable {

    var panel : Panel;
    var element : DivElement;
    var messages : OListElement;
    //var metaInfo : DivElement;
    //var errorResolver : DivElement;

    var errors : Array<ErrorMessage>;

    public function new() {

        errors = [];

        element = document.createDivElement();
        element.classList.add( 'haxe-buildlog', 'resizer' );

        messages = document.createOListElement();
        //messageContainer.classList.add( 'list-group', 'messages', 'scroller' );
        messages.classList.add( 'messages', 'scroller' );
        element.appendChild( messages );

        panel = workspace.addBottomPanel( { item: element, visible: true } );

        element.addEventListener( 'contextmenu', handleRightClick, false );
        window.addEventListener( 'keydown', handleKeyDown, false );
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
        errors = [];
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
        return this;
    }

    public function scrollToBottom() {
        element.scrollTop = messages.scrollHeight;
    }

    public function log( str : String, level : String ) : BuildLogView {
        var msg = new LogMessageView( str );
        //messageContainer.appendChild( view.element );
        appendMessage( msg );
        return this;
    }

    public inline function info( str : String ) : BuildLogView
        return log( str, 'info' );

    public function error( text : String ) : BuildLogView
        return log( text, 'error' );

    public function errorMessage( error : ErrorMessage ) : BuildLogView {
        var msg = new ErrorMessageView( error );
        appendMessage( msg );
        errors.push( error );
        return this;
    }

    public function dispose() {
        panel.destroy();
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
        messages.appendChild( msg.element );
        //messageContainer.appendChild( container );
    }

    function handleRightClick(e) {
        if( e.which != 1 ) {
            hide();
            //clear();
        }
    }

    function handleKeyDown(e) {
        trace(e.keyCode);
    }
}

private class MessageView {

    public var element(default,null) : LIElement;

    var time : TimeElement;
    var content : DivElement;

    public function new( status : String, ?iconId : String ) {

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
        //content.textContent = text;

        if( iconId != null ) {
            //content.classList.add( 'icon', 'icon-$iconId' );
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

private class LogMessageView extends MessageView {

    public function new( msg : String ) {
        super( 'log' );
        content.textContent = msg;
    }
}

private class ErrorMessageView extends MessageView {

    var error : ErrorMessage;

    public function new( error : ErrorMessage ) {

        super( 'error', 'bug' );
        this.error = error;

        var parts = Atom.project.relativizePath( error.path );
        var dir = parts[0].split( '/' );

        addLink( dir.last() + '/' + parts[1] );
        addSpan( ':' );
        addLink( Std.string( error.line ), error.line-1 );

        if( error.characters != null ) {
            addSpan( ': ' );
            addLink( 'characters '+error.characters.start+'-'+error.characters.end );
            addSpan( ': ' );
        }

        /*
        var pos = document.createSpanElement();
        pos.classList.add( 'link' );
        if( error.character != null ) {
            //addSpan( ': character ' );
            //pos.textContent = Std.string( error.character );
        } else if( error.characters != null )  {
            //addSpan( ': characters ' );
            //pos.textContent = error.characters.start+'-'+error.characters.end;
        } else {
            //addSpan( ': lines ' );
            //pos.textContent = error.lines.start+'-'+error.lines.end;
        }
        //pos.onclick = function(_) open( error.line-1, error.characters.start-1 );
        element.appendChild( pos );

        addSpan( ': ' );
        */

        addSpan( error.content );
        //content.textContent = error.content;
        //content.textContent = error.toString();
    }

    function addLink( text : String, ?line : Null<Int> ) : AnchorElement {
        var e = document.createAnchorElement();
        e.classList.add( 'link' );
        e.textContent = text;
        content.appendChild( e );
        e.onclick = function(_) open( line );
        return e;
    }

    function addSpan( text : String, ?classes : Array<String> ) {
        var e = document.createSpanElement();
        if( classes != null ) for( c in classes ) e.classList.add(c);
        e.textContent = text;
        content.appendChild( e );
    }

    function open( line : Null<Int> = null, column : Null<Int> = null ) {
        Atom.workspace.open( error.path, {
            initialLine: line,
            initialColumn: column,
            activatePane: true,
            searchAllPanes : true
        }).then( function(editor:TextEditor){

            trace(":::::");
            //editor.scrollToCursorPosition();

            trace(line,column);

            /*
            if( column == null ) {
                //TODO select line
            }
            */
            //editor.selectToEndOfWord();
            //editor.selectWordsContainingCursors();
            //editor.setSelectedScreenRange( [line,column] );
        });
    }
}
