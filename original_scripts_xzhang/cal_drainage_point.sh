#!/bin/bash

echo "after Matlab program 'cal_freshwater_to_ocean.m' "
echo "remap 720x720 grid to GR15 grid"

REF=/Users/xzhang/Dataset/Research_scripts/REF

cp ${REF}/GR15s.nc .

#ncap2 -O -s 'lat=-1*lat' 35ka_ice_volume_mask_DHDt_afterPointer.nc 35ka_ice_volume_mask_DHDt_afterPointer_revertLat.nc

ncap2 -O -s 'lon=lon-360' 35ka_ice_volume_mask_DHDt_afterPointer.nc 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc
ncrename -v HGLOBH,fwf 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc
ncatted -O -a units,fwf,c,c,"m3s-1" -a long_name,fwf,o,c,"freshwater flux" 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc

################################
### regular grid calculation ###
################################
reg=0
if [[ $reg = 1 ]]
then
  cdo mulc,-1 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc 1
  cdo -setvrange,0,9e99 1 p1
  cdo -setvrange,-9e99,0 1 n1

  cdo -s -setmisstoc,0 -settaxis,0000-12-31,12:00,1year p1 fnl_temp_p1
  cdo -s -setmisstoc,0 -settaxis,0000-12-31,12:00,1year n1 fnl_temp_n1

  ## test the conservation
  test=1
  if [[ $test = 1 ]]
  then
    cdo -fldsum p1 p2
    cdo -s -settaxis,0000-12-31,12:00,1year p2 p3
    ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' p3 35ka_normal_grid_pfwf_sum_reg.nc
    ncatted -O -a history,global,d,, 35ka_normal_grid_pfwf_sum_reg.nc
    cdo -fldsum n1 n2
    cdo -s -settaxis,0000-12-31,12:00,1year n2 n3
    ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' n3 35ka_normal_grid_nfwf_sum_reg.nc
    ncatted -O -a history,global,d,, 35ka_normal_grid_nfwf_sum_reg.nc
  fi
  ##

  ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' fnl_temp_p1 35ka_ice_volume_mask_DHDt_positiveFWF.nc
  ncatted -O -a history,global,d,, 35ka_ice_volume_mask_DHDt_positiveFWF.nc

  ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' fnl_temp_n1 35ka_ice_volume_mask_DHDt_negativeFWF.nc
  ncatted -O -a history,global,d,, 35ka_ice_volume_mask_DHDt_negativeFWF.nc


  rm 1 p1 n1 p2 p3 n2 n3 fnl_temp_p1 fnl_temp_n1
fi
############################
### convert to GR15 grid ###
############################
cvt=1
if [[ $cvt = 1 ]]
then
# scale the flux to grid box
cdo gridarea 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc gridarea.nc
cdo -div 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc gridarea.nc 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_ms-1.nc
# remap the scaled flux to a new map
cdo -s -remapcon2,GR15s.nc 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_ms-1.nc fnl_temp
# convert the scaled flux to real flux
cdo -mul fnl_temp -gridarea fnl_temp test_fwf.nc
cdo mulc,-1 test_fwf.nc 1
cdo -setvrange,0,9e99 1 p1
cdo -setvrange,-9e99,0 1 n1

cdo -s -setmisstoc,0 -settaxis,0000-12-31,12:00,1year 1 fnl_temp1
cdo -s -setmisstoc,0 -settaxis,0000-12-31,12:00,1year p1 fnl_temp_p1
cdo -s -setmisstoc,0 -settaxis,0000-12-31,12:00,1year n1 fnl_temp_n1

    ## test the conservation
    test=0
    if [[ $test = 1 ]]
    then
      cdo -fldsum 1 2
      cdo -s -settaxis,0000-12-31,12:00,1year 2 3
      ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' 3 35ka_GR15grid_fwf_sum.nc
      ncatted -O -a history,global,d,, 35ka_GR15grid_fwf_sum.nc
      cdo -fldsum p1 p2
      cdo -s -settaxis,0000-12-31,12:00,1year p2 3
      ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' 3 35ka_GR15grid_pfwf_sum.nc
      ncatted -O -a history,global,d,, 35ka_GR15grid_pfwf_sum.nc
      cdo -fldsum n1 n2
      cdo -s -settaxis,0000-12-31,12:00,1year n2 3
      ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' 3 35ka_GR15grid_nfwf_sum.nc
      ncatted -O -a history,global,d,, 35ka_GR15grid_nfwf_sum.nc
    fi
    ##

ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' fnl_temp1 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15.nc
ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' fnl_temp_p1 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15_Positive.nc
ncap2 -O -s 'T122KP1=T122KP1*0.1-34.95' fnl_temp_n1 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15_Negative.nc

#ncrename -v HGLOBH,fwf 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15.nc
#ncatted -O  -a units,fwf,c,c,"m3s-1" -a long_name,fwf,o,c,"freshwater flux" 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15.nc
ncatted -O -a history,global,d,, 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15.nc
ncatted -O -a history,global,d,, 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15_Positive.nc
ncatted -O -a history,global,d,, 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_GR15_Negative.nc

rm fnl_temp1 fnl_temp_p1 fnl_temp_n1
rm -fr fnl_temp  1 2 3 p1 p2 n1 n2 test_fwf.nc 35ka_ice_volume_mask_DHDt_afterPointer_adjLon.nc gridarea.nc 35ka_ice_volume_mask_DHDt_afterPointer_adjLon_ms-1.nc
fi
