@IsTest
private class WorkflowDataMapperTest {
    private static final String CUSTOMER_JSON =
        '{' +
        '"fullName":"Ajay",' +
        '"email":"test@gmail.com",' +
        '"phone":"9999999999",' +
        '"customerType":"Individual",' +
        '"address":"ABC Street",' +
        '"city":"Indore",' +
        '"state":"MP",' +
        '"postalCode":"452001"' +
        '}';

    private static final String DEALER_JSON =
        '{' +
        '"companyName":"Acme Motors",' +
        '"businessEmail":"dealer@acme.com",' +
        '"businessType":"ServicePartner",' +
        '"gstNumber":"22AAAAA0000A1Z5",' +
        '"bankName":"HDFC",' +
        '"accountNumber":"1234567890",' +
        '"ifscCode":"HDFC0001234"' +
        '}';

    private static final String WARRANTY_JSON =
        '{' +
        '"productName":"Smart TV",' +
        '"serialNumber":"SN-10001",' +
        '"purchaseDate":"2024-05-10",' +
        '"issueType":"PhysicalDamage",' +
        '"issueDescription":"Screen cracked",' +
        '"severity":"High"' +
        '}';

    @IsTest
    static void hydratesCustomerOnboardingFromTrigger() {
        Customer_Onboarding__c record = new Customer_Onboarding__c(
            JSON_Data__c = CUSTOMER_JSON,
            Status__c = 'Submitted'
        );

        Test.startTest();
        insert record;
        Test.stopTest();

        Customer_Onboarding__c result = [
            SELECT Full_Name__c, Email__c, Phone_Number__c, Customer_Type__c,
                   Address__c, City__c, State__c, Postal_Code__c, JSON_Data__c
            FROM Customer_Onboarding__c
            WHERE Id = :record.Id
        ];

        System.assertEquals('Ajay', result.Full_Name__c);
        System.assertEquals('test@gmail.com', result.Email__c);
        System.assertEquals('9999999999', result.Phone_Number__c);
        System.assertEquals('Individual', result.Customer_Type__c);
        System.assertEquals('ABC Street', result.Address__c);
        System.assertEquals('Indore', result.City__c);
        System.assertEquals('MP', result.State__c);
        System.assertEquals('452001', result.Postal_Code__c);
        System.assertEquals(CUSTOMER_JSON, result.JSON_Data__c);
    }

    @IsTest
    static void hydratesDealerRegistrationFromMapper() {
        Dealer_Registration__c record = new Dealer_Registration__c(
            JSON_Data__c = DEALER_JSON,
            Workflow_Type__c = 'Dealer Registration',
            Status__c = 'Submitted'
        );
        insert record;

        Test.startTest();
        WorkflowDataMapper.hydrateRecordById(record.Id, null);
        Test.stopTest();

        Dealer_Registration__c result = [
            SELECT Company_Name__c, Email__c, Business_Type__c, GST_Number__c,
                   Bank_Name__c, Account_Number__c, IFSC_Code__c
            FROM Dealer_Registration__c
            WHERE Id = :record.Id
        ];

        System.assertEquals('Acme Motors', result.Company_Name__c);
        System.assertEquals('dealer@acme.com', result.Email__c);
        System.assertEquals('Service Partner', result.Business_Type__c);
        System.assertEquals('22AAAAA0000A1Z5', result.GST_Number__c);
        System.assertEquals('HDFC', result.Bank_Name__c);
        System.assertEquals('1234567890', result.Account_Number__c);
        System.assertEquals('HDFC0001234', result.IFSC_Code__c);
    }

    @IsTest
    static void hydratesWarrantyClaimThroughInvocable() {
        Warranty_Claim__c record = new Warranty_Claim__c(
            JSON_Data__c = WARRANTY_JSON,
            Workflow_Type__c = 'Warranty Claim',
            Status__c = 'Submitted'
        );
        insert record;

        WorkflowDataMapper.HydrateRequest request = new WorkflowDataMapper.HydrateRequest();
        request.recordId = record.Id;
        request.jsonPayload = WARRANTY_JSON;

        Test.startTest();
        List<WorkflowDataMapper.HydrateResult> results = WorkflowDataMapper.hydrateFromFlow(
            new List<WorkflowDataMapper.HydrateRequest>{ request }
        );
        Test.stopTest();

        System.assertEquals(true, results[0].success);

        Warranty_Claim__c result = [
            SELECT Product_Name__c, Serial_Number__c, Purchase_Date__c,
                   Issue_Type__c, Issue_Description__c, Severity__c
            FROM Warranty_Claim__c
            WHERE Id = :record.Id
        ];

        System.assertEquals('Smart TV', result.Product_Name__c);
        System.assertEquals('SN-10001', result.Serial_Number__c);
        System.assertEquals(Date.newInstance(2024, 5, 10), result.Purchase_Date__c);
        System.assertEquals('Physical Damage', result.Issue_Type__c);
        System.assertEquals('Screen cracked', result.Issue_Description__c);
        System.assertEquals('High', result.Severity__c);
    }

    @IsTest
    static void parsesNestedWorkflowResponsePayload() {
        String nestedJson =
            '{' +
            '"workflowType":"CustomerOnboarding",' +
            '"formData":' + CUSTOMER_JSON +
            '}';

        Map<String, Object> payload = WorkflowDataMapper.parseJsonPayload(nestedJson);
        System.assertEquals('Ajay', payload.get('fullName'));
        System.assertEquals('Indore', payload.get('city'));
    }

    @IsTest
    static void skipsInvalidJsonSafely() {
        Customer_Onboarding__c record = new Customer_Onboarding__c(
            JSON_Data__c = 'not-valid-json',
            Status__c = 'Submitted'
        );

        Test.startTest();
        insert record;
        Test.stopTest();

        Customer_Onboarding__c result = [
            SELECT Full_Name__c, Email__c
            FROM Customer_Onboarding__c
            WHERE Id = :record.Id
        ];

        System.assertEquals(null, result.Full_Name__c);
        System.assertEquals(null, result.Email__c);
    }

    @IsTest
    static void rehydratesWhenJsonDataChanges() {
        Customer_Onboarding__c record = new Customer_Onboarding__c(
            JSON_Data__c = '{"fullName":"Initial","email":"initial@test.com","phone":"1111111111"}',
            Status__c = 'Submitted'
        );
        insert record;

        record.JSON_Data__c = '{"fullName":"Updated","email":"updated@test.com","phone":"2222222222"}';

        Test.startTest();
        update record;
        Test.stopTest();

        Customer_Onboarding__c result = [
            SELECT Full_Name__c, Email__c, Phone_Number__c
            FROM Customer_Onboarding__c
            WHERE Id = :record.Id
        ];

        System.assertEquals('Updated', result.Full_Name__c);
        System.assertEquals('updated@test.com', result.Email__c);
        System.assertEquals('2222222222', result.Phone_Number__c);
    }
}
