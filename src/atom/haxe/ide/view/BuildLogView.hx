package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import haxe.compiler.ErrorMessage;

class BuildLogView {

    public var dom(default,null) : DivElement;

    var panel : atom.Panel;
    var messages : DivElement;

    public function new() {

        dom = document.createDivElement();
        dom.classList.add( 'build-log' );

        messages = document.createDivElement();
        messages.classList.add( 'messages' );
        dom.appendChild( messages );

        panel = Atom.workspace.addBottomPanel( { item:dom, visible:false } );

        dom.addEventListener( 'contextmenu', handleRightClick, false );
    }

    public function show() {
        panel.show();
    }

    public function hide() {
        panel.hide();
    }

    public function message( msg : String, ?status : String ) {
        var view = new LogMessageView( msg, messages.children.length, status );
        messages.appendChild( view.dom );
        return this;
    }

    public function error( err : ErrorMessage ) {
        var view = new ErrorMessageView( err, messages.children.length );
        messages.appendChild( view.dom );
        return this;
    }

    public function clear() {
        while( messages.firstChild != null )
            messages.removeChild( messages.firstChild );
    }

    public function destroy() {
        dom.removeEventListener( 'contextmenu', handleRightClick );
    }

    function handleRightClick(e) {
        if( e.which != 1 ) {
            hide();
            clear();
        }
    }
}

private class MessageView {

    public var dom(default,null) : DivElement;

    function new( index : Int ) {

        dom = document.createDivElement();
        dom.setAttribute( 'tabindex', '$index' );
        dom.classList.add( 'message' );

        dom.addEventListener( 'click', handleClick, false );
    }

    function handleClick(e) {
        if( e.ctrlKey ) copyToClipboard();
    }

    function copyToClipboard() {}
}

private class LogMessageView extends MessageView {

    var text : String;

    public function new( text : String, index : Int, ?status : String ) {

        super( index );
        this.text = text;

        if( status != null ) dom.classList.add( status );

        var content = document.createSpanElement();
        content.classList.add( 'content' );
        //content.textContent = StringTools.htmlUnescape( text );
        content.textContent = text;
        dom.appendChild( content );

    }

    override function copyToClipboard() {
        Atom.clipboard.write( text );
    }
}

private class ErrorMessageView extends MessageView {

    var error : ErrorMessage;

    public function new( error : ErrorMessage, index : Int ) {

        super( index );
        this.error = error;

        dom.classList.add( 'error' );

        var icon = document.createSpanElement();
        icon.classList.add( 'icon', 'icon-bug' );
        dom.appendChild( icon );

        var path = document.createAnchorElement();
        path.classList.add( 'link' );
        path.textContent = error.path;
        dom.appendChild( path );
        path.onclick = function(_) open();

        span( ':' );

        var line = document.createAnchorElement();
        line.classList.add( 'link' );
        line.textContent = Std.string( error.line );
        dom.appendChild( line );
        line.onclick = function(_) open( error.line-1 );


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
        dom.appendChild( pos );

        /*
        span( ': characters ' );

        var pos = document.createAnchorElement();
        pos.classList.add( 'link' );
        pos.textContent = error.pos.start+'-'+error.pos.end;
        dom.appendChild( pos );
        pos.onclick = function(_) open( error.line-1, error.pos.start-1 );
        */

        span( ': ' );

        var content = document.createSpanElement();
        content.classList.add( 'content' );
        content.textContent = error.content;
        dom.appendChild( content );
    }

    override function copyToClipboard() {
        Atom.clipboard.write( error.toString() );
    }

    function open( line : Null<Int> = null, column : Null<Int> = null ) {

        //var editor = Atom.workspace.getActiveTextEditor();
        //trace(untyped editor.buffer.file.path);
        //trace(error.path);
        //editor.selectAll();

        Atom.workspace.open( error.path, {
            initialLine: line,
            initialColumn: column
        });
    }

    function span( text : String ) {
        var e = document.createSpanElement();
        e.textContent = text;
        dom.appendChild( e );
    }
}
