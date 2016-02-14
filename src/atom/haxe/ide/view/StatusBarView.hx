package atom.haxe.ide.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import haxe.ds.ObjectMap;

class StatusBarView {

    public var element(default,null) : DivElement;

    var icon : SpanElement;
    var info : AnchorElement;
    var meta : SpanElement;

    var serverStatus : ServerStatus;
    var buildStatus : BuildStatus;
    var buildFile : String;
    //var path : String;
    //var buildStartTime : Float;
    var tooltips : ObjectMap<Element,Disposable>;

    public function new() {

        element = document.createDivElement();
        element.setAttribute( 'is', 'status-bar-haxe' );
        element.classList.add( 'haxe-status', 'inline-block' );

        icon = document.createSpanElement();
        icon.classList.add( 'haxeicon' );
        element.appendChild( icon );

        info = document.createAnchorElement();
        info.classList.add( 'info' );
        element.appendChild( info );

        meta = document.createSpanElement();
        meta.classList.add( 'meta' );
        element.appendChild( meta );

        icon.addEventListener( 'click', handleClickIcon, false );
        info.addEventListener( 'click', handleClickText, false );
        info.addEventListener( 'contextmenu', handleRightClickText, false );

        tooltips = new ObjectMap();

        setServerStatus( off );
        setBuildStatus( idle );

        //Atom.contextMenu.add({
    }

    public function set( ?buildFile : String, ?buildStatus : BuildStatus, ?meta : String ) {
        if( buildFile != null ) setBuildFile( buildFile );
        if( buildStatus != null ) setBuildStatus( buildStatus );
        if( meta != null ) setMetaInfo( meta );
    }

    public function setServerStatus( status : ServerStatus, ?exe : String, ?host : String, ?port : Int ) {
        if( status != serverStatus ) {
            if( serverStatus != null ) icon.classList.remove( serverStatus );
            icon.classList.add( status );
            if( status == off ) {
                addTooltip( icon, '$status' );
            } else {
                addTooltip( icon, '$port:$status' );
            }
        }
        serverStatus = status;
    }

    public function setBuildFile( buildFile : String ) {
        if( buildFile == null ) {
            info.textContent = "";
            info.classList.remove( buildStatus );
            removeTooltip( info );
        } else {
            this.buildFile = buildFile;
            var parts = Atom.project.relativizePath( buildFile );
            if( parts[0] != null ) {
                var projectParts = parts[0].split( '/' );
                var str = projectParts[projectParts.length-1]+'/'+parts[1];
                info.textContent = str;
            }
            addTooltip( info, buildFile );
        }
    }

    public function setBuildStatus( status : BuildStatus ) {
        if( status != buildStatus ) {
            for( e in [icon,info] ) {
                if( e.classList.contains( buildStatus ) ) e.classList.remove( buildStatus );
                e.classList.add( status );
            }
        }
        buildStatus = status;
    }

    public inline function setMetaInfo( text : String ) {
        meta.textContent = text;
        addTooltip( meta, text );
    }

    public function destroy() {
        icon.removeEventListener( 'click', handleClickIcon );
        info.removeEventListener( 'click', handleClickText );
        info.removeEventListener( 'contextmenu', handleRightClickText );
        for( tip in tooltips ) tip.dispose();
        tooltips = new ObjectMap();
    }

    function addTooltip( element : Element, title : String, ?keyBindingCommand : String ) {
        removeTooltip( element );
        var tip = Atom.tooltips.add( element, untyped {
            title: '<div>'+title.split(', ').join('<br>')+'</div>',
            html: true,
            keyBindingCommand: keyBindingCommand,
            //template: '<div class="tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
        } );
        tooltips.set( element, tip );
    }

    function removeTooltip( element : Element ) {
        if( tooltips.exists( element ) ) {
            tooltips.get( element ).dispose();
            tooltips.remove( element );
        }
    }

    function handleClickIcon(e) {
        HaxeIDE.serverLog.toggle();
    }

    function handleClickText(e) {
        HaxeIDE.build();
    }

    function handleRightClickText(e) {
        if( buildFile != null ) Atom.workspace.open( buildFile );
    }

}
