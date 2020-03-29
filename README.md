# Machine injector
This project enable the use of a custom distribution or
operating system over a cloud provider like Hetzner.

In the tested environment the operating system was OpenBSD 6.6.

The same thing can be achieved by using the rescue mode in
certain cloud provider, but you'll need to use the graphical mode
to enable it.

## Prerequisites
The script assume that the target machine is an ubuntu-18.04 operating
system and will install some prequisites automatically and re-format
the disks of the machine.

## Installation of the system
Note: **EVERY DATA YOU HAVE ON THE TARGET MACHINE WILL BE LOST.**

To run the script you need the IP of the target machine and a
ssh access to it.

Then you can run the script as:
```bash
$ execute.sh 192.168.0.123 ~/.ssh/id_rsa
```
with `~/.ssh/id_rsa` as your ssh key and 192.168.0.123 as the target
machine ip address.

After that you can install the system from your vnc console (if you
have any).  Otherwise you can place an autoinstalling or pre-installed
raw image as `target.img` and the script will install it for you.

## Example
A simple example of usage is the following one:

1. Download the target image you want and rename it as "target.img", please note that
the image must be the target root filesystem, not the iso.

This command will retrieve the openbsd 66 install filesystem.
```bash
bera@walrus ~/injector $ wget -O target.img https://openbsd.mirror.garr.it/pub/OpenBSD/6.6/amd64/install66.fs
```

2. Create a ssh-key or use one you already have.
```bash
bera@walrus ~/injector $ ssh-keygen -t ed25519 -f ssh/id_cloud
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in id_cloud
Your public key has been saved in id_cloud.pub
...
```

2. Copy and paste the key contained in `id_cloud.pub` to your cloud provider
![ssh key upload hetzner](https://raw.githubusercontent.com/berdav/vm_injector/master/readme_img/hetzner_ssh_load.png)

3. Create a server selecting ubuntu-18.04 as the os image and adding the loaded ssh-key:
Wait for it to boot and get its IP address.  For example on hetzner you will see the following screen:
![Server instantiated](https://raw.githubusercontent.com/berdav/vm_injector/master/readme_img/hetzner_server.png)

4. Run the script with the IP of the server and your ssh-key.
```bash
bera@walrus ~/injector $ ./execute.sh 95.217.xx.xx id_cloud
The authenticity of host '95.217.xx.xx (95.217.xx.xx)' can't be established.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '95.217.xx.xx' (ECDSA) to the list of known hosts.
vagrant@95.217.xx.xx: Permission denied (publickey,password).
Seems that this is the first run, nuking the system.
inject.sh                               100% 1416    22.2KB/s   00:00    
target.img                              100%  450MB  10.4MB/s   00:43    

...
Get:92 http://archive.ubuntu.com/ubuntu bionic-backports/universe Translation-en [1,900 B]
Fetched 65.5 MB in 13s (4,956 kB/s)
...
Processing triggers for systemd (237-3ubuntu10.39) ...
In 5 minute connect to the machine
```

5. Give some time to the disk writer and then install the system
(if it is not autoinstallable) using the console of your cloud provider.

![Openbsd Installation screen](https://raw.githubusercontent.com/berdav/vm_injector/master/readme_img/openbsd_install.png)

6. Reset the ssh key for your server and enjoy it!
```bash
bera@walrus ~/injector $ ssh-keygen -R 95.xx.xx.xx
```
