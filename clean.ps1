
try {
    $InformationPreference=2
    ipmo "$PSScriptRoot\Project.Common.psm1" -force -ea 0 -wa 0

    if ( (get-process devenv -ea 0).count -gt 0  ) {
        write-warning "Visual Studio is running. (This may fail if this project is open)"
    }

    $solutionFile = Find-ProjectRoot
    if( !$solutionFile ) {
        return write-error "Didn't find project.json or global file in tree ($pwd)"
    }
    
    # switch to the solution folder
    cd (Get-Folder $solutionFile)
    
    if( Is-LoneProject $solutionFile ) {
         write-status -fore DarkGreen "Cleaning relative to project file: $solutionFile"
         return nuke-knownfolders $pwd
    }
    
    write-status -fore DarkGreen "Cleaning relative to solution file: $solutionFile"
    nuke-knownfolders (resolve-path "$pwd")
    
    (convertfrom-json (get-content -raw $solutionFile )).Projects |% {
        write-status -fore DarkGreen "Cleaning project ($_)"
        if( (test-path "$pwd\$_") ) {
            nuke-knownfolders (resolve-path "$pwd\$_")
        }
    }
    
} finally {
    Restore-state
}