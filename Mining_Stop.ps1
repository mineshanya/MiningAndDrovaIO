# this script writen by mineshanya#1525, you can find me in Discord
# ===================================================================================================================================== #

#Requires -RunAsAdministrator

# ========================================= Configure this section below according to your PC ========================================= #

$AfterburnerApp = 'MSIAfterburner'
$AfterburnerPath = 'C:\Program Files (x86)\MSI Afterburner'

$PillApp = 'OhGodAnETHlargementPill-r2'

# ===================================================================================================================================== #

Taskkill /IM $($PillApp+'.exe')
Taskkill /IM app_nhm.exe
Start-Sleep -s 2
Start-Process -FilePath $($AfterburnerApp+'.exe') -WorkingDirectory $AfterburnerPath -ArgumentList "-Profile2"