@isTest
public with sharing class FirmHandlerTest {

	static testMethod void FirmHandlerTestMethod() {

		Account account = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(account.Id);

        RDS_CustomerCtlr.runFirstTime = true;

        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        
        Account serviceAcc = new Account();
        serviceAcc.Name='Sparrow';
        serviceAcc.BillingStreet = 'Testtest';
        serviceAcc.BillingState = 'AK';
        serviceAcc.BillingCity = 'City';
        serviceAcc.BillingPostalCode = '10001';
        serviceAcc.Billingcountry='Canada';
        serviceAcc.ShippingStreet = 'Test';
        serviceAcc.ShippingState = 'New York';
        serviceAcc.ShippingCountry = 'UNITED STATES';
        serviceAcc.ShippingPostalCode = '10001';
        serviceAcc.ShippingCity = 'Lake Trees';
        serviceAcc.Account_Type__c = 'Treatment Provider Firm';
        serviceAcc.RecordTypeId = RecordTypeIdAccount;
        insert serviceAcc;

        Contact cont = new Contact(
        AccountId = serviceAcc.Id,
        LastName = 'Testtest1',
        FirstName = 'Testtest1',
        Phone = '(91) 5019 0000111',
        Email = 'test@testtest.com',
        MailingStreet = '123 Testtest1.',
        MailingCity = 'Testtest1',
        MailingState = 'AK',
        MailingCountry = 'UNITED STATES',
        MailingPostalCode = '10001'
        );
        insert cont;

		Opportunity opp = new Opportunity(
      	Name = 'Test1',
        AccountId = account.Id,
        CloseDate = Date.today(),
        StageName = 'Loan Approval',
        Lawyer__c = con.Id,
        Law_Firm__c = account.id,
        Date_Financing_Statement_Done__c = Date.today(),
        Date_Financing_Statement_Expires__c = Date.today().addDays(1),
        Amount = 2000
        );
        insert opp;
		/*
        Opportunity opprt = new Opportunity();
        opprt.Name = 'Test2';
        opprt.AccountId = serviceAcc.Id;
        opprt.CloseDate = Date.today();
        opprt.StageName = 'Intake';
        opprt.Lawyer__c = cont.Id;
        opprt.Law_Firm__c = serviceAcc.Id;
        opprt.Date_Financing_Statement_Done__c = Date.today().addDays(1);
        opprt.Date_Financing_Statement_Expires__c = Date.today().addDays(2);
        opprt.Amount = 5000;
        insert opprt;

        Opportunity oppr = new Opportunity();
        oppr.id = opp.id;
        oppr.Law_Firm__c = serviceAcc.Id;
        oppr.StageName = 'Prospecting';
        update oppr;
		*/
        opp.Law_Firm__c = serviceAcc.id;
        
        update opp;
    }
}