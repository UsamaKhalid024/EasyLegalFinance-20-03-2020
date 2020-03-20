@isTest
public class RDS_DispatcherComponentControllerTest {
    public static testMethod void dispatcherComponentTest(){
        Test.startTest();
        Account account;
        Account acc = new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', 
                                  RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId());
        
        insert acc;
        account = RDS_DispatcherComponentControllerApex.getAccount(acc.Id);
        system.assertEquals(acc.Id, account.Id);
        
        Contact con = new Contact(LastName = 'Test Client Contact', AccountId = acc.Id,
                                  RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId());
        insert con;
        
        account = RDS_DispatcherComponentControllerApex.getAccount(con.Id);
        system.assertEquals(acc.Id, account.Id);
        
        
        Opportunity opp = new Opportunity(AccountId = acc.Id,
                                          Name = 'Test Opportunity ',
                                          Lawyer__c = con.Id,
                                          CloseDate = Date.today().addDays(14),
                                          StageName = 'Closed With Loan',
                                          Stage_Status__c = 'Approved',
                                          Payout_Date__c = Date.newInstance(2018,01,01),
                                          Type_of_Loan__c = 'Facility Loan',
                                          RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId()
                                         );
        
        insert opp;
        
        account = RDS_DispatcherComponentControllerApex.getAccount(opp.Id);
        system.assertEquals(acc.Id, account.Id);
        
        Test.stopTest();
        
    }
    
}