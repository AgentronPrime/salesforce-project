public with sharing class ElectraCreateLeadAction {
    
    public class RequestWrapper {
        
        @InvocableVariable(required=true)
        public String phoneNumber;
        
        @InvocableVariable(required=true)
        public String fullName;
        
        @InvocableVariable(required=false)
        public String street;
        
        @InvocableVariable(required=false)
        public String city;
        
        @InvocableVariable(required=false)
        public String state;
        
        @InvocableVariable(required=false)
        public String zip;
        
        @InvocableVariable(required=false)
        public String country;
    }
    
    public class ResponseWrapper {
        
        @InvocableVariable
        public Id leadId;
        
        @InvocableVariable
        public String leadName;
        
        @InvocableVariable
        public String message;
    }
    
    @InvocableMethod(
        label='Create Lead From Phone And Name'
        description='Creates a Lead using phone number, full name, and address details.'
    )
    public static List<ResponseWrapper> createLead(List<RequestWrapper> requests) {
        List<ResponseWrapper> results = new List<ResponseWrapper>();
        
        for (RequestWrapper req : requests) {
            ResponseWrapper res = new ResponseWrapper();
            
            String fullName    = req.fullName    != null ? req.fullName.trim()    : '';
            String phoneNumber = req.phoneNumber != null ? req.phoneNumber.trim() : '';
            
            if (String.isBlank(fullName) || String.isBlank(phoneNumber)) {
                res.message = 'Full name and phone number are required.';
                results.add(res);
                continue;
            }
            
            String firstName = null;
            String lastName  = fullName;
            
            if (fullName.contains(' ')) {
                Integer idx = fullName.lastIndexOf(' ');
                firstName = fullName.substring(0, idx).trim();
                lastName  = fullName.substring(idx + 1).trim();
            }
            
            Lead newLead        = new Lead();
            newLead.FirstName   = firstName;
            newLead.LastName    = lastName;
            newLead.MobilePhone = phoneNumber;
            newLead.Company     = 'Electra Website Lead';
            
            // Address fields
            if (!String.isBlank(req.street)) newLead.Street     = req.street.trim();
            if (!String.isBlank(req.city))   newLead.City       = req.city.trim();
            if (!String.isBlank(req.state))  newLead.State      = req.state.trim();
            if (!String.isBlank(req.zip))    newLead.PostalCode = req.zip.trim();
            newLead.Country = (!String.isBlank(req.country)) ? req.country.trim() : 'IN';
            
            insert newLead;
            
            res.leadId   = newLead.Id;
            res.leadName = ((newLead.FirstName != null ? newLead.FirstName + ' ' : '') + newLead.LastName).trim();
            res.message  = 'Lead created successfully';
            
            results.add(res);
        }
        
        return results;
    }
    
}