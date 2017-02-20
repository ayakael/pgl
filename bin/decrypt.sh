#!/usr/bin/bash
#
# Author Ayakael (Antoine Martin)
# Copyright (c) 2016-2017 Antoine Martin <antoine.martin@protonmail.com>
# Distributed under the GNU Affero General Public License (AGPL v3)
# See LICENSE or http://www.gnu.org/licenses/agpl.html
#

# Global variables
VERSION="0.5.2"
STDERR=$(mktemp /tmp/STDERR.XXXXXXXXXX)
INDENT=0
WARN=false
driveArray=()
o_kch=false
o_efi=false
o_cfg=false
o_mkcfg=false

function log {
		if [ ${1} = "INDENT" ]; then
			if [ -z "${1}" ]; then
				INDENT="0"
			else
				shift
				INDENT=$((${INDENT} ${1} *6 ))
			fi
		elif [ ${1} = "EXEC" ]; then
			shift
			echo -en "$(tput cuf "${INDENT}") [      ] ${1}\n"
		elif [ ${1} = "OK" ]; then
			if [ -z "${2}" ]; then
				HEIGHT=1
			else
				HEIGHT=$(( ${2} + 1))
			fi
			echo -en "$(tput cuu "${HEIGHT}")$(tput cuf "${INDENT}") [$(tput bold)$(tput setaf 2)  OK  $(tput sgr0)]$(tput cub 100)$(tput cud "${HEIGHT}")"
		elif [ ${1} = "WARN" ]; then
			shift;
			if [ -z "${2}" ]; then
				HEIGHT=1
			else
				HEIGHT=$(( ${2} + 1))
			fi
			echo -en "$(tput cuu "${HEIGHT}")$(tput cuf "${INDENT}") [$(tput bold)$(tput setaf 3) WARN $(tput sgr0)]"
			echo -en "\n$(tput cuf "${INDENT}") [>>>>>>] ${1} \n"
			if [ -n "${STDERR}" ]; then
				cat ${STDERR}
			fi
			rm ${STDERR}
			STDERR=$(mktemp /tmp/STDERR.XXXXXXXXXX)
			echo -en "$(tput cub 100)$(tput cud "${HEIGHT}")"
		elif [ ${1} = "FAIL" ]; then
			shift;
			if [ -z "${2}" ]; then
				HEIGHT=1
			else
				HEIGHT=$(( ${2} + 1))
			fi
			echo -en "$(tput cuu "${HEIGHT}")$(tput cuf "${INDENT}") [$(tput bold)$(tput setaf 1) FAIL $(tput sgr0)]"
			echo -en "\n$(tput cuf "${INDENT}") [>>>>>>] ${1} \n"
			if [ -n "${STDERR}" ]; then
				cat ${STDERR}
			fi
			rm ${STDERR}
			STDERR=$(mktemp /tmp/STDERR.XXXXXXXXXX)
			echo -en "$(tput cuf "${INDENT}") [      ] Fatal error reported. Press any key to shutdown." 
			read -n 1 -s
			echo -en "$(tput cub 100)$(tput cuf "${INDENT}") ["
			TIME=3
			while [ ${TIME} -ne 0 ]; do
				sleep 1;
				echo -en "||"
				TIME=$(( ${TIME}-1 ))
			done
			echo -en "\n$(tput cub 100)$(tput cud "${HEIGHT}")"
			exit
		elif [ ${1} = "ECHO" ]; then
			shift
			echo -e "$(tput cuf "${INDENT}") [======] ${1}"
		fi
	}

function cfg_loader {

	if [ -z "${CFG}" ]; then
		CFG="/tmp/decrypt/mnt/decrypt/decrypt.cfg"
	fi
	if [ -z "${EFI}" ]; then
		EFI="/dev/disk/by-partlabel/EFI"
	fi
	log EXEC "Loading decrypt.cfg"
	mkdir -p /tmp/decrypt/mnt
	if [ "${o_cfg}" == false ]; then
		mount -r -t vfat "${EFI}" /tmp/decrypt/mnt >${STDERR} 2>&1
		if [ $? == 0 ]; then
			echo -n
		else
			log FAIL "Could not mount EFI partition"
		fi
	fi
	if [ -e "${CFG}" ]; then
		if egrep -q -v '^#|^[^ ]*=[^;]*' "${CFG}"; then
			log WARN "Unclean config detected. Someone may be doing something weird. Cleaning and then echoing"
			egrep '^#|^[^ ]*=[^;&]*'  "${CFG}" > "/tmp/decrypt/decrypt.cfg"
			cat "/tmp/decrypt/decrypt.cfg"
			log ECHO "If it looks good, press any key to continue. If not, exit and clean it manually"
			read -n 1 -s
			source /tmp/decrypt/decrypt.cfg
		else
			log OK
			dd if=${CFG} of=/tmp/decrypt/decrypt.cfg >/dev/null 2>&1
			source /tmp/decrypt/decrypt.cfg
		fi
		if [ "${o_cfg}" == false ]; then
			umount /tmp/decrypt/mnt
		fi
	else
		log FAIL "Could not find decrypt.cfg."
	fi
}

