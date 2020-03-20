@isTest
public with sharing class AmendmentTriggerHandlerTest {
    public AmendmentTriggerHandlerTest() {
        
    }
    static testMethod void AmendmentUpdateTest(){
        Account account = ELUtilTest.createAccount();
       
        Opportunity opp = new Opportunity(
            Name = 'Test',
            AccountId = account.Id,
            CloseDate = Date.today(),
            StageName = 'ENTERED',
            Date_Financing_Statement_Done__c = Date.today().AddDays(2),
            Date_Financing_Statement_Expires__c =Date.today().AddDays(20),
            Renewal_Date__c = Date.today().AddDays(5),
            Amount =200
        );

        insert opp;

        Opportunity oppr = new Opportunity();
            oppr.id = opp.id;
            oppr.Date_Financing_Statement_Done__c = Date.today().AddDays(10);
            oppr.Date_Financing_Statement_Done__c = Date.today().AddDays(50);
            oppr.Renewal_Date__c = Date.today().AddDays(50);

        update oppr;

        Opportunity oppr1 = new Opportunity();
            oppr1.id = opp.id;
            oppr1.Amount = 300;

        update oppr1;
    }
}