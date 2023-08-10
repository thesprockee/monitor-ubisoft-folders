# Monitor Ubisoft Game Folders

 Powershell script to track changes to Ghost Recon: Breakpoint directories

## Usage

1. Edit grbPath in `monitor-ubisoft-folders.ps1`
2. Run `monitor-ubisoft-folders.ps1`

## Running as a background process

Create a Scheduled Task (see: <https://learn.microsoft.com/en-us/windows/win32/taskschd/using-the-task-scheduler>):

* Action: **Start a program**
* Program/script: `powershell.exe`
* Arguments: `-NoExit -ExecutionPolicy Bypass C:\Users\User\Example\monitor-ubisoft-folders.ps1`