public with sharing class ElectraFetchVehiclesAction {

    public class RequestWrapper {
        @InvocableVariable(required=false)
        public String dummy;

        @InvocableVariable(required=false)
        public String bodyType;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String vehicleDisplayList;

        @InvocableVariable
        public String vehicleIdMap;

        @InvocableVariable
        public Integer totalCount;

        @InvocableVariable
        public String message;

        @InvocableVariable
        public String appliedBodyType;
    }

    @InvocableMethod(
        label='Fetch Available Vehicles'
        description='Fetches Vehicle Definitions available for test drive, optionally filtered by body type.'
    )
    public static List<ResponseWrapper> fetchVehicles(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();
        ResponseWrapper res = new ResponseWrapper();

        try {
            String bodyTypeFilter = null;
            if (requests != null &&
                !requests.isEmpty() &&
                requests[0] != null) {
                String raw = requests[0].bodyType;
                if (String.isNotBlank(raw)) {
                    String trimmed = raw.trim();
                    if (trimmed.equalsIgnoreCase('ALL')) {
                        bodyTypeFilter = null;
                    } else {
                        bodyTypeFilter = trimmed;
                    }
                }
            }

            res.appliedBodyType = (bodyTypeFilter == null)
                                  ? 'ALL'
                                  : bodyTypeFilter;

            List<VehicleDef_Dealer__c> vdaList;
            if (bodyTypeFilter != null) {
                vdaList = [
                    SELECT VehicleDefinition__c
                    FROM VehicleDef_Dealer__c
                    WHERE Is_Available_For_TestDrive__c = true
                    AND Status__c = 'Active'
                    AND Vehicle__r.Vehicle_Type__c
                        = :bodyTypeFilter
                ];
            } else {
                vdaList = [
                    SELECT VehicleDefinition__c
                    FROM VehicleDef_Dealer__c
                    WHERE Is_Available_For_TestDrive__c = true
                    AND Status__c = 'Active'
                ];
            }

            if (vdaList.isEmpty()) {
                res.message            = (bodyTypeFilter == null)
                    ? 'No vehicles currently available.'
                    : 'No ' + bodyTypeFilter +
                      ' vehicles currently available.';
                res.totalCount         = 0;
                res.vehicleDisplayList = '';
                res.vehicleIdMap       = '';
                results.add(res);
                return results;
            }

            Set<Id> vdIds = new Set<Id>();
            for (VehicleDef_Dealer__c vda : vdaList) {
                if (vda.VehicleDefinition__c != null) {
                    vdIds.add(vda.VehicleDefinition__c);
                }
            }

            List<VehicleDefinition> vehicles = [
                SELECT Id, Name, ModelCode 
                FROM VehicleDefinition
                WHERE Id IN :vdIds
                ORDER BY Name
            ];

            if (vehicles.isEmpty()) {
                res.message            = 'No vehicles found.';
                res.totalCount         = 0;
                res.vehicleDisplayList = '';
                res.vehicleIdMap       = '';
                results.add(res);
                return results;
            }

            String displayStr      = '';
            List<String> idEntries = new List<String>();
            Integer idx = 1;

            for (VehicleDefinition v : vehicles) {
                if (idx == 1) {
                    displayStr += idx + '. ' + v.Name;
                } else {
                    displayStr += '\n' + idx + '. ' + v.Name;
                }
                // Part 1 = number
                // Part 2 = vehicleDefinitionId
                // Part 3 = modelCode
                idEntries.add(
                    idx + '##' + v.Id + '##' +
                    (v.ModelCode != null ? v.ModelCode : '')
                );
                idx++;
            }

            res.vehicleDisplayList = displayStr;
            res.vehicleIdMap       = String.join(
                                        idEntries, '||');
            res.totalCount         = vehicles.size();
            res.message            = 'Success';
            results.add(res);

        } catch (Exception e) {
            res.message            =
                'Error: ' + e.getMessage();
            res.totalCount         = 0;
            res.vehicleDisplayList = '';
            res.vehicleIdMap       = '';
            results.add(res);
        }

        return results;
    }
}