# COSD Data Conversion Script - v3.0

Changes: Direct csv to COSD required format.  Total rewrite of each xslt file alongside the ps1 script.

This script is used to transform CSV data downloaded from the Clinisys PathManager tool using an appropriate column naming convention.  The previous version required a further upload to mTuitive, but the conversion is now ready for direct submission.

The script is configured to convert data for multiple organisations at the same time - this can be changed or reduced to just one organisation by
changing the $orgCodes array.
