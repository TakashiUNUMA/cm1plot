#!/bin/sh

if test $# -lt 2
then
    echo "USAGE: $0 [org_file] [outfile]"
    exit
fi

file=$1
cm1out=$2

wind=1

### horizontal section
nx=`ncdump -h ${file} | grep "ni = " | awk '{print $3}'`
ny=`ncdump -h ${file} | grep "nj = " | awk '{print $3}'`
nz=`ncdump -h ${file} | grep "nk = " | awk '{print $3}'`
xint=1
yint=1
SLON=1
SLAT=1
ELON=${nx}
#ELAT=${ny}
ELAT=${nz}

# set grid interval
INT="${xint}/${yint}"

# set range
RANGE="${SLON}/${ELON}/${SLAT}/${ELAT}"

# xyz2grd
xyz2grd ${cm1out} \
    -G${cm1out%.out}.grd \
    -R${RANGE} \
    -I${INT} \
    -ZBLf

if test ${wind} -eq 1
then
    time=${cm1out:`expr ${#cm1out} - 16`:12}
    wind1=cm1out_uinterp_ft${time}.out
    wind2=cm1out_winterp_ft${time}.out
    
    xyz2grd ${wind1} \
	-G${wind1%.out}.grd \
	-R${RANGE} \
	-I${INT} \
	-ZBLf
    
    xyz2grd ${wind2} \
	-G${wind2%.out}.grd \
	-R${RANGE} \
	-I${INT} \
	-ZBLf
fi

lhixy="0.1/0.165"
hddi="a10f5"
hcbar="10.25/2.5/5.0/0.225"

echo " Now drawing ${cm1out}"
# GMT setting
gmtdefaults -D > .gmtdefaults4
gmtset HEADER_FONT_SIZE 12p
gmtset LABEL_FONT_SIZE  12p
gmtset ANOT_FONT_SIZE   10p
gmtset BASEMAP_TYPE     plain
gmtset TICK_LENGTH     -0.10c
gmtset FRAME_PEN        0.20p
gmtset GRID_PEN         0.20p
gmtset TICK_PEN         0.25p
gmtset MEASURE_UNIT     cm
gmtset PAPER_MEDIA      a4
gmtset VECTOR_SHAPE     2

gmtsta='-P -K'
gmtcon='-P -K -O'
gmtend='-P -O'

psfile=${cm1out%.out}.ps

gray=0
value="qc+qr+qg+qi+qs"
unucpt ${value} 0.5 0.6 0.5
#value="th"
#unucpt ${value} 290.0 380.0 5
if test ${gray} -eq 1
then
    CPALET=cpalet_${value}_g.cpt
    if test -s scale_${value}_g.cpt
    then
	SCALE=scale_${value}_g.cpt
    else
	SCALE=cpalet_${value}_g.cpt
    fi
    if test -s cscale_${value}_g.cpt
    then
	CSCALE=cscale_${value}_g.cpt
    else
	CSCALE=cpalet_${value}_g.cpt
    fi
else
    CPALET=cpalet_${value}.cpt
    if test -s scale_${value}.cpt
    then
	SCALE=scale_${value}.cpt
    else
	SCALE=cpalet_${value}.cpt
    fi
    if test -s cscale_${value}.cpt
    then
	CSCALE=cscale_${value}.cpt
    else
	CSCALE=cpalet_${value}.cpt
    fi
fi

PRG="x${lhixy}"
RANGE="100/200/${SLAT}/${ELAT}"

#grdimage ${cm1out%.out}.grd \
#    -J${PRG} \
#    -R${RANGE} \
#    -C${CPALET} \
#    -X1.2 -Y1.8 \
#    ${gmtsta} > ${psfile}

grdcontour ${cm1out%.out}.grd \
    -J${PRG} \
    -R${RANGE} \
    -C${CPALET} \
    -X1.2 -Y1.8 \
    ${gmtsta} > ${psfile}
#    ${gmtcon} >> ${psfile}

if test ${wind} -eq 1
then
    grdvector ${wind1%.out}.grd ${wind2%.out}.grd \
	-J${PRG} \
	-R${RANGE} \
	-S50 -Q0.01/0.2/0.1n0.5 -G0 -I5/2 \
	${gmtcon} >> ${psfile}
