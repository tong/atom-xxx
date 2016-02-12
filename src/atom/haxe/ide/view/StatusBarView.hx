package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import om.Time.now;

class StatusBarView {

    public var element(default,null) : DivElement;

    var icon : SpanElement;
    var text : AnchorElement;
    var meta : SpanElement;
    var tooltip : Disposable;

    var path : String;
    var currentStatus : BuildStatus;
    var buildStartTime : Float;

    public function new() {

        element = document.createDivElement();
        element.setAttribute( 'is', 'status-bar-haxe' );
        element.classList.add( 'haxe-status', 'inline-block' );

        icon = document.createSpanElement();
        icon.classList.add( 'haxeicon' );
        element.appendChild( icon );

        text = document.createAnchorElement();
        text.classList.add( 'hxml' );
        element.appendChild( text );

        meta = document.createSpanElement();
        meta.classList.add( 'meta' );
        element.appendChild( meta );

        text.addEventListener( 'click', handleClickText, false );
        text.addEventListener( 'contextmenu', handleRightClickText, false );
    }

    public function setServerStatus( exe : String, host : String, port : Int, running : Bool ) {
        if( running ) {
            var str = '$host:$port';
            if( exe != 'haxe' ) str = '$exe $str';
            icon.title = str;
        } else {
            icon.title = 'Server not running';
        }
    }

    public function setBuildPath( path : String ) {
        if( path != null ) {
            this.path = path;
            setTooltip( path );
            var pathParts = Atom.project.relativizePath( path );
            if( pathParts[0] != null ) {
                var projectPathParts = pathParts[0].split( '/' );
                var str = projectPathParts[projectPathParts.length-1]+'/'+pathParts[1];
                text.textContent = str;
            }
        } else {
            text.textContent = "";
        }
    }

    public function setBuildStatus( status : BuildStatus ) {

        for( e in [icon,text] ) {
            e.classList.remove( currentStatus );
            e.classList.add( status );
        }

        currentStatus = status;

        switch status {
        case active:
            buildStartTime = now();
        case success:
            var elapsedStr = Std.string( Std.int( now() - buildStartTime ) );
            elapsedStr = elapsedStr.substr( 0, elapsedStr.indexOf( '.' )+2 );
            meta.textContent = elapsedStr+'ms';
        default:
        }
    }

    public inline function setMetaInfo( text : String ) {
        meta.textContent = text;
    }

    public inline function set( path : String, status : BuildStatus ) {
        setBuildPath( path );
        setBuildStatus( status );
    }

    public function destroy() {
        if( tooltip != null ) tooltip.dispose();
        text.removeEventListener( 'click', handleClickText );
        text.removeEventListener( 'contextmenu', handleRightClickText );
    }

    function setTooltip( title : String ) {
        if( tooltip != null ) tooltip.dispose();
        tooltip = Atom.tooltips.add( element, { title: title } );
    }

    function handleClickText(e) {
        HaxeIDE.build();
    }

    function handleRightClickText(e) {
        Atom.workspace.open( path );
    }

}
