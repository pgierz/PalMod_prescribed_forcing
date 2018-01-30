#!/bin/bash
################################################################################
#
# SCRIPT: calculate_sealevel.sh
#
# PURPOSE: TODO
#
# REQUIRED INPUTS: TODO
#
# RETURNED OUTPUTS: TODO
#
# Project: PalMod
# Date: 2016-2019
#
# Scientists:
# Dr. Xu Zhang,   AWI Bremerhaven
# Dr. Paul Gierz, AWI Bremerhaven
#
# ------------
# Changes:
# ------------
#
# 29.01.18 Gierz
#
# Rewrite of Xu's scripts for improved clarity to ensure `PISM`-`MPIESM`
# coupling does the same thing.
#
################################################################################

# Physical constants
density_ice=0.9167  # kg m**-3


# Parse arguments


# define CDO with some common switches
cdo="cdo -s"

# Define the directories to be used: original data location and temporary workdir
RAW_DATA_DIR=${PROJECT_HOME}/original_data_ltarasov/
WORK_DIR=${PROJECT_HOME}/work
OUT_DATA=${PROJECT_HOME}/outdata

function prepare_raw_data {
    # TODO: Condense this once Xu answers the questions. It can probably also
    # end up being one or two lines...

    ### Define variable names for this function
    # RAW input
    RAW_DATA=${RAW_DATA_DIR}/GLAC1DHiceF40.nc

    # INTERMEDIATE files
    GSM_HEIGHT=${WORK_DIR}/$(basename ${RAW_DATA})
    GSM_AREA=${WORK_DIR}/GSM_gridarea.nc
    GSM_MASS=${WORK_DIR}/GSM_ice_mass_35ka.nc
    rmlist="$GSM_HEIGHT $GSM_AREA $GSM_MASS $rmlist"

    # PROCESSED output
    OUTPUT_DATA=${OUT_DATA}/$(basename ${GSM_MASS})

    # Determine the gridarea that the Glacial System Model (GSM) was run on:
    $cdo gridarea ${RAW_DATA} ${GSM_AREA}

    # Prepare any RAW output that needs to be directly copied into an intermediate file
    cp ${RAW_DATA} ${GSM_HEIGHT}

    ################################################################################
    # QUESTION: Xu, you name this next file "*_Vol.nc" in the original script.
    # Are you sure this is correct?
    #
    # From what I can tell, the line in your script calcules the *mass*, and not the *volume*
    # Mass = [kg], Volume = [m**3]
    ################################################################################

    # transform from height to mass of ice (kg = height (m) * area (m**2) * density_ice (kg m**-3))
    $cdo -mulc,$density_ice \
         -mul \
         ${GSM_HEIGHT} ${GSM_AREA} \
         ${GSM_MASS}

    # Correct the time axis for selection of individual years:
    $cdo -settaxis,0000-12-31,12:00,1year ${GSM_MASS} tmp && mv tmp ${GSM_MASS}

    ################################################################################
    # QUESTION: Xu, in your script, a ncap is performed to shift the lon by 360. Why?
    ################################################################################

    ################################################################################
    # QUESTION: Xu, why are these specific years selected?
    ################################################################################
    # Select years 50 until 401, and reset the axis to start from year 0 again
    $cdo -settaxis,0000-12-31,12:00,1year \
         -selyear,50/401 \
         ${GSM_MASS} \
         tmp && mv tmp ${GSM_MASS}

    # OUTPUT:
    mv ${GSM_MASS} ${OUTPUT_DATA}

    # Cleanup intermediate files
    rm -v $rmlist

}


function calculate_masked_ice_volume {
    ### Define Filenames
    # RAW Files:
    RAW_MASK=${RAW_DATA_DIR}/TOPicemsk.GLACD35kN9894GE90227A6005GGrBgic.nc 
    # Input:
    INPUT=${OUT_DATA}/GSM_ice_mass_35ka.nc
    # Output:
    OUTPUT=${OUT_DATA}/GSM_ice_mass_35ka_masked.nc
    ### Define Variable names
    GSM_MASK=ICEM

    $cdo -P 28 -mul \
         -remapcon,$INPUT -selvar,$GSM_VAR_NAME $RAW_MASK \
         $INPUT \
         $OUTPUT

}