function cfg_generator {
	log 
}

function help {
	case ${1} in
		# Help for decrypt open
		open)
			echo -e "\033[1A
Usage: decrypt open

Opens encrypted drive array

Opens encrypted drive array and mounts them to /dev/mapper/<partlabel> using the
configuration file and keychain key found in the EFI partition (Any partition 
with 'EFI' as partlabel) in the ./decrypt subfolder. If there's no key drive,
a password will be requested.
"
			exit
		;;

		# Help for decrypt close
		close)
			echo -e "\033[1A
Usage: decryt close

Closes encrypted drive array

Closes encrypted drive array, which implies unmounting them from /dev/mapper/<partlabel>.
If the partitions are mounted to the local filesystem, this action will fail.
"
		;;

		# Help for decrypt create
		create)
			echo -e "\033[1A
Usage: decrypt create [--config-only=<output>] <keydrive> <efi> <devices>

Creates encrypted drive array

Creates encrypted drive array with the devices defined at the endby first generating a 
keydrive and a decypt subfolder in the efi partition. In this folder, a config file and 
a keychain key will be generated as well. The keychain key is used to unlock the keydrive. 
The config file is used to know what drives to open and which keydrive is used (Both via 
the partition UUIDs). 

For an encrypted drive array to be created, a few things must be done:
   * A partition with a PARTLABEL called 'EFI' formatted as FAT32. In the standard configuration,
     the EFI partition will also be where the boot files will live
   * An unformatted key-drive (Any removable device with a minimum of 4MB of unformatted space)
   * Unformatted partitions that will be encrypted
   * Use of the GPT partition scheme.

--config-only=<output>
	This will only generate a config file
"
		;;

		# Help for decrypt addkey
		addkey)
			echo -e "\033[1A
Usage: decrypt addkey <key-drive> 

Add a keydrive to the drive array
"
		;;

		# Help for decrypt --info
		info)
			echo -e "\033[1A
Decrypt v${VERSION}
Copyright (c) 2016-2017 Antoine Martin <antoine.martin@protonmail.com>

Distributed under the GNU Affero General Public License (AGPL v3)
See LICENSE or http://www.gnu.org/licenses/agpl.html
"
		;;
	
		# Help for decrypt --help
		*)
			echo -e "\033[1A
Usage: decrypt [--help] [--info] [<options>] <command> [<args>]

Options
   --config=</path/to/config> 
      In a setup where no EFI partition exists, or is not usable, you can manually
      specify the location of the configuration file. This is usually used in a recovery 
      setting. Requires --keychain to be called. Ignored if command is 'decrypt create'
   --keychain=</path/to/keychain>
      In a setup where no EFI partition exists, or is not usable, you can manually
      specify the location of the keychain. This is usually used in a recovery setting.
      Requires --config to be called. Ignored if 'decrypt create' is called.
   --efi-partition=</path/to/efi/device>
      In a setup with multiple partitions that has EFI as partlabel, this option
      manually defines the efi partition. Within this partition, it will look 
      for decrypt.cfg and kch in the ./decrypt subfolder. Ignored if 'decrypt create'
      is called. Ignored if --keychain or --config is called.

Commands
   open
      Opens encrypted drive array
   close
      Closes encrypted drive arra
   create [--config-only=<output>] <keydrive> <efi> <devices> 
      Creates an encrypted drive array
      NOTICE: Full drive array creation not yet supported, --config-only is forced on
   addkey <new-keydrive>
      Add a keydrive to the drive array
      NOTE: Function not supported yet
   remkey <old-keydrive>
      Remove a keydrive from the drive array
      NOTE: Function not supported yet
"
		;;
	esac
}

