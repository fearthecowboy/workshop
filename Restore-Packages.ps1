param (
    [Parameter(HelpMessage="The removes the packages")][Switch]$clean
    ,[Parameter(HelpMessage="Updates project.json")][Switch]$update
)

if( $clean )  {
    wipe-packagecache
}

if( $update )  {
    $opts = "--no-cache"
} else {
    $opts = ""
}

try {
  # import the workshop module
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0  -Scope local; push-state ; $InformationPreference=2
   
    Find-SolutionFile |%% { 
        # do something with the project file: $_
        $solutionRoot, $projects, $frameworks, $loneProject = Parse-SolutionFile $_
        dnu restore $projects --parallel $opts
    } -else {
        write-status -error "Unable to find root of project (no project.json or global.json file found) in tree ($pwd)."
    }
} finally {
    popd
} 
