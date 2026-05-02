/**
 * @description Invocable Apex called by Flow after
 *              Skill is created/verified.
 *
 * Creates:
 *   - ServiceResource for User (if not exists)
 *   - ServiceResourceSkill linking User → Zip Skill
 *
 * Removes:
 *   - Old ServiceResourceSkill (if zip changed)
 *
 * Called from: User Record-Triggered Flow
 */
public without sharing class DealerSkillSetupInvocable {

    private static final String SKILL_PREFIX = 'Zip_';

    public class FlowInput {
        @InvocableVariable(required=true label='User Id')
        public Id userId;

        @InvocableVariable(required=true label='New Zip Code')
        public String newZip;

        @InvocableVariable(label='Old Zip Code')
        public String oldZip;
    }

    /**
     * @description Main entry point called by Flow.
     *              Handles bulkified list of inputs.
     */
    @InvocableMethod(
        label='Setup Dealer Skill Assignment'
        description='Creates ServiceResource and ServiceResourceSkill for Dealer User'
    )
    public static void setupDealerSkills(List<FlowInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            return;
        }

        // Collect all data
        Map<Id, String> userNewZipMap = new Map<Id, String>();
        Map<Id, String> userOldZipMap = new Map<Id, String>();
        Set<String> allSkillNames = new Set<String>();

        for (FlowInput input : inputs) {
            if (String.isNotBlank(input.newZip)) {
                String zip = input.newZip.trim();
                userNewZipMap.put(input.userId, zip);
                allSkillNames.add(SKILL_PREFIX + zip);
            }

            if (String.isNotBlank(input.oldZip)) {
                String zip = input.oldZip.trim();
                userOldZipMap.put(input.userId, zip);
                allSkillNames.add(SKILL_PREFIX + zip);
            }
        }

        // Query all needed Skills
        Map<String, Id> skillMap = new Map<String, Id>();
        for (Skill s : [
            SELECT Id, DeveloperName
            FROM Skill
            WHERE DeveloperName IN :allSkillNames
        ]) {
            skillMap.put(s.DeveloperName, s.Id);
        }

        // Get all user Ids
        Set<Id> allUserIds = new Set<Id>();
        allUserIds.addAll(userNewZipMap.keySet());
        allUserIds.addAll(userOldZipMap.keySet());

        // ── Step 1: Ensure ServiceResources exist ──
        Map<Id, Id> userToSRId = new Map<Id, Id>();
        for (ServiceResource sr : [
            SELECT Id, RelatedRecordId, IsActive
            FROM ServiceResource
            WHERE RelatedRecordId IN :allUserIds
        ]) {
            userToSRId.put(sr.RelatedRecordId, sr.Id);
        }

        // Create missing ServiceResources
        Set<Id> usersNeedingSR = new Set<Id>(userNewZipMap.keySet());
        usersNeedingSR.removeAll(userToSRId.keySet());

        if (!usersNeedingSR.isEmpty()) {
            Map<Id, String> userNames = new Map<Id, String>();
            for (User u : [
                SELECT Id, Name
                FROM User
                WHERE Id IN :usersNeedingSR
            ]) {
                userNames.put(u.Id, u.Name);
            }

            List<ServiceResource> newSRs = new List<ServiceResource>();
            for (Id userId : usersNeedingSR) {
                newSRs.add(new ServiceResource(
                    Name            = userNames.get(userId),
                    RelatedRecordId = userId,
                    ResourceType    = 'A',
                    IsActive        = true
                ));
            }

            List<Database.SaveResult> srResults =
                Database.insert(newSRs, false);

            for (Integer i = 0; i < srResults.size(); i++) {
                if (srResults[i].isSuccess()) {
                    userToSRId.put(
                        newSRs[i].RelatedRecordId,
                        newSRs[i].Id
                    );
                } else {
                    System.debug(LoggingLevel.ERROR,
                        '[DealerSkillSetup] SR create failed: '
                        + srResults[i].getErrors()[0].getMessage());
                }
            }
        }

        // Reactivate inactive ServiceResources
        List<ServiceResource> inactiveSRs = [
            SELECT Id
            FROM ServiceResource
            WHERE RelatedRecordId IN :userNewZipMap.keySet()
              AND IsActive = false
        ];
        if (!inactiveSRs.isEmpty()) {
            for (ServiceResource sr : inactiveSRs) {
                sr.IsActive = true;
            }
            Database.update(inactiveSRs, false);
        }

        // ── Step 2: Remove old ServiceResourceSkill ──
        if (!userOldZipMap.isEmpty()) {
            removeOldAssignments(userOldZipMap, userToSRId, skillMap);
        }

        // ── Step 3: Create new ServiceResourceSkill ──
        if (!userNewZipMap.isEmpty()) {
            createNewAssignments(userNewZipMap, userToSRId, skillMap);
        }
    }

    private static void removeOldAssignments(
        Map<Id, String> userOldZipMap,
        Map<Id, Id> userToSRId,
        Map<String, Id> skillMap
    ) {
        Set<Id> srIds = new Set<Id>();
        Set<Id> oldSkillIds = new Set<Id>();

        for (Id userId : userOldZipMap.keySet()) {
            Id srId = userToSRId.get(userId);
            String skillName = SKILL_PREFIX + userOldZipMap.get(userId);
            Id skillId = skillMap.get(skillName);

            if (srId != null) srIds.add(srId);
            if (skillId != null) oldSkillIds.add(skillId);
        }

        if (srIds.isEmpty() || oldSkillIds.isEmpty()) {
            return;
        }

        List<ServiceResourceSkill> toDelete = [
            SELECT Id
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :srIds
              AND SkillId IN :oldSkillIds
        ];

        if (!toDelete.isEmpty()) {
            Database.delete(toDelete, false);
            System.debug('[DealerSkillSetup] Removed '
                + toDelete.size() + ' old assignments');
        }
    }

    private static void createNewAssignments(
        Map<Id, String> userNewZipMap,
        Map<Id, Id> userToSRId,
        Map<String, Id> skillMap
    ) {
        // Check existing to avoid duplicates
        Set<Id> srIds = new Set<Id>(userToSRId.values());
        Set<String> existingKeys = new Set<String>();

        for (ServiceResourceSkill srs : [
            SELECT ServiceResourceId, SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :srIds
        ]) {
            existingKeys.add(
                srs.ServiceResourceId + '_' + srs.SkillId
            );
        }

        List<ServiceResourceSkill> newAssignments =
            new List<ServiceResourceSkill>();

        for (Id userId : userNewZipMap.keySet()) {
            String zip = userNewZipMap.get(userId);
            String skillName = SKILL_PREFIX + zip;
            Id srId = userToSRId.get(userId);
            Id skillId = skillMap.get(skillName);

            if (srId == null) {
                System.debug(LoggingLevel.WARN,
                    '[DealerSkillSetup] No SR for user: ' + userId);
                continue;
            }

            if (skillId == null) {
                System.debug(LoggingLevel.WARN,
                    '[DealerSkillSetup] No Skill for: ' + skillName
                    + ' — Flow may not have created it yet');
                continue;
            }

            String key = srId + '_' + skillId;
            if (existingKeys.contains(key)) {
                System.debug('[DealerSkillSetup] Already exists: ' + key);
                continue;
            }

            newAssignments.add(new ServiceResourceSkill(
                ServiceResourceId  = srId,
                SkillId            = skillId,
                SkillLevel         = 10,
                EffectiveStartDate = System.now()
            ));
        }

        if (!newAssignments.isEmpty()) {
            List<Database.SaveResult> results =
                Database.insert(newAssignments, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    System.debug('[DealerSkillSetup] Created: '
                        + newAssignments[i].ServiceResourceId
                        + ' → Skill');
                } else {
                    System.debug(LoggingLevel.ERROR,
                        '[DealerSkillSetup] Failed: '
                        + results[i].getErrors()[0].getMessage());
                }
            }
        }
    }
}