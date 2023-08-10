# Track changes to ubisoft folders

# Have this run as a background service
# Action: Start a program
# Program/script: Powershell.exe
# Arguments: -NoExit -ExecutionPolicy Bypass C:\Temp\Script.ps1

# Set log file path
$logFile = "${PSScriptRoot}\grb-changes.log"
$grbPath = "D:\UbisoftLibrary\Ghost Recon Breakpoint"

Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO","WARN","ERROR")]
        [string] $level = "INFO"
    )
    # Create timestamp
    $timestamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $logEntry = "$timestamp [$level] - $message"

    # Write to the console
    Write-Host $logEntry -ForegroundColor DarkYellow
    # Append content to log file
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log -level INFO -message "Using logfile at $logFile"

$foldersToMonitor = @(
    "${grbPath}",
    "${Env:LOCALAPPDATA}\Ubisoft Game Launcher",
    "${Env:LOCALAPPDATA}\NVIDIA\NvBackend\ApplicationOntology\data\wrappers",
    "${Env:LOCALAPPDATA}\NVIDIA\NvBackend\VisualOPSData\tom_clancys_ghost_recon_breakpoint",
    "${Env:ProgramFiles(x86)}\Ubisoft"
    )


# specify which files you want to monitor
$FileFilter = '*'

# specify whether you want to monitor subfolders as well:
$IncludeSubfolders = $true

# specify the file or folder properties you want to monitor:
$AttributeFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite


# define the code that should execute when a change occurs:
$action = {
    # the code is receiving this to work with:

    # change type information:
    $details = $event.SourceEventArgs
    $Name = $details.Name
    $FullPath = $details.FullPath
    $OldFullPath = $details.OldFullPath
    $OldName = $details.OldName

    # type of change:
    $ChangeType = $details.ChangeType

    # when the change occured:
    $Timestamp = $event.TimeGenerated

    # save information to a global variable for testing purposes
    # so you can examine it later
    # MAKE SURE YOU REMOVE THIS IN PRODUCTION!
    #$global:all = $details

    # now you can define some action to take based on the
    # details about the change event:

    # let's compose a message:
    $message = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp

    Write-Log -level WARN -message $message

    # you can also execute code based on change type here:
    }


try {
    $watchers = @()

    foreach ($Path in $foldersToMonitor) {
        $watcher = New-Object -TypeName System.IO.FileSystemWatcher -Property @{
            Path                  = $Path
            Filter                = $FileFilter
            IncludeSubdirectories = $IncludeSubfolders
            NotifyFilter          = $AttributeFilter
        }


        # subscribe your event handler to all event types that are
        # important to you. Do this as a scriptblock so all returned
        # event handlers can be easily stored in $handlers:
        $handlers = . {
            Register-ObjectEvent -InputObject $watcher -EventName Changed  -Action $action
            Register-ObjectEvent -InputObject $watcher -EventName Created  -Action $action
            Register-ObjectEvent -InputObject $watcher -EventName Deleted  -Action $action
            Register-ObjectEvent -InputObject $watcher -EventName Renamed  -Action $action
        }

        # monitoring starts now:
        $watcher.EnableRaisingEvents = $true

        Write-Log -level INFO -message "Watching for changes to $Path"

        $watchers += $watcher
    }

    # since the FileSystemWatcher is no longer blocking PowerShell
    # we need a way to pause PowerShell while being responsive to
    # incoming events. Use an endless loop to keep PowerShell busy:
    do {
        # Wait-Event waits for a second and stays responsive to events
        # Start-Sleep in contrast would NOT work and ignore incoming events
        Wait-Event -Timeout 2

        # write a dot to indicate we are still monitoring:
        #Write-Host "." -NoNewline

    } while ($true)
}
finally {
    # this gets executed when user presses CTRL+C:

    foreach ($watcher in $watchers) {
        # stop monitoring
        $watcher.EnableRaisingEvents = $false

        # remove the event handlers
        $handlers | ForEach-Object {
            Unregister-Event -SourceIdentifier $_.Name
        }

        # event handlers are technically implemented as a special kind
        # of background job, so remove the jobs now:
        $handlers | Remove-Job

        # properly dispose the FileSystemWatcher:
        $watcher.Dispose()
    }

    Write-Log -level INFO -message "Event handlers disabled."
    Write-Warning "Event Handler disabled, monitoring ends."
}