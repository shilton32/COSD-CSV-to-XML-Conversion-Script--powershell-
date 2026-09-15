# COSD Data Conversion Script
# Version 3.0
# Author: Chris Shilton
# Date: 2026-05-01
# Description: This script processes COSD data files extracted from PathManager.
# The input is a zip file containing CSV files for different organisations.
# The script extracts the zip, converts the CSV files to XML using XSLT, and performs data transformations, de-duplication of SNOMED codes,
# and adds required date fields before saving the final XML files to the output directory.
# The output XML files are formatted to be compatible with direct submission to NHS Digital's COSD Pathology system.

Write-Output "COSD Script v3.2"
Write-Output "--------------------"
Write-Output ""

# Location of the zip file from PathManager
$inputPath = "c:/Pathology/COSD/input/*.zip"
# Location of the xml file to be output
$outputPath = "c:/Pathology/COSD/output/"
# Temporary folder for extracted files
$tempPath = "c:/Pathology/COSD/temp/"
# Root folder (location of the script and xslt file)
$rootPath = "c:/Pathology/COSD"

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

Write-Output "input path: $inputPath"
Write-Output "temp path: $tempPath"



# Next, extract the archive
Write-Output "Extracting data"
Expand-Archive -Path $inputPath -DestinationPath $tempPath

## Path to the dates.csv file
$dateFile  = "$tempPath\dates.csv"

# Read entire file as a single string
$content = Get-Content -Path $dateFile -Raw

# If the file starts with CRLF (`r`n), remove it
if ($content.StartsWith("`r`n")) {
    $content = $content.Substring(2)
    Set-Content -Path $dateFile -Value $content
}

# Main iteration loop
Write-Output "Processing data files"
Write-Output "---------------------"
# Iterating through the Org codes and related files
foreach ($orgCode in $orgCodes) {

If (Test-Path -Path "$outputPath$orgCode-cosd-export.xml")
{
	Remove-Item "$outputPath$orgCode-cosd-export.xml"
}

## Path to the original file
$inputFile  = "$tempPath$orgCode-lims-output.csv"

# Read entire file as a single string
$content = Get-Content -Path $inputFile -Raw

# If the file starts with CRLF (`r`n), remove it
if ($content.StartsWith("`r`n")) {
    $content = $content.Substring(2)
    Set-Content -Path $inputFile -Value $content
}




# Transform csv to xml using the xslt library
Write-Output "Processing: $orgCode Data"
get-content -path "$tempPath$orgCode-lims-output.csv" -raw | foreach-object {$_ -replace "[\x00-\x08\x0B\x0C\x0E-\x1F\xA0]"} | Set-Content -path "$tempPath$orgCode-test-interim.csv"
import-csv -Path  "$tempPath$orgCode-test-interim.csv" |  ConvertTo-Xml -as String | Set-Content -path "$tempPath$orgCode-multi-records-test.xml" -Encoding UTF8

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform;
$xslt.load( "$rootPath/$orgCode-convert.xslt" )
$xslt.Transform( "$tempPath$orgCode-multi-records-test.xml", "$tempPath$orgCode-cosd-export.xml" )

# De-duplication of SNOMED codes
# Load the XML file
Write-Output "De-duplicating SNOMED codes"
[xml]$xml = Get-Content -Path "$tempPath$orgCode-cosd-export.xml" -Encoding UTF8

foreach ($other in $xml.SelectNodes("//OtherRecord")) {

    $path = $other.Pathology
    if (-not $path) { continue }

    $tmNode = $path.TopographyMorphologySnomed
    if (-not $tmNode) { continue }

    #
    # 1) Extract ALL codes from existing XML
    #
    $rawCodes = @()

    foreach ($node in $tmNode.SelectNodes("TopographySnomedPathology | MorphologySnomedPathology")) {
        if ($node.code) { $rawCodes += $node.code }
    }

    #
    # 2) Normalise separators (comma to pipe)
    #
    $rawCodes = ($rawCodes -join "|") -replace ',', '|'

    #
    # 3) Clean, split, dedupe
    #
    $codes =
        $rawCodes -split '\|' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne "" } |
        Sort-Object -Unique

    #
    # 4) Split into Topography (T) and Morphology (M)
    #
    $topoCodes =
        $codes |
        Where-Object { $_.StartsWith("T") }

    $morphCodes =
        $codes |
        Where-Object { $_.StartsWith("M") }

    #
    # 5) Remove ALL existing SNOMED nodes (except version)
    #
    $tmNode.SelectNodes("TopographySnomedPathology | MorphologySnomedPathology") |
        ForEach-Object { $tmNode.RemoveChild($_) | Out-Null }

    #
    # 6) Add Topography nodes
    #
    foreach ($code in $topoCodes) {
        $newNode = $xml.CreateElement("TopographySnomedPathology")
        $attr = $xml.CreateAttribute("code")
        $attr.Value = $code
        $newNode.Attributes.Append($attr) | Out-Null
        $tmNode.AppendChild($newNode) | Out-Null
    }

    #
    # 7) Add Morphology nodes
    #
    foreach ($code in $morphCodes) {
        $newNode = $xml.CreateElement("MorphologySnomedPathology")
        $attr = $xml.CreateAttribute("code")
        $attr.Value = $code
        $newNode.Attributes.Append($attr) | Out-Null
        $tmNode.AppendChild($newNode) | Out-Null
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
Write-Output "Applying date information for: $orgCode"

# Load XML
$xml = New-Object System.Xml.XmlDocument
$xml.Load("$tempPath$orgCode-cosd-export.xml")

# Namespace manager
$nsm = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
$nsm.AddNamespace("cosd", "http://www.datadictionary.nhs.uk/messages/COSD_Pathology-v5-1-1")

# Select nodes using namespace-aware XPath
$xml_filedate        = $xml.SelectSingleNode("//cosd:COSD_Pathology/FileCreationDateTime", $nsm)
$xml_reportStartDate = $xml.SelectSingleNode("//cosd:COSD_Pathology/ReportingPeriodStartDate", $nsm)
$xml_reportEndDate   = $xml.SelectSingleNode("//cosd:COSD_Pathology/ReportingPeriodEndDate", $nsm)

# Debug
Write-Host "FileDate node: $xml_filedate"
$node = $xml.SelectSingleNode("//*[local-name()='FileCreationDateTime']")
Write-Host "Namespace URI: $($node.NamespaceURI)"

# Update values
$xml_filedate.InnerText        = $fileDateCreation
$xml_reportStartDate.InnerText = $ReportingPeriodStartDate
$xml_reportEndDate.InnerText   = $ReportingPeriodEndDate

# Save
$xml.Save("$tempPath$orgCode-cosd-export.xml")


# GUID Additions;
# Load XML
$xml = New-Object System.Xml.XmlDocument
$xml.Load("$tempPath$orgCode-cosd-export.xml")

# GUID for the overall xml
$xml_rootID = $xml.SelectSingleNode("//cosd:COSD_Pathology/Id", $nsm)
$xml_rootID.Attributes["root"].Value = (New-Guid).ToString().ToUpper()

foreach ($record in $xml.SelectNodes("//OtherRecord")) {

    $newNode = $xml.CreateElement("Id")
    $attr = $xml.CreateAttribute("root")
    $attr.Value = (New-Guid).ToString().ToUpper()
    $newNode.Attributes.Append($attr)

    if ($record.HasChildNodes) {
        $record.InsertBefore($newNode, $record.FirstChild)
    }
    else {
        $record.AppendChild($newNode)
    }
}

# Save back to the fil
$xml.Save("$tempPath$orgCode-cosd-export.xml")


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