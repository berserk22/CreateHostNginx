#!/bin/bash
echo -e "\n"
echo -e "\e[01;32m #################################\e[00m"
echo -e "\e[01;32m # Web Installations Script      #\e[00m"
echo -e "\e[01;32m #################################\e[00m"
echo -e "\n"

existuser(){
	if uid=$(id -u "$USERID" 2>/dev/null); then
       echo -e  "\e[01;31m User $USERID exisitier bereits \e[00m"
    else
       echo -e  "\e[01;36m User $USERID exisitier nicht \e[00m"
       echo -e  "\e[01;36m Erstelle die benötigten Ordner für $USERID \e[00m"
       createdirs
    fi
}


createdirs(){
	dirsarray=('/srv/www/'${USERID}'/html' '/srv/www/'${USERID}'/logs' '/srv/www/'${USERID}'/sessions' '/srv/www/'${USERID}'/tmp')
	for var in "${dirsarray[@]}"
       do
        if [ ! -d $var ]; then
          echo -e ""
        	echo -e  "\e[01;36m Ordner ${var} exsistiert nicht und wird erstellt \e[00m"
        	mkdir -p $var;
        	if [ -d $var ]; then
        		echo -e  "\e[01;32m  Ordner ${var} wurde erstellt \e[00m"
        	fi
        elif [ -d $var ]; then
        	echo -e  "\e[01;32m  Ordner ${var} exisitier bereits \e[00m"
        fi
    done
    createuser
}

createuser(){
	if uid=$(id -u "$USERID" 2>/dev/null); then
		echo -e  "\e[01;31m User $USERID exisitier bereits \e[00m"
	else
      echo -e ""
       echo -e  "\e[01;31m Erstelle User $USERID \e[00m"
       passgenerator
       useradd -s /bin/sh -d /srv/www/${USERID}/ ${USERID}
       if uid=$(id -u "$USERID" 2>/dev/null); then
        echo -e ""
       	echo -e  "\e[01;31m Setze Passwort User $USERID \e[00m"
        echo -e ""
        { echo $pass; sleep 1; echo $pass;} | passwd $USERID
        echo -e ""
       fi
    fi
    adduser www-data ${USERID}
    chrights
}

