#!/bin/bash

# ------ Global Variables ------ 
# Paths
path=""
path_tftp=""
path_smb=""
path_apache=""
path_nfs=""
path_sh=""

# User Specified
smb_name=""
smb_username=""
smb_passwd=""

# Booleans
img_bg="FALSE"
file_win10="FALSE"
file_win11="FALSE"
file_clone="FALSE"
file_mem="FALSE"

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

# ------ End of Global Variables ------ 

# ------ Functions ------ 
# Main Menu Print Function
function intro(){
    clear
    
    path_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Getting path to script, where SHOULD BE stored all of the data (Win10/11 Installation Files, bg.img, etc.). For more information chceck README.md and look on file tree img.

    echo -e "${BLUE}---------- PXE Configuration Script ----------${NC}"
    echo "1. Configure PXE"
    echo "2. ReadMe"
    echo "E. Exit Scritp"

    read -p "Choose what you want to do: " choise

    if [ $choise == "1" ]
    then
        config_start            # Go to config_start function
    elif [ $choise == "2" ]
    then
        readme_file             # Go to readme_file function
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
        1) full_install ;;                      # Starting full installation process *Recommended*
        D|d) pack_down ;;                       # Downloading packages
        S|s) service_start ;;                   # Starting Services 
        E|e) exit_fn ;;                         # Exiting Script
        *) invalid_param_config_start ;;        #Invalid Parameter Function
    esac
}

# Setting up PXE Server from scratch
function full_install(){
    clear

    pack_down       # Go to pack_down function
    root_folder     # Go to root_folder function
    file_tree       # Go to file_tree function
    dhcp_config     # Go to dhcp_config function
    tftp_config     # Go to tftp_config function
    samba_config    # Go to samba_config function
    apache_config   # Go to apache_config function
    nfs_config      # Go to nfs_config function
    ipxe_config     # Go to ipxe_config function
    os_down         # Go to os_down function
    service_start   # Go to service_start function
    misc_options    # Go to misc_options function
}

# Creating root folder for PXE files
function root_folder(){
    clear

    echo -en "${CYAN}Default path for storing all of PXE files is /pxe-boot. Do you want to change it? (Y/N):${NC} "
    read choise

    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
    then
        read -p "Please select path for PXE files: " -i "/" -e usr_path
        path=$usr_path          # Setting usr_path as root directory of PXE server files
    elif [ $choise == "N" ] || [ $choise == "n" ] || [[ -z $choise ]]
        then
            path="/pxe-boot"    # Setting default path as root directory of PXE server files 
    else
        echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
        sleep 3
        file_tree
    fi
    echo -e "${GREEN}Setting ${path} as a default path for all servers. Please wait...${NC}"

    path_tftp=$path         # Setting $path for TFTP server.
    path_apache=$path       # Setting $path for Apache2 server.
    path_smb=$path          # Setting $path for Samba server. 
    path_nfs=$path          # Setting $path for NFS server.
    
    echo -en "${GREEN}Press ENTER to continue...${NC}"
    read -n 1 -r -s
}

