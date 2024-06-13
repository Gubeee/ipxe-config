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
bools=("background:FALSE" "Windows10:FALSE" "Windows11:FALSE" "CloneZilla:FALSE" "MemTest:FALSE" "Ubuntu:FALSE" "OpenSUSE:FALSE")

# Misc
srv="" # PXE Server IP Address
package_down_status=0 # Checking if packages have been downloaded or not

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34;47m' # With a white background

RED_BOLD='\033[1;31m'
CYAN_BOLD='\033[1;36m'

CYAN_UNDER='\033[4;36m'

NC='\033[0m'

# ------ End of Global Variables ------

# ------ Functions ------
function check(){
    clear

    path_sh="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # Getting path to script, where SHOULD BE stored all of the data (Win10/11 Installation Files, bg.img, etc.). For more information chceck README.md and look for a file tree img.

    if [ ! -e '${path_sh}/boot.wim' ] || [ ! -d '${path_sh}/Win10' ] || [ ! -d '${path_sh}/Win11' ] # If in script path those files aren't present, then script is telling user that some files are missing
    then
        echo -e "${RED}Some files are missing! Would You like to continue? (Y/N): ${NC}"
        read choise

        if [ $choise == 'Y' ] || [ $choise == 'y' ] || [ $choise == 'T' ] || [ $choise == 't' ] || [ -z $choise ]
        then
            intro # Go to *intro* function
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
        config_start            # Go to *config_start* function
    elif [ $choise == "2" ]
    then
        readme_file             # Go to *readme_file* function
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
        *) invalid_param_config_start ;;        # Invalid Parameter Function
    esac
}
# ------ End of Configuration Start Function ------

# ------ Full Installation Function ------
# Setting up PXE Server from scratch
function full_install(){
    clear

    # ------------------------------------------------
    pack_down       # Go to *pack_down* function
    pxe_tree        # Go to *pxe_tree* function
    # ------------------------------------------------
    conf_dhcp       # Go to *dhcp_config* function
    conf_tftp       # Go to *tftp_config* function
    conf_smb        # Go to *samba_config* function
    conf_apache     # Go to *apache_config* function

    if [ -d $path/Installers/CloneZilla ] 
    then
        conf_nfs    # Go to *nfs_config* function
    fi

    # ------------------------------------------------
    conf_ipxe       # Go to *ipxe_config* function
    # ------------------------------------------------
    service_start   # Go to *service_start* function
    misc_options    # Go to *misc_options* function
}
# ------ End of Full Installation Function ------

