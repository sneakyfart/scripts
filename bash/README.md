# vmware_ovf_backup.sh
The purpose of this script is to make OVA VM backups.
This is not a great way to make a VM backup but sometimes it's the only option.

The logic of this script is pretty simple:
1. Login to ESXi host, find VM and its ID and World-ID.
2. Check VM power state. If VM is powered off, then go to 4. 
3. If VM is powered on then try soft power off. If it fails try hard power off.
4. Create OVA backup.
5. Power on VM.

There are a few rough places in this script where putting lines in log file wasn't enough.
So I've wrote sendMail function to notify the user if something goes wrong. The function itself uses "mailx" to deliver the mail so you have to make sure it's available on a host from where the script is running.