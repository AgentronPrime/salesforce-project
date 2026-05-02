import { LightningElement, api } from 'lwc';

export default class ElectraQuickOptionsButtons extends LightningElement {
    @api value;
    @api configuration;

    get options() {
        if (Array.isArray(this.value)) {
            return this.value;
        }

        if (Array.isArray(this.value?.options)) {
            return this.value.options;
        }

        if (Array.isArray(this.value?.result?.options)) {
            return this.value.result.options;
        }

        return [];
    }

    get hasOptions() {
        return this.options.length > 0;
    }

    connectedCallback() {
        // eslint-disable-next-line no-console
        console.log('ElectraQuickOptionsButtons value:', JSON.stringify(this.value));
    }

    handleClick(event) {
        const message = event.currentTarget.dataset.message;

        if (!message) {
            return;
        }

        if (this.configuration?.util?.sendTextMessage) {
            this.configuration.util
                .sendTextMessage(message)
                .catch((error) => {
                    // eslint-disable-next-line no-console
                    console.error('Failed to send quick option message', error);
                });
        } else {
            // eslint-disable-next-line no-console
            console.warn('sendTextMessage API is not available in this context');
        }
    }
}