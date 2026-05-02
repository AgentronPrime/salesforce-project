public with sharing class ElectraQuickOptionsController {
    @AuraEnabled(cacheable=true)
    public static ElectraQuickOptions.QuickOptionsResponse getStartupOptions() {
        return new ElectraQuickOptions.QuickOptionsResponse(
            new List<ElectraQuickOptions.QuickOptionRow>{
                new ElectraQuickOptions.QuickOptionRow('1', 'New Customer', 'I am a new customer.'),
                new ElectraQuickOptions.QuickOptionRow('2', 'Book a Test Drive', 'I want to book a test drive.'),
                new ElectraQuickOptions.QuickOptionRow('3', 'Review Test Drive', 'I want to review my test drive.')
            }
        );
    }
}