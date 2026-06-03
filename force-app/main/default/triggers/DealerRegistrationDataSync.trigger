trigger DealerRegistrationDataSync on Dealer_Registration__c (after insert, after update) {
    WorkflowDataSyncTriggerHandler.run(Trigger.new, Trigger.oldMap);
}
