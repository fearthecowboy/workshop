# build and publish the packages
param (
    [Parameter(HelpMessage="Nuget Repository to push to")][string]$repository = "nuget.org"
    ,[Parameter(HelpMessage="Sets Configuration to 'debug' ")][Switch] $dbg
    ,[Parameter(HelpMessage="Configuration to build (default='release') ")][string] $config = "release"
)
try {
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0  -Scope local ; push-state ; $InformationPreference=2 

    Find-SolutionFile |%% { 
        $solutionRoot, $projects, $frameworks, $loneProject = Parse-SolutionFile $_
        $config = (= $dbg ? "debug" : $config )
        
        dir -ea 0 -recurse "$solutionRoot\packages\$config\*.nupkg" | %% { 
            write-output $_
        } -else { 
            write-status -error "Unable to find built packages for configuration '$config' in $solutionRoot\packages\$config\"    
        }
    } -else {
        write-status -error "Unable to find root of project (no project.json or global.json file found) in tree ($pwd)."
    }

} finally {
    pop-state
}