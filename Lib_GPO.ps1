# ==============================================================================
# LOGICA GROUP POLICY (GPO)
# ==============================================================================

function Applica-GPO-Pacchetto {
    param($GPOName, $RegPath, $Settings)

    Import-Module GroupPolicy
    Import-Module ActiveDirectory

    # 1. Gestione creazione GPO
    if (-not (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue)) {
        New-GPO -Name $GPOName -Comment "Creata via script AdminTool"
    }

    # 2. Costruzione dell'albero visivo per la selezione
    $dominio = Get-ADDomain
    $ous = Get-ADOrganizationalUnit -Filter *
    
    $listaAlbero = @()
    # Aggiungiamo il Dominio
    $listaAlbero += [PSCustomObject]@{
        Gerarchia = "[DOMINIO: $($dominio.DNSRoot.ToUpper())]"
        DN        = $dominio.DistinguishedName
        SortKey   = "000" # Forza il dominio in cima
    }

    # Prepariamo le OU con la chiave di ordinamento invertita
    foreach ($ou in $ous) {
        $dnParti = $ou.DistinguishedName.Split(',')
        [array]::Reverse($dnParti)
        $depth = ([regex]::Matches($ou.DistinguishedName, "OU=")).Count
        
        $listaAlbero += [PSCustomObject]@{
            Gerarchia = ("    " * ($depth - 1)) + "|--- $($ou.Name)"
            DN        = $ou.DistinguishedName
            SortKey   = $dnParti -join ','
        }
    }

    # 3. Selezione tramite Out-GridView
    $OUTarget = $listaAlbero | Sort-Object SortKey | Out-GridView -Title "Seleziona destinazione per $GPOName" -OutputMode Single

    if ($OUTarget) { 
        New-GPLink -Name $GPOName -Target $OUTarget.DN -ErrorAction SilentlyContinue 
        
        # 4. Applicazione settaggi registry
        foreach ($S in $Settings) {
            $FinalPath = if ($S.SpecificPath) { $S.SpecificPath } else { $RegPath }
            Set-GPRegistryValue -Name $GPOName -Key $FinalPath -ValueName $S.Name -Type $S.Type -Value $S.Value
            Write-Host "Configurato: $($S.Name) ($($S.Type))" -ForegroundColor Gray
        }
        Write-Host "GPO $GPOName applicata con successo a $($OUTarget.DN)!" -ForegroundColor Green
    } else {
        Write-Host "Operazione annullata: nessuna destinazione selezionata." -ForegroundColor Yellow
    }
}


function Show-MenuGPO {
    $back = $false
    while (-not $back) {
        Write-Header "GESTIONE GROUP POLICY"
        Write-Host "1 - Applica Policy Bitlocker Completa"
        Write-Host "2 - Applica Policy Wallpaper (Esempio String)"
        Write-Host "B - Torna Indietro"

        $key = [System.Console]::ReadKey($true).KeyChar.ToString().ToUpper()
        switch ($key) {
            '1' {
                # --- CONTROLLO E CREAZIONE PERCORSO ---
                $LocalPath = "C:\DATI\CED\MDS\BITLOCKER_KEY"
                $NetworkPath = "\\$env:COMPUTER_NAME\CED\MDS\BITLOCKER_KEY\"

                Write-Host "Verifica percorso: $LocalPath..." -ForegroundColor Yellow
                if (!(Test-Path $LocalPath)) {
                    try {
                        # Creazione ricorsiva di tutte le sottocartelle mancanti
                        New-Item -Path $LocalPath -ItemType Directory -Force | Out-Null
                        Write-Host "Percorso creato con successo." -ForegroundColor Green
                    } catch {
                        Write-Host "Errore creazione cartella: $($_.Exception.Message)" -ForegroundColor Red
                        Pausa; return
                    }
                }

                # --- CONFIGURAZIONE PARAMETRI ---
                $BitlockerSettings = @(
                    @{ Name="ActiveDirectoryBackup"; Type="DWord"; Value=1 },
                    @{ Name="DefaultRecoveryFolderPath"; Type="ExpandString"; Value=$NetworkPath },
                    @{ Name="UseRecoveryPassword"; Type="DWord"; Value=1 },
                    @{ Name="UseAdvancedStartup"; Type="DWord"; Value=1 },
                    @{ Name="OSEncryptionType"; Type="DWord"; Value=2 },
                    @{ Name="OSPassphrase"; Type="DWord"; Value=1 },
                    @{ Name="OSPassphraseComplexity"; Type="DWord"; Value=1 },
                    @{ Name="OSRecovery"; Type="DWord"; Value=1 },
                    @{ Name="RDVConfigureBDE"; Type="DWord"; Value=1 },
                    @{ Name="RDVDenyWriteAccess"; Type="DWord"; Value=1; SpecificPath="HKLM\System\CurrentControlSet\Policies\Microsoft\FVE" },
                    @{ Name="RDVEncryptionType"; Type="DWord"; Value=2 },
                    @{ Name="RDVPassphrase"; Type="DWord"; Value=1 },
                    @{ Name="RDVPassphraseComplexity"; Type="DWord"; Value=1 },
                    @{ Name="RDVRecovery"; Type="DWord"; Value=1 },
                    @{ Name="FDVDenyWriteAccess"; Type="DWord"; Value=1; SpecificPath="HKLM\System\CurrentControlSet\Policies\Microsoft\FVE" },
                    @{ Name="FDVEncryptionType"; Type="DWord"; Value=2 },
                    @{ Name="FDVPassphrase"; Type="DWord"; Value=1 },
                    @{ Name="FDVPassphraseComplexity"; Type="DWord"; Value=1 },
                    @{ Name="FDVRecovery"; Type="DWord"; Value=1 }
                )
                Applica-GPO-Pacchetto -GPOName "MDS-Bitlocker" -RegPath "HKLM\SOFTWARE\Policies\Microsoft\FVE" -Settings $BitlockerSettings
                Pausa
            }
            '2' {
                $WallSettings = @( @{ Name="Wallpaper"; Type="String"; Value="\\$NOME_PC\CONDIVISA\sfondo.jpg" } )
                Applica-GPO-Pacchetto -GPOName "MDS-Wallpaper" -RegPath "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Settings $WallSettings
                Pausa
            }
            'B' { $back = $true }
        }
    }
}