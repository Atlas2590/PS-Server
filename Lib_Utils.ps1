# ==============================================================================
# FUNZIONI DI UTILITÀ E INTERFACCIA
# ==============================================================================

function Set-ProfessionalShare {
    param (
        [string]$Path,
        [string]$ShareName,
        [string]$UserIdentity,
        [string]$Rights = "Modify"
    )

    if (!(Test-Path $Path)) { New-Item -Path $Path -ItemType Directory | Out-Null }

    if (Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue) {
        Remove-SmbShare -Name $ShareName -Force
    }

    # Condivisione SMB
    New-SmbShare -Name $ShareName -Path $Path -FullAccess "Administrators" -ChangeAccess $UserIdentity -CachingMode None | Out-Null

    # Sicurezza NTFS
    $Acl = Get-Acl $Path
    $Acl.SetAccessRuleProtection($true, $false) 
    
    $AdminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $Acl.AddAccessRule($AdminRule)

    try {
        $UserRule = New-Object System.Security.AccessControl.FileSystemAccessRule($UserIdentity, $Rights, "ContainerInherit,ObjectInherit", "None", "Allow")
        $Acl.AddAccessRule($UserRule)
        Set-Acl $Path $Acl
    } catch {
        Start-Sleep -Seconds 2
        Set-Acl $Path $Acl
    }
}

function Pausa {
    Write-Host "`nPremere un tasto per continuare..." -ForegroundColor Gray
    [void][System.Console]::ReadKey($true)
}

function Write-Header {
    param($Title)
    cls
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "      $Title" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}