# Creating files tree
function file_tree(){
    clear 
    echo -e "${CYAN}Creating files tree. Please wait...${NC}"
    mkdir $path                                 # Creating root folder using $path variable
    mkdir $path/Installers                      # Creating 'Installers' folder - there will be stored Windows10/11 installation files, linux distros files etc.
    mkdir $path/Installers/Windows              # Creating 'Windows' subfolder for clarity :P
    mkdir $path/Installers/Windows/Win10        # Creating 'Win10' subfolder for clarity :P 
    mkdir $path/Installers/Windows/Win11        # Creating 'Win11' subfolder for clarity :P
    mkdir $path/Installers/Linux                # Creating 'Linux' subfolder for clarity :P So far there is only 'CloneZilla' config (14.05.2024)
    mkdir $path/Installers/Misc                 # Creating 'Misc' subfolder for clarity :P
    mkdir $path/Installers/Misc/MemTest         # Creating "MemTest" subfolder for clarity :P
    mkdir $path/Installers/Misc/Hirens          # Creating "Hirens" subfolder for clarity :P
    mkdir $path/nfs                             # Creating 'nfs' folder for storing cloned disk images
    mkdir $path/ipxe-files                      # Creating 'ipxe-files' folder for storing '.ipxe' files
    mkdir $path/Other                           # Creating 'Other' folder for storing files such as 'bg.png', 'boot.wim' or 'wimboot'
    mkdir $path/Other/ipxe                      # Creating 'ipxe' subfolder for storing git cloned 'ipxe' files
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

        net_cut=$(echo "$net" | cut -d'.' -f1-3)

        # If content of 'gate' is empty then loop is working until 'gate' have an content inside
        while [ -z "$gate" ]
        do
            read -e -p "Enter a gateway address: " -i "$net_cut." gate
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
            read -e -p "Enter a server address: " -i "$net_cut."  srv
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
            read -e -p "Enter range of DHCP addresses (ie. 192.168.50.3 192.168.50.254): " range
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

    smb_proc=0 # Auxiliary variable for 'while' loop
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
            read -p "Enter share name: " usr_smb_name
            smb_name=$usr_smb_name # Setting Samba share name as $usr_smb_name
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            smb_name="pxe-files" # Setting default Samba share name
        else
            echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
            sleep 3
            samba_config
        fi
        echo -e "${CYAN}Writing informations to config file...${NC}"

        echo "[${smb_name}]" > /etc/samba/smb.conf
        echo "  comment = Samba on PXE Server" >> /etc/samba/smb.conf
        echo "  path = ${path_smb}" >> /etc/samba/smb.conf
        echo "  read only = no" >> /etc/samba/smb.conf
        echo "  browseable = yes" >> /etc/samba/smb.conf
        echo "  writeable = yes" >> /etc/samba/smb.conf

        # Creating Samba user for access to Samba share - this step is required for Windows 10/11 Installation
        echo -en "${CYAN}If you want samba to work properly, you have to create an user${NC}"
        echo ""
        echo -en "Enter username: "
        read smb_username

        while [ $smb_proc != 1 ] # If $smb_proc is different than 1 that means 'smbpasswd' output is an error. 
        do    
            smbpasswd -a $smb_username
            if [ $? -ne 0 ]
            then
                echo -e "${RED_BOLD}'smbpasswd' returned erorr. Please try again...${NC}"
                smb_proc=0
            else
                echo -en "${CYAN}Please, enter the same password. It'll be used in Windows Automation Script:${NC} "
                read smb_passwd # This needed for autorun 'setup.exe' file in Windows Automation Script. If you put wrong password, Win PE will automatycally reboot!
                smb_proc=1 # If $smb_proc is 1 that means everything went well
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
            while [ -z $srv_adm_addr ]
            do
                read -p "Enter your Server Admin Email Address: " srv_adm_addr # Idk for what it's needed but I saw this in tutorial so I putted it there
            done
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
        # Writing '$path/nfs' to exports file. This will be accessible from all PC's with IP from $net network.
        echo "$path/nfs ${net}/${mask}(rw,sync,no_subtree_check)" > /etc/exports
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
        git clone https://github.com/ipxe/ipxe.git $path/Other/ipxe # Clonning iPXE files to '$path/Other/ipxe'
        echo ""

        # If script is not in expected path then it's changing directory 
        if [ $(pwd) != $path/Other ]
        then
            cd $path/Other
            # If there is not 'wimboot' file in expected directory then script is downloading it
            if [ ! -e $path/Other/wimboot ]
            then
                echo -e "${CYAN}Downloading wimboot bootloader...${NC}"
                wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot # Idk why there is 'wget' instead of 'git clone' but - one more time - I saw this in tutorial and I putted it there ;P
            fi
        fi
        
        echo -e "${CYAN}Creating 'embed.ipxe' file...${NC}"
        touch $path/Other/ipxe/src/embed.ipxe # 'embed.ipxe' file is a file required for custom build of '.efi' or/and '.kpxe' files. Without this file, you can build only stock build and later you would have to write iPXE commands

        echo -en "${CYAN}Would you like to add background image to iPXE bootloader?${NC}${RED} MAKE SURE YOU HAVE 'bg.png' FILE IN ${path_sh} PATH!${NC} (Y/N):${NC} "
        read choise

        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            # Writing information to '.h' libraries for background image support
            sed -i '3i#define CONSOLE_FRAMEBUFFER' $path/Other/ipxe/src/config/console.h
            sed -i "3i#define IMAGE_PNG" $path/Other/ipxe/src/config/general.h
            sed -i "4i#define CONSOLE_CMD" $path/Other/ipxe/src/config/general.h
            cp $path_sh/bg.png $path/Other

            img_bg="TRUE"
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            img_bg="FALSE"
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

        echo -e "${CYAN}Creating 'ipxe.efi' file and 'undionly.kpxe' file. Please wait...${NC}"
        # Checking if script is in expected path, if not then it's changing directory
        if [ $(pwd) != $path/Other/ipxe/src ]
        then
            cd $path/Other/ipxe/src
            make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe 2>&1 | pv -l > $path/make-efi.log # 'pv' command informs us that script isn't stuck
            mv bin-x86_64-efi/ipxe.efi $path
            make bin/undionly.kpxe EMBED=embed.ipxe 2>&1 | pv -l > $path/make-kpxe.log      # 'pv' command informs us that script isn't stuck
            mv bin/undionly.kpxe $path
        else
            make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe 2>&1 | pv -l > $path/make-efi.log # 'pv' command informs us that script isn't stuck
            mv bin-x86_64-efi/ipxe.efi $path
            make bin/undionly.kpxe EMBED=embed.ipxe 2>&1 | pv -l > $path/make-kpxe.log      # 'pv' command informs us that script isn't stuck
            mv bin/undionly.kpxe $path
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
                file_win10="TRUE"
                touch $path/ipxe-files/win10.ipxe
            fi
            
            echo -en "${CYAN}Would you like to create Windows 11 config file? (Y/N):${NC} " 
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                file_win11="TRUE"
                touch $path/ipxe-files/win11.ipxe
            fi

            echo -en "${CYAN}Would you like to create CloneZilla config file? (Y/N):${NC} " 
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                file_clone="TRUE"
                touch $path/ipxe-files/clone.ipxe
            fi

            echo -en "${CYAN}Would you like to create MemTest config file? (Y/N):${NC} "
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
            then
                file_mem="TRUE"
                touch $path/ipxe-files/mem.ipxe
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
                if [ $img_bg == "TRUE" ]
                then
                    echo "console --x 1024 --y 768 --picture http://${srv}/Other/bg.png" >> $path/ipxe-files/main.ipxe 
                fi

                echo ":menu" >> $path/ipxe-files/main.ipxe
                echo "menu" >> $path/ipxe-files/main.ipxe
                echo "  item --gap -- -------- iPXE Boot Menu --------" >> $path/ipxe-files/main.ipxe

                # Writing informations to 'menu' tab.
                # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
                if [ $file_win10 == "TRUE" ]
                then
                    echo "  item win10    Install Windows 10" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'win11.ipxe' file is present. It depends on earlier user choise.
                if [ $file_win11 == "TRUE" ]
                then
                    echo "  item win11    Install Windows 11" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
                if [ $file_clone == "TRUE" ]
                then
                    echo "  item clone    CloneZilla" >> $path/ipxe-files/main.ipxe
                fi

                # Miscellaneous options which you can choose in iPXE bootloader
                echo "  item --gap -- -------- Misc --------" >> $path/ipxe-files/main.ipxe
                # Script is checking if 'mem.ipxe' file is present. It depends on earlier user choise.
                if [ $file_mem == "TRUE" ]
                then
                    echo "  item mem    MemTest" >> $path/ipxe-files/main.ipxe
                fi
                echo "  item shell    iPXE Shell" >> $path/ipxe-files/main.ipxe
                echo "  item sett     Network Settings" >> $path/ipxe-files/main.ipxe
                echo "" >> $path/ipxe-files/main.ipxe
                echo 'choose --default return --timeout 5000 target && goto ${target}' >> $path/ipxe-files/main.ipxe
                echo "" >> $path/ipxe-files/main.ipxe
                
                # Writing informations to 'target' tab.
                # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
                if [ $file_win10 == "TRUE" ]
                then
                    echo ":win10" >> $path/ipxe-files/main.ipxe
                    echo "    chain http://${srv}/ipxe-files/win10.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'win11.ipxe' file is present. It depends on earlier user choise.
                if [ $file_win11 == "TRUE" ]
                then
                    echo ":win11" >> $path/ipxe-files/main.ipxe
                    echo "    chain http://${srv}/ipxe-files/win11.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
                if [ $file_clone == "TRUE" ]
                then
                    echo ":clone" >> $path/ipxe-files/main.ipxe
                    echo "  chain http://${srv}/ipxe-files/clone.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                # Script is checking if 'mem.ipxe' file is present. It depends on earlier user choise.
                if [ $file_mem == "TRUE" ]
                then
                    echo ":mem" >> $path/ipxe-files/main.ipxe
                    echo "  chain http://${srv}/ipxe-files/mem.ipxe" >> $path/ipxe-files/main.ipxe
                fi

                echo ":shell" >> $path/ipxe-files/main.ipxe
                echo "  shell" >> $path/ipxe-files/main.ipxe
                echo ":sett" >> $path/ipxe-files/main.ipxe
                echo "  config" >> $path/ipxe-files/main.ipxe
                echo "  goto menu" >> $path/ipxe-files/main.ipxe
            fi

            # Writing informations to '$path/ipxe-files/{target}.ipxe' file.
            # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
            if [ $file_win10 == "TRUE" ]
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
            if [ $file_win11 == "TRUE" ]
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
            if [ $file_clone == "TRUE" ]
            then
                echo "#!ipxe" > $path/ipxe-files/clone.ipxe
                echo "" >> $path/ipxe-files/clone.ipxe
                echo "kernel http://${srv}/Installers/Linux/live/vmlinuz initrd=${path}/Installers/Linux/live/initrd.img boot=live live-config noswap nolocales edd=on nomodeset ocs_daemonon=\"ssh\" ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"--batch -g auto -e1 auto -e2 -r -j2 -p reboot restoredisk ask_user sda\" ocs_live_keymap=\"/usr/share/keymaps/i386/qwerty/us.kmap/gz\" ocs_live_batch=\"yes\" ocs_lang=\"en_US.UTF-8\" vga=788 nosplash fetch=${srv}/Installers/Linux/live/filesystem.squashfs ocs_prerun=\"mount -t nfs ${srv}:${path}/nfs /home/partimag"\" >> $path/ipxe-files/clone.ipxe
                echo "initrd http://${srv}/Installers/Linux/live/initrd.img" >> $path/ipxe-files/clone.ipxe
                echo "" >> $path/ipxe-files/clone.ipxe
                echo "boot" >> $path/ipxe-files/clone.ipxe  
            fi

            # Script is checking if 'mem.ipxe' file is present. It depends on earlier user choise.
            if [ $file_mem == "TRUE" ]
            then
                echo "#!ipxe" > $path/ipxe-files/mem.ipxe
                echo "" >> $path/ipxe-files/mem.ipxe
                echo "kernel http://${srv}/Installers/Misc/MemTest/memdisk || read void" >> $path/ipxe-files/mem.ipxe
                echo "initrd http://${srv}/Installers/Misc/MemTest/memtest.iso || read void" >> $path/ipxe-files/mem.ipxe
                echo "imgargs memdisk iso raw || read void" >> $path/ipxe-files/mem.ipxe
                echo "" >> $path/ipxe-files/mem.ipxe
                echo "boot || read void" >> $path/ipxe-files/mem.ipxe
            fi

            echo -e "${CYAN}Creating Windows Auto Startup Script...${NC}"
            # Script is checking if 'win10.ipxe' file is present. It depends on earlier user choise.
            if [ $file_win10 == "TRUE" ]
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

            if [ $file_win11 == "TRUE" ]
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
            rsync -a --info=progress2 $path_sh/boot.wim $path/Other/boot.wim

            
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
    if [ $file_win10 == "TRUE" ]
    then
        echo -e "${CYAN}Copying Windows 10 installation files...${NC}"
        rsync -a --info=progress2 $path_sh/Win10/* $path/Installers/Windows/Win10
    fi

    if [ $file_win11 == "TRUE" ]
    then
        echo -e "${CYAN}Copying Windows 11 installation files...${NC}"
        rsync -a --info=progress2 -R $path_sh/Win11/* $path/Installers/Windows/Win11
    fi

    # Downloading, mounting, copying and removing 'clone.iso' file.
    if [ $file_clone == "TRUE" ]
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

    if [ $file_mem == "TRUE" ]
    then
        cp /usr/share/syslinux/memdisk $path/Installers/Misc/MemTest
        curl 'https://memtest.org/download/v7.00/mt86plus_7.00_64.iso.zip' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'Accept-Language: pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7' \
        -H 'Connection: keep-alive' \
        -H 'Sec-Fetch-Dest: document' \
        -H 'Sec-Fetch-Mode: navigate' \
        -H 'Sec-Fetch-Site: none' \
        -H 'Sec-Fetch-User: ?1' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36' \
        -H 'sec-ch-ua: "Chromium";v="124", "Google Chrome";v="124", "Not-A.Brand";v="99"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' -o $path/Installers/Misc/MemTest/memtest.iso
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
    zypper in -y make gcc binutils perl mtools mkisofs syslinux liblzma5 xz-devel
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

        # Adding services to 'autostart'.
        systemctl enable dhcpd
        systemctl enable apache2
        systemctl enable tftp
        systemctl enable smb
        systemctl enable nfs
        systemctl enable nfs-server

        echo "${CYAN}Adding firewall rules for services...${NC}"
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
    if [ -e $path_sh/README.md ]
    then
        export VISUAL="/usr/bin/nano"
        $VISUAL $path/README
    else
        echo "${RED} File 'README.md' doesn't exists!${NC}"
    fi
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

if [ $EUID -ne 0 ]
then
    echo "Script should be run as su. Try login to su account or run script with sudo."
    sleep 3
    exit
else
    intro
fi
