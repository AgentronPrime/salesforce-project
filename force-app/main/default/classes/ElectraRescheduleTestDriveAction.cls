public with sharing class ElectraRescheduleTestDriveAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String testDriveId;

        @InvocableVariable(required=true)
        public String newDate;

        @InvocableVariable(required=true)
        public String newSlotLabel;
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
        label='Reschedule Test Drive'
        description='Reschedules a Test Drive with new date and time slot'
    )
    public static List<ResponseWrapper> rescheduleTestDrive(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {
                Date newDate = Date.valueOf(req.newDate);

                DateTime newDateTime = null;
                try {
                    String startTimePart =
                        req.newSlotLabel.split(' - ')[0].trim();
                    String[] timeParts =
                        startTimePart.split(':');
                    Integer hour   = Integer.valueOf(
                                        timeParts[0].trim());
                    Integer minute = Integer.valueOf(
                                        timeParts[1]
                                        .substring(0, 2).trim());
                    String amPm    = timeParts[1]
                                        .substring(2).trim();
                    if (amPm == 'PM' && hour != 12) hour += 12;
                    if (amPm == 'AM' && hour == 12) hour = 0;
                    newDateTime = DateTime.newInstance(
                        newDate.year(), newDate.month(),
                        newDate.day(), hour, minute, 0
                    );
                } catch (Exception ex) {
                    newDateTime = DateTime.newInstance(
                        newDate.year(), newDate.month(),
                        newDate.day(), 10, 0, 0
                    );
                }

                Test_Drive__c td = [
                    SELECT Id, Name
                    FROM Test_Drive__c
                    WHERE Id = :req.testDriveId
                    LIMIT 1
                ];

                td.Test_Drive_Date__c      = newDate;
                td.Test_Drive_Date_Time__c = newDateTime;
                td.Slot_Label__c           = req.newSlotLabel;
                td.Status__c               = 'Draft';
                update td;

                res.success       = true;
                res.testDriveName = td.Name;
                res.message       =
                    'Test drive ' + td.Name +
                    ' has been rescheduled successfully.';

            } catch (Exception e) {
                res.success = false;
                res.message =
                    'Error rescheduling: ' +
                    e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}