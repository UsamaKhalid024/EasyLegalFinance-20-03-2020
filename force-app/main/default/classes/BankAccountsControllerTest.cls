/**
*    @description : Test class for BankAccountsController
**/
@isTest(seeAllData=false)
private with sharing class BankAccountsControllerTest {
	
    /**
	*    @description : Test get bank accounts list
	**/
	@isTest
    static void test_getBankAccounts(){
        Account[] accRecs = TestDataFactory.getAccountObjects(1);

        Bank_Account__c[] bankRecs = TestDataFactory.getBankAccountObjects(1);

    	Test.startTest();
    	// get account 
   		Map<String, Object> objectsMap = BankAccountsController.getBankAccounts(accRecs[0].Id, 'BankAccounts');
   		List<Object> recordsList = (List<Object>)objectsMap.get('records');
   		System.assertEquals(1,recordsList.size());
    	Test.stopTest();
    }

    public static testMethod void testGetUsedBankAccounts(){
        Account[] accRecs = TestDataFactory.getAccountObjects(2);

        FObject baConfig = TestDataFactory.getBankAccountConfig(2);
        Bank_Account__c[] bankRecs = TestDataFactory.getBankAccountObjects(baConfig, false);
        // Ensure we're using different accounts
        bankRecs[0].Client__c = accRecs[0].Id;
        bankRecs[1].Client__c = accRecs[1].Id;
        TestDataFactory.getBankAccountObjects(baConfig, true);

        FObject oppConfig = TestDataFactory.getOpportunityConfig(1);
        Opportunity[] oppRecs = TestDataFactory.getOpportunityObjects(oppConfig, false);
        oppRecs[0].AccountId = accRecs[0].Id;
        oppRecs = TestDataFactory.getOpportunityObjects(oppConfig, true);

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(2);
        spConfig.setDefinition('Amount__c', 'static value(1000)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        Scheduled_Payment__c[] spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, false);
        spRecs[0].Account__c = accRecs[1].Id;
        spRecs[0].Sent_to_Bank_Date__c = Datetime.now();
        spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, true);

        Object results = BankAccountsController.getUsedBankAccounts(accRecs[0].Id);
    }

    public static testMethod void testRemoveBankAccount(){
        Bank_Account__c[] bankRecs = TestDataFactory.getBankAccountObjects(1);
        BankAccountsController.removeBankAccount(bankRecs[0].Id);
    }
}