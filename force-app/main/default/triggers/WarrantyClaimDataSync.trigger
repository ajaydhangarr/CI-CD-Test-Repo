trigger WarrantyClaimDataSync on Warranty_Claim__c (after insert, after update) {
    WorkflowDataSyncTriggerHandler.run(Trigger.new, Trigger.oldMap);
}
