import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getVehicleTypes from '@salesforce/apex/VehicleShowcaseController.getVehicleTypes';
import getVehiclesByType from '@salesforce/apex/VehicleShowcaseController.getVehiclesByType';

export default class VehicleShowcaseCmp extends NavigationMixin(LightningElement) {

    vehicleTypes = [];
    selectedType = 'All';
    vehicles = [];
    isLoading = true;
    error;

    // ── Load picklist values ──
    @wire(getVehicleTypes)
    wiredTypes({ data, error }) {
        if (data) {
            this.vehicleTypes = ['All', ...data];
        } else if (error) {
            this.error = error.body?.message;
        }
    }

    // ── Load vehicles reactively based on selected type ──
    @wire(getVehiclesByType, { vehicleType: '$selectedType' })
    wiredVehicles({ data, error }) {
        this.isLoading = true;
        if (data) {
            this.vehicles = data.map(v => ({
                Id: v.Id,
                Name: v.Name,
                vehicleType: v.Vehicle_Type__c || 'N/A',
                price: v.MarketPrice
                    ? '$' + Number(v.MarketPrice).toLocaleString()
                    : 'Contact Dealer',
                fuel: v.FuelSource || 'N/A',
                color: v.ExteriorColor || 'N/A',
                imageUrl: v.Vehicle_Image__c
                    ? '/resource/' + v.Vehicle_Image__c
                    : '',
                hasImage: !!v.Vehicle_Image__c,
                imageLoaded: true    // tracks if image loaded successfully
            }));
            this.error = undefined;
        } else if (error) {
            this.vehicles = [];
            this.error = error.body?.message;
        }
        this.isLoading = false;
    }

    // ── Type pill click ──
    handleTypeClick(event) {
        this.selectedType = event.currentTarget.dataset.type;
    }

    // ── Card click → navigate to record ──
    handleCardClick(event) {
    const vehicleId = event.currentTarget.dataset.id;

    this[NavigationMixin.Navigate]({
        type: 'standard__webPage',
        attributes: {
            url: `/vehicle-details?c__vehicleId=${vehicleId}`
        }
    });
   }

    // ── Handle broken / missing static resource image ──
    handleImageError(event) {
        const vehicleId = event.target.dataset.id;
        this.vehicles = this.vehicles.map(v => {
            if (v.Id === vehicleId) {
                return { ...v, imageLoaded: false };
            }
            return v;
        });
    }

    // ── Computed: pill buttons ──
    get typePills() {
        return this.vehicleTypes.map(t => ({
            label: t,
            value: t,
            pillClass: t === this.selectedType ? 'pill pill-active' : 'pill'
        }));
    }

    get hasVehicles() {
        return this.vehicles.length > 0;
    }

    get vehicleCount() {
        return this.vehicles.length;
    }
}