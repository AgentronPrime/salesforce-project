public without sharing class VehicleShowcaseController {

    @AuraEnabled(cacheable=true)
    public static List<String> getVehicleTypes() {
        List<String> types = new List<String>();
        Schema.DescribeFieldResult fieldResult = Vehicle.Vehicle_Type__c.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                types.add(entry.getValue());
            }
        }
        return types;
    }

    @AuraEnabled(cacheable=true)
    public static List<Vehicle> getVehiclesByType(String vehicleType) {
        if (String.isBlank(vehicleType) || vehicleType == 'All') {
            return [
                SELECT Id, Name, Vehicle_Type__c, MarketPrice,
                       FuelSource, ExteriorColor, Vehicle_Image__c
                FROM Vehicle
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        } else {
            return [
                SELECT Id, Name, Vehicle_Type__c, MarketPrice,
                       FuelSource, ExteriorColor, Vehicle_Image__c
                FROM Vehicle
                WHERE Vehicle_Type__c = :vehicleType
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        }
    }
}