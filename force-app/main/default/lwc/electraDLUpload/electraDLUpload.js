import { LightningElement, track } from 'lwc';
import getTestDriveDetails from
    '@salesforce/apex/ElectraUploadDLController.getTestDriveDetails';
import updateTestDriveStatus from
    '@salesforce/apex/ElectraUploadDLController.updateTestDriveStatus';

export default class ElectraDLUpload extends LightningElement {

    @track isLoading        = true;
    @track hasError         = false;
    @track isSuccess        = false;
    @track errorMessage     = '';
    @track testDriveId      = '';
    @track testDriveName    = '';
    @track vehicleName      = '';
    @track dealerName       = '';
    @track testDriveDate    = '';
    @track slotLabel        = '';

    get showUpload() {
        return !this.isLoading &&
               !this.hasError &&
               !this.isSuccess;
    }

    get acceptedFormats() {
    return '.jpg,.jpeg,.png,.pdf';
}

    connectedCallback() {
        const urlParams  = new URLSearchParams(
            window.location.search
        );
        this.testDriveId = urlParams.get('tdId');

        if (!this.testDriveId) {
            this.errorMessage =
                'Invalid link. Please use the link ' +
                'provided in your booking confirmation.';
            this.hasError  = true;
            this.isLoading = false;
            return;
        }
        this.loadDetails();
    }

    loadDetails() {
        getTestDriveDetails({ 
            testDriveId: this.testDriveId 
        })
        .then(result => {
            const td           = JSON.parse(result);
            this.testDriveName = td.Name;
            this.vehicleName   = td.Vehicle_Definition__r
                                 ? td.Vehicle_Definition__r.Name
                                 : 'N/A';
            this.dealerName    = td.Dealer__r
                                 ? td.Dealer__r.Name
                                 : 'N/A';
            this.testDriveDate = td.Test_Drive_Date__c;
            this.slotLabel     = td.Slot_Label__c;
            this.isLoading     = false;
        })
        .catch(() => {
            this.errorMessage =
                'Could not load booking details. ' +
                'Please try again.';
            this.hasError  = true;
            this.isLoading = false;
        });
    }

    handleUploadFinished(event) {
        // lightning-file-upload automatically attaches
        // file to the record-id we passed
        // Now just update the status
        updateTestDriveStatus({ 
            testDriveId: this.testDriveId 
        })
        .then(() => {
            this.isSuccess = true;
        })
        .catch(() => {
            this.errorMessage =
                'File uploaded but status update failed. ' +
                'Please contact support.';
            this.hasError = true;
        });
    }
}