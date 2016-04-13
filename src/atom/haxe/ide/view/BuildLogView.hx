package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import om.haxe.ErrorMessage;

using StringTools;

class BuildLogView {

    public var element(default,null) : DivElement;
    public var showLineNumbers(default,set) : Bool;

    var panel : atom.Panel;
    var messageContainer : DivElement;
    var numMessages : Int;
    var messages : Array<MessageView>;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'build-log' );

        messageContainer = document.createDivElement();
        messageContainer.classList.add( 'messages' );
        element.appendChild( messageContainer );

        element.addEventListener( 'contextmenu', handleRightClick, false );

        panel = Atom.workspace.addBottomPanel( { item: element, visible: false } );

        numMessages = 0;
        messages = [];

        this.showLineNumbers = Atom.config.get( 'haxe-ide.buildlog_numbers' );
    }

    inline function set_showLineNumbers(v:Bool) : Bool {
        //number.style.display = v ? 'inline-block' : 'none';
        for( message in messages )
            message.showLineNumber = v;
        return showLineNumbers = v;
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
            var view = new LogMessageView( msg, messages.length, status, numMessages, showLineNumbers );
            messageContainer.appendChild( view.element );
            messages.push( view );
        }
        return this;
    }

    public function error( err : ErrorMessage ) {
        numMessages++;
        var view = new ErrorMessageView( err, messages.length, numMessages, showLineNumbers );
        messageContainer.appendChild( view.element );
        messages.push( view );
        return this;
    }

    public function meta( msg : String ) : BuildLogView {
        var view = new MetaMessageView( msg );
        messageContainer.appendChild( view.element );
        return this;
    }

    public function clear() {
        while( messageContainer.firstChild != null )
            messageContainer.removeChild( messageContainer.firstChild );
        numMessages = 0;
        messages = [];
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
        //trace(e);
    }
}

private class MessageView {

    public var element(default,null) : Element;
    public var showLineNumber(get,set) : Bool;

    var number : Element;
    var content : Element;

    function new( index : Int, num : Int, showLineNumber : Bool ) {

        //element = document.createElement( 'pre' );
        element = document.createDivElement();
        element.classList.add( 'message' );
        //element.setAttribute( 'tabindex', '$index' );

        //var messageNum = document.createElement( 'pre' );
        number = document.createSpanElement( );
        number.classList.add( 'num' );
        number.textContent = Std.string( num );
        element.appendChild( number );

        this.showLineNumber = showLineNumber;

        content = document.createSpanElement();
        content.classList.add( 'content' );
        element.appendChild( content );

        element.addEventListener( 'click', handleClick, false );
    }

    inline function get_showLineNumber() : Bool return number.style.display == 'inline-block';
    inline function set_showLineNumber(v:Bool) : Bool {
        number.style.display = v ? 'inline-block' : 'none';
        return v;
    }

    function copyToClipboard() {}

    function handleClick(e) {
        if( e.ctrlKey ) copyToClipboard();
    }

    static function ansiToHTML( str : String ) : String {
        //TODO
        var regexp = untyped __js__('/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g');
        var html = '';
        for( line in str.split( '\n' ) ) {
            if( (line = line.trim()).length == 0 ) {
                continue;
            }
            var ansiCodes : Array<String> = untyped line.match( regexp );
            if( ansiCodes != null && ansiCodes.length > 0 ) {
                var ansiCode = Std.parseInt( ansiCodes[0].substr( 2, ansiCodes[0].length - 2 ) );
                var ansiType = getAnsiType( ansiCode );
                if( ansiType != null ) {
                    var classes = '$ansiType';
                    /*
                    var icon = switch ansiType {
                        case 'info': 'info';
                        //case 'debug': 'debug';
                        case 'warning': 'alert';
                        case 'error': 'bug';
                        case 'success': 'check';
                        default: null;
                    }
                    if( icon != null ) {
                        classes += ' icon icon-$icon';
                        //line = '<i class="icon-$icon"/>'+line;
                    }
                    */
                    line = line.replace( ansiCodes[0], '<span class="$classes">' );
                    line = line.replace( ansiCodes[1], '</span>' );

                } else {
                    line = line.replace( ansiCodes[0], '' ).replace( ansiCodes[1], '' );
                    line = '<span>$line</span>';
                }
            } else {
                line = '<span>$line</span>';
            }
            html += line;//+'<br>';
        }
        return html;
    }

    static function getAnsiType( code : Int ) : String {
        return switch code {
            //case 30: '#000000';
            case 31: 'error';
            case 32: 'success';
            //case 33: '#ffff00';
            case 34: 'debug';
            case 35: 'warning';
            case 36: 'info';
            //case 37: '#ffffff';
            default: 'test';
        }
    }
}

private class MetaMessageView extends MessageView {

    public function new( text : String ) {
        super( -1, 0, false );
        element.classList.add( 'meta' );
        content.textContent = text;
    }
}

private class LogMessageView extends MessageView {

    var text : String;

    public function new( text : String, index : Int, ?status : String, num : Int, showLineNumber : Bool ) {

        super( index, num, showLineNumber );
        this.text = text;

        if( status != null ) element.classList.add( status );

        //TODO
        //var content = document.createElement( 'pre' );
        //var content = document.createDivElement();
        //content.classList.add( 'content' );

        trace(text);
        /*
        var html = '';
        for( line in text.split('\n') ) {
            html += MessageView.ansiToHTML( line );
        }
        //trace(html);
        */
        var html = MessageView.ansiToHTML( text );
        content.innerHTML = html;

        //element.appendChild( content );
    }

    override inline function copyToClipboard() {
        Atom.clipboard.write( text );
    }
}

private class ErrorMessageView extends MessageView {

    var error : ErrorMessage;

    public function new( error : ErrorMessage, index : Int, num : Int, showLineNumber : Bool ) {

        super( index, num, showLineNumber );
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
        content.appendChild( e );
        e.onclick = function(_) open( line );
        return e;
    }

    function span( text : String, ?classes : Array<String> ) {
        var e = document.createSpanElement();
        if( classes != null ) for( c in classes ) e.classList.add(c);
        e.textContent = text;
        content.appendChild( e );
    }
}
