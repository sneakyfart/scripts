#!/bin/sh
# NO CHANGES SHOULD BE MADE BEYOND THIS LINE #
##############
# PARAMETERS #
##############
USERNAME=""
PASSWORD=""
HOSTNAME=""
VMNAME=""
STORAGE=""
ARGS=( $@ )
#############
# FUNCTIONS #
#############
function display_usage() {
	IFS='' read -r -d '' usage <<'EOF'
		Usage: -h HOSTNAME -u USERNAME -p PASSWORD -vm VMNAME -s STORAGE
		HOSTNAME
			- ESXi hostname where VM is located. IP address will do too.
		USERNAME & PASSWORD
			- username and password used to authorize on ESXi host.
		VMNAME
			- .vmx file name. Usually coincides with VM name shown in ESXi but if VM
			was renamed they may differ. Better to check .vmx file name manually in ESXi datastore.
		STORAGE
			- path to a location where OVA will be stored. Have to be full path and not relative one.
EOF
	echo "$usage"
}

function parse_arguments() {
	for (( i = 0; i < ${#ARGS[@]}; i = i + 2 )); do
		case "${ARGS[$i]}" in 
			"-h")
				if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
					echo "ERROR: hostname is not specified. Aborting."
					display_usage
					exit 1
				else
					HOSTNAME=${ARGS[((i+1))]}
				fi
				;;
			"-u")
				if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
					echo "ERROR: username is not specified. Aborting."
					display_usage
					exit 1
				else
					USERNAME=${ARGS[((i+1))]}
				fi
				;;
			"-p")
				if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
					echo "ERROR: password is not specified. Aborting."
					display_usage
					exit 1
				else
					PASSWORD=${ARGS[((i+1))]}
				fi
				;;
			"-vm")
				if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
					echo "ERROR: vmname is not specified. Aborting."
					display_usage
					exit 1
				else
					VMNAME=${ARGS[((i+1))]}
				fi
				;;
			"-s")
				if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
					echo "ERROR: storage is not specified. Aborting."
					display_usage
					exit 1
				else
					STORAGE=${ARGS[((i+1))]}
				fi
				;;
			*)
				echo "ERROR: unexpected option. Aborting."
				display_usage
				exit 1
		esac
	done
}
