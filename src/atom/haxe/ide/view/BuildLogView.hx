package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import haxe.compiler.ErrorMessage;

class BuildLogView {

    public var element(default,null) : DivElement;

    var panel : atom.Panel;
    var messages : DivElement;
    var numMessages : Int;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'build-log' );

        messages = document.createDivElement();
        messages.classList.add( 'messages' );
        element.appendChild( messages );

        panel = Atom.workspace.addBottomPanel( { item: element, visible: false } );

        element.addEventListener( 'contextmenu', handleRightClick, false );

        numMessages = 0;
    }

    public inline function show() {
        panel.show();
    }

    public inline function hide() {
        panel.hide();
    }

    public function message( msg : String, ?status : String ) {
        if( msg != null && msg.length > 0 ) {
            numMessages++;
            var view = new LogMessageView( msg, messages.children.length, status, numMessages );
            messages.appendChild( view.element );
        }
        return this;
    }

    public function error( err : ErrorMessage ) {
        numMessages++;
        var view = new ErrorMessageView( err, messages.children.length, numMessages );
        messages.appendChild( view.element );
        return this;
    }

    public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
        numMessages = 0;
    }

    public function destroy() {
        element.removeEventListener( 'contextmenu', handleRightClick );
        panel.destroy();
    }

    function handleRightClick(e) {
        if( e.which != 1 ) {
            hide();
            clear();
        }
    }

    function handleKeyDown(e) {
        trace(e);
    }
}

private class MessageView {

    public var element(default,null) : DivElement;

    function new( index : Int, num : Int ) {

        element = document.createDivElement();
        element.classList.add( 'message' );
        //element.setAttribute( 'tabindex', '$index' );

        var messageNum = document.createSpanElement();
        messageNum.classList.add( 'num' );
        messageNum.textContent = Std.string( num );
        element.appendChild( messageNum );

        element.addEventListener( 'click', handleClick, false );
    }

    function handleClick(e) {
        if( e.ctrlKey ) copyToClipboard();
    }

    function copyToClipboard() {}
}

private class LogMessageView extends MessageView {

    var text : String;

    public function new( text : String, index : Int, ?status : String, num : Int ) {

        super( index, num );
        this.text = text;

        if( status != null ) element.classList.add( status );

        var content = document.createSpanElement();
        content.classList.add( 'content' );
        content.textContent = text;
        element.appendChild( content );
    }

    override function copyToClipboard() {
        Atom.clipboard.write( text );
    }
}

private class ErrorMessageView extends MessageView {

    var error : ErrorMessage;

    public function new( error : ErrorMessage, index : Int, num : Int ) {

        super( index, num );
        this.error = error;

        element.classList.add( 'error' );

        var icon = document.createSpanElement();
        icon.classList.add( 'icon', 'icon-bug' );
        element.appendChild( icon );

        link( error.path );
        span( ':' );
        link( Std.string( error.line ), error.line-1 );

        var pos = document.createAnchorElement();
        pos.classList.add( 'link' );
        if( error.character != null ) {
            span( ': character ' );
            pos.textContent = Std.string( error.character );
        } else if( error.characters != null )  {
            span( ': characters ' );
            pos.textContent = error.characters.start+'-'+error.characters.end;
        } else {
            span( ': lines ' );
            pos.textContent = error.lines.start+'-'+error.lines.end;
        }
        pos.onclick = function(_) open( error.line-1, error.characters.start-1 );
        element.appendChild( pos );

        span( ': ' );

        span( error.content, ['content'] );
    }

    override function copyToClipboard() {
        Atom.clipboard.write( error.toString() );
    }

    function open( line : Null<Int> = null, column : Null<Int> = null ) {
        Atom.workspace.open( error.path, {
            initialLine: line,
            initialColumn: column,
            activatePane: true,
            searchAllPanes : true
        }).then( function(editor:TextEditor){
            editor.scrollToCursorPosition();
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

    function link( text : String, ?line : Null<Int> ) : AnchorElement {
        var e = document.createAnchorElement();
        e.classList.add( 'link' );
        e.textContent = text;
        element.appendChild( e );
        e.onclick = function(_) open( line );
        return e;
    }

    function span( text : String, ?classes : Array<String> ) {
        var e = document.createSpanElement();
        if( classes != null ) for( c in classes ) e.classList.add(c);
        e.textContent = text;
        element.appendChild( e );
    }
}
