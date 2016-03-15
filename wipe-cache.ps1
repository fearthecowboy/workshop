try {
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0 -scope local ; push-state ; $InformationPreference=2
    # wipes the package cache
    # deletes the installed packages 
    # requires use of DNU RESTORE to bring them back
    
    if ( (get-process devenv -ea 0).count -gt 0  ) {
        write-status -fore magenta "Visual Studio is running. This may fail if this project is open."
    }
    
    Wipe-PackageCache

} finally { 
    pop-state
}