import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getVehicleById from '@salesforce/apex/VehicleDetailsController.getVehicleById';

export default class VehicleDetailsCmp extends LightningElement {
    recordId;
    vehicle;
    isLoading = true;
    error;

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef?.state?.c__vehicleId) {
            this.recordId = pageRef.state.c__vehicleId;
        }
    }

    @wire(getVehicleById, { vehicleId: '$recordId' })
    wiredVehicle({ data, error }) {
        if (!this.recordId) {
            return;
        }

        this.isLoading = true;

        if (data) {
            this.vehicle = {
                Id: data.Id,
                Name: data.Name,
                type: data.Vehicle_Type__c || 'N/A',
                fuel: data.FuelSource || 'N/A',
                color: data.ExteriorColor || 'N/A',
                description: data.Description || 'No description available',
                price: data.MarketPrice
                    ? '$' + Number(data.MarketPrice).toLocaleString()
                    : 'Contact Dealer',
                imageUrl: data.Vehicle_Image__c
                    ? '/resource/' + data.Vehicle_Image__c
                    : '',
                hasImage: !!data.Vehicle_Image__c
            };
            this.error = undefined;
        } else if (error) {
            this.vehicle = undefined;
            this.error = error.body?.message || 'Failed to load vehicle details';
        }

        this.isLoading = false;
    }

    get hasVehicle() {
        return !!this.vehicle;
    }
}