# wlab_configbackup
Personal backup script for configuration files, etc. This is ran as part of a task via Ansible playbook

# WLAB Configuration File Backup Utility
--------------------------------------------------
# Synopsis:
 * Backup Script located on WMSERVER.WLAB.LOCAL
   Ensures that Devices are available, then copies 
   relevant backup configuration files. 

--------------------------------------------------
# Documentation:                 
 * Logging
   > B:\_logs\configbackup.log

--------------------------------------------------
# Device List:                 
 * pihole Server
 * OPNsense Router
 * utility Server
 * Unifi Network Application

--------------------------------------------------
# Change Log:
 * 11/1/2022
   - Initial Setup
   - Added logging for when ping fails on either server
 * 12/3/2022
   - Added final paths
   - Added feature to zip the entire directory and store in _archive with datestime stamp
 * 12/5/2022
   - Added opnsense backup
 * 7/30/2023
   - Added PW Encryption
   - Removed parameters
   - Consolidated logging files & added better formatting for logging file
 * 10/22/2023
   - Replaced PW authentication with PKI auth. for all devices besides opnsense
   - Updated Logging

--------------------------------------------------
 # Known Issues:
 1. (Fixed) Must add auth. here for ansible user. Should have Least Priv.
 2. PiHole_Backup.yml must be ran before backing up which is done via ansible playbook.
 2.1 PiHole_Backup.yml ensures that the most update to date file is backed-up from pihole.
 3. This script assumes that you have added the PuTTY & 7Zip directories to the PATH evironment variable. Fix is coming to check then set if needed.

--------------------------------------------------
# Notes:
 * Author - W.Bansbach

--------------------------------------------------
