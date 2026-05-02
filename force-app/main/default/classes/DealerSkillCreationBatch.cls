/**
 * @description Creates Skill records for all unique
 *              Dealer_Zip__c values.
 *
 * Skill is a setup object — can only be created in
 * a setup-only context. Batch jobs CAN create setup objects
 * if no non-setup DML is in the same execute method.
 *
 * Run BEFORE DealerSkillSetupBatch:
 *   Database.executeBatch(new DealerSkillCreationBatch(), 200);
 *   // Then after completion:
 *   Database.executeBatch(new DealerSkillSetupBatch(), 50);
 */
public without sharing class DealerSkillCreationBatch
    implements Database.Batchable<AggregateResult> {

    private static final String SKILL_PREFIX = 'Zip_';

    public Iterable<AggregateResult> start(Database.BatchableContext bc) {
        return [
            SELECT Dealer_Zip__c zip
            FROM User
            WHERE Dealer_Zip__c != NULL
              AND IsActive = TRUE
            GROUP BY Dealer_Zip__c
        ];
    }

    public void execute(
        Database.BatchableContext bc,
        List<AggregateResult> scope
    ) {
        Set<String> skillNames = new Set<String>();
        Map<String, String> skillToLabel = new Map<String, String>();

        for (AggregateResult ar : scope) {
            String zip = ((String) ar.get('zip')).trim();
            String skillName = SKILL_PREFIX + zip;
            skillNames.add(skillName);
            skillToLabel.put(skillName, 'Zip ' + zip);
        }

        // Check existing
        Set<String> existing = new Set<String>();
        for (Skill s : [
            SELECT DeveloperName
            FROM Skill
            WHERE DeveloperName IN :skillNames
        ]) {
            existing.add(s.DeveloperName);
        }

        // Create missing — ONLY setup DML in this method
        List<Skill> newSkills = new List<Skill>();
        for (String skillName : skillNames) {
            if (!existing.contains(skillName)) {
                newSkills.add(new Skill(
                    MasterLabel   = skillToLabel.get(skillName),
                    DeveloperName = skillName
                ));
            }
        }

        if (!newSkills.isEmpty()) {
           // Database.insert(newSkills, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('[DealerSkillCreationBatch] Complete');
        // Chain: Now run ServiceResource setup
        Database.executeBatch(new DealerSkillSetupBatch(), 50);
    }
}