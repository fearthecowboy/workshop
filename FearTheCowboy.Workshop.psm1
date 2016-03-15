
$InformationPreference=2
function Push-State {
    try { 
        $state=@( @{ pwd=$pwd; fore=$host.UI.RawUI.ForegroundColor; back=$host.UI.RawUI.BackgroundColor; indent = $global:__indentLevel } )
        if( $global:__stateStack ) {
            $global:__stateStack = @( $state ) + @( $global:__stateStack )
        } else {
            $global:__stateStack = @( $state )
        }
    } finally { }
}

function Pop-State ([switch]$all) {
    try { 
        if( $global:__stateStack ) {
            $state, $global:__stateStack = $global:__stateStack  
            if( $state ) {
                if(  $state.pwd ) {
                    cd $state.pwd 
                }
                if( $state.fore ) {
                    $host.UI.RawUI.ForegroundColor = $state.fore
                }
                if( $state.back ) {
                    $host.UI.RawUI.BackgroundColor = $state.back
                }
                $global:__indentLevel = $state.indent
           }
        }
        if( !$global:__stateStack ) { 
            # clean up everything on the way out
            remove-variable -Scope global -name __stateStack
            remove-variable -Scope global -name __indentLevel
            get-module FearTheCowboy.Workshop | remove-module
        } else {
            if( $all) {
                pop-state -all 
            }
        }
    } finally { }
}

function Set-Color {
    param( 
        $foregroundColor,
        $backgroundColor
    ) 
    if( $foregroundColor ) {
        try { $host.UI.RawUI.ForegroundColor = [System.ConsoleColor]$foregroundColor} finally { }
    }
    if( $backgroundColor ) {
        try { $host.UI.RawUI.BackgroundColor = [System.ConsoleColor]$backgroundColor } finally { }
    }
}

$indent_level = 0

function push-indent {
    $global:__indentLevel++
}

function pop-indent {
    $global:__indentLevel--
    if($global:__indentLevel -lt 0  ) {
        $global:__indentLevel =0
    }
}


function Call {
    param( [ScriptBlock]$scriptBlock, $session=$null, [switch]$async) 
    if( $session -eq $null )  {
        if( $async ) {
            return start-job -Scriptblock $scriptBlock
        }
        return invoke-command -Scriptblock ([scriptblock]::Create(($scriptBlock.ToString() -replace '\$using:', '$' )))
    } 
    
    if( $async ) {  
        Invoke-Command -Session $session -ScriptBlock $scriptBlock -AsJob
    }
    return Invoke-Command -Session $session -ScriptBlock $scriptBlock
}



function Convert-ToHashtable{ 
    param( $object )
    $keys = ($object| get-member -MemberType NoteProperty).Name
    
    $result = @{}
    $keys |% { $result[$_] = $object.($_) }
    return $result
}

function Get-Keys {
    param( $object )
    return ($object| get-member -MemberType NoteProperty).Name
}

function Get-Folder {
    param( [string]$path ) 
    $p = (resolve-path $path)
    if( $p ) { return (dir $p).Directory.FullName } 
    return $null
}

function Get-FolderName {
    param( [string]$path ) 
    $p = (resolve-path $path)
    if( $p ) { return (dir $p).Directory.BaseName } 
    return $null
}

function Nuke-Folder {
    param ( [string]$folder ) 
    if( test-path $folder )  {
        $folder = resolve-path $folder
        write-status -detail "Removing $folder"
        $null = mkdir "$env:temp\mt" -ea 0 
        $shh = robocopy /mir "$env:temp\mt" "$folder" 
        $shh += rmdir -recurse -force "$folder" 
        if( test-path $folder ) {
            write-warning "FAILED TO REMOVE: '$FOLDER'"
        }
    }
}

function nuke-knownfolders {
   param ( [string]$folder ) 
    write-status -debug "Nuking known folders from: $folder"
    nuke-folder "$env:temp\$((get-item $folder).Name)"
    nuke-folder "$folder\bin" 
    nuke-folder "$folder\intermediate" 
    nuke-folder "$folder\generated" 
    nuke-folder "$folder\obj" 
    nuke-folder "$folder\output" 
    nuke-folder "$folder\artifacts"
    nuke-folder "$folder\packages"
}

function Is-LoneProject {
    param ($solutionFile) 
    return $solutionFile -match "project.json$"
}

