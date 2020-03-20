@isTest
public with sharing class LeadTriggerHandlerTest {    
    
    static testMethod void leadTriggerHandlerTest() {
        Test.startTest();
        Lead ld = new Lead();
        ld.FirstName = 'Test';  
        ld.MiddleName = '';
        ld.LastName = 'Lead';
        ld.Company = 'ABC Pvt ltd';
        ld.DOB__c = date.today();
        ld.Phone = '456789123';
        ld.Loan_Amount__c = 200000;
        ld.Funding_Requested__c = 200000;
        ld.Account_Type__c = 'Client';
        insert ld;

        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(ld.id);

        LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        Test.stopTest();
    }

}