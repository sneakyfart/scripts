#!/bin/bash
##############
# PARAMETERS #
##############
# Define log directory here without trailing slash
LOG_DIR=""
##############################################
# NO CHANGES SHOULD BE MADE BEYOND THIS LINE #
##############################################
USERNAME=""
PASSWORD=""
HOSTNAME=""
VM_NAME=""
STORAGE=""
COMPRESS=""
DATE=`date +%Y-%m-%d`
LOG_FILE=""$LOG_DIR"/"$VM_NAME"_OVA_backup.log"
ARGS=( $@ )

#############
# FUNCTIONS #
#############
function write_log() {
	echo -en "$1" >> $LOG_FILE
}

function display_usage() {
	IFS='' read -r -d '' usage <<'EOF'
	Usage: -h HOSTNAME -u USERNAME -p PASSWORD -vm VM_NAME -s STORAGE -c COMPRESS
	HOSTNAME
		- ESXi hostname where VM is located. IP address will do too.
	USERNAME & PASSWORD
		- username & password used to authorize on ESXi host.
	VM_NAME
		- virtual machine name shown in ESXi GUI/web GUI. VM name and .vmx file name may differ
		if VM was renamed somewhere after creation.
	STORAGE
		- path to a location where OVA will be stored. Have to be full path and not relative one.
	COMPRESS
		- disks compress ratio. Value must be between 1 and 9. 1 is the fastest, but gives the worst 
		compression, whereas 9 is the slowest, but gives the best compression.
EOF
	echo "$usage"
}

function parse_arguments() {
	if [[ -n "$ARGS" ]]; then
		for (( i = 0; i < ${#ARGS[@]}; i = i + 2 )); do
			case "${ARGS[$i]}" in 
				"-h")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: hostname is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						HOSTNAME=${ARGS[((i+1))]}
						write_log "INFO: hostname is parsed.\n"
					fi
					;;
				"-u")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: username is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						USERNAME=${ARGS[((i+1))]}
						write_log "INFO: username is parsed.\n"
					fi
					;;
				"-p")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: password is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						PASSWORD=${ARGS[((i+1))]}
						write_log "INFO: password is parsed.\n"
					fi
					;;
				"-vm")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: vm_name is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						VM_NAME=${ARGS[((i+1))]}
						write_log "INFO: VM name is parsed.\n"
					fi
					;;
				"-s")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: storage is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						STORAGE=${ARGS[((i+1))]}
						write_log "INFO: storage location is parsed.\n"
					fi
					;;
				"-c")
					if [[ "`echo ${ARGS[((i+1))]} |head -c 1`" == "-" || "${ARGS[((i+1))]}" == "" ]]; then
						write_log "ERROR: compress ratio is not specified. Aborting.\n"
						display_usage
						exit 1
					else
						COMPRESS=${ARGS[((i+1))]}
						write_log "INFO: compress ratio is parced.\n"
					fi
					;;
				*)
					write_log "ERROR: unexpected option. Aborting.\n"
					display_usage
					exit 1
			esac
		done
	else
		write_log "ERROR: no arguments specified. Aborting.\n"
		display_usage
		exit 1
	fi
}

#function check_log_file() {
#	LOG="$LOG/"$VM_NAME"_OVA_backup.log"
#	if [[ -w $LOG ]]; then
#		
#	fi
#}

function get_vm_id() {
	write_log "INFO: getting $VM_NAME ID...\n"
	VM_LIST=`ssh $USERNAME@$HOSTNAME "vim-cmd vmsvc/getallvms | grep $VM_NAME; exit"`
	VM_ID=`echo $VM_LIST | awk '{print $1}'`
	if [[ -z "$VM_ID" ]]; then
		write_log "ERROR: cannot find an ID for VM $VM_NAME on host $HOSTNAME. Please check -vm and -h parameters.\n"
		exit 1
	else
		write_log "INFO: VM ID for $VM_NAME is $VM_ID.\n"
	fi
}

