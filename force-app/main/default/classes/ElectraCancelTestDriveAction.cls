public with sharing class ElectraCancelTestDriveAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String testDriveId;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public String testDriveName;
    }

    @InvocableMethod(
        label='Cancel Test Drive'
        description='Cancels a Test Drive by updating status to Cancelled'
    )
    public static List<ResponseWrapper> cancelTestDrive(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {
                Test_Drive__c td = [
                    SELECT Id, Name, Status__c
                    FROM Test_Drive__c
                    WHERE Id = :req.testDriveId
                    LIMIT 1
                ];

                td.Status__c = 'Cancelled';
                update td;

                res.success       = true;
                res.testDriveName = td.Name;
                res.message       =
                    'Test drive ' + td.Name +
                    ' has been cancelled successfully.';

            } catch (Exception e) {
                res.success = false;
                res.message =
                    'Error cancelling test drive: ' +
                    e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}