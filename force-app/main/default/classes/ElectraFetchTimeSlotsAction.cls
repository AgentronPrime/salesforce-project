public with sharing class ElectraFetchTimeSlotsAction {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String dealerId;

        @InvocableVariable(required=true)
        public String selectedDate;
    }

    public class ResponseWrapper {
        @InvocableVariable
        public String slotDisplayList;

        @InvocableVariable
        public String slotIdMap;

        @InvocableVariable
        public Integer totalCount;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Fetch Available Time Slots'
        description='Returns available 30-min time slots for a dealer on a selected date'
    )
    public static List<ResponseWrapper> fetchSlots(
                            List<RequestWrapper> requests) {

        List<ResponseWrapper> results =
            new List<ResponseWrapper>();

        for (RequestWrapper req : requests) {

            ResponseWrapper res = new ResponseWrapper();

            try {
                // ── Always derive today in IST (UTC+5:30 = 19800 seconds) ──
                // Date.today() uses org timezone (PDT/UTC-7) which causes
                // wrong date when accessed from IST. This fix is timezone-safe.
                DateTime nowIST  = DateTime.now().addSeconds(19800);
                Date today       = nowIST.date();
                Date maxDate     = today.addDays(7);

                Date selDate = Date.valueOf(req.selectedDate);

                if (selDate < today || selDate > maxDate) {
                    res.message         =
                        'Please select a date between ' +
                        'today and the next 7 days.';
                    res.totalCount      = 0;
                    res.slotDisplayList = '';
                    res.slotIdMap       = '';
                    results.add(res);
                    continue;
                }

                List<Test_Drive__c> booked = [
                    SELECT Slot_Label__c
                    FROM Test_Drive__c
                    WHERE Dealer__c        = :req.dealerId
                    AND Test_Drive_Date__c = :selDate
                    AND Status__c         != 'Cancelled'
                ];

                Set<String> bookedSlots = new Set<String>();
                for (Test_Drive__c td : booked) {
                    if (td.Slot_Label__c != null) {
                        bookedSlots.add(td.Slot_Label__c);
                    }
                }

                // ── IST current hour & minute (only used when date = today) ──
                Boolean isToday        = (selDate == today);
                Integer currentHour24  = 0;
                Integer currentMinute  = 0;

                if (isToday) {
                    currentHour24 = nowIST.hour();
                    currentMinute = nowIST.minute();
                }

                List<String> allSlots = new List<String>{
                    '10:00 AM - 10:30 AM',
                    '10:30 AM - 11:00 AM',
                    '11:00 AM - 11:30 AM',
                    '11:30 AM - 12:00 PM',
                    '12:00 PM - 12:30 PM',
                    '12:30 PM - 01:00 PM',
                    '01:00 PM - 01:30 PM',
                    '01:30 PM - 02:00 PM',
                    '02:00 PM - 02:30 PM',
                    '02:30 PM - 03:00 PM',
                    '03:00 PM - 03:30 PM',
                    '03:30 PM - 04:00 PM',
                    '04:00 PM - 04:30 PM',
                    '04:30 PM - 05:00 PM',
                    '05:00 PM - 05:30 PM',
                    '05:30 PM - 06:00 PM'
                };

                // Slot start times in 24h — parallel to allSlots
                List<Integer> slotHours = new List<Integer>{
                    10, 10, 11, 11, 12, 12, 13, 13,
                    14, 14, 15, 15, 16, 16, 17, 17
                };
                List<Integer> slotMinutes = new List<Integer>{
                     0, 30,  0, 30,  0, 30,  0, 30,
                     0, 30,  0, 30,  0, 30,  0, 30
                };

                String displayStr      = '';
                List<String> idEntries = new List<String>();
                Integer idx = 1;

                for (Integer i = 0; i < allSlots.size(); i++) {
                    String slot = allSlots[i];

                    // Skip already booked slots
                    if (bookedSlots.contains(slot)) {
                        continue;
                    }

                    // If today, skip slots whose start time has already passed
                    if (isToday) {
                        Integer currentTotalMins = currentHour24 * 60 + currentMinute;
                        Integer slotTotalMins    = slotHours[i] * 60 + slotMinutes[i];

                        if (slotTotalMins <= currentTotalMins) {
                            continue;
                        }
                    }

                    // Add to available list
                    if (idx == 1) {
                        displayStr += idx + '. ' + slot;
                    } else {
                        displayStr += '\n' + idx + '. ' + slot;
                    }
                    idEntries.add(idx + '##' + slot);
                    idx++;
                }

                if (idx == 1) {
                    if (isToday) {
                        res.message =
                            'No more slots are available for today. ' +
                            'Would you like to book for tomorrow or another date?';
                    } else {
                        res.message =
                            'No slots available for this date. ' +
                            'Please choose another date.';
                    }
                    res.totalCount      = 0;
                    res.slotDisplayList = '';
                    res.slotIdMap       = '';
                } else {
                    res.slotDisplayList = displayStr;
                    res.slotIdMap       = String.join(idEntries, '||');
                    res.totalCount      = idx - 1;
                    res.message         = 'Success';
                }

                results.add(res);

            } catch (Exception e) {
                res.message         =
                    'Error fetching slots: ' + e.getMessage();
                res.totalCount      = 0;
                res.slotDisplayList = '';
                res.slotIdMap       = '';
                results.add(res);
            }
        }

        return results;
    }
}