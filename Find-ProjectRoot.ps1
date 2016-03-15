param( [Parameter(HelpMessage="Initial directory to start search from.")][string]$startLocation=$pwd.path )

try { 
    ipmo "$PSScriptRoot\FearTheCowboy.Workshop.psm1" -force -ea 0 -wa 0 -scope local ; push-state ; $InformationPreference=2
	
	return Find-SolutionFile $startLocation
} finally {
	pop-state  
}