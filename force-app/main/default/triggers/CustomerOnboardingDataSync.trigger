trigger CustomerOnboardingDataSync on Customer_Onboarding__c (after insert, after update) {
    WorkflowDataSyncTriggerHandler.run(Trigger.new, Trigger.oldMap);
}
