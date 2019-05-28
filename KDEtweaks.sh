#! /bin/bash
#
version="V19.05.033";
# Neu seit 33: nutze zusätzlich als ersten Befehl das Toolkit pkcon, wie von den KDE neon Entwickler empfohlen (apt bleibt, z.B. um alten Kernel zu entfernen)
# Quelle: https://neon.kde.org/faq#command-to-update
#
# wenn Script-Dateiname ".KDEtweaks.sh" und Ort /home/USER/bin/ ist, kann mit dem Dateimanager (z.B.Dolphin)
# eine "Verknüpfung zu Programm ..." erstellt werden (Kontextmenü -> Neu erstellen)
# Wichtig! Befehl: konsole -e ~/bin/KDEtweaks.sh
#
#
# wenn die Variable passwort leer ist, kommt bei Bedarf eine sudo Passwortabfrage
passwort="";
#
#
# Flatpak ist eine Alternative zu Canonical snap Apps, wenn du das benutzt mit einer 1 aktivieren, sonst 0
flatpak=0;
#
#
# welcher Kernel wird benutzt? Wichtig für Punkt 4!
# ab Ubuntu 16.04.2 gibt es Rolling HWE Stacks, wenn dieser verwendet wird dann z.B.: kernel="linux-generic-hwe-16.04 xserver-xorg-hwe-16.04"
# ab Ubuntu 18.04 ist es wieder "linux-generic" und bei 18.04.2 wird es wahrscheinlich ab Feb. 2019 "linux-generic-hwe-18.04 xserver-xorg-hwe-18.04"
kernel="linux-generic";
#
#
# Zugriffsrechte: alle /home Dateien chmod 644 und Ordner chmod 755 geben, wenn du das willst mit einer 1 aktivieren, sonst 0
# ACHTUNG! Wer Programme ohne sudo unter /home installiert hat (z.B. Tor Browser oder ein Flatpak mit dem Flag --user), sollte das nicht tun!
# *.sh und *.desktop Dateien werden ausführbar gemacht - Dateien ohne diese Extension sind dann nicht ausführbar!
# Setzt die Datei .xsession-errors auf 0 Bytes und unveränderbar!
# Wenn du mit Linux Zugriffsrechte nichts anfangen kannst, belasse es auf 0 !


