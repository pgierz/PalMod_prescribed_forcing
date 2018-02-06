# PalMod Prescribed Forcing
Collection of scripts to transform data for prescribed forcing in MPIESM.

Raw input data is stored in the folder `original_data_ltarasov`.

Transformation scripts (originally written by X. Zhang, originals backed up in
`original_scripts_xzhang`) have been cleaned up and documented **considerably**,
and are stored in `scripts`.

Each may be run with an argument `./$SCRIPT_NAME -h ` to obtain usage
information and purpose.

## `calculate_sealevel.sh`

This script generates several data files which may be used to approximate freshwater flux during Termination I (T-I), approximately 35ka BP to present. Original data from the Glacial Systems Model (GSM) is provided by Lev Tarasov, and is not documented in detail here.

Freshwater flux from the collapsing Northern Hemisphere ice sheets may be estimated by the change in their height over time ($\delta \eta / \delta t$)

## TODO:
+ [x] Xu needs to answer some questions for me...
+ [ ] Use `ncatted` to give sensible variable names to the output files
+ [ ] A `makefile` should be provide to run the scripts in the correct order...

