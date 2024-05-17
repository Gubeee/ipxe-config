# OVERVIEW
### All required packages
1. iPXE
	- make
	- gcc
	- binutils
	- perl
	- mtools
	- mkisofs
	- syslinux
	- liblzma5
	- xz-devel
2. Other Packages
	- yast2-dhcp-server 
	- yast2-tftp-server 
	- apache2 
	- git 
	- yast2-nfs-server 
	- tftp
 	- dhcp-server 
	- samba 
	- yast2-samba-server 
	- nfs-kernel-server 
	- pv

# About
> [!NOTE]
> All tests have been performed on virtual machines!  
> Software used: Oracle Virtual Box 7.0.14 r161095 (Qt5.15.2), libvirt  
> OS: openSUSE Leap (nogui just server 'edition'), Windows 10    

> [!IMPORTANT]
> The script should be run as `su` or with the `sudo` command!


First I want to mention that **I'M NOT** a professional bash scripts writer 😝 So if you find something wrong in the script, just let me know; should you know a solution for that I would be grateful if you share it the solution with me.

Now I want to say thank you to:
- [rpi4cluster Owner](https://rpi4cluster.com/) - So far the best site about iPXE configuration for Windows Support (but I'm kinda sad there is no Linux documentation 😆)
- [Guys from openSUSE Forum](https://forums.opensuse.org/) - Now I can't remeber anymore what I was looking for but I'm sure I've found something necessary there
- [Microsoft](https://www.microsoft.com) - for Windows 10, Windows 11 and Windows PE (but please do something about your documentation and `copype.cmd` script...)
- [CloneZilla Owner](https://clonezilla.org/) - for the best cloning cloning software!
- [iPXE Owner](ipxe.org) - for the best PXE firmware!

# LICENSE
I don't know what license I should choose so I'll say this - feel free to use this script, make changes or whatever you want but make sure you don't break the license rules of the corporations/people above.

If you appreciate my work [you can buy me a coffee](https://help.buymeacoffee.com/en/)

# WORTH KNOWING
If you want to configure the **SAMBA SERVER** while using a different Linux Account than the one already created you have to make new a LINUX ACCOUNT, e.g.:

Your default account is `pxe-admin`. So when you create samba server, you **HAVE TO** put `pxe-admin` as username, because it's stored in the variable `$smb_username`. So looks like this:

1. You insert a username which is already created
2. The Script uses `smbpasswd $smb_username -a` command
3. Then it asks for a password for samba share
4. If the password is wrong or there is no account with `$smb_username` name, the srcipt return an error and you have to re-run the script

And now we are getting to my favourite section:

---------- Windows Lack of Technology 🤣 ----------

Because of Microsoft's brilliant technological thought I didn't find a good way to download the latest .iso files of both Windows 10 and 11. For now you HAVE TO download them manually and put successively in:

	Windows 10 installation files - /home/$USER/PXE-DATA/Win10
	Windows 11 installation files - /home/$USER/PXE-DATA/Win11

Same thing with the 'boot.wim' file - it SHOULD BE in the /home/$USER/PXE-DATA/ folder. But what is 'boot.wim' file exactly is? 
A 'boot.wim' file is a kind of universal Windows bootloader. You can use it with Windows 10 and Windows 11, and it is loaded by ipxe's 'wimboot' file. 'wimboot' is loading 'boot.wim' and then Windows Preinstalation Enviroment is loaded.

To get the 'boot.wim' file you have to follow [Microsoft's Official Documentation](https://learn.microsoft.com/pl-pl/windows-hardware/manufacture/desktop/download-winpe--windows-pe?view=windows-11) and - one more time - due to Microsoft's brilliant technological thought, you have to [edit one scritp](https://777notes.wordpress.com/2013/10/21/winpe-the-following-processor-architecture-was-not-found-amd64/).

If you have any problems with the script or the other things that are needed to make the script work feel free to contact me via email: gubisiowy@gmail.com.

The PXE-DATA tree should look the same as below:

![PXE-DATA TREE](image-1.png)
```
PXE-DATA
|
--- bg.png
|
--- boot.wim
|
--- Win10
|   |
|   --- Windows 10 installation files
|
--- Win11
|   |
|   --- Windows 11 installation files
```
If there are not Windows 10 or 11 installation files, the script will not work unless I'll find a good way to download .iso from Official Servers. Then the whole script will be changed.

If you want to change a background image simply put the image into `/home/$USER/PXE-DATA` or into `$path/Other/bg.png`. Note that you have to enable this option in the script and your background image name **SHOULD BE** `bg.png` and it has to be 1024x768px!

And one more thing - if you made a mistake while writing something e.g. while typing in IP addresses, it's recommended to re-run the script. Since later those IP addresses are present in '.efi' as well as '.kpxe', DHCP and NFS files so it'll be easier to write it one more time than to correct and generate all files "by hand".

I think that's all. One more time - if you have any questions - feel free to ask. My email address: gubisiowy@gmail.com.

Have a good day and I wish you a lot of Windows installations and disks clones haha.

# KNOWN ISSUES
So far so good.

# TO DO
- Find a way to download the latest `.iso` files of Windows 10 and 11 and other OSes/softwares
- Add GUI
- Add more options to PXE such as Hirens, MEMTEST and similar [IN PROGRESS]
- Make the script prettier
- Migration to Kea DHCP
- Better DHCP configuration function [IN PROGRESS]
- git clone only the README file or check if in same path as `.sh` there is `.md` file or smth [IN PROGRESS]
- Checking if samba username is present in system - if not then script will ask for creating new account
- And things I have no idea about (for now) 😝
- ~~Find a way to generate `.kpxe` file~~ [DONE]
- ~~Add [TRUE/FALSE] variables instead of checking if the file exists~~ [DONE]

# OLDER ISSUES
~~As you could see in the [Overview](#overview) there is one package missing in openSUSE - `isolinux`. What does it mean? You won't be able to generate `undionly.kpxe` file which is required to run iPXE on BIOS systems. If you want to do that, you have to use (rpi4cluster)[https://rpi4cluster.com/ipxe/] guide using Ubuntu (I know that package exists there) and then copy that file. Maybe in the future I'll find a way to make that file but now I don't have time and knowledge how to do this.~~
- ~~The custom Samba share name doensn't work~~
- ~~iPXE can't load due to a background image - so if you don't need a background image skip this step~~
- ~~Generating Windows `.ipxe` file is broken (idk why, it was working earlier 🤔)~~
