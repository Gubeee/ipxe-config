#!/bin/bash

path=""
path_tftp=""
path_apache=""
path_smb=""
path_nfs=""

srv=""
smb_name=""
smb_usr_usrname="" 
smb_usr_passw=""

function intro(){
    clear
    echo "-------- PXE Configurator --------"
    read -p "Chcesz skonfigurowac PXE? (Y/N): " choise

    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
    then
        down_packs
        menu
    elif [ $choise == "N" ] || [ $choise == "n" ]
    then
        echo "Konczenie programu..."
        exit
    else
        echo "Nie ma takiej opcji! Zacznijmy od nowa..."
        sleep 3
        intro
    fi
}

function menu(){
    clear
    echo "0. Pelna instalacja"
    echo "1. Tworzenie drzewa plikow"
    echo "2. Konfiguracja DHCP"
    echo "3. Konfiguracja TFTP"
    echo "4. Konfiguracja Samby"
    echo "5. Konfiguracja Apache"
    echo "6. Konfiguracja NFS"
    echo "7. Konfiguracja iPXE"
    echo "8. Pobieranie Windowsa"
    echo "9. Uruchamianie uslug"
    read -p "Wybierz opcje: " choise
    if [ $choise == 1 ]
    then
        path_qna
        file_tree
        menu
    elif [ $choise == 2 ]
    then
        dhcp_conf
        menu
    elif [ $choise == 3 ]
    then
        tftp_conf
        menu
    elif [ $choise == 4 ]
    then
        smb_conf
        menu
    elif [ $choise == 5 ]
    then
        apache_conf
        menu
    elif [ $choise == 6 ]
    then
        nfs_conf
        menu
    elif [ $choise == 7 ]
    then
        ipxe_conf
        menu
    elif [ $choise == 8 ]
    then
        os_down
    elif [ $choise == 9 ]
    then
        service_start
    elif [ $choise == 0 ]
    then
        path_qna
        file_tree
        dhcp_conf
        tftp_conf
        smb_conf
        apache_conf
        nfs_conf
        ipxe_conf
        os_down
        service_start
    else
        echo "Nie ma takiej opcji w menu. Zacznijmy od nowa"
        sleep 2
        menu
    fi
}

function down_packs(){
    clear
    echo "Odswiezanie i pobieranie pakietow. Moze to chwile potrwac..."
    #Odswiezanie repo
    zypper ref > /dev/null
    zypper up > /dev/null

    #Pobieranie skladnikow do iPXE
    echo "Pobieranie pakietow niezbednych dla iPXE..."
    zypper in -y make gcc binutils perl mtools mkisofs syslinux liblzma5 > /dev/null

    #Pobieranie uslug
    echo "Pobieranie uslug takich jak DHCP, Apache..."
    zypper in -y yast2-dhcp-server yast2-tftp-server apache2 git yast2-nfs-server tftp dhcp-server samba yast2-samba-server nfs-kernel-server yast2-nfs-server > /dev/null
}

function path_qna(){
    clear
    if [ ! -d /pxe-boot ]
    then
        read -p "Defaultowa sciezka do serwera PXE, to '/pxe-boot'. Czy chcesz ja zmienic (Y/N): " choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            read -p "Podaj sciezke, w ktorej maja znalez sie pliki serwera: " usr_path
            path=$usr_path
            echo "Sciezka do plikow PXE, to ${path}"
            read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
        elif [ $choise == "N" ] || [ $choise == "n" ] || [[ -z $choise ]]
        then
            path="/pxe-boot"
            echo "Sciezka do plikow PXE, to ${path}"
            read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
        else
            echo "Nie ma takiej opcji! Zacznijmy od nowa..."
            sleep 3
            qna
        fi
    else
        read -n 1 -r -s -p $"Folder /pxe-boot istnieje. Kliknij ENTER, by przejsc dalej..."
    fi
    #Zmiana lokalizacji serwerow
    echo "Zmieniam lokalizacje serwerow. Prosze czekac..."
    path_tftp=$path
    path_apache=$path
    path_smb=$path
    path_nfs=$path
}