fi

psbasemap \
    -J${PRG} \
    -R${RANGE} \
    -B${hddi}WSne \
    ${gmtcon} >> ${psfile}

cbar=0
if test ${cbar} -eq 1
then
    gmtset FRAME_PEN 0.10p
    gmtset GRID_PEN  0.10p
    gmtset TICK_PEN  0.10p
    gmtset ANOT_FONT_SIZE 10p
    psscale -D${hcbar} \
	-C${SCALE} -L \
	${gmtcon} >> ${psfile}
fi

valunit=0
valname="[g/kg]"
if test ${valunit} -eq 1
then
    echo " 11.2 6.7 10 0.0 0 ML ${valname}" | pstext \
	-R1/100/1/100 -Jx1.0 -N ${gmtcon} >> ${psfile}
fi


datainfo=0
if test ${datainfo} -eq 1
then
    WE=`grep -i "WEST-EAST_GRID_DIMENSION" ${file} | awk '{print $7}'`
    SN=`grep -i "SOUTH-NORTH_GRID_DIMENSION" ${file} | awk '{print $7}'`
    LEVELS=`grep -i "BOTTOM-TOP_GRID_DIMENSION" ${file} | awk '{print $7}'`
    DX=`grep -i "DX = " ${file} | awk '{print $7}'`
    cu_physics=`grep -i "cu_physics" ${file} | awk '{print $7}'`
    mp_physics=`grep -i "mp_physics" ${file} | awk '{print $7}'`
    sf_sfclay_physics=`grep -i "sf_sfclay_physics" ${file} | awk '{print $7}'`
    sf_surface_physics=`grep -i "sf_surface_physics" ${file} | awk '{print $7}'`
    bl_pbl_physics=`grep -i "bl_pbl_physics" ${file} | awk '{print $7}'`
    diff_opt=`grep -i "diff_opt" ${file} | awk '{print $7}'`
    km_opt=`grep -i "km_opt" ${file} | awk '{print $7}'`
    initial_time=`grep -i "SIMULATION_START_DATE" ${file} | awk '{print $7}'`
    dir_info=`basename \`cd ../../ ; pwd\``

# Lavels (pstext)
# x     y   size angle font place comment
    cat << EOF | pstext -R1/100/1/100 -Jx1.0 -N ${gmtcon} >> ${psfile}
 1.0   0.4    5   0.0   8    ML    WE=${WE}, SN=${SN}, LEVELS=${LEVELS}, DX=${DX}, cu_physics=${cu_physics}, mp_physics=${mp_physics}
 1.0   0.2    5   0.0   8    ML    sf_sfclay_physics=${sf_sfclay_physics}, sf_surface_physics=${sf_surface_physics}, bl_pbl_physics=${bl_pbl_physics}diff_opt=${diff_opt}, km_opt=${km_opt}
 1.0   0.0    5   0.0   8    ML    Init=${initial_time}, EXPERIMENT_INFOMATION=${dir_info}
EOF
fi


# draw point
dpoint=0
lonp=140.1
latp=36.2
if test ${dpoint} -eq 1
then
    echo ${lonp} ${latp} | psxy \
        -J${PRG} \
        -R${RANGE} \
        -St0.25 \
        -W2,0/0/0 \
	-G0/0/0 \
        ${gmtcon} >> ${psfile}
fi

val0=`echo ${value} | tr "[:lower:]" "[:upper:]"`
length=${#cm1out}
lpoint=`expr ${length} - 16`
ftime=${cm1out:${lpoint}:12}
comment=""
# Lavels (pstext)
# x     y   size angle font place comment
cat << EOF | pstext -R1/100/1/100 -Jx1.0 -N ${gmtend} >> ${psfile}
 1.0   7.2   10   0.0   0    ML    CM1 ${val0} ${comment}
 11.0   7.2   10   0.0   0    MR    FT=${ftime}
# 1.5   8.0   25   0.0   0    ML    ${hgttype}
# 1.5   1.7   25   0.0   0    ML    ${hgttype}
 1.0   7.5    1   0.0   0    ML    .
EOF

#unurast_g ${psfile}
ps2raster -Tg -E144 -A ${psfile}
rm -f *.cpt
