package xxx.atom.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import Atom.contextMenu;
import Atom.workspace;

using haxe.io.Path;

class StatusBarView {

    public var element(default,null) : DivElement;

    var icon : SpanElement;
    var info : AnchorElement;
    var meta : SpanElement;
    var status : String;

    public function new() {

        element = document.createDivElement();
        element.classList.add( 'haxe-status', 'inline-block' );

        icon = document.createSpanElement();
        icon.classList.add( 'haxe-icon' );
        element.appendChild( icon );

        info = document.createAnchorElement();
        info.classList.add( 'info' );
        element.appendChild( info );

        meta = document.createSpanElement();
        meta.classList.add( 'meta' );
        element.appendChild( meta );

        Atom.contextMenu.add( {
            '.status-bar-haxe' : untyped [
                { label: 'BuildAll' },
                { type: 'separator' }
            ]
        });

        info.addEventListener( 'click', handleClickInfo, false );
    }

    /*
    public function init() {

        setHxmlPath( project.hxml );

        for( hxmlFile in project.hxmlFiles ) {
            var parts = Atom.project.relativizePath( hxmlFile );
            var label = parts[0].split( '/' ).pop() +'/'+ parts[1];
            Atom.contextMenu.add( {
                '.status-bar-haxe' : [
                    { label: label }]
            });
        }

        project.onDidChangeHxml( handleHxmlChange );
    }
    */

    public function setStatus( status : String ) {
        if( status != this.status ) {
            if( this.status != null ) {
                icon.classList.remove( this.status );
                info.classList.remove( this.status );
            }
            this.status = status;
            icon.classList.add( status );
            info.classList.add( status );
        }
    }

    public function setHxml( path : String ) {
        if( path == null ) {
            icon.style.display = 'none';
            info.textContent = meta.textContent = '';
        } else {
            icon.style.display = 'inline-block';
            var parts = Atom.project.relativizePath( path );
            if( parts[0] != null ) {
                var projectParts = parts[0].split( '/' );
                var str = projectParts[projectParts.length-1]+'/'+parts[1];
                info.textContent = str.withoutExtension();
            }
            meta.textContent = '';
        }
    }

    public function setMeta( ?text : String ) {
        if( text == null ) meta.textContent = '' else {
            meta.textContent = text;
        }
    }

    public function destroy() {
        info.removeEventListener( 'click', handleClickInfo );
        element.remove();
    }

    function handleClickInfo(e) {
        if( e.ctrlKey ) {
            IDE.project.build();
        } else {
            if( IDE.project.hxml != null ) workspace.open( IDE.project.hxml );
        }
    }

    /*
    function handleHxmlChange( path : String ) {
        //setHxmlPath( path );
    }
    */
}
