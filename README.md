# apcupsd-callhome

## Why
I wanted an Telegram message and email when the power went out at any of my sites.

## How
There are only two requirements here, SMTP server for sending emails and Telegram API + ConversationID for sending the messages to Telegram.

It works by changing the default scripts that come with apcupsd, setting those scripts to call our script. From our one script, we can send emails and Telegram messages regarding all of the power messages that apcupsd can send.

Normally apcupsd has a script for each condition, so it can be a little tedious to edit and maintain each one. Thus, each script just calls our script with the specific condition.

## Telegram
I can't cover the methods of creating Bots or getting your conversation ID from Telegram because these methods may change in the future. Here are the basic steps:
1. Create Telegram Bot, get the Bot Token ID
2. Create a conversation or channel, get the ID

## Installation & Usage
* Clone git repository
  * `git clone git@github.com:spmfox/apcupsd-callhome.git`
* Movie directory to wherever you want it to run from
  * `mv apcupsd-callhome /opt/`
* Set root ownership
  * `sudo chown -R root:root /opt/apcupsd-callhome`
* Set execute bit on main script
  * `sudo chmod 700 /opt/apcupsd-callhome/apcupsd-callhome.sh`
* Install SELinux module (if using SELinux)
  * `sudo semodule -i /opt/apcupsd-callhome/apcupsd-callhome-selinux.pp`
* Configure apcupsd to call our script on each alert
  * `sudo /opt/apcupsd-callhome/apcupsd-callhome.sh -create-event-files`
* Edit the following variables:

| Variable | Purpose |
| ---------| ------- |
|opt_FromEmail|Email address to sent from|
|opt_ToEmail|Email address to send to|
|opt_TelegramBotToken|Token of Telegram Bot|
|opt_TelegramMessageID|ID of the Telegram conversation to post the alert to|


## Troubleshooting
