/**
 * @description Finds a Lead by email, phone, or name for the Review Test Drive agent.
 *              Bulkified for multiple requests in one transaction.
 *              No Contact lookup exists — all searches target Lead only.
 */
public with sharing class TestDriveReviewService {

    // ─────────────────────────────────────────────
    // Input / Output Wrappers
    // ─────────────────────────────────────────────
  /*  public class CustomerSearchRequest {
        @InvocableVariable(label='Email Address' required=false)
        public String email;

        @InvocableVariable(label='Phone Number' required=false)
        public String phone;

        @InvocableVariable(label='Full Name' required=false)
        public String fullName;
    }

    public class CustomerSearchResult {
        @InvocableVariable(label='Customer Found')
        public Boolean customerFound;

        @InvocableVariable(label='Lead Record Id')
        public String leadId;

        @InvocableVariable(label='Customer Name')
        public String customerName;

        @InvocableVariable(label='Customer Email')
        public String customerEmail;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    // ─────────────────────────────────────────────
    // Invocable Method
    // ─────────────────────────────────────────────
    @InvocableMethod(
        label='Find Customer for Test Drive Review'
        description='Searches Lead records by email, phone, or name. Returns the matching Lead.'
        category='Test Drive'
    )
    public static List<CustomerSearchResult> findCustomer(
        List<CustomerSearchRequest> requests
    ) {
        List<CustomerSearchResult> results = new List<CustomerSearchResult>();

        // Collect all search values for bulk querying
        Set<String> emails = new Set<String>();
        Set<String> phones = new Set<String>();
        Set<String> names  = new Set<String>();

        for (CustomerSearchRequest req : requests) {
            if (String.isNotBlank(req.email))    emails.add(req.email.toLowerCase().trim());
            if (String.isNotBlank(req.phone))    phones.add(req.phone.trim());
            if (String.isNotBlank(req.fullName)) names.add(req.fullName.trim());
        }

        // Single bulk query against Lead
        Map<String, Lead> leadByEmail = new Map<String, Lead>();
        Map<String, Lead> leadByPhone = new Map<String, Lead>();
        Map<String, Lead> leadByName  = new Map<String, Lead>();

        if (!emails.isEmpty() || !phones.isEmpty() || !names.isEmpty()) {

            String soql = 'SELECT Id, Name, Email, Phone FROM Lead WHERE IsConverted = false AND (';
            List<String> clauses = new List<String>();

            if (!emails.isEmpty()) clauses.add('Email IN :emails');
            if (!phones.isEmpty()) clauses.add('Phone IN :phones');
            if (!names.isEmpty())  clauses.add('Name IN :names');

            soql += String.join(clauses, ' OR ') + ') WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 500';

            for (Lead l : Database.query(soql)) {
                if (l.Email != null && !leadByEmail.containsKey(l.Email.toLowerCase())) {
                    leadByEmail.put(l.Email.toLowerCase(), l);
                }
                if (l.Phone != null && !leadByPhone.containsKey(l.Phone)) {
                    leadByPhone.put(l.Phone, l);
                }
                if (l.Name != null && !leadByName.containsKey(l.Name)) {
                    leadByName.put(l.Name, l);
                }
            }
        }

        // Match each request — priority: Email > Phone > Name
        for (CustomerSearchRequest req : requests) {
            CustomerSearchResult res = new CustomerSearchResult();
            res.customerFound = false;

            Lead matched = null;

            if (matched == null && String.isNotBlank(req.email)) {
                matched = leadByEmail.get(req.email.toLowerCase().trim());
            }
            if (matched == null && String.isNotBlank(req.phone)) {
                matched = leadByPhone.get(req.phone.trim());
            }
            if (matched == null && String.isNotBlank(req.fullName)) {
                matched = leadByName.get(req.fullName.trim());
            }

            if (matched != null) {
                res.customerFound = true;
                res.leadId = matched.Id;
                res.customerName = matched.Name;
                res.customerEmail = matched.Email;
            } else {
                res.errorMessage = 'No matching customer found. Please verify your email, phone, or name.';
            }

            results.add(res);
        }

        return results;
    } */
}