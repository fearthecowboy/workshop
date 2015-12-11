# build the packages
param (
    [Parameter(HelpMessage="Builds DEBUG binaries (default) ")]
    [Switch]
    $Dbg,
    
    [Parameter(HelpMessage="Builds RELEASE binaries")]
    [Switch]
    $release
)

try {
    $InformationPreference=2
    ipmo "$PSScriptRoot\Project.Common.psm1" -force -Scope local -ea 0 -wa 0 
    Set-Color gray
    
    if( $release ) { 
        $cfg = "release"
    } 

    if( -not $cfg ) { 
        $cfg = "debug"
    } 

    $solutionFile = Find-ProjectRoot
    if(!$solutionFile ) {
        return write-error "Unable to find root of project (no project.json or global.json file found in tree)"
    }
    $solutionRoot = get-folder $solutionFile
    
    if( !(Is-LoneProject $solutionFile) ) {
        $solution = (convertfrom-json (get-content -raw .\global.json ))
        $projects = $solution.projects |? { -not ("$_" -match "test" ) } 
        $frameworks = get-keys $solution.frameworks
    } else {
        $loneProject = $true
        $projects="$(Get-FolderName projectFolder)"
        $frameworks=@("net45")
    }
    
    $buildNumberFile = resolve-path "$solutionRoot\.number" -ea 0
    if( $buildNumberFile ) {
        $ENV:DNX_BUILD_VERSION=(([int](get-content $buildNumberFile))+1)
        set-content $buildNumberFile  -Value $env:DNX_BUILD_VERSION
        write-status -fore green "Build number: $ENV:DNX_BUILD_VERSION" 
    }
   
    clean
    
    # just build the top project for output.
    dnu restore --parallel
    if( $lastExitCode ) {
        return write-error "Failed package restore "
    }
    
    write-status -fore white "Building packages ($projects)"
    dnu pack $projects --configuration $cfg  
     # --framework $frameworks
    
    if( $lastExitCode ) {
        # write-status -fore green "Log: $_"
        return write-error "Failed build."
    }
    
    # use of --out in dnu pack causes packages to have assemblies from the out folder that were compiled stuffed into their package. Stupid.
    if( !$loneProject ) {
        # create package output folder
        $packageFolder = "$solutionRoot\packages"
        $shh = mkdir $packageFolder -ea 0

        $projects |% {  copy -force -recurse "$solutionRoot\$_\bin\*" $packageFolder;  nuke-folder "$solutionRoot\$_\bin" }
    } else {
        rename "$solutionRoot\bin" "packages"
    }
    
    dir -recurse packages\$cfg\*.nupkg |% { 
        write-output $_
    } 
} finally {
    Restore-state
}
