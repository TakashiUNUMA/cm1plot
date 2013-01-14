#!/bin/sh
#
# GrADS script for making binary data from cm1out.nc
# producted by Takashi Unuma, Kyoto Univ.
# Last modified: 2012/11/24
#

if test $# -lt 3
then
    echo "USAGE: $0 [file] [time] [var]"
    exit
fi

file=$1
input_date=$2
var=$3

#DATADIR=./

#lslon=`awk '$1=="MINLON,MAXLON" {print $3}' ${file}`
#lelon=`awk '$1=="MINLON,MAXLON" {print $4}' ${file}`
#lslat=`awk '$1=="MINLAT,MAXLAT" {print $3}' ${file}`
#lelat=`awk '$1=="MINLAT,MAXLAT" {print $4}' ${file}`

#iyy=`echo ${input_date} | cut -c1-4`
#imm=`echo ${input_date} | cut -c5-6`
#idd=`echo ${input_date} | cut -c7-8`
#ihh=`echo ${input_date} | cut -c9-10`
#inn=`echo ${input_date} | cut -c11-12`

#time=`jst2utc_grads ${input_date}`
#utctime=`jst2utc ${input_date} | cut -c1-8`
#utcyy=`echo ${utctime} | cut -c1-4`
#utcmm=`echo ${utctime} | cut -c5-6`

# input file check
if test ! -s cm1out.nc
then
    echo "There is no cm1out.nc ."
    exit
fi

# time format
input_date=`expr ${input_date} - 1`
if test ${input_date} -lt 10
then
    time="00000000000${input_date}"
elif test ${input_date} -ge 10 -a ${input_date} -lt 99
then
    time="0000000000${input_date}"
elif test ${input_date} -ge 100 -a ${input_date} -lt 999
then
    time="000000000${input_date}"
elif test ${input_date} -ge 1000 -a ${input_date} -lt 9999
then
    time="00000000${input_date}"
elif test ${input_date} -ge 10000 -a ${input_date} -lt 99999
then
    time="0000000${input_date}"
elif test ${input_date} -ge 100000 -a ${input_date} -lt 999999
then
    time="000000${input_date}"
elif test ${input_date} -ge 1000000 -a ${input_date} -lt 9999999
then
    time="00000${input_date}"
elif test ${input_date} -ge 10000000 -a ${input_date} -lt 99999999
then
    time="0000${input_date}"
elif test ${input_date} -ge 100000000 -a ${input_date} -lt 999999999
then
    time="000${input_date}"
elif test ${input_date} -ge 1000000000 -a ${input_date} -lt 9999999999
then
    time="00${input_date}"
elif test ${input_date} -ge 10000000000 -a ${input_date} -lt 99999999999
then
    time="0${input_date}"
elif test ${input_date} -ge 100000000000 -a ${input_date} -lt 999999999999
then
    time="${input_date}"
else
    echo "time error"
    exit
fi
input_date=`expr ${input_date} + 1`

echo "Processing time"
echo " TIME: ${time}"
echo " VAR = ${var}"

OUTPUT="cm1out_${var}_ft${time}.out"
echo " OUTPUT: ${OUTPUT}"
echo ""
cat << EOF > tmp_fwriteuv.gs 
'reinit'

var=${var}

'sdfopen cm1out.nc'
'set fwrite -le ${OUTPUT}'
'set gxout fwrite'
'set t ${input_date}'
'set z 1 36'
'set y 30'
#'set lon ${lslon} ${lelon}'
#'set lat ${lslat} ${lelat}'

#'q dims'
# loninfo = sublin(result,2)
# latinfo = sublin(result,3)
#  x1 = subwrd(loninfo,11)
#  x2 = subwrd(loninfo,13)
#  y1 = subwrd(latinfo,11)
#  y2 = subwrd(latinfo,13)

#z=1
#while(z<=16)
#  'set z 'z
#  'd aave(${var}, x='x1',x='x2', y='y1',y='y2')'
#  z=z+1
#endwhile

if( var="qc" | var="qr" | var="qg" | var="qi" | var="qs" | var="qv" )
  'd var*1000'
endif

if( var="water")
#  'd (qc+qr+qg+qi+qs)*1000'
  'd ave((qc+qr+qg+qi+qs)*1000, y=1, y=60, -b)'
endif

if( var="uinterp" | var="vinterp" )
#  'd ${var}'
  'd ave(${var}, y=1, y=60, -b)'
endif

if( var="winterp" )
#  'd ${var}*10'
  'd ave(${var}*10, y=1, y=60, -b)'
endif

'quit'
EOF

grads -blc tmp_fwriteuv.gs >& /dev/null 2>&1

#OUTPUTDIR=output/fmean
#mkdir -p ${OUTPUTDIR}
#mv ${OUTPUT} ${OUTPUTDIR}/

rm -f tmp_lst
rm -f fwrite_fm_val.sh~
rm -f tmp_fwriteuv.gs
