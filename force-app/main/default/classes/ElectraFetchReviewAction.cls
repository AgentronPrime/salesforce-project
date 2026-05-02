public with sharing class ElectraFetchReviewAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String testDriveId;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String reviewDisplayList;
        // Clean display for user

        @InvocableVariable
        public String reviewIdMap;
        // Format: 1##reviewId##rating||2##reviewId##rating

        @InvocableVariable
        public Integer totalCount;

        @InvocableVariable
        public Boolean reviewExists;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Fetch Review For Test Drive'
        description='Fetches all reviews for a test drive'
    )
    public static List<ResponseWrapper> fetchReview(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {
                List<Review__c> reviews = [
                    SELECT Id,
                           Review_Description__c,
                           Actual_Rating__c,
                           CreatedDate
                    FROM Review__c
                    WHERE Test_Drive__c = :req.testDriveId
                    ORDER BY CreatedDate DESC
                ];

                if (reviews.isEmpty()) {
                    res.reviewExists      = false;
                    res.totalCount        = 0;
                    res.reviewDisplayList = '';
                    res.reviewIdMap       = '';
                    res.message           = 'No review found.';
                } else {
                    res.reviewExists = true;
                    res.totalCount   = reviews.size();

                    String displayStr      = '';
                    List<String> idEntries = new List<String>();
                    Integer idx = 1;

                    for (Review__c r : reviews) {
                        String reviewText =
                            r.Review_Description__c != null ?
                            r.Review_Description__c : 'N/A';
                        Decimal rating =
                            r.Actual_Rating__c != null ?
                            r.Actual_Rating__c : 0;

                        if (idx == 1) {
                            displayStr +=
                                idx + '. ' +
                                reviewText +
                                ' (Rating: ' + rating + '/5)';
                        } else {
                            displayStr +=
                                '\n' + idx + '. ' +
                                reviewText +
                                ' (Rating: ' + rating + '/5)';
                        }

                        idEntries.add(
                            idx + '##' +
                            r.Id + '##' +
                            rating
                        );
                        idx++;
                    }

                    res.reviewDisplayList = displayStr;
                    res.reviewIdMap       = String.join(
                        idEntries, '||');
                    res.message           = 'Reviews found.';
                }
                results.add(res);

            } catch (Exception e) {
                res.reviewExists      = false;
                res.totalCount        = 0;
                res.reviewDisplayList = '';
                res.reviewIdMap       = '';
                res.message           = 'Error: ' + e.getMessage();
                results.add(res);
            }
        }
        return results;
    }
}