/**
 * @description Returns full detail for a single Test_Drive__c record.
 *              Uses only available fields: Vehicle__c, Test_Drive_Date_Time__c,
 *              Status__c, Pincode__c, Lead__c
 */
public with sharing class TestDriveDetailService {

    public class DetailRequest {
        @InvocableVariable(label='Test Drive Record Id' required=true)
        public String testDriveId;
    }

    public class DetailResult {
        @InvocableVariable(label='Record Found')
        public Boolean found;

        @InvocableVariable(label='Test Drive Name')
        public String testDriveName;

        @InvocableVariable(label='Vehicle')
        public String vehicle;

        @InvocableVariable(label='Scheduled Date Time')
        public Datetime scheduledDateTime;

        @InvocableVariable(label='Formatted Date Time')
        public String formattedDateTime;

        @InvocableVariable(label='Pincode')
        public String pincode;

        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Lead Name')
        public String leadName;

        @InvocableVariable(label='Formatted Detail for Display')
        public String formattedDetail;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label='Get Test Drive Detail'
        description='Returns full detail for a specific Test Drive record.'
        category='Test Drive'
    )
    public static List<DetailResult> getDetail(List<DetailRequest> requests) {
        List<DetailResult> results = new List<DetailResult>();

        // Collect all IDs for bulk query
        Set<Id> tdIds = new Set<Id>();
        for (DetailRequest req : requests) {
            try {
                tdIds.add(Id.valueOf(req.testDriveId));
            } catch (Exception e) {
                // Invalid ID — handled below
            }
        }

        // Single bulk query
        Map<Id, Test_Drive__c> tdMap = new Map<Id, Test_Drive__c>();
        if (!tdIds.isEmpty()) {
            tdMap = new Map<Id, Test_Drive__c>([
                SELECT Id, Name, Vehicle__c, Test_Drive_Date_Time__c,
                       Status__c, Pincdoe__c, Lead__c, Lead__r.Name
                FROM Test_Drive__c
                WHERE Id IN :tdIds
                WITH USER_MODE
            ]);
        }

        // Build result per request
        for (DetailRequest req : requests) {
            DetailResult res = new DetailResult();

            Id tdId;
            try {
                tdId = Id.valueOf(req.testDriveId);
            } catch (Exception e) {
                res.found = false;
                res.errorMessage = 'Invalid Test Drive ID provided.';
                results.add(res);
                continue;
            }

            Test_Drive__c td = tdMap.get(tdId);

            if (td == null) {
                res.found = false;
                res.errorMessage = 'Test Drive record not found.';
                results.add(res);
                continue;
            }

            res.found = true;
            res.testDriveName = td.Name;
            res.vehicle = td.Vehicle__c;
            res.scheduledDateTime = td.Test_Drive_Date_Time__c;
            res.formattedDateTime = td.Test_Drive_Date_Time__c != null
                ? td.Test_Drive_Date_Time__c.format('EEEE, MMMM d, yyyy \'at\' h:mm a')
                : 'Not scheduled';
            res.pincode = td.Pincdoe__c;
            res.status = td.Status__c;
            res.leadName = td.Lead__r != null ? td.Lead__r.Name : 'Unknown';

            res.formattedDetail =
                '🚗 Test Drive Details: ' + td.Name + '\n'
                + '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
                + '• Customer: ' + res.leadName + '\n'
                + '• Vehicle: ' + (td.Vehicle__c != null ? td.Vehicle__c : 'N/A') + '\n'
                + '• Date & Time: ' + res.formattedDateTime + '\n'
                + '• Location Pincode: ' + (td.Pincdoe__c != null ? td.Pincdoe__c : 'N/A') + '\n'
                + '• Status: ' + td.Status__c + '\n'
                + '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

            results.add(res);
        }

        return results;
    }
}