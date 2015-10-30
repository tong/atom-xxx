package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import om.Time.now;

class StatusBarView {

    public var dom(default,null) : DivElement;

    var icon : SpanElement;
    var text : AnchorElement;
    var time : SpanElement;

    var currentStatus : BuildStatus;
    var path : String;
    var buildStartTime : Float;

    public function new() {

        dom = document.createDivElement();
        dom.setAttribute( 'is', 'status-bar-haxe' );
        dom.classList.add( 'haxe-status', 'inline-block' );

        icon = document.createSpanElement();
        icon.classList.add( 'haxeicon' );
        dom.appendChild( icon );

        text = document.createAnchorElement();
        text.classList.add( 'hxml' );
        dom.appendChild( text );

        time = document.createSpanElement();
        time.classList.add( 'time' );
        dom.appendChild( time );

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
            var buildDuration = (now() - buildStartTime) / 1000;
            var buildDurationString = Std.string( buildDuration );
            buildDurationString = buildDurationString.substr( 0, buildDurationString.indexOf( '.' )+2 );
            time.textContent = '($buildDurationString)';
        default:
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

    public function destroy() {
        text.removeEventListener( 'click', handleClickText );
    }

    function handleClickText(e) {
        Atom.workspace.open( path );
    }

}
