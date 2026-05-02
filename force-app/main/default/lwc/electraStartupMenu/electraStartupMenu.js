import { LightningElement, track } from 'lwc';
import getStartupOptions from '@salesforce/apex/ElectraQuickOptionsController.getStartupOptions';

export default class ElectraStartupMenu extends LightningElement {
    @track options = [];
    @track errorMessage = '';

    connectedCallback() {
        this.loadOptions();
    }

    get hasOptions() {
        return this.options && this.options.length > 0;
    }

    async loadOptions() {
        this.errorMessage = '';
        try {
            const result = await getStartupOptions();
            this.options = (result && result.options) ? result.options : [];
        } catch (error) {
            this.options = [];
            this.errorMessage = 'Unable to load startup options.';
            // Keep this for debugging in browser console
            // eslint-disable-next-line no-console
            console.error('getStartupOptions failed', error);
        }
    }

    handleOptionClick(event) {
        const detail = {
            id: event.currentTarget.dataset.id,
            label: event.currentTarget.dataset.label,
            message: event.currentTarget.dataset.message
        };

        this.dispatchEvent(
            new CustomEvent('optionselect', {
                detail,
                bubbles: true,
                composed: true
            })
        );
    }
}