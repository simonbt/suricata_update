#!/bin/bash

rulesdir="/etc/suricata/rules"
suffix="rules"

backuploc="/home/suricatayaml"
rulesloc="/etc/suricata/rules"
log="/var/log/suricata_update.log"

#Run the updater first
oinkmaster -Q -o ${rulesloc} >> ${log} 

if [ $? -ne 0 ]; then
	echo "Oinkmaster FAILED - UPDATE halted! - "${date}
fi

#make sure that the backup folder exists
if [ ! -d ${backuploc} ]; then
	mkdir ${backuploc} 
fi

#Fuction that inserts the new rules list into the yaml file
function replace () {
awk 'FNR==NR{ _[++d]=$0;next}
/rule-files:/{
  print
  for(i=1;i<=d;i++){ print _[i] }
  f=1;next
}
/classification-file:/{f=0}!f' ${backuploc}/rules.tmp $@ > temp && mv temp $@
}

#Create the new rules list ready for inserting into the yaml files
for i in "${rulesdir}"/*.${suffix}
do
        echo " - "$i | sed 's/\/etc\/suricata\/rules\///g' >> ${backuploc}/rules.tmp
done

#Take backup of existing yaml files
cp /etc/suricata/suricata.eth1.yaml ${backuploc}/suricata.eth1.yaml.${date}
cp /etc/suricata/suricata.eth2.yaml ${backuploc}/suricata.eth2.yaml.${date}
cp /etc/suricata/suricata.eth3.yaml ${backuploc}/suricata.eth3.yaml.${date}
cp /etc/suricata/suricata.eth4.yaml ${backuploc}/suricata.eth4.yaml.${date}
cp /etc/suricata/suricata.eth5.yaml ${backuploc}/suricata.eth5.yaml.${date}

#Delete backups over 30days old
find ${backuploc}* -mtime +30 -exec rm {} \;

#Replace rule file entries
replace "/etc/suricata/suricata.eth1.yaml"
replace "/etc/suricata/suricata.eth2.yaml"
replace "/etc/suricata/suricata.eth3.yaml"
replace "/etc/suricata/suricata.eth4.yaml"
replace "/etc/suricata/suricata.eth5.yaml"

#Delete temp rules list
rm -f ${backuploc}/rules.tmp

#Restart all the Suricata
service suricata.eth1 restart
service suricata.eth2 restart
service suricata.eth3 restart
service suricata.eth4 restart
service suricata.eth5 restart

#Purge all old log files
/bin/bash /usr/local/bin/randomstorm/suricata-purge >> ${log}

#Update the update log
echo " The Suricata updater ran at "${date} >> ${log}
