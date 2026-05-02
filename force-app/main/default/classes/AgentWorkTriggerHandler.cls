/**
 * @description Handles AgentWork events for Test_Drive__c routing.
 *
 * Enhanced Omni-Channel Routing:
 *   WorkItemId in AgentWork can be:
 *     - Test_Drive__c Id (Queue-Based routing)
 *     - PendingServiceRouting Id (Skills-Based routing)
 *
 *   PSR is deleted after successful routing, so for
 *   Skills-Based (Dealer), we resolve the actual
 *   Test_Drive__c record using the agent's recent assignments.
 *
 * Rules:
 *   From Verification Queue → No auto status change
 *   From Dealer Queue → Status = "Test Drive Scheduled"
 *
 * Uses User.Dealer_Zip__c for zip validation.
 */
public without sharing class AgentWorkTriggerHandler {

    private static final String AW_STATUS_OPENED = 'Opened';

    private static final String TD_PREFIX;
    private static final String PSR_PREFIX;

    static {
        TD_PREFIX = Test_Drive__c.SObjectType
            .getDescribe().getKeyPrefix();
        PSR_PREFIX = PendingServiceRouting.SObjectType
            .getDescribe().getKeyPrefix();
    }

    // ────────────────────────────────────────────────────────────
    // ENTRY POINT
    // ────────────────────────────────────────────────────────────

    public static void execute(
        List<AgentWork> newList,
        Map<Id, AgentWork> oldMap,
        System.TriggerOperation operation
    ) {
        switch on operation {
            when AFTER_INSERT {
                processAcceptedWork(newList, null);
            }
            when AFTER_UPDATE {
                processAcceptedWork(newList, oldMap);
            }
        }
    }

    // ────────────────────────────────────────────────────────────
    // CORE LOGIC
    // ────────────────────────────────────────────────────────────

    private static void processAcceptedWork(
        List<AgentWork> newList,
        Map<Id, AgentWork> oldMap
    ) {
        Map<String, Id> queueMap = TestDriveTriggerHandler.getQueueMap();
        Id vQueueId = queueMap.get(TestDriveTriggerHandler.VERIFICATION_QUEUE);
        Id dQueueId = queueMap.get(TestDriveTriggerHandler.DEALER_QUEUE);

        // Collect work items by source queue
        // Key = WorkItemId or PSR Id, Value = AgentWork
        Set<Id> verificationTdIds = new Set<Id>();
        Map<Id, AgentWork> dealerWorkByPsrId = new Map<Id, AgentWork>();
        Map<Id, AgentWork> dealerWorkByTdId = new Map<Id, AgentWork>();

        for (AgentWork aw : newList) {
            // Only process Opened status
            if (aw.Status != AW_STATUS_OPENED) {
                continue;
            }

            // Skip if already was Opened
            if (oldMap != null) {
                AgentWork oldAw = oldMap.get(aw.Id);
                if (oldAw != null && oldAw.Status == AW_STATUS_OPENED) {
                    continue;
                }
            }

            // Skip if not from our queues
            if (aw.OriginalQueueId != vQueueId
                && aw.OriginalQueueId != dQueueId) {
                continue;
            }

            String prefix = String.valueOf(aw.WorkItemId)
                .substring(0, 3);

            // ── Verification Queue ──
            if (aw.OriginalQueueId == vQueueId && prefix == TD_PREFIX) {
                verificationTdIds.add(aw.WorkItemId);
                // No action — agent updates manually
            }

            // ── Dealer Queue ──
            if (aw.OriginalQueueId == dQueueId) {
                if (prefix == TD_PREFIX) {
                    // Direct Test Drive Id
                    dealerWorkByTdId.put(aw.WorkItemId, aw);
                } else if (prefix == PSR_PREFIX) {
                    // PSR Id (need to resolve)
                    dealerWorkByPsrId.put(aw.WorkItemId, aw);
                }
            }
        }

        // Handle Dealer acceptances
        if (!dealerWorkByTdId.isEmpty() || !dealerWorkByPsrId.isEmpty()) {
            handleDealerAcceptance(dealerWorkByTdId, dealerWorkByPsrId);
        }
    }

    // ────────────────────────────────────────────────────────────
    // DEALER ACCEPTANCE HANDLER
    // ────────────────────────────────────────────────────────────

    /**
     * @description Processes Dealer Queue acceptances.
     *
     * Two scenarios:
     *   A) WorkItemId = Test_Drive__c Id (direct)
     *      → Query Test Drive directly
     *
     *   B) WorkItemId = PSR Id (Skills-Based)
     *      → PSR may be deleted already
     *      → Try to resolve via PSR query first
     *      → If deleted, find by agent's User.Dealer_Zip__c
     *        matching Test_Drive__c.Zip_Code__c
     *
     * Updates matching records: Status → "Test Drive Scheduled"
     */
    private static void handleDealerAcceptance(
        Map<Id, AgentWork> directTdWork,
        Map<Id, AgentWork> psrWork
    ) {
        Set<Id> testDriveIds = new Set<Id>();
        Set<Id> agentUserIds = new Set<Id>();

        // Collect direct Test Drive Ids
        testDriveIds.addAll(directTdWork.keySet());
        for (AgentWork aw : directTdWork.values()) {
            agentUserIds.add(aw.UserId);
        }

        // Resolve PSR Ids → Test Drive Ids
        if (!psrWork.isEmpty()) {
            // Try querying PSR (may still exist briefly)
            Map<Id, Id> psrToTdId = new Map<Id, Id>();
            for (PendingServiceRouting psr : [
                SELECT Id, WorkItemId
                FROM PendingServiceRouting
                WHERE Id IN :psrWork.keySet()
            ]) {
                String prefix = String.valueOf(psr.WorkItemId)
                    .substring(0, 3);
                if (prefix == TD_PREFIX) {
                    psrToTdId.put(psr.Id, psr.WorkItemId);
                    testDriveIds.add(psr.WorkItemId);
                }
            }

            // Collect agents for resolved PSRs
            for (Id psrId : psrToTdId.keySet()) {
                AgentWork aw = psrWork.get(psrId);
                if (aw != null) {
                    agentUserIds.add(aw.UserId);
                }
            }

            // Handle unresolved PSRs (already deleted)
            Set<Id> unresolvedPsrIds = new Set<Id>(psrWork.keySet());
            unresolvedPsrIds.removeAll(psrToTdId.keySet());

            if (!unresolvedPsrIds.isEmpty()) {
                // Get agent Ids for unresolved work
                Set<Id> unresolvedAgentIds = new Set<Id>();
                for (Id psrId : unresolvedPsrIds) {
                    AgentWork aw = psrWork.get(psrId);
                    if (aw != null) {
                        unresolvedAgentIds.add(aw.UserId);
                        agentUserIds.add(aw.UserId);
                    }
                }

                // Find Test Drives by matching agent's Dealer_Zip__c
                // with Test_Drive__c.Zip_Code__c
                resolveByDealerZip(unresolvedAgentIds, testDriveIds);
            }
        }

        if (testDriveIds.isEmpty()) {
            return;
        }

        // Query Test Drive records and update status
        List<Test_Drive__c> toUpdate = new List<Test_Drive__c>();

        for (Test_Drive__c td : [
            SELECT Id, Status__c, OwnerId, Pincdoe__c
            FROM Test_Drive__c
            WHERE Id IN :testDriveIds
              AND Status__c = :TestDriveTriggerHandler.STATUS_DL_VERIFIED
        ]) {
            toUpdate.add(new Test_Drive__c(
                Id        = td.Id,
                Status__c = TestDriveTriggerHandler.STATUS_SCHEDULED
            ));
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    // ────────────────────────────────────────────────────────────
    // RESOLVE BY DEALER ZIP
    // ────────────────────────────────────────────────────────────

    /**
     * @description When PSR is deleted and we cannot resolve
     *              the Test Drive Id from PSR, we find it by:
     *
     *              1. Query agent's Dealer_Zip__c
     *              2. Find Test Drives with matching Zip_Code__c
     *                 AND Status = DL Verified
     *                 AND OwnerId = agent (just assigned by Omni)
     *
     * @param agentIds Set of agent User Ids
     * @param testDriveIds Set to add resolved Test Drive Ids into
     */
    private static void resolveByDealerZip(
        Set<Id> agentIds,
        Set<Id> testDriveIds
    ) {
        // Get agent zip codes
        Map<Id, String> agentZipMap = new Map<Id, String>();
        for (User u : [
            SELECT Id, Dealer_Zip__c
            FROM User
            WHERE Id IN :agentIds
              AND Dealer_Zip__c != NULL
        ]) {
            agentZipMap.put(u.Id, u.Dealer_Zip__c.trim());
        }

        if (agentZipMap.isEmpty()) {
            return;
        }

        // Find Test Drives owned by these agents
        // with matching zip and DL Verified status
        Set<String> agentZips = new Set<String>(agentZipMap.values());

        for (Test_Drive__c td : [
            SELECT Id, OwnerId, Pincdoe__c
            FROM Test_Drive__c
            WHERE OwnerId IN :agentIds
              AND Status__c = :TestDriveTriggerHandler.STATUS_DL_VERIFIED
              AND Pincdoe__c IN :agentZips
        ]) {
            // Double check: agent's zip matches record's zip
            String agentZip = agentZipMap.get(td.OwnerId);
            if (agentZip != null
                && agentZip == td.Pincdoe__c.trim()) {
                testDriveIds.add(td.Id);
            }
        }
    }
}