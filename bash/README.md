# vmware_ovf_backup.sh
The purpose of this script is to make OVA VM backups.
This is not a great way to make a VM backup but sometimes it's the only option.

The logic of this script is pretty simple:
1. Login to ESXi host, find VM and its ID and World-ID.
2. Check VM power state. If VM is powered off, then go to 4. 
3. If VM is powered on then try soft power off. If it fails try hard power off.
4. Create OVA backup.
5. Power on VM.

For this script to work you will need to configure pubkey SSH access to ESXi host. VMware article: https://kb.vmware.com/s/article/1002866
Note that SSH key should be generated WITHOUT any passphrase (just hit Enter all the time).

There are a few rough places in this script where putting lines in log file wasn't enough, so I've wrote sendMail function to notify the user if something goes wrong. In fact, every "exit 1" situation in this script is covered by sendMail function. The function itself uses "mailx" to deliver the mail so you have to make sure it's available on a host from where the script is running.

There also are some room for improvements. The biggest issue so far is that ovftool can't connect to ESXi host using SSH keys. That's why PASSWORD argument is present. In clear text. Which is obviously VERY bad. I've done some poking around and didn't find any elegant and simple solution to this problem.