function caclulate_dHdt {
    ### Define Filenames:
    # Input:
    INPUT=${OUT_DATA}/GSM_ice_mass_35ka_masked.nc
    OUTPUT1=${OUT_DATA}/GSM_ice_mass_35ka_masked_dHdt.nc
    ################################################################################
    # QUESTION: I don't understand this next line. It appears as if you
    # convert the file to a timeseries and convert to Sv, but why don't you list
    # both of those operations in the name somehow? It is to me unclear why
    # $OUTPUT1 is a 2-D field, and $OUTPUT2 is a timeseries. Naming conventions
    # should be consistent if possible!
    ################################################################################
    OUTPUT2=${OUT_DATA}/GSM_ice_mass_35ka_masked_dHdt_Sv.nc
    OUTPUT2_SUGGESTED_NAME=${OUT_DATA}/GSM_ice_mass_45ka_masked_dHdt_fldsum_Sv.nc

    ################################################################################
    # QUESTION: Xu, why are these specific years selected? The factor 3.1536e9
    # is seconds in 100 years? Without an explination, the numbers appear to
    # have been taken out of thin air...
    ################################################################################
    # In the next step, the difference between years 0/349 and 1/350 is calculated, and converted by a factor.
    #
    # NOTE: The factor in Xu's script seems to be something like number of
    # seconds in 100 years. If so, I would write it like this to preserve
    # clarity:
    #
    num_seconds_in_100_years=$(python -c "num_secs=60*60*24*365*100; print('%e' % num_secs)")
    $cdo -s -settaxis,0000-12-31,12:00,1year \
         -divc,$num_seconds_in_100_years \
         -sub \
         -selyear,1/350 $INPUT \
         -selyear,0/349 $INPUT \
         $OUTPUT1

    ################################################################################
    # QUESTION: What does this step do? Why must the variable T122KP1 be
    # modified? What are the units? What is variable T122KP1?
    ################################################################################
    ncap2 -s "T122KP1=T122KP1*0.1-34.95" $OUTPUT1

    # Generate the dHdt timeseries output based upon the conversions already applied:
    num_m_per_s_in_Sv=1e6
    cdo -P 8 \
        -fldsum \
        -divc,$num_m_per_sec_in_Sv \
        -settaxis,0000-12-31,12:00,1year \
        $OUTPUT1 \
        $OUTPUT2

    ################################################################################
    # QUESTION: in the next step, you apply the ncap2 operation again, but the
    # file has already been modified! Why does it need to be done twice?
    ################################################################################
    # Apply the ncap2 operation again (I still don't know what this does, or why doing it twice is necessary...)
    ncap2 -s "T122KP1=T122KP1*0.1-34.95" $OUTPUT2
}


function calculate_eustatic_sealevel {
    INPUT=${OUT_DATA}/GSM_ice_mass_35ka_masked.nc
    OUTPUT=${OUT_DATA}/GSM_ice_mass_35ka_masked_global_esl.nc
    ################################################################################
    # QUESTION: What is this strange factor? In order to go from *mass*, which
    # is what you have, you need density of water as well as area...
    ################################################################################
    strange_factor=3.62E14
    cdo -settaxis,0000-12-31,12:00,1year \
        -divc,$strange_factor \
        -fldsum \
        $INPUT \
        $OUTPUT
}

function extract_pointer_field_dHdt {
    # File Definitions
    RAW_DATA=${RAW_DATA_DIR}/GLAC1DdrainagePointerF40ka.nc
    OUTPUT=${OUT_DATA}/GSM_pointer_fields_35ka.nc
    ################################################################################
    # QUESTION: Why are years 51 until 400 selected, and why is the operation
    # required??
    ################################################################################
    # Select years 51 until 400 of the raw data, and reset the time axis
    cdo -settaxis,0000-12-31,12:00,1year \
        -selyear,51/400 \
        -settaxis,0000-12-31,12:00,1year \
        $RAW_DATA \
        $OUTPUT
    # Perform a ncap2 operation
    ncap2 -s "T40H1=T40H1*0.1-34.95" $OUTPUT
}

pre=0; # extract the 35ka BP time series from Lev's reconstruction and calculate the ice volume
if [[ $pre = 1 ]]
then
    prepare_raw_data
fi

# extract the area where there is ice volume change
vol=0;
if [[ $vol = 1 ]]
then
    calculate_masked_ice_volume
else
  echo "don't calculate MASKED ice volume"
fi

# calculate DH/DT
dh=1;
if [[ $dh = 1 ]]
then
    calculate_dHdt
else
  echo "don't calculate Dh/Dt"
fi


# assess the e.s.l. change due to ice volume changes
esl=0;
if [[ $esl = 1 ]]
then
    calculate_eustatic_sealevel
else
  echo "don't calculate e.s.l. ice volume"
fi

# extract the pointer field for Dh/Dt
pnt=0;
if [[ $pnt = 1 ]]
then
    extract_pointer_field_dHdt
else
  echo "don't extract pointer fields"
fi
