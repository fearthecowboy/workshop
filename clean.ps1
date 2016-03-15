try {
    # import the workshop module
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0  -Scope local; push-state ; $InformationPreference=2
   
    Find-SolutionFile |%% { 
        # warn if VS is running.
        if ( (get-process devenv -ea 0).count -gt 0  ) {
            write-status -warning "Visual Studio is running. (This may fail if this project is open)"
        }

        Clear-SolutionAritfacts $_ 
    } -else {
        write-status -error "Unable to find root of project (no project.json or global.json file found) in tree ($pwd)."
    }
    
} finally {
    pop-state -all
}