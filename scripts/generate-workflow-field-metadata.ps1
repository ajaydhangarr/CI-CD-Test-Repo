param(
    [string]$ConfigPath = "config/workflow-field-structure.json",
    [string]$ObjectsRoot = "force-app/main/default/objects",
    [string]$PermissionSetsRoot = "force-app/main/default/permissionsets",
    [string]$PermissionSetName = "Workflow_Platform_All_Access"
)

$metadataNamespace = "http://soap.sforce.com/2006/04/metadata"
$config = Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json

function ConvertTo-XmlText {
    param([AllowNull()][object]$Value)

    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function Get-RelationshipName {
    param(
        [string]$ObjectApiName,
        [string]$FieldApiName
    )

    $objectStem = $ObjectApiName -replace "__c$", ""
    $fieldStem = $FieldApiName -replace "__c$", ""
    $name = "$($objectStem)_$($fieldStem)" -replace "[^A-Za-z0-9_]", "_"

    if ($name.Length -gt 40) {
        $name = $name.Substring(0, 40)
    }

    return $name
}

function New-ObjectMetadata {
    param([object]$ObjectDefinition)

    $nameFieldLabel = "$($ObjectDefinition.label) Name"

    return @"
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="$metadataNamespace">
    <deploymentStatus>Deployed</deploymentStatus>
    <description>$(ConvertTo-XmlText $ObjectDefinition.description)</description>
    <enableActivities>true</enableActivities>
    <enableBulkApi>true</enableBulkApi>
    <enableFeeds>false</enableFeeds>
    <enableHistory>true</enableHistory>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
    <enableSharing>true</enableSharing>
    <enableStreamingApi>true</enableStreamingApi>
    <label>$(ConvertTo-XmlText $ObjectDefinition.label)</label>
    <nameField>
        <label>$(ConvertTo-XmlText $nameFieldLabel)</label>
        <type>Text</type>
    </nameField>
    <pluralLabel>$(ConvertTo-XmlText $ObjectDefinition.pluralLabel)</pluralLabel>
    <sharingModel>ReadWrite</sharingModel>
</CustomObject>
"@
}

function New-FieldMetadata {
    param(
        [object]$FieldDefinition,
        [string]$ObjectApiName
    )

    $description = ConvertTo-XmlText $FieldDefinition.description
    $label = ConvertTo-XmlText $FieldDefinition.label
    $apiName = ConvertTo-XmlText $FieldDefinition.apiName
    $required = if ($null -ne $FieldDefinition.required) { [string]$FieldDefinition.required.ToString().ToLowerInvariant() } else { $null }
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add('<?xml version="1.0" encoding="UTF-8"?>')
    $lines.Add("<CustomField xmlns=""$metadataNamespace"">")
    $lines.Add("    <fullName>$apiName</fullName>")
    $lines.Add("    <description>$description</description>")

    switch ($FieldDefinition.type) {
        "Lookup" {
            $relationshipName = ConvertTo-XmlText (Get-RelationshipName -ObjectApiName $ObjectApiName -FieldApiName $FieldDefinition.apiName)
            $relationshipLabel = ConvertTo-XmlText "$($FieldDefinition.label) Records"
            $lines.Add("    <deleteConstraint>SetNull</deleteConstraint>")
            $lines.Add("    <label>$label</label>")
            $lines.Add("    <referenceTo>$(ConvertTo-XmlText $FieldDefinition.referenceTo)</referenceTo>")
            $lines.Add("    <relationshipLabel>$relationshipLabel</relationshipLabel>")
            $lines.Add("    <relationshipName>$relationshipName</relationshipName>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Lookup</type>")
        }
        "Picklist" {
            $lines.Add("    <label>$label</label>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Picklist</type>")
            $lines.Add("    <valueSet>")
            $lines.Add("        <restricted>true</restricted>")
            $lines.Add("        <valueSetDefinition>")
            $lines.Add("            <sorted>false</sorted>")
            foreach ($value in $FieldDefinition.values) {
                $escapedValue = ConvertTo-XmlText $value
                $lines.Add("            <value>")
                $lines.Add("                <fullName>$escapedValue</fullName>")
                $lines.Add("                <default>false</default>")
                $lines.Add("                <label>$escapedValue</label>")
                $lines.Add("            </value>")
            }
            $lines.Add("        </valueSetDefinition>")
            $lines.Add("    </valueSet>")
        }
        "Text" {
            $lines.Add("    <externalId>false</externalId>")
            $lines.Add("    <label>$label</label>")
            $lines.Add("    <length>$($FieldDefinition.length)</length>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Text</type>")
            $lines.Add("    <unique>false</unique>")
        }
        "Email" {
            $lines.Add("    <externalId>false</externalId>")
            $lines.Add("    <label>$label</label>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Email</type>")
            $lines.Add("    <unique>false</unique>")
        }
        "Phone" {
            $lines.Add("    <label>$label</label>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Phone</type>")
        }
        "LongTextArea" {
            $lines.Add("    <label>$label</label>")
            $lines.Add("    <length>$($FieldDefinition.length)</length>")
            $lines.Add("    <type>LongTextArea</type>")
            $lines.Add("    <visibleLines>$($FieldDefinition.visibleLines)</visibleLines>")
        }
        "DateTime" {
            $lines.Add("    <label>$label</label>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>DateTime</type>")
        }
        "Date" {
            $lines.Add("    <label>$label</label>")
            if ($required) {
                $lines.Add("    <required>$required</required>")
            }
            $lines.Add("    <type>Date</type>")
        }
        default {
            throw "Unsupported field type '$($FieldDefinition.type)' for $($FieldDefinition.apiName)."
        }
    }

    $lines.Add("</CustomField>")
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

function New-PermissionSetMetadata {
    param([object]$Config)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('<?xml version="1.0" encoding="UTF-8"?>')
    $lines.Add("<PermissionSet xmlns=""$metadataNamespace"">")
    $lines.Add("    <description>Grants access to reusable multi-step workflow objects and fields.</description>")

    foreach ($objectDefinition in $Config.objects) {
        $allFields = @($Config.commonFields) + @($objectDefinition.fields)
        foreach ($fieldDefinition in $allFields) {
            $fieldFullName = ConvertTo-XmlText "$($objectDefinition.apiName).$($fieldDefinition.apiName)"
            $lines.Add("    <fieldPermissions>")
            $lines.Add("        <editable>true</editable>")
            $lines.Add("        <field>$fieldFullName</field>")
            $lines.Add("        <readable>true</readable>")
            $lines.Add("    </fieldPermissions>")
        }
    }

    $lines.Add("    <hasActivationRequired>false</hasActivationRequired>")
    $lines.Add("    <label>Workflow Platform All Access</label>")

    foreach ($objectDefinition in $Config.objects) {
        $objectApiName = ConvertTo-XmlText $objectDefinition.apiName
        $lines.Add("    <objectPermissions>")
        $lines.Add("        <allowCreate>true</allowCreate>")
        $lines.Add("        <allowDelete>true</allowDelete>")
        $lines.Add("        <allowEdit>true</allowEdit>")
        $lines.Add("        <allowRead>true</allowRead>")
        $lines.Add("        <modifyAllRecords>false</modifyAllRecords>")
        $lines.Add("        <object>$objectApiName</object>")
        $lines.Add("        <viewAllRecords>false</viewAllRecords>")
        $lines.Add("    </objectPermissions>")
    }

    $lines.Add("</PermissionSet>")
    return ($lines -join [Environment]::NewLine) + [Environment]::NewLine
}

foreach ($objectDefinition in $config.objects) {
    $objectDirectory = Join-Path $ObjectsRoot $objectDefinition.apiName
    $fieldsDirectory = Join-Path $objectDirectory "fields"

    New-Item -ItemType Directory -Force -Path $fieldsDirectory | Out-Null
    New-ObjectMetadata -ObjectDefinition $objectDefinition |
        Set-Content -Path (Join-Path $objectDirectory "$($objectDefinition.apiName).object-meta.xml") -Encoding UTF8

    $allFields = @($config.commonFields) + @($objectDefinition.fields)
    foreach ($fieldDefinition in $allFields) {
        New-FieldMetadata -FieldDefinition $fieldDefinition -ObjectApiName $objectDefinition.apiName |
            Set-Content -Path (Join-Path $fieldsDirectory "$($fieldDefinition.apiName).field-meta.xml") -Encoding UTF8
    }
}

New-Item -ItemType Directory -Force -Path $PermissionSetsRoot | Out-Null
New-PermissionSetMetadata -Config $config |
    Set-Content -Path (Join-Path $PermissionSetsRoot "$PermissionSetName.permissionset-meta.xml") -Encoding UTF8