# ------ Root Folder Function ------
# Creating PXE dir tree
function pxe_tree(){
    clear

    echo -e "${BLUE}---------- CREATING TREE ----------${NC}"
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
    path_tftp=$path         # Setting $path as a TFTP server path.
    path_apache=$path       # Setting $path as a Apache2 server path.
    path_smb=$path          # Setting $path as a Samba server path. 
    path_nfs=$path          # Setting $path as a NFS server path.

    # Creating default folders in $path
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
                IFS=':' read -ra parts <<< "${bools[$index]}"   # Update parts with the new value from bools
                mkdir $path/Installers/${parts[0]}              # Creating directories for holding files
                touch $path/ipxe-files/"${parts[0]}.ipxe"       # Creating .ipxe files
                break
            elif [ $choise == "N" ] || [ $choise == "n" ]
            then
                bools[$index]="${parts[0]}:FALSE"
                IFS=':' read -ra parts <<< "${bools[$index]}"   # Update parts with the new value from bools
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

    check_dhcp # Go to *check_dhcp* function
    echo -e "${BLUE}---------- DHCP CONFIGURATION ----------${NC}"

    next=""         # Global variable 'next' is holding a 'next-server' address which equals 'srv'
    gate=""         # Global variable 'gate' is holding a 'gateway' address
    mask=""         # Global variable 'mask' is holding a 'subnet mask' address
    srv=""          # Global variable 'srv' is holding a 'server' address
    dns=""          # Global variable 'dns' is holding a 'dns server' address

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

    # Let's take a look to this command - for example our Network IP Address is 192.168.0.0. Command below is splitting our '$net' variable by '.'
    # and it's holding only three octets of this address. So if or Network IP is 192.168.0.0 then our '$net_cut' is 192.168.0
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
        read -e -p "Enter a first address of a DHCP range: " -i "$net_cut." range_one
        read -e -p "Enter a last address of a DHCP range: " -i "$net_cut." range_last
        range="${range_one} ${range_last}"
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
            # Selecting ethernet adapter with the same IP and setting it as a DHCP default adapter
            yast dhcp-server interface select=$iface > /dev/null
        fi
    done

    echo -e "${CYAN}Writing informations to config file. Please wait...${NC}"
    echo "option client-arch code 93 = unsigned integer 16;" > /etc/dhcpd.conf      # DHCP specified variable for get information if client has a UEFI or BIOS
    echo "allow booting;" >> /etc/dhcpd.conf                                        # DHCP specified variable which allows booting via Network
    echo "allow bootp;" >> /etc/dhcpd.conf                                          # Idk, same as above I guess >_<        
    echo "" >> /etc/dhcpd.conf
    echo "subnet ${net} netmask ${mask} {" >> /etc/dhcpd.conf                       # DHCP specified class(???) for our configuration
    echo "  range ${range};" >> /etc/dhcpd.conf                                     # Range of a DHCP server
    echo "  option routers ${gate};" >> /etc/dhcpd.conf                             # Gateway address
    echo "  option subnet-mask ${mask};" >> /etc/dhcpd.conf                         # Subent mask
    echo "  option domain-name-servers ${dns};" >> /etc/dhcpd.conf                  # DNS Address
    echo "  default-lease-time 600;" >> /etc/dhcpd.conf                             # Lease time
    echo "  max-lease-time 7200;" >> /etc/dhcpd.conf                                # Lease time
    echo "  next-server ${next};" >> /etc/dhcpd.conf                                # Next server address
    echo "  if option client-arch != 00:00 {" >> /etc/dhcpd.conf                    # DHCP specified if statement. If 'client-arch' is different than "00:00"
    echo '    filename "ipxe.efi";' >> /etc/dhcpd.conf                              # then iPXE will boot PXE via 'ipxe.efi' file
    echo "  } else { " >> /etc/dhcpd.conf                                           # but if 'client-arch' equals '00:00'
    echo '    filename "undionly.kpxe";' >> /etc/dhcpd.conf                         # then iPXE will boot PXE via 'undionly.kpxe' file.
    echo "  }" >> /etc/dhcpd.conf
    echo "}" >> /etc/dhcpd.conf

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of DHCP Server Configuration

# TFTP Server Configuration
function conf_tftp(){
    clear

    check_tftp # Go to *check_tftp* function

    echo -e "${BLUE}---------- TFTP CONFIGURATION ----------${NC}"
    echo "TFTP_USER='tftp'" > /etc/sysconfig/tftp
	echo "TFTP_OPTIONS='--secure'" >> /etc/sysconfig/tftp
	echo "TFTP_DIRECTORY='${path_tftp}'" >> /etc/sysconfig/tftp
	echo "TFTP_ADDRESS='0.0.0.0:69'" >> /etc/sysconfig/tftp

    # Nothing much going on here. Only setting 'TFTP_DIRECTORY' as a $path_tftp. Other variables are premade and should not be changed unless
    # you know what you are doing

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of TFTP Server Configuration

# Samba Server Configuration
function conf_smb(){
    clear

    check_smb   # Go to *check_smb* function
    smb_proc=0  # Auxiliary variable for 'while' loop

    echo -e "${BLUE}---------- SAMBA CONFIGURATION ----------${NC}"

    echo -en "${CYAN}Default share name is 'pxe-files'. Would you like to change it? (Y/N):${NC} "
    read choise

    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
    then
        read -p "Enter share name: " usr_smb_name
        smb_name=$usr_smb_name          # Setting Samba share name same as $usr_smb_name
    elif [ $choise == "N" ] || [ $choise == "n" ]
    then
        smb_name="pxe-files"            # Setting default Samba share name
    else
        echo -e "${RED_BOLD}Undefined option! Let's start over...${NC}"
        sleep 3
        conf_smb
    fi

    echo -e "${CYAN}Writing informations to config file...${NC}"
    echo "[${smb_name}]" > /etc/samba/smb.conf                              # Setting share name same as a $smb_name
    echo "  comment = Samba on PXE Server" >> /etc/samba/smb.conf           # You can change comment in script. It only informs you what it is.
    echo "  path = ${path_smb}" >> /etc/samba/smb.conf                      # Setting Samba path same as a $path_smb
    echo "  read only = no" >> /etc/samba/smb.conf                          # 'read only' is set to 'no' so you can exit files while you are connected to a share
    echo "  browseable = yes" >> /etc/samba/smb.conf                        # 'browseable' is set to 'yes' so you can search your share
    echo "  writeable = yes" >> /etc/samba/smb.conf                         # 'writeable' is set to 'yes' so you can upload files to your share

    # Creating Samba user for access to Samba share - this step is required for Windows 10/11 Installation
    echo -en "${CYAN}If you want samba to work properly, you have to create an user${NC}"
    echo ""
    echo -en "Enter username: "
    read smb_username

    if id -u "$smb_username" > /dev/null 2>&1
    then
        while [ $smb_proc != 1 ]    # If $smb_proc is different than 1 that means 'smbpasswd' output is an error. 
        do    
            smbpasswd -a $smb_username
            if [ $? -ne 0 ]
            then
                echo -e "${RED_BOLD}'smbpasswd' returned erorr. Please try again...${NC}"
                smb_proc=0
            else
                echo -en "${CYAN}Please, enter the same password. It'll be used in Windows Automation Script:${NC} "
                read smb_passwd     # This needed for autorun 'setup.exe' file in Windows Automation Script. If you put wrong password, Win PE will automatycally reboot!
                smb_proc=1          # If $smb_proc is 1 that means everything went well
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
                    smb_proc=1      # If $smb_proc is 1 that means everything went well
                fi
            done
        elif [ $choise == "N" ] || [ $choise == "n" ] || [[ -z $choise ]]
        then
            echo -e "${RED}Can not configure Samba! Please try again!${NC}"
            conf_smb
        fi
    fi

    echo -en "${GREEN}User created. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of Samba Server Configuration

# Apache Server Configuration
function conf_apache(){
    clear

    check_apache # Go to *conf_apache* function

    echo -e "${BLUE}---------- APACHE CONFIGURATION ----------${NC}"

    touch /etc/apache2/vhosts.d/pxe.conf
    if [ ! -e /etc/apache2/vhosts.d/pxe.conf ] # Checking if 'pxe.conf' file is present in a expected path.
    then
        echo -e "${RED_BOLD}Can not make Apache '.conf' file. Please re-run script and make sure that all packages were successfully downloaded.${NC}"    
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        while [ -z $srv_adm_addr ]
        do
            read -p "Enter your Server Admin Email Address: " srv_adm_addr      # Idk for what it's needed but I saw this in tutorial so I putted it there
        done
        echo "<VirtualHost *:80>" > /etc/apache2/vhosts.d/pxe.conf              # Creating a new Virtual Host
        echo "  ServerAdmin ${srv_adm_addr}" >> /etc/apache2/vhosts.d/pxe.conf  # Setting a '$srv_adm_addr' as a 'ServerAdmin'
        echo "  DocumentRoot ${path_apache}" >> /etc/apache2/vhosts.d/pxe.conf  # Setting a 'path_apache' as a 'DocumentRoot'
        echo "</VirtualHost>" >> /etc/apache2/vhosts.d/pxe.conf                 # End of creating a Virtual Host
    fi

    if [ ! -e /etc/apache2/httpd.conf ] # Checking if 'httpd.conf' file is present in a expected path.
    then
        echo -e "${RED_BOLD}'httpd.conf' is not present.Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Services started. Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    else
        echo "<Directory />" >> /etc/apache2/httpd.conf                         # Creating a new Directory   
        echo "  Options +FollowSymLinks +Indexes" >> /etc/apache2/httpd.conf    # Couple of options
        echo "  Require all granted" >> /etc/apache2/httpd.conf                 # Couple of options
        echo "</Directory>" >> /etc/apache2/httpd.conf                          # End of creating a new Directory
    fi   

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s

}
# End of Apache Server Configuration

# NFS Server Configuration
function conf_nfs(){
    clear
    
    check_nfs # Go to *check_nfs* function

    echo -e "${BLUE}---------- NFS CONFIGURATION ----------${NC}"

    mkdir $path/NFS

    echo -e "${CYAN}Writing informations to config file...${NC}"

    # Writing '$path/nfs' to exports file. This will be accessible from all PC's with IP from $net network.
    echo "$path/NFS ${net}/${mask}(rw,sync,no_subtree_check)" > /etc/exports
    exportfs -a

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
}
# End of NFS Server Configuration
# ------ End of Services Configuration Functions ------

# ------ iPXE Configuration Function ------
# Download and configure iPXE
function conf_ipxe(){
    clear

    check_ipxe # Go to check_ipxe function

    echo -e "${BLUE}---------- IPXE CONFIGURATION ----------${NC}"

    # REPO SPECIFIED
    echo -e "${CYAN}Cloning iPXE repo. Please wait...${NC}"
    git clone https://github.com/ipxe/ipxe.git $path/Other/ipxe         # Cloning 'iPXE' repo to '$path/Other/ipxe'
    clear
    echo -e "${CYAN}Cloning Wimboot repo. Please wait...${NC}"
    git clone https://github.com/ipxe/wimboot $path/Other/Wimboot-dir   # Cloning 'wimboot' repo to '$path/Other/Wimboot-dir'
    cp $path/Other/Wimboot-dir/wimboot $path/Other                      # Copying only 'wimboot' file to '$path/Other'
    rm -R $path/Other/Wimboot-dir                                       # Removing a 'Wimboot-dir' directory
    clear
    # /REPO SPECIFIED

    git config --global --add safe.directory $path/Other/ipxe

    # .h FILES SPECIFIED
    if [ "${bools[0]}" == "background:TRUE" ]   # If earlier user has pressed 'Y' while script was asking to, then script will add support for a background image
    then
        # Writing information to '.h' libraries for background image support
        sed -i '3i#define CONSOLE_FRAMEBUFFER' $path/Other/ipxe/src/config/console.h        # Inserting '#define CONSOLE_FRAMEBUFFER' to '.h' file
        sed -i "3i#define IMAGE_PNG" $path/Other/ipxe/src/config/general.h                  # Inserting '#define IMAGE_PNG' to '.h' file
        sed -i "4i#define CONSOLE_CMD" $path/Other/ipxe/src/config/general.h                # Inserting '#define CONSOLE_CMD' to '.h' file

        # Writing informations to '.h' library for NFS download support
        echo "#define DOWNLOAD_PROTO_NFS" >> $path/Other/ipxe/src/config/local/general.h    # Inserting '#define DOWNLOAD_PROTO_NFS' to '.h' file
    fi
    # /.h FILES SPECIFIED

    # EMBED.IPXE SPECIFIED
    echo -e "${CYAN}Creating 'embed.ipxe' file...${NC}"
    # 'embed.ipxe' file is required for custom build of '.efi' or/and '.kpxe' files. Without this file, you can build only stock configuration and later you would have to write iPXE commands
    touch $path/Other/ipxe/src/embed.ipxe

    # Writing information to 'embed.ipxe' file
    echo "#!ipxe" > $path/Other/ipxe/src/embed.ipxe                                             # Same as in a bash script
    echo "" >> $path/Other/ipxe/src/embed.ipxe
    echo "dhcp && goto netboot || dhcperror" >> $path/Other/ipxe/src/embed.ipxe                 # Creating targerts. 'dhcp && goto netboot' tells script to first get an IP address from DHCP server and later go to 'netboot' target or if firmware can not access DHCP server then go to 'dhcperror' target
    echo "" >> $path/Other/ipxe/src/embed.ipxe
    echo ":dhcperror" >> $path/Other/ipxe/src/embed.ipxe                                        # 'dhcperror' target

    # If DHCP error occured, user have 10 seconds to press 's' key to open iPXE Shell. If user will miss that, then PC will automatically reboot.
    echo "  prompt --key s --timeout 10000 DHCP Failed. Hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot" >> $path/Other/ipxe/src/embed.ipxe
    echo "" >> $path/Other/ipxe/src/embed.ipxe
    echo ":netboot" >> $path/Other/ipxe/src/embed.ipxe                                          # 'netboot' target
    # This line is telling firmware to connect to a server via TFTP and download a 'main.ipxe' file.
    echo "  chain tftp://${srv}/ipxe-files/main.ipxe ||" >> $path/Other/ipxe/src/embed.ipxe
    # If netboot error occured, user have 10 seconds to press 's' key to open iPXE Shell. If user will miss that, then PC will automatically reboot.
    echo "  prompt --key s --timeout 10000 Netboot Failed. Hit 's' for the iPXE shell; reboot in 10 seconds && shell || reboot" >> $path/Other/ipxe/src/embed.ipxe
    
    echo -e "${CYAN}Creating 'ipxe.efi' file and 'undionly.kpxe' file. Please wait...${NC}"
    # Checking if script is in expected path, if not then it's changing directory
    if [ $(pwd) != $path/Other/ipxe/src ]
    then
        cd $path/Other/ipxe/src
        make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe 2>&1 | pv -l > $path/make-efi.log     # 'pv' command informs us that script isn't stuck
        mv bin-x86_64-efi/ipxe.efi $path                                                    # moving an 'ipxe.efi'  file to a $path
        make bin/undionly.kpxe EMBED=embed.ipxe 2>&1 | pv -l > $path/make-kpxe.log          # 'pv' command informs us that script isn't stuck
        mv bin/undionly.kpxe $path                                                          # moving an 'undionly.kpxe' file to a $path
    fi
    # /EMBED.IPXE SPECIFIED

    # MAIN.IPXE SPECIFIED
    echo -e "${CYAN}Checking if expected path is present...${NC}"
    check_dir_ipxe # Go to 'check_dir_ipxe' funtion

    # Creating 'main.ipxe' file where bootloader menu information are 'stored'
    echo -e "${CYAN}Creating 'main.ipxe' file...${NC}"
    touch $path/ipxe-files/main.ipxe # Creating 'main.ipxe' file in '$path/ipxe-files' path.

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
        if [ "${bools[0]}" == "background:TRUE" ]
        then
            # Adding an background image to a bootloader
            cp $path_sh/bg.png $path/Other > /dev/null
            echo "console --x 1024 --y 768 --picture http://${srv}/Other/bg.png" >> $path/ipxe-files/main.ipxe 
        fi

        echo ":menu" >> $path/ipxe-files/main.ipxe # Creating 'menu' target
        echo "menu" >> $path/ipxe-files/main.ipxe  # 'menu' targert
        echo "  item --gap -- -------- iPXE Boot Menu --------" >> $path/ipxe-files/main.ipxe # Header

        # Writing informations to 'menu' tab.
        for index in "${!bools[@]}" # For loop is going through all elements in bools array
        do
            IFS=':' read -ra parts <<< "${bools[$index]}" # This command is splitting values of bools array by ':' character. In bools array there are a name:value types, so i.e if we have a "Windows10:FALSE" then 'Windows10' = name and 'FALSE' = value. So our 'name' = '$parts[0]' and our 'value' = '$parts[1]'.
            if [ "${bools[$index]}" == "${parts[0]}:TRUE" ]
            then
                IFS=':' read -ra parts <<< "${bools[$index]}"   # Update parts with the new value from bools
                # If '${parts[0]}' is TRUE then it's creating a new target called ''${parts[0]}'
                echo "  item ${parts[0],,}" "  ${parts[0]}"  >> $path/ipxe-files/main.ipxe 
            fi
        done
        # Premade options which can help later if user has a problem.
        echo "  item shell    iPXE Shell" >> $path/ipxe-files/main.ipxe
        echo "  item sett     Network Settings" >> $path/ipxe-files/main.ipxe
        echo "" >> $path/ipxe-files/main.ipxe
        # This line is going to a specified target selected by client
        echo 'choose --default return --timeout 5000 target && goto ${target}' >> $path/ipxe-files/main.ipxe
        echo "" >> $path/ipxe-files/main.ipxe

        # Writing informations to 'target' tab.
        for index in "${!bools[@]}" # For loop is going through all elements in bools array
        do
            IFS=':' read -ra parts <<< "${bools[$index]}" # This command is splitting values of bools array by ':' character. In bools array there are a name:value types, so i.e if we have a "Windows10:FALSE" then 'Windows10' = name and 'FALSE' = value. So our 'name' = '$parts[0]' and our 'value' = '$parts[1]'.
            if [ "${bools[$index]}" == "${parts[0]}:TRUE" ]
            then
                IFS=':' read -ra parts <<< "${bools[$index]}"   # Update parts with the new value from bools
                # If '${parts[0]}' is TRUE then it's creating a new http chain to get informations from '.ipxe' file to boot selected OS.
                if [ "${parts[0],,}" == "background" ]
                then
                    echo "Dummy echo" > /dev/null
                fi
                echo ":${parts[0],,}" >> $path/ipxe-files/main.ipxe
                echo "  chain http://${srv}/ipxe-files/${parts[0]}.ipxe" >> $path/ipxe-files/main.ipxe
            fi
        done

        # Premade options which can help later if user has a problem.
        echo ":shell" >> $path/ipxe-files/main.ipxe
        echo "  shell" >> $path/ipxe-files/main.ipxe
        echo ":sett" >> $path/ipxe-files/main.ipxe
        echo "  config" >> $path/ipxe-files/main.ipxe
        echo "  goto menu" >> $path/ipxe-files/main.ipxe
    fi

    # Writing informations to '$path/ipxe-files/{target}.ipxe' file.
    for index in "${!bools[@]}" # For loop is going through all elements in bools array
    do
        IFS=':' read -ra parts <<< "${bools[$index]}" # This command is splitting values of bools array by ':' character. In bools array there are a name:value types, so i.e if we have a "Windows10:FALSE" then 'Windows10' = name and 'FALSE' = value. So our 'name' = '$parts[0]' and our 'value' = '$parts[1]'.
        if [ "${bools[$index]}" == "${parts[0]}:TRUE" ]
        then
            IFS=':' read -ra parts <<< "${bools[$index]}"   # Update parts with the new value from bools
            case "${parts[0]}" in Windows*)
                for win in Windows10 Windows11
                do
                    echo "#!ipxe" > $path/ipxe-files/$win.ipxe
                    echo "" >> $path/ipxe-files/$win.ipxe
                    echo "kernel http://${srv}/Other/wimboot gui" >> $path/ipxe-files/$win.ipxe
                    echo "" >> $path/ipxe-files/$win.ipxe
                    echo "initrd http://${srv}/Installers/$win/winpeshl.ini     winpeshl.ini" >> $path/ipxe-files/$win.ipxe
                    echo "initrd http://${srv}/Installers/$win/install.bat      install.bat" >> $path/ipxe-files/$win.ipxe
                    echo "initrd http://${srv}/Installers/$win/boot/bcd         bcd" >> $path/ipxe-files/$win.ipxe
                    echo "initrd http://${srv}/Installers/$win/boot/boot.sdi    boot.sdi" >> $path/ipxe-files/$win.ipxe
                    echo "initrd http://${srv}/Other/boot.wim                       boot.wim" >> $path/ipxe-files/$win.ipxe
                    echo "" >> $path/ipxe-files/$win.ipxe
                    echo "boot || goto failed" >> $path/ipxe-files/$win.ipxe

                    touch $path/Installers/$win/winpeshl.ini
                    touch $path/Installers/$win/install.bat

                    echo "[LaunchApps]" > $path/Installers/$win/winpeshl.ini
                    echo '"install.bat"' >> $path/Installers/$win/winpeshl.ini

                    echo "wpeinit" > $path/Installers/$win/install.bat
                    echo "net use \\\\$srv\\$smb_name /user:${smb_username} ${smb_passwd}" >> $path/Installers/$win/install.bat
                    echo "\\\\$srv\\$smb_name\Installers\\${win}\\setup.exe" >> $path/Installers/$win/install.bat

                    echo -e "${CYAN}Copying installation files to ${win} folder...${NC}"
                    rsync -a --info=progress2 $path_sh/Win10/* $path/Installers/$win
                done
                ;;
            esac
        fi
    done

    # Script is checking if 'clone.ipxe' file is present. It depends on earlier user choise.
    if [ -e $path/ipxe-files/CloneZilla.ipxe ]
    then
        echo "#!ipxe" > $path/ipxe-files/CloneZilla.ipxe
        echo "" >> $path/ipxe-files/CloneZilla.ipxe
        echo "kernel http://${srv}/Installers/CloneZilla/live/vmlinuz initrd=${path}/Installers/CloneZilla/live/initrd.img boot=live live-config noswap nolocales edd=on nomodeset ocs_daemonon=\"ssh\" ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"--batch -g auto -e1 auto -e2 -r -j2 -p reboot restoredisk ask_user sda\" ocs_live_keymap=\"/usr/share/keymaps/i386/qwerty/us.kmap/gz\" ocs_live_batch=\"yes\" ocs_lang=\"en_US.UTF-8\" vga=788 nosplash fetch=${srv}/Installers/CloneZilla/live/filesystem.squashfs ocs_prerun=\"mount -t nfs ${srv}:${path}/nfs /home/partimag"\" >> $path/ipxe-files/CloneZilla.ipxe
        echo "initrd http://${srv}/Installers/CloneZilla/live/initrd.img" >> $path/ipxe-files/CloneZilla.ipxe
        echo "" >> $path/ipxe-files/CloneZilla.ipxe
        echo "boot" >> $path/ipxe-files/CloneZilla.ipxe

        echo -e "${CYAN}Downloading CloneZilla .iso file...${NC}"
        curl 'https://deac-riga.dl.sourceforge.net/project/clonezilla/clonezilla_live_stable/3.1.2-22/clonezilla-live-3.1.2-22-amd64.iso?viasf=1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://sourceforge.net/' -H 'Connection: keep-alive' -H 'Cookie: __cmpconsentx11319=CP9nwjAP9nwjAAfUnBENAxEsAP_AAEPAACiQGgwEAAGgAVABAAC0AGgATAAoABfADCAHgAQQAowCEALzAZeA0EDQYCAADQAKgAgABaADQAJgAUAAvgBhADwAIIAUYBCAF5gMvAaCAAA; __cmpcvcx11319=__c37910_s135_c48392_s30_U__; __cmpcpcx11319=____; __gads=ID=51ca8e34ae5905c0:T=1714043840:RT=1714043840:S=ALNI_MZYJCQfXewTvz1OnvD_MDkzB_h-SA; __gpi=UID=00000dfe1d0b78b9:T=1714043840:RT=1714043840:S=ALNI_MZ-vKxNSTOZQlHMunc0b57EHUI9gQ; __eoi=ID=ac4bf2da1cea6aae:T=1714043840:RT=1714043840:S=AA-AfjYlMlSvxwex91lUf6RofYJP' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-site' -o $path/clone.iso
        echo "Mounting .iso file..."
        mount $path/clone.iso /mnt
        echo -e "${CYAN}Copying files...${NC}"
        rsync -a --info=progress2 /mnt/* $path/Installers/CloneZilla
        umount /mnt
        rm -R $path/clone.iso
    fi

    # Script is checking if 'mem.ipxe' file is present. It depends on earlier user choise.
    if [ "${bools[$index]}" == "MemTest:TRUE" ]
    then
        echo "#!ipxe" > $path/ipxe-files/MemTest.ipxe
        echo "" >> $path/ipxe-files/MemTest.ipxe
        echo "kernel http://${srv}/Other/memdisk || read void" >> $path/ipxe-files/MemTest.ipxe
        echo "initrd http://${srv}/Installers/MemTest/memtest.iso || read void" >> $path/ipxe-files/MemTest.ipxe
        echo "imgargs memdisk iso raw || read void" >> $path/ipxe-files/MemTest.ipxe
        echo "" >> $path/ipxe-files/MemTest.ipxe
        echo "boot || read void" >> $path/ipxe-files/MemTest.ipxe

        cp /usr/share/syslinux/memdisk $path/Other

        echo -e "${CYAN}Downloading Memtest .iso file...${NC}"
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
        -H 'sec-ch-ua-platform: "Windows"' -o $path/Installers/MemTest/memtest.iso
    fi

    if [ -e $path/ipxe-files/Ubuntu.ipxe ]
    then
        echo "#!ipxe" > $path/ipxe-files/Ubuntu.ipxe
        echo "" >> $path/ipxe-files/Ubuntu.ipxe
        echo "kernel http://${srv}/Installers/Ubuntu/vmlinuz root=/dev/ram0 netboot=http url=https://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso ip=dhcp || read void" >> $path/ipxe-files/Ubuntu.ipxe
        echo "initrd http://${srv}/Installers/Ubuntu/initrd || read void" >> $path/ipxe-files/Ubuntu.ipxe
        echo "" >> $path/ipxe-files/Ubuntu.ipxe
        echo "boot || read void" >> $path/ipxe-files/Ubuntu

        echo -e "${CYAN}Downloading Ubuntu 24.04 .iso file...${NC}"
        curl 'http://releases.ubuntu.com/focal/ubuntu-20.04.6-desktop-amd64.iso' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'Accept-Language: pl,en;q=0.9,en-GB;q=0.8,en-US;q=0.7' \
        -H 'Connection: keep-alive' \
        -H 'Cookie: _ga_EBCMJZG58E=GS1.2.1712897762.2.0.1712897762.60.0.0; _vwo_uuid_v2=DCB5834B0BAE81A0E7DFCB9422FAB312F|1724d73808af39530ef940082baa6ca0; __gtm_referrer=https%3A%2F%2Fwww.google.com%2F; _gcl_au=1.1.1880230484.1718098013; _mkto_trk=id:066-EOV-335&token:_mch-ubuntu.com-1718098015321-57943; _ce.irv=new; cebs=1; _CEFT=Q%3D%3D%3D; cebsp_=7; _ga=GA1.2.2086458117.1710413291; _ce.s=v~3bf6f3a7b3846458efca7d9b5de04077b471afd9~lcw~1718195286782~lva~1718098015541~vpv~0~v11.cs~30754~v11.s~fe5fdec0-28a7-11ef-933a-d96a941dd9b2~v11.sla~1718189619072~gtrk.la~lxbt4071~v11.send~1718195291080~lcw~1718195291080; _ga_5LTL1CNEJM=GS1.1.1718195291.6.0.1718195291.60.0.0; _ga_PGQQ61N4N6=GS1.1.1718195291.6.0.1718195291.0.0.0' \
        -H 'Referer: http://releases.ubuntu.com/focal/' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0' \
        --insecure -o $path/Ubuntu.iso

        echo -e "${CYAN}Mounting iso and copying required files...${NC}"
        mount $path/Ubuntu.iso /mnt
        echo -e "${CYAN}Copying files...${NC}"
        rsync -a --info=progress2 /mnt/casper/vmlinuz $path/Installers/Ubuntu
        rsync -a --info=progress2 /mnt/casper/initrd $path/Installers/Ubuntu
        umount /mnt
        rm -R $path/Ubuntu.iso
    fi

    if [ "${bools[$index]}" == "OpenSUSE:TRUE" ]
    then
        echo "#!ipxe" > $path/ipxe-files/OpenSUSE.ipxe
        echo "" >> $path/ipxe-files/OpenSUSE.ipxe
        echo "kernel http://${srv}/Installers/OpenSUSE/boot/x86_64/loader/linux root=/dev/ram0 install=http://${srv}/Installers/OpenSUSE ip=dhcp || read void" >> $path/ipxe-files/OpenSUSE.ipxe
        echo "initrd http://${srv}/Installers/OpenSUSE/boot/x86_64/loader/initrd || read void" >> $path/ipxe-files/OpenSUSE.ipxe
        echo "" >> $path/ipxe-files/OpenSUSE.ipxe
        echo "boot || read void" >> $path/ipxe-files/OpenSUSE.ipxe

        echo -e "${CYAN}Downloading OpenSUSE Leap .iso file...${NC}"
        curl 'https://mirroronet.pl/pub/mirrors/opensuse//distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Build709.1-Media.iso' \
        -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'Accept-Language: pl,en;q=0.9,en-GB;q=0.8,en-US;q=0.7' \
        -H 'Connection: keep-alive' \
        -H 'Referer: https://download.opensuse.org/' \
        -H 'Sec-Fetch-Dest: document' \
        -H 'Sec-Fetch-Mode: navigate' \
        -H 'Sec-Fetch-Site: cross-site' \
        -H 'Sec-Fetch-User: ?1' \
        -H 'Upgrade-Insecure-Requests: 1' \
        -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0' \
        -H 'sec-ch-ua: "Microsoft Edge";v="125", "Chromium";v="125", "Not.A/Brand";v="24"' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'sec-ch-ua-platform: "Windows"' -o $path/suse.iso

        echo -e "${CYAN}Mounting iso and copying required files...${NC}"
        mount $path/suse.iso /mnt
        echo -e "${CYAN}Copying files...${NC}"
        rsync -a --info=progress2 /mnt/* $path/Installers/OpenSUSE
        umount /mnt
        rm -R $path/suse.iso
    fi

    # Copying 'boot.wim' file to PXE root folder
    if [ "${bools[$index]}" == "Windows10:FALSE" ] && [ "${bools[$index]}" == "Windows11:FALSE" ]
    then
        echo -e "${RED}There isn't any of Windows Install Files! Skipping...${NC}"
    else
        echo -e "${CYAN}Copying neccessary files to root folder...${NC}"
        rsync -a --info=progress2 $path_sh/boot.wim $path/Other/boot.wim
    fi

    echo -en "${GREEN}Everything OK. Press ENTER to continue...${NC}"
    read -n 1 -r -s
    echo ""
}
# ------ End of iPXE Configuration Function ------

# ------ Service Start Function ------
# Starting required services and adding them to autostart
function service_start(){
    clear

    serv=("dhcpd.service" "apache2" "tftp" "smb" "nfs" "nfs-server")
    fire=("apache2" "http" "dhcp" "nfs" "samba" "tftp")
    
    echo -e "${CYAN}Checking if services are working...${NC}"
    for service in "${serv[@]}" # For loop is going through all elements in bools array
    do
        systemctl start "$service"
        systemctl enable "$service"
        systemctl restart "$service"
    done
    
    echo -e "${CYAN}Adding firewall rules for services...${NC}"
    for rule in "${fire[@]}"
    do
        firewall-cmd --zone=public --permanent --add-service="$rule"
    done
    firewall-cmd --reload

    echo -e "${CYAN}Making $path/nfs writable for reading/saving disk images made with CloneZilla...${NC}"
    chmod -R 777 $path/NFS > /dev/null
    chown -R nobody:nogroup $path/NFS > /dev/null

    echo -en "${GREEN}Services started. Press ENTER to continue...${NC}"
    read -n 1 -r -s
    config_start
}
# ------ End of Service Start Function ------

# Misc options
# ------ Misc Options Function ------
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
        $VISUAL $path_sh/README.md
    else
        echo -e "${RED} File 'README.md' doesn't exists!${NC}"
    fi
}

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

function check_ipxe(){
    if [ ! -d $path/Other ] && [ ! -d $path/Other/ipxe ]
    then
        echo -e "${RED_BOLD}Can not download and configure iPXE because of missing catalogs. Please re-run script and make sure that all packages were successfully downloaded."
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function check_dir_ipxe(){
    if [ ! -d $path/ipxe-files ]
    then
        echo -e "${RED_BOLD}Can not download and configure iPXE because of missing catalogs. Please re-run script and make sure that all packages were successfully downloaded.${NC}"
        echo -en "${RED_BOLD}Press ENTER to continue...${NC}"
        read -n 1 -r -s
        exit
    fi
}

function pack_down(){
    clear
    echo -e "${CYAN_BOLD}Refresing and updating zypper...${NC}"
    zypper --gpg-auto-import-keys ref
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
# ------ End of Misc Options Function ------

# ------ Program ------
if [ $EUID -ne 0 ]
then
    echo "Script should be run as su. Try login to su account or run script with sudo."
    sleep 3
    exit
else
    check
fi
# ------ End of Program ------
