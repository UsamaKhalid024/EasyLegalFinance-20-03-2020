@isTest
public with sharing class leadHelperTest {

    static testMethod void TestleadHelper() {
        
        Lead ld = new Lead();
        ld.FirstName = 'John';  
        ld.MiddleName = 'Daniel';
        ld.LastName = 'Brown';
        ld.Company = 'JDB Pvt ltd';
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
    }

}