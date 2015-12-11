# wipes the package cache
# deletes the installed packages 
# requires use of DNU RESTORE to bring them back
function nuke {
    param ( [string]$folder ) 
    if( test-path $folder )  {
        $folder = resolve-path $folder
        write-host -fore DarkYellow "    Removing $folder"
        $null = mkdir "$env:temp\mt" -ea 0 
        $shh = robocopy /mir "$env:temp\mt" "$folder" 
        $shh += rmdir -recurse -force "$folder" 
        if( test-path $folder ) {
            write-host -fore red "FAILED TO REMOVE: '$FOLDER'"
        }
    }
}

if ( (get-process devenv -ea 0).count -gt 0  ) {
    write-host -fore magenta "Visual Studio is running. This may fail if this project is open."
}

write-host -fore DarkGreen "Clearing package http cache"
dnu clear-http-cache

write-host -fore DarkGreen "Clearing installed package folder ($env:userprofile\.dnx\packages)"
nuke "$env:userprofile\.dnx\packages"

write-host -fore Green "Done."