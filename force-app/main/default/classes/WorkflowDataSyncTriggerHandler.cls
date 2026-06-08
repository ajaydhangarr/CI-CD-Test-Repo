/**
 * Trigger handler that hydrates structured fields when JSON_Data__c is populated or changed.
 */
public with sharing class WorkflowDataSyncTriggerHandler {
    private static final String JSON_DATA_FIELD = 'JSON_Data__c';

    public static void run(List<SObject> newRecords, Map<Id, SObject> oldRecordsById) {
        if (newRecords == null || newRecords.isEmpty()) {
            return;
        }

        List<SObject> recordsToHydrate = new List<SObject>();
        for (SObject record : newRecords) {
            if (shouldHydrate(record, oldRecordsById)) {
                recordsToHydrate.add(record);
            }
        }

        if (!recordsToHydrate.isEmpty()) {
            WorkflowDataMapper.hydrateRecords(recordsToHydrate);
        }
    }

    private static Boolean shouldHydrate(SObject record, Map<Id, SObject> oldRecordsById) {
        if (record == null || record.Id == null) {
            return false;
        }

        String objectApiName = record.getSObjectType().getDescribe().getName();
        if (!WorkflowFieldMappingRegistry.isSupportedObject(objectApiName)) {
            return false;
        }

        String newJson = (String) record.get(JSON_DATA_FIELD);
        if (String.isBlank(newJson)) {
            return false;
        }

        if (oldRecordsById == null || !oldRecordsById.containsKey(record.Id)) {
            return true;
        }

        String oldJson = (String) oldRecordsById.get(record.Id).get(JSON_DATA_FIELD);
        return newJson != oldJson;
    }
}
