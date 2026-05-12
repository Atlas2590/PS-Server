# ==============================================================================
# SCRIPT PRINCIPALE - AVVIO
# ==============================================================================

# Funzione per comando FileZilla (rimasta singola per ora)
function Esegui-FileZilla {
    Write-Host "Configurazione FileZilla in corso..."
    # ... (Inserisci qui la tua logica XML esistente)
}

function Esegui-Comando1 {
    Write-Host "Hai scelto Comando 1"
    # Inserisci qui il codice per il Comando 1
    $NOME_DOMINIO = (Get-ADDomain).NetBIOSName
    $parentOU = Read-Host "Inserisci il nome dell'unità organizzativa principale (NOME SCUOLA)"
    $parentOU_DN = "OU=$parentOU,DC=$NOME_DOMINIO,DC=local" #modifica il dominio se necessario

    #Creazione della parent OU
    try {
        New-ADOrganizationalUnit -Name $parentOU -Path "DC=$NOME_DOMINIO,DC=local"
        Write-Host "Unità Organizzativa '$parentOU' creata con successo!"
    }
    catch{
        Write-Host "Errore durante la creazione dell'OU '$parentOU': $_"
        return
    }

#Creazione delle OUs figlie
$childOUDN = "OU=Utenti_User,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Utenti_User" -Path $parentOU_DN
        Write-Host "OU figlia Utenti_User creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Utenti_Admin,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Utenti_Admin" -Path $parentOU_DN
        Write-Host "OU figlia Utenti_Admin creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Computers_User,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Computers_User" -Path $parentOU_DN
        Write-Host "OU figlia Computers_User creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
$childOUDN = "OU=Computers_Admin,$parentOU_DN"

    try {
        New-ADOrganizationalUnit -Name "Computers_Admin" -Path $parentOU_DN
        Write-Host "OU figlia Computers_Admin creata con successo in '$parentOU'."
    }
    catch {
        Write-Host "Errore durante la creazione della OU Utenti_User: $_"
    }
}

# LOOP PRINCIPALE
while ($true) {
    Write-Header "SISTEMA GESTIONE SERVER"
    Write-Host "1 - Crea Unità Organizzative (OU)"
    Write-Host "2 - Gestione Utenti (Manuale/CSV) >" -ForegroundColor Yellow
    Write-Host "3 - Gestione FileZilla >" -ForegroundColor Yellow
    Write-Host "4 - Gestione Group Policy (GPO) >" -ForegroundColor Yellow
    Write-Host "Q - Esci"
    
    $tasto = [System.Console]::ReadKey($true).KeyChar.ToString().ToUpper()
    switch ($tasto) {
        '1' { Esegui-Comando1; Pausa } # La tua funzione OU
        '2' { Show-MenuAD }
        '3' { Show-MenuFileZilla } # La tua funzione FileZilla
        '4' { Show-MenuGPO }
        'Q' { exit }
    }
}
