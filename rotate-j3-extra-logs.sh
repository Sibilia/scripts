#!/bin/bash
#
# usage:
# /opt/pmm-bms/sbin/rotate-j3-extra-logs.sh /opt/just
#

EngineDir=$1
EngineName=$(basename $EngineDir)
LogsDir="$EngineDir/log"
ArcDir='/home/bms-backup/.engines-logs/J3-extra-logs'
HostName=$(hostname)
LogFile=$(dirname $ArcDir)'/log-rotate-'${EngineName}'-extra.log'
MaxLogFStr='1024'
MaxLogSize=$((1024*1024*1024*25))       # 25 Gb
NumberFile=700

ActualDirName=$(date '+%Y-%m-%d')

log() {
        echo "$(date '+%Y-%m-%d %H:%M') $1" >> $LogFile
}
#####################################################################
if [[ "$(du -b $LogsDir/$ActualDirName| cut -f1)" -lt "$MaxLogSize" ]]; then
        log "start false: size $(du -h "$LogsDir/$ActualDirName"| cut -f1)"
        exit 0
else
        log "start true: size $(du -h "$LogsDir/$ActualDirName"| cut -f1)"
        echo "start true: size $(du -h "$LogsDir/$ActualDirName"| cut -f1)"
fi
###################

if [ ! -d "$ArcDir" ]; then
        mkdir -p $ArcDir
fi

if [ -f "$LogFile" ]; then
        CurLogStrs=$(cat $LogFile | wc -l)
        if [ "$CurLogStrs" -gt "$MaxLogFStr" ]; then
                mv -f ${LogFile} ${LogFile}'.0'
        fi
else
        touch $LogFile
fi

log "   Engine: $EngineName"
log "EngineDir: $EngineDir"
log "  LogsDir: $LogsDir"
log "   ArcDir: $ArcDir"

find "$LogsDir/$ActualDirName" -type f -name "??????_[0-9]*.log" > /dev/shm/temp.$EngineName.1

prev_start=
if [ -e "$ArcDir/$EngineName-on-$HostName-$ActualDirName-00.tar.gz" ]; then
        prev_start=$(ls -la $ArcDir/$EngineName-on-$HostName-$ActualDirName-* |wc -l)
else
        prev_start=0
fi

sect=1
parts=$(( $(cat /dev/shm/temp.$EngineName.1 |wc -l)/$NumberFile))
for i in $(seq -f %02.0f $prev_start $(( $parts + $prev_start )) ) ; do
        log_files=$(head -n $NumberFile /dev/shm/temp.$EngineName.1)
        echo "create $sect/$((parts + 1)) archive file"
        tar -czf "$ArcDir/$EngineName-on-$HostName-$ActualDirName-$i.tar.gz" $log_files >> "$LogFile"
        if [ "$?" -ne "0" ]; then
                log "ERROR create $sect/$((parts + 1)) archive file: $EngineName-on-$HostName-$ActualDirName-$i.tar.gz"
                log "Exit"
                log "---------------------------------------------------------------"
                rm -f /dev/shm/temp.$EngineName.1
                exit 0
        fi

        log "create $sect/$((parts + 1)) archive file: $EngineName-on-$HostName-$ActualDirName-$i.tar.gz"
        rm -f $log_files
        ((sect++))
        sed "1,$NumberFile d" /dev/shm/temp.$EngineName.1 > /dev/shm/temp.$EngineName.2
        mv /dev/shm/temp.$EngineName.2 /dev/shm/temp.$EngineName.1
done
echo "end rotate $EngineName logs"

rm -f /dev/shm/temp.$EngineName.1

log "End rotate J3 extra log"
log "---------------------------------------------------------------"

