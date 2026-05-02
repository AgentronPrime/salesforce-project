public class ElectraUploadDLController {

    @AuraEnabled
    public static String getTestDriveDetails(
                            String testDriveId) {
        try {
            Test_Drive__c td = [
                SELECT Id, Name,
                       Test_Drive_Date__c,
                       Slot_Label__c,
                       Status__c,
                       Dealer__r.Name,
                       Vehicle_Definition__r.Name
                FROM Test_Drive__c
                WHERE Id = :testDriveId
                LIMIT 1
            ];
            return JSON.serialize(td);
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static void updateTestDriveStatus(
                            String testDriveId) {
        try {
            Test_Drive__c td = new Test_Drive__c();
            td.Id            = testDriveId;
            td.Status__c     = 'Pending Verification';
            update td;
        } catch (Exception e) {
            throw new AuraHandledException(
                'Error updating status: ' + e.getMessage()
            );
        }
    }
}