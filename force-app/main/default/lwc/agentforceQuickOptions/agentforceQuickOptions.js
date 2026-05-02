import { LightningElement, api } from 'lwc';

/**
 * Quick-option chips styled like Agentforce suggested prompts.
 * Place this component on the same Experience Cloud page as your embedded chat;
 * listen for the `quickoptionselect` event on the page or wrap in a parent that
 * forwards text to your Messaging / Agentforce integration.
 */
export default class AgentforceQuickOptions extends LightningElement {
    @api headerTitle = 'Need help? Choose an option.';
    @api showHeader = false;

    options = [
        { id: '1', label: 'New customer?', message: 'I am a new customer and need help getting started.' },
        {
            id: '2',
            label: 'Book a test drive (Already In)',
            message: 'I am already in the flow — I want to book a test drive.'
        },
        {
            id: '3',
            label: 'Give a review for the Test drive',
            message: 'I would like to leave a review for my test drive experience.'
        }
    ];

    handleOptionClick(event) {
        const id = event.currentTarget.dataset.id;
        const opt = this.options.find((o) => o.id === id);
        if (!opt) {
            return;
        }

        this.dispatchEvent(
            new CustomEvent('quickoptionselect', {
                detail: {
                    id: opt.id,
                    label: opt.label,
                    message: opt.message
                },
                bubbles: true,
                composed: true
            })
        );
    }
}