<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:COSD_Pathology="http://www.datadictionary.nhs.uk/messages/COSD_Pathology-v5-1-1"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    exclude-result-prefixes="xsi">

  <!-- Output formatting -->
  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <!-- Root template -->
  <xsl:template match="/">

    <COSD_Pathology:COSD_Pathology>

      <!-- Static header fields -->
      <Id root=""/>
      <OrganisationIdentifierCodeOfSubmittingOrganisation extension="RAE"/>
      <RecordCount>
        <xsl:attribute name="value">
          <xsl:value-of select="count(Objects/Object)"/>
        </xsl:attribute>
      </RecordCount>

      <ReportingPeriodStartDate/>
      <ReportingPeriodEndDate/>
        <FileCreationDateTime/>


      <!-- Iterate through CSV rows -->
      <xsl:for-each select="Objects/Object">
        <OtherRecord>

  <!-- ========================= -->
  <!-- Patient Identity Details  -->
  <!-- ========================= -->
  <PatientIdentityDetails>
  
    <NhsNumber>
      <xsl:attribute name="extension">
        <xsl:value-of select="Property[@Name='NHS Number']"/>
      </xsl:attribute>
    </NhsNumber>

    <LocalPatientIdentifier>
      <xsl:value-of select="Property[@Name='CRN (Hospital) Number']"/>
    </LocalPatientIdentifier>

    <NHSNumberStatusIndicator>
      <xsl:attribute name="code">
        <xsl:value-of select="Property[@Name='NHS Number Status Indicator']"/>
      </xsl:attribute>
    </NHSNumberStatusIndicator>

    <PersonBirthDate>
		<xsl:call-template name="dateTimeFormatter">
			<xsl:with-param name="dt" select="Property[@Name='Date of Birth']"/>
		</xsl:call-template>	
    </PersonBirthDate>

    <OrganisationIdentifierCodeOfProvider>
      <xsl:attribute name="extension">
        <xsl:value-of select="'RAE'"/>
      </xsl:attribute>
    </OrganisationIdentifierCodeOfProvider>
  </PatientIdentityDetails>

  <!-- ========================= -->
  <!-- Demographics              -->
  <!-- ========================= -->
  <Demographics>
    <PersonFamilyName>
      <xsl:value-of select="Property[@Name='Surname']"/>
    </PersonFamilyName>

    <PersonGivenName>
      <xsl:value-of select="Property[@Name='Forename']"/>
    </PersonGivenName>

    <Address>
      <UnstructuredAddress>
        <StreetAddressLine>
            <xsl:value-of select="concat(Property[@Name='Address Line 1'], ' ')"/>
            <xsl:text/>
            <xsl:value-of select="concat(Property[@Name='Address Line 2'], ' ')"/>
            <xsl:text/>
            <xsl:value-of select="concat(Property[@Name='Address Line 3'], ' ')"/>
            <xsl:text/>
            <xsl:value-of select="Property[@Name='Address Line 4']"/>
        </StreetAddressLine>
      </UnstructuredAddress>
    </Address>

    <PostcodeOfUsualAddressAtDiagnosis>
      <xsl:value-of select="Property[@Name='Post Code']"/>
    </PostcodeOfUsualAddressAtDiagnosis>

    <PersonStatedGenderCode>
      <xsl:attribute name="code">
        <xsl:value-of select="Property[@Name='Sex']"/>
      </xsl:attribute>
    </PersonStatedGenderCode>
  </Demographics>


  <!-- ========================= -->
  <!-- Pathology Section         -->
  <!-- ========================= -->
  <Pathology>

    <InvestigationResultDate>
		<xsl:call-template name="dateTimeFormatter">
			<xsl:with-param name="dt" select="Property[@Name='Date &amp; Time Last Authorised']"/>
		</xsl:call-template>
    </InvestigationResultDate>

    <ServiceReportIdentifier>
      <xsl:attribute name="extension">
        <xsl:value-of select="Property[@Name='Specimen Number']"/>
      </xsl:attribute>
    </ServiceReportIdentifier>

    <ServiceReportStatus>
      <xsl:attribute name="code">
        <xsl:value-of select="Property[@Name='Service Report Status']"/>
      </xsl:attribute>
    </ServiceReportStatus>

    <ConsultantPathologyTestRequestedBy>
      <ProfessionalRegistrationIssuerCode-ConsultantPathologyTestRequestedBy>
        <xsl:attribute name="code">
          <xsl:value-of select="'03'"/>
        </xsl:attribute>
      </ProfessionalRegistrationIssuerCode-ConsultantPathologyTestRequestedBy>

      <ProfessionalRegistrationEntryIdentifier-ConsultantPathologyTestRequestedBy>
        <xsl:value-of select="Property[@Name='Requesting Clinician Code']"/>
      </ProfessionalRegistrationEntryIdentifier-ConsultantPathologyTestRequestedBy>
    </ConsultantPathologyTestRequestedBy>

    <OrganisationSiteIdentifierPathologyTestRequestedBy>
      <xsl:attribute name="extension">
        <xsl:value-of select="'RAE00'"/>
      </xsl:attribute>
    </OrganisationSiteIdentifierPathologyTestRequestedBy>

    <SampleReceiptDate>
	<xsl:call-template name="dateTimeFormatter">
			<xsl:with-param name="dt" select="Property[@Name='Date &amp; Time Booked In']"/>
		</xsl:call-template>
    </SampleReceiptDate>

    <OrganisationIdentifierOfReportingPathologist>
      <xsl:attribute name="extension">
        <xsl:value-of select="'RAE'"/>
      </xsl:attribute>
    </OrganisationIdentifierOfReportingPathologist>

    <ConsultantPathologist>
      <ProfessionalRegistrationIssuerCode-ConsultantPathologist>
        <xsl:attribute name="code">
          <xsl:value-of select="'03'"/>
        </xsl:attribute>
      </ProfessionalRegistrationIssuerCode-ConsultantPathologist>

      <ProfessionalRegistrationEntryIdentifier-ConsultantPathologist>
        <xsl:value-of select="Property[@Name='Reporting Pathologist Code']"/>
      </ProfessionalRegistrationEntryIdentifier-ConsultantPathologist>
    </ConsultantPathologist>

    <TopographyMorphologySnomed>
      <SnomedVersionPathology>
        <xsl:attribute name="code">
          <xsl:value-of select="'01'"/>
        </xsl:attribute>
      </SnomedVersionPathology>

      <TopographySnomedPathology>
        <xsl:attribute name="code">
          <xsl:value-of select="Property[@Name='All Diagnosis Codes']"/>
        </xsl:attribute>
      </TopographySnomedPathology>

      <MorphologySnomedPathology>
        <xsl:attribute name="code">
          <xsl:value-of select="Property[@Name='All Diagnosis Codes']"/>
        </xsl:attribute>
      </MorphologySnomedPathology>
    </TopographyMorphologySnomed>

    <PathologyReportText>
      <xsl:value-of select="Property[@Name='Report Output']"/>
    </PathologyReportText>

  </Pathology>

</OtherRecord>

      </xsl:for-each>

    </COSD_Pathology:COSD_Pathology>

  </xsl:template>
	<xsl:template name="dateTimeFormatter">
		<xsl:param name="dt"/>
		<xsl:value-of select="concat(
    substring($dt,7,4),'-',
    substring($dt,4,2),'-',
    substring($dt,1,2))"/>
	</xsl:template>
</xsl:stylesheet>
