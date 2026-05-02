/**
 * @description Single trigger for Test_Drive__c.
 */
trigger TestDriveTrigger on Test_Drive__c(before insert,after insert,after update) {
    TestDriveTriggerHandler.execute(Trigger.new,Trigger.oldMap,Trigger.operationType);
}