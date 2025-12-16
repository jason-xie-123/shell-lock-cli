param (
    [string]$MutexName,
    [string]$GitBashPath,
    [string]$ShellCommand
)

if (-not $MutexName) {
    Write-Error "MutexName parameter is required."
    exit 1
}

if (-not $ShellCommand) {
    Write-Error "ShellCommand parameter is required."
    exit 1
}

$isNewMutex = $false
$mutex = [System.Threading.Mutex]::new($true, $MutexName, [ref]$isNewMutex)

if (-not $isNewMutex) {
    $mutex.WaitOne([System.Threading.Timeout]::Infinite) | Out-Null
}

try {
    #    Write-output "Executing shell command: $ShellCommand"

   $arguments = "-c `"$ShellCommand`""
   
   $process = Start-Process -FilePath $GitBashPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait
   
   if ($process.ExitCode -ne 0) {
       exit $process.ExitCode
   }
} catch {
    Write-Error "ShellCommand execution failed: $_"
    exit 1
} finally {
    $mutex.ReleaseMutex()
}
