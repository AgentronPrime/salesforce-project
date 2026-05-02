public without sharing class VehicleDetailsController {

    @AuraEnabled(cacheable=true)
    public static Vehicle getVehicleById(Id vehicleId) {
        if (vehicleId == null) {
            throw new AuraHandledException('Vehicle Id is required');
        }

        return [
            SELECT Id,
                   Name,
                   Vehicle_Type__c,
                   MarketPrice,
                   FuelSource,
                   ExteriorColor,
                   Vehicle_Image__c
            FROM Vehicle
            WHERE Id = :vehicleId
            LIMIT 1
        ];
    }
}