passgenerator(){
    #Maximale Länge des Passwortes +1 weil ab 0 gezählt wird
	MAXSIZE=11
	#Array mit Zeichen
	chararray=(q w e r t y u i o p a s d f g h j k l z x c v b n m Q W E R T Y U I O P A S D F G H J K L Z X C V B N M 1 2 3 4 5 6 7 8 9 0 \! @ \# \$ \% ^ \& \* \( \))
    num=${#chararray[*]}
    pass=''
   i=0
   while [ $i -le $MAXSIZE ]
   do
    pass=$pass${chararray[$((RANDOM%num))]}
    let i=$i+1
   done
    
}


# Create DB_Table 27.02.2016
dbsave(){
	read -p "\e[01;36m Gieb bitte Datenbak Passwort: " DBPASS
	cp adduser.sql adduser_${USERID}.sql
	find adduser_${USERID}.sql -type f -exec sed -i 's/%webuser/'${USERID}'/g' {} \;
	find adduser_${USERID}.sql -type f -exec sed -i 's/%password/'${pass}'/g' {} \;
	find adduser_${USERID}.sql -type f -exec sed -i 's/%host/'${HOST}'/g' {} \;
	find adduser_${USERID}.sql -type f -exec sed -i 's/%ip/'${IP}'/g' {} \;
	mysql -h localhost -u root -p${DBPASS} < adduser_${USERID}.sql
	rm adduser_${USERID}.sql
}

chrights(){
	echo -e "\e[01;36m Ändere Userrechte für Ordner /srv/www/${USERID}/ \e[00m"
	chown root:${USERID} /srv/www/${USERID}/ && chmod 750 /srv/www/${USERID}
  echo -e ""
	echo -e "\e[01;36m Ändere Userrechte für Ordner /srv/www/${USERID}/* \e[00m"
    chown ${USERID}:${USERID} -R /srv/www/${USERID}/* && chmod 750 -R /srv/www/${USERID}/*

    makefpmpool
}

makefpmpool(){
  echo -e ""
	echo -e "\e[01;36m Erstelle die php5-fpm Pool Datei für User ${USERID} \e[00m"
	cp fpm-pool_template.txt /etc/php5/fpm/pool.d/${USERID}.conf
    find /etc/php5/fpm/pool.d/${USERID}.conf -type f -exec sed -i 's/%webuser/'${USERID}'/g' {} \;
  echo -e ""

    makesocksfolder
}

makesocksfolder(){
  if [ ! -d /run/php5-fpm ]; then
    mkdir /run/php5-fpm
    if [ -d /run/php5-fpm ]; then
       /etc/init.d/php5-fpm restart
    fi
  else
    /etc/init.d/php5-fpm restart
  fi

  oudnewuserdata
}

oudnewuserdata(){
  echo -e ""
	echo -e "\e[01;32m Neuer Web und User erfolgreich erstellt hier die Zugangsdaten\e[00m"
	echo -e ""
	echo -e "\e[01;32m User: ${USERID}  \e[00m"
	echo -e "\e[01;32m Passwort: ${pass}  \e[00m"
  echo -e ""

  makevhost
}

makevhost(){
  read -p "Gieb bitte den Domain-Namen (format: example.com) der angelegt werden soll ein: " HOST
  read -p "Gieb bitte den Locale IP-Adresse (beispiel: 127.0.0.2) der angelegt werden soll ein (schreibt in /etc/hosts): " IP
  echo -e "\e[1;31m Du hast Domain-Name: ${HOST} und Locale IP-Adresse: ${IP} eingegeben \e[00m"
  echo -e "\e[1;31m Möchtest du diesen erstellen [ja/nein] \e[00m"
  read -p "" answer
  if [ $answer = ja ];
  then
     createvhost
  elif [ $answer = nein  ];
  then
    echo -e "\e[1;31m Du hast das Script beendet \e[00m"
  fi
}

createvhost(){
  echo -e ""
	echo -e "\e[01;36m Erstelle die Virtual-Host Datei für Domain-Name ${HOST} \e[00m"
	cp vhost_template.txt /etc/nginx/sites-available/${HOST}
        find /etc/nginx/sites-available/${HOST} -type f -exec sed -i 's/%webuser/'${USERID}'/g' {} \;
        find /etc/nginx/sites-available/${HOST} -type f -exec sed -i 's/%ip/'${IP}'/g' {} \;
        find /etc/nginx/sites-available/${HOST} -type f -exec sed -i 's/%host/'${HOST}'/g' {} \;
        ln -s /etc/nginx/sites-available/${HOST} /etc/nginx/sites-enabled/
        mkdir /srv/www/${USERID}/html/${HOST}
        mkdir /srv/www/${USERID}/html/${HOST}/public
        cp test_index.php /srv/www/${USERID}/html/${HOST}/public/index.php
        chown ${USERID}:${USERID} -R /srv/www/${USERID}/* && chmod 750 -R /srv/www/${USERID}/*

        echo "${IP}	${HOST}" 1>> /etc/hosts
        /etc/init.d/nginx restart
  echo -e ""

}


read -p "Gieb bitte den Webuser der angelegt werden soll ein: " USERID
echo -e "\e[1;31m Du hast User: ${USERID} eingegeben \e[00m"
echo -e "\e[1;31m Möchtest du diesen erstellen [ja/nein] \e[00m"
read -p "" answer


if [ $answer = ja ]; 
then
	existuser
	dbsave

elif [ $answer = nein ]; 
then
	echo -e "\e[1;31m Du hast das Script beendet \e[00m"
fi
