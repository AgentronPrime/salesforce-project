public with sharing class ElectraLookupLeadByPhoneAction {
    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String phoneNumber;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public Boolean foundLead;
        
        @InvocableVariable
        public Id leadId;
        
        @InvocableVariable
        public String leadName;
        
        @InvocableVariable
        public String message;
    }
    
    @InvocableMethod(
        label='Lookup Lead By Phone'
        description='Looks up a Lead using mobile phone or phone number.'
    )
    public static List<ResponseWrapper> lookupLead(List<RequestWrapper> requests) {
        List<ResponseWrapper> results = new List<ResponseWrapper>();
        
        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            
            String inputPhone = normalizePhone(req.phoneNumber);
            
            if (String.isBlank(inputPhone)) {
                res.foundLead = false;
                res.message = 'No valid phone number was provided.';
                results.add(res);
                continue;
            }
            
            Lead matchedLead = null;
            
            for (Lead l : [
                SELECT Id, Name, Phone, MobilePhone
                FROM Lead
                WHERE Phone != null OR MobilePhone != null
                LIMIT 5000
            ]) {
                String phone = normalizePhone(l.Phone);
                String mobile = normalizePhone(l.MobilePhone);
                
                if (inputPhone == phone || inputPhone == mobile) {
                    matchedLead = l;
                    break;
                }
            }
            
            if (matchedLead != null) {
                res.foundLead = true;
                res.leadId = matchedLead.Id;
                res.leadName = matchedLead.Name;
                res.message = 'Lead found';
            } else {
                res.foundLead = false;
                res.message = 'No lead found';
            }
            
            results.add(res);
        }
        
        return results;
    }
    
    private static String normalizePhone(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        return value.replaceAll('[^0-9]', '');
    } 
}