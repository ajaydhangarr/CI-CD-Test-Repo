param(
    [string]$FlexipagesRoot = "force-app/main/default/flexipages"
)

$metadataNamespace = "http://soap.sforce.com/2006/04/metadata"

function ConvertTo-XmlText {
    param([AllowNull()][object]$Value)

    return [System.Security.SecurityElement]::Escape([string]$Value)
}

function New-FieldFacet {
    param(
        [string]$Name,
        [array]$Fields
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("    <flexiPageRegions>")
    foreach ($field in $Fields) {
        $identifier = ($field.apiName -replace "[^A-Za-z0-9]", "") + "Field"
        $lines.Add("        <itemInstances>")
        $lines.Add("            <fieldInstance>")
        $lines.Add("                <fieldInstanceProperties>")
        $lines.Add("                    <name>uiBehavior</name>")
        $lines.Add("                    <value>$($field.behavior)</value>")
        $lines.Add("                </fieldInstanceProperties>")
        $lines.Add("                <fieldItem>Record.$($field.apiName)</fieldItem>")
        $lines.Add("                <identifier>$identifier</identifier>")
        $lines.Add("            </fieldInstance>")
        $lines.Add("        </itemInstances>")
    }
    $lines.Add("        <name>$Name</name>")
    $lines.Add("        <type>Facet</type>")
    $lines.Add("    </flexiPageRegions>")

    return $lines
}

function New-ColumnFacet {
    param(
        [string]$Name,
        [array]$ColumnFacetNames
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("    <flexiPageRegions>")
    for ($index = 0; $index -lt $ColumnFacetNames.Count; $index++) {
        $columnNumber = $index + 1
        $lines.Add("        <itemInstances>")
        $lines.Add("            <componentInstance>")
        $lines.Add("                <componentInstanceProperties>")
        $lines.Add("                    <name>body</name>")
        $lines.Add("                    <value>$($ColumnFacetNames[$index])</value>")
        $lines.Add("                </componentInstanceProperties>")
        $lines.Add("                <componentName>flexipage:column</componentName>")
        $lines.Add("                <identifier>$($Name)_column$columnNumber</identifier>")
        $lines.Add("            </componentInstance>")
        $lines.Add("        </itemInstances>")
    }
    $lines.Add("        <name>$Name</name>")
    $lines.Add("        <type>Facet</type>")
    $lines.Add("    </flexiPageRegions>")

    return $lines
}

function New-FieldSectionInstance {
    param(
        [string]$Label,
        [string]$ColumnsFacet,
        [string]$Identifier
    )

    return @"
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>columns</name>
                    <value>$ColumnsFacet</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>horizontalAlignment</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>label</name>
                    <value>$(ConvertTo-XmlText $Label)</value>
                </componentInstanceProperties>
                <componentName>flexipage:fieldSection</componentName>
                <identifier>$Identifier</identifier>
            </componentInstance>
        </itemInstances>
"@
}

function New-FlexiPageMetadata {
    param(
        [string]$PageName,
        [string]$MasterLabel,
        [string]$SObjectType,
        [array]$Sections
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add('<?xml version="1.0" encoding="UTF-8"?>')
    $lines.Add("<FlexiPage xmlns=""$metadataNamespace"">")
    $lines.Add(@"
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>collapsed</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>enableActionsConfiguration</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>enableActionsInNative</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>hideChatterActions</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>numVisibleActions</name>
                    <value>3</value>
                </componentInstanceProperties>
                <componentName>force:highlightsPanel</componentName>
                <identifier>force_highlightsPanel</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>header</name>
        <type>Region</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>relatedListComponentOverride</name>
                    <value>NONE</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>rowsToDisplay</name>
                    <value>10</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>showActionBar</name>
                    <value>true</value>
                </componentInstanceProperties>
                <componentName>force:relatedListContainer</componentName>
                <identifier>force_relatedListContainer</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>relatedTabContent</name>
        <type>Facet</type>
    </flexiPageRegions>
"@)

    foreach ($section in $Sections) {
        $leftFacet = "$($section.key)_left"
        $rightFacet = "$($section.key)_right"
        $columnsFacet = "$($section.key)_columns"
        foreach ($line in (New-FieldFacet -Name $leftFacet -Fields $section.leftFields)) {
            $lines.Add($line)
        }
        foreach ($line in (New-FieldFacet -Name $rightFacet -Fields $section.rightFields)) {
            $lines.Add($line)
        }
        foreach ($line in (New-ColumnFacet -Name $columnsFacet -ColumnFacetNames @($leftFacet, $rightFacet))) {
            $lines.Add($line)
        }
    }

    $lines.Add("    <flexiPageRegions>")
    foreach ($section in $Sections) {
        $lines.Add((New-FieldSectionInstance -Label $section.label -ColumnsFacet "$($section.key)_columns" -Identifier "$($section.key)_section"))
    }
    $lines.Add("        <mode>Replace</mode>")
    $lines.Add("        <name>detailTabContent</name>")
    $lines.Add("        <type>Facet</type>")
    $lines.Add("    </flexiPageRegions>")
    $lines.Add(@"
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>body</name>
                    <value>relatedTabContent</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>title</name>
                    <value>Standard.Tab.relatedLists</value>
                </componentInstanceProperties>
                <componentName>flexipage:tab</componentName>
                <identifier>relatedListsTab</identifier>
            </componentInstance>
        </itemInstances>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>active</name>
                    <value>true</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>body</name>
                    <value>detailTabContent</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>title</name>
                    <value>Standard.Tab.detail</value>
                </componentInstanceProperties>
                <componentName>flexipage:tab</componentName>
                <identifier>detailTab</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>maintabs</name>
        <type>Facet</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>label</name>
                    <value>Tabs</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>tabs</name>
                    <value>maintabs</value>
                </componentInstanceProperties>
                <componentName>flexipage:tabset</componentName>
                <identifier>flexipage_tabset</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>main</name>
        <type>Region</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>showLegacyActivityComposer</name>
                    <value>false</value>
                </componentInstanceProperties>
                <componentName>runtime_sales_activities:activityPanel</componentName>
                <identifier>runtime_sales_activities_activityPanel</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>activityTabContent</name>
        <type>Facet</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>active</name>
                    <value>true</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>body</name>
                    <value>activityTabContent</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>title</name>
                    <value>Standard.Tab.activity</value>
                </componentInstanceProperties>
                <componentName>flexipage:tab</componentName>
                <identifier>activityTab</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>sidebartabs</name>
        <type>Facet</type>
    </flexiPageRegions>
    <flexiPageRegions>
        <itemInstances>
            <componentInstance>
                <componentInstanceProperties>
                    <name>label</name>
                    <value>Tabs</value>
                </componentInstanceProperties>
                <componentInstanceProperties>
                    <name>tabs</name>
                    <value>sidebartabs</value>
                </componentInstanceProperties>
                <componentName>flexipage:tabset</componentName>
                <identifier>flexipage_tabset2</identifier>
            </componentInstance>
        </itemInstances>
        <mode>Replace</mode>
        <name>sidebar</name>
        <type>Region</type>
    </flexiPageRegions>
    <masterLabel>$(ConvertTo-XmlText $MasterLabel)</masterLabel>
    <parentFlexiPage>flexipage__default_rec_L</parentFlexiPage>
    <sobjectType>$SObjectType</sobjectType>
    <template>
        <name>flexipage:recordHomeTemplateDesktop</name>
    </template>
    <type>RecordPage</type>
</FlexiPage>
"@)

    return ($lines -join [Environment]::NewLine)
}

$commonSections = @(
    @{
        key = "information"
        label = "Information"
        leftFields = @(@{ apiName = "Name"; behavior = "required" })
        rightFields = @(@{ apiName = "OwnerId"; behavior = "none" })
    },
    @{
        key = "workflow_user_information"
        label = "Workflow User Information"
        leftFields = @(
            @{ apiName = "Full_Name__c"; behavior = "none" },
            @{ apiName = "Email__c"; behavior = "none" }
        )
        rightFields = @(
            @{ apiName = "Phone_Number__c"; behavior = "none" },
            @{ apiName = "Assigned_User__c"; behavior = "none" }
        )
    },
    @{
        key = "workflow_tracking"
        label = "Workflow Tracking"
        leftFields = @(
            @{ apiName = "Workflow_Type__c"; behavior = "none" },
            @{ apiName = "Status__c"; behavior = "none" },
            @{ apiName = "Step_Status__c"; behavior = "none" }
        )
        rightFields = @(
            @{ apiName = "Submission_Date__c"; behavior = "none" },
            @{ apiName = "JSON_Data__c"; behavior = "none" }
        )
    }
)

$pageDefinitions = @(
    @{
        pageName = "Customer_Onboarding_Record_Page"
        masterLabel = "Customer Onboarding Record Page"
        sobjectType = "Customer_Onboarding__c"
        objectSection = @{
            key = "customer_details"
            label = "Customer Details"
            leftFields = @(
                @{ apiName = "Customer_Type__c"; behavior = "none" },
                @{ apiName = "Address__c"; behavior = "none" },
                @{ apiName = "State__c"; behavior = "none" }
            )
            rightFields = @(
                @{ apiName = "Preferred_Contact_Method__c"; behavior = "none" },
                @{ apiName = "City__c"; behavior = "none" },
                @{ apiName = "Postal_Code__c"; behavior = "none" }
            )
        }
    },
    @{
        pageName = "Dealer_Registration_Record_Page"
        masterLabel = "Dealer Registration Record Page"
        sobjectType = "Dealer_Registration__c"
        objectSection = @{
            key = "dealer_details"
            label = "Dealer Details"
            leftFields = @(
                @{ apiName = "Company_Name__c"; behavior = "none" },
                @{ apiName = "GST_Number__c"; behavior = "none" },
                @{ apiName = "Bank_Name__c"; behavior = "none" },
                @{ apiName = "IFSC_Code__c"; behavior = "none" }
            )
            rightFields = @(
                @{ apiName = "Business_Type__c"; behavior = "none" },
                @{ apiName = "License_Number__c"; behavior = "none" },
                @{ apiName = "Account_Number__c"; behavior = "none" }
            )
        }
    },
    @{
        pageName = "Warranty_Claim_Record_Page"
        masterLabel = "Warranty Claim Record Page"
        sobjectType = "Warranty_Claim__c"
        objectSection = @{
            key = "warranty_claim_details"
            label = "Warranty Claim Details"
            leftFields = @(
                @{ apiName = "Product_Name__c"; behavior = "none" },
                @{ apiName = "Purchase_Date__c"; behavior = "none" },
                @{ apiName = "Issue_Type__c"; behavior = "none" },
                @{ apiName = "Issue_Description__c"; behavior = "none" }
            )
            rightFields = @(
                @{ apiName = "Serial_Number__c"; behavior = "none" },
                @{ apiName = "Invoice_Number__c"; behavior = "none" },
                @{ apiName = "Severity__c"; behavior = "none" }
            )
        }
    }
)

New-Item -ItemType Directory -Force -Path $FlexipagesRoot | Out-Null

foreach ($pageDefinition in $pageDefinitions) {
    $sections = @($commonSections) + @($pageDefinition.objectSection) + @(
        @{
            key = "system_information"
            label = "System Information"
            leftFields = @(@{ apiName = "CreatedById"; behavior = "readonly" })
            rightFields = @(@{ apiName = "LastModifiedById"; behavior = "readonly" })
        }
    )

    New-FlexiPageMetadata `
        -PageName $pageDefinition.pageName `
        -MasterLabel $pageDefinition.masterLabel `
        -SObjectType $pageDefinition.sobjectType `
        -Sections $sections |
        Set-Content -Path (Join-Path $FlexipagesRoot "$($pageDefinition.pageName).flexipage-meta.xml") -Encoding UTF8
}