function file_tree(){
    if [ ! -d $path ]
    then
        echo "Folder nie istnieje. Tworzenie drzewa plikow..."
        mkdir $path
        mkdir -p $path/Installers/Windows/
        mkdir $path/Installers/Windows/Win10
        mkdir $path/Installers/Windows/Win11
        mkdir $path/Installers/Linux
        mkdir $path/nfs
        mkdir $path/Other
        mkdir $path/Other/ipxe
        mkdir $path/ipxe-files
    else
        read -n 1 -r -s -p $"Foldery istnieja. Kliknij ENTER, by przejsc dalej..."
    fi
}

function dhcp_conf(){
    clear
    echo "Sprawdzanie, czy pliki, do konfiguracji DHCP istnieja. Prosze czekac..."
    if [ ! -e /etc/dhcpd.conf ]
    then
        echo "Plik konfiguracyjny nie istnieje. Sprobuj zainstalowac 'yast2-dhcp-server' i 'dhcp-server' recznie."
        echo "Konczenie..."
        sleep 2
        exit
    else
        next=""
        dns=""
        echo "Plik konfiguracyjny istnieje. Mozna przejsc dalej."
        read -p "Podaj adres sieci (Network): " net
        read -p "Podaj adres routera (Gateway): " gate
        read -p "Podaj maske sieci (np. 255.255.255.0): " mask
        read -p "Podaj adres serwera: " srv
        read -p "Podaj zakres DHCP (np. 192.168.50.3 192.168.50.254): " range
        #Konfiguracja DNS
        read -p "Czy chcesz zmienic adres DNS? (default: 8.8.8.8) (Y/N): " choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            read -p "Podaj adres DNS: " usr_dns
            dns=$usr_dns
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            dns="8.8.8.8"
        else
            echo "Nie ma takiej opcji! Zacznijmy od nowa..."
            sleep 3
            clear
            dhcp_conf
        fi
        #Konfiguracja next-server
        echo "Adres 'next-server', to adres serwera, na ktorym beda pliki niezbedne do dzialania serwera PXE. Zalecane jest, by 'next-server' mial to samo IP, co serwer DHCP itd."
        read -p "Czy chcesz zmienic adres 'next-server'? (default: ${srv}) (Y/N): " choise
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            read -p "Podaj adres 'next-server': " usr_next
            next=$usr_next
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            next=$srv
        else
            echo "Nie ma takiej opcji! Zacznijmy od nowa..."
            sleep 3
            clear
            dhcp_conf
        fi

	echo ""
	echo "Nie wiem czemu, ale po wpisanu configu do pliku txt, dhcpd.service nie chce sie uruchomic, dlatego teraz zostaniesz przekierowany do 'yast2 dhcp-server' i wystaczy, ze wybierzesz tam interface, otworzysz port w firewallu, potem ustawisz DNSy i na koncu zmienisz status na aktywny i wlaczysz uruchamienie uslugi wraz ze startem systemu"
	read -n 1 -r -s -p $"Po przeczytaniu informacji kliknij ENTER, by przejsc dalej..."

	yast2 dhcp-server

        #Informacje
        echo "Plik 'ipxe.efi' (do bootowania w urzadzeniach z UEFI) zostanie wygenerowany automatycznie. Niestety, przez brak jednej paczki pod openSUSE, niemozliwe jest wygenerowanie pliku 'undionly.kpxe' (do bootowania w urzadzeniach z BIOS) dlatego, owy plik, bedzie 'pre-built', co w pewien sposob ograniczy mozliwosc customizacji."
        read -n 1 -r -s -p $"Po przeczytaniu informacji kliknij ENTER, by przejsc dalej..."
        echo ""
        #Wpisywanie informacji do pliku
        echo "Wpisywanie podanych informacji, do pliku konfiguracyjnego. Moze to chwile potrwac..."

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
		echo "DHCP skonfigurowane. Plik konfiguracyjny znajduje sie w /etc/dhcpd.conf."
        read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
    fi
}

function tftp_conf(){
    clear
    echo "Sprawdzanie, czy plik konfiguracyjny TFTP istnieje..."
    if [ ! -e /etc/sysconfig/tftp ]
    then
        echo "Plik konfiguracyjny nie istnieje. Sprobuj zainstalowac 'yast2-tftp-server' i 'tftp' recznie."
        echo "Konczenie..."
        sleep 2
        exit
    else
        echo "Plik istnieje. Wpisywanie konfiguracji..."
        echo "TFTP_USER='tftp'" > /etc/sysconfig/tftp
		echo "TFTP_OPTIONS='--secure'" >> /etc/sysconfig/tftp
		echo "TFTP_DIRECTORY='${path_tftp}'" >> /etc/sysconfig/tftp
		echo "TFTP_ADDRESS='0.0.0.0:69'" >> /etc/sysconfig/tftp
		echo "TFTP skonfigurowane. Plik konfiguracyjny znajduje sie w /etc/sysconfig/tftp."
        read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
    fi
}

