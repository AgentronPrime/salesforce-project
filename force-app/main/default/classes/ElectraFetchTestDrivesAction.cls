public with sharing class ElectraFetchTestDrivesAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String leadId;

        // context values:
        // "REVIEW"      → only Completed test drives
        // "RESCHEDULE"  → only active/upcoming test drives
        // "CANCEL"      → only active/upcoming test drives
        // leave empty   → all test drives (original behavior)
        @InvocableVariable(required=false)
        public String context;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String displayList;

        @InvocableVariable
        public String idMap;

        @InvocableVariable
        public Integer totalCount;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Fetch Test Drives By Lead'
        description='Fetches test drives for a lead. Pass context = REVIEW to get only Completed drives. Pass context = RESCHEDULE or CANCEL to get only active/upcoming drives. Leave empty for all.'
    )
    public static List<ResponseWrapper> fetchTestDrives(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        // ── Status sets per context ───────────────────────────────────
        Set<String> reviewStatuses = new Set<String>{
            'Completed'
        };

        Set<String> activeStatuses = new Set<String>{
            'Requested',
            'Pending DL',
            'Pending DL Verification',
            'DL Verified',
            'Test Drive Scheduled'
        };
        // Note: 'Test Drive In progress', 'Cancelled', 'DL Verification Failed'
        // are intentionally excluded from reschedule/cancel

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {

                // ── Build status filter based on context ──────────────
                String ctx = String.isBlank(req.context) ?
                             '' : req.context.toUpperCase().trim();

                List<Test_Drive__c> tds = new List<Test_Drive__c>();

                if (ctx == 'REVIEW') {
                    tds = [
                        SELECT Id, Name,
                               Test_Drive_Date__c,
                               Slot_Label__c,
                               Status__c,
                               Dealer__c,
                               Dealer__r.Name,
                               Vehicle_Definition__c,
                               Vehicle_Definition__r.Name,
                               VDA__r.Vehicle__c
                        FROM Test_Drive__c
                        WHERE Lead__c  = :req.leadId
                        AND Status__c IN :reviewStatuses
                        ORDER BY Test_Drive_Date__c DESC
                    ];
                } else if (ctx == 'RESCHEDULE' || ctx == 'CANCEL') {
                    tds = [
                        SELECT Id, Name,
                               Test_Drive_Date__c,
                               Slot_Label__c,
                               Status__c,
                               Dealer__c,
                               Dealer__r.Name,
                               Vehicle_Definition__c,
                               Vehicle_Definition__r.Name,
                               VDA__r.Vehicle__c
                        FROM Test_Drive__c
                        WHERE Lead__c  = :req.leadId
                        AND Status__c IN :activeStatuses
                        ORDER BY Test_Drive_Date__c DESC
                    ];
                } else {
                    // No context — return all (original behavior)
                    tds = [
                        SELECT Id, Name,
                               Test_Drive_Date__c,
                               Slot_Label__c,
                               Status__c,
                               Dealer__c,
                               Dealer__r.Name,
                               Vehicle_Definition__c,
                               Vehicle_Definition__r.Name,
                               VDA__r.Vehicle__c
                        FROM Test_Drive__c
                        WHERE Lead__c = :req.leadId
                        ORDER BY Test_Drive_Date__c DESC
                    ];
                }

                // ── No records found ──────────────────────────────────
                if (tds.isEmpty()) {
                    res.totalCount  = 0;
                    res.displayList = '';
                    res.idMap       = '';

                    if (ctx == 'REVIEW') {
                        res.message =
                            'No completed test drives found. ' +
                            'A review can only be submitted after ' +
                            'completing a test drive.';
                    } else if (ctx == 'RESCHEDULE') {
                        res.message =
                            'No active test drives found to reschedule. ' +
                            'Only test drives with status Requested, ' +
                            'Pending DL, Pending DL Verification, ' +
                            'DL Verified or Test Drive Scheduled ' +
                            'can be rescheduled.';
                    } else if (ctx == 'CANCEL') {
                        res.message =
                            'No active test drives found to cancel. ' +
                            'Only test drives with status Requested, ' +
                            'Pending DL, Pending DL Verification, ' +
                            'DL Verified or Test Drive Scheduled ' +
                            'can be cancelled.';
                    } else {
                        res.message = 'No test drives found.';
                    }

                    results.add(res);
                    continue;
                }

                // ── Build display list ────────────────────────────────
                String displayStr      = '';
                List<String> idEntries = new List<String>();
                Integer idx = 1;

                for (Test_Drive__c td : tds) {
                    String vehicleName =
                        td.Vehicle_Definition__r != null ?
                        td.Vehicle_Definition__r.Name : 'N/A';
                    String dealerName =
                        td.Dealer__r != null ?
                        td.Dealer__r.Name : 'N/A';
                    String dealerId =
                        td.Dealer__c != null ?
                        td.Dealer__c : '';
                    String vehicleId =
                        td.VDA__r != null &&
                        td.VDA__r.Vehicle__c != null ?
                        td.VDA__r.Vehicle__c : '';
                    String tdDate =
                        td.Test_Drive_Date__c != null ?
                        td.Test_Drive_Date__c.format() : 'N/A';

                    if (idx == 1) {
                        displayStr +=
                            idx + '. ' +
                            td.Name + ' | ' +
                            vehicleName + ' | ' +
                            dealerName + ' | ' +
                            tdDate + ' | ' +
                            td.Status__c;
                    } else {
                        displayStr +=
                            '\n' + idx + '. ' +
                            td.Name + ' | ' +
                            vehicleName + ' | ' +
                            dealerName + ' | ' +
                            tdDate + ' | ' +
                            td.Status__c;
                    }

                    idEntries.add(
                        idx + '##' +
                        td.Id + '##' +
                        dealerId + '##' +
                        vehicleId
                    );

                    idx++;
                }

                res.displayList = displayStr;
                res.idMap       = String.join(idEntries, '||');
                res.totalCount  = tds.size();
                res.message     = 'Success';
                results.add(res);

            } catch (Exception e) {
                res.message     = 'Error: ' + e.getMessage();
                res.totalCount  = 0;
                res.displayList = '';
                res.idMap       = '';
                results.add(res);
            }
        }
        return results;
    }
}