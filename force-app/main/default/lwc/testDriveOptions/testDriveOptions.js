import { LightningElement } from 'lwc';

export default class TestDriveOptions extends LightningElement {

    // Handle option click — Book
    handleBookClick() {
        this.dispatchEvent(new CustomEvent('useraction', {
            detail: {
                action: 'Book a Test Drive'
            },
            bubbles: true,
            composed: true
        }));
    }

    // Handle option click — Review
    handleReviewClick() {
        this.dispatchEvent(new CustomEvent('useraction', {
            detail: {
                action: 'Review My Test Drive'
            },
            bubbles: true,
            composed: true
        }));
    }
}