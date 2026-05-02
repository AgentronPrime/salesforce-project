public without sharing class ElectraUploadDLVFController {

    public String testDriveId   { get; set; }
    public String testDriveName { get; set; }
    public String vehicleName   { get; set; }
    public String dealerName    { get; set; }
    public String testDriveDate { get; set; }
    public String slotLabel     { get; set; }
    public String errorMessage  { get; set; }
    public Boolean isSuccess    { get; set; }
    public Boolean hasError     { get; set; }
    public Blob fileBody        { get; set; }
    public String fileName      { get; set; }

    public ElectraUploadDLVFController() {
        isSuccess    = false;
        hasError     = false;
        errorMessage = '';
        testDriveId  = ApexPages.currentPage()
                           .getParameters().get('tdId');

        if (String.isBlank(testDriveId)) {
            errorMessage = 
                'Invalid link. Please use the link ' +
                'provided in your booking confirmation.';
            hasError = true;
            return;
        }

        loadTestDriveDetails();
    }

    private void loadTestDriveDetails() {
        try {
            Test_Drive__c td = [
                SELECT Id, Name,
                       Test_Drive_Date__c,
                       Slot_Label__c,
                       Dealer__r.Name,
                       Vehicle_Definition__r.Name
                FROM Test_Drive__c
                WHERE Id = :testDriveId
                LIMIT 1
            ];

            testDriveName = td.Name;
            vehicleName   = td.Vehicle_Definition__r != null
                            ? td.Vehicle_Definition__r.Name
                            : 'N/A';
            dealerName    = td.Dealer__r != null
                            ? td.Dealer__r.Name
                            : 'N/A';
            testDriveDate = td.Test_Drive_Date__c != null
                            ? td.Test_Drive_Date__c.format()
                            : '';
            slotLabel     = td.Slot_Label__c;

        } catch (Exception e) {
            errorMessage = 
                'Could not load booking details. ' +
                'Please try again.';
            hasError = true;
        }
    }

    public PageReference uploadFile() {
        try {
            if (fileBody == null) {
                errorMessage = 
                    'Please select a file first.';
                return null;
            }

            // Step 1: Create ContentVersion
            ContentVersion cv  = new ContentVersion();
            cv.Title           = 'Driving_License_' +
                                  fileName;
            cv.PathOnClient    = fileName;
            cv.VersionData     = fileBody;
            cv.ContentLocation = 'S';
            insert cv;

            // Step 2: Get ContentDocumentId
            ContentVersion inserted = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];

            // Step 3: Link to Test Drive record
            ContentDocumentLink cdl = 
                new ContentDocumentLink();
            cdl.ContentDocumentId = 
                inserted.ContentDocumentId;
            cdl.LinkedEntityId    = testDriveId;
            cdl.ShareType         = 'V';
            cdl.Visibility        = 'AllUsers';
            insert cdl;

            // Step 4: Update Test Drive status
            Test_Drive__c td = new Test_Drive__c();
            td.Id            = testDriveId;
            td.Status__c     = 'Pending DL Verification';
            update td;

            isSuccess    = true;
            errorMessage = '';
            return null;

        } catch (Exception e) {
            errorMessage = 
                'Upload failed: ' + e.getMessage();
            return null;
        }
    }
}