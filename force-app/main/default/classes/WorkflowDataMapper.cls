/**
 * Deserializes workflow JSON payloads and hydrates structured Salesforce fields.
 * JSON_Data__c remains the source of truth; structured fields are derived on save.
 */
public with sharing class WorkflowDataMapper {
    private static final String JSON_DATA_FIELD = 'JSON_Data__c';

    @TestVisible
    private static Boolean skipTriggerRecursion = false;

    /**
     * Invocable entry point for Screen Flow after record creation.
     */
    @InvocableMethod(
        label='Hydrate Workflow Fields from JSON'
        description='Parses JSON_Data__c and populates structured fields on workflow records.'
        category='Workflow Platform'
    )
    public static List<HydrateResult> hydrateFromFlow(List<HydrateRequest> requests) {
        List<HydrateResult> results = new List<HydrateResult>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        for (HydrateRequest request : requests) {
            HydrateResult result = new HydrateResult();
            result.success = false;
            results.add(result);

            if (request == null || request.recordId == null) {
                result.message = 'Record Id is required.';
                continue;
            }

            try {
                result.success = hydrateRecordById(request.recordId, request.jsonPayload);
                result.message = result.success
                    ? 'Structured fields hydrated successfully.'
                    : 'No structured fields were updated.';
            } catch (Exception ex) {
                result.message = ex.getMessage();
            }
        }

        return results;
    }

    /**
     * Hydrates a single record using JSON_Data__c when jsonPayload is blank.
     */
    public static Boolean hydrateRecordById(Id recordId, String jsonPayload) {
        if (recordId == null) {
            return false;
        }

        Schema.SObjectType objectType = recordId.getSObjectType();
        String objectApiName = objectType.getDescribe().getName();
        if (!WorkflowFieldMappingRegistry.isSupportedObject(objectApiName)) {
            return false;
        }

        SObject existingRecord = Database.query(
            'SELECT Id, ' + JSON_DATA_FIELD + ' FROM ' + objectApiName + ' WHERE Id = :recordId LIMIT 1'
        );

        if (String.isNotBlank(jsonPayload)) {
            existingRecord.put(JSON_DATA_FIELD, jsonPayload);
        }

        SObject hydratedRecord = buildHydratedRecord(existingRecord);
        if (hydratedRecord == null) {
            return false;
        }

        skipTriggerRecursion = true;
        try {
            update hydratedRecord;
        } finally {
            skipTriggerRecursion = false;
        }
        return true;
    }

    /**
     * Bulk hydrates records that contain JSON_Data__c. Used by triggers.
     */
    public static void hydrateRecords(List<SObject> records) {
        if (records == null || records.isEmpty() || skipTriggerRecursion) {
            return;
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        for (SObject record : records) {
            SObject hydratedRecord = buildHydratedRecord(record);
            if (hydratedRecord != null) {
                recordsToUpdate.add(hydratedRecord);
            }
        }

        if (recordsToUpdate.isEmpty()) {
            return;
        }

        skipTriggerRecursion = true;
        try {
            update recordsToUpdate;
        } finally {
            skipTriggerRecursion = false;
        }
    }

    /**
     * Builds an update-ready record with structured fields populated from JSON.
     * Returns null when no mappable values exist.
     */
    public static SObject buildHydratedRecord(SObject sourceRecord) {
        if (sourceRecord == null || sourceRecord.Id == null) {
            return null;
        }

        String objectApiName = sourceRecord.getSObjectType().getDescribe().getName();
        if (!WorkflowFieldMappingRegistry.isSupportedObject(objectApiName)) {
            return null;
        }

        String jsonPayload = (String) sourceRecord.get(JSON_DATA_FIELD);
        Map<String, Object> payload = parseJsonPayload(jsonPayload);
        if (payload.isEmpty()) {
            return null;
        }

        Map<String, String> fieldMappings = WorkflowFieldMappingRegistry.getMappingsForObject(objectApiName);
        Map<String, Schema.SObjectField> fieldDescribeByApi = sourceRecord.getSObjectType()
            .getDescribe()
            .fields.getMap();

        SObject targetRecord = sourceRecord.getSObjectType().newSObject(sourceRecord.Id);
        Boolean hasChanges = false;

        for (String jsonKey : fieldMappings.keySet()) {
            if (!payload.containsKey(jsonKey)) {
                continue;
            }

            Object rawValue = payload.get(jsonKey);
            if (isEmptyValue(rawValue)) {
                continue;
            }

            String fieldApiName = fieldMappings.get(jsonKey);
            Schema.SObjectField fieldToken = fieldDescribeByApi.get(fieldApiName);
            if (fieldToken == null) {
                continue;
            }

            Object convertedValue = convertValueForField(rawValue, fieldToken.getDescribe());
            if (convertedValue == null) {
                continue;
            }

            try {
                targetRecord.put(fieldApiName, convertedValue);
                hasChanges = true;
            } catch (Exception ex) {
                System.debug(
                    LoggingLevel.WARN,
                    'WorkflowDataMapper skipped field ' + fieldApiName + ': ' + ex.getMessage()
                );
            }
        }

        return hasChanges ? targetRecord : null;
    }

    /**
     * Parses workflow JSON safely and normalizes supported payload shapes.
     */
    public static Map<String, Object> parseJsonPayload(String jsonPayload) {
        if (String.isBlank(jsonPayload)) {
            return new Map<String, Object>();
        }

        try {
            Object parsed = JSON.deserializeUntyped(jsonPayload);
            return extractFormDataMap(parsed);
        } catch (Exception ex) {
            System.debug(LoggingLevel.WARN, 'WorkflowDataMapper invalid JSON: ' + ex.getMessage());
            return new Map<String, Object>();
        }
    }

    private static Map<String, Object> extractFormDataMap(Object parsed) {
        if (parsed instanceof Map<String, Object>) {
            Map<String, Object> rootMap = (Map<String, Object>) parsed;
            if (rootMap.containsKey('formData') && rootMap.get('formData') instanceof Map<String, Object>) {
                return (Map<String, Object>) rootMap.get('formData');
            }
            return rootMap;
        }
        return new Map<String, Object>();
    }

    private static Boolean isEmptyValue(Object value) {
        if (value == null) {
            return true;
        }
        if (value instanceof String && String.isBlank((String) value)) {
            return true;
        }
        return false;
    }

    private static Object convertValueForField(Object rawValue, Schema.DescribeFieldResult fieldDescribe) {
        if (rawValue == null || fieldDescribe == null) {
            return null;
        }

        Schema.DisplayType fieldType = fieldDescribe.getType();
        String stringValue = String.valueOf(rawValue).trim();
        if (String.isBlank(stringValue)) {
            return null;
        }

        try {
            if (fieldType == Schema.DisplayType.DATE) {
                return Date.valueOf(stringValue);
            }
            if (fieldType == Schema.DisplayType.DATETIME) {
                return Datetime.valueOf(stringValue.replace('T', ' '));
            }
            if (fieldType == Schema.DisplayType.BOOLEAN) {
                return Boolean.valueOf(stringValue);
            }
            if (fieldType == Schema.DisplayType.DOUBLE || fieldType == Schema.DisplayType.CURRENCY) {
                return Decimal.valueOf(stringValue);
            }
            if (fieldType == Schema.DisplayType.PERCENT) {
                return Decimal.valueOf(stringValue);
            }
            if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                return normalizePicklistValue(stringValue);
            }
            return stringValue;
        } catch (Exception ex) {
            System.debug(
                LoggingLevel.WARN,
                'WorkflowDataMapper conversion failed for ' + fieldDescribe.getName() + ': ' + ex.getMessage()
            );
            return null;
        }
    }

    /**
     * Converts LWC picklist values (e.g. ServicePartner) to Salesforce API values (Service Partner).
     */
    private static String normalizePicklistValue(String jsonValue) {
        if (String.isBlank(jsonValue)) {
            return jsonValue;
        }
        if (jsonValue.contains(' ')) {
            return jsonValue;
        }
        return jsonValue.replaceAll('([a-z])([A-Z])', '$1 $2');
    }

    public class HydrateRequest {
        @InvocableVariable(label='Record Id' required=true)
        public Id recordId;

        @InvocableVariable(label='JSON Payload' description='Optional override. Uses JSON_Data__c when blank.')
        public String jsonPayload;
    }

    public class HydrateResult {
        @InvocableVariable(label='Success')
        public Boolean success;

        @InvocableVariable(label='Message')
        public String message;
    }
}
