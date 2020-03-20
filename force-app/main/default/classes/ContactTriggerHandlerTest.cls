@isTest
public with sharing class ContactTriggerHandlerTest {
	public ContactTriggerHandlerTest() {
		
	}
	static testMethod void contactHistoryUpdateTest(){
        Account account = ELUtilTest.createAccount();
        Contact res = ELUtilTest.createContact(account.Id);
        
        Contact res1 = new Contact();
            res1.id = res.id;
            res1.Email = 'test@test1.com';
        update res1;
        /*List<Contact_History__c> chLst = [select id, name from Contact_History__c where contactId = res.Id];
        system.debug('@@@'+chLst.size());*/
        
        Contact res2 = new Contact();
            res2.id = res1.id;
            res1.MailingStreet = '123 Test1';
            res1.MailingCity = 'Test1';
        update res2;
        List<Contact_History__c> chLst1 = [select id, name from Contact_History__c];
        system.debug('@@@'+chLst1.size());
    }
}