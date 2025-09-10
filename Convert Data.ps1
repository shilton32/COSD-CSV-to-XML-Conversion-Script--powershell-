# COSD Data Conversion Script
# Version 2.0
# Author: Chris Shilton
# Date: 2025-09-10
# Description: This script processes COSD data files extracted from PathManager.
# The input is a zip file containing CSV files for different organisations.
# The script extracts the zip, converts the CSV files to XML using XSLT, and performs data transformations, de-duplication of SNOMED codes,
# and adds required date fields before saving the final XML files to the output directory.
# The output XML files are formatted to be compatible with the Xpert mTuitive upload requirements.

Write-Output "COSD Script v2.0"
Write-Output "--------------------"
Write-Output ""

# Location of the zip file from PathManager
$inputPath = "x:/COSD/input/*.zip"
# Location of the xml file to be output
$outputPath = "x:/COSD/output/"
# Temporary folder for extracted files
$tempPath = "x:/COSD/temp/"
# Root folder (location of the script and xslt file)
$rootPath = "x:/COSD"

# Organisation codes to work through
# These are used to identify the file names of the different extracted data files
# and used to build the xml files so multiple organisations data can be processed
# in one script.
# For example, the initial filename rcf-cosd-output.csv- rcf being the org code
$orgCodes = @(
"rcf",
"rae",
"rcd"
);

# Remove any residual csv or xml files from the temp folder
Remove-Item "$tempPath*.csv"
Remove-Item "$tempPath*.xml"

# Next, extract the archive
Write-Output "Extracting data"
Expand-Archive -Path $inputPath -DestinationPath $tempPath

# Main iteration loop
Write-Output "Processing data files"
Write-Output "---------------------"
# Iterating through the Org codes and related files
foreach ($orgCode in $orgCodes) {

If (Test-Path -Path "$outputPath$orgCode-cosd-export.xml")
{
	Remove-Item "$outputPath$orgCode-cosd-export.xml"
}

# Transform csv to xml using the xslt library
Write-Output "Processing: $orgCode Data"
get-content -path "$tempPath$orgCode-lims-output.csv" -raw | foreach-object {$_ -replace "[\x00-\x08\x0B\x0C\x0E-\x1F\xA0]"} | Set-Content -path "$tempPath$orgCode-test-interim.csv"
import-csv -Path  "$tempPath$orgCode-test-interim.csv" |  ConvertTo-Xml -as String | Set-Content -path "$tempPath$orgCode-multi-records-test.xml" -Encoding UTF8
$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
$xslt.load( "$rootPath/rcf-convert.xslt" )
$xslt.Transform( "$tempPath$orgCode-multi-records-test.xml", "$tempPath$orgCode-cosd-export.xml" )

# De-duplication of SNOMED codes
# Load the XML file
Write-Output "De-duplicating SNOMED codes"
[xml]$xml = Get-Content -Path "$tempPath$orgCode-cosd-export.xml" -Encoding UTF8

# Iterate through each Record
foreach ($record in $xml.SelectNodes("//Record")) {
    $core = $record.CorePathology

    # De-duplicate TopographySNOMEDPathology
    if ($core.TopographySNOMEDPathology) {
        $topoCodes = $core.TopographySNOMEDPathology -split '\|'
        $uniqueTopo = $topoCodes | Sort-Object -Unique
        $core.TopographySNOMEDPathology = $uniqueTopo -join '|'
    }

    # De-duplicate MorphologySNOMEDPathology
    if ($core.MorphologySNOMEDPathology) {
        $morphCodes = $core.MorphologySNOMEDPathology -split '\|'
        $uniqueMorph = $morphCodes | Sort-Object -Unique
        $core.MorphologySNOMEDPathology = $uniqueMorph -join '|'
    }
}

# Save the updated XML to a new file in the final output folder
$xml.Save("$tempPath$orgCode-cosd-export.xml")

# Add the required dates to the script
Write-Output "Adding date fields"
# Open the dates csv and get the required fields
$csvPath = Join-Path -Path $tempPath -ChildPath "dates.csv"
$dates = Import-CSV -Path $csvPath -Delimiter ","

$fileDateCreation = $dates[0].FileCreationDateTime
$ReportingPeriodStartDate = $dates[0].ReportingPeriodStartDate
$ReportingPeriodEndDate = $dates[0].ReportingPeriodEndDate

# Apply the dates to the file
Write-Output "Applying date information to: $orgCode"

# Load and update XML
$xml = New-Object XML
$xml.Load("$tempPath$orgCode-cosd-export.xml")
$xml_filedate = $xml.SelectSingleNode("LIMSData/FileCreationDateTime")
$xml_reportStartDate = $xml.SelectSingleNode("LIMSData/ReportingPeriodStartDate")
$xml_reportEndDate = $xml.SelectSingleNode("LIMSData/ReportingPeriodEndDate")
# Set the dates within the InnerText of the xml fields
$xml_filedate.InnerText = $fileDateCreation
$xml_reportStartDate.InnerText = $ReportingPeriodStartDate
$xml_reportEndDate.InnerText = $ReportingPeriodEndDate

# Save with UTF-8 encoding (no-BOM)
$settings = New-Object System.Xml.XmlWriterSettings
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$settings.Encoding = $utf8NoBom
$settings.Indent = $true
# Write the file
$writer = [System.Xml.XmlWriter]::Create("$outputPath$orgCode-cosd-export.xml", $settings)
$xml.WriteTo($writer)
$writer.Close()

}

# Post Processing tidy-up
Write-Output "Tidying up temp files"
remove-item -Path "$tempPath*.*"
Write-Output "Script finished... :-)"
pause




















