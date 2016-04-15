package xxx.atom.view;

import Atom.contextMenu;
import Atom.workspace;
import atom.Panel;
import js.Browser.document;
import js.html.Element;
import js.html.DivElement;
import js.html.LIElement;
import js.html.OListElement;
import js.html.SpanElement;
import js.html.TimeElement;
import om.haxe.ErrorMessage;
import xxx.atom.IDE.project;

using haxe.io.Path;

class BuildLogView {

    public var element(default,null) : DivElement;

    var messageContainer : OListElement;
    var panel : Panel;

    public function new() {

        element = document.createDivElement();
        //element.setAttribute( 'is', 'h' );
        element.classList.add( 'haxe-buildlog', 'inline-block' );

        messageContainer = document.createOListElement();
        messageContainer.classList.add( 'messages', 'scroller' );
        element.appendChild( messageContainer );

        panel = workspace.addBottomPanel( { item: element, visible: false } );
        //trace( untyped panel.item.parentElement.background = 'rgba(0,255,0,0) !important' );
    }

    /*
    public function init( project : Project ) {
        project.onBuild(
            function(err){
                trace(err);
            },
            function(msg){
                trace(msg);
            },
            function(){
                trace("success");
            },
        );
    }
    */

    public inline function isVisible() : Bool {
        return panel.isVisible();
    }

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
        hide();
        while( messageContainer.firstChild != null )
            messageContainer.removeChild( messageContainer.firstChild );
        return this;
    }

    public function destroy() {
        panel.destroy();
    }

    public function log( text : String, level : String ) : BuildLogView {
        var view = new MessageView( text, level );
        messageContainer.appendChild( view.element );
        return this;
    }

    /*
    public inline function error( err : ErrorMessage ) : BuildLogView {
        return log( err.toString(), 'error' );
        var view = new ErrorView( text, level );
        messageContainer.appendChild( view.element );
    }
    */

    public inline function errors( errors : Array<ErrorMessage> ) : BuildLogView {
        for( err in errors ) {
            var view = new MessageView( err.toString(), 'error' );
            messageContainer.appendChild( view.element );
        }
        return this;
    }

    public inline function info( text : String ) : BuildLogView {
        return log( text, 'info' );
    }
}

private class MessageView {

    public var element(default,null) : LIElement;

    var time : TimeElement;
    var content : DivElement;

    public function new( text : String, status : String, ?iconId : String ) {

        element = document.createLIElement();
        element.classList.add( 'message', status );

        /*
        var now = Date.now();
        time = cast document.createElement( 'time' );
        time.dateTime = now.toString();
        time.textContent = now.getHours() +':'+ now.getMinutes() +':'+ now.getSeconds();
        element.appendChild( time );
        */

        if( iconId != null ) {
            var i = document.createElement('i');
            i.classList.add( 'icon', 'icon-$iconId' );
            element.appendChild(i);
        }

        content = document.createDivElement();
        content.classList.add( 'content', status );
        for( line in text.split( '\n' ) ) {
            var e = document.createDivElement();
            e.textContent = line;
            content.appendChild(e);
        }

        switch status {
        case 'error':
            //var i = document.createElement('i');
            //i.classList.add( 'icon', 'icon-bug' );
            //element.appendChild(i);
        }

        element.appendChild( content );
    }

    public function destroy() {
    }
}

/*
private class ErrorMessageView extends MessageView {

    public function new( errors : Array<> ) {

        super( text, status, 'bug' );


    }
}
*/