function power_off_vm() {
	write_log "INFO: trying to power off VM $VM_NAME...\n"
	VM_STATUS=`ssh $USERNAME@$HOSTNAME "vim-cmd vmsvc/power.getstate $VM_ID | tail -1; exit"`
	case "$VM_STATUS" in
		"Powered on")
			write_log "INFO: VM $VM_NAME is powered ON. Trying to power off...\n"
			PROCESS_LIST=`ssh $USERNAME@$HOSTNAME "esxcli vm process list; exit"`
			WORLD_ID=`echo $PROCESS_LIST | grep -A 1 $VM_NAME | grep "World ID" | awk '{print $4}'`
			S_PWR_OFF_STATUS=`ssh $USERNAME@$HOSTNAME "exscli vm process kill --type=soft --world-id=$WORLD_ID; echo $?"`
			if [[ "$S_PWR_OFF_STATUS" = "0" ]]; then
				write_log "INFO: VM $VM_NAME was powered off successfully.\n"
			elif [[ "$S_PWR_OFF_STATUS" = "1" ]]; then
				write_log "ERROR: soft power off for VM $VM_NAME has failed. Hard mode ON.\n"
				H_PWR_OFF_STATUS=`ssh $USERNAME@$HOSTNAME "exscli vm process kill --type=hard --world-id=$WORLD_ID; echo $?"`
				if [[ "$H_PWR_OFF_STATUS" = "0" ]]; then
					write_log "INFO: VM $VM_NAME was powered off hard successfully. This is a bad sign tho.\n"
					write_log "WARNING: data corruption is possible. Please check VM state manually.\n"
				elif [[ "$H_PWR_OFF_STATUS" = "1" ]]; then
					write_log "ERROR: hard power off for VM $VM_NAME has failed. Aborting.\n"
					write_log "WARNING: please check VM state manually.\n"
					exit 1
				else
					write_log "ERROR: unexpected hard power off attempt result. Aborting.\n"
					exit 1
				fi
			else
				write_log "ERROR: unexpected soft power off attempt result. Aborting.\n"
				exit 1
			fi
			;;
		"Powered off")
			write_log "INFO: VM $VM_NAME is powered OFF.\n"
			;;
		*)
			write_log "ERROR: unexpected VM status. Aborting.\n"
			write_log "INFO: please check VM $VM_NAME status manually.\n"
			write_log "INFO: or check the output of \"vim-cmd vmsvc/power.getstate $VM_ID\" command.\n"
			exit 1
	esac
}

function power_on_vm() {
	write_log "INFO: trying to power on VM $VM_NAME...\n"
	VM_STATUS=`ssh $USERNAME@$HOSTNAME "vim-cmd vmsvc/power.getstate $VM_ID | tail -1; exit"`
	case "$VM_STATUS" in
		"Powered on")
			write_log "ERROR: VM $VM_NAME is still powered ON. Aborting.\n"
			write_log "WARNING: INFO: please check script log above, VM $VM_NAME status and current tasks on host.\n"
			exit 1
			;;
		"Powered off")
			write_log "INFO: VM $VM_NAME is powered OFF. Trying to power on...\n"
			PWR_ON_STATUS=`vim-cmd vmsvc/power.on $VM_ID; echo $?`
			if [[ "$PWR_ON_STATUS" = "0" ]]; then
				write_log "INFO: VM $VM_NAME was powered on successfully.\n"
				#check S_PWR_OFF H_PWR_OFF and throw warning if hard was done
			elif [[ "$PWR_ON_STATUS" = "1" ]]; then
				write_log "ERROR: VM $VM_NAME wasn't powered on successfully. Aborting.\n"
				write_log "INFO: please check script log above, VM $VM_NAME status and current tasks on host.\n"
				exit 1
			else
				write_log "ERROR: unexpected power on attempt result. Aborting.\n"
				exit 1
			fi
			;;
		*)
			write_log "ERROR: unexpected VM status. Aborting.\n"
			write_log "INFO: please check VM $VM_NAME status manually.\n"
			write_log "INFO: or check the output of \"vim-cmd vmsvc/power.getstate $VM_ID\" command.\n"
			exit 1
	esac
}

########
# MAIN #
########
write_log "INFO: $DATE VM $VM_NAME OVA backup process has started.\n"
parse_arguments
get_vm_id
power_off_vm
#ovftool --compress $COMPRESS vi://$USERNAME:$PASSWORD@$HOSTNAME/$VM_NAME $STORAGE.ova
power_on_vm
write_log "INFO: $DATE VM $VM_NAME OVA backup process has finished.\n"