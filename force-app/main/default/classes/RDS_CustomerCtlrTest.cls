@isTest
public with sharing class RDS_CustomerCtlrTest {
    public RDS_CustomerCtlrTest() {
        
    }
    static testMethod void CustomerTest(){
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);
        
        //String address = 'Montreal, US, QCB, 7th Memorial Drive, W5C 8YZ';
        
        Note n = new note();
        n.parentId = acc.Id;
        n.Title = 'For Testing Notes';
        n.Body = 'Body for Account notes'; 
        //n.ContentType = 'Text';
        insert n;

        Opportunity o = new Opportunity(
          
        Name = 'Test',
        AccountId = acc.Id,
        Lawyer__c = con.id,
        CloseDate = Date.today(),
        StageName = 'ENTERED',
        Amount = 120.00,
        Subsequent_Drawdowns__c = 12.00   
        );
           
        insert o;

        List<Event> lstEvent = new List<Event>();
        Event evnt = New Event();                
        evnt.WhatId = o.Id;
        evnt.StartDateTime = date.today();
        evnt.EndDateTime = date.today().AddDays(5);
        evnt.Subject = 'Subsequent Drawdown on '+date.today()+ ' for 30';
        lstEvent.add(evnt);
        insert lstEvent;

        Amendment__c am = new Amendment__c();
        am.Opportunity__c = o.id;
        am.Amount__c = 300.00;
        am.Date_Financing_Statement_Done__c = Date.today().AddDays(3);
        am.Date_Financing_Statement_Expires__c = Date.today().AddDays(20);

        insert am;

        Firm__c  f = new Firm__c();
        f.Opportunity__c = o.id;
        f.Law_Firm__c = acc.id;
        f.Lawyer__c = con.id;
        f.Date_of_Update__c =Date.today().AddDays(10);
       
        insert f;

        Contact_History__c ch = new Contact_History__c();
        ch.Address__c = 'Montreal, US, QCB, 6th Memorial Drive, W4C 8YZ';
        ch.Alternate_Phone__c = '(90) 4000 0000';
        ch.Date_of_update__c = Date.today().AddDays(2);
        ch.Email__c = 'pierce1.ray@yopmail.com';
        ch.Phone__c = '(75) 74868907';
        ch.Contact__c = con.id;

        insert ch;  

        PageReference pageRef = Page.RDS_Customer;
        Test.setCurrentPage(pageRef); 
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(acc); 
        ApexPages.currentPage().getParameters().put('Id',acc.Id);
        RDS_CustomerCtlr Le = new RDS_CustomerCtlr(sc);

        RDS_CustomerCtlr.runFirstTime = true;
        Le.saveDb();
        Le.init();
        //Le.saveSubsequent();
        Le.saveNotesDb();
        /*List<selectOption> getLoan_Option = Le.getLoanType();
        String fetchPage = Le.fetchContactDetail().getUrl();*/
        String cancel = Le.cancel().getUrl();
        System.assertEquals('/apex/RDS_Customer?id='+acc.id,cancel);
       
        String print = Le.PrintableView().getUrl();
        System.assertEquals('/apex/RDS_AccountPrintableView?Id='+acc.Id,print);


        List<selectOption> maritalStatus_options = Le.getMaritalStatuss();
        System.AssertNotEquals(0, maritalStatus_options.size());

        List<selectOption> spousalSupportPayments_options = Le.getSpousalSupportPayments();
        System.AssertNotEquals(0, spousalSupportPayments_options.size());

        List<selectOption> arrearsPayments_options = Le.getArrearsPayments();
        System.AssertNotEquals(0, arrearsPayments_options.size());


        List<selectOption> Dependants_options = Le.getDependants();
        System.AssertNotEquals(0, Dependants_options.size());

        List<selectOption> bankruptcies_options = Le.getbankruptcies();
        System.AssertNotEquals(0, bankruptcies_options.size());
        
        List<selectOption> litigations_options = Le.getLitigations();
        System.AssertNotEquals(0, litigations_options.size());
        
        List<selectOption> employment_options = Le.getEmployments();
        System.AssertNotEquals(0, employment_options.size());

        Le.Dependant = 'yes';
        Le.getMartialStatusOptions();
        Le.getSpousalChildPaymentOptions();
        Le.getArrearsPaymentOptions();
        Le.getDependentOptions();
        Le.getBankruptcyOptions();
        Le.getEmploymentOptions();
        Le.getLitigationOptions(); 

        Le.deleteLead();       

        /*List<selectOption> getSpousalChildPaymentOptions = Le.getSpousalChildPaymentOptions();
        System.AssertNotEquals(0, Any_SpousalChild_support_payment__c.size());*/
         RDS_Util rd = new RDS_Util();
    }

    /*static testMethod void CustomerTestForNullAndDelete(){
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);

        Note n = new note();
        n.parentId = acc.Id;
        n.Title = 'For Testing Notes';
        n.Body = 'Body for Account notes'; 
        //n.ContentType = 'Text';
        insert n;

        PageReference pageRef = Page.RDS_Customer;
        Test.setCurrentPage(pageRef); 
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(acc); 
        ApexPages.currentPage().getParameters().put('Id',acc.Id);
        RDS_CustomerCtlr Le = new RDS_CustomerCtlr(sc);

        //Le.saveSubsequent();
        Le.saveDb();
       
    }*/
}