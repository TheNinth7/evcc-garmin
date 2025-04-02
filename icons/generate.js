/* This script generates the resources/drawables folder for different
   devices, with drawables.xml and icons in the right size.

   Additional devices or icons can be added in generate.json
   without having to update this script.

   The script uses inkscape for generating PNGs from SVGs.
   inkscape.exe needs to be in the PATH environment variable
   for the script to work.
   */
WScript.Echo( "Reading configuration ...");

// Read the JSON configuration
var fso = new ActiveXObject("Scripting.FileSystemObject");
var jsonFile = fso.OpenTextFile("generate.json", 1);
var content = jsonFile.ReadAll();

// Convert JSON string to object structure
eval('var config = ' + content );

var device_families = config["device-families"];
var files = config["files"];

var errors = "";

// As parameter we take a resource folder name,
// e.g. "resources-round-240x240", in which case
// only this folder is regenerated.
if( WScript.Arguments.Unnamed.Count > 0 ) {
    if( WScript.Arguments.Item(0) == "drawables.xml" )
    {
	    for( var family in device_families ) {
	        errors += generateFamily( family, device_families, files, true );
	    }
    }
    else if( ! device_families[WScript.Arguments.Item(0)] ) {
        errors += "Device family \"" + WScript.Arguments.Item(0) + "\" not found. Note: don't forget the \"resources-\" prefix!";
    } else {
        errors += generateFamily( WScript.Arguments.Item(0), device_families, files, false );
    }
} else {
    for( var family in device_families ) {
        errors += generateFamily( family, device_families, files, false );
    }
}

if( errors != "" ) {
    WScript.Echo ( "\r\nErrors:\r\n" + errors );
}

WScript.Echo( "" );

/* Function to generate the resource folder for one
   device family */
function generateFamily( family, device_families, files, xmlOnly ) {
    WScript.Echo( "\nGenerating " + family );
    
    var fso = new ActiveXObject("Scripting.FileSystemObject");
    
    // Generate the device family/drawables folder names
    // and create them if they are not there yet
    var resourceFolder = "..\\" + family 
    var drawableFolder = resourceFolder + "\\drawables";
    if( ! fso.FolderExists( resourceFolder ) ) {
        WScript.Echo( "    Creating " + resourceFolder );
        fso.CreateFolder( resourceFolder );
    }
    if( ! fso.FolderExists( drawableFolder ) ) {
        WScript.Echo( "    Creating " + drawableFolder );
        fso.CreateFolder( drawableFolder );
    } else {
        // If folder already exists, we delete everything
        // in it to start with a clean slate (e.g. for the
        // case that icons were removed from the JSON configuration)
        if( ! xmlOnly ) {
	        // WScript.Echo( "    Deleting files" );
	        fso.DeleteFile( drawableFolder + "\\*" );
        }
    }
    
	// We count the files for the status bar
	// Start from 1 to cover drawables.xml
	var totalFiles = 1;
	if( ! xmlOnly ) {
		for( var file in files ) {
	        var types = files[file]["types"];
	        for( var i in types ) { 
	            var height = device_families[family][types[i]];
				if( height != undefined ) { totalFiles++; }
			}
		}
	}


	// WScript.Echo( "    Copying drawables.xml" );
    fso.CopyFile( "drawables.xml", drawableFolder + "\\", true );
	var fileCount = 1;
	drawProgress( fileCount, totalFiles );

	if( ! xmlOnly ) {

	    for( var file in files ) {
			var anti_aliasing = files[file]["anti-aliasing"];
	        if( anti_aliasing == undefined ) { anti_aliasing = "0"; };
	    
	        var types = files[file]["types"];
	    
	        for( var i in types ) {
	            var height = device_families[family][types[i]];
	            
	            if( height != undefined ) {
	                // Prepare the inkscape command
	                //WScript.Echo( "    " + file + ": type=" + types[i] + ", height=" + height + ( anti_aliasing != "0" ? ", anti-aliasing=" + anti_aliasing : "" ) );
	                
	                // If a PNG file name is specified for the file we use it,
	                // otherwise we generate one
	                var final_name = files[file]["png-name"];
	                if( final_name == undefined ) {
	                    final_name = types[i] + "_" + file.split( "." )[0] + ".png";
	                }
	                var inkscape_name = final_name.split( "." )[0] + "_inkscape.png";
	                
					var cmd = "inkscape.exe --export-type=png" +
	                    " --export-filename=" + drawableFolder + "\\" + inkscape_name + 
	                    " --export-png-antialias=" + anti_aliasing + 
	                    " --export-height=" + height +
	                    " " + file;

						// Make the call to inkscape and wait until it finishes
	                var shell = new ActiveXObject("WScript.Shell");
	                var exec = shell.Exec( cmd );
	                while ( exec.Status == 0 ) { WScript.Sleep( 100 ); }

	                //WScript.Echo( "    Crushing to " + final_name );
					var crush = "pngcrush.exe " + drawableFolder + "\\" + inkscape_name + " " + drawableFolder + "\\" + final_name;
					fileCount++;
					var exec = shell.Exec( crush );
	                while ( exec.Status == 0 ) { WScript.Sleep( 100 ); }
					fso.DeleteFile( drawableFolder + "\\" + inkscape_name );
					drawProgress( fileCount, totalFiles );
				}
	        }
	    }
	    
		//WScript.Echo( fileCount + "/" + totalFiles );

		// For safety we check that the number of generated files
	    // matches what we expect
	    var folder = fso.GetFolder( drawableFolder );
	    if( folder.Files.Count != fileCount ) {
	        return "File count for " + family + " does not match!\r\n";
	    }
	}	    

	return "";
	    
	    /* Code that iterates through a folder
	    var folder = fso.GetFolder(".\\");
	    var files = folder.Files;
	    var fileEnumerator = new Enumerator(files);
	    for (; !fileEnumerator.atEnd(); fileEnumerator.moveNext()) {
	        var file = fileEnumerator.item().Name;
	    }
	    */ 
}

function drawProgress(current, total) {
	var stdout = WScript.StdOut;
	var barWidth = 40;
    var percent = current / total;
    var done = Math.floor(percent * barWidth);
    
    var bar = Array(done + 1).join("#") + Array(barWidth - done + 1).join("-");
    var percentText = Math.floor(percent * 100) + "%";

    stdout.Write("\r[" + bar + "] " + percentText);
}