function smb_conf(){    
    clear
    echo "Sprawdzanie, czy plik konfiguracyjny Samby istnieje..."
	if [ ! -e /etc/samba/smb.conf ]
	then
        echo "Plik konfiguracyjny nie istnieje. Sprobuj zainstalowac 'yast2-samba-server' i 'samba' recznie."
        echo "Konczenie..."
        sleep 2
        exit
	else
        echo "Plik istnieje. Przejdzmy dalej..."
        read -p "Defaultowa nazwa udzialu to 'pxe-files'. Czy chcesz ja zmienic? (Y/N): " choise
        #Zmiana nazwy udzialu
        if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
        then
            read -p "Podaj nazwe udzialu: " usr_smb_name
            smb_name=$user_smb_name
        elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
        then
            smb_name="pxe-files"
        else
            echo "Nie ma takiej opcji! Zacznijmy od nowa..."
            sleep 3
            smb_conf
        fi
        echo "Wpisywanie konfiguracji..."

        echo "[${smb_name}]" > /etc/samba/smb.conf
        echo "  comment = Samba na serwerze PXE" >> /etc/samba/smb.conf
        echo "  path = ${path_smb}" >> /etc/samba/smb.conf
        echo "  read only = no" >> /etc/samba/smb.conf
        echo "  browseable = yes" >> /etc/samba/smb.conf
        echo "  writeable = yes" >> /etc/samba/smb.conf

        echo "By w pelni korzystac z samby, musisz stworzyc nowego uzytkownika"
        read -p "Podaj nazwe uzytkownika: " smb_usr_usrname
        smbpasswd -a $smb_usr_usrname

        read -p "Podaj to samo haslo, by mozna bylo je wpisac do pliku automatyzacji Windowsa: " smb_usr_passw

        echo "Uzytkownik zostal utworzony"
        echo "Samba zostala skonfigurowana. Plik konfiguracyjny znajduje sie w '/etc/samba/smb.conf'."
        read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
    fi
}

function apache_conf(){
    clear
    echo "Sprawdzanie, czy folder z konfiguracyja Apache istnieje..."
	if [ ! -d /etc/apache2/vhosts.d/ ]
    then
        echo "Folder z plikami Apache nie istnieje. Sprobuj pobrac 'apache2' recznie."
        echo "Konczenie..."
        sleep 2 
        exit
    else
        touch /etc/apache2/vhosts.d/pxe.conf
        if [ ! -e /etc/apache2/vhosts.d/pxe.conf ]
        then
            echo "Plik z konfiguracja apache nie istnieje. Sprobuj utworzyc go recznie w podanej sciezce i sprobuj ponownie: '/etc/apache2/vhosts.d/vhost/pxe.conf'."
            echo "Konczenie..."
            sleep 2
            exit
        else
            echo "<VirtualHost *:80>" > /etc/apache2/vhosts.d/pxe.conf
            echo "  ServerAdmin it@emiter.com" >> /etc/apache2/vhosts.d/pxe.conf
            echo "  DocumentRoot ${path_apache}" >> /etc/apache2/vhosts.d/pxe.conf
            echo "</VirtualHost>" >> /etc/apache2/vhosts.d/pxe.conf

            echo "Apache2 skonfigurowany. Plik konfiguracyjny znajduje sie w '/etc/apache2/vhosts.d/pxe.conf'"
            read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
        fi
    fi
    if [ ! -e /etc/apache2/httpd.conf ]
    then
        echo "Plik httpd.conf nie istnieje. Pobierz 'apache2' recznie i sprobuj ponownie."
        echo "Konczenie..."
        sleep 3
        exit
    else
        echo "<Directory />" >> /etc/apache2/httpd.conf
        echo "  Options +FollowSymLinks +Indexes" >> /etc/apache2/httpd.conf
        echo "  Require all granted" >> /etc/apache2/httpd.conf
        echo "</Directory>" >> /etc/apache2/httpd.conf
    fi
}

