/**
 * Central registry mapping LWC JSON keys (camelCase) to Salesforce field API names.
 * Add new workflows by extending the object-specific mapping methods.
 */
public with sharing class WorkflowFieldMappingRegistry {
    private static final String CUSTOMER_ONBOARDING = 'Customer_Onboarding__c';
    private static final String DEALER_REGISTRATION = 'Dealer_Registration__c';
    private static final String WARRANTY_CLAIM = 'Warranty_Claim__c';

    private static Map<String, Map<String, String>> mappingsByObject;

    /**
     * Returns a copy of JSON-key to field-API mappings for the given object.
     */
    public static Map<String, String> getMappingsForObject(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return new Map<String, String>();
        }
        ensureMappingsLoaded();
        Map<String, String> mappings = mappingsByObject.get(objectApiName);
        return mappings == null ? new Map<String, String>() : mappings.clone();
    }

    public static Boolean isSupportedObject(String objectApiName) {
        ensureMappingsLoaded();
        return mappingsByObject.containsKey(objectApiName);
    }

    private static void ensureMappingsLoaded() {
        if (mappingsByObject != null) {
            return;
        }
        mappingsByObject = new Map<String, Map<String, String>>{
            CUSTOMER_ONBOARDING => customerOnboardingMappings(),
            DEALER_REGISTRATION => dealerRegistrationMappings(),
            WARRANTY_CLAIM => warrantyClaimMappings()
        };
    }

    private static Map<String, String> customerOnboardingMappings() {
        return new Map<String, String>{
            'fullName' => 'Full_Name__c',
            'email' => 'Email__c',
            'phone' => 'Phone_Number__c',
            'customerType' => 'Customer_Type__c',
            'address' => 'Address__c',
            'city' => 'City__c',
            'state' => 'State__c',
            'postalCode' => 'Postal_Code__c',
            'gstNumber' => 'GST_Number__c',
            'preferredContactMethod' => 'Preferred_Contact_Method__c'
        };
    }

    private static Map<String, String> dealerRegistrationMappings() {
        return new Map<String, String>{
            'companyName' => 'Company_Name__c',
            'businessEmail' => 'Email__c',
            'businessType' => 'Business_Type__c',
            'gstNumber' => 'GST_Number__c',
            'bankName' => 'Bank_Name__c',
            'accountNumber' => 'Account_Number__c',
            'ifscCode' => 'IFSC_Code__c',
            'licenseNumber' => 'License_Number__c',
            'fullName' => 'Full_Name__c',
            'email' => 'Email__c',
            'phone' => 'Phone_Number__c'
        };
    }

    private static Map<String, String> warrantyClaimMappings() {
        return new Map<String, String>{
            'productName' => 'Product_Name__c',
            'serialNumber' => 'Serial_Number__c',
            'purchaseDate' => 'Purchase_Date__c',
            'issueType' => 'Issue_Type__c',
            'issueDescription' => 'Issue_Description__c',
            'severity' => 'Severity__c',
            'invoiceNumber' => 'Invoice_Number__c',
            'fullName' => 'Full_Name__c',
            'email' => 'Email__c',
            'phone' => 'Phone_Number__c'
        };
    }
}
