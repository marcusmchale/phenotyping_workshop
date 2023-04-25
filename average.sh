#!/bin/bash

OUTDIR="/home/admin/hourly"

mkdir -p ${OUTDIR}

RAW_HOURLY=(/home/admin/raw/*h00m*)

for i in "${RAW_HOURLY[@]}"
do
  PATTERN_PATH=${i%h*}
  PATTERN=${PATTERN_PATH##*/}
  HOUR_STACK=(${PATTERN_PATH}*)
  HOURLY="${OUTDIR}/${PATTERN}_${HOSTNAME}.jpg"
  if [ ! -f ${HOURLY} ]
  then
    echo ${PATTERN} 
    convert ${HOUR_STACK} -evaluate-sequence median ${HOURLY} 
  fi
done
