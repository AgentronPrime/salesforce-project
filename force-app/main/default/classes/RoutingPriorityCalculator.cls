/**
 * @description Calculates Omni-Channel routing priority
 *              based on how soon the Test Drive is scheduled.
 *
 * Sooner test drives = lower priority number = routed first.
 * Returns String (for Picklist field): "1" to "10"
 *
 * Service Channel Secondary Routing Priority reads
 * the picklist field and sorts ascending (1 first, 10 last).
 */
public without sharing class RoutingPriorityCalculator {

    /**
     * @description Priority tiers based on hours until test drive.
     *
     * Hours Until        Priority
     * ──────────         ────────
     * Past / ≤2 hrs      1  (Immediate)
     * 2-6 hrs             2  (Very Urgent)
     * 6-12 hrs            3  (Urgent)
     * 12-24 hrs           4  (Today)
     * 1-2 days            5  (Tomorrow)
     * 2-3 days            6  (Soon)
     * 3-5 days            7  (This Week)
     * 5-7 days            8  (Next Week)
     * 7+ days             9  (Standard)
     * No date             10 (Lowest)
     */
    public static String calculatePriority(DateTime testDriveDateTime) {
        if (testDriveDateTime == null) {
            return '10';
        }

        Long minutesUntil = getMinutesDifference(
            System.now(), testDriveDateTime
        );

        if (minutesUntil <= 120)   return '1';
        if (minutesUntil <= 360)   return '2';
        if (minutesUntil <= 720)   return '3';
        if (minutesUntil <= 1440)  return '4';
        if (minutesUntil <= 2880)  return '5';
        if (minutesUntil <= 4320)  return '6';
        if (minutesUntil <= 7200)  return '7';
        if (minutesUntil <= 10080) return '8';
        return '9';
    }

    private static Long getMinutesDifference(
        DateTime fromDT, DateTime toDT
    ) {
        return (toDT.getTime() - fromDT.getTime()) / 60000;
    }
}