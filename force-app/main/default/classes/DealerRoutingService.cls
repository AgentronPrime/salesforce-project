/**
 * @description Creates PendingServiceRouting records with
 *              SkillRequirements to route Test Drive records
 *              to Dealer Users matching the Zip Code.
 *
 * How it works: Remove this class later
 *   1. Record is in Dealer Queue
 *   2. PendingServiceRouting created with RoutingType = SkillsBased
 *   3. SkillRequirement attached: Skill = "Zip_90210"
 *   4. Omni-Channel finds online Dealer User who has "Zip_90210" skill
 *   5. Record routed to that specific Dealer User
 *
 * This ensures Zip Code matching via Omni-Channel routing.
 */
public without sharing class DealerRoutingService {

    private static final String SKILL_PREFIX = 'Zip_';

    /**
     * @description Creates PendingServiceRouting + SkillRequirement
     *              for each Test Drive record being routed to Dealer.
     * @param records Test Drive records with DL Verified status
     */
    public static void createSkillsBasedRouting(List<Test_Drive__c> records) {
        if (records == null || records.isEmpty()) {
            return;
        }

        // Step 1: Get Service Channel for Test_Drive__c
        Id serviceChannelId = getServiceChannelId();
        if (serviceChannelId == null) {
            System.debug(LoggingLevel.ERROR,
                '[DealerRoutingService] Service Channel not found');
            return;
        }

        // Step 2: Collect zip codes and build skill developer names
        Set<String> skillDevNames = new Set<String>();
        Map<Id, String> recordIdToSkillName = new Map<Id, String>();

        for (Test_Drive__c td : records) {
            String zip = td.Pincdoe__c.trim();
            String skillName = SKILL_PREFIX + zip;
            skillDevNames.add(skillName);
            recordIdToSkillName.put(td.Id, skillName);
        }

        // Step 3: Query matching Skills (bulk)
        Map<String, Id> skillNameToId = new Map<String, Id>();
        for (Skill s : [
            SELECT Id, DeveloperName
            FROM Skill
            WHERE DeveloperName IN :skillDevNames
        ]) {
            skillNameToId.put(s.DeveloperName, s.Id);
        }

        if (skillNameToId.isEmpty()) {
            System.debug(LoggingLevel.WARN,
                '[DealerRoutingService] No matching skills found for: '
                + skillDevNames);
            return;
        }

        // Step 4: Delete any existing PSR for these work items
        //         (prevents duplicate routing)
        cleanupExistingPSR(recordIdToSkillName.keySet());

        // Step 5: Create PendingServiceRouting records
        //         IsReadyForRouting = false (will set true after skills attached)
        List<PendingServiceRouting> psrList = new List<PendingServiceRouting>();
        Map<Id, PendingServiceRouting> workItemToPSR =
            new Map<Id, PendingServiceRouting>();

        for (Test_Drive__c td : records) {
            String skillName = recordIdToSkillName.get(td.Id);

            // Only create PSR if matching skill exists
            if (skillNameToId.containsKey(skillName)) {
                PendingServiceRouting psr = new PendingServiceRouting(
                    CapacityWeight    = 1,
                    IsReadyForRouting = false,
                    RoutingModel      = 'MostAvailable',
                    RoutingPriority   = 1,
                    RoutingType       = 'SkillsBased',
                    ServiceChannelId  = serviceChannelId,
                    WorkItemId        = td.Id,
                    PushTimeout       = 0
                );
                psrList.add(psr);
                workItemToPSR.put(td.Id, psr);
            }
        }

        if (psrList.isEmpty()) {
            return;
        }

        insert psrList;

        // Step 6: Create SkillRequirements linking PSR → Skill
        List<SkillRequirement> skillReqs = new List<SkillRequirement>();

        for (Test_Drive__c td : records) {
            PendingServiceRouting psr = workItemToPSR.get(td.Id);
            String skillName = recordIdToSkillName.get(td.Id);

            if (psr != null && psr.Id != null
                && skillNameToId.containsKey(skillName)) {

                skillReqs.add(new SkillRequirement(
                    RelatedRecordId = psr.Id,
                    SkillId         = skillNameToId.get(skillName),
                    SkillLevel      = 1
                ));
            }
        }

        if (!skillReqs.isEmpty()) {
            insert skillReqs;
        }

        // Step 7: Mark PSRs as ready for routing
        for (PendingServiceRouting psr : psrList) {
            psr.IsReadyForRouting = true;
        }
        update psrList;
    }

    // ────────────────────────────────────────────────────────────
    // CLEANUP EXISTING PSR
    // ────────────────────────────────────────────────────────────

    private static void cleanupExistingPSR(Set<Id> workItemIds) {
        List<PendingServiceRouting> existing = [
            SELECT Id
            FROM PendingServiceRouting
            WHERE WorkItemId IN :workItemIds
        ];
        if (!existing.isEmpty()) {
            delete existing;
        }
    }

    // ────────────────────────────────────────────────────────────
    // SERVICE CHANNEL CACHE
    // ────────────────────────────────────────────────────────────

    private static Id cachedChannelId;
    private static Id getServiceChannelId() {
        if (cachedChannelId == null) {
            List<ServiceChannel> channels = [
                SELECT Id
                FROM ServiceChannel
                WHERE RelatedEntity = 'Test_Drive__c'
                LIMIT 1
            ];
            cachedChannelId = channels.isEmpty() ? null : channels[0].Id;
        }
        return cachedChannelId;
    }
}