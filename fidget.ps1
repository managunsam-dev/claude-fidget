param($mode)
$pidf = Join-Path $env:TEMP 'claude-fidget.pid'

function Halt {
    if (Test-Path $pidf) {
        Stop-Process -Id (Get-Content $pidf) -Force -ErrorAction SilentlyContinue
        Remove-Item $pidf -ErrorAction SilentlyContinue
    }
}

switch ($mode) {
    'stop' { Halt }
    'start' {
        Halt
        $p = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, 'loop'
        $p.Id | Set-Content $pidf
    }
    'loop' {
        $interval = if ($env:FIDGET_INTERVAL) { [int]$env:FIDGET_INTERVAL } else { 30 }
        # ponytail: Esc-interrupt fires no Stop hook, so the loop dies on its own after 15 min (or on next prompt)
        $end = (Get-Date).AddMinutes(15)
        while ((Get-Date) -lt $end) {
            Start-Sleep $interval
            $f = Get-ChildItem (Join-Path $PSScriptRoot 'sounds') -Filter *.wav | Get-Random
            (New-Object Media.SoundPlayer $f.FullName).PlaySync()
        }
        Remove-Item $pidf -ErrorAction SilentlyContinue
    }
}
