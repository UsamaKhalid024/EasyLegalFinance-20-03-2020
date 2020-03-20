global class Batch_UpdateSelectedForAssessmentPayout implements Database.Batchable<Account>, Database.stateful {
    private Set<Id> accIds;
    private Boolean selected;
    global Batch_UpdateSelectedForAssessmentPayout(Set<Id> accountIds, Boolean areSelected)
    {
        accIds = accountIds;
        selected = areSelected;
    }
	global Iterable<Account> start(Database.BatchableContext BC)
    {
        String strQuery = 'SELECT Id, Selected_for_Assessment_Payout__c';
        strQuery += ' FROM Account WHERE';
        strQuery += !accIds.isEmpty()? selected? ' Id IN :accIds' : ' Id NOT IN :accIds' : '';
        strQuery += !accIds.isEmpty()? ' AND' : '';
        strQuery += ' Selected_for_Assessment_Payout__c != :selected';
        
        return (List<Account>)Database.query(strQuery);
    }
    
    global void execute(Database.BatchableContext BC,List<Account> accounts)
    {
        for(Account acc : accounts){
            acc.Selected_for_Assessment_Payout__c = selected;
        }
        if(!accounts.isEmpty())
                update accounts;
    }
    
    global void finish(Database.BatchableContext BC)
    {
    }
}