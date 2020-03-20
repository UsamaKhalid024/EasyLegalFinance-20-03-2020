/**
*    @description : Method to fetch bank accounts
**/
public with sharing class BankAccountsController {
	
	/**
	* @description Method to fetch bank accounts
	* @param accountId Id of the account record
	* @return Map<String, Object> list of bank accounts
	**/
	@AuraEnabled
	public static Map<String, Object> getBankAccounts(Id accountId, String fieldSetName){
		Map<String,Object> objectsMap = new Map<String,Object>();
		List<String> fieldsList = SchemaHelper.getFieldsFromFieldsSet(Bank_Account__c.sObjectType.getDescribe().getName(),fieldSetName);
		// add datatable fields
		objectsMap.put('columns',SchemaHelper.getDataTableFields(Bank_Account__c.sObjectType.getDescribe().getName(),fieldsList));
		// add records
		String soqlQuery = 'SELECT Id, '+String.join(fieldsList,',')+' FROM '+Bank_Account__c.sObjectType.getDescribe().getName()+' WHERE '+Bank_Account__c.Client__c.getDescribe().getName()+' = \''+accountId+'\' ORDER BY '+Bank_Account__c.CreatedDate.getDescribe().getName()+' DESC LIMIT 15000';
		objectsMap.put('records',(List<Bank_Account__c>)Database.query(soqlQuery));
		return objectsMap;
	}
	
	/**
	* @description Method to delete bank account
	* @param bankAccountId Id of the bank account record
	* @return
	**/
	@AuraEnabled
	public static void removeBankAccount(Id bankAccountId){
		Bank_Account__c ba = [Select Id From Bank_Account__c Where Id = :bankAccountId];
		delete ba;
	}

    Class BankAccountAggregateResult {
        @AuraEnabled public Integer sentCount;
        @AuraEnabled public Decimal sentAmount;
        @AuraEnabled public Integer scheduledCount;
        @AuraEnabled public Decimal scheduledAmount;
        @AuraEnabled public String name;
        @AuraEnabled public Id bankAccountId;
        @AuraEnabled public Bank_Account__c bankAccount;
        @AuraEnabled public String accountName;
        @AuraEnabled public Id accountId;

        public BankAccountAggregateResult() {
            this.sentCount = 0;
            this.sentAmount = 0;
            this.scheduledCount = 0;
            this.scheduledAmount = 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static Object getUsedBankAccounts(Id accountId){
        /*
        Aggregate query
        Group by Bank Account
        Bank Account Info
        Sent Total
        Scheduled Total
        */
        Scheduled_Payment__c[] spList = [
            SELECT
                //COUNT(Id) paymentCount,
                Id,
                Send_Cheque__c,
                Sent__c,
                Current_Account_Id__c,
                Current_Account_Name__c,
                Current_Bank_Account_Id__c,
                Current_Bank_Account_Name__c,
                Amount__c
                //SUM(Amount__c) totalAmount
            FROM Scheduled_Payment__c
            WHERE Opportunity__r.AccountId = :accountId
            // GROUP BY
            //    Sent__c, Send_Cheque__c,
            //    Current_Account_Id__c, Current_Account_Name__c,
            //    Current_Bank_Account_Id__c, Current_Bank_Account_Name__c
            ORDER BY Current_Bank_Account_Name__c ASC
        ];

        // Get Bank Account Ids to fetch and aggregate payment numbers
        Map<String, BankAccountAggregateResult> results = new Map<String, BankAccountAggregateResult>();
        BankAccountAggregateResult currResult;
        Set<Id> bankAccountIds = new Set<Id>();

        for (Scheduled_Payment__c sp : spList) {
            if (results.containsKey(sp.Current_Bank_Account_Name__c)) {
                currResult = results.get(sp.Current_Bank_Account_Name__c);
            } else {
                currResult = new BankAccountAggregateResult();
                currResult.accountId = (Id)sp.Current_Account_Id__c;
                currResult.accountName = (String)sp.Current_Account_Name__c;
                currResult.name = (String)sp.Current_Bank_Account_Name__c;
                if (sp.Send_Cheque__c == false) {
                    currResult.bankAccountId = (Id)sp.Current_Bank_Account_Id__c;
                    bankAccountIds.add((Id)sp.get('Current_Bank_Account_Id__c'));
                }
                results.put(sp.Current_Bank_Account_Name__c, currResult);
            }
            if (sp.Sent__c == false) {
                currResult.scheduledCount += 1;
                currResult.scheduledAmount += sp.Amount__c;
            } else {
                currResult.sentCount += 1;
                currResult.sentAmount += sp.Amount__c;
            }
        }

        // Get Bank Accounts
        Map<Id, Bank_Account__c> bankAccountMap = new Map<Id, Bank_Account__c>([
            SELECT
                Id,
                Name,
                Account__c,
                Bank__c,
                Bank_Name__c,
                Transit__c
            FROM Bank_Account__c
            WHERE Id in :bankAccountIds
        ]);

        // attach bank accounts to aggregates
        for (BankAccountAggregateResult result : results.values()) {
            if (result.bankAccountId != null) {
                if (bankAccountMap.containsKey(result.bankAccountId)) {
                    result.bankAccount = bankAccountMap.get(result.bankAccountId);
                }
            }
        }

        return results.values();
    }
}