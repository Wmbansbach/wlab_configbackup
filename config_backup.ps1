# WLAB Configuration File Backup Utility
#--------------------------------------------------
# Synopsis:
# * Backup Script located on WMSERVER.WLAB.LOCAL
#   Ensures that Devices are available, then copies 
#   relevant backup configuration files. 
#
#--------------------------------------------------
# Documentation:                 
# * Logging
#   > B:\_logs\configbackup.log
#
#--------------------------------------------------
# Device List:                 
# * pihole Server
# * OPNsense Router
# * utility Server
# * Unifi Network Application
#
#--------------------------------------------------
# Change Log:
# * 11/1/2022
#   - Initial Setup
#   - Added logging for when ping fails on either server
# * 12/3/2022
#   - Added final paths
#   - Added feature to zip the entire directory and store in _archive with datestime stamp
# * 12/5/2022
#   - Added opnsense backup
# * 7/30/2023
#   - Added PW Encryption
#   - Removed parameters
#   - Consolidated logging files & added better formatting for logging file
# * 10/22/2023
#   - Replaced PW authentication with PKI auth. for all devices besides opnsense
#   - Updated Logging
#
#--------------------------------------------------
# Known Issues:
# 1. (Fixed) Must add auth. here for ansible user. Should have Least Priv.
# 2. PiHole_Backup.yml must be ran before backing up which is done via ansible playbook.
# 2.1 PiHole_Backup.yml ensures that the most update to date file is backed-up from pihole.
# 3. This script assumes that you have added the PuTTY & 7Zip directories to the PATH evironment variable. Fix is coming to check then set if needed.
#
#--------------------------------------------------
# Notes:
# * Author - W.Bansbach
#
#--------------------------------------------------
######Requires -RunAsAdministrator

$ErrorActionPreference = 'SilentlyContinue'

## Set Vars
$runlog = "B:\_logs\configbackup.log"
$key = "C:\Users\Administrator\.ssh\WMSERVER.ppk"
$starttime = Get-Date


## Start logging
Add-Content -Path $runlog -Value ("`n`nNew Session Started @ " + (Get-Date).ToString())
Add-Content -Path $runlog -Value ("`n.")
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************************************* CONFIG BACKUP START *********************************************")
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Current User: " + ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))

foreach ($path in env:Path) {
    Write-Host
}

## Move to PuTTY Directory.
Set-Location -Path "C:\Program Files\PuTTY"

## Check for Utility Server
Add-Content -Path $runlog -Value ("`n`n" + (Get-Date).ToString() + "    -    ********************* UTILITY SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n`n.")

If ((Test-NetConnection -ComputerName 192.168.10.18).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.18... Starting Copy.")

    ## Pull a copy of ansible directory
    .\pscp.exe -v -r -i $key "auto@192.168.10.18:/etc/ansible/*" "B:\config_backups\utility\ansible\." | Add-Content -Path $runlog

    ## Pull a copy of crontab file
    .\pscp.exe -v -r -i $key "auto@192.168.10.18:/etc/crontab" "B:\config_backups\utility\crontab\." | Add-Content -Path $runlog
     
}

## Failed to Connect
Else {
   
    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ansible Server @ 192.168.10.18 not found...")
}


## Check for Pihole Server
Add-Content -Path $runlog -Value ("`n`n" + (Get-Date).ToString() + "    -    ********************* PIHOLE DNS SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n`n.")

If ((Test-NetConnection -ComputerName 192.168.10.25).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.25... Starting Copy.")

    ## Run Secure Copy to pull copy of teleporter backup directory for PiHole
    .\pscp.exe -v -r -i $key "domain_admin@192.168.10.25:/home/domain_admin/pihole_backups/*" "B:\config_backups\pihole\." | Add-Content -Path $runlog

}

## Failed to Connect
Else {
    
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    PiHole Server @ 192.168.10.25 not found...")

}


## Check for opnsense Router
Add-Content -Path $runlog -Value ("`n`n" + (Get-Date).ToString() + "    -    ********************* OPNSENSE ROUTER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n`n.")

If ((Test-NetConnection -ComputerName 192.168.10.1).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.1... Starting Copy.")

    ## Run Secure Copy to pull backup of opnsense configuration file.
    .\pscp.exe -v -r -i $key "ansible_svc@192.168.10.1:/conf/config.xml" "B:\config_backups\opnsense\." | Add-Content -Path $runlog

}

 ## Failed to Connect
Else {

    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + " OPNsense Router @ 192.168.10.1 not found...")
}


## Backup Local Unifi Network Application's Backup Directory
Add-Content -Path $runlog -Value ("`n`n" + (Get-Date).ToString() + "    -    ********************* UNIFI LOCAL BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n`n.")
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Unifi Network Application Backup on localhost... Starting Copy.")

Copy-Item -Path "C:\Users\Administrator\Ubiquiti UniFi\data\backup\*" -Destination "B:\config_backups\unifi\" | Add-Content -Path $runlog


## Compress Contents of config_backups - set a name and timestamp
## Move to 7Zip directory
Set-Location -Path "C:\Program Files\7-Zip"
$update_path = "B:\config_backups\_archive\confbackup_archive" + $(Get-Date -Format "yyyyMMdd").ToString() + ".7z"

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ************************ BUILD ARCHIVE START ***********************")

.\7z.exe a -r -spf2 -mx9 $update_path "B:\config_backups\*" -x!"B:\config_backups\_archive" | Add-Content -Path $runlog


## End Logging
Add-Content -Path $runlog -Value ("`n.    -    Runtime Length: " + (New-TimeSpan -Start $starttime -End (Get-Date)).ToString())
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************************************* CONFIG BACKUP END *********************************************")
Add-Content -Path $runlog -Value ("`n.")
Add-Content -Path $runlog -Value ("`n.")
Add-Content -Path $runlog -Value ("`n.")
