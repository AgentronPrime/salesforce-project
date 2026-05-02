public with sharing class ElectraFetchAvailableDatesAction {

    public class RequestWrapper {
        @InvocableVariable(required=false)
        public String placeholder; // not used, required for Agentforce action structure
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String dateDisplayList;  // Numbered list e.g. "1. 01-May-2026\n2. 02-May-2026"

        @InvocableVariable
        public String dateValueMap;     // For parsing e.g. "1##2026-05-01||2##2026-05-02"

        @InvocableVariable
        public String todayDisplay;     // e.g. "01-May-2026"

        @InvocableVariable
        public String todayValue;       // e.g. "2026-05-01" (for SOQL use)

        @InvocableVariable
        public Integer totalDays;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Fetch Available Booking Dates'
        description='Returns todays date and next 7 days in IST for test drive date selection. Always call this action to get available dates — never calculate dates manually.'
    )
    public static List<ResponseWrapper> fetchDates(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results = new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {

            ResponseWrapper res = new ResponseWrapper();

            try {
                // ── Derive today in IST (UTC+5:30 = 19800 seconds) ──
                // Never use Date.today() — org timezone is PDT (UTC-7)
                // which returns wrong date when accessed from India.
                DateTime nowIST = DateTime.now().addSeconds(19800);
                Date today      = nowIST.date();

                String displayStr      = '';
                List<String> mapEntries = new List<String>();

                for (Integer i = 0; i < 7; i++) {
                    Date d         = today.addDays(i);
                    String display = formatDate(d);   // e.g. 01-May-2026
                    String value   = String.valueOf(d); // e.g. 2026-05-01

                    if (i == 0) {
                        displayStr += (i + 1) + '. ' + display;
                    } else {
                        displayStr += '\n' + (i + 1) + '. ' + display;
                    }
                    mapEntries.add((i + 1) + '##' + value);
                }

                res.dateDisplayList = displayStr;
                res.dateValueMap    = String.join(mapEntries, '||');
                res.todayDisplay    = formatDate(today);
                res.todayValue      = String.valueOf(today);
                res.totalDays       = 7;
                res.message         = 'Success';

            } catch (Exception e) {
                res.message         = 'Error fetching dates: ' + e.getMessage();
                res.dateDisplayList = '';
                res.dateValueMap    = '';
                res.todayDisplay    = '';
                res.todayValue      = '';
                res.totalDays       = 0;
            }

            results.add(res);
        }

        return results;
    }

    // ── Helper: format Date as DD-MMM-YYYY ──────────────────────────
    private static String formatDate(Date d) {
        String[] months = new String[]{
            'Jan','Feb','Mar','Apr','May','Jun',
            'Jul','Aug','Sep','Oct','Nov','Dec'
        };
        String dd  = String.valueOf(d.day()).leftPad(2, '0');
        String mmm = months[d.month() - 1];
        String yyyy = String.valueOf(d.year());
        return dd + '-' + mmm + '-' + yyyy;
    }
}