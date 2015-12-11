# build and publish the packages
param (
    [Parameter(HelpMessage="Publish to the repository")]
    [Switch]
    $publish,
    
    [Parameter(HelpMessage="Nuget Repository to push to")]
    [string]
    $repository = "nuget.org"
)
try {
    $InformationPreference=2
    ipmo "$PSScriptRoot\Project.Common.psm1" -force -Scope local -ea 0 -wa 0 
    Set-Color gray
    
    $p = call -async { 
        cd $using:pwd
        build-package -release  
    }  
    wait-job $p
    write-status -fore red "done."
    
    $packages = receive-job $p 

write-status -fore red "done again."
    
    if( $packages ) {
        $packages |% { 
            write-status -fore blue "$_"
        }
    }

} finally {
    Restore-state
}
