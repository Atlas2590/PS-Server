# ==============================================================================
# SCRIPT PRINCIPALE - AVVIO
# ==============================================================================

# Caricamento dei file (Dot Sourcing)
# $PSScriptRoot punta alla cartella dove si trova questo file
. "$PSScriptRoot\Lib_Utils.ps1"
. "$PSScriptRoot\Lib_AD.ps1"
. "$PSScriptRoot\Lib_GPO.ps1"
. "$PSScriptRoot\Lib_FileZilla.ps1"

# Funzione per comando FileZilla (rimasta singola per ora)
function Esegui-FileZilla {
    Write-Host "Configurazione FileZilla in corso..."
    # ... (Inserisci qui la tua logica XML esistente)
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