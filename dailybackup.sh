#!/bin/bash

#Please use crontab scheduling to make this script run daily
#Please Find More Informtion in README.txt

#################################
#		BEGIN OF CONFIG			#
#################################

#Set the local backup DIR
BACKDIR="/home/backups/daily"
#Source DIR
SOURCE_USR="/home/peiyuan"
SOURCE_SHDATA="/opt/shares"
SOURCE_VM="/opt/vmware/vm"

#Set Error Log DIR
LOG_DIR="backuplog.txt"
#Set Admin Email ADDR
EMAIL="Admin@admin.com"
#Initial verbosity mode
mode=0

#Set the verbosity
if [ "$1" = "-quiet" ]; then
    mode=1
elif [ "$1" = "-normal" ]; then
	mode=2
elif [ "$1" = "-debug" ]; then
	mode=0
elif [ $# != 0 ]; then
    # Invalid arguments
    echo "Usage: $0 [-quiet/-normal/-debug]"
    exit
fi

####### FOR DELETE ##############
FILEAGE=0


#################################
#		END OF CONFIG			#
#################################



#################################
#		CHECK STATUS			#
#################################
# This section checks for all of the binaries used in the backup
BINARIES=( cat cd date dirname echo pwd rm dar )

# Iterate over the list of binaries, and if one isn't found, abort
for BINARY in "${BINARIES[@]}"; do
    if [ ! "$(command -v "$BINARY")" ]; then
        echo "$BINARY is not installed. Install it and try again"
        exit
    fi
done


# Check if the backup folders exist and are writeable
if [ ! -w "${BACKDIR}" ]; then
    echo "${BACKDIR} either doesn't exist or isn't writable"
    echo "Either fix or replace the BACKDIR setting"
    exit
fi


#Then go to backup DIR
cd "${BACKDIR}" 
#Get Current DIR
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
touch ${LOG_DIR}

#################################
#		END CHECK				#
#################################




#################################
#		BACKUP FUNCTIONS		#
#################################


function darbackup(){
	local args="$1"
	local archive=""
	local stderr=""

    #Backup VMWares
    archive="$2.vmware"
    printf "$(date -u +%Y-%m-%d-%H%M):\n" > ${LOG_DIR}
	if ! stderr="$(dar $args $archive -R $SOURCE_VM >>${LOG_DIR})"
	then   #""
		echo "dar vmware failed"
		tail -1 "$BACKDIR/${LOG_DIR}"
		mail -s "$(date +%Y-%m-%d): Backup error occurred" $EMAIL < $SCRIPT_DIR/${LOG_DIR}
    else
        printf "dar vmware success \n\n" >> ${LOG_DIR}
	fi

    #Backup Shared Data 
    archive="$2.shared"
    printf "$(date -u +%Y-%m-%d-%H%M):\n" >> ${LOG_DIR}
    if ! stderr="$(dar $args $archive -R $SOURCE_SHDATA >>${LOG_DIR})"
    then
        echo "dar shared data failed"
        tail -1 "$BACKDIR/${LOG_DIR}"
        mail -s "$(date +%Y-%m-%d): Backup error occurred" $EMAIL < $SCRIPT_DIR/${LOG_DIR}
    else
        echo "dar shared data success " >> ${LOG_DIR}
    fi
    cat $BACKDIR/${LOG_DIR}
}


function backup(){
    CURRENT_TIME=$(date -u +%Y-%m-%d-%H%M)
case "$1" in
    0)
        darbackup "-v -c" "${BACKDIR}/${CURRENT_TIME}" #debug mode
        ;;
    1)
        darbackup "-q -c" "${BACKDIR}/${CURRENT_TIME}" #quiet mode
        ;;
    2)
        darbackup "-c"  "${BACKDIR}/${CURRENT_TIME}" #normal mode
        ;;
    *)
		echo "Error: Unknown backup Mode!" >> ${LOG_DIR}
		exit
		;;
esac
}

function getFileDate() {
    unset FILEYEAR FILEMONTH FILEDAY FILEDAYS FILEAGE
    FILEYEAR=$(echo "$1" | cut -b 1-4)
    FILEMONTH=$(echo "$1" | cut -b 6-7)
    FILEDAY=$(echo "$1" | cut -b 9-10)
        if [[ "${FILEYEAR}" && "${FILEMONTH}" && "${FILEDAY}" ]]
         then
            #Approximate a 30-day month and 365-day year
            FILEDAYS=$(( $((10#${FILEYEAR}*365)) + $((10#${FILEMONTH}*30)) + $((10#${FILEDAY})) ))
            FILEAGE=$(( 10#${DAYS} - 10#${FILEDAYS} ))
            return 0
        fi
    return 1 #File isn't a backup archive
}

function deleteBackups(){

    #Get current time
    DAY=$(date -u +%d)
    MONTH=$(date -u +%m)
    YEAR=$(date -u +%C%y)

    #Approximate a 30-day month and 365-day year
    DAYS=$(( $((10#${YEAR}*365)) + $((10#${MONTH}*30)) + $((10#${DAY})) ))

    # Count how many backups have been deleted/kept, and how much space has been saved/used
    NDELETED=0
    NKEPT=0
    SPACEFREED=0
    SPACEUSED=0

    cd "${BACKDIR}" || exit

    printf "\n\nStart to delete:\n" >> ${LOG_DIR}

    #Iterate over all .enc files
    for f in *.dar 
    do

        KEEPFILE="NO"
        getFileDate "$f"

        if [ $? == 0 ]  #getfiledate work well
        then
            if [[ ${FILEAGE} -gt 30 ]]
             then
                #Mark to be delete
                KEEPFILE="NO"
                NKEPT=$(( 10#${NKEPT} + 1 ))
                LS=($(ls -l "$f"))
                SPACEUSED=$(( 10#${SPACEUSED} + 10#${LS[4]} ))
            else
                KEEPFILE="YES"
                NKEPT=$(( 10#${NKEPT} + 1 ))
                LS=($(ls -l "$f"))
                SPACEUSED=$(( 10#${SPACEUSED} + 10#${LS[4]} ))
            fi

            if [ ${KEEPFILE} == "NO" ]
             then
                # delete it
                NDELETED=$(( 10#${NDELETED} + 1 ))
                LS=($(ls -l "$f"))
                SPACEFREED=$(( 10#${SPACEFREED} + 10#${LS[4]} ))
                rm -f "$f"
                echo "$f DELETED"  >> ${LOG_DIR}
            fi

        fi
    done

    echo "Deleted ${NDELETED} backups, freeing ${SPACEFREED} Byte" >> ${LOG_DIR}
    echo "${NKEPT} backups remain, taking up ${SPACEUSED} Byte" >> ${LOG_DIR}
    cat ${LOG_DIR}

}







#################################
#	HERE IS THE MAIN FUNCTION	#
#################################

backup "$mode"
deleteBackups
