/**
 * @description One-time batch to create ServiceResource
 *              and ServiceResourceSkill for existing dealers.
 *
 * Pre-requisite: Skills must already exist.
 *   Run Flow or create Skills manually first,
 *   OR run DealerSkillCreationBatch first.
 *
 * Usage:
 *   Database.executeBatch(new DealerSkillSetupBatch(), 50);
 */
public without sharing class DealerSkillSetupBatch
    implements Database.Batchable<SObject> {

    private static final String SKILL_PREFIX = 'Zip_';

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Dealer_Zip__c
            FROM User
            WHERE Dealer_Zip__c != NULL
              AND IsActive = TRUE
        ]);
    }

    public void execute(Database.BatchableContext bc, List<User> scope) {
        Map<Id, String> userZipMap = new Map<Id, String>();
        Set<String> skillNames = new Set<String>();

        for (User u : scope) {
            String zip = u.Dealer_Zip__c.trim();
            userZipMap.put(u.Id, zip);
            skillNames.add(SKILL_PREFIX + zip);
        }

        // Get existing Skills
        Map<String, Id> skillMap = new Map<String, Id>();
        for (Skill s : [
            SELECT Id, DeveloperName
            FROM Skill
            WHERE DeveloperName IN :skillNames
        ]) {
            skillMap.put(s.DeveloperName, s.Id);
        }

        // Get existing ServiceResources
        Map<Id, Id> userToSRId = new Map<Id, Id>();
        for (ServiceResource sr : [
            SELECT Id, RelatedRecordId
            FROM ServiceResource
            WHERE RelatedRecordId IN :userZipMap.keySet()
        ]) {
            userToSRId.put(sr.RelatedRecordId, sr.Id);
        }

        // Create missing ServiceResources
        List<ServiceResource> newSRs = new List<ServiceResource>();
        for (User u : scope) {
            if (!userToSRId.containsKey(u.Id)) {
                newSRs.add(new ServiceResource(
                    Name            = u.Name,
                    RelatedRecordId = u.Id,
                    ResourceType    = 'A',
                    IsActive        = true
                ));
            }
        }

        if (!newSRs.isEmpty()) {
            Database.insert(newSRs, false);
            for (ServiceResource sr : [
                SELECT Id, RelatedRecordId
                FROM ServiceResource
                WHERE RelatedRecordId IN :userZipMap.keySet()
            ]) {
                userToSRId.put(sr.RelatedRecordId, sr.Id);
            }
        }

        // Check existing assignments
        Set<String> existingKeys = new Set<String>();
        for (ServiceResourceSkill srs : [
            SELECT ServiceResourceId, SkillId
            FROM ServiceResourceSkill
            WHERE ServiceResourceId IN :userToSRId.values()
        ]) {
            existingKeys.add(srs.ServiceResourceId + '_' + srs.SkillId);
        }

        // Create missing assignments
        List<ServiceResourceSkill> newSRS1 = new List<ServiceResourceSkill>();
        for (Id userId : userZipMap.keySet()) {
            String skillName = SKILL_PREFIX + userZipMap.get(userId);
            Id srId = userToSRId.get(userId);
            Id skillId = skillMap.get(skillName);

            if (srId == null || skillId == null) {
                continue;
            }

            String key = srId + '_' + skillId;
            if (!existingKeys.contains(key)) {
                newSRS1.add(new ServiceResourceSkill(
                    ServiceResourceId  = srId,
                    SkillId            = skillId,
                    SkillLevel         = 10,
                    EffectiveStartDate = System.now()
                ));
            }
        }

        if (!newSRS1.isEmpty()) {
            Database.insert(newSRS1, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('[DealerSkillSetupBatch] Complete');
    }
}