#Recursive argument parser
while true; do
	case ${1} in
		--help)
			help
			exit
		;;

		--info)
			help info
			exit
		;;

		--config=*)
			if [ -z "${1#*=}" ]; then
				help
			else
				log ECHO "--config called. Config file location defined as: ${1#*=}"
				CFG="${1#*=}"
				o_cfg=true
			fi							
		;;

		--keychain=*)
			if [ -z "${1#*=}" ]; then
				help
			else
				log ECHO "--keychain called. Keychain file location defined as: ${1#*=}"
				KCH="${1#*=}"
				o_kch=true
			fi
		;;

		--efi-partition=*)
			if [ -z "${1#*=}" ]; then
				help
			else
				log ECHO "--efi-partition called. EFI partition defined as: ${1#*=}"
				EFI="${1#*=}"
				o_efi=true
			fi
		;;

		*)
			break
		;;

	esac
	shift
done

#Level 1 argument parser
case ${1} in
	open)
		shift
		log ECHO "Executing decryption script"
		cfg_loader
		if [ -z ${kd[@]+x} ]; then
			KEYDRIVE_NAME=KCH
			if [ -z "${KCH}" ]; then
				mount -r -t vfat "/dev/disk/by-partlabel/EFI" /tmp/decrypt/mnt > ${STDERR} 2>&1
				if [ $? == 0 ]; then
					KCH="/tmp/decrypt/mnt/decrypt/kch"
				else
					log FAIL "Could not mount EFI partition"
				fi
			fi
			dd if="${KCH}" of="/tmp/decrypt/kch" > /dev/null 2>&1
			if [ $? == 1 ]; then
				log FAIL "Could not find keychain"
			fi
			log EXEC "Please input password"
			while true; do
				read -s PASSWD
				printf "%s" "${PASSWD}" | cryptsetup luksOpen "/tmp/decrypt/kch" ${KEYDRIVE_NAME} > ${STDERR} 2>&1
				if [ $? == 0 ]; then
					log OK	
					break
				elif [ $? == 1 ] || [ $? == 2 ]; then
					log WARN "Keychain decryption failed."
					log EXEC "Please input password again"
				else
					log FAIL "Keychain decrypting failed"
				fi
			done
		else
			log EXEC "Looking for keydrive"
			while true; do
				currentDrive=1
				for i in ${kd[@]// /:}; do
					# Value extractor
					currentArray=$(echo "${i}" | sed "s/\:/ /g")
					currentArray=(${currentArray})
					if [ ${#currentArray[@]} != 1 ]; then
						echo "${currentArray[@]}" > ${STDERR}
						log FAIL "Bad configuration, expected only 1 element, echoing variables for keydrive ${currentDrive}"

					fi
					dd if="/dev/disk/by-partuuid/${currentArray[0]}" of="/tmp/decrypt/keychain" >/dev/null 2>&1
					if [ $? == 0 ]; then
						KEYDRIVE_NAME=$(lsblk --output=PARTLABEL /dev/disk/by-partuuid/${currentArray[0]} | sed '2q;d')
						log OK
						log INDENT +1
						log EXEC "Extracting keys from ${KEYDRIVE_NAME}"
						if [ -z "${KCH}" ]; then
							mount -r -t vfat "/dev/disk/by-partlabel/EFI" /tmp/decrypt/mnt > ${STDERR} 2>&1
							KCH="/tmp/decrypt/mnt/decrypt/kch"
						fi
						dd if="${KCH}" of="/tmp/decrypt/kch" >/dev/null 2>&1
						if [ $? == 1 ]; then
							log FAIL "Could not find keychain"
							break 2
						fi
						cryptsetup -d "/tmp/decrypt/kch" open --type plain "/tmp/decrypt/keychain" "${KEYDRIVE_NAME}" > ${STDERR} 2>&1
						if [ $? == 0 ]; then
							log OK	
							break 2
						else
							log FAIL "Keychain decryption failed."
							break 2
						fi
					fi
					currentDrive=$((${currentDrive} +1))
				done
				sleep 0.5
			done
		fi
		log EXEC "Opening drives..."
		log INDENT +1
		currentDrive=1
		for i in ${ed[@]// /:}; do
			log EXEC "Opening drive ${currentDrive}"
			# Value extractor
			currentArray=$(echo "${i}" | sed "s/\:/ /g")
			currentArray=(${currentArray})
			if [ ${#currentArray[@]} != 3 ]; then
				echo "${currentArray[@]}" > ${STDERR}
				log FAIL "Bad configuration file, expected 3 elements, echoing variables for drive ${currentDrive}"
			fi
			# Device name extractor
			DEVICE_NAME=$(lsblk --output=PARTLABEL /dev/disk/by-partuuid/${currentArray[0]} | sed '2q;d')
			# Open cryptdevice
			cryptsetup -d "/dev/mapper/${KEYDRIVE_NAME}" --keyfile-offset=${currentArray[1]} --keyfile-size=${currentArray[2]} luksOpen "/dev/disk/by-partuuid/${currentArray[0]}" "${DEVICE_NAME}" > ${STDERR} 2>&1 &
			cryptsetup_pid[${currentDrive}]=$!
			currentDrive=$((${currentDrive} +1))
		done
		waitDrive=1
		for i in ${ed[@]// /:}; do
			wait ${cryptsetup_pid[${waitDrive}]}
			if [ $? == 0 ]; then
				log OK $(if [ ${currentDrive} == 2 ]; then echo ""; else echo "$(( ${currentDrive} - 2 ))"; fi)
			else
				log WARN "Drive ${curentDrive} open failed" $(if [ ${currentDrive} == 2 ]; then echo ""; else echo "$(( ${currentDrive} - 2 ))"; fi)
				WARN=true
			fi
			currentDrive=$((${currentDrive} -1))
		done
		log INDENT -1
		cryptsetup close ${KEYDRIVE_NAME}
		if [ ${WARN} == true ]; then
			log ECHO "Non-fatal errors have occured. Some drives may not have opened properly, proceed with caution" ${#ed[@]}
		else
			log OK ${#ed[@]}
			log INDENT -1
			log ECHO "Decryption script complete"
		fi
		if [ "${o_cfg}" == false ]; then
			umount /tmp/decrypt/mnt
		fi

	;;

	close)
		shift
		cfg_loader
		log EXEC "Closing drives..."
		log INDENT +1
		currentDrive=1
		for i in ${ed[@]// /:}; do
			log EXEC "Closing drive ${currentDrive}"
			# Value extractor
			currentArray=$(echo "${i}" | sed "s/\:/ /g")
			currentArray=(${currentArray})
			if [ ${#currentArray[@]} != 3 ]; then
				echo "${currentArray[@]}" > ${STDERR}
				log FAIL "Bad configuration file, expected 3 elements, echoing variables for drive ${currentDrive}"
			fi

			# Device name extractor
			DEVICE_NAME=$(lsblk --output=PARTLABEL /dev/disk/by-partuuid/${currentArray[0]} | sed '2q;d')
			# Open cryptdevice
			cryptsetup close "/dev/mapper/${DEVICE_NAME}" > ${STDERR} 2>&1
			if [ $? == 0 ]; then
				log OK
			else
				log WARN "Drive ${curentDrive} close failed"
				WARN=true
			fi
			currentDrive=$((${currentDrive} +1))
		done
		log INDENT -1
		if [ ${WARN} == true ]; then
			log ECHO "Non-fatal errors have occured. Some drives may not have closed properly, proceed with caution" ${#ed[@]}
		else
			log OK ${#ed[@]}
		fi
	;;

	create)
		#TODO: Support full disk generation. For now, config generator only.
		o_mkcfg=true
		shift
		# Options parser
		case ${1} in
			--config-only=*)
				if [ -z "${1#*=}" ]; then
					help
				else
					log ECHO "--config-only called. Config generation output defined as: ${1#*=}"
					MKCFG="${1#*=}"
					o_mkcfg=true
					shift
				fi
			;;

		esac

		# Variable parser
		KEYDRIVE=${1}
		EFI=${2}

		while true; do
			case ${3} in
				/dev*)
					driveArray=(${driveArray[@]} ${3})
				;;

				*)
					break
				;;
			esac
			shift
		done
		
		# Sanity check
		log EXEC "Sanity checking..."
		if [ -b ${KEYDRIVE} ]; then
			if [ -z "$(lsblk --output=FSTYPE ${KEYDRIVE} | sed '2q;d'| sed 's/\ //g')" ]; then
				echo -n
			else
				log FAIL "Requires ${KEYDRIVE} to be unformatted to be used as Keydrive"
			fi
		else
			log FAIL "${KEYDRIVE} block device does not exist"
		fi
		if [ -b ${EFI} ]; then
			if [ $(lsblk --output=FSTYPE ${EFI} | sed '2q;d'| sed 's/\ //g') == vfat ]; then
				echo -n
			else
				log FAIL "Requires ${EFI} to be formatted to vfat (F32) to be used as EFI partition"
			fi
		else
			log FAIL "${EFI} block device does not exist"
		fi
		for i in ${driveArray[@]}; do
			if [ -b ${i} ]; then
				if [ -z "$(lsblk --output=FSTYPE ${i} | sed '2q;d'| sed 's/\ //g')" ]; then
					echo -n
				else
					log FAIL "Requires ${i} to be unformatted to be used as encrypted drive"
				fi
			else
				log FAIL "${i} block device does not exist"
			fi
		done
		log OK
		
		# Notice
		log ECHO "Notice: You are about to create an encrypted drive array with the following devices:"
		log INDENT +1
		log ECHO "EFI Partion:	${EFI}, $(lsblk --output=SIZE ${EFI} | sed '2q;d'| sed 's/\ //g'), $(lsblk --output=FSTYPE ${EFI} | sed '2q;d'| sed 's/\ //g')"
		log ECHO "Keydrive 1:	${KEYDRIVE}, $(lsblk --output=SIZE ${KEYDRIVE} | sed '2q;d' | sed 's/\ //g'), $(lsblk --output=FSTYPE ${KEYDRIVE} | sed '2q;d' | sed 's/\ //g')"
		currentDrive=1
		for i in ${driveArray[@]}; do
			log ECHO "Drive ${currentDrive}:	${i}, $(lsblk --output=SIZE ${i} | sed '2q;d'| sed 's/\ //g'), $(lsblk --output=FSTYPE ${KEYDRIVE} | sed '2q;d' | sed 's/\ //g')"
			currentDrive=$((${currentDrive} + 1))
		done
		log INDENT -1
		log ECHO "WARNING!"
		log INDENT +1
		log ECHO "This will overwrite data on all of these devices"
		log EXEC "Are you sure? (Type uppercase yes): "
		echo -en "\033[1A\033[53C"
		read confirm
		if [ ${confirm} == "YES" ]; then
			log OK
		else
			log FAIL "Input was not YES, exiting"
		fi
		log INDENT -1
		# Config generator
		log ECHO "Generating config file to EFI partition"
		log INDENT +1
		if [ -d "/tmp/decrypt" ]; then
			echo -n
		else
			mkdir /tmp/decrypt
		fi
		# Checks and mounts EFI partition
		if [ ${o_mkcfg} == false ]; then
			log EXEC "Mounting EFI partition"
			mount -t vfat "${EFI}" /tmp/decrypt/ >${STDERR} 2>&1
			if [ $? == 0 ]; then
				log OK
				log EXEC "Checking if decrypt.cfg already exists..."
				if [ -f "/tmp/decrypt/decrypt/decrypt.cfg" ]; then
					log WARN "decrypt.cfg already exists, renamed to decrypt.cfg.old"
					mv /tmp/decrypt/decrypt/decrypt.cfg /tmp/decrypt/decrypt/decrypt.cfg.old
					CFG="/tmp/decrypt/decrypt/decrypt.cfg"
				else
					CFG="/tmp/decrypt/decrypt/decrypt.cfg"
					log OK
				fi
			else
				log FAIL "Could not mount EFI partition"
			fi
		else
			CFG="${MKCFG}"
		fi
		log EXEC "Generating..."
		# Echo burst
		echo "#!/usr/bin/ash" > ${CFG}
		currentDrive=1
		for i in ${driveArray[@]}; do
			echo "sd[${currentDrive}]=$(lsblk --output=PARTUUID ${i} | sed '2q;d'| sed 's/\ //g') $((RANDOM%4194304+1)) 2048" >> ${CFG}
			currentDrive=$((${currentDrive} + 1))
		done
		echo "kd[1]=$(lsblk --output=PARTUUID ${KEYDRIVE} | sed '2q;d'| sed 's/\ //g')" >> ${CFG}
		log OK
		log INDENT -1
		if [ ${o_mkcfg} == false ]; then
			log EXEC "Generating keychain key"
			dd if=/dev/urandom of=/tmp/decrypt/decrypt/kch bs=512 count=4 > /dev/null 2>&1
			log OK
			cfg_loader
			log EXEC "Formatting drives"
			INDENT +1
			log EXEC "Keydrive..."
		fi
	;;

	addkey)
		#TODO: Code this function
		shift
		help
	;;

	remkey)
		#TODO: Code this function
		shift
		help
	;;

	*)
		help
	;;
esac
