#! /bin/bash
#
# V18.02.024
# wenn Script-Dateiname ".KDEtweaks.sh" und Ort /home/USER ist, kann mit dem Dateimanager (z.B.Dolphin)
# eine "Verknüpfung zu Programm ..." erstellt werden (Kontextmenü -> Neu erstellen)
# Wichtig! Befehl: konsole -e ~/.KDEtweaks.sh
#
#
# wenn die Variable passwort leer ist, kommt eine sudo Passwortabfrage
passwort="";
#
# Flatpak ist eine Alternative zu Canonical snap Apps, wenn du das benutzt mit einer 1 aktivieren, sonst 0
flatpak=0;
#
# welcher Kernel wird benutzt? Wichtig für Punkt 4!
# ab Ubuntu 16.04.2 gibt es Rolling HWE Stacks, wenn dieser verwendet wird dann z.B.: kernel="linux-generic-hwe-16.04 xserver-xorg-hwe-16.04"
kernel="linux-generic";
#
# wenn Tor-Browser lokal installiert ist (https://www.torproject.org/download/download.html), hier den Ort eintragen
torVerzeichnis=".tor-browser";
#
#
# ab hier nur ändern wenn du weisst was du tust!
    # gibt es ein public_html im Homeordner?
    if [ -d ~/public_html ]; then
       html="1";
       else
       html="0";
    fi
 
    # gibt es einen Tor-Browser im Homeordner?
    if [ -d ~/$torVerzeichnis ]; then
       tor="1";
       else
       tor="0";
    fi

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
    6 "alte Konfigurationen löschen" off 7 "Paketlisten aufräumen" off 8 "Zugriffsrechte aktualisieren" off 9 "Obsolete Pakete anzeigen" off 2>/dev/null`;

    case $answer in
        "1")
        echo $passwort | sudo -S -s apt update -y; sudo -S -s apt upgrade -y; sudo -S -s apt dist-upgrade -y; sudo -S -s apt clean -y; sudo -S -s apt autoclean -y; sudo -S -s apt-get -f install -y; sudo -S -s apt clean -y; sudo -S -s apt autoremove --purge -y;
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
        echo $passwort | sudo -S -s dpkg --configure -a; sudo -S -s apt upgrade -f -y; sudo -S -s apt dist-upgrade -f -y;
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
        sudo chown -R $USER:$USER /home/$USER/;

        # Zugriffsrechte: alle /home Dateien chmod 644 und Ordner chmod 755 geben
        sudo find /home/$USER/ \( -type d -exec chmod 755 {} + \) -or \( -type f -exec chmod 644 {} + \);

            # nur wenn es im Homeordner ein public_html gibt:
            case "$html" in
            0) echo ""; #dummy
            ;;
            1) # Besitzer: alle public_html Dateien der Gruppe www-data geben
               # nur aktivieren wenn ~/public_html benutzt wird!
               sudo chown -R www-data:www-data /home/$USER/public_html/;

               # Zugriffsrechte: alle public_html Dateien chmod 664 und Ordner chmod 775 geben
               # nur aktivieren wenn ~/public_html benutzt wird!
               sudo find /home/$USER/public_html/ \( -type d -exec chmod 775 {} + \) -or \( -type f -exec chmod 664 {} + \);
            ;;
            *) echo "error html";;
            esac

            # nur wenn es im Homeordner einen Tor-Browser gibt:
            case "$tor" in
            0) echo ""; #dummy
            ;;
            1) # bestimmte Tor-Dateien müssen ausführbar sein
               chmod 754 /home/$USER/$torVerzeichnis/Browser/TorBrowser/Tor/tor;
                chmod 754 /home/$USER/$torVerzeichnis/Browser/execdesktop;
                 chmod 754 /home/$USER/$torVerzeichnis/Browser/firefox;
                  chmod 754 /home/$USER/$torVerzeichnis/Browser/execdesktop;
                   chmod 754 /home/$USER/$torVerzeichnis/Browser/plugin-container;
                    chmod 754 /home/$USER/$torVerzeichnis/Browser/start-tor-browser;
                      chmod 754 /home/$USER/$torVerzeichnis/Browser/updater;
            ;;
            *) echo "error tor";;
            esac

        # *.sh und *.desktop ausführbar machen
        sudo find /home/$USER/ -name "*.sh" -exec chmod 0754 {} \;
        sudo find /home/$USER/ -name "*.desktop" -exec chmod 0754 {} \;

        clear;

        # Im Homeordner sollten sich keine Dateien befinden die nicht dem Benutzer gehören!
        # wenn das Apache Modul mod_userdir und ~/public_html benutzt wird, sollten nur Dateien gelistet die der Gruppe www-data gehören

        # Liste Dateien die nicht dem Benutzer oder www-data gehören!
        find ~ ! -user $USER -and ! -user www-data -ls;
        echo "";
        echo "##################################################################################";
        echo "";

            case "$html" in
            0) echo "*** hier sollte nichts stehen und alle Dateien gehören dir ***";
               echo "";
               echo "Hinweis: alle deine *.sh und *.desktop Dateien im Homeordner sind ausführbar und";
               echo "shellscripts ohne .sh Dateiendung sind nicht ausführbar, das musst du manuell tun!";
            ;;
            1) echo "*** hier sollte nichts stehen und alle Dateien - ausser im Ordner ~/public_html - gehören dir ***";
               echo "*** nur Dateien im Ordner ~/public_html gehören dem User www-data ***";
               echo "";
               echo "Hinweis: alle deine *.sh und *.desktop Dateien im Homeordner sind ausführbar und";
               echo "shellscripts ohne .sh Dateiendung sind nicht ausführbar, das musst du manuell tun!";
            ;;
            *) echo "error2";;
            esac

        echo "";
        kdialog --msgbox "Zugriffsrechte und Besitzer neu gesetzt.\nBitte die Konsolenausgabe auf evtl. Fehler prüfen." 2>/dev/null;
        ;;
        "9")
        echo $passwort | sudo -S -s apt install aptitude -y; #wenn nicht installiert
        reset;
        aptitude search '?obsolete';
        kdialog --msgbox "Liste von obsoleten Pakete können auch von Drittanbietern stammen.\nDaher sollten diese nur manuell gelöscht werden!\nTipp: Benutze dafür die Synaptic Paketverwaltung." 2>/dev/null;
        ;;
        *) echo "abgebrochen";;
    esac

exit;
