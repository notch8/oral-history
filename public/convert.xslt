<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="tei" version="1.0">
    <xsl:output method="html" encoding="utf-8" indent="yes" />

    <xsl:template match="text">
      <div id="tei-content">
        <xsl:attribute name="data-object"><xsl:value-of select="../@xml:id"/></xsl:attribute>
        <xsl:apply-templates/>
      </div>
    </xsl:template>

    <xsl:template match="Header"></xsl:template>

    <xsl:template match="lb">
      <br/>
    </xsl:template>
    <xsl:template match="head">
      <div class="tei-head">
        <xsl:apply-templates/>
      </div>
    </xsl:template>


    <xsl:template match="opener">
      <div class="opener">
        <xsl:apply-templates/>
      </div>
    </xsl:template>
    <xsl:template match="note">
      <div class="note">
        <xsl:apply-templates/>
      </div>
    </xsl:template>

    <xsl:template match="date">
      <span class="date">
        <xsl:apply-templates/>
      </span>
    </xsl:template>
    <xsl:template match="p">
      <p>
        <xsl:apply-templates/>
      </p>
    </xsl:template>
    <xsl:template match="del">
      <del>
        <xsl:apply-templates/>
      </del>
    </xsl:template>
    <xsl:template match="unclear">
      <span class="unclear">
        <xsl:attribute name="data-reason"><xsl:value-of select="@reason"/></xsl:attribute>
        <xsl:apply-templates/>
      </span>
    </xsl:template>

    <xsl:template match="sp">
      <div class="sp">
        <xsl:apply-templates/>
      </div>
    </xsl:template>
    <xsl:template match="speaker">
      <span class="speaker">
        <xsl:apply-templates/>
      </span>
    </xsl:template>
    <xsl:template match="milestone">

      <span unit="timestamp" >
        <xsl:attribute name="data-start"><xsl:value-of select="@start"/></xsl:attribute>
        <xsl:apply-templates/>
      </span>
    </xsl:template>

</xsl:stylesheet>

