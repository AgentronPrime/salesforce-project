import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavigationBanner extends NavigationMixin(LightningElement) {

    @api logoUrl;
    @api brandName = 'AUTOMOTIVE';
    @api brandTagline = 'CLOUD';
    @api isLoggedIn = false;
    @api userName = 'John Doe';
    @api userEmail = 'john@example.com';

    @track activeNavId = 'home';
    @track isMobileMenuOpen = false;
    @track isSearchOpen = false;
    @track isUserMenuOpen = false;
    @track searchTerm = '';
    @track isScrolled = false;

    _scrollHandler;

    get navItems() {
        const items = [
            { id: 'home', label: 'Home', pageRef: 'Home', href: '/' },
            { id: 'vehicles', label: 'Vehicles', pageRef: 'VehicleShowcase__c', href: '/vehicleshowcase' },
            { id: 'service', label: 'Service & Support', pageRef: 'Service_Support__c', href: '/service-support' },
            { id: 'testdrive', label: 'Test Drive', pageRef: 'Test_Drive__c', href: '/test-drive' },
            { id: 'contact', label: 'Contact Us', pageRef: 'Contact_Us__c', href: '/contact-us' }
        ];

        return items.map(item => ({
            ...item,
            cssClass: `nav-link ${item.id === this.activeNavId ? 'nav-link-active' : ''}`,
            mobileCssClass: `mobile-nav-link ${item.id === this.activeNavId ? 'mobile-nav-link-active' : ''}`
        }));
    }

    get userInitials() {
        if (!this.userName) return 'U';
        const parts = this.userName.split(' ');
        if (parts.length >= 2) {
            return (parts[0][0] + parts[1][0]).toUpperCase();
        }
        return parts[0][0].toUpperCase();
    }

    get hamburgerClass() {
        return `hamburger ${this.isMobileMenuOpen ? 'hamburger-active' : ''}`;
    }

    get mobileMenuClass() {
        return `mobile-menu ${this.isMobileMenuOpen ? 'mobile-menu-open' : ''}`;
    }

    get searchBarClass() {
        return `search-bar ${this.isSearchOpen ? 'search-bar-open' : ''}`;
    }

    connectedCallback() {
        this._scrollHandler = this._handleScroll.bind(this);
        window.addEventListener('scroll', this._scrollHandler);
        this._detectActivePage();
    }

    disconnectedCallback() {
        window.removeEventListener('scroll', this._scrollHandler);
    }

    renderedCallback() {
        const header = this.template.querySelector('.nav-banner');
        if (header) {
            if (this.isScrolled) {
                header.classList.add('nav-scrolled');
            } else {
                header.classList.remove('nav-scrolled');
            }
        }
    }

    _handleScroll() {
        const scrolled = window.scrollY > 20;
        if (scrolled !== this.isScrolled) {
            this.isScrolled = scrolled;
            const header = this.template.querySelector('.nav-banner');
            if (header) {
                if (this.isScrolled) {
                    header.classList.add('nav-scrolled');
                } else {
                    header.classList.remove('nav-scrolled');
                }
            }
        }
    }

    _detectActivePage() {
        const path = window.location.pathname.toLowerCase();
        if (path.includes('vehicleshowcase') || path.includes('vehicle')) {
            this.activeNavId = 'vehicles';
        } else if (path.includes('service') || path.includes('support')) {
            this.activeNavId = 'service';
        } else if (path.includes('test-drive') || path.includes('testdrive')) {
            this.activeNavId = 'testdrive';
        } else if (path.includes('contact')) {
            this.activeNavId = 'contact';
        } else {
            this.activeNavId = 'home';
        }
    }

    handleLogoClick() {
        this.activeNavId = 'home';
        this.isMobileMenuOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Home'
            }
        });
    }

    handleNavClick(event) {
        event.preventDefault();
        const navId = event.currentTarget.dataset.id;
        const pageRef = event.currentTarget.dataset.page;

        this.activeNavId = navId;
        this.isMobileMenuOpen = false;

        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageRef
            }
        });
    }

    handleLogin() {
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'login'
            }
        });
    }

    handleLogout() {
        this.isUserMenuOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__loginPage',
            attributes: {
                actionName: 'logout'
            }
        });
    }

    handleMyAccount() {
        this.isUserMenuOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'My_Account__c'
            }
        });
    }

    handleMyVehicles() {
        this.isUserMenuOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'VehicleShowcase__c'
            }
        });
    }

    handleServiceHistory() {
        this.isUserMenuOpen = false;
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Service_History__c'
            }
        });
    }

    toggleMobileMenu() {
        this.isMobileMenuOpen = !this.isMobileMenuOpen;
        this.isSearchOpen = false;
        this.isUserMenuOpen = false;
    }

    toggleSearch() {
        this.isSearchOpen = !this.isSearchOpen;
        this.isMobileMenuOpen = false;
        this.isUserMenuOpen = false;

        if (this.isSearchOpen) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                const input = this.template.querySelector('.search-input');
                if (input) input.focus();
            }, 300);
        }
    }

    toggleUserMenu() {
        this.isUserMenuOpen = !this.isUserMenuOpen;
        this.isMobileMenuOpen = false;
        this.isSearchOpen = false;
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
    }

    handleSearchKeyup(event) {
        if (event.key === 'Enter' && this.searchTerm.trim()) {
            this.isSearchOpen = false;
            this.dispatchEvent(new CustomEvent('search', {
                detail: { searchTerm: this.searchTerm },
                bubbles: true,
                composed: true
            }));
        }
        if (event.key === 'Escape') {
            this.isSearchOpen = false;
        }
    }
}