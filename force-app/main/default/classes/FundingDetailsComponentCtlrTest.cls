/**
 * @File Name          : FundingDetailsComponentCtlrTest.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/10/2019, 7:36:16 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/9/2019, 2:53:07 PM   Seth Boyd     Initial Version
**/
@isTest
public class FundingDetailsComponentCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){        
        FObject.seed = 1234;

        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];
        u.EFT_Originator_Id__c = 'TWELF10201';
        update u;
        /*
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm',
                                    RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId()));
        
        insert accountList;       
        
        contactList.add( new Contact(LastName = 'Test Client Contact', AccountId = accountList[0].Id,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId()));
        contactList.add( new Contact(LastName = 'Test Lawyer Contact', AccountId = accountList[1].Id,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId()));
        insert contactList;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.File_Sent_For_EFT_Date__c = Date.today();
        Opp.StageName = 'Loan Approved';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'File Sent for EFT';
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        insert Opp;
        
        Opportunity OppoRe = new Opportunity(Name = 'Test Opportunity 2', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                             AccountId = accountList[0].Id);
        OppoRe.Lawyer__c = contactList[1].Id;
        OppoRe.CloseDate = Date.today().addDays(14);
        OppoRe.File_Sent_For_EFT_Date__c = Date.today().addDays(14);
        OppoRe.StageName = 'Loan Approved';
        OppoRe.Law_Firm__c = accountList[1].Id;        
        OppoRe.Stage_Status__c = 'File Sent for EFT';
        OppoRe.Type_of_Loan__c = 'Facility Loan';
        OppoRe.Primary_Contact__c = contactList[0].Id;
        OppoRe.Minimum_Interest_Period__c = '0 months';
        OppoRe.Compounding_Interest__c = 'Monthly';
        OppoRe.Interest_Rate__c = 15.0;
        OppoRe.Interest_Compounding_Period__c = 'Simple Interest';
        OppoRe.Interest_Deferral_Period__c = '0';
        insert OppoRe;
        */
    }
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50)));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    /*
    public static testMethod void testGetOpportunitiesDateFilter(){
        Test.startTest();
        List<Opportunity> opps = FundingDetailsComponentCtlr.getOpportunities(Date.today(), null);
        Test.stopTest();

        system.assertEquals(opps.size(), 1);
        Opportunity opp = opps[0];
        system.assertEquals(opp.File_Sent_For_EFT_Date__c, Date.today());
    }
    */

    public static testMethod void testGetScheduledPaymentsWithOpportunities(){
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Scheduled)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(true)');
        sp.setDefinition('Cheque_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        Test.startTest();
        Map<String, Object> results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'validateEft', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'generateBankingSheet', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'validateCheque', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'sendCheques', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'updateEFTInfo', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), 'processAndValidateLoan', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(Date.today(), null, 'reviewClosedPayments', null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, Date.today(), null, null);
        results = FundingDetailsComponentCtlr.getScheduledPaymentsWithOpportunities(null, null, 'staging', null);
        Test.stopTest();

        system.assert(results.containsKey('scheduled_payments'), 'Results should contain scheduled payments');
        system.assert(results.containsKey('opportunities'), 'Results should contain opportunities');
        system.assert(results.containsKey('accounts'), 'Results should contain accounts');
    }


    //public static Opportunity[] (){
    public static testMethod void testGetOpportunitiesWithScheduledPayments(){
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        opp.setDefinition('Funding_Details_Status__c', 'static value(Loan Setup Check)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Processed by Bank)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(true)');
        sp.setDefinition('Cheque_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        Test.startTest();
        List<Opportunity> opps = FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments(null, null);
        Test.stopTest();

        system.assertEquals(1, opps.size(), 'Should return 1 opp');
        system.assertEquals(1, opps[0].Scheduled_Payments__r.size(), 'Opp should have 1 scheduled payment');
    }

    public static testMethod void testFilterOpportunitiesByScheduledPaymentDate(){
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        opp.setDefinition('Funding_Details_Status__c', 'static value(Loan Setup Check)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        
        Datetime firstDate = Datetime.newInstance(2019, 10, 1, 0, 0, 0);
        Datetime secondDate = Datetime.newInstance(2019, 10, 2, 0, 0, 0);
        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(2);
        Scheduled_Payment__c[] spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, false);
        spRecs[0].Amount__c = 1000;
        spRecs[0].Payment_Type__c = 'Ad-Hoc';
        spRecs[0].Status__c = 'Processed by Bank';
        spRecs[1].Amount__c = 1000;
        spRecs[1].Payment_Type__c = 'Ad-Hoc';
        spRecs[1].Status__c = 'Processed by Bank';
        spRecs[1].Sent_to_Bank_Date__c = secondDate;
        spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, true);
        spRecs[0].Sent_to_Bank_Date__c = firstDate;
        spRecs[1].Sent_to_Bank_Date__c = secondDate;
        update spRecs;

        Opportunity[] filteredOpps;
        Test.startTest();
        List<Opportunity> opps = FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments(null, null);
        Test.stopTest();

        // No filters
        filteredOpps = FundingDetailsComponentCtlr.filterOpportunitiesByScheduledPaymentDate(opps, null, null);
        system.assertEquals(1, filteredOpps.size(), 'Should return 1 opp');
        system.assertEquals(2, filteredOpps[0].Scheduled_Payments__r.size(), 'Opp should have 2 scheduled payments');

        filteredOpps = FundingDetailsComponentCtlr.filterOpportunitiesByScheduledPaymentDate(opps, firstDate.Date(), secondDate.date());
        system.assertEquals(1, filteredOpps.size(), 'Should return 1 opp');
        system.assertEquals(2, filteredOpps[0].Scheduled_Payments__r.size(), 'Opp should have 2 scheduled payments');

        filteredOpps = FundingDetailsComponentCtlr.filterOpportunitiesByScheduledPaymentDate(opps, null, firstDate.Date());
        system.assertEquals(1, filteredOpps.size(), 'Should return 1 opp');
        system.assertEquals(2, filteredOpps[0].Scheduled_Payments__r.size(), 'Opp should have 2 scheduled payments');

        filteredOpps = FundingDetailsComponentCtlr.filterOpportunitiesByScheduledPaymentDate(opps, secondDate.Date(), null);
        system.assertEquals(1, filteredOpps.size(), 'Should return 1 opp');
        system.assertEquals(2, filteredOpps[0].Scheduled_Payments__r.size(), 'Opp should have 2 scheduled payments');

        Date outOfBoundsDate = secondDate.date().addDays(1);
        filteredOpps = FundingDetailsComponentCtlr.filterOpportunitiesByScheduledPaymentDate(opps, outOfBoundsDate, outOfBoundsDate);
        system.assertEquals(0, filteredOpps.size(), 'Should return no opp');
    }

    //public static string generateBankingSheet(Id[] spIds){
    public static testMethod void testGenerateBankingSheet(){
        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];

        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];
        Account acc = new Account(Id=bankRec.Client__c);
        acc.Primary_Bank_Account__c = bankRec.Id;
        update acc;

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        //opp.setDefinition('Funding_Details_Status__c', 'static value(Loan Setup Check)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Approved to Send)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(false)');
        sp.setDefinition('EFT_Number__c', 'static value(123)');
        sp.setDefinition('Account__c', 'random lookup(Account) source(forceea)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        String sheet = FundingDetailsComponentCtlr.generateBankingSheet(new Id[]{spRecs[0].Id});
    }

    //public static Scheduled_Payment__c[] updateScheduledPayments(Scheduled_Payment__c[] scheduledPayments){
    public static testMethod void testUpdateScheduledPayments(){
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        //opp.setDefinition('Funding_Details_Status__c', 'static value(Loan Setup Check)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Approved to Send)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(true)');
        sp.setDefinition('Cheque_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        spRecs[0].Amount__c = 1500.00;

        test.startTest();
        spRecs = FundingDetailsComponentCtlr.updateScheduledPayments(spRecs);
        test.stopTest();
        system.assertEquals(1500.00, spRecs[0].Amount__c);
    }

    //public static Scheduled_Payment__c[] moveToProcessStep(Scheduled_Payment__c[] scheduledPayments){
    public static testMethod void testMoveToProcessStep(){
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(475)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        //opp.setDefinition('Funding_Details_Status__c', 'static value(Loan Setup Check)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Sent to Bank)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(true)');
        sp.setDefinition('Cheque_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        test.startTest();
        spRecs = FundingDetailsComponentCtlr.moveToProcessStep(spRecs);
        test.stopTest();
        //system.assertEquals(1500.00, spRecs[0].Amount__c)
    }
}