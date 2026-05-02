/**
 * @description Handler for Test_Drive__c.
 *
 * Priority Routing:
 *   Routing_Priority__c picklist set BEFORE queue assignment.
 *   Service Channel reads this as Secondary Routing Priority.
 *   Field is set only when record is NOT owned by a Queue
 *   (to avoid FIELD_INTEGRITY_EXCEPTION).
 */
public without sharing class TestDriveTriggerHandler {

    // ── Status Constants ────────────────────────────────────────
    public static final String STATUS_NEW         = 'New';
    public static final String STATUS_REQUESTED   = 'Requested';
    public static final String STATUS_DL_VERIFIED = 'DL Verified';
    public static final String STATUS_PENDING_DL_VERIFIED = 'Pending DL Verification';
    public static final String STATUS_DL_PENDING  = 'DL Pending';
    public static final String STATUS_SCHEDULED   = 'Test Drive Scheduled';

    // ── Queue Names ─────────────────────────────────────────────
    @TestVisible
    public static final String VERIFICATION_QUEUE = 'Verification_Queue';
    @TestVisible
    public static final String DEALER_QUEUE = 'Test_Drive_Requests_Queue';

    private static final String SKILL_PREFIX = 'Zip_';

    // ── Recursion Guard ─────────────────────────────────────────
    private static Boolean isProcessing = false;

    // ── Queue Id Cache ──────────────────────────────────────────
    private static Set<Id> queueIdCache;
    private static Set<Id> getQueueIds() {
        if (queueIdCache == null) {
            queueIdCache = new Set<Id>();
            for (Group g : [
                SELECT Id
                FROM Group
                WHERE Type = 'Queue'
            ]) {
                queueIdCache.add(g.Id);
            }
        }
        return queueIdCache;
    }

    // ── Cached Queue Map ────────────────────────────────────────
    private static Map<String, Id> queueCache;
    public static Map<String, Id> getQueueMap() {
        if (queueCache == null) {
            queueCache = new Map<String, Id>();
            for (Group g : [
                SELECT Id, DeveloperName
                FROM Group
                WHERE DeveloperName IN (:VERIFICATION_QUEUE, :DEALER_QUEUE)
                AND Type = 'Queue'
            ]) {
                queueCache.put(g.DeveloperName, g.Id);
            }
        }
        return queueCache;
    }

    // ── Cached Service Channel ──────────────────────────────────
    private static Id channelCache;
    public static Id getServiceChannelId() {
        if (channelCache == null) {
            List<ServiceChannel> channels = [
                SELECT Id
                FROM ServiceChannel
                WHERE RelatedEntity = 'Test_Drive__c'
                LIMIT 1
            ];
            channelCache = channels.isEmpty() ? null : channels[0].Id;
        }
        return channelCache;
    }

    // ────────────────────────────────────────────────────────────
    // ENTRY POINT
    // ────────────────────────────────────────────────────────────

    public static void execute(
        List<Test_Drive__c> newList,
        Map<Id, Test_Drive__c> oldMap,
        System.TriggerOperation operation
    ) {
        switch on operation {
            when BEFORE_INSERT {
                setRoutingPriority(newList);
            }
            when BEFORE_UPDATE {
                setRoutingPrioritySafe(newList);
            }
            when AFTER_INSERT {
                /* if (!isProcessing) {
                    isProcessing = true;
                    moveToVerificationQueue(newList,oldMap);
                    isProcessing = false;
                } */
            }
            when AFTER_UPDATE {
                if (!isProcessing) {
                    isProcessing = true;
                    moveToVerificationQueue(newList, oldMap);
                    handleDLVerified(newList, oldMap);
                    isProcessing = false;
                }
            }
        }
    }

    // ────────────────────────────────────────────────────────────
    // BEFORE INSERT: Always set priority (record not in queue yet)
    // ────────────────────────────────────────────────────────────

    private static void setRoutingPriority(List<Test_Drive__c> records) {
        for (Test_Drive__c td : records) {
            td.Routing_Priority__c = RoutingPriorityCalculator.calculatePriority(td.Test_Drive_Date_Time__c);
        }
    }

    // ────────────────────────────────────────────────────────────
    // BEFORE UPDATE: Only set priority if NOT owned by a Queue
    // ────────────────────────────────────────────────────────────

    /**
     * @description Sets Routing_Priority__c ONLY when the record
     *              is NOT currently owned by a Queue.
     *
     *              When a record is in a Queue with Routing Config,
     *              Salesforce locks the Secondary Routing Priority
     *              field and throws FIELD_INTEGRITY_EXCEPTION.
     *
     *              Priority is set here (before queue assignment).
     *              The AFTER trigger then moves it to the Queue.
     *              By then, the priority field is already saved.
     */
    private static void setRoutingPrioritySafe(List<Test_Drive__c> records) {
        Set<Id> queueIds = getQueueIds();

        for (Test_Drive__c td : records) {
            // Only set if NOT owned by a Queue
            if (!queueIds.contains(td.OwnerId)) {
                td.Routing_Priority__c = RoutingPriorityCalculator.calculatePriority(td.Test_Drive_Date_Time__c);
            }
        }
    }

    // ────────────────────────────────────────────────────────────
    // AFTER UPDATE: Queue + PSR for Verification
    // ────────────────────────────────────────────────────────────

    private static void moveToVerificationQueue(
        List<Test_Drive__c> newList,
        Map<Id, Test_Drive__c> oldMap
    ) {
        Id vQueueId  = getQueueMap().get(VERIFICATION_QUEUE);
        Id channelId = getServiceChannelId();

        if (vQueueId == null || channelId == null) {
            System.debug(LoggingLevel.ERROR,
                'Verification Queue or Service Channel not found');
            return;
        }

        List<Test_Drive__c> toUpdate = new List<Test_Drive__c>();
        List<Test_Drive__c> eligibleForPSR = new List<Test_Drive__c>();

        for (Test_Drive__c td : newList) {
            Test_Drive__c oldTd = oldMap.get(td.Id);
            if (td.Status__c == STATUS_PENDING_DL_VERIFIED
                && oldTd.Status__c != STATUS_PENDING_DL_VERIFIED
                && String.isNotBlank(td.Pincdoe__c)) {

                toUpdate.add(new Test_Drive__c(
                    Id        = td.Id,
                    OwnerId   = vQueueId,
                    Status__c = STATUS_REQUESTED
                ));
                eligibleForPSR.add(td);
            }
        }

        if (!toUpdate.isEmpty()) {
            logDmlErrors(
                Database.update(toUpdate, false),
                'moveToVerificationQueue'
            );
        }

        if (!eligibleForPSR.isEmpty()) {
            createQueueBasedPSR(eligibleForPSR, channelId);
        }
    }

    // ────────────────────────────────────────────────────────────
    // AFTER UPDATE: DL Verified → Dealer Queue + Skills PSR
    // ────────────────────────────────────────────────────────────

    private static void handleDLVerified(
        List<Test_Drive__c> newList,
        Map<Id, Test_Drive__c> oldMap
    ) {
        Id dQueueId = getQueueMap().get(DEALER_QUEUE);
        Id channelId = getServiceChannelId();

        if (dQueueId == null || channelId == null) {
            System.debug(LoggingLevel.ERROR,
                'Dealer Queue or Service Channel not found');
            return;
        }

        List<Test_Drive__c> verifiedRecords = new List<Test_Drive__c>();
        Set<String> zipCodes = new Set<String>();

        for (Test_Drive__c td : newList) {
            Test_Drive__c oldTd = oldMap.get(td.Id);
            if (td.Status__c == STATUS_DL_VERIFIED
                && oldTd.Status__c != STATUS_DL_VERIFIED
                && String.isNotBlank(td.Pincdoe__c)) {
                verifiedRecords.add(td);
                zipCodes.add(td.Pincdoe__c.trim());
            }
        }

        if (verifiedRecords.isEmpty()) {
            return;
        }

        Set<String> validZips = getValidDealerZips(zipCodes);

        if (validZips.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'No active Dealer Users found for zips: ' + zipCodes);
            return;
        }

        List<Test_Drive__c> toUpdate = new List<Test_Drive__c>();
        List<Test_Drive__c> validForRouting = new List<Test_Drive__c>();

        for (Test_Drive__c td : verifiedRecords) {
            String zip = td.Pincdoe__c.trim();
            if (validZips.contains(zip)) {
                toUpdate.add(new Test_Drive__c(
                    Id      = td.Id,
                    OwnerId = dQueueId
                ));
                validForRouting.add(td);
            } else {
                System.debug(LoggingLevel.WARN,
                    'No Dealer User for zip: ' + zip
                    + ' on record: ' + td.Id);
            }
        }

        if (!toUpdate.isEmpty()) {
            logDmlErrors(
                Database.update(toUpdate, false),
                'handleDLVerified_Queue'
            );
        }

        if (!validForRouting.isEmpty()) {
            createSkillsBasedPSR(validForRouting, channelId);
        }
    }

    // ────────────────────────────────────────────────────────────
    // ZIP VALIDATION
    // ────────────────────────────────────────────────────────────

    @TestVisible
    private static Set<String> getValidDealerZips(Set<String> zipCodes) {
        Set<String> validZips = new Set<String>();
        for (User u : [
            SELECT Dealer_Zip__c
            FROM User
            WHERE Dealer_Zip__c IN :zipCodes
            AND IsActive = TRUE
            AND Dealer_Zip__c != NULL
        ]) {
            validZips.add(u.Dealer_Zip__c.trim());
        }
        return validZips;
    }

    // ────────────────────────────────────────────────────────────
    // PSR: Queue-Based (Verification)
    // ────────────────────────────────────────────────────────────

    private static void createQueueBasedPSR(
        List<Test_Drive__c> records,
        Id channelId
    ) {
        List<PendingServiceRouting> psrList =
            new List<PendingServiceRouting>();

        for (Test_Drive__c td : records) {
            PendingServiceRouting psr = new PendingServiceRouting();
            psr.ServiceChannelId  = channelId;
            psr.WorkItemId        = td.Id;
            psr.RoutingType       = 'QueueBased';
            psr.CapacityWeight    = 1;
            psr.IsReadyForRouting = false;
            psrList.add(psr);
        }

        if (psrList.isEmpty()) {
            return;
        }

        logDmlErrors(
            Database.insert(psrList, false),
            'createQueueBasedPSR_Insert'
        );

        List<PendingServiceRouting> toActivate =
            new List<PendingServiceRouting>();
        for (PendingServiceRouting psr : psrList) {
            if (psr.Id != null) {
                psr.IsReadyForRouting = true;
                toActivate.add(psr);
            }
        }

        if (!toActivate.isEmpty()) {
            logDmlErrors(
                Database.update(toActivate, false),
                'createQueueBasedPSR_Ready'
            );
        }
    }

    // ────────────────────────────────────────────────────────────
    // PSR: Skills-Based (Dealer)
    // ────────────────────────────────────────────────────────────

    private static void createSkillsBasedPSR(
        List<Test_Drive__c> records,
        Id channelId
    ) {
        Set<String> skillDevNames = new Set<String>();
        Map<Id, String> recordToSkillName = new Map<Id, String>();

        for (Test_Drive__c td : records) {
            String skillName = SKILL_PREFIX + td.Pincdoe__c.trim();
            skillDevNames.add(skillName);
            recordToSkillName.put(td.Id, skillName);
        }

        Map<String, Id> skillMap = new Map<String, Id>();
        for (Skill s : [
            SELECT Id, DeveloperName
            FROM Skill
            WHERE DeveloperName IN :skillDevNames
        ]) {
            skillMap.put(s.DeveloperName, s.Id);
        }

        if (skillMap.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                'No skills found for: ' + skillDevNames);
            return;
        }

        Set<Id> workItemIds = recordToSkillName.keySet();
        List<PendingServiceRouting> existingPsr = [
            SELECT Id, RoutingType, WorkItemId
            FROM PendingServiceRouting
            WHERE WorkItemId IN :workItemIds
        ];

        if (!existingPsr.isEmpty()) {
            List<Database.DeleteResult> deleteResults =
                Database.delete(existingPsr, false);

            for (Integer i = 0; i < deleteResults.size(); i++) {
                if (!deleteResults[i].isSuccess()) {
                    System.debug(LoggingLevel.WARN,
                        'Cannot delete PSR: '
                        + existingPsr[i].Id
                        + ' Error: '
                        + deleteResults[i].getErrors()[0].getMessage());
                }
            }
        }

        Set<Id> blockedWorkItems = new Set<Id>();
        for (PendingServiceRouting psr : [
            SELECT WorkItemId
            FROM PendingServiceRouting
            WHERE WorkItemId IN :workItemIds
        ]) {
            blockedWorkItems.add(psr.WorkItemId);
        }

        List<PendingServiceRouting> psrList =
            new List<PendingServiceRouting>();
        Map<Id, String> psrWorkItemToSkill =
            new Map<Id, String>();

        for (Test_Drive__c td : records) {
            if (blockedWorkItems.contains(td.Id)) {
                continue;
            }

            String skillName = recordToSkillName.get(td.Id);
            if (!skillMap.containsKey(skillName)) {
                continue;
            }

            PendingServiceRouting psr = new PendingServiceRouting();
            psr.ServiceChannelId  = channelId;
            psr.WorkItemId        = td.Id;
            psr.RoutingType       = 'SkillsBased';
            psr.CapacityWeight    = 1;
            psr.RoutingModel      = 'MostAvailable';
            psr.IsReadyForRouting = false;
            psrList.add(psr);
            psrWorkItemToSkill.put(td.Id, skillName);
        }

        if (psrList.isEmpty()) {
            return;
        }

        List<Database.SaveResult> insertResults =
            Database.insert(psrList, false);

        List<PendingServiceRouting> successPsr =
            new List<PendingServiceRouting>();
        for (Integer i = 0; i < insertResults.size(); i++) {
            if (insertResults[i].isSuccess()) {
                successPsr.add(psrList[i]);
            } else {
                System.debug(LoggingLevel.ERROR,
                    'PSR insert failed: '
                    + insertResults[i].getErrors()[0].getMessage());
            }
        }

        if (successPsr.isEmpty()) {
            return;
        }

        List<SkillRequirement> skillReqs =
            new List<SkillRequirement>();

        for (PendingServiceRouting psr : successPsr) {
            String skillName = psrWorkItemToSkill.get(psr.WorkItemId);
            if (skillName != null && skillMap.containsKey(skillName)) {
                skillReqs.add(new SkillRequirement(
                    RelatedRecordId = psr.Id,
                    SkillId         = skillMap.get(skillName),
                    SkillLevel      = 1
                ));
            }
        }

        if (!skillReqs.isEmpty()) {
            Database.insert(skillReqs, false);
        }

        for (PendingServiceRouting psr : successPsr) {
            psr.IsReadyForRouting = true;
        }
        Database.update(successPsr, false);
    }

    // ────────────────────────────────────────────────────────────
    // UTILITY
    // ────────────────────────────────────────────────────────────

    private static void logDmlErrors(
        List<Database.SaveResult> results, String ctx
    ) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,
                        '[TestDriveTriggerHandler.' + ctx + '] '
                        + sr.getId() + ': ' + err.getMessage());
                }
            }
        }
    }
}