function Write-Status {     
    param( 
        [string] $message,
        [string] $details ="",
        [int] $progress =-1,
        [Switch] $info,
        [Switch] $important,
        [Switch] $detail,
        [Switch] $warning,
        [Switch] $verbose,
        [Switch] $debug,
        [Switch] $error,
        [Switch] $indent,
        $foregroundColor,
        $backgroundColor
    ) 
    if( $warning ) {
        return Write-Warning $message 
    }
    if( $verbose ) {
        return write-verbose $message
    }
    if( $debug ) {
        return write-debug $message 
    }
    if( $error ) {
        return write-error $message 
    }
       
    if( $detail ) { 
        $foregroundColor = "DarkGray"
    }
    if( $info ) {
        $foregroundColor = "DarkGreen"
    }
    if( $important ) { 
        $foregroundColor = "Green"
    }
   
    Set-Color $foregroundColor $backgroundColor
    $i == $indent ? ($global:__indentLevel + 1) : $global:__indentLevel  
    write-information  "$('  ' * $i )$message"
}
<#
.Synopsis
Given a path, verifies that the target is a folder, or it's parent is a folder and returns the full path.
#>
function Resolve-Directory ( [Parameter(HelpMessage="Initial directory to start search from.")][string]$location ){
     try {
        $startLocation = $startLocation.trim("/\")
        pushd .
        cd -ea 0 $startLocation
        if( "$(resolve-path -ea 0 $pwd.Path)" -ne "$(resolve-path -ea 0 $startLocation)" ) {
             $startLocation +=  "\.." 
            cd -ea 0 $startLocation
            if( "$(resolve-path -ea 0 $pwd.Path)" -ne "$(resolve-path -ea 0 $startLocation)" ) {
                return $null
            } 
        }
        return $pwd.path 
     } finally {
         popd
     }
}

function Find-FileInTree (
    [Parameter(HelpMessage="Initial directory to start search from.")][string]$startLocation=$pwd.Path,
    [Parameter(HelpMessage="Filename to search for.",Mandatory=$true)][string]$filename ) {
    try {
        pushd . 
        $startLocation = Resolve-Directory $startLocation
        if( $startLocation ) {
            cd $startLocation
            do {
                $last = $pwd
                if( (test-path ".\$filename" ) ) {
                    return (resolve-path ".\$filename").Path
                }
                cd ..
            } while($pwd.path -ne $last.path ) 
        }
    } finally {
        popd 
    }
    return $null
}

function eval($item) {
    if( $item ) {
        if( $item -is "ScriptBlock" ) {
            return & $item
        }
        return $item
    }
    return $null
}

function Invoke-Assignment {
    if( $args ) {
        # ternary
        if ($p = [array]::IndexOf($args,'?' )+1) {
            if (eval($args[0])) {
                return eval($args[$p])
            } 
            return eval($args[([array]::IndexOf($args,':',$p))+1]) 
        }
        
        # null-coalescing
        if ($p = ([array]::IndexOf($args,'??',$p)+1)) {
            if ($result = eval($args[0])) {
                return $result
            } 
            return eval($args[$p])
        } 
        
        # neither ternary or null-coalescing  
        return eval($args[0])
    }
    return $null
}

function Find-SolutionFile ([Parameter(HelpMessage="Initial directory to start search from.")][string]$startLocation=$pwd.Path){
    return = { Find-FileInTree $startLocation "global.json" } ?? { Find-FileInTree $startLocation "project.json"} 
}

function Parse-SolutionFile( 
    [Parameter(HelpMessage="Solution (global.json) or Project file (project.json) ")][string]$solutionFile ) {
    
    if( $solutionFile -and  (test-path $solutionFile )) {
        $solutionRoot = get-folder $solutionFile
        
        if( (Is-LoneProject $solutionFile) ) {
            $loneProject = $true
            $projects="$(Get-FolderName projectFolder)"
            $frameworks=@("net45")
        } else {
            $solution = (convertfrom-json (get-content -raw "$solutionRoot\global.json" ))
            if ($solution -and $solution.projects) {
                $projects = $solution.projects |? { -not ("$_" -match "test" ) } 
                $frameworks = get-keys $solution.frameworks    
                $loneProject = $false
            } else { 
                return
            }
        }
        return $solutionRoot, $projects, $frameworks, $loneProject
    }
}

function Get-BuildNumber ([Parameter(HelpMessage="Solution Root Directory")][string]$solutionRoot){
    $buildNumberFile = resolve-path "$solutionRoot\.number" -ea 0
    $env:DNX_BUILD_VERSION = 0
    
    if( $buildNumberFile ) {
        $ENV:DNX_BUILD_VERSION=(([int](get-content $buildNumberFile))+1)
        set-content $buildNumberFile  -Value $env:DNX_BUILD_VERSION
    }
    return $env:DNX_BUILD_VERSION
}

function Clear-SolutionAritfacts([Parameter(HelpMessage="Solution (global.json) or Project file (project.json) ")][string]$solutionFile) {
    if ($solutionFile -and (test-path $solutionFile)) {
    # switch to the solution folder
    cd (Get-Folder $solutionFile)
    
        if( Is-LoneProject $solutionFile ) {
            write-status -info "Cleaning relative to project file: $solutionFile"
        } else {
            write-status -info "Cleaning relative to solution file: $solutionFile"
        }
        nuke-knownfolders (resolve-path "$pwd")
        
        push-indent
        (convertfrom-json (get-content -raw $solutionFile )).Projects |% {
            write-status -info "Cleaning project ($_)"
            push-indent
            if( (test-path "$pwd\$_") ) {
                nuke-knownfolders (resolve-path "$pwd\$_")
            }
            pop-indent
        }
        pop-indent
    }
} 

function Build-Package(
    [Parameter(HelpMessage="Solution (global.json) or Project file (project.json) ")][string]$solutionFile,
    [Parameter(HelpMessage="Configuration to build (default='debug') ")][string] $config = "debug"
    ) {
        write-host "in here $solutionFile"
    if ($solutionFile -and (test-path $solutionFile)) { 
        $solutionRoot, $projects, $frameworks, $loneProject = Parse-SolutionFile $solutionFile
        
        Push-State
        
        write-status $important "Build number: $(Get-BuildNumber $solutionRoot)"
    
        Clear-SolutionAritfacts $solutionFile
        
        # just build the top project for output.
        dnu restore --parallel
        if( $lastExitCode ) {
            return write-error "Failed package restore "
        }
        
        write-status -fore white "Building packages ($projects)"
        dnu pack $projects --configuration $config  
        # specifying frameworks doesn't work correctly.
        # --framework $frameworks
        
        if( $lastExitCode ) {
            return write-error "Failed build."
        }
        
        # use of --out in dnu pack causes packages to have assemblies from the out folder that were compiled stuffed into their package. Stupid.
        if( $loneProject ) {
            rename "$solutionRoot\bin" "packages"
        } else {
            # create package output folder
            $packageFolder = "$solutionRoot\packages"
            $shh = mkdir $packageFolder -ea 0

            # move all the output packages to the packages folder
            $projects |% {  copy -force -recurse "$solutionRoot\$_\bin\*" $packageFolder;  nuke-folder "$solutionRoot\$_\bin" }
        }
        
        # tell the user what we built
        Pop-State
        
        dir -recurse "$solutionRoot\packages\$config\*.nupkg" |% { 
            write-output $_
        }
    } 
}

function For-EachObjectElse{
    [CmdletBinding()]

    Param (
        [Parameter(Mandatory=$true)][ScriptBlock]$Process
        ,[Parameter(Mandatory=$false,ValueFromPipeline=$true)] $InputObject =$null
        ,[Parameter(Mandatory=$false)][ScriptBlock]$else )
    Begin{ 
        $processed = $false
        $process = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)`r`n" + $process.ToString())
    }
    Process{
        if( $InputObject ) { 
            $processed = $true
            & $Process $InputObject
        }
    }
    End{
        if( (!$processed) -and ($else) ) {
           # $else  = $ExecutionContext.InvokeCommand.NewScriptBlock("param(`$_)`r`n" + $else.ToString())
           & $else
        }
    }
}

function Wipe-PackageCache {
    write-status -fore DarkGreen "Clearing package http cache"
    dnu clear-http-cache
    
    write-status -fore DarkGreen "Clearing installed package folder ($env:userprofile\.dnx\packages)"
    nuke-folder "$env:userprofile\.dnx\packages"
}

new-alias -name "=" Invoke-Assignment  -Description "FearTheCowboy's Invoke-Assignment."
new-alias -name "%%" For-EachObjectElse
  
export-modulemember -alias * -function *