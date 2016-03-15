# build the packages
param (
    [Parameter(HelpMessage="Sets Configuration to 'release' ")][Switch] $release
    ,[Parameter(HelpMessage="Configuration to build (default='debug') ")][string] $config = "debug"
)

try {
    # import the workshop module
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0  -scope local ; push-state ; $InformationPreference=2
    
    Find-SolutionFile |%% { 
        Build-Package $_ (= $release ? "release" : $config )
    } -else {
        write-status -error "Unable to find root of project (no project.json or global.json file found) in tree ($pwd)."
    }
    
} finally {
    pop-state -all
}