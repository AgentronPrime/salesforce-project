public with sharing class ElectraSaveReviewAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String testDriveId;

        @InvocableVariable(required=true)
        public String leadId;

        @InvocableVariable(required=true)
        public String vehicleId;

        @InvocableVariable(required=true)
        public String reviewText;

        @InvocableVariable(required=true)
        public Decimal rating;

        @InvocableVariable(required=false)
        public String reviewId;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String reviewId;

        @InvocableVariable
        public Boolean success;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public Boolean isUpdate;
    }

    @InvocableMethod(
        label='Save Test Drive Review'
        description='Creates or updates a review for a test drive'
    )
    public static List<ResponseWrapper> saveReview(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {
                Boolean isUpdate =
                    String.isNotBlank(req.reviewId);

                Review__c review = new Review__c();

                if (isUpdate) {
                    review.Id                    = req.reviewId;
                    review.Review_Description__c = req.reviewText;
                    review.Actual_Rating__c      = req.rating;
                    update review;
                    res.reviewId = req.reviewId;
                    res.isUpdate = true;
                    res.message  = 'Review updated successfully!';
                } else {
                    review.Test_Drive__c         = req.testDriveId;
                    review.Lead__c               = req.leadId;
                    review.Vehicle__c            = req.vehicleId;
                    review.Review_Description__c = req.reviewText;
                    review.Actual_Rating__c      = req.rating;
                    review.Type__c               = 'TestDrive';
                    insert review;
                    res.reviewId = review.Id;
                    res.isUpdate = false;
                    res.message  = 'Review added successfully!';
                }

                res.success = true;
                results.add(res);

            } catch (Exception e) {
                res.success = false;
                res.message = 'Error: ' + e.getMessage();
                results.add(res);
            }
        }
        return results;
    }
}