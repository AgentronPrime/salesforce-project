import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import BANNER_IMAGE from '@salesforce/resourceUrl/Banner_Car_Evet_Background';

export default class EventBanner extends NavigationMixin(LightningElement) {

    // Configurable Properties from Experience Builder
    @api titleLine1 = 'Car Month';
    @api titleLine2 = 'Sales Event';
    @api subtitle = 'Exclusive Offers 2026';
    @api description = 'Discover unbeatable deals on premium vehicles. Trade-in bonuses, special financing, and exclusive packages available this month only.';
    @api primaryButtonLabel = 'Learn More';
    @api secondaryButtonLabel = 'Contact Us';
    @api primaryPageName = 'Learn_More';
    @api secondaryPageName = 'Contact_Us';
    @api bannerHeight = '92vh';

    // Internal
    _backgroundUrl = BANNER_IMAGE;
    _hasRendered = false;

    // Apply background image and animations after render
    renderedCallback() {
        if (this._hasRendered) return;
        this._hasRendered = true;

        // Set background image via JavaScript
        const bgElement = this.refs.heroBg;
        if (bgElement) {
            bgElement.style.backgroundImage = `url('${this._backgroundUrl}')`;
            bgElement.style.minHeight = this.bannerHeight;
        }

        // Set banner height
        const bannerEl = this.template.querySelector('.hero-banner');
        if (bannerEl) {
            bannerEl.style.minHeight = this.bannerHeight;
        }

        // Trigger entrance animation
        const content = this.refs.heroContent;
        if (content) {
            // Small delay for smooth entrance
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                content.classList.add('animate-in');
            }, 100);
        }
    }

    // Navigation Handlers
    handleLearnMore() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: this.primaryPageName
            }
        });
    }

    handleContactUs() {
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: this.secondaryPageName
            }
        });
    }

    handleScrollDown() {
        const bannerEl = this.template.querySelector('.hero-banner');
        if (bannerEl) {
            const bannerBottom = bannerEl.getBoundingClientRect().bottom + window.scrollY;
            window.scrollTo({
                top: bannerBottom,
                behavior: 'smooth'
            });
        }
    }
}