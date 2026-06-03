$flowDirectory = "force-app/main/default/flows"
$flowPath = Join-Path $flowDirectory "Unified_Workflow_Flow.flow-meta.xml"

function Escape-Xml {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

function ValueXml {
    param([string]$Type, [object]$Value)
    if ($Type -eq "ref") { return "<value><elementReference>$Value</elementReference></value>" }
    if ($Type -eq "bool") { return "<value><booleanValue>$($Value.ToString().ToLowerInvariant())</booleanValue></value>" }
    return "<value><stringValue>$(Escape-Xml ([string]$Value))</stringValue></value>"
}

function AssignmentItemXml {
    param([string]$Target, [string]$Type, [object]$Value)
    return @"
        <assignmentItems>
            <assignToReference>$Target</assignToReference>
            <operator>Assign</operator>
            $(ValueXml $Type $Value)
        </assignmentItems>
"@
}

function AssignmentXml {
    param([string]$Name, [string]$Label, [array]$Items, [string]$Target, [int]$X, [int]$Y)
    $connector = if ($Target) { "<connector><targetReference>$Target</targetReference></connector>" } else { "" }
    return @"
    <assignments>
        <name>$Name</name>
        <label>$(Escape-Xml $Label)</label>
        <locationX>$X</locationX>
        <locationY>$Y</locationY>
$($Items -join "`n")
        $connector
    </assignments>
"@
}

function ConstantXml {
    param([string]$Name, [string]$Value)
    return @"
    <constants>
        <name>$Name</name>
        <dataType>String</dataType>
        <value>
            <stringValue>$(Escape-Xml $Value)</stringValue>
        </value>
    </constants>
"@
}

function ChoiceXml {
    param([string]$Name, [string]$Label, [string]$Value)
    return @"
    <choices>
        <name>$Name</name>
        <choiceText>$(Escape-Xml $Label)</choiceText>
        <dataType>String</dataType>
        <value>
            <stringValue>$Value</stringValue>
        </value>
    </choices>
"@
}

function DisplayTextFieldXml {
    param([string]$Name, [string]$Text)
    return @"
        <fields>
            <name>$Name</name>
            <fieldText>$(Escape-Xml $Text)</fieldText>
            <fieldType>DisplayText</fieldType>
            <styleProperties>
                <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
                <width><stringValue>12</stringValue></width>
            </styleProperties>
        </fields>
"@
}

function RadioFieldXml {
    return @"
        <fields>
            <name>workflowTypeSelector</name>
            <choiceReferences>CustomerOnboardingChoice</choiceReferences>
            <choiceReferences>DealerRegistrationChoice</choiceReferences>
            <choiceReferences>WarrantyClaimChoice</choiceReferences>
            <dataType>String</dataType>
            <fieldText>Select Workflow</fieldText>
            <fieldType>RadioButtons</fieldType>
            <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
            <isRequired>true</isRequired>
            <styleProperties>
                <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
                <width><stringValue>12</stringValue></width>
            </styleProperties>
        </fields>
"@
}

function DynamicFormFieldXml {
    param([string]$Name, [string]$WorkflowTypeValue, [string]$ConfigReference)
    return @"
        <fields>
            <name>$Name</name>
            <extensionName>c:dynamicFormRenderer</extensionName>
            <fieldType>ComponentInstance</fieldType>
            <inputParameters>
                <name>workflowType</name>
                <value><stringValue>$WorkflowTypeValue</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>fieldConfigJson</name>
                <value><elementReference>$ConfigReference</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>existingDataJson</name>
                <value><elementReference>existingDataJson</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>currentStep</name>
                <value><elementReference>currentStep</elementReference></value>
            </inputParameters>
            <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
            <isRequired>true</isRequired>
            <outputParameters>
                <assignToReference>formDataJson</assignToReference>
                <name>formDataJson</name>
            </outputParameters>
            <outputParameters>
                <assignToReference>isStepValid</assignToReference>
                <name>isStepValid</name>
            </outputParameters>
            <outputParameters>
                <assignToReference>workflowResponseJson</assignToReference>
                <name>workflowResponseJson</name>
            </outputParameters>
            <storeOutputAutomatically>false</storeOutputAutomatically>
            <styleProperties>
                <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
                <width><stringValue>12</stringValue></width>
            </styleProperties>
        </fields>
"@
}

function ReviewSummaryFieldXml {
    param([string]$Name, [string]$WorkflowTypeValue, [string]$ConfigReference)
    return @"
        <fields>
            <name>$Name</name>
            <extensionName>c:reviewSummary</extensionName>
            <fieldType>ComponentInstance</fieldType>
            <inputParameters>
                <name>workflowType</name>
                <value><stringValue>$WorkflowTypeValue</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>formDataJson</name>
                <value><elementReference>formDataJson</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>fieldConfigJson</name>
                <value><elementReference>$ConfigReference</elementReference></value>
            </inputParameters>
            <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
            <isRequired>true</isRequired>
            <storeOutputAutomatically>true</storeOutputAutomatically>
            <styleProperties>
                <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
                <width><stringValue>12</stringValue></width>
            </styleProperties>
        </fields>
"@
}

function CheckboxFieldXml {
    param([string]$Name)
    return @"
        <fields>
            <name>$Name</name>
            <dataType>Boolean</dataType>
            <fieldText>I confirm the above information is correct.</fieldText>
            <fieldType>InputField</fieldType>
            <inputsOnNextNavToAssocScrn>UseStoredValues</inputsOnNextNavToAssocScrn>
            <isRequired>true</isRequired>
            <styleProperties>
                <verticalAlignment><stringValue>top</stringValue></verticalAlignment>
                <width><stringValue>12</stringValue></width>
            </styleProperties>
        </fields>
"@
}

function ScreenXml {
    param([string]$Name, [string]$Label, [array]$Fields, [string]$Target, [int]$X, [int]$Y, [bool]$Terminal = $false)
    $connector = if ($Target) { "<connector><targetReference>$Target</targetReference></connector>" } else { "" }
    $allowFinish = if ($Terminal) { "true" } else { "false" }
    return @"
    <screens>
        <name>$Name</name>
        <label>$(Escape-Xml $Label)</label>
        <locationX>$X</locationX>
        <locationY>$Y</locationY>
        <allowBack>true</allowBack>
        <allowFinish>$allowFinish</allowFinish>
        <allowPause>true</allowPause>
        $connector
$($Fields -join "`n")
        <showFooter>true</showFooter>
        <showHeader>true</showHeader>
    </screens>
"@
}

function DecisionRuleXml {
    param([string]$Name, [string]$Label, [string]$Left, [string]$Type, [object]$Right, [string]$Target)
    return @"
        <rules>
            <name>$Name</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>$Left</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>$(if ($Type -eq "bool") { "<booleanValue>$($Right.ToString().ToLowerInvariant())</booleanValue>" } else { "<stringValue>$Right</stringValue>" })</rightValue>
            </conditions>
            <connector><targetReference>$Target</targetReference></connector>
            <label>$(Escape-Xml $Label)</label>
        </rules>
"@
}

function DecisionXml {
    param([string]$Name, [string]$Label, [array]$Rules, [string]$DefaultTarget, [string]$DefaultLabel, [int]$X, [int]$Y)
    return @"
    <decisions>
        <name>$Name</name>
        <label>$(Escape-Xml $Label)</label>
        <locationX>$X</locationX>
        <locationY>$Y</locationY>
        <defaultConnector><targetReference>$DefaultTarget</targetReference></defaultConnector>
        <defaultConnectorLabel>$(Escape-Xml $DefaultLabel)</defaultConnectorLabel>
$($Rules -join "`n")
    </decisions>
"@
}

function RecordCreateXml {
    param([string]$Name, [string]$Label, [string]$ObjectName, [string]$SuccessTarget, [string]$FaultTarget, [string]$NameValue)
    $flowCurrentDateTime = '$Flow.CurrentDateTime'
    return @"
    <recordCreates>
        <name>$Name</name>
        <label>$(Escape-Xml $Label)</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>$SuccessTarget</targetReference></connector>
        <faultConnector><targetReference>$FaultTarget</targetReference></faultConnector>
        <inputAssignments><field>Name</field><value><stringValue>$NameValue</stringValue></value></inputAssignments>
        <inputAssignments><field>Workflow_Type__c</field><value><elementReference>workflowType</elementReference></value></inputAssignments>
        <inputAssignments><field>Status__c</field><value><elementReference>workflowStatus</elementReference></value></inputAssignments>
        <inputAssignments><field>JSON_Data__c</field><value><elementReference>formDataJson</elementReference></value></inputAssignments>
        <inputAssignments><field>Submission_Date__c</field><value><elementReference>$flowCurrentDateTime</elementReference></value></inputAssignments>
        <object>$ObjectName</object>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordCreates>
"@
}

function VariableXml {
    param([string]$Name, [string]$DataType, [bool]$Input, [bool]$Output, [string]$DefaultType = "", [object]$DefaultValue = $null)
    $valueXml = if ($DefaultType) { ValueXml $DefaultType $DefaultValue } else { "" }
    return @"
    <variables>
        <name>$Name</name>
        <dataType>$DataType</dataType>
        <isCollection>false</isCollection>
        <isInput>$($Input.ToString().ToLowerInvariant())</isInput>
        <isOutput>$($Output.ToString().ToLowerInvariant())</isOutput>
        $valueXml
    </variables>
"@
}

$configs = @{
    customerPersonalInfoConfig = '[{"name":"fullName","label":"Full Name","type":"text","required":true,"placeholder":"Enter Full Name","visible":true,"visibleWhen":null},{"name":"email","label":"Email Address","type":"email","required":true,"placeholder":"Enter Email","visible":true,"visibleWhen":null},{"name":"phone","label":"Phone Number","type":"phone","required":true,"placeholder":"Enter 10-digit Phone","visible":true,"visibleWhen":null},{"name":"customerType","label":"Customer Type","type":"picklist","required":true,"options":[{"label":"Individual","value":"Individual"},{"label":"Business","value":"Business"}],"visible":true,"visibleWhen":null},{"name":"gstNumber","label":"GST Number","type":"text","required":true,"placeholder":"Enter GST Number","visible":false,"visibleWhen":{"field":"customerType","operator":"equals","value":"Business"}}]'
    customerAddressConfig = '[{"name":"address","label":"Full Address","type":"textarea","required":true,"placeholder":"Enter Full Address","visible":true,"visibleWhen":null},{"name":"city","label":"City","type":"text","required":true,"placeholder":"Enter City","visible":true,"visibleWhen":null},{"name":"state","label":"State","type":"text","required":true,"placeholder":"Enter State","visible":true,"visibleWhen":null},{"name":"postalCode","label":"Postal Code","type":"text","required":true,"placeholder":"Enter Postal Code","visible":true,"visibleWhen":null}]'
    dealerCompanyConfig = '[{"name":"companyName","label":"Company Name","type":"text","required":true,"placeholder":"Enter Company Name","visible":true,"visibleWhen":null},{"name":"businessEmail","label":"Business Email","type":"email","required":true,"placeholder":"Enter Business Email","visible":true,"visibleWhen":null},{"name":"businessType","label":"Business Type","type":"picklist","required":true,"options":[{"label":"Distributor","value":"Distributor"},{"label":"Reseller","value":"Reseller"},{"label":"Service Partner","value":"ServicePartner"}],"visible":true,"visibleWhen":null},{"name":"gstNumber","label":"GST Number","type":"text","required":true,"placeholder":"Enter GST Number","visible":true,"visibleWhen":null}]'
    dealerBankingConfig = '[{"name":"bankName","label":"Bank Name","type":"text","required":true,"placeholder":"Enter Bank Name","visible":true,"visibleWhen":null},{"name":"accountNumber","label":"Account Number","type":"text","required":true,"placeholder":"Enter Account Number","visible":true,"visibleWhen":null},{"name":"ifscCode","label":"IFSC Code","type":"text","required":true,"placeholder":"Enter IFSC Code","visible":true,"visibleWhen":null}]'
    warrantyProductConfig = '[{"name":"productName","label":"Product Name","type":"text","required":true,"placeholder":"Enter Product Name","visible":true,"visibleWhen":null},{"name":"serialNumber","label":"Serial Number","type":"text","required":true,"placeholder":"Enter Serial Number","visible":true,"visibleWhen":null},{"name":"purchaseDate","label":"Purchase Date","type":"date","required":true,"visible":true,"visibleWhen":null}]'
    warrantyIssueConfig = '[{"name":"issueType","label":"Issue Type","type":"picklist","required":true,"options":[{"label":"Physical Damage","value":"PhysicalDamage"},{"label":"Manufacturing Defect","value":"ManufacturingDefect"},{"label":"Performance Issue","value":"PerformanceIssue"},{"label":"Other","value":"Other"}],"visible":true,"visibleWhen":null},{"name":"issueDescription","label":"Issue Description","type":"textarea","required":true,"placeholder":"Describe the issue","visible":true,"visibleWhen":null},{"name":"severity","label":"Severity","type":"picklist","required":true,"options":[{"label":"Low","value":"Low"},{"label":"Medium","value":"Medium"},{"label":"High","value":"High"},{"label":"Critical","value":"Critical"}],"visible":true,"visibleWhen":null}]'
}

New-Item -ItemType Directory -Force -Path $flowDirectory | Out-Null

$constants = $configs.Keys | Sort-Object | ForEach-Object { ConstantXml $_ $configs[$_] }
$choices = @(
    ChoiceXml "CustomerOnboardingChoice" "Customer Onboarding" "CustomerOnboarding"
    ChoiceXml "DealerRegistrationChoice" "Dealer Registration" "DealerRegistration"
    ChoiceXml "WarrantyClaimChoice" "Warranty Claim" "WarrantyClaim"
)

$assignments = @(
    AssignmentXml "Set_Selected_Workflow" "Set Selected Workflow" @((AssignmentItemXml "workflowType" "ref" "workflowTypeSelector")) "Workflow_Router" 500 75
    AssignmentXml "Set_Customer_Step1" "Set Customer Step 1" @((AssignmentItemXml "currentStep" "string" "Step1"), (AssignmentItemXml "workflowStatus" "string" "InProgress"), (AssignmentItemXml "isStepValid" "bool" $false)) "Customer_Personal_Info_Screen" 100 200
    AssignmentXml "Persist_Customer_Step1" "Persist Customer Step 1" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Customer_Step2" 100 500
    AssignmentXml "Set_Customer_Step2" "Set Customer Step 2" @((AssignmentItemXml "currentStep" "string" "Step2"), (AssignmentItemXml "isStepValid" "bool" $false)) "Customer_Address_Screen" 100 600
    AssignmentXml "Persist_Customer_Step2" "Persist Customer Step 2" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Customer_Review" 100 900
    AssignmentXml "Set_Customer_Review" "Set Customer Review" @((AssignmentItemXml "currentStep" "string" "Review"), (AssignmentItemXml "workflowStatus" "string" "Submitted")) "Customer_Review_Screen" 100 1000
    AssignmentXml "Set_Dealer_Step1" "Set Dealer Step 1" @((AssignmentItemXml "currentStep" "string" "Step1"), (AssignmentItemXml "workflowStatus" "string" "InProgress"), (AssignmentItemXml "isStepValid" "bool" $false)) "Dealer_Company_Info_Screen" 500 200
    AssignmentXml "Persist_Dealer_Step1" "Persist Dealer Step 1" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Dealer_Step2" 500 500
    AssignmentXml "Set_Dealer_Step2" "Set Dealer Step 2" @((AssignmentItemXml "currentStep" "string" "Step2"), (AssignmentItemXml "isStepValid" "bool" $false)) "Dealer_Banking_Screen" 500 600
    AssignmentXml "Persist_Dealer_Step2" "Persist Dealer Step 2" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Dealer_Review" 500 900
    AssignmentXml "Set_Dealer_Review" "Set Dealer Review" @((AssignmentItemXml "currentStep" "string" "Review"), (AssignmentItemXml "workflowStatus" "string" "Submitted")) "Dealer_Review_Screen" 500 1000
    AssignmentXml "Set_Warranty_Step1" "Set Warranty Step 1" @((AssignmentItemXml "currentStep" "string" "Step1"), (AssignmentItemXml "workflowStatus" "string" "InProgress"), (AssignmentItemXml "isStepValid" "bool" $false)) "Warranty_Product_Screen" 900 200
    AssignmentXml "Persist_Warranty_Step1" "Persist Warranty Step 1" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Warranty_Step2" 900 500
    AssignmentXml "Set_Warranty_Step2" "Set Warranty Step 2" @((AssignmentItemXml "currentStep" "string" "Step2"), (AssignmentItemXml "isStepValid" "bool" $false)) "Warranty_Issue_Screen" 900 600
    AssignmentXml "Persist_Warranty_Step2" "Persist Warranty Step 2" @((AssignmentItemXml "existingDataJson" "ref" "formDataJson")) "Set_Warranty_Review" 900 900
    AssignmentXml "Set_Warranty_Review" "Set Warranty Review" @((AssignmentItemXml "currentStep" "string" "Review"), (AssignmentItemXml "workflowStatus" "string" "Submitted")) "Warranty_Review_Screen" 900 1000
    AssignmentXml "Set_Invalid_Workflow_Error" "Set Invalid Workflow Error" @((AssignmentItemXml "errorMessage" "string" "Invalid workflow selected.")) "Error_Screen" 1300 300
    AssignmentXml "Set_Customer_Create_Error" "Set Customer Create Error" @((AssignmentItemXml "errorMessage" "string" "Failed to create Customer Onboarding record.")) "Error_Screen" 100 1300
    AssignmentXml "Set_Dealer_Create_Error" "Set Dealer Create Error" @((AssignmentItemXml "errorMessage" "string" "Failed to create Dealer Registration record.")) "Error_Screen" 500 1300
    AssignmentXml "Set_Warranty_Create_Error" "Set Warranty Create Error" @((AssignmentItemXml "errorMessage" "string" "Failed to create Warranty Claim record.")) "Error_Screen" 900 1300
    AssignmentXml "Set_Workflow_Completed" "Set Workflow Completed" @((AssignmentItemXml "workflowStatus" "string" "Completed")) "Success_Screen" 500 1500
)

$decisions = @(
    DecisionXml "Workflow_Router" "Workflow Router" @(
        DecisionRuleXml "Customer_Onboarding" "Customer Onboarding" "workflowType" "string" "CustomerOnboarding" "Set_Customer_Step1"
        DecisionRuleXml "Dealer_Registration" "Dealer Registration" "workflowType" "string" "DealerRegistration" "Set_Dealer_Step1"
        DecisionRuleXml "Warranty_Claim" "Warranty Claim" "workflowType" "string" "WarrantyClaim" "Set_Warranty_Step1"
    ) "Set_Invalid_Workflow_Error" "Invalid Workflow" 500 100
    DecisionXml "Validate_Personal_Info" "Validate Personal Info" @((DecisionRuleXml "Customer_Personal_Info_Valid" "Valid" "isStepValid" "bool" $true "Persist_Customer_Step1")) "Customer_Personal_Info_Screen" "Invalid" 100 400
    DecisionXml "Validate_Customer_Address" "Validate Customer Address" @((DecisionRuleXml "Customer_Address_Valid" "Valid" "isStepValid" "bool" $true "Persist_Customer_Step2")) "Customer_Address_Screen" "Invalid" 100 800
    DecisionXml "Validate_Dealer_Company" "Validate Dealer Company" @((DecisionRuleXml "Dealer_Company_Valid" "Valid" "isStepValid" "bool" $true "Persist_Dealer_Step1")) "Dealer_Company_Info_Screen" "Invalid" 500 400
    DecisionXml "Validate_Dealer_Banking" "Validate Dealer Banking" @((DecisionRuleXml "Dealer_Banking_Valid" "Valid" "isStepValid" "bool" $true "Persist_Dealer_Step2")) "Dealer_Banking_Screen" "Invalid" 500 800
    DecisionXml "Validate_Warranty_Product" "Validate Warranty Product" @((DecisionRuleXml "Warranty_Product_Valid" "Valid" "isStepValid" "bool" $true "Persist_Warranty_Step1")) "Warranty_Product_Screen" "Invalid" 900 400
    DecisionXml "Validate_Warranty_Issue" "Validate Warranty Issue" @((DecisionRuleXml "Warranty_Issue_Valid" "Valid" "isStepValid" "bool" $true "Persist_Warranty_Step2")) "Warranty_Issue_Screen" "Invalid" 900 800
)

$screens = @(
    ScreenXml "Workflow_Selection_Screen" "Workflow Selection" @((DisplayTextFieldXml "WelcomeMessage" "Welcome to the Unified Workflow Platform.<br/>Please select the workflow to proceed."), (RadioFieldXml)) "Set_Selected_Workflow" 500 0
    ScreenXml "Customer_Personal_Info_Screen" "Customer Personal Information" @((DynamicFormFieldXml "CustomerPersonalInfoForm" "CustomerOnboarding" "customerPersonalInfoConfig")) "Validate_Personal_Info" 100 300
    ScreenXml "Customer_Address_Screen" "Customer Address Information" @((DynamicFormFieldXml "CustomerAddressForm" "CustomerOnboarding" "customerAddressConfig")) "Validate_Customer_Address" 100 700
    ScreenXml "Customer_Review_Screen" "Customer Review and Submit" @((ReviewSummaryFieldXml "CustomerReviewSummary" "CustomerOnboarding" "customerPersonalInfoConfig"), (CheckboxFieldXml "CustomerConfirmation")) "Create_Customer_Onboarding_Record" 100 1100
    ScreenXml "Dealer_Company_Info_Screen" "Dealer Company Information" @((DynamicFormFieldXml "DealerCompanyForm" "DealerRegistration" "dealerCompanyConfig")) "Validate_Dealer_Company" 500 300
    ScreenXml "Dealer_Banking_Screen" "Dealer Banking Details" @((DynamicFormFieldXml "DealerBankingForm" "DealerRegistration" "dealerBankingConfig")) "Validate_Dealer_Banking" 500 700
    ScreenXml "Dealer_Review_Screen" "Dealer Review and Submit" @((ReviewSummaryFieldXml "DealerReviewSummary" "DealerRegistration" "dealerCompanyConfig"), (CheckboxFieldXml "DealerConfirmation")) "Create_Dealer_Registration_Record" 500 1100
    ScreenXml "Warranty_Product_Screen" "Warranty Product Information" @((DynamicFormFieldXml "WarrantyProductForm" "WarrantyClaim" "warrantyProductConfig")) "Validate_Warranty_Product" 900 300
    ScreenXml "Warranty_Issue_Screen" "Warranty Issue Information" @((DynamicFormFieldXml "WarrantyIssueForm" "WarrantyClaim" "warrantyIssueConfig")) "Validate_Warranty_Issue" 900 700
    ScreenXml "Warranty_Review_Screen" "Warranty Review and Submit" @((ReviewSummaryFieldXml "WarrantyReviewSummary" "WarrantyClaim" "warrantyProductConfig"), (CheckboxFieldXml "WarrantyConfirmation")) "Create_Warranty_Claim_Record" 900 1100
    ScreenXml "Success_Screen" "Submission Successful" @((DisplayTextFieldXml "SuccessMessage" "Your workflow has been submitted successfully.<br/>Our team will review your submission shortly.<br/><br/>Workflow Type: {!workflowType}<br/>Status: {!workflowStatus}")) "" 500 1600 $true
    ScreenXml "Error_Screen" "Submission Failed" @((DisplayTextFieldXml "ErrorMessageDisplay" "Something went wrong. Please try again or contact support.<br/><br/>{!errorMessage}")) "" 1300 500 $true
)

$records = @(
    RecordCreateXml "Create_Customer_Onboarding_Record" "Create Customer Onboarding Record" "Customer_Onboarding__c" "Set_Workflow_Completed" "Set_Customer_Create_Error" "CustomerOnboarding"
    RecordCreateXml "Create_Dealer_Registration_Record" "Create Dealer Registration Record" "Dealer_Registration__c" "Set_Workflow_Completed" "Set_Dealer_Create_Error" "DealerRegistration"
    RecordCreateXml "Create_Warranty_Claim_Record" "Create Warranty Claim Record" "Warranty_Claim__c" "Set_Workflow_Completed" "Set_Warranty_Create_Error" "WarrantyClaim"
)

$variables = @(
    VariableXml "workflowType" "String" $true $true
    VariableXml "currentStep" "String" $false $false "string" "Step1"
    VariableXml "workflowStatus" "String" $false $false "string" "Draft"
    VariableXml "formDataJson" "String" $true $true
    VariableXml "existingDataJson" "String" $false $false "string" ""
    VariableXml "workflowResponseJson" "String" $false $true
    VariableXml "isStepValid" "Boolean" $false $false "bool" $false
    VariableXml "errorMessage" "String" $false $false "string" ""
)

$flow = @"
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <areMetricsLoggedToDataCloud>false</areMetricsLoggedToDataCloud>
$($assignments -join "`n")
$($choices -join "`n")
$($constants -join "`n")
    <customProperties>
        <name>ScreenProgressIndicator</name>
        <value><stringValue>{&quot;location&quot;:&quot;top&quot;,&quot;type&quot;:&quot;simple&quot;}</stringValue></value>
    </customProperties>
$($decisions -join "`n")
    <description>Reusable multi-step workflow platform using Screen Flow and dynamic LWC rendering.</description>
    <environments>Default</environments>
    <interviewLabel>Unified Workflow Flow {!`$Flow.CurrentDateTime}</interviewLabel>
    <label>Unified Workflow Flow</label>
    <processMetadataValues><name>BuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>
    <processMetadataValues><name>CanvasMode</name><value><stringValue>FREE_FORM_CANVAS</stringValue></value></processMetadataValues>
    <processMetadataValues><name>OriginBuilderType</name><value><stringValue>LightningFlowBuilder</stringValue></value></processMetadataValues>
    <processType>Flow</processType>
$($records -join "`n")
$($screens -join "`n")
    <start>
        <locationX>500</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Workflow_Selection_Screen</targetReference></connector>
    </start>
    <status>Active</status>
$($variables -join "`n")
</Flow>
"@

Set-Content -Path $flowPath -Value $flow -Encoding UTF8
