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
#   > Backup Log - D:\Datastore\William\_sysadmin\logs\configbackup.log
#
#--------------------------------------------------
# Device List:                 
# * pihole DNS Server
# * OPNsense Router
# * Utility Server (Ansible, Grafana, Uptime Kuma)
# * Unifi WNC Server
# * CUPS Print Server
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
#   - Updated logging
# * 03/17/2024
#   - PKI is used to connect to all devices. Updated some commenting.
#   - Removed remaining references to PW authentication method.
#   - Added all working directories (PuTTY, 7Zip) to $env:Path
# * 03/23/2024
#   - Removed Unifi References until WNC is migrated to new debian box
# * 03/24/2024
#   - Updated references to directories that have been moved. 
#   - Updated references to IP addresses that have been changed.
# * 03/30/2024
#   - Added new section for Unifi WNC Server
#   - Added new section for CUPS Print Server
#   - Updated each device to backup their .ssh folder
#   - Updated logging
#--------------------------------------------------
# Known Issues:
# 1. (Fixed) Must add auth. here for ansible user. Should have Least Priv.
# 2. PiHole_Backup.yml must be ran before backing up which is done via ansible playbook.
# 2.1 PiHole_Backup.yml ensures that the most up to date file is backed-up from pihole.
# 3. Must allow access to /var/lib/unifi/backup for user wncadmin 
#
#--------------------------------------------------
# Notes:
# * Author - W.Bansbach
#
#--------------------------------------------------
######Requires -RunAsAdministrator

$ErrorActionPreference = 'SilentlyContinue'

## Set Vars
$runlog = "D:\Datastore\William\_sysadmin\logs\configbackup.log"
$key = "C:\Users\ansible_svc\.ssh\ansible_svc.ppk"
$starttime = Get-Date

## Start logging
Add-Content -Path $runlog -Value ("`n`nNew Session Started @ " + (Get-Date).ToString())
Add-Content -Path $runlog -Value ("`n.")
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************************************* CONFIG BACKUP START *********************************************")
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Current User: " + ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name))

## Move to PuTTY Directory.
Set-Location -Path "C:\Program Files\PuTTY"


##__________________________________________
##
## Check for then backup Utility Server
##___________________________________________

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************* UTILITY SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n.")

If ((Test-NetConnection -ComputerName 192.168.10.55).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.55... Starting Copy.")

    ## Pull a copy of ansible directory
    .\pscp.exe -v -r -i $key "auto@192.168.10.55:/etc/ansible/*" "D:\Datastore\William\_sysadmin\backups\config_backups\utility\ansible\." | Add-Content -Path $runlog

    ## Pull a copy of crontab file
    .\pscp.exe -v -r -i $key "auto@192.168.10.55:/etc/crontab" "D:\Datastore\William\_sysadmin\backups\config_backups\utility\crontab\." | Add-Content -Path $runlog
    
    ## Pull a copy of .ssh folder
    .\pscp.exe -v -r -i $key "auto@192.168.10.55:/home/auto/.ssh/*" "D:\Datastore\William\_sysadmin\backups\config_backups\utility\ssh\." | Add-Content -Path $runlog
      
}

## Failed to Connect
Else {
   
    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ansible Server @ 192.168.10.55 not found...")
}


##__________________________________________
##
## Check for then backup DNS Server
##___________________________________________

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************* PIHOLE DNS SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n.")

If ((Test-NetConnection -ComputerName 192.168.10.25).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.25... Starting Copy.")

    ## Run Secure Copy to pull copy of teleporter backup directory for PiHole
    .\pscp.exe -v -r -i $key "domain_admin@192.168.10.25:/home/domain_admin/pihole_backups/*" "D:\Datastore\William\_sysadmin\backups\config_backups\pihole\." | Add-Content -Path $runlog

    ## Pull a copy of .ssh folder
    .\pscp.exe -v -r -i $key "domain_admin@192.168.10.25:/home/domain_admin/.ssh/*" "D:\Datastore\William\_sysadmin\backups\config_backups\pihole\ssh\." | Add-Content -Path $runlog

}

