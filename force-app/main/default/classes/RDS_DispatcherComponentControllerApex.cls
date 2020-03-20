public class RDS_DispatcherComponentControllerApex {
	@auraEnabled
    public static Account getAccount(String recordId)
    {
        List<Account> accounts = new List<Account>();
        if(recordId.startsWith('006'))
        {
            accounts = [Select id, RecordType.Name, Account_Type__c from Account where Id in 
                        (Select AccountId from Opportunity where Id=:recordId)];
        }
        if(recordId.startsWith('003'))
        {
            accounts = [Select id, RecordType.Name, Account_Type__c from Account where Id in 
                        (Select AccountId from Contact where Id=:recordId)];
        }
        if(recordId.startsWith('001'))
        {
            accounts = [Select id, RecordType.Name, Account_Type__c from Account where Id=:recordId];
        }
        return accounts.isEmpty() ? null : accounts[0];
    }
}