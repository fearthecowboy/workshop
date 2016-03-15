#==============================================================================
#  Copyright (c) Microsoft Corporation. All rights reserved.
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#==============================================================================

#==============================================================================
#
# This script makes it so you can execute .ps1 scripts either by double clicking 
# or anywhere you can run an command (ie, from cmd.exe command line, or the 
# WinKey-R Run Dialog)
#
# WARNING: There is a reason that this is not the default in Windows. This 
# certainly would make it simpler to accidentally run a script when you expected
# something else. 
#
# I Like this because it makes it easier for me to use my system like I always
# have; I make a lot of scripts to automate so much, and I don't always run from
# the powershell prompt; I use cmd.exe for a lot of stuff too. 
#
#==============================================================================

# Ensure this script is elevated.
#==============================================================================
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    return Start-Process -wait -FilePath PowerShell.exe -Verb Runas -windowstyle hidden -WorkingDirectory $pwd -ArgumentList (@('-file',$MyInvocation.MyCommand.Definition)+$args)
}

# Set the open command for .ps1 files to execute via powershell.exe 
#==============================================================================
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
Set-ItemProperty -Path "HKCR:\Microsoft.PowerShellScript.1\Shell\open\command" -name '(Default)' -Value '"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -noLogo -ExecutionPolicy unrestricted -file "%1" %*'

# Ensure that .ps1 is in the ExtPath (for calling via cmd.exe)
#==============================================================================

function Append-ToEnvironment{ param( [string] $var, [string] $value, [System.EnvironmentVariableTarget]$Context = "Machine" ) 
    [System.Environment]::SetEnvironmentVariable( $var, (("$([System.Environment]::GetEnvironmentVariable($var, $context))".Split(';',[StringSplitOptions]'RemoveEmptyEntries') + $val | select -uniq ) -join ';') , $context )
}

Append-ToEnvironment "PATHEXT" ".ps1"
Append-ToEnvironment "PATHEXT" ".ps1" "Process"
