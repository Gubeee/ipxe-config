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
bools=("background:FALSE" "Windows10:FALSE" "Windows11:FALSE" "CloneZilla:FALSE" "MemTest:FALSE")

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
function check(){
    path_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Getting path to script, where SHOULD BE stored all of the data (Win10/11 Installation Files, bg.img, etc.). For more information chceck README.md and look on file tree img.

    if [ ! -e '${path_sh}/boot.wim' ] || [ ! -d '${path_sh}/Win10' ] || [ ! -d '${path_sh}/Win11' ]
    then
        echo -e "${RED}Some files are missing! Would You like to continue? (Y/N): ${NC}"
        read choise

        if [ $choise == 'Y' ] || [ $choise == 'y' ] || [ $choise == 'T' ] || [ $choise == 't' ] || [ -z $choise ]
        then
            intro
        else
            exit
        fi
    fi
}


# ------ Main Menu Print Function ------
function intro(){
    clear

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
# ------ End of Main Menu Print Function ------

# ------ Configuration Start Function ------
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
# ------ End of Configuration Start Function ------

# ------ Full Installation Function ------
# Setting up PXE Server from scratch
function full_install(){
    clear
    # ------------------------------------------------
    pack_down       # Go to pack_down function
    pxe_tree        # Go to pxe_tree function
    # ------------------------------------------------
    conf_dhcp       # Go to dhcp_config function
    conf_tftp       # Go to tftp_config function
    conf_smb        # Go to samba_config function
    conf_apache     # Go to apache_config function
    conf_nfs        # Go to nfs_config function
    # ------------------------------------------------
    ipxe_config     # Go to ipxe_config function
    # ------------------------------------------------
    os_down         # Go to os_down function
    # ------------------------------------------------
    service_start   # Go to service_start function
    misc_options    # Go to misc_options function
}
# ------ End of Full Installation Function ------

# ------ Root Folder Function ------
# Creating PXE dir tree
function pxe_tree(){
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

    mkdir $path
    mkdir $path/Installers
    mkdir $path/ipxe-files
    mkdir -p $path/Other/ipxe

    clear
    for index in "${!bools[@]}" # For loop is going through all elements in bools array
    do
        IFS=':' read -ra parts <<< "${bools[$index]}" # This command is splitting values of bools array by ':' character. In bools array there are a name:value types, so i.e if we have a "Windows10:FALSE" then 'Windows10' = name and 'FALSE' = value. So our 'name' = '$parts[0]' and our 'value' = '$parts[1]'.
        echo -e "Would you like to add ${parts[0]} support to your firmware? (Y/N):"
        while :
        do
            read choise
            if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
            then
                bools[$index]="${parts[0]}:TRUE"
                IFS=':' read -ra parts <<< "${bools[$index]}" # Update parts with the new value from bools
                mkdir $path/Installers/$parts[0]
                break
            elif [ $choise == "N" ] || [ $choise == "n" ]
            then
                bools[$index]="${parts[0]}:FALSE"
                IFS=':' read -ra parts <<< "${bools[$index]}" # Update parts with the new value from bools
                break
            else
                echo -e "${RED}Invalid option! Try again.${NC}"
            fi
        done
    done

    echo -en "${GREEN}Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# ------ End of PXE dirs Function ------

# ------ Services Configuration Functions ------
# DHCP Server configuration
function conf_dhcp(){
    clear
    check_dhcp # Go to check_dhcp function
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

    # If content of 'range' is empty then loop is working until 'range' have an content inside
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
}
# End of DHCP Server Configuration

# TFTP Server Configuration
function conf_tftp(){
    clear
    check_tftp # Go to check_tftp function
    echo "TFTP_USER='tftp'" > /etc/sysconfig/tftp
	echo "TFTP_OPTIONS='--secure'" >> /etc/sysconfig/tftp
	echo "TFTP_DIRECTORY='${path_tftp}'" >> /etc/sysconfig/tftp
	echo "TFTP_ADDRESS='0.0.0.0:69'" >> /etc/sysconfig/tftp

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of TFTP Server Configuration

# Samba Server Configuration
function conf_smb(){
    clear
    check_smb # Go to check_smb function
    smb_proc=0 # Auxiliary variable for 'while' loop
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

    if id -u "$smb_username" > /dev/null 2>&1
    then
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
    else
        echo -en "${RED}User ${smb_username} isn't exist in system! Would you like to create new account? (Y/N):${NC} "
        read choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            useradd -m $smb_username

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
        elif [ $choise == "N" ] || [ $choise == "n" ] || [[ -z $choise ]]
        then
            echo -e "${RED}Can not configure Samba! Please try again!${NC}"
        else
            echo -e "${RED}Can not configure Samba! Please try again!${NC}"
        fi
    fi

    echo -en "${GREEN}User created. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of Samba Server Configuration

# Apache Server Configuration
function conf_apache(){
    clear
    check_apache # Go to conf_apache function
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
# End of Apache Server Configuration

# NFS Server Configuration
function conf_nfs(){
    check_nfs # Go to check_nfs function
    echo -e "${CYAN}Writing informations to config file..."
    # Writing '$path/nfs' to exports file. This will be accessible from all PC's with IP from $net network.
    echo "$path/nfs ${net}/${mask}(rw,sync,no_subtree_check)" > /etc/exports
    exportfs -a

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of NFS Server Configuration
# ------ End of Services Configuration Functions ------

# ------ File/Path Check Functions ------
# There are stored all of the functions for checking if config files are exist.
function check_dhcp(){
    if [ ! -e /etc/dhcpd.conf ]
    then
        echo -e "${RED_BOLD}Can not configure DHCP server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function check_tftp(){
    if [ ! -e /etc/sysconfig/tftp ]
    then
        echo -e "${RED_BOLD}Can not configure TFTP server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function check_smb(){
    if [ ! -e /etc/samba/smb.conf ]
    then
        echo -e "${RED_BOLD}Can not configure Samba server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function check_apache(){
    if [ ! -d /etc/apache2/vhosts.d ]
    then
        echo -e "${RED_BOLD}Can not configure Apache because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function check_nfs(){
    if [ ! -e /etc/exports ]
    then
        echo -e "${RED_BOLD}Can not configure NFS server because of missing config files. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

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

check