zugriffsrechte=0;
#
#
#
#
# ab hier nur ändern wenn du weisst was du tust!
    # gibt es ein public_html im Homeordner?
    if [ -d ~/public_html ]; then
       html="1";
       else
       html="0";
    fi

    echo $version;
    
    if [ $passwort ] # Abfrage Passwort
        then
        echo ">--------------------------------------------------";
        echo "Hinweis: Dein Passwort ist im Script gespeichert";
        echo "--------------------------------------------------<";
    else echo "mit Dialog Passwort Abfrage weiter!";
        passwort=`kdialog --password "Dein root Passwort wird für diese Anwendungen benötigt!" 2>/dev/null`;
        if [ $? = 0 ]; then
           echo "OK";
        else
           exit;
        fi
    fi

    ###################################################################################

    answer=`kdialog --radiolist "Bitte wähle:" 1 "System aktualisieren und reinigen" on 2 "Pakete reparieren" off \
    3 "alte Linux-Kernel anzeigen" off 4 "Linux-Kernel wieder herstellen" off 5 "UTF-8 Fehler beheben" off \
    6 "alte Konfigurationen löschen" off 7 "Paketlisten aufräumen" off \
    8 "Zugriffsrechte aktualisieren" off 9 "Obsolete Pakete anzeigen" off 10 "NVMe SSD S.M.A.R.T. LOG" off 2>/dev/null`;

    case $answer in
        "1")
        #nur wenn kein PackageKit verwendet werden sool
        #echo $passwort | sudo -S -s apt update -y; sudo -S -s apt upgrade -y; sudo -S -s apt full-upgrade -y; sudo -S -s apt clean -y; sudo -S -s apt autoclean -y; sudo -S -s apt-get -f install -y;  sudo -S -s apt autoremove --purge -y;
        #pkcon und apt Befehle
        echo $passwort | sudo -S -s sudo pkcon refresh force -c -1 && pkcon update -y; sudo -S -s apt clean -y; sudo -S -s apt autoclean -y; sudo -S -s apt-get -f install -y;  sudo -S -s apt autoremove --purge -y;
           if [ $flatpak -gt 0 ]
              then
              echo;
              echo "suche Flatpak updates:";
              echo $passwort | sudo -S -s flatpak update -y;
              echo "Done";
           fi
        kdialog --msgbox "Systemaktualisierung fertig.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "2")
        echo $passwort | sudo -S -s dpkg --configure -a; sudo -S -s apt upgrade -f -y; sudo -S -s apt full-upgrade -f -y;
        kdialog --msgbox "System ist repariert.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "3")
        reset;
        dpkg -l 'linux-[ihs]*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\([-0-9]*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d';
        kdialog --msgbox "Liste der alten Kernel einschließlich der Header-Dateien bis auf den aktuellen.\nHinweis: alte Kernel bis auf die beiden neuesten Kernel werden mit Punkt 1 entfernt." 2>/dev/null;
        ;;
        "4")
        echo $passwort | sudo -S -s apt install --reinstall linux-image-$(uname -r); sudo -S -s apt install $kernel -y;
        kdialog --msgbox "Aktueller Kernel wurde wieder hergestellt.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "5")
        echo $passwort | sudo -S -s dpkg-reconfigure locales -u; sudo -S -s update-locale LANG=de_DE.UTF-8; sudo -S -s locale-gen --purge --no-archive; sudo -S -s update-initramfs -u -k all;
        kdialog --msgbox "UTF-8 Fehler wurden behoben.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "6")
        echo $passwort | sudo -S -s apt purge `dpkg -l | grep ^rc | awk '{print $2}'` -y;
        kdialog --msgbox "Zurückgebliebene Konfiguration wurden gelöscht.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "7")
        echo $passwort | sudo -S -s rm -rf /var/lib/apt/lists/*; sudo -S -s apt update -y;
        kdialog --msgbox "Paketlisten wurden aufgeräumt.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "8")
        # Besitzrechte und Zugriffsrechte rekursiv in /home/USER dem Benutzer geben
        echo "Liste dein /home/USER/";
        echo $passwort | sudo -S -s ls ~;
        echo "";
        echo "Bitte warten...";

        # Besitzer: alle /home Dateien dem aktuellen Benutzer geben
        sudo chattr -i /home/$USER/.xsession-errors;         # veränderlich Attribut setzen
        sudo chown -R $USER:$USER /home/$USER/;

            # Zugriffsrechte: alle /home Dateien chmod 644 und Ordner chmod 755 geben
            if [ $zugriffsrechte -gt 0 ]
              then
              sudo find /home/$USER/ \( -type d -exec chmod 755 {} + \);
              sudo find /home/$USER/ \( -type f -exec chmod 644 {} + \);
            fi
       

            # nur wenn es im home Ordner ein public_html gibt:
            case "$html" in
            0) echo ""; #dummy
            ;;
            1) # Besitzer: alle public_html Dateien der Gruppe www-data geben
               # nur aktivieren wenn ~/public_html benutzt wird!
               sudo chown -R www-data:www-data /home/$USER/public_html/;

               # Zugriffsrechte: alle public_html Dateien chmod 664 und Ordner chmod 775 geben
               # nur aktivieren wenn ~/public_html benutzt wird!
               sudo find /home/$USER/public_html/ \( -type d -exec chmod 775 {} + \);
               sudo find /home/$USER/public_html/ \( -type f -exec chmod 664 {} + \);
            ;;
            *) echo "error html";;
            esac


            # *.sh und *.desktop ausführbar machen
            sudo find /home/$USER/ -name "*.sh" -exec chmod 0744 {} \;
            sudo find /home/$USER/ -name "*.desktop" -exec chmod 0744 {} \;
                        
            # .xsession-errors wird auf 0 Bytes gesetzt (gelöscht und wieder erstellt) und dann ein unveränderlich Attribut gesetzt,
            # wodurch verhindert wird, dass ein Prozess darauf schreibt (SSD Festplatten freuen sich ;-)
            rm -f /home/$USER/.xsession-errors;
            touch /home/$USER/.xsession-errors;
            sudo chattr +i /home/$USER/.xsession-errors;

        clear;

        # Im home Ordner sollten sich keine Dateien befinden die nicht dem Benutzer gehören!
        # Ausnahme: Wenn das Apache Modul mod_userdir und ~/public_html benutzt wird, gehören diese Dateien der Gruppe www-data.

        # Liste Dateien die nicht dem Benutzer oder www-data gehören!
        find ~ ! -user $USER -and ! -user www-data -ls;
        echo "";
        echo "##################################################################################";
        echo "";

            case "$html" in
            0) echo "*** hier sollte nichts stehen und alle Dateien gehören dir ***";
               echo "";
               echo "Hinweis: alle deine *.sh und *.desktop Dateien im Homeordner sind ausführbar!";
            ;;
            1) echo "*** hier sollte nichts stehen und alle Dateien - ausser im Ordner ~/public_html - gehören dir ***";
               echo "*** Dateien im Ordner ~/public_html gehören dem User www-data und chmod ist 664 bzw. 775 ***";
               echo "";
               echo "Hinweis: alle deine *.sh und *.desktop Dateien im Homeordner sind ausführbar!";
            ;;
            *) echo "error2";;
            esac

        echo "";
        echo "##################################################################################";
        echo "";
        kdialog --msgbox "Zugriffsrechte und Besitzer neu gesetzt.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "9")
        echo $passwort | sudo -S -s apt install aptitude -y; #wenn nicht installiert
        reset;
        aptitude search '?obsolete';
        kdialog --msgbox "Liste von obsoleten Pakete können auch von Drittanbietern stammen.\nDaher sollten diese nur manuell gelöscht werden!\nTipp: Benutze dafür die Synaptic Paketverwaltung." 2>/dev/null;
        ;;
        "10")
        #echo $passwort | sudo -S -s apt install nvme-cli -y; #wenn nicht installiert
        #reset;
        echo $passwort | sudo -S -s sudo nvme --smart-log /dev/nvme0n1;
        kdialog --msgbox "NVMe SSD DEVICE S.M.A.R.T. LOG" 2>/dev/null;
        ;;        
        *) echo "abgebrochen";;
    esac

exit;
