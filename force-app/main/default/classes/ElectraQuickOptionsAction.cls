public with sharing class ElectraQuickOptionsAction {
    public class RequestWrapper {
        @InvocableVariable(required=false)
        public String customerMessage;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String result;

        public ResponseWrapper() {
        }

        public ResponseWrapper(String result) {
            this.result = result;
        }
    }

    @InvocableMethod(
        label='Get Electra Quick Options'
        description='Returns the startup menu for the Electra Agent.'
    )
    public static List<ResponseWrapper> getQuickOptions(List<RequestWrapper> requests) {
        String message =
            'Welcome! Please select one of the options below to get started.\n\n' +
            '1. Book a Test Drive\n' +
            '2. Review a Test Drive\n' +
            '3. Reschedule/Cancel\n\n' +
            'Reply with 1, 2, or 3.';

        return new List<ResponseWrapper>{
            new ResponseWrapper(message)
        };
    }
}