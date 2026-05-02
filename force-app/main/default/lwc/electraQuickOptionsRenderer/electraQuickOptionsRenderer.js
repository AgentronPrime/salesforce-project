import { LightningElement, api, track } from 'lwc';
import getStartupOptions from '@salesforce/apex/ElectraQuickOptionsController.getStartupOptions';

export default class ElectraQuickOptionsRenderer extends LightningElement {
    /**
     * Agentforce renderer payload (usually injected by platform):
     * {
     *   options: [{ id, label, message }]
     * }
     */
    @api value;   // common renderer payload property
    @api result;  // fallback if payload is mapped to "result"
    @api title = 'Here are some quick options for you to choose from:';

    @track loading = false;
    @track error;
    @track fallbackOptions = [];

    connectedCallback() {
        // If Agentforce doesn't inject value/result in preview, fallback to Apex.
        if (!this.hasInjectedOptions) {
            this.loadFallbackOptions();
        }
    }

    get hasInjectedOptions() {
        return (
            Array.isArray(this.value?.options) ||
            Array.isArray(this.result?.options)
        );
    }

    get options() {
        const incoming = this.value?.options || this.result?.options || this.fallbackOptions;
        return (incoming || []).map((o, idx) => ({
            id: o.id ?? String(idx + 1),
            label: o.label ?? 'Option',
            message: o.message ?? ''
        }));
    }

    get hasOptions() {
        return this.options.length > 0 && !this.loading && !this.error;
    }

    async loadFallbackOptions() {
        this.loading = true;
        this.error = undefined;
        try {
            const response = await getStartupOptions();
            this.fallbackOptions = response?.options || [];
        } catch (e) {
            this.error = e;
        } finally {
            this.loading = false;
        }
    }

    handleSelect(event) {
        const selected = {
            id: event.currentTarget.dataset.id,
            label: event.currentTarget.dataset.label,
            message: event.currentTarget.dataset.message
        };

        // Event 1: for your custom parent handling
        this.dispatchEvent(
            new CustomEvent('optionselect', {
                detail: selected,
                bubbles: true,
                composed: true
            })
        );

        // Event 2: commonly used by host wrappers to send user text
        this.dispatchEvent(
            new CustomEvent('sendmessage', {
                detail: { text: selected.message },
                bubbles: true,
                composed: true
            })
        );
    }
}