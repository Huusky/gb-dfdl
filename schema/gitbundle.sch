<?xml version="1.0" encoding="UTF-8"?>
<!--
  Schematron rules for the GitLab git bundle infoset.

  This file MIRRORS the nine validation rules already enforced by the DFDL
  schema (schema/gitbundle.dfdl.xsd; design spec section 5). It is a
  secondary, human-readable statement of those rules.

  IMPORTANT - what this can and cannot do:
  Schematron validates the *parsed infoset*, i.e. it runs AFTER Daffodil has
  parsed a bundle. gitbundle.dfdl.xsd already rejects every one of these nine
  violations at parse time, so a non-conforming bundle never produces an
  infoset for these rules to inspect. In normal operation these assertions
  therefore never fire - they are documentation and defence in depth, not the
  primary gate. gitbundle.dfdl.xsd remains the authoritative validator.

  Usage - Apache Daffodil 4.1.0 bundles the schematron validator, so
  (-V is the short form of the validate option):

    daffodil parse -V schematron=schema/gitbundle.sch \
        -s schema/gitbundle.dfdl.xsd -r gitBundle some.bundle

  queryBinding is xslt2: Daffodil 4.1.0 bundles Saxon-HE, so XPath 2.0
  (matches(), if/then/else) is available.
-->
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    queryBinding="xslt2">

  <sch:title>GitLab git bundle - validation rules</sch:title>
  <sch:ns prefix="gb" uri="urn:gitlab:git-bundle:1.0"/>

  <!-- Rule 1: the signature is exactly "# v2 git bundle" or
       "# v3 git bundle". -->
  <sch:pattern id="rule-1-signature">
    <sch:rule context="gb:signature">
      <sch:assert test="gb:format = '# v'">Rule 1: the bundle signature must begin with "# v".</sch:assert>
      <sch:assert test="gb:version = '2' or gb:version = '3'">Rule 1: the bundle version must be 2 or 3.</sch:assert>
      <sch:assert test="gb:label = ' git bundle'">Rule 1: the signature label must be " git bundle".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 2: @capability lines occur only in a v3 bundle. -->
  <sch:pattern id="rule-2-capabilities-v3-only">
    <sch:rule context="gb:capabilities">
      <sch:assert test="../gb:signature/gb:version = '3' or count(gb:capability) = 0">Rule 2: a v2 git bundle must not contain @capability lines.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 3: a capability key is one of the known keys. -->
  <sch:pattern id="rule-3-capability-key">
    <sch:rule context="gb:capability/gb:key">
      <sch:assert test=". = 'object-format' or . = 'filter'">Rule 3: capability key must be "object-format" or "filter".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 4: an object-format capability value is sha1 or sha256. -->
  <sch:pattern id="rule-4-object-format-value">
    <sch:rule context="gb:capability[gb:key = 'object-format']/gb:assignment/gb:value">
      <sch:assert test=". = 'sha1' or . = 'sha256'">Rule 4: an object-format capability value must be "sha1" or "sha256".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 5: object ids are lowercase hex, 40 (SHA-1) or 64 (SHA-256)
       characters, consistent with the declared hash format and each other.
       The single length test, evaluated on every object id, also enforces
       the "consistent with each other" part. -->
  <sch:pattern id="rule-5-object-id">
    <sch:rule context="gb:objectId">
      <sch:assert test="matches(., '^[0-9a-f]+$')">Rule 5: an object id must be lowercase hexadecimal.</sch:assert>
      <sch:assert test="if (//gb:capability[gb:key = 'object-format']/gb:assignment/gb:value = 'sha256') then string-length(.) = 64 else string-length(.) = 40">Rule 5: object id length must match the bundle hash format - 64 hex characters for SHA-256 (object-format=sha256), otherwise 40 for SHA-1.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 6: free-text header fields contain no control characters. The
       regex \p{Cc} is the Unicode control category; the class subtraction
       removes the C1 range (0x80-0x9F) so the test matches exactly bytes
       0x00-0x1F and 0x7F, which is what rule 6 forbids. -->
  <sch:pattern id="rule-6-no-control-characters">
    <sch:rule context="gb:refName | gb:comment | gb:value">
      <sch:assert test="not(matches(., '[\p{Cc}-[&#x80;-&#x9F;]]'))">Rule 6: header text fields must not contain control characters (bytes 0x00-0x1F or 0x7F).</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 7: a reference name is non-empty. -->
  <sch:pattern id="rule-7-refname-non-empty">
    <sch:rule context="gb:reference/gb:refName">
      <sch:assert test="string-length(.) > 0">Rule 7: a reference name must not be empty.</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 8: the packfile magic is "PACK". -->
  <sch:pattern id="rule-8-pack-magic">
    <sch:rule context="gb:packfile/gb:magic">
      <sch:assert test=". = 'PACK'">Rule 8: the packfile magic must be "PACK".</sch:assert>
    </sch:rule>
  </sch:pattern>

  <!-- Rule 9: the packfile version is 2 or 3. -->
  <sch:pattern id="rule-9-pack-version">
    <sch:rule context="gb:packfile/gb:version">
      <sch:assert test=". = '2' or . = '3'">Rule 9: the packfile version must be 2 or 3.</sch:assert>
    </sch:rule>
  </sch:pattern>

</sch:schema>
