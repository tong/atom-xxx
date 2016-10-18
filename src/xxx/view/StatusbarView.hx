package xxx.view;

import js.Browser.document;
import js.html.Element;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.SpanElement;
import om.Time;
import atom.Disposable;
import atom.File;
import Atom.workspace;
import Atom.tooltips;

using haxe.io.Path;

@:keep
class StatusbarView implements atom.Disposable {

	public var element(default,null) : DivElement;

	var icon : SpanElement;
    var info : AnchorElement;
    var meta : SpanElement;
    //var message : SpanElement;

	var status : String;
	var contextMenu : Disposable;
	//var tooltip : Disposable;
	//var prevSelectedHxmlFiles : Array<String>;

	public function new() {

        element = document.createDivElement();
        element.classList.add( 'status-bar-xxx', 'inline-block' );

		icon = document.createSpanElement();
        icon.classList.add( 'icon-haxe' );
        element.appendChild( icon );

		info = document.createAnchorElement();
        info.classList.add( 'info' );
        element.appendChild( info );

        meta = document.createSpanElement();
        meta.classList.add( 'meta' );
        element.appendChild( meta );

		//message = document.createSpanElement();
		//message.classList.add( 'message' );
		//element.appendChild( message );

		IDE.onSelectHxml( changeHxml );
		IDE.onBuild( function(build){

			var timeBuildStart : Float = null;
			var numErrors = 0;

			build.onStart( function(){
				timeBuildStart = Time.now();
				changeStatus( 'active' );
			});
			build.onMessage( function(msg){
				//meta.textContent = msg;
			});
			build.onError( function(err){
				//trace(err);
				numErrors++;
				changeStatus( 'error' );
				//meta.textContent = ''+err;
			});
			build.onEnd( function(code){

				if( code == 0 ) {

					changeStatus( 'success' );

					var time = (Time.now() - timeBuildStart)/1000;
					var timeStr = Std.string( time );
					var cpos = timeStr.indexOf('.');
					meta.textContent = timeStr.substring( 0, cpos ) + timeStr.substring( cpos, 3 ) + 's';

				} else {
					changeStatus( 'error' );
					meta.textContent = '($numErrors)';
				}
			});
		});

		/*
		if( IDE.hxml != null ) {
			changeHxml( IDE.hxml );
		}
		*/

		info.addEventListener( 'click', handleClickInfo, false );
	}

	/*
	public function setMeta( text : String ) {
		meta.textContent = text;
	}
	*/

	public function dispose() {
		info.removeEventListener( 'click', handleClickInfo );
		if( contextMenu != null ) contextMenu.dispose();
	}

	function changeHxml( hxml : File ) {

		if( hxml == null ) {
			icon.style.display = 'none';
			info.textContent = '';

		} else {
			icon.style.display = 'inline-block';
			info.textContent = getRelativePath( hxml.getPath() ).withoutExtension();
		}

		meta.textContent = '';

		buildContextMenu();
	}

	function changeStatus( status : String ) {
		if( status != this.status ) {
			if( this.status != null ) {
                icon.classList.remove( this.status );
                info.classList.remove( this.status );
            }
			this.status = status;
			if( status != null ) {
				icon.classList.add( status );
				info.classList.add( status );
			}
		}
		//meta.textContent = '';
	}

	function buildContextMenu() {
		if( contextMenu != null ) contextMenu.dispose();
		var items = [];
		if( IDE.hxml != null ) {
			items.push( { label: 'Build', command: 'xxx:build' } );
			items.push( untyped { type: 'separator' } );
		}
		//TODO
		for( file in IDE.hxmlFiles ) {
			if( IDE.hxml != null && IDE.hxml.getPath() == file )
				continue;
			items.push( { label: getRelativePath( file ), command: 'xxx:select-hxml' } );
		}
		contextMenu = Atom.contextMenu.add( { '.status-bar-xxx .info': items } );
	}

	function handleClickInfo(e) {
        if( e.ctrlKey ) {
        	IDE.build();
        } else {
        	if( IDE.hxml != null )
				workspace.open( IDE.hxml.getPath() );
        }
    }

	static function getRelativePath( fullPath : String ) {
		var rel = Atom.project.relativizePath( fullPath );
		var parts = rel[0].split( '/' );
		return parts[parts.length-1]+'/'+rel[1];
	}
}
