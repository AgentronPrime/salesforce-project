public with sharing class ElectraFetchDealersAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String vehicleDefinitionId;

        @InvocableVariable(required=true)
        public String userPincode;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String dealerDisplayList;

        @InvocableVariable
        public String dealerIdMap;

        @InvocableVariable
        public Integer totalCount;

        @InvocableVariable
        public Boolean pincodeMatched;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Fetch Dealers By Vehicle And Pincode'
        description='Fetches dealers for a selected vehicle filtered by pincode'
    )
    public static List<ResponseWrapper> fetchDealers(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            try {
                // Step 1: Try exact pincode match first
                List<VehicleDef_Dealer__c> matches = [
                    SELECT Id,
                           Dealer__c,
                           Dealer__r.Name,
                           Dealer__r.BillingCity,
                           Dealer__r.BillingState,
                           Dealer__r.BillingPostalCode,
                           Dealer__r.Rating,
                           Dealer_Pincode__c
                    FROM VehicleDef_Dealer__c
                    WHERE VehicleDefinition__c =
                          :req.vehicleDefinitionId
                    AND Is_Available_For_TestDrive__c = true
                    AND Status__c = 'Active'
                    AND Dealer_Pincode__c = :req.userPincode
                    ORDER BY Dealer__r.Rating DESC
                ];

                Boolean pincodeMatched = !matches.isEmpty();

                // Step 2: If no match fetch all
                if (!pincodeMatched) {
                    matches = [
                        SELECT Id,
                               Dealer__c,
                               Dealer__r.Name,
                               Dealer__r.BillingCity,
                               Dealer__r.BillingState,
                               Dealer__r.BillingPostalCode,
                               Dealer__r.Rating,
                               Dealer_Pincode__c
                        FROM VehicleDef_Dealer__c
                        WHERE VehicleDefinition__c =
                              :req.vehicleDefinitionId
                        AND Is_Available_For_TestDrive__c = true
                        AND Status__c = 'Active'
                        ORDER BY Dealer__r.Rating DESC
                    ];
                }

                if (matches.isEmpty()) {
                    res.pincodeMatched    = false;
                    res.totalCount        = 0;
                    res.dealerDisplayList = '';
                    res.dealerIdMap       = '';
                    res.message           =
                        'No dealers found for this vehicle.';
                    results.add(res);
                    continue;
                }

                // Step 3: Build display and id map
                String displayStr      = '';
                List<String> idEntries = new List<String>();
                Integer idx = 1;

                for (VehicleDef_Dealer__c vda : matches) {
                    String city  =
                        vda.Dealer__r.BillingCity != null ?
                        vda.Dealer__r.BillingCity : '';
                    String state =
                        vda.Dealer__r.BillingState != null ?
                        vda.Dealer__r.BillingState : '';

                    // Clean display line
                    if (idx == 1) {
                        displayStr +=
                            idx + '. ' +
                            vda.Dealer__r.Name +
                            ' - ' + city + ', ' + state;
                    } else {
                        displayStr +=
                            '\n' + idx + '. ' +
                            vda.Dealer__r.Name +
                            ' - ' + city + ', ' + state;
                    }

                    // Use ## as separator and || between entries
                    idEntries.add(
                        idx + '##' +
                        vda.Dealer__c + '##' +
                        vda.Id
                    );

                    idx++;
                }

                res.dealerDisplayList = displayStr;
                res.dealerIdMap       = String.join(
                    idEntries, '||');
                res.totalCount        = matches.size();
                res.pincodeMatched    = pincodeMatched;
                res.message           = pincodeMatched ?
                    'Dealers found near your pincode' :
                    'No dealers near your pincode. Showing all available dealers.';
                results.add(res);

            } catch (Exception e) {
                res.message           =
                    'Error: ' + e.getMessage();
                res.totalCount        = 0;
                res.pincodeMatched    = false;
                res.dealerDisplayList = '';
                res.dealerIdMap       = '';
                results.add(res);
            }
        }
        return results;
    }
}