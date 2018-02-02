#!/bin/bash
# Universal backup rotation script
# Author: Kirill Yuferev, kyuferev@mera.ru
# Additional email: yuferev.k@protonmail.ch
# Version: 0.1
##############
# PARAMETERS #
##############
LOG_DIR=""
##############################################
# NO CHANGES SHOULD BE MADE BEYOND THIS LINE #
##############################################
DATE=`date +%F@%T | sed "s/://g"`
DAY=`date +%A`

#############
# FUNCTIONS #
#############
function write_log() {
	echo -en "$1" >> "$LOG_FILE"
}