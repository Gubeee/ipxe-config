#!/bin/bash

# ------ Global Variables ------ 
# Paths
path=""
path_tftp=""
path_smb=""
path_apache=""
path_nfs=""

# User Specified
smb_name=""
smb_username=""
smb_passwd=""

# Misc
srv="" # PXE Server IP Address
package_down_status=0 # Checking if packages have been downloaded or not

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34;47m'

RED_BOLD='\033[1;31m'
GREEN_BOLD='\033[1;32m'
CYAN_BOLD='\033[1;36m'
BLUE_BOLD='\033[1;34;47m'

RED_UNDER='\033[4;31m'
GREEN_UNDER='\033[4;32m'
CYAN_UNDER='\033[4;36m'
BLUE_UNDER='\033[4;34;47m'

NC='\033[0m'

# ------ Functions ------ 
# Main Menu Print Function
function intro(){
    clear
    echo -e "${BLUE}---------- PXE Configuration Script ----------${NC}"
    echo "1. Configure PXE"
    echo "2. ReadMe"
    echo "E. Exit Scritp"

    read -p "Choose what you want to do: " choise

    if [ $choise == "1" ]
    then
        config_start
    elif [ $choise == "2" ]
    then
        readme_file
    elif [ $choise == "E" ] || [ $choise == "e" ]
    then
        echo ""
        echo "Quitting script..."
        exit
    else
        echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
        sleep 3
        intro
    fi
}

# If user pressed 1 as a option in the first function this function is printing new menu with all functions needed to be setup for PXE work.
function config_start(){
    clear
    echo -e "${BLUE}---------- Configure PXE ----------${NC}"
    echo "1. Full Install"
    echo "S. Starting Services"
    echo "D. Downloading Packages"
    echo "E. Exit"
    
    read -p "Select one option: " choise

    # Case for choose which option is chosen by user
    case $choise in 
        1) full_install ;; # Starting full installation process *Recommended*
        D|d) pack_down ;; # Downloading packages
        S|s) service_start ;; # Starting Services 
        E|e) exit_fn ;; # Exiting Script
        *) invalid_param_config_start ;; #Invalid Parameter Function
    esac
}

# Setting up PXE Server from scratch
function full_install(){
    clear
    pack_down
    root_folder
    file_tree
    dhcp_config
    tftp_config
    samba_config
    apache_config
    nfs_config
    ipxe_config
    os_down
    service_start
    misc_options
}

# Creating root folder for PXE files
function root_folder(){
    clear

    echo -en "${CYAN}Default path for storing all of PXE files is /pxe-boot. Do you want to change it? (Y/N):${NC} "
    read choise
    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
    then
        read -p "Please select path for PXE files: " usr_path
        path=$usr_path
    elif [ $choise == "N" ] || [ $choise == "n" ] || [[ -z $choise ]]
        then
            path="/pxe-boot"
    else
        echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
        sleep 3
        file_tree
    fi
    echo -e "${GREEN}Setting ${path} as a default path for all servers. Please wait...${NC}"
    path_tftp=$path
    path_apache=$path
    path_smb=$path
    path_nfs=$path
    echo -e "${CYAN}Selected path: ${path}${NC}"
    echo -en "${GREEN}Press ENTER to continue...${NC}"
    read -n 1 -r -s
}

