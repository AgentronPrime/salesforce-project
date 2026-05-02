/**
 * @description Retrieves all Test_Drive__c records for a given Lead.
 *              Bulkified. Uses only the fields available in the org:
 *              Lead__c, Vehicle__c, Test_Drive_Date_Time__c, Status__c, Pincode__c
 */
public with sharing class TestDriveRetrievalService {

    // ─────────────────────────────────────────────
    // Input / Output Wrappers
    // ─────────────────────────────────────────────
    public class RetrievalRequest {
        @InvocableVariable(label='Lead Record Id' required=true)
        public String leadId;

        @InvocableVariable(label='Status Filter (comma-separated, optional)' required=false)
        public String statusFilter;
    }

    public class TestDriveSummary {
        @InvocableVariable(label='Test Drive Id')
        public String testDriveId;

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
    }

    public class RetrievalResult {
        @InvocableVariable(label='Test Drives Found')
        public Boolean testDrivesFound;

        @InvocableVariable(label='Number of Test Drives')
        public Integer testDriveCount;

        @InvocableVariable(label='Test Drive Summaries JSON')
        public String testDriveSummariesJson;

        @InvocableVariable(label='Formatted List for Display')
        public String formattedList;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    // ─────────────────────────────────────────────
    // Invocable Method
    // ─────────────────────────────────────────────
    @InvocableMethod(
        label='Get Test Drives for Lead'
        description='Retrieves all test drives linked to a Lead. Optionally filters by status.'
        category='Test Drive'
    )
    public static List<RetrievalResult> getTestDrives(
        List<RetrievalRequest> requests
    ) {
        List<RetrievalResult> results = new List<RetrievalResult>();

        // Collect all Lead IDs for bulk query
        Set<Id> allLeadIds = new Set<Id>();
        for (RetrievalRequest req : requests) {
            allLeadIds.add(Id.valueOf(req.leadId));
        }

        // Default active statuses
        Set<String> defaultStatuses = new Set<String>{
            'Scheduled', 'Confirmed', 'Pending', 'Rescheduled'
        };

        // Single bulk query — all test drives for all requested Leads
        Map<Id, List<Test_Drive__c>> testDrivesByLeadId = new Map<Id, List<Test_Drive__c>>();

        for (Test_Drive__c td : [
            SELECT Id, Name, Vehicle__c, Test_Drive_Date_Time__c,
                   Status__c, Pincdoe__c, Lead__c
            FROM Test_Drive__c
            WHERE Lead__c IN :allLeadIds
            WITH USER_MODE
            ORDER BY Test_Drive_Date_Time__c ASC
            LIMIT 1000
        ]) {
            if (!testDrivesByLeadId.containsKey(td.Lead__c)) {
                testDrivesByLeadId.put(td.Lead__c, new List<Test_Drive__c>());
            }
            testDrivesByLeadId.get(td.Lead__c).add(td);
        }

        // Build result per request
        for (RetrievalRequest req : requests) {
            RetrievalResult res = new RetrievalResult();
            Id leadId = Id.valueOf(req.leadId);

            List<Test_Drive__c> custTestDrives = testDrivesByLeadId.get(leadId);

            if (custTestDrives == null || custTestDrives.isEmpty()) {
                res.testDrivesFound = false;
                res.testDriveCount = 0;
                res.errorMessage = 'No test drives found for this customer.';
                results.add(res);
                continue;
            }

            // Determine status filter
            Set<String> allowedStatuses = defaultStatuses;
            if (String.isNotBlank(req.statusFilter)) {
                allowedStatuses = new Set<String>();
                for (String s : req.statusFilter.split(',')) {
                    allowedStatuses.add(s.trim());
                }
            }

            List<TestDriveSummary> summaries = new List<TestDriveSummary>();
            List<String> displayLines = new List<String>();
            Integer idx = 1;

            for (Test_Drive__c td : custTestDrives) {
                if (!allowedStatuses.contains(td.Status__c)) continue;

                TestDriveSummary s = new TestDriveSummary();
                s.testDriveId = td.Id;
                s.testDriveName = td.Name;
                s.vehicle = td.Vehicle__c;
                s.scheduledDateTime = td.Test_Drive_Date_Time__c;
                s.formattedDateTime = td.Test_Drive_Date_Time__c != null
                    ? td.Test_Drive_Date_Time__c.format('EEEE, MMMM d, yyyy \'at\' h:mm a')
                    : 'Not set';
                s.pincode = td.Pincdoe__c;
                s.status = td.Status__c;
                summaries.add(s);

                displayLines.add(
                    idx + '. ' + td.Vehicle__c
                    + ' | ' + s.formattedDateTime
                    + ' | Pincode: ' + td.Pincdoe__c
                    + ' | Status: ' + td.Status__c
                );
                idx++;
            }

            res.testDrivesFound = !summaries.isEmpty();
            res.testDriveCount = summaries.size();
            res.testDriveSummariesJson = JSON.serialize(summaries);
            res.formattedList = summaries.isEmpty()
                ? null
                : String.join(displayLines, '\n');

            if (summaries.isEmpty()) {
                res.errorMessage = 'No test drives match the requested status filter.';
            }

            results.add(res);
        }

        return results;
    }
}