public with sharing class ElectraCreateTestDriveAction {

    public class RequestWrapper {
        @InvocableVariable(required=true) public String leadId;
        @InvocableVariable(required=true) public String vehicleDefinitionId;
        @InvocableVariable(required=true) public String dealerId;
        @InvocableVariable(required=true) public String vdaId;
        @InvocableVariable(required=true) public String testDriveDate;
        @InvocableVariable(required=true) public String slotLabel;
        @InvocableVariable(required=false) public String pincode;
    }

    public class ResponseWrapper {
        @InvocableVariable public String testDriveId;
        @InvocableVariable public String testDriveName;
        @InvocableVariable public String message;
        @InvocableVariable public Boolean success;
        @InvocableVariable public String uploadUrl;
    }

    @InvocableMethod(label='Create Test Drive' description='Creates a Test Drive record with all booking details')
    public static List<ResponseWrapper> createTestDrive(List<RequestWrapper> requests) {
        List<ResponseWrapper> results = new List<ResponseWrapper>();
        List<Test_Drive__c> testDrivesToInsert = new List<Test_Drive__c>();
        
        // 1. Collect all VDA IDs to query outside the loop
        Set<Id> vdaIds = new Set<Id>();
        for (RequestWrapper req : requests) {
            if (String.isNotBlank(req.vdaId)) {
                vdaIds.add(req.vdaId);
            }
        }

        // 2. Query VDA records once and map VehicleDefinition_Dealer ID to Vehicle (Asset) ID
        Map<Id, Id> vdaToVehicleMap = new Map<Id, Id>();
        if (!vdaIds.isEmpty()) {
            for (VehicleDef_Dealer__c vda : [SELECT Id, Vehicle__c FROM VehicleDef_Dealer__c WHERE Id IN :vdaIds]) {
                vdaToVehicleMap.put(vda.Id, vda.Vehicle__c);
            }
        }

        // 3. Prepare Test Drive records for insertion
        for (RequestWrapper req : requests) {
            try {
                Date tdDate = Date.valueOf(req.testDriveDate);
                DateTime tdDateTime = parseDateTime(tdDate, req.slotLabel);

                Test_Drive__c td = new Test_Drive__c();
                td.Lead__c = req.leadId;
                td.Vehicle_Definition__c = req.vehicleDefinitionId;
                td.Dealer__c = req.dealerId;
                td.VDA__c = req.vdaId;
                
                // Get the Vehicle ID from our pre-queried map
                td.Vehicle__c = vdaToVehicleMap.get(req.vdaId); 
                
                td.Test_Drive_Date__c = tdDate;
                td.Test_Drive_Date_Time__c = tdDateTime;
                td.Slot_Label__c = req.slotLabel;
                td.Pincdoe__c = req.pincode != null ? req.pincode : ''; // Matches your existing field name typo
                td.Status__c = 'Draft';
                
                testDrivesToInsert.add(td);
            } catch (Exception e) {
                // If a single record fails parsing, we add an error response here
                ResponseWrapper errorRes = new ResponseWrapper();
                errorRes.success = false;
                errorRes.message = 'Parsing Error: ' + e.getMessage();
                results.add(errorRes);
            }
        }

        // 4. Perform a single DML operation
        if (!testDrivesToInsert.isEmpty()) {
            insert testDrivesToInsert;
            
            // Re-query to get Auto-Numbers and Names for the response
            Map<Id, Test_Drive__c> insertedMap = new Map<Id, Test_Drive__c>([
                SELECT Id, Name FROM Test_Drive__c WHERE Id IN :testDrivesToInsert
            ]);

            for (Test_Drive__c td : testDrivesToInsert) {
                ResponseWrapper res = new ResponseWrapper();
                res.testDriveId = td.Id;
                res.testDriveName = insertedMap.get(td.Id).Name;
                res.uploadUrl = 'https://orgfarm-c0d788b8f5.my.site.com/vforcesite/apex/ElectraDLUpload?tdId=' + td.Id;
                res.success = true;
                res.message = 'Test Drive booked successfully!';
                results.add(res);
            }
        }

        return results;
    }

    // Helper method to keep the main loop clean
    private static DateTime parseDateTime(Date tdDate, String slotLabel) {
        try {
            String startTimePart = slotLabel.split(' - ')[0].trim();
            String[] timeParts = startTimePart.split(':');
            Integer hour = Integer.valueOf(timeParts[0].trim());
            Integer minute = Integer.valueOf(timeParts[1].substring(0, 2).trim());
            String amPm = timeParts[1].substring(2).trim();

            if (amPm == 'PM' && hour != 12) hour += 12;
            if (amPm == 'AM' && hour == 12) hour = 0;

            return DateTime.newInstance(tdDate.year(), tdDate.month(), tdDate.day(), hour, minute, 0);
        } catch (Exception ex) {
            return DateTime.newInstance(tdDate.year(), tdDate.month(), tdDate.day(), 10, 0, 0);
        }
    }

}