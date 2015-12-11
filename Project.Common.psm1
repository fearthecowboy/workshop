$InformationPreference=2
try { 
    $script:origPWD = $pwd
    $script:origFore = $host.UI.RawUI.ForegroundColor 
    $script:origBack = $host.UI.RawUI.BackgroundColor 
} finally { }

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

function Restore-State {
    try { 
        if( $script:origPWD ) { 
            cd $script:origPWD 
        }
        if( $origFore ) {
            $host.UI.RawUI.ForegroundColor = $script:origFore 
            $host.UI.RawUI.BackgroundColor = $script:origBack 
        }
    } finally { }
}

function Convert-ToHashtable{ 
    param( 
        $object 
    )
    $keys = ($object| get-member -MemberType NoteProperty).Name
    
    $result = @{}
    $keys |% { $result[$_] = $object.($_) }
    return $result
}

function Get-Keys {
    param( 
        $object 
    )
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
        write-status -fore DarkGray "    Removing $folder"
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
        [int] $detail = 1,
        $foregroundColor,
        $backgroundColor
    )    
    Set-Color $foregroundColor $backgroundColor
    write-information "$message"
}

function Find-ProjectRoot {
    try {
        do {
            $last = $pwd
            if( (test-path .\global.json ) ) {
                return (resolve-path .\global.json).Path
            }
            cd ..
        } while($pwd.path -ne $last.path ) 
        popd 
        pushd 
        do {
            $last = $pwd
            if( (test-path .\project.json ) ) {
                return (resolve-path .\project.json).Path
            }
        } while($pwd.path -ne $last.path )
    } finally {
        popd
    }
    return $null
}
