clear;clc;
cd /Users/xzhang/Dataset/DataOutside/Model_Output/Icesheet_Tarasov/Cal_drainage_point/input_for_MATLAB_to_cal_freshwater_to_ocean_from_point_field

fwf=ncread('35ka_ice_volume_mask_DHDt.nc','HGLOBH');
ix=ncread('35ka_pointer_fields.nc','IX');
jy=ncread('35ka_pointer_fields.nc','JY');


% fwf=ncread('35ka_ice_volume_mask_DHDt_GR15.nc','HGLOBH');
% ix=ncread('35ka_pointer_fields_GR15.nc','IX');
% jy=ncread('35ka_pointer_fields_GR15.nc','JY');


tgt=zeros(size(fwf));

for t=1:size(fwf,3)
%      t=1
    for j=1:size(fwf,2)        
        for i=1:size(fwf,1)
            
            tgt(ix(i,j,t),721-jy(i,j,t),t)=fwf(i,j,t)+tgt(ix(i,j,t),721-jy(i,j,t),t); 
            
        end
        
        tgt(2:end,j,t)=tgt(1:end-1,j,t);
        tgt(1,j,t)=tgt(end,j,t);
%         tgt(1,721-jy(size(fwf,1),j,t),t)=fwf(size(fwf,1),j,t)+tgt(ix(size(fwf,1),j,t),721-jy(size(fwf,1),j,t),t); 
    end
end


id=netcdf.open('35ka_ice_volume_mask_DHDt_afterPointer.nc','NC_WRITE');
% id=netcdf.open('35ka_ice_volume_mask_DHDt_afterPointer_GR15.nc','NC_WRITE');

% for i=1:5
% %      i=55
%     [varname,xtype,dimids,natts]=netcdf.inqVar(id,i); 
%     i, varname
% end

netcdf.putVar(id,3,tgt);
netcdf.close(id);


