<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output indent="yes" method="xml" encoding="utf-8" cdata-section-elements="PathologyReportText"/>
	<xsl:template match="/">
		<xsl:variable name="recordCount" select="count(/Objects/Object)"/>
		<LIMSData>
			<OrganisationIdentifierCodeOfSubmittingOrganisation extension="RCD"/>
			<RecordCount>
				<xsl:attribute name="value">
					<xsl:value-of select="$recordCount"/>
				</xsl:attribute>
			</RecordCount>
			<ReportingPeriodStartDate/>
			<ReportingPeriodEndDate/>
			<FileCreationDateTime>
					<xsl:value-of select="Property[@Name='FileCreationDateTime']/text()"/>
				</FileCreationDateTime>
			<xsl:apply-templates select="/Objects/Object"/>
		</LIMSData>
	</xsl:template>
	<xsl:template match="Objects/Object">
		<xsl:variable name="rawCodes" select="Property[@Name='All Diagnosis Codes']/text()"/>
		<Record>
			<CoreLinkagePatientId>
				<NHSNumber>
					<xsl:value-of select="Property[@Name='NHS Number']/text()"/>
				</NHSNumber>
				<LocalPatientIdExtended>
					<xsl:value-of select="Property[@Name='CRN (Hospital) Number']/text()"/>
				</LocalPatientIdExtended>
				<NHSNumberStatusIndicator>01</NHSNumberStatusIndicator>
				<Birthdate>
					<xsl:call-template name="dateTimeFormatter">
						<xsl:with-param name="dt" select="Property[@Name='Date of Birth']/text()"/>
					</xsl:call-template>
				</Birthdate>
				<OrganisationIdentifierCodeOfProvider>
					<xsl:value-of select="'RCD'"/>
				</OrganisationIdentifierCodeOfProvider>
			</CoreLinkagePatientId>
			<CoreDemographics>
				<PersonFamilyName>
					<family>
						<xsl:value-of select="Property[@Name='Surname']/text()"/>
					</family>
				</PersonFamilyName>
				<PersonGivenName>
					<given>
						<xsl:value-of select="Property[@Name='Forename']/text()"/>
					</given>
				</PersonGivenName>
				<Address>
					<UnstructuredAddress>
						<streetAddressLine>
							<xsl:value-of select="Property[@Name='Address Line 1']/text()"/>
							<xsl:text/>
							<xsl:value-of select="Property[@Name='Address Line 2']/text()"/>
							<xsl:text/>
							<xsl:value-of select="Property[@Name='Address Line 3']/text()"/>
							<xsl:text/>
							<xsl:value-of select="Property[@Name='Address Line 4']/text()"/>
						</streetAddressLine>
					</UnstructuredAddress>
				</Address>
				<Postcode>
					<postalCode>
						<xsl:value-of select="Property[@Name='Post Code']/text()"/>
					</postalCode>
				</Postcode>
				<Gender>
					<xsl:value-of select="Property[@Name='Sex']/text()"/>
				</Gender>
			</CoreDemographics>
			<CorePathology>
				<InvestigationResultDate>
					<xsl:call-template name="dateTimeFormatter">
						<xsl:with-param name="dt" select="Property[@Name='Date &amp; Time Last Authorised']/text()"/>
					</xsl:call-template>
				</InvestigationResultDate>
				<ServiceReportId>
					<xsl:value-of select="Property[@Name='Specimen Number']/text()"/>
				</ServiceReportId>
				<PathologyObservationReportIdentifier/>
				<ServiceReportStatus>1</ServiceReportStatus>
				<PathologistTestRequestIssuerCode>
					<xsl:value-of select="'03'"/>
				</PathologistTestRequestIssuerCode>
				<PathTestReqCareProfCode>
					<xsl:value-of select="Property[@Name='Requesting Clinician Code']/text()"/>
				</PathTestReqCareProfCode>
				<OrganisationSiteIdentifierOfPathologyTestRequest>
					<xsl:call-template name="siteIdentifier">
						<xsl:with-param name="snc" select="Property[@Name='Source National Code']/text()"/>
					</xsl:call-template>
				</OrganisationSiteIdentifierOfPathologyTestRequest>
				<SampleReceiptDate>
					<xsl:call-template name="dateTimeFormatter">
						<xsl:with-param name="dt" select="Property[@Name='Date &amp; Time Booked In']/text()"/>
					</xsl:call-template>
				</SampleReceiptDate>
				<PathologistConsultantIssuerCode>
					<xsl:value-of select="'03'"/>
				</PathologistConsultantIssuerCode>
				<PathologistConsultantCode>
					<xsl:value-of select="Property[@Name='Reporting Pathologist Code']/text()"/>
				</PathologistConsultantCode>
				<SNOMEDVersionPathology>01</SNOMEDVersionPathology>
				<!-- Assuming SNOMED II-->
				<xsl:apply-templates select="Property[@Name='All Diagnosis Codes']"/>
				<PathologyReportText>
					<xsl:value-of select="Property[@Name='Report Output']/text()"/>
				</PathologyReportText>
			</CorePathology>
		</Record>
	</xsl:template>
	<xsl:template name="dateTimeFormatter">
		<xsl:param name="dt"/>
		<xsl:value-of select="concat(
    substring($dt,7,4),'-',
    substring($dt,4,2),'-',
    substring($dt,1,2))"/>
	</xsl:template>
	<xsl:template name="siteIdentifier">
		<xsl:param name="snc"/>
		<xsl:choose>
			<xsl:when test="$snc != ''">
				<xsl:value-of select="$snc"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="'RCD00'"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:variable name="delimiter" select="','"/>
	<xsl:template match="Property[@Name='All Diagnosis Codes']">
		<xsl:variable name="rawCodes">
			<xsl:value-of select="./text()"/>
		</xsl:variable>
		<TopographySNOMEDPathology>
			<xsl:call-template name="handleCodesTemplate">
				<xsl:with-param name="rawcodes" select="$rawCodes"/>
				<xsl:with-param name="startsWith" select="'T'"/>
				<xsl:with-param name="numCodes" select="number(0)"/>
			</xsl:call-template>
		</TopographySNOMEDPathology>
		<MorphologySNOMEDPathology>
			<xsl:call-template name="handleCodesTemplate">
				<xsl:with-param name="rawcodes" select="$rawCodes"/>
				<xsl:with-param name="startsWith" select="'M'"/>
				<xsl:with-param name="numCodes" select="number(0)"/>
			</xsl:call-template>
		</MorphologySNOMEDPathology>
	</xsl:template>
	<!--https://stackoverflow.com/questions/7425071/split-function-in-xslt-1-0-->
	<xsl:template name="handleCodesTemplate">
		<xsl:param name="rawcodes"/>
		<xsl:param name="startsWith"/>
		<xsl:param name="numCodes"/>
		<xsl:choose>
			<xsl:when test="contains($rawcodes,$delimiter)">
				<xsl:variable name="code" select="substring-before($rawcodes,$delimiter)"/>
				<xsl:variable name="writingVal" select="starts-with($code,$startsWith)"/>
				<xsl:if test="$writingVal">
					<xsl:if test="$numCodes &gt; number(0)">
						<xsl:value-of select="'|'"/>
					</xsl:if>
					<xsl:value-of select="$code"/>
				</xsl:if>
				<xsl:call-template name="handleCodesTemplate">
					<xsl:with-param name="rawcodes" select="substring-after($rawcodes,$delimiter)"/>
					<xsl:with-param name="startsWith" select="$startsWith"/>
					<xsl:with-param name="numCodes" select="number($numCodes + number($writingVal))"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="starts-with($rawcodes,$startsWith)">
				<xsl:if test="$numCodes &gt; number(0)">
					<xsl:value-of select="'|'"/>
				</xsl:if>
				<xsl:value-of select="$rawcodes"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
