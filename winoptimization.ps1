# winopt-adm.ps1 – Otimizador Windows completo (REQUER ADMIN)
# Hospede em: https://raw.githubusercontent.com/seuuser/winopt-adm/main/winopt-adm.ps1

# ---- AUTO-ELEVAR ----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoP -Ep Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ---- PONTO DE RESTAURAÇÃO ----
Write-Host "Deseja criar um Ponto de Restauração antes de continuar? (S/N)" -ForegroundColor Yellow
$resp = Read-Host
if ($resp -eq 'S' -or $resp -eq 's') {
    Checkpoint-Computer -Description "WinOpt-$(Get-Date -Format 'yyyyMMdd-HHmm')" -RestorePointType "MODIFY_SETTINGS"
    Write-Host "Ponto de restauração criado!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

# ---- FUNÇÕES ----
function Show-Menu {
    Clear-Host
    Write-Host "=== OTIMIZADOR WINDOWS (ADMIN) ===" -ForegroundColor Cyan
    Write-Host "[1] Limpeza"
    Write-Host "[2] Desempenho"
    Write-Host "[3] Segurança & Privacidade"
    Write-Host "[4] Serviços Desnecessários"
    Write-Host "[5] Integridade do Sistema"
    Write-Host "[6] Teclado & Mouse (Remove Delay)"
    Write-Host "[7] Sair"
}

function Invoke-Clean {
    Clear-Host; Write-Host "--- LIMPEZA ---" -ForegroundColor Green
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    ipconfig /flushdns | Out-Null
    vssadmin delete shadows /all /quiet 2>$null
    Remove-Item "$env:SystemRoot\Logs\CBS\*.log" -Force -ErrorAction SilentlyContinue
    Write-Host "Limpeza concluída!" -ForegroundColor Green; Pause
}

function Invoke-Performance {
    Clear-Host; Write-Host "--- DESEMPENHO ---" -ForegroundColor Blue
    Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name MenuShowDelay -Value 0
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name IconsOnly -Value 1
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name ConsentPromptBehaviorAdmin -Value 0
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Start-Process "$env:SystemRoot\System32\OneDriveSetup.exe" "/uninstall" -Wait -NoNewWindow
    powercfg /hibernate off
    Write-Host "Ajustes de desempenho aplicados!" -ForegroundColor Green; Pause
}

function Invoke-Security {
    Clear-Host; Write-Host "--- SEGURANÇA & PRIVACIDADE ---" -ForegroundColor Magenta
    Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -Value 0 -Force
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name Value -Value 0 -Force
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableSmartScreen -Value 0 -Force
    Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name TailoredExperiencesWithDiagnosticDataEnabled -Value 0
    Write-Host "Privacidade reforçada!" -ForegroundColor Green; Pause
}

function Invoke-Services {
    Clear-Host; Write-Host "--- SERVIÇOS ---" -ForegroundColor Yellow
    $services = @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","DiagTrack","dmwappushservice","MapsBroker","lfsvc")
    foreach ($svc in $services) {
        Stop-Service $svc -Force -ErrorAction SilentlyContinue
        Set-Service $svc -StartupType Disabled
    }
    Write-Host "Serviços desabilitados!" -ForegroundColor Green; Pause
}

function Invoke-Health {
    Clear-Host; Write-Host "--- INTEGRIDADE ---" -ForegroundColor Red
    sfc /scannow
    DISM /Online /Cleanup-Image /RestoreHealth
    chkdsk C: /scan
    Pause
}

function Invoke-InputTuning {
    do {
        Clear-Host
        Write-Host "--- TECLADO & MOUSE (REMOVE DELAY) ---" -ForegroundColor Cyan
        Write-Host "[1] Acelerar repetição de tecla"
        Write-Host "[2] Mouse sem aceleração"
        Write-Host "[3] Polling rate 1000 Hz"
        Write-Host "[4] Bluetooth sem delay"
        Write-Host "[5] Aplicar todos"
        Write-Host "[0] Voltar"
        $opt = Read-Host "Escolha"
        switch ($opt) {
            '1' {
                Set-ItemProperty "HKCU:\Control Panel\Keyboard" -Name KeyboardDelay -Value 0
                Set-ItemProperty "HKCU:\Control Panel\Keyboard" -Name KeyboardSpeed -Value 31
                Write-Host "Repetição de tecla otimizada!" -ForegroundColor Green; Pause
            }
            '2' {
                Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseSpeed -Value 0
                Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseThreshold1 -Value 0
                Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseThreshold2 -Value 0
                Write-Host "Aceleração do mouse desativada!" -ForegroundColor Green; Pause
            }
            '3' {
                Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name MouseSensitivity -Value 10
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\UsbHub\Parameters" -Name SelectiveSuspendEnabled -Value 0 -Force
                Write-Host "Polling rate ajustado (1000 Hz)!" -ForegroundColor Green; Pause
            }
            '4' {
                Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\BTHUSB\Parameters" -Name SelectiveSuspendEnabled -Value 0 -Force
                Write-Host "Bluetooth sem delay aplicado!" -ForegroundColor Green; Pause
            }
            '5' {
                '1','2','3','4' | % { Invoke-InputTuning $_ }
                Write-Host "Todas as otimizações de input aplicadas!" -ForegroundColor Green; Pause
            }
            '0' { return }
        }
    } while ($true)
}

# ---- LOOP PRINCIPAL ----
do {
    Show-Menu
    switch (Read-Host "Escolha") {
        '1' { Invoke-Clean }
        '2' { Invoke-Performance }
        '3' { Invoke-Security }
        '4' { Invoke-Services }
        '5' { Invoke-Health }
        '6' { Invoke-InputTuning }
        '7' { exit }
    }
} while ($true)