## Failed to Connect
Else {
    
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    PiHole Server @ 192.168.10.25 not found...")

}


##__________________________________________
##
## Check for then backup Router
##___________________________________________

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************* OPNSENSE ROUTER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n.")

If ((Test-NetConnection -ComputerName 192.168.10.1).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.1... Starting Copy.")

    ## Run Secure Copy to pull backup of opnsense configuration file.
    .\pscp.exe -v -r -i $key "ansible_svc@192.168.10.1:/conf/config.xml" "D:\Datastore\William\_sysadmin\backups\config_backups\opnsense\." | Add-Content -Path $runlog

    ## Pull a copy of .ssh folder
    .\pscp.exe -v -r -i $key "ansible_svc@192.168.10.1:/home/ansible_svc/.ssh/*" "D:\Datastore\William\_sysadmin\backups\config_backups\opnsense\ssh\." | Add-Content -Path $runlog

}

 ## Failed to Connect
Else {

    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + " OPNsense Router @ 192.168.10.1 not found...")
}


##__________________________________________
##
## Check for then backup Unifi Network Controller Server & Service
##___________________________________________

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************* UNIFI WNC SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n.")

If ((Test-NetConnection -ComputerName 192.168.10.60).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.60... Starting Copy.")

    ## Run Secure Copy to pull backup of unify WNC configuration file.
    .\pscp.exe -v -r -i $key "wncadmin@192.168.10.60:/home/wncadmin/unifi/*" "D:\Datastore\William\_sysadmin\backups\config_backups\unifi\." | Add-Content -Path $runlog

    ## Pull a copy of .ssh folder
    .\pscp.exe -v -r -i $key "wncadmin@192.168.10.60:/home/wncadmin/.ssh/*" "D:\Datastore\William\_sysadmin\backups\config_backups\unifi\ssh\." | Add-Content -Path $runlog

}

 ## Failed to Connect
Else {

    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + " OPNsense Router @ 192.168.10.60 not found...")
}


##__________________________________________
##
## Check for then backup CUPS Print Server
##___________________________________________

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************* PRINT SERVER BACKUP START *********************")
Add-Content -Path $runlog -Value ("`n.")

If ((Test-NetConnection -ComputerName 192.168.10.50).PingSucceeded) {

    ## Logging
    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    Ping Successul on 192.168.10.50... Starting Copy.")

    ## Run Secure Copy to pull backup of unify WNC configuration file.
    .\pscp.exe -v -r -i $key "prtadmin@192.168.10.50:/etc/cups/cupsd.conf" "D:\Datastore\William\_sysadmin\backups\config_backups\printserv\." | Add-Content -Path $runlog

    ## Pull a copy of .ssh folder
    .\pscp.exe -v -r -i $key "prtadmin@192.168.10.50:/home/prtadmin/.ssh/*" "D:\Datastore\William\_sysadmin\backups\config_backups\printserv\ssh\." | Add-Content -Path $runlog

}

## Failed to Connect
Else {

    Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + " Print Server @ 192.168.10.50 not found...")
}


## Compress Contents of config_backups - set a name and timestamp
## Move to 7Zip directory
Set-Location -Path "C:\Program Files\7-Zip"
$update_path = "D:\Datastore\William\_sysadmin\backups\config_backups\_archive\" + $(Get-Date -Format "yyyyMMdd").ToString() + "_configbackup" + ".7z"

Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ************************ BUILD ARCHIVE START ***********************")

.\7z.exe a -r -spf2 -mx9 $update_path "D:\Datastore\William\_sysadmin\backups\config_backups\*" -x!"D:\Datastore\William\_sysadmin\backups\config_backups\_archive" | Add-Content -Path $runlog

## End Logging
Add-Content -Path $runlog -Value ("`n.    -    Runtime Length: " + (New-TimeSpan -Start $starttime -End (Get-Date)).ToString())
Add-Content -Path $runlog -Value ("`n" + (Get-Date).ToString() + "    -    ********************************************* CONFIG BACKUP END *********************************************")
Add-Content -Path $runlog -Value ("`n.")
