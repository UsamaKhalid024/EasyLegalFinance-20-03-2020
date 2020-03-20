@isTest
public class RDS_OpportunityCtlrTest {
    
    static testMethod void OpportunityTest() {
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);
        
        Opportunity o = new Opportunity(
          
        Name = 'Test',
        AccountId = acc.Id,
        Lawyer__c = con.id,
        CloseDate = Date.today(),
        StageName = 'ENTERED',
        Amount = 120.00,
        Subsequent_Drawdowns__c = 13.00   
        );
        insert o;
       
        /* Drawdown__c Dr = new Drawdown__c();
        Dr.Date__c = date.today();
        Dr.Amount__c = 120;
        Dr.Opportunity__c = o.Id;
        insert Dr; */

        /* List<Event> lstEvent = new List<Event>();
        Event evnt = New Event();                
        evnt.WhatId = o.Id;
        evnt.StartDateTime = date.today();
        evnt.EndDateTime = date.today().AddDays(5);
        evnt.Subject = 'Subsequent Drawdown on '+date.today()+ ' for 30';
        lstEvent.add(evnt);
        insert lstEvent; */



        PageReference pageRef = Page.RDS_Opportunity;
        Test.setCurrentPage(pageRef); 
        System.assertNotEquals(null,pageRef);
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(o); 
        ApexPages.currentPage().getParameters().put('accId',acc.Id);
        ApexPages.currentPage().getParameters().put('oppId',o.Id);

        RDS_OpportunityCtlr RDS_Opp = new RDS_OpportunityCtlr(sc);

        List<selectOption> bankruptcies_options = RDS_Opp.getbankruptcies();
        System.AssertNotEquals(0, bankruptcies_options.size());

        RDS_Opp.currentOppSObj = o;
        RDS_Opp.initOpp(o.Id);
        RDS_Opp.getOpp();
        RDS_Opp.saveCurrOpp();
        //RDS_Opp.saveSubsequent();
        
        //System.assertEquals(13,RDS_Opp.saveSubsequent().ddnCount);
        //System.assertEquals(13,RDS_Opp.lstsubscDropdown.size());

    }
    static testMethod void OpportunityForDdCountEqualTest() {
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);
        
        Opportunity o = new Opportunity(
        Name = 'TestOpp',
        AccountId = acc.Id,
        Lawyer__c = con.id,
        CloseDate = Date.today(),
        StageName = 'ENTERED',
        Amount = 120.00,
        Subsequent_Drawdowns__c = 1.00   
        );
        insert o;

        PageReference pageRef = Page.RDS_Opportunity;
        Test.setCurrentPage(pageRef); 
        System.assertNotEquals(null,pageRef);

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(o); 
        ApexPages.currentPage().getParameters().put('accId',acc.Id);
        ApexPages.currentPage().getParameters().put('oppId',o.Id);

        RDS_OpportunityCtlr RDS_Opp = new RDS_OpportunityCtlr(sc);
        RDS_Opp.deleteOpportunity();

        //System.assertEquals(0,RDS_Opp.lstsubscDropdown.size());
    }
    static testMethod void OpportunityfornullTest() {
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);
        
        Opportunity o = new Opportunity(
        Name = '+',
        AccountId = acc.Id,
        Lawyer__c = con.id,
        CloseDate = Date.today(),
        StageName = 'ENTERED',
        Amount = 120.00,
        Subsequent_Drawdowns__c = 12.00   
        );
        insert o;
        
        PageReference pageRef = Page.RDS_Opportunity;
        Test.setCurrentPage(pageRef);
        System.assertNotEquals(null,pageRef);

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(o); 
      
        RDS_OpportunityCtlr RDS_Opp = new RDS_OpportunityCtlr(sc);
        //RDS_Opp.saveSubsequent();
    }
}