# Creating files tree
function file_tree(){
    clear 
    echo -e "${CYAN}Creating files tree. Please wait...${NC}"
    mkdir $path
    mkdir $path/Installers
    mkdir $path/Installers/Windows
    mkdir $path/Installers/Windows/Win10
    mkdir $path/Installers/Windows/Win11
    mkdir $path/Installers/Linux
    mkdir $path/nfs
    mkdir $path/ipxe-files
    mkdir $path/Other
    mkdir $path/Other/ipxe
    echo -en "${GREEN}Tree succesfully created. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}

# DHCP Configuration
function dhcp_config(){
    clear
    echo -e "${CYAN}Checking if DHCP config files exists. Please wait...${NC}"
    if [ ! -e /etc/dhcpd.conf ]
    then
        echo -e "${RED_BOLD}Can not configure DHCP server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        next=""
        gate=""
        mask=""
        srv=""
        dns=""
        # If content of 'net' is empty then loop is working until 'net' have an content inside
        while [ -z "$net" ] 
        do
            read -p "Enter a network address: " net
            if [[ $net =~ ^([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.([01]?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.0$ ]]
            then
                echo "Dummy Echo" > /dev/null 
            else
                echo -e "${RED_BOLD}Invalid IP.${NC}"
                net=""
            fi
        done
        # If content of 'gate' is empty then loop is working until 'gate' have an content inside
        while [ -z "$gate" ]
        do
            read -p "Enter a gateway address: " gate
            if [[ $gate =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
            then
                echo "Dummy Echo" > /dev/null 
            else
                echo -e "${RED_BOLD}Invalid address.${NC}"
                gate=""
            fi
        done
        # If content of 'mask' is empty then loop is working until 'mask' have an content inside
        while [ -z "$mask" ]
        do
            read -p "Enter a network mask: " mask
            if [[ $mask =~ ^(255\.){3}(255|254|252|248|240|224|192|128|0)$|^255\.(255|254|252|248|240|224|192|128|0)\.0\.0$|^255\.255\.(255|254|252|248|240|224|192|128|0)\.0$|^255\.255\.255\.(255|254|252|248|240|224|192|128|0)$ ]]
            then
                echo "Dummy Echo" > /dev/null
            else
                echo -e "${RED_BOLD}Invalid network mask!.${NC}"
                mask=""
            fi
        done
        # If content of 'srv' is empty then loop is working until 'srv' have an content inside
        while [ -z "$srv" ]
        do
            read -p "Enter a server address: " srv
            if [[ $srv =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
            then
                echo "Dummy Echo" > /dev/null 
            else
                echo -e "${RED_BOLD}Invalid address.${NC}"
                srv=""
            fi
        done
        while [ -z "$range" ]
        do
            read -p "Enter range of DHCP addresses (ie. 192.168.50.3 192.168.50.254): " range
            if [[ $range =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])[[:space:]]+(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
            then
                echo "Dummy Echo" > /dev/null
            else
                echo -e "${RED_BOLD}Invalid range.${NC}"
                range=""
            fi
        done
        # DNS Question
        echo -en "${CYAN}By default DNS server is 8.8.8.8. Do you want to change DNS server IP? (Y/N):${NC} "
        read choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            read -p "Enter DNS address: " usr_dns
            if [[ $usr_dns =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]]
            then
                dns=$usr_dns
            else
                echo -e "${RED_BOLD}Invalid address.${NC}"
                dns=""
            fi
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            dns="8.8.8.8"
        else
            echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
        fi 
        # 'next-server' IP address = server address
        next=$srv
        # Looking for ethernet adapter which have the same IP address as DHCP server
        for iface in $(ip -br -4 addr sh | awk '$3 != "127.0.0.1/8" {print $1}')
        do
            iface_ip=$(ip -br -4 addr sh | awk '$3 != "127.0.0.1/8" {print $3}')
            if [[ "$iface_ip" == "$srv/24" ]]
            then
                yast dhcp-server interface select=$iface > /dev/null # Selecting ethernet adapter with the same IP and setting it as a DHCP default adapter
            fi
        done
        echo -e "${CYAN}Writing informations to config file. Please wait...${NC}"
        echo "option client-arch code 93 = unsigned integer 16;" > /etc/dhcpd.conf
        echo "allow booting;" >> /etc/dhcpd.conf
        echo "allow bootp;" >> /etc/dhcpd.conf
        echo "" >> /etc/dhcpd.conf
        echo "subnet ${net} netmask ${mask} {" >> /etc/dhcpd.conf
        echo "  range ${range};" >> /etc/dhcpd.conf
        echo "  option routers ${gate};" >> /etc/dhcpd.conf
        echo "  option subnet-mask ${mask};" >> /etc/dhcpd.conf
        echo "  option domain-name-servers ${dns};" >> /etc/dhcpd.conf
        echo "  default-lease-time 600;" >> /etc/dhcpd.conf
        echo "  max-lease-time 7200;" >> /etc/dhcpd.conf
        echo "  next-server ${next};" >> /etc/dhcpd.conf
        echo "  if option client-arch != 00:00 {" >> /etc/dhcpd.conf
        echo '    filename "ipxe.efi";' >> /etc/dhcpd.conf
        echo "  } else { " >> /etc/dhcpd.conf
        echo '    filename "undionly.kpxe";' >> /etc/dhcpd.conf
        echo "  }" >> /etc/dhcpd.conf
        echo "}" >> /etc/dhcpd.conf
        echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
        read -n 1 -r -s
    fi
}

# TFTP Configuration
function tftp_config(){
    clear
    echo -e "${CYAN}Checking if TFTP config file is present...${NC}"
    if [ ! -e /etc/sysconfig/tftp ]
    then
        echo -e "${RED_BOLD}Can not configure TFTP server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo -e "${CYAN}File exists. Writing information to config file...${WHTIE}"
        echo "TFTP_USER='tftp'" > /etc/sysconfig/tftp
		echo "TFTP_OPTIONS='--secure'" >> /etc/sysconfig/tftp
		echo "TFTP_DIRECTORY='${path_tftp}'" >> /etc/sysconfig/tftp
		echo "TFTP_ADDRESS='0.0.0.0:69'" >> /etc/sysconfig/tftp
        echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
        read -n 1 -r -s
    fi
}

# Samba Configuration
function samba_config(){
    clear
    smb_proc=0
    echo -e "${CYAN}Checking if Samba config file is present...${NC}"
    if [ ! -e /etc/samba/smb.conf ]
    then
        echo -e "${RED_BOLD}Can not configure Samba server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo -en "${CYAN}Default share name is 'pxe-files'. Would you like to change it? (Y/N):${NC} "
        read choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            echo ""
            read -p "Enter share name: " usr_smb_name
            smb_name=$user_smb_name
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            smb_name="pxe-files"
        else
            echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
            sleep 3
            smb_conf
        fi
        echo -e "${CYAN}Writing informations to config file...${NC}"

        echo "[${smb_name}]" > /etc/samba/smb.conf
        echo "  comment = Samba on PXE Server" >> /etc/samba/smb.conf
        echo "  path = ${path_smb}" >> /etc/samba/smb.conf
        echo "  read only = no" >> /etc/samba/smb.conf
        echo "  browseable = yes" >> /etc/samba/smb.conf
        echo "  writeable = yes" >> /etc/samba/smb.conf

        echo -en "${CYAN}If you want samba to work properly, you have to create an user${NC}"
        echo ""
        echo -en "Enter username: "
        read smb_username

        while [ $smb_proc != 1 ]
        do    
            smbpasswd -a $smb_username
            if [ $? -ne 0 ]
            then
                echo -e "${RED_BOLD}'smbpasswd' returned erorr. Please try again...${NC}"
                smb_proc=0
            else
                echo -en "${CYAN}Please, enter the same password. It'll be used in Windows Automation Script:${NC} "
                read smb_passwd
                smb_proc=1
            fi
        done
        
        echo -en "${GREEN}User created. Press ENTER to continue...${NC}"
        read -n 1 -r -s
    fi
}

# Apache Configuration
function apache_config(){
    clear
    echo -e "${CYAN}Checking if Apache config file is present...${NC}"
    if [ ! -d /etc/apache2/vhosts.d ]
    then
        echo -e "${RED_BOLD}Can not configure Apache because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        touch /etc/apache2/vhosts.d/pxe.conf
        if [ ! -e /etc/apache2/vhosts.d/pxe.conf ]
        then
            echo -e "${RED_BOLD}Can not make Apache '.conf' file. Please re-run script and make sure that all packages were successfully downloaded.${NC}"    
            echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
            read -n 1 -r -s
            exit
        else
            read -p "Enter your Server Admin Email Address: " srv_adm_addr
            echo "<VirtualHost *:80>" > /etc/apache2/vhosts.d/pxe.conf
            echo "  ServerAdmin ${srv_adm_addr}" >> /etc/apache2/vhosts.d/pxe.conf
            echo "  DocumentRoot ${path_apache}" >> /etc/apache2/vhosts.d/pxe.conf
            echo "</VirtualHost>" >> /etc/apache2/vhosts.d/pxe.conf
        fi
    fi
    if [ ! -e /etc/apache2/httpd.conf ]
    then
        echo -e "${RED_BOLD}'httpd.conf' is not present.Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo "<Directory />" >> /etc/apache2/httpd.conf
        echo "  Options +FollowSymLinks +Indexes" >> /etc/apache2/httpd.conf
        echo "  Require all granted" >> /etc/apache2/httpd.conf
        echo "</Directory>" >> /etc/apache2/httpd.conf
    fi   

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}

# NFS Configuration
function nfs_config(){
    clear
    echo -e "${CYAN}Checking if NFS config file is present...${NC}"
    if [ ! -e /etc/exports ]
    then
        echo -e "${RED_BOLD}Can not configure NFS server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo -e "${CYAN}Writing informations to config file..."
        echo "$path/nfs *(rw,sync,no_subtree_check)" > /etc/exports
        exportfs -a
        echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
        read -n 1 -r -s
    fi
}

# Download and configure iPXE
function ipxe_config(){
    clear
    echo -e "${CYAN}Checking if expected path is present...${NC}"
    if [ ! -d $path/Other ] && [ ! -d $path/Other/ipxe ]
    then
        echo -e "${RED_BOLD}Can not download and configure iPXE because of missing catalogs. Please re-run script and make sure that all packages were successfully downloaded."
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo -e "${CYAN}Clonning github repo. Please wait...${NC}"
        git clone https://github.com/ipxe/ipxe.git $path/Other/ipxe
        echo ""
        # If script is not in expected path then it's changing directory 
        if [ $(pwd) != $path/Other ]
        then
            cd $path/Other
            # If there is not 'wimboot' file in expected directory then script is downloading it
            if [ ! -e $path/Other/wimboot ]
            then
                echo -e "${CYAN}Downloading wimboot bootloader...${NC}"
                wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot
            fi
        fi
        
        echo -e "${CYAN}Creating 'embed.ipxe' file...${NC}"
        touch $path/Other/ipxe/src/embed.ipxe

        echo -en "${CYAN}Would you like to add background image to iPXE bootloader? (Y/N):${NC} "
        read choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            # Writing information to '.h' libraries for background image support
            echo "#define CONSOLE_FRAMEBUFFER" > $path/Other/ipxe/src/config/console.h
            echo "#define IMAGE_PNG" > $path/Other/ipxe/src/config/general.h
            echo "#define CONSOLE_CMD" > $path/Other/ipxe/src/config/general.h
            cp /home/$USER/PXE-DATA/bg.png $path/Other
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            echo -e "${CYAN}Skipping...${NC}"
        else
            echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
            sleep 3
            ipxe_config
        fi

        # Writing informations to '.h' library for NFS download support
        echo "#define DOWNLOAD_PROTO_NFS" >> $path/Other/ipxe/src/config/local/general.h

        # Writing information to 'embed.ipxe' file
        if [ ! -e $path/Other/ipxe/src/embed.ipxe ]
        then
            echo -e "${RED_BOLD}Can not write information to 'embed.ipxe' file because file is missing. Please re-run script and make sure that all packages were successfully downloaded."    
            echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
            read -n 1 -r -s
            exit
        else
            echo "#!ipxe" > $path/Other/ipxe/src/embed.ipxe
            echo "" >> $path/Other/ipxe/src/embed.ipxe
            echo "dhcp && goto netboot || dhcperror" >> $path/Other/ipxe/src/embed.ipxe
            echo "" >> $path/Other/ipxe/src/embed.ipxe
            echo ":dhcperror" >> $path/Other/ipxe/src/embed.ipxe
            echo "  prompt --key s --timeout 10000 DHCP Failed. Hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot" >> $path/Other/ipxe/src/embed.ipxe
            echo "" >> $path/Other/ipxe/src/embed.ipxe
            echo ":netboot" >> $path/Other/ipxe/src/embed.ipxe
            echo "  chain tftp://${srv}/ipxe-files/main.ipxe ||" >> $path/Other/ipxe/src/embed.ipxe
            echo "  prompt --key s --timeout 10000 Netboot Failed. Hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot" >> $path/Other/ipxe/src/embed.ipxe
        fi

        echo -e "${CYAN}Creating 'ipxe.efi' file. Please wait...${NC}"
        # Checking if script is in expected path, if not then it's changing directory
        if [ $(pwd) != $path/Other/ipxe/src ]
        then
            cd $path/Other/ipxe/src
            make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe 2>&1 | pv -l > $path/make.log
            mv bin-x86_64-efi/ipxe.efi $path
        else
            make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe 2>&1 | pv -l > $path/make.log
            mv bin-x86_64-efi/ipxe.efi $path
        fi

        # 'main.ipxe' file questions
        echo -e "${CYAN}Checking if expected path is present...${NC}"
        if [ ! -d $path/ipxe-files ]
        then
            echo -e "${RED_BOLD}Can not download and configure iPXE because of missing catalogs. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
            echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
            read -n 1 -r -s
            exit
        else
            # Creating '.ipxe' files prefered by user
            echo -en "${CYAN}Would you like to create Windows 10 config file? (Y/N):${NC} " 
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                touch $path/ipxe-files/win10.ipxe
            fi
            
            echo -en "${CYAN}Would you like to create Windows 11 config file? (Y/N):${NC} " 
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                touch $path/ipxe-files/win11.ipxe
            fi

            echo -en "${CYAN}Would you like to create CloneZilla config file? (Y/N):${NC} " 
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                touch $path/ipxe-files/clone.ipxe
            fi

            # Creating 'main.ipxe' file where bootloader menu information are 'stored'
            echo -e "${CYAN}Creating 'main.ipxe' file...${NC}"
            touch $path/ipxe-files/main.ipxe

            if [ ! -e $path/ipxe-files/main.ipxe ]
            then
                echo -e "${RED_BOLD}Can not write information to 'main.ipxe' file because it's missing. Please re-run script and make sure that all packages were successfully downloaded."        
                echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
                read -n 1 -r -s
                exit
            else
                echo "#!ipxe" > $path/ipxe-files/main.ipxe
                echo "" >> $path/ipxe-files/main.ipxe

                # Script is checking if 'bg.png' file is present. It depends on earlier user choise.
                if [ -e $path/Other/bg.png ]
                then
                    echo "console --x 1024 --y 768" >> $path/ipxe-files/main.ipxe
                    echo "console --picture http://${srv}/Other/bg.png" >> $path/ipxe-files/main.ipxe
                fi

                echo ":menu" >> $path/ipxe-files/main.ipxe
                echo "menu" >> $path/ipxe-files/main.ipxe
                echo "  item --gap -- -------- iPXE Boot Menu --------" >> $path/ipxe-files/main.ipxe

                # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/win10.ipxe ]
                then
                    echo "  item win10    Install Windows 10" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'win11.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/win11.ipxe ]
                then
                    echo "  item win11    Install Windows 11" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/clone.ipxe ]
                then
                    echo "  item clone    CloneZilla" >> $path/ipxe-files/main.ipxe
                fi

                echo "  item --gap -- -------- Misc --------" >> $path/ipxe-files/main.ipxe
                echo "  item shell    iPXE Shell" >> $path/ipxe-files/main.ipxe
                echo "  item sett     Network Settings" >> $path/ipxe-files/main.ipxe
                echo "" >> $path/ipxe-files/main.ipxe
                echo 'choose --default return --timeout 5000 target && goto ${target}' >> $path/ipxe-files/main.ipxe
                echo "" >> $path/ipxe-files/main.ipxe
                
                # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/win10.ipxe ]
                then
                    echo ":win10" >> $path/ipxe-files/main.ipxe
                    echo "    chain http://${srv}/ipxe-files/win10.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'win11.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/win11.ipxe ]
                then
                    echo ":win11" >> $path/ipxe-files/main.ipxe
                    echo "    chain http://${srv}/ipxe-files/win11.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
                if [ -e $path/ipxe-files/clone.ipxe ]
                then
                    echo ":clone" >> $path/ipxe-files/main.ipxe
                    echo "  chain http://${srv}/ipxe-files/clone.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                echo ":shell" >> $path/ipxe-files/main.ipxe
                echo "  shell" >> $path/ipxe-files/main.ipxe
                echo ":sett" >> $path/ipxe-files/main.ipxe
                echo "  config" >> $path/ipxe-files/main.ipxe
                echo "  goto menu" >> $path/ipxe-files/main.ipxe
            fi

            # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
            if [ -e $path/ipxe-files/win10.ipxe ]
            then
                echo "#!ipxe" > $path/ipxe-files/win10.ipxe
                echo "" >> $path/ipxe-files/win10.ipxe
                echo "kernel http://${srv}/Other/wimboot gui" >> $path/ipxe-files/win10.ipxe
                echo "" >> $path/ipxe-files/win10.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win10/winpeshl.ini    winpeshl.ini" >> $path/ipxe-files/win10.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win10/install.bat     install.bat" >> $path/ipxe-files/win10.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win10/boot/bcd        bcd" >> $path/ipxe-files/win10.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win10/boot/boot.sdi   boot.sdi" >> $path/ipxe-files/win10.ipxe
                echo "initrd http://${srv}/Other/boot.wim                           boot.wim" >> $path/ipxe-files/win10.ipxe
                echo "" >> $path/ipxe-files/win10.ipxe
                echo "boot || goto failed" >> $path/ipxe-files/win10.ipxe
            fi

            # Script is checking if 'win11.ipxe' file is present. It depends on earlier user choise.
            if [ -e $path/ipxe-files/win11.ipxe ]
            then
                echo "#!ipxe" > $path/ipxe-files/win11.ipxe
                echo "" >> $path/ipxe-files/win11.ipxe
                echo "kernel http://${srv}/Other/wimboot gui" >> $path/ipxe-files/win11.ipxe
                echo "" >> $path/ipxe-files/win11.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win11/winpeshl.ini    winpeshl.ini" >> $path/ipxe-files/win11.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win11/install.bat     install.bat" >> $path/ipxe-files/win11.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win11/boot/bcd        bcd" >> $path/ipxe-files/win11.ipxe
                echo "initrd http://${srv}/Installers/Windows/Win11/boot/boot.sdi   boot.sdi" >> $path/ipxe-files/win11.ipxe
                echo "initrd http://${srv}/Other/boot.wim                           boot.wim" >> $path/ipxe-files/win11.ipxe
                echo "" >> $path/ipxe-files/win11.ipxe
                echo "boot || goto failed" >> $path/ipxe-files/win11.ipxe
            fi

            # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
            if [ -e $path/ipxe-files/clone.ipxe ]
            then
                echo "#!ipxe" > $path/ipxe-files/clone.ipxe
                echo "" >> $path/ipxe-files/clone.ipxe
                echo "kernel http://${srv}/Installers/Linux/live/vmlinuz initrd=${path}/Installers/Linux/live/initrd.img boot=live live-config noswap nolocales edd=on nomodeset ocs_daemonon=\"ssh\" ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"--batch -g auto -e1 auto -e2 -r -j2 -p reboot restoredisk ask_user sda\" ocs_live_keymap=\"/usr/share/keymaps/i386/qwerty/us.kmap/gz\" ocs_live_batch=\"yes\" ocs_lang=\"en_US.UTF-8\" vga=788 nosplash fetch=${srv}/Installers/Linux/live/filesystem.squashfs ocs_prerun=\"mount -t nfs ${srv}:${path}/nfs /home/partimag"\" >> $path/ipxe-files/clone.ipxe
                echo "initrd http://${srv}/Installers/Linux/live/initrd.img" >> $path/ipxe-files/clone.ipxe
                echo "" >> $path/ipxe-files/clone.ipxe
                echo "boot" >> $path/ipxe-files/clone.ipxe  
            fi

            echo -e "${CYAN}Creating Windows Auto Startup Script...${NC}"
            # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
            if [ -e $path/ipxe-files/win10.ipxe ]
            then
                # Creating 'winpeshl.ini' and 'install.bat' files. Files name should not be changed otherwise scripts will not work.
                touch $path/Installers/Windows/Win10/winpeshl.ini
                touch $path/Installers/Windows/Win10/install.bat

                if [ ! -e $path/Installers/Windows/Win10/winpeshl.ini ]
                then
                    echo -e "${RED_BOLD}Can not create 'winpeshl.ini file. Please re-run script and make sure that all catalogs were sucessfully made."
                    echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
                    read -n 1 -r -s
                    exit
                else
                    echo "[LaunchApps]" > $path/Installers/Windows/Win10/winpeshl.ini
                    echo '"install.bat"' >> $path/Installers/Windows/Win10/winpeshl.ini
                fi
                if [ ! -e $path/Installers/Windows/Win10/install.bat ]
                then
                    echo -e "${RED_BOLD}Can not create 'install.bat file. Please re-run script and make sure that all catalogs were sucessfully made."            
                    echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
                    read -n 1 -r -s
                    exit
                else
                    echo "wpeinit" > $path/Installers/Windows/Win10/install.bat
                    echo "net use \\\\$srv\\$smb_name /user:${smb_username} ${smb_passwd}" >> $path/Installers/Windows/Win10/install.bat
                    echo "\\\\$srv\\$smb_name\Installers\Windows\Win10\setup.exe" >> $path/Installers/Windows/Win10/install.bat
                fi
            fi

            if [ -e $path/ipxe-files/win11.ipxe ]
            then
                # Creating 'winpeshl.ini' and 'install.bat' files. Files name should not be changed otherwise scripts will not work.
                touch $path/Installers/Windows/Win11/winpeshl.ini
                touch $path/Installers/Windows/Win11/install.bat

                if [ ! -e $path/Installers/Windows/Win11/winpeshl.ini ]
                then
                    echo -e "${RED_BOLD}Can not create 'winpeshl.ini file. Please re-run script and make sure that all catalogs were sucessfully made."
                    echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
                    read -n 1 -r -s
                    exit
                else
                    echo "[LaunchApps]" > $path/Installers/Windows/Win11/winpeshl.ini
                    echo '"install.bat"' >> $path/Installers/Windows/Win11/winpeshl.ini
                fi
                if [ ! -e $path/Installers/Windows/Win11/install.bat ]
                then
                    echo -e "${RED_BOLD}Can not create 'install.bat file. Please re-run script and make sure that all catalogs were sucessfully made."            
                    echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
                    read -n 1 -r -s
                    exit
                else
                    echo "wpeinit" > $path/Installers/Windows/Win11/install.bat
                    echo "net use \\\\$srv\\$smb_name /user:${smb_username} ${smb_passwd}" >> $path/Installers/Windows/Win11/install.bat
                    echo "\\\\$srv\\$smb_name\Installers\Windows\Win11\setup.exe" >> $path/Installers/Windows/Win11/install.bat
                fi
            fi

            # Copying 'boot.wim' file to PXE root folder
            echo -e "${CYAN}Copying 'boot.wim' file to root folder...${NC}"
            rsync -a --info=progress2 /home/$USER/PXE-DATA/boot.wim $path/Other/boot.wim

            
            echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
            read -n 1 -r -s
            echo ""
        fi
    fi
}

# Copying and downloading OS
function os_down(){
    clear
    # Script is checking if 'win10.ipxe' file, 'win11.ipxe' file and 'clone.ipxe' file are present. If not .iso files will not be downloaded/copied.

    if [ -e $path/ipxe-files/win10.ipxe ]
    then
        echo -e "${CYAN}Copying Windows 10 installation files...${NC}"
        rsync -a --info=progress2 /home/$USER/PXE-DATA/Win10/* $path/Installers/Windows/Win10
    fi

    if [ -e $path/ipxe-files/win11.ipxe ]
    then
        echo -e "${CYAN}Copying Windows 11 installation files...${NC}"
        rsync -a --info=progress2 -R /home/$USER/PXE-DATA/Win11/* $path/Installers/Windows/Win11
    fi

    if [ -e $path/ipxe-files/clone.ipxe ]
    then
        echo -e "${CYAN}Downloading CloneZilla .iso file...${NC}"
        curl 'https://deac-riga.dl.sourceforge.net/project/clonezilla/clonezilla_live_stable/3.1.2-22/clonezilla-live-3.1.2-22-amd64.iso?viasf=1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://sourceforge.net/' -H 'Connection: keep-alive' -H 'Cookie: __cmpconsentx11319=CP9nwjAP9nwjAAfUnBENAxEsAP_AAEPAACiQGgwEAAGgAVABAAC0AGgATAAoABfADCAHgAQQAowCEALzAZeA0EDQYCAADQAKgAgABaADQAJgAUAAvgBhADwAIIAUYBCAF5gMvAaCAAA; __cmpcvcx11319=__c37910_s135_c48392_s30_U__; __cmpcpcx11319=____; __gads=ID=51ca8e34ae5905c0:T=1714043840:RT=1714043840:S=ALNI_MZYJCQfXewTvz1OnvD_MDkzB_h-SA; __gpi=UID=00000dfe1d0b78b9:T=1714043840:RT=1714043840:S=ALNI_MZ-vKxNSTOZQlHMunc0b57EHUI9gQ; __eoi=ID=ac4bf2da1cea6aae:T=1714043840:RT=1714043840:S=AA-AfjYlMlSvxwex91lUf6RofYJP' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-site' -o $path/clone.iso
        echo "Mounting .iso file..."
        mount $path/clone.iso /mnt
        echo -e "${CYAN}Copying files...${NC}"
        rsync -a --info=progress2 /mnt/* $path/Installers/Linux
        umount /mnt
        rm -R $path/clone.iso
    fi
        
    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
    echo ""
}

# Downloading reqiured packages for PXE work
function pack_down(){
    clear
    echo -e "${CYAN_BOLD}Refresing and updating zypper...${NC}"
    zypper ref
    zypper up -y
    clear
    echo -e "${CYAN_BOLD}Downloading packages required for iPXE...${NC}"
    zypper in -y make gcc binutils perl mtools mkisofs syslinux liblzma5
    clear
    echo -e "${CYAN_BOLD}Downloading services required for PXE Server...${NC}"
    zypper in -y yast2-dhcp-server yast2-tftp-server apache2 git yast2-nfs-server tftp dhcp-server samba yast2-samba-server nfs-kernel-server pv
    package_down_status=1
    echo -en "${GREEN}All packages downloaded. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}

# Starting required services and adding them to autostart
function service_start(){
    clear
    if [ $package_down_status == 1 ]
    then
        echo -e "${CYAN}Checking if services are working...${NC}"
        
        # Checking if DHCP service is active
        if ! systemctl --quiet is-active dhcpd.service
        then
            systemctl start dhcpd.service
            systemctl restart dhcpd.service
        fi
        
        # Checking if Apache2 service is active
        if ! systemctl --quiet is-active apache2
        then
            systemctl start apache2
        fi

        # Cheking if TFPT service is active
        if ! systemctl --quiet is-active tftp
        then
            systemctl start tftp
        fi

        # Checking if Samba service is active
        if ! systemctl --quiet is-active smb
        then
            systemctl start smb
        fi

        # Checkign if NFS services are active
        if ! systemctl --quiet is-active nfs
        then
            systemctl start nfs
        fi
        if ! systemctl --quiet is-active nfs-server
        then
            systemctl start nfs-server
        fi

        systemctl enable dhcpd
        systemctl enable apache2
        systemctl enable tftp
        systemctl enable smb
        systemctl enable nfs
        systemctl enable nfs-server

        echo "Adding firewall rules for services..."
        firewall-cmd --zone=public --permanent --add-service=apache2
        firewall-cmd --zone=public --permanent --add-service=http
        firewall-cmd --zone=public --permanent --add-service=dhcp
        firewall-cmd --zone=public --permanent --add-service=nfs
        firewall-cmd --zone=public --permanent --add-service=apache2
        firewall-cmd --zone=public --permanent --add-service=samba
        firewall-cmd --zone=public --permanent --add-service=tftp
        firewall-cmd --reload

        echo -e "${CYAN}Making $path/nfs writable for reading/saving disk images made with CloneZilla...${NC}"
        chmod -R 777 $path/nfs > dev/null
        chown -R nobody:nogroup $path/nfs > /dev/null
    else
        echo -e "${RED_BOLD}There is nothing to start, because packages haven't been downloaded yet. Try 'Downloading Packages' option in menu and then try again or select 'Full Install' option.${NC}"
        echo -en "${GREEN}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        config_start
    fi
}

# Misc options
function misc_options(){
    clear
    echo -e "${BLUE}------ Misc Options ------${NC}"
    echo -e "1. Open Readme file ${CYAN_UNDER}*RECOMMENDED*${NC}"
    echo "E. Exit"
    read -p "Select option: " choise
    case $choise in
        1) readme_file ;;
        E|e) exit_fn ;;
        *) invalid_param_misc_options ;;
    esac
}

# Exiting script
function exit_fn(){
    echo ""
    echo "Quitting script..."
    exit
}

# Opening README file function
function readme_file(){
    git clone https://github.com/Gubeee/ipxe-config/README $path
    export VISUAL="/usr/bin/nano"
    $VISUAL $path/README
}

# If user choose an invalid parameter in case statement then it's reseting 'config_start' function
function invalid_param_config_start(){
    echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
    sleep 3
    config_start
}

# If user choose an invalid parameter in case statement then it's reseting 'misc_options' function
function invalid_param_misc_options(){
    echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
    sleep 3
    misc_options
}

intro