function nfs_conf(){
    clear
    echo "Sprawdzanie, czy pliki konfiguracyjne NFS istnieja..."
    if [ ! -e /etc/exports ]
    then
        echo "Plik konfiguracyjny NFS nie istnieje. Sprobuj pobrac 'yast2-nfs-server' i 'nfs-kernel-server' recznie."
        echo "Konczenie..."
        sleep 2
        exit
    else
        echo "Wpisywanie konfiguracji do pliku konfiguracyjnego..."
        echo "$path/nfs *(rw,sync,no_subtree_check)" > /etc/exports
        exportfs -a
        echo "NFS skonfigurowany pomyslnie. Plik konfiguracyjny znajduje sie w '/etc/exports'."
        read -n 1 -r -s -p $"Kliknij ENTER, by przejsc dalej..."
    fi
}

function ipxe_conf(){
    clear
    echo "Pobieranie iPXE..."
    git clone https://github.com/ipxe/ipxe.git $path/Other/ipxe > /dev/null
    if [ -d $path/Other ]
    then
        if [ $(pwd) != $path/Other ]
        then
            if [ ! -e $path/Other/wimboot ]
            then
                cd $path/Other
                wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot > /dev/null
            fi
        else
            if [ ! -e $path/Other/wimboot ]
            then
                wget https://github.com/ipxe/wimboot/releases/latest/download/wimboot > /dev/null
            fi
        fi
    else
        echo "Folder nie istnieje. Sprobuj swtorzyc drzewo plikow i wroc tutaj potem."
        echo "Konczenie..."
        sleep 2
        exit
    fi

    echo "Tworzenie pliku embed.ipxe..."
    touch $path/Other/ipxe/src/embed.ipxe

    read -p "Czy chcesz dodac zdjecie w tle do bootloadera? (Y/N): " choise
    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ]
    then
        echo "#define CONSOLE_FRAMEBUFFER" >> $path/Other/ipxe/src/config/console.h
        echo "#define IMAGE_PNG" >> $path/Other/ipxe/src/config/general.h
        echo "#define CONSOLE_CMD" >> $path/Other/ipxe/src/config/general.h
	cp /home/suse/PXE-DATA/bg.png $path/Other
    elif [ $choise == "N" ] || [ $choise == "n" ] || [ -z $choise ]
    then
        echo "Pomijanie..."
    else
        echo "Nie ma takiej opcji. Zacznijmy od nowa..."
        sleep 5
        ipxe_conf
    fi

    echo "#define DOWNLOAD_PROTO_NFS" >> $path/Other/ipxe/src/config/local/general.h

    if [ ! -e $path/Other/ipxe/src/embed.ipxe ]
    then
        echo "Nie udalo sie utworzyc pliku embed.ipxe. Sprobuj stworzyc go recznie w podanej lokalizacji: '${path}/Other/ipxe/src/embed.ipxe'."
        echo "Konczenie..."
        sleep 3
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

    echo "Tworzenie pliku ipxe.efi..."
    if [ $(pwd) != $path/Other/ipxe/src ]
    then
        cd $path/Other/ipxe/src
        make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe > /dev/null
        mv bin-x86_64-efi/ipxe.efi $path
    else
        make bin-x86_64-efi/ipxe.efi EMBED=embed.ipxe > /dev/null
        mv bin-x86_64-efi/ipxe.efi $path
    fi
    
    #Pytania o wpisy do main.ipxe
    read -p "Czy chcesz skonfigurowac iPXE do instalacji Windows 10? (Y/N): " choise
    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
    then
        touch $path/ipxe-files/win10.ipxe
    fi
    read -p "Czy chcesz skonfigurowac iPXE do instalacji Windows 11? (Y/N): " choise
    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
    then
        touch $path/ipxe-files/win11.ipxe
    fi
    read -p "Czy chcesz skonfigurowac iPXE do klonowania dyskow przez CloneZille? (Y/N): " choise
    if [ $choise == "Y" ] || [ $choise == "y" ] || [ $choise == "T" ] || [ $choise == "t" ] || [ -z $choise ]
    then
        touch $path/ipxe-files/clone.ipxe
    fi

    echo "Tworzenie pliku main.ipxe..."
    touch $path/ipxe-files/main.ipxe

    if [ ! -e $path/ipxe-files/main.ipxe ]
    then
        echo "Plik main.ipxe nie istnieje. Sprobuj stworzyc go recznie w lokalizacji '${path}/ipxe-files/main.ipxe'."
        echo "Konczenie..."
        sleep 2
        exit
    else
        echo "#!ipxe" > $path/ipxe-files/main.ipxe
        echo "" >> $path/ipxe-files/main.ipxe
	if [ -e $path/Other/bg.png ]
	then
	    echo "console --x 1024 --y 768 --picture http://${srv}/Other/bg.png" >> $path/ipxe-files/main.ipxe
	fi
        echo ":menu" >> $path/ipxe-files/main.ipxe
        echo "menu" >> $path/ipxe-files/main.ipxe
        echo "  item --gap -- -------- iPXE Boot Menu --------" >> $path/ipxe-files/main.ipxe
        if [ -e $path/ipxe-files/win10.ipxe ]
        then
            echo "  item win10    Install Windows 10" >> $path/ipxe-files/main.ipxe
        fi
        if [ -e $path/ipxe-files/win11.ipxe ]
        then
            echo "  item win11    Install Windows 11" >> $path/ipxe-files/main.ipxe
        fi
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
        if [ -e $path/ipxe-files/win10.ipxe ]
        then
            echo ":win10" >> $path/ipxe-files/main.ipxe
            echo "    chain http://${srv}/ipxe-files/win10.ipxe" >> $path/ipxe-files/main.ipxe
        fi
        if [ -e $path/ipxe-files/win11.ipxe ]
        then
            echo ":win11" >> $path/ipxe-files/main.ipxe
            echo "    chain http://${srv}/ipxe-files/win11.ipxe" >> $path/ipxe-files/main.ipxe
        fi
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
    if [ -e $path/ipxe-files/clone.ipxe ]
    then
        echo "#!ipxe" > $path/ipxe-files/clone.ipxe
        echo "" >> $path/ipxe-files/clone.ipxe
        echo "kernel http://${srv}/Installers/Linux/live/vmlinuz initrd=${path}/Installers/Linux/live/initrd.img boot=live live-config noswap nolocales edd=on nomodeset ocs_daemonon=\"ssh\" ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"--batch -g auto -e1 auto -e2 -r -j2 -p reboot restoredisk ask_user sda\" ocs_live_keymap=\"/usr/share/keymaps/i386/qwerty/us.kmap/gz\" ocs_live_batch=\"yes\" ocs_lang=\"en_US.UTF-8\" vga=788 nosplash fetch=${srv}/Installers/Linux/live/filesystem.squashfs ocs_prerun=\"mount -t nfs ${srv}:${path}/nfs /home/partimag"\" >> $path/ipxe-files/clone.ipxe
        echo "initrd http://${srv}/Installers/Linux/live/initrd.img" >> $path/ipxe-files/clone.ipxe
        echo "" >> $path/ipxe-files/clone.ipxe
        echo "boot" >> $path/ipxe-files/clone.ipxe  
    fi

    echo "Tworzenie automatyzacji Windowsa..."
    if [ -e $path/ipxe-files/win10.ipxe ]
    then
        touch $path/Installers/Windows/Win10/winpeshl.ini
        touch $path/Installers/Windows/Win10/install.bat

        if [ ! -e $path/Installers/Windows/Win10/winpeshl.ini ]
        then
            echo "Nie udalo sie stworzyc pliku 'winpeshl.ini. Sprobuj stworzyc go recznie w lokalizacji '$path/Installers/Windows/Win10/winpeshl.ini'."
            echo "Konczenie...."
            sleep 3
            exit
        else
            echo "[LaunchApps]" > $path/Installers/Windows/Win10/winpeshl.ini
            echo '"install.bat"' >> $path/Installers/Windows/Win10/winpeshl.ini
        fi
        if [ ! -e $path/Installers/Windows/Win10/install.bat ]
        then
            echo "Nie udalo sie stworzyc pliku 'install.bat'. Sprobuj stworzyc go recznie w lokalizacji '$path/Installers/Windows/Win10/install.bat'."
            echo "Konczenie...."
            sleep 3
            exit
        else
            echo "wpeinit" > $path/Installers/Windows/Win10/install.bat
            echo "net use \\\\$srv\\$smb_name /user:${smb_usr_usrname} ${smb_usr_passw}" >> $path/Installers/Windows/Win10/install.bat
            echo "\\\\$srv\\$smb_name\Installers\Windows\Win10\setup.exe" >> $path/Installers/Windows/Win10/install.bat
        fi
    fi
    if [ -e $path/ipxe-files/win11.ipxe ]
    then
        touch $path/Installers/Windows/Win11/winpeshl.ini
        touch $path/Installers/Windows/Win11/install.bat

        if [ ! -e $path/Installers/Windows/Win11/winpeshl.ini ]
        then
            echo "Nie udalo sie stworzyc pliku 'winpeshl.ini. Sprobuj stworzyc go recznie w lokalizacji '$path/Installers/Windows/Win11/winpeshl.ini'."
            echo "Konczenie...."
            sleep 3
            exit
        else
            echo "[LaunchApps]" > $path/Installers/Windows/Win11/winpeshl.ini
            echo '"install.bat"' >> $path/Installers/Windows/Win11/winpeshl.ini
        fi
        if [ ! -e $path/Installers/Windows/Win11/install.bat ]
        then
            echo "Nie udalo sie stworzyc pliku 'install.bat'. Sprobuj stworzyc go recznie w lokalizacji '$path/Installers/Windows/Win11/install.bat'."
            echo "Konczenie...."
            sleep 3
            exit
        else
            echo "wpeinit" > $path/Installers/Windows/Win11/install.bat
            echo "net use \\\\$srv\\$smb_name /user:${smb_usr_usrname} ${smb_usr_passw}" >> $path/Installers/Windows/Win11/install.bat
            echo "\\\\$srv\\$smb_name\Installers\Windows\Win11\setup.exe" >> $path/Installers/Windows/Win11/install.bat
        fi
    fi
    cp /home/suse/PXE-DATA/boot.wim $path/Other/boot.wim
    cp /home/suse/PXE-DATA/undionly.kpxe $path/undionly.kpxe

    read -n 1 -r -s -p $"Plik utworzone. Kliknij ENTER, by przejsc dalej..."
    echo ""
}

