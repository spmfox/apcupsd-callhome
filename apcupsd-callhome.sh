#!/bin/bash

#This script assumes that the following packages are in use and/or configured:
#logger
#apcupsd
#curl

#SMTP server credentials will be in plaintext, its probably a good idea to have a dedicated email account.
#cURL command can be modified to provide an external credential file.

#Options that need to be changed
opt_FromEmail=""				# Email address to sent from
opt_ToEmail=""					# Email address to send to
opt_SMTPserver=""				# cURL formatted SMTP server (smtp://mail.host.com:25 OR smtps://mail.host.com:465)
opt_SMTPcredentials=""				# Credentials for the SMTP server, in cURL format (user:password)
opt_TelegramBotToken=""                         # Token of Telegram Bot
opt_TelegramMessageID=""                        # ID of the Telegram conversation to post the alert to

# Less common options to change
opt_SendEmail="yes"				# If not set to yes, email wont be sent
opt_SendTelegram="yes"				# If not set to yes, Telegram message wont be sent
dir_TemporaryDirectory="/tmp/"			# Directory to put one file that will be deleted
file_EmailMessageFile="$dir_TemporaryDirectory/apcupsd-email.txt"

strScriptPath=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
strScriptName="${0##*/}"
strFullPath="$strScriptPath/$strScriptName"

var_ArgumentCounter=1
if [ "$#" -gt 0 ]; then
 while [ $var_ArgumentCounter -le $# ]; do
  str_CurrentArgument="'$'$var_ArgumentCounter"
  str_CurrentArgument=$(eval eval echo "$str_CurrentArgument")

  if echo "$str_CurrentArgument" |grep -q "onbattery"; then
   str_Subject="$HOSTNAME POWER LOSS!"
   logger "APCUPSD-CallHome: WARNING: Running on battery power!"
  fi

  if echo "$str_CurrentArgument" |grep -q "offbattery"; then
   str_Subject="$HOSTNAME Power Restored"
   logger "ACPUPSD-CallHome: INFO: Mains power has been restored."
  fi

  if echo "$str_CurrentArgument" |grep -q "doshutdown"; then
   str_Subject="$HOSTNAME POWER SHUTDOWN!"
   logger "ACPUPSD-CallHome: WARNING: System is being shutdown due to power loss!"
  fi

  if echo "$str_CurrentArgument" |grep -q "commfailure"; then
   str_Subject="$HOSTNAME UPS CONNECTION LOST!"
   logger "ACPUPSD-CallHome: WARNING: Communication with the UPS battery has been lost!"
  fi

  if echo "$str_CurrentArgument" |grep -q "commok"; then
   str_Subject="$HOSTNAME UPS Connection OK"
   logger "ACPUPSD-CallHome: INFO: Communication with the UPS battery has been restored."
  fi

  if echo "$str_CurrentArgument" |grep -q "loadlimit"; then
   str_Subject="$HOSTNAME UPS EXCEEDING LOAD!"
   logger "ACPUPSD-CallHome: WARNING: UPS indicates its load is being exceeded!"
  fi

  if echo "$str_CurrentArgument" |grep -q "changeme"; then
   str_Subject="$HOSTNAME UPS BATTERY PROBLEMS!"
   logger "ACPUPSD-CallHome: WARNING: UPS indicates the battery might need to be changed!"
  fi

  if echo "$str_CurrentArgument" |grep -q "emergency"; then
   str_Subject="$HOSTNAME UPS BATTERY PROBLEMS!"
   logger "ACPUPSD-CallHome: WARNING: UPS indicates the battery might need to be changed!"
  fi

  if echo "$str_CurrentArgument" |grep -q "failing"; then
   str_Subject="$HOSTNAME UPS BATTERY PROBLEMS!!"
   logger "ACPUPSD-CallHome: WARNING: UPS indicates the battery might need to be changed!"
  fi

  if echo "$str_CurrentArgument" |grep -q "create-event-files"; then
   printf '#!/bin/bash\n'"$strFullPath -onbattery" > /etc/apcupsd/onbattery; chmod 700 /etc/apcupsd/onbattery
   printf '#!/bin/bash\n'"$strFullPath -offbattery" > /etc/apcupsd/offbattery; chmod 700 /etc/apcupsd/offbattery
   printf '#!/bin/bash\n'"$strFullPath -doshutdown" > /etc/apcupsd/doshutdown; chmod 700 /etc/apcupsd/doshutdown
   printf '#!/bin/bash\n'"$strFullPath -commfailure" > /etc/apcupsd/commfailure; chmod 700 /etc/apcupsd/commfailure
   printf '#!/bin/bash\n'"$strFullPath -commok" > /etc/apcupsd/commok; chmod 700 /etc/apcupsd/commok
   printf '#!/bin/bash\n'"$strFullPath -loadlimit" > /etc/apcupsd/loadlimit; chmod 700 /etc/apcupsd/loadlimit
   printf '#!/bin/bash\n'"$strFullPath -changeme" > /etc/apcupsd/changeme; chmod 700 /etc/apcupsd/changeme
   printf '#!/bin/bash\n'"$strFullPath -emergency" > /etc/apcupsd/emergency; chmod 700 /etc/apcupsd/emergency
   printf '#!/bin/bash\n'"$strFullPath -failing" > /etc/apcupsd/failing; chmod 700 /etc/apcupsd/failing
   logger -s "ACPUPSD-CallHome: INFO: Created APCUPSD event files."
   exit
  fi

  let var_ArgumentCounter+=1
 done
else
 echo " "
 echo "Use of this script requires an argument, which coincides with an APCUPSD event. Supported arguments are below:"
 echo " "
 echo "-onbattery"
 echo "-offbattery"
 echo "-doshutdown"
 echo "-commfailure"
 echo "-commok"
 echo "-loadlimit"
 echo "-changeme"
 echo "-emergency"
 echo "-failing"
 echo " "
 echo "-create-event-files - This argument can be used to create the APCUPSD files automatically."
 echo " "
 exit
fi

str_CurrentPowerStatus=$(/sbin/apcaccess)

if [ "$opt_SendEmail" = "yes" ]; then
 printf "From: $opt_FromEmail\nTo: $opt_ToEmail\nSubject: $str_Subject\n\n$str_CurrentPowerStatus" > $file_EmailMessageFile
 str_EmailSendMessage=$(curl --ssl $opt_SMTPserver --user $opt_SMTPcredentials --mail-from $opt_FromEmail --mail-rcpt $opt_ToEmail --upload-file $file_EmailMessageFile)
 rm $file_EmailMessageFile
 logger -s "ACPUPSD-CallHome: INFO: Email triggered."
else
 logger -s "ACPUPSD-CallHome: INFO: Email not enabled so it was not triggered."
fi

if [ "$opt_SendTelegram" = "yes" ]; then
 str_TelegramMessage=$(echo $str_Subject; echo "=========="; echo -e $str_CurrentPowerStatus; echo "==========")
 str_TelegramGenerateMessageJSON=$(cat <<EOF
{"chat_id": "$opt_TelegramMessageID", "text": "$str_Subject
==========
$str_CurrentPowerStatus
=========="}
EOF
 )

 str_TelegramSendMessage=$(curl -s -X POST -H "Content-Type: application/json" -d "$str_TelegramGenerateMessageJSON" https://api.telegram.org/bot$opt_TelegramBotToken/sendMessage)
 logger -s "ACPUPSD-CallHome: INFO: Telegram message triggered."
else
 logger -s "ACPUPSD-CallHome: INFO: Telegram message not enabled so it was not triggered."
fi
