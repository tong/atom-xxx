package xxx.atom.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import atom.Disposable;
import atom.File;
import Atom.workspace;

using haxe.io.Path;

class StatusBarView implements atom.Disposable {

    public var element(default,null) : DivElement;

    var icon : SpanElement;
    var info : AnchorElement;
    var meta : SpanElement;

    var status : String;
    var hxml : String; // current hxml path in status bar
    var contextMenu : Disposable;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'status-bar-xxx', 'inline-block' );
        //element.setAttribute( 'is', 'status-bar-xxx' );

        icon = document.createSpanElement();
        icon.classList.add( 'haxe-icon' );
        element.appendChild( icon );

        info = document.createAnchorElement();
        info.classList.add( 'info' );
        element.appendChild( info );

        meta = document.createSpanElement();
        meta.classList.add( 'meta' );
        element.appendChild( meta );

        info.addEventListener( 'click', handleClickInfo, false );
    }

    public function setStatus( ?status : String ) {
        if( status != this.status ) {
            if( this.status != null ) {
                icon.classList.remove( this.status );
                info.classList.remove( this.status );
            }
            this.status = status;
            icon.classList.add( status );
            info.classList.add( status );
        }
        meta.textContent = '';
    }

    public function setHxml( file : File ) {
        if( file == null ) {
            this.hxml = null;
            icon.style.display = 'none';
            info.textContent = meta.textContent = '';
            if( contextMenu != null ) contextMenu.dispose();
        } else{
            var filePath = file.getPath();
            if( filePath != this.hxml ) {
                this.hxml = filePath;
                icon.style.display = 'inline-block';
                var parts = Atom.project.relativizePath( file.getPath() );
                if( parts[0] != null ) {
                    var projectParts = parts[0].split( '/' );
                    var str = projectParts[projectParts.length-1]+'/'+parts[1];
                    info.textContent = str.withoutExtension();
                }
                meta.textContent = '';
                contextMenu = Atom.contextMenu.add({
                    '.status-bar-xxx .info': [
                    { label: 'Build', command: 'xxx.build' }
                    ]
                });
            }
        }
    }

    public function setMetaInfo( ?str : String ) {
        if( str == null ) {
            meta.textContent = '';
        } else {
            meta.textContent = str;
        }
    }

    public function setServerInfo( port : Int ) {
        icon.title = ''+port;
    }

    public function dispose() {
        hxml = null;
        info.removeEventListener( 'click', handleClickInfo );
        element.remove();
        if( contextMenu != null ) contextMenu.dispose();

    }

    function handleClickInfo(e) {
        if( e.ctrlKey ) {
            IDE.build();
        } else {
            if( IDE.hxml != null ) workspace.open( IDE.hxml.getPath() );
        }
    }

    /*
    function handleHxmlChange( path : String ) {
        //setHxmlPath( path );
    }
    */
}