function os_down(){
    clear
    if [ -e $path/ipxe-files/win10.ipxe ]
    then
        echo "Kopiowanie plikow instalacyjnych Win10..."
        cp -R /home/suse/PXE-DATA/Win10/* $path/Installers/Windows/Win10
    fi
    if [ -e $path/ipxe-files/win11.ipxe ]
    then
        echo "Kopiowanie plikow instalacyjnych Win11..."
        cp -R /home/suse/PXE-DATA/Win11/* $path/Installers/Windows/Win11
    fi
    if [ -e $path/ipxe-files/clone.ipxe ]
    then
        echo "Pobieranie obrazu CloneZilla..."
        curl 'https://deac-riga.dl.sourceforge.net/project/clonezilla/clonezilla_live_stable/3.1.2-22/clonezilla-live-3.1.2-22-amd64.iso?viasf=1' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Referer: https://sourceforge.net/' -H 'Connection: keep-alive' -H 'Cookie: __cmpconsentx11319=CP9nwjAP9nwjAAfUnBENAxEsAP_AAEPAACiQGgwEAAGgAVABAAC0AGgATAAoABfADCAHgAQQAowCEALzAZeA0EDQYCAADQAKgAgABaADQAJgAUAAvgBhADwAIIAUYBCAF5gMvAaCAAA; __cmpcvcx11319=__c37910_s135_c48392_s30_U__; __cmpcpcx11319=____; __gads=ID=51ca8e34ae5905c0:T=1714043840:RT=1714043840:S=ALNI_MZYJCQfXewTvz1OnvD_MDkzB_h-SA; __gpi=UID=00000dfe1d0b78b9:T=1714043840:RT=1714043840:S=ALNI_MZ-vKxNSTOZQlHMunc0b57EHUI9gQ; __eoi=ID=ac4bf2da1cea6aae:T=1714043840:RT=1714043840:S=AA-AfjYlMlSvxwex91lUf6RofYJP' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-site' -o $path/clone.iso
        echo "Montowanie obrazu..."
        mount $path/clone.iso /mnt
        echo "Kopiowanie plikow..."
        cp -R /mnt/* $path/Installers/Linux
        umount /mnt
        rm -R $path/clone.iso
        read -n 1 -r -s -p $"Pliki skopiowane. Kliknij ENTER, by przejsc dalej..."
        echo ""
    fi
}

function service_start(){
    systemctl start dhcpd
    systemctl start apache2
    systemctl start tftp
    systemctl start smb
    systemctl start nfs
    systemctl start nfs-server
}

clear
intro
