# ==============================================================================
# LOGICA ACTIVE DIRECTORY - GESTIONE UTENTI
# ==============================================================================

function Crea-UtenteCompleto {
    param($Nome, $Cognome, $Password, $OUPath)

    $NOME_DOMINIO = (Get-ADDomain).NetBIOSName
    
    # Controllo: se il cognome è nullo, non possiamo creare il SamAccountName
    if ([string]::IsNullOrWhiteSpace($Cognome)) {
        Write-Host "SALTO RIGA: Cognome mancante o riga vuota nel CSV." -ForegroundColor Yellow
        return
    }

    # Username = Cognome (mantiene gli spazi come richiesto)
    $SamName = $Cognome.Trim()
    $UPN = "$SamName@$NOME_DOMINIO.local"

    try {
        # 1. Creazione Utente AD
        # Nota: SamAccountName massimo 20 caratteri
        New-ADUser -SamAccountName $SamName -GivenName $Nome -Surname $Cognome `
                   -Name "$Nome $Cognome" -UserPrincipalName $UPN -DisplayName "$Nome $Cognome" `
                   -Path $OUPath -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                   -Enabled $true
        
        Write-Host "SUCCESSO: Utente AD [$SamName] creato." -ForegroundColor Green

        # 2. Struttura Cartelle Personali
        $RootDati = "C:\DATI"
        Set-ProfessionalShare -Path "$RootDati\$SamName" -ShareName $SamName -UserIdentity "$NOME_DOMINIO\$SamName" | Out-Null
        New-Item -Path "$RootDati\$SamName\SCANSIONI" -ItemType Directory -Force | Out-Null

        # 3. Creazione Collegamenti (Shortcut)
        $CedPolicyPath = "$RootDati\CED\MDS\Policy_folder"
        if (!(Test-Path $CedPolicyPath)) { New-Item -Path $CedPolicyPath -ItemType Directory -Force | Out-Null }
        
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$CedPolicyPath\$SamName.lnk")
        $Shortcut.TargetPath = "\\svrcentrale\$SamName"
        $Shortcut.Save()

    } catch {
        Write-Host "ERRORE per $SamName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Genera-TemplateCSV {
    # Crea un file CSV con l'intestazione corretta sul Desktop dell'utente
    $Path = "$env:USERPROFILE\Desktop\Template_Utenti.csv"
    "Nome;Cognome;Password" | Out-File -FilePath $Path -Encoding utf8
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Template creato: $Path" -ForegroundColor Green
    Write-Host "Puoi aprirlo con il Blocco Note o Excel." -ForegroundColor White
    Write-Host "Usa il punto e virgola (;) per separare i campi." -ForegroundColor Yellow
    Write-Host "------------------------------------------------" -ForegroundColor Cyan
}

function Show-MenuAD {
    $back = $false
    while (-not $back) {
        Write-Header "GESTIONE UTENTI AD"
        Write-Host "1 - Esporta Template CSV (Desktop)"
        Write-Host "2 - Importazione Massiva da CSV"
        Write-Host "3 - Crea Singolo Utente (Manuale)"
        Write-Host "B - Torna al Menu Principale"
        
        $key = [System.Console]::ReadKey($true).KeyChar.ToString().ToUpper()
        switch ($key) {
            '1' { 
                Genera-TemplateCSV
                Pausa 
            }
            '2' { 
                $file = Read-Host "Trascina qui il file CSV"
                $file = $file.Trim('"').Trim()
                
                if (Test-Path $file) {
                    # RILEVAMENTO AUTOMATICO DELIMITATORE
                    # Legge la prima riga e cerca il punto e virgola
                    $primaRiga = Get-Content $file -TotalCount 1
                    $sep = if ($primaRiga -match ';') { ';' } else { ',' }
                    
                    $OU = Get-ADOrganizationalUnit -Filter * | Out-GridView -Title "Seleziona OU Destinazione" -OutputMode Single
                    
                    if ($OU) {
                        $Lista = Import-Csv $file -Delimiter $sep
                        foreach ($U in $Lista) { 
                            Crea-UtenteCompleto -Nome $U.Nome -Cognome $U.Cognome -Password $U.Password -OUPath $OU.DistinguishedName 
                        }
                    }
                } else { 
                    Write-Host "File non trovato al percorso indicato!" -ForegroundColor Red 
                }
                Pausa
            }
            '3' {
                $OU = Get-ADOrganizationalUnit -Filter * | Out-GridView -Title "Seleziona OU Destinazione" -OutputMode Single
                if ($OU) {
                    $n = Read-Host "Nome"
                    $c = Read-Host "Cognome"
                    $p = Read-Host "Password"
                    Crea-UtenteCompleto -Nome $n -Cognome $c -Password $p -OUPath $OU.DistinguishedName
                }
                Pausa
            }
            'B' { $back = $true }
        }
    }
}