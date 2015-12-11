param (
    [Parameter(HelpMessage="The removes the packages")]
    [Switch]
    $clean,
    [Parameter(HelpMessage="Updates project.json")]
    [Switch]
    $update
)

if( $clean )  {
    & "$PSScriptRoot\wipe-cache.ps1"
}

if( $update )  {
    $opts = "--no-cache"
} else {
    $opts = ""
}

pushd .

try {
    do {
        $last = $pwd
        if( (test-path .\global.json ) ) {
            write-host -fore green "Using global file: $(resolve-path .\global.json)"
            dnu restore ((convertfrom-json (get-content -raw .\global.json )).projects ) --parallel $opts 
            return
        }
        cd ..
        if( $pwd.path -eq $last.path )  {
            popd 
            pushd 
            do {
                $last = $pwd
                if( (test-path .\project.json ) ) {
                    write-host -fore green "Using project file: $(resolve-path .\project.json)"
                    dnu restore --parallel $opts 
                    return
                }
                
                 if( $pwd.path -eq $last.path )  {
                    write-host -fore red "Didn't find project.json file in tree."
                    return;
                 }
            } while( $true )    
        }
    } while( $true ) 
} finally {
    popd
}