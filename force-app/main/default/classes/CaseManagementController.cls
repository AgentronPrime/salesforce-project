public without sharing class CaseManagementController {

    @InvocableMethod(
        label='Case Status'
        description='Return Case Status, when user ask for it, for example user can say what is the status of the case 100'
    )
    public static List<String> getStatus(List<String> caseNumber) {

        List<Case> cases = [
            SELECT Id, Status
            FROM Case
            WHERE CaseNumber = :caseNumber[0]
            LIMIT 1
        ];

        if (cases.size() > 0) {
            return new List<String>{ cases[0].Status };
        } else {
            return new List<String>{ 'Case Number is not valid' };
        }
    }
}