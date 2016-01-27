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
    var time : SpanElement;

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

        time = document.createSpanElement();
        time.classList.add( 'time' );
        element.appendChild( time );

        text.addEventListener( 'click', handleClickText, false );
    }

    //public function setServerStatus( status : HaxeServerStatus ) {
    public function setServerStatus( exe : String, host : String, port : Int, running : Bool ) {
        if( running ) {
            var str = '$host:$port';
            if( exe != 'haxe' ) str = exe + ' '+str;
            icon.title = str;
        } else {
            icon.title = 'Server not running';
        }
    }

    public function setBuildPath( path : String ) {
        if( path != null ) {
            this.path = path;
            var pathParts = Atom.project.relativizePath( path );
            if( pathParts[0] != null ) {
                var projectPathParts = pathParts[0].split( '/' );
                text.textContent = projectPathParts[projectPathParts.length-1]+'/'+pathParts[1];
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
            var time = (now() - buildStartTime) / 1000;
            var timeStr = Std.string( time );
            timeStr = timeStr.substr( 0, timeStr.indexOf( '.' )+2 );
            this.time.textContent = '($timeStr)';
        default:
        }
    }

    public inline function set( path : String, status : BuildStatus ) {
        setBuildPath( path );
        setBuildStatus( status );
    }

    public function destroy() {
        text.removeEventListener( 'click', handleClickText );
    }

    function handleClickText(e) {
        Atom.workspace.open( path );
    }

}
