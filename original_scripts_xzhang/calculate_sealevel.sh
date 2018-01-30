  #!/bin/bash
pre=0; # extract the 35ka BP time series from Lev's reconstruction and calculate the ice volume
if [[ $pre = 1 ]]
then
cdo gridarea GLAC1DHiceF40.nc GLAC1DHiceF40_area.nc
# calculate the eqi. water volume
cdo  -mulc,0.9167 -mul GLAC1DHiceF40.nc GLAC1DHiceF40_area.nc GLAC1DHiceF40_Vol.nc
cdo -settaxis,0000-12-31,12:00,1year GLAC1DHiceF40_Vol.nc temp
cdo -selyear,50/401 temp temp2
#ncap2 -O -s 'lon=lon-360' temp2 temp3
cdo -settaxis,0000-12-31,12:00,1year temp2 GLAC1DHiceF40_Vol_35ka.nc
rm -fr temp temp2 temp3
fi

# extract the area where there is ice volume change
vol=0;
if [[ $vol = 1 ]]
then
  cdo griddes GLAC1DHiceF40_Vol_35ka.nc > Hice.grid
  cdo -settaxis,0000-12-31,12:00,1year -remapcon,Hice.grid -selvar,ICEM TOPicemsk.GLACD35kN9894GE90227A6005GGrBgic.nc mask.nc
  cdo mul GLAC1DHiceF40_Vol_35ka.nc mask.nc 35ka_ice_volume_mask.nc
else
  echo "don't calculate MASKED ice volume"
fi

# calculate DH/DT
dh=1;
if [[ $dh = 1 ]]
then
  cdo -s -selyear,0/349 35ka_ice_volume_mask.nc temp1
  cdo -s -settaxis,0000-12-31,12:00,1year temp1 1
  cdo -s -selyear,1/350 35ka_ice_volume_mask.nc temp1
  cdo -s -settaxis,0000-12-31,12:00,1year temp1 2
  cdo -s -sub 2 1 35ka_ice_volume_mask_DH.nc
  cdo -s -divc,3.1536e9 35ka_ice_volume_mask_DH.nc 1
  # freshwater flux unit: m3/s
  ncap2 -O -s "T122KP1=T122KP1*0.1-34.95" 1 35ka_ice_volume_mask_DHDt.nc
  # negative means freshwater input (Sv)
  cdo -s -fldsum 35ka_ice_volume_mask_DHDt.nc 1
  cdo -s -divc,1e6 1 2
  cdo -s -settaxis,0000-12-31,12:00,1year 2 1
  ncap2 -O -s "T122KP1=T122KP1*0.1-34.95" 1 35ka_ice_volume_mask_DhDt_Sv.nc
  #rm -fr temp1 1 2
else
  echo "don't calculate Dh/Dt"
fi


# assess the e.s.l. change due to ice volume changes
esl=0;
if [[ $esl = 1 ]]
then
# calculate the equivalent sea level drop of the ice volume
cdo -fldsum 35ka_ice_volume_mask.nc 35ka_ice_volume_mask_global.nc
cdo -divc,3.62E14 35ka_ice_volume_mask_global.nc 35ka_ice_volume_mask_global_esl.nc
cdo settaxis,0000-12-31,12:00,1year 35ka_ice_volume_mask_global_esl.nc 35ka_ice_volume_mask_global_esl_redate.nc
else
  echo "don't calculate e.s.l. ice volume"
fi

# extract the pointer field for Dh/Dt
pnt=0;
if [[ $pnt = 1 ]]
then
  cdo -settaxis,0000-12-31,12:00,1year GLAC1DdrainagePointerF40ka.nc temp
  cdo -selyear,51/400 temp temp2
  cdo -settaxis,0000-12-31,12:00,1year temp2 temp
  ncap2 -O -s "T40H1=T40H1*0.1-34.95" temp 35ka_pointer_fields.nc
  rm -rf temp temp2
else
  echo "don't extract pointer fields"
fi
