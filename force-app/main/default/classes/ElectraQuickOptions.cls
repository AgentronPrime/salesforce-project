public with sharing class ElectraQuickOptions {

    public class QuickOptionsRequest {
        @AuraEnabled
        public String userMessage;

        public QuickOptionsRequest() {}
    }

    public class QuickOptionsResponse {
        @AuraEnabled
        public List<QuickOptionRow> options;

        public QuickOptionsResponse() {}

        public QuickOptionsResponse(List<QuickOptionRow> options) {
            this.options = options;
        }
    }

    public class QuickOptionRow {
        @AuraEnabled
        public String id;

        @AuraEnabled
        public String label;

        @AuraEnabled
        public String message;

        public QuickOptionRow() {}

        public QuickOptionRow(String id, String label, String message) {
            this.id = id;
            this.label = label;
            this.message = message;
        }
    }
}