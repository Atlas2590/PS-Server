# ==============================================================================
# LOGICA FILEZILLA SERVER (Versione 0.9.x - GESTIONE AVANZATA)
# ==============================================================================

function Configura-FileZillaFirewall {
    Write-Host "Configurazione Firewall per Applicazione e Interfaccia FileZilla..." -ForegroundColor Yellow
    
    $dirZilla = "C:\Program Files (x86)\FileZilla Server"
    $exeServer = "$dirZilla\FileZilla Server.exe"
    $exeInterface = "$dirZilla\FileZilla Server Interface.exe"
    
    # Verifica esistenza cartella
    if (!(Test-Path $dirZilla)) {
        Write-Host " [!] ERRORE: Cartella FileZilla non trovata." -ForegroundColor Red
        return
    }

    # --- 1. REGOLA PER IL MOTORE (SERVER) ---
    if (Test-Path $exeServer) {
        if (!(Get-NetFirewallRule -Name "FileZilla_Server_App" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "FileZilla Server (Core Service)" `
                                -Direction Inbound -Program $exeServer -Action Allow `
                                -Name "FileZilla_Server_App" -Description "Permette il traffico FTP gestito dal servizio" | Out-Null
            
            New-NetFirewallRule -DisplayName "FileZilla Server (Core Service Out)" `
                                -Direction Outbound -Program $exeServer -Action Allow `
                                -Name "FileZilla_Server_App_Out" | Out-Null
            Write-Host " > Regole per il Servizio Server create." -ForegroundColor Green
        } else {
            Write-Host " > Regole Servizio Server già esistenti." -ForegroundColor Cyan
        }
    }

    # --- 2. REGOLA PER L'INTERFACCIA (ADMIN) ---
    if (Test-Path $exeInterface) {
        if (!(Get-NetFirewallRule -Name "FileZilla_Interface_App" -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -DisplayName "FileZilla Server (Admin Interface)" `
                                -Direction Inbound -Program $exeInterface -Action Allow `
                                -Name "FileZilla_Interface_App" -Description "Permette la connessione dell'interfaccia di amministrazione" | Out-Null
            
            Write-Host " > Regola per l'Interfaccia Admin creata." -ForegroundColor Green
        } else {
            Write-Host " > Regola Interfaccia Admin già esistente." -ForegroundColor Cyan
        }
    }
}

function Aggiungi-UtenteFileZilla {
    param([string]$Username)

    $xmlPath = "C:\Program Files (x86)\FileZilla Server\FileZilla Server.xml"
    if (!(Test-Path $xmlPath)) { return }

    # Path cartella
    $folderPath = if ($Username -eq "SCANSIONI") { "C:\DATI\SCANSIONI" } else { "C:\DATI\$Username\SCANSIONI" }
    if (!(Test-Path $folderPath)) { New-Item -Path $folderPath -ItemType Directory -Force | Out-Null }

    [xml]$xmlDoc = Get-Content $xmlPath
    $usersNode = $xmlDoc.SelectSingleNode("//Users")

    # --- CONTROLLO DUPLICATI INTERATTIVO ---
    $existingUser = $usersNode.User | Where-Object { $_.Name -eq $Username }
    if ($existingUser) {
        Write-Host "`n [!] ATTENZIONE: L'utente [$Username] è già registrato." -ForegroundColor Yellow
        $scelta = Read-Host " Vuoi sostituirlo/aggiornarlo? (S/N)"
        if ($scelta.ToUpper() -eq 'S') {
            Write-Host " > Rimozione vecchio profilo..." -ForegroundColor Gray
            $usersNode.RemoveChild($existingUser) | Out-Null
        } else {
            Write-Host " > Operazione annullata per l'utente $Username." -ForegroundColor Cyan
            return
        }
    }

    # Fermiamo il servizio per l'aggiornamento
    Stop-Service "FileZilla Server" -ErrorAction SilentlyContinue

    # --- COSTRUZIONE UTENTE ---
    $userNode = $xmlDoc.CreateElement("User")
    $userNode.SetAttribute("Name", $Username)

    function Add-FzOption($parent, $name, $value) {
        $opt = $xmlDoc.CreateElement("Option")
        $opt.SetAttribute("Name", $name)
        $opt.InnerText = $value
        $parent.AppendChild($opt) | Out-Null
    }

    # Parametri Account
    Add-FzOption $userNode "Pass" $Username
    Add-FzOption $userNode "Enabled" "1"
    Add-FzOption $userNode "Bypass server userlimit" "2"
    Add-FzOption $userNode "User Limit" "0"
    Add-FzOption $userNode "IP Limit" "0"
    Add-FzOption $userNode "Comments" ""
    Add-FzOption $userNode "ForceSsl" "0"

    # Permessi
    $permsNode = $xmlDoc.CreateElement("Permissions")
    $permNode = $xmlDoc.CreateElement("Permission")
    $permNode.SetAttribute("Dir", $folderPath)
    $opts = @{"FileRead"=1;"FileWrite"=1;"FileDelete"=1;"FileAppend"=1;"DirCreate"=1;"DirDelete"=1;"DirList"=1;"DirSubdirs"=1;"IsHome"=1;"AutoCreate"=0}
    foreach ($key in $opts.Keys) { Add-FzOption $permNode $key $opts[$key] }
    $permsNode.AppendChild($permNode) | Out-Null
    $userNode.AppendChild($permsNode) | Out-Null

    # Nodi strutturali vuoti (richiesti)
    $userNode.AppendChild($xmlDoc.CreateElement("IpFilter")) | Out-Null
    $speedNode = $xmlDoc.CreateElement("SpeedLimits")
    $speedNode.SetAttribute("DlType","0"); $speedNode.SetAttribute("UlType","0")
    $userNode.AppendChild($speedNode) | Out-Null

    $usersNode.AppendChild($userNode) | Out-Null

    # Salvataggio e Riavvio
    $xmlDoc.Save($xmlPath)
    Start-Service "FileZilla Server"
    Write-Host " > Utente [$Username] configurato correttamente." -ForegroundColor Green
}

function Show-MenuFileZilla {
    $back = $false
    while (-not $back) {
        Write-Header "GESTIONE FILEZILLA 0.9.x"
        Write-Host "1 - Configura Firewall (App Rule)"
        Write-Host "2 - Importa Utenti da CSV (Usa Cognome)"
        Write-Host "3 - Aggiungi Utente Singolo"
        Write-Host "4 - Crea Utente Generico 'SCANSIONI'"
        Write-Host "5 - Riavvia Servizio"
        Write-Host "B - Torna Indietro"

        $key = [System.Console]::ReadKey($true).KeyChar.ToString().ToUpper()
        switch ($key) {
            '1' { Configura-FileZillaFirewall; Pausa }
            '2' { 
                $file = Read-Host "`nTrascina il CSV degli utenti"
                $file = $file.Trim('"').Trim()
                if (Test-Path $file) {
                    $sep = if ((Get-Content $file -TotalCount 1) -match ';') { ';' } else { ',' }
                    Import-Csv $file -Delimiter $sep | ForEach-Object { 
                        if ($_.Cognome) { Aggiungi-UtenteFileZilla -Username $_.Cognome } 
                    }
                }
                Pausa
            }
            '3' {
                $user = Read-Host "Inserisci Cognome"
                if ($user) { Aggiungi-UtenteFileZilla -Username $user }
                Pausa
            }
            '4' { Aggiungi-UtenteFileZilla -Username "SCANSIONI"; Pausa }
            '5' { Restart-Service "FileZilla Server"; Write-Host "Riavviato."; Pausa }
            'B' { $back = $true }
        }
    }
}