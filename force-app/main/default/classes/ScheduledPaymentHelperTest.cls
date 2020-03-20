/**
 * @File Name          : ScheduledPaymentHelperTest.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/1/2019, 3:19:14 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/25/2019, 10:39:39 AM   Seth Boyd     Initial Version
**/
@isTest(seeAllData=false)
public class ScheduledPaymentHelperTest {

    @isTest
    static void test_one_sp() {
        // Test with no account set on SP
        System.debug(System.LoggingLevel.ERROR, Date.today());
        DateUtil.today = Date.today();
        DateUtil.now = DateTime.now();
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
        sp.setDefinition('Status__c', 'static value(Sent to Bank)');
        sp.setDefinition('Payment_Type__c', 'static value(Lump-Sum)');
        sp.setDefinition('Sent_to_Bank_Date__c', 'static value(2015-12-31 15:13:00)');
        sp.setDefinition('EFT_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c spRec = ((List<Scheduled_Payment__c>)sp.getRecords())[0];
        Date sentDate = Date.newInstance(2015,12,31);

        String eftNum = '123';
        test.startTest();
        Id[] spIds = new Id[]{spRec.Id};
        system.debug(System.LoggingLevel.ERROR, spRec.Sent_to_Bank_Date__c);
        ScheduledPaymentHelper.generateDrawdowns(spIds);
        test.stopTest();

        spRec = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                First_Sent_to_Bank_Date__c
            From Scheduled_Payment__c
            Where Id = :spRec.Id
        ];
        system.debug(System.LoggingLevel.ERROR, spRec.First_Sent_to_Bank_Date__c);

        Drawdown__c[] dd = [
            Select
                Id,
                Scheduled_Payment__c,
                Amount__c,
                Opportunity__c,
                EFT__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c,
                Scheduled_Payment__r.First_Sent_to_Bank_Date__c
            FROM Drawdown__c
            Where Scheduled_Payment__c = :spRec.Id
        ];
        
        system.debug(System.LoggingLevel.ERROR, dd[0].Scheduled_Payment__r.First_Sent_to_Bank_Date__c);
        system.debug(System.LoggingLevel.ERROR, 'dd[0].Date__c: ' + dd[0].Date__c);
        // ensure drawdown was created correctly
        system.assert(!dd.isEmpty(), 'Drawdown should have been created');
        system.assertEquals(spRec.Id, dd[0].Scheduled_Payment__c, 'Drawdown should be associated with Scheduled Payment');
        system.assertEquals(spRec.Amount__c, dd[0].Amount__c, 'Drawdown Amount should be set');
        system.assertEquals(spRec.Opportunity__c, dd[0].Opportunity__c, 'Drawdown Opporunity should be set');
        system.assertEquals(eftNum, dd[0].EFT__c, 'Drawdown EFT # should be set');
        system.assertEquals('e-Transfer', dd[0].Payment_Method__c, 'Drawdown payment method should be set');
        system.assertEquals('Payment to Client', dd[0].Reference_Notes__c, 'Drawdown Reference Notes should be set');
        system.assertEquals(dd[0].Scheduled_Payment__r.First_Sent_to_Bank_Date__c, dd[0].Date__c, 'Drawdown date should be set');
        system.assertEquals(sentDate, dd[0].Date__c, 'Drawdown date should be set');

        // ensure admin fee drawdown was created
        Drawdown__c[] adminDD = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            From Drawdown__c
            Where
                Payment_Method__c = 'Admin Fee'];
        System.debug(adminDD);
        system.assert(!adminDD.isEmpty(), 'Admin Fee drawdown should have been created');
        system.assertEquals(oppRec.Admin_Fee__c, adminDD[0].Amount__c, 'Amount should have been set');
        system.assertEquals(oppRec.Id, adminDD[0].Opportunity__c, 'Opporunity should have been set');
        system.assertEquals('Admin Fee', adminDD[0].Reference_Notes__c, 'Reference notes should have been set');
        system.assertEquals(dd[0].Date__c, adminDD[0].Date__c, 'Date should have been set');
        system.assertEquals(sentDate, adminDD[0].Date__c, 'Date should have been set');

        //oppRec = [Select Id, Funding_Details_Status__c from Opportunity Where Id = :oppRec.Id][0];
        //System.assertEquals('Loan Setup Check', oppRec.Funding_Details_Status__c, 'Opportunity Funding Details Status should have been set');
    }

    @isTest
    static void test_multiple_sp_per_opp() {
        // Test with multiple scheduled payments per opp
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

        FObject sp = new Fobject('Scheduled_Payment__c', 2);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Sent to Bank)');
        sp.setDefinition('Payment_Type__c', 'static value(Ad-Hoc)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('Send_Cheque__c', 'static value(true)');
        sp.setDefinition('Cheque_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c[] spRecs = ((List<Scheduled_Payment__c>)sp.getRecords());

        String chqNum = '123';
        test.startTest();
        ScheduledPaymentHelper.invocableGenerateDrawdowns(new Id[]{oppRec.Id});
        test.stopTest();

        // Test first sp
        Id[] spIds = new Id[]{spRecs[0].Id, spRecs[1].Id};

        spRecs = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                First_Sent_to_Bank_Date__c
            From Scheduled_Payment__c
            Where Id in :spIds
            Order By First_Sent_to_Bank_Date__c ASC
        ];

        Scheduled_Payment__c spRec = spRecs[0];

        Drawdown__c[] dd = [
            Select
                Id,
                Scheduled_Payment__c,
                Amount__c,
                Opportunity__c,
                CHQ__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            FROM Drawdown__c
            Where Scheduled_Payment__c = :spRec.Id
        ];

        // ensure drawdown was created correctly
        system.assert(!dd.isEmpty(), 'Drawdown should have been created');
        system.assertEquals(spRec.Id, dd[0].Scheduled_Payment__c, 'Drawdown should be associated with Scheduled Payment');
        system.assertEquals(spRec.Amount__c, dd[0].Amount__c, 'Drawdown Amount should be set');
        system.assertEquals(spRec.Opportunity__c, dd[0].Opportunity__c, 'Drawdown Opporunity should be set');
        system.assertEquals(chqNum, dd[0].CHQ__c, 'Drawdown CHQ # should be set');
        system.assertEquals('Cheque', dd[0].Payment_Method__c, 'Drawdown payment method should be set');
        system.assertEquals('Payment to Client', dd[0].Reference_Notes__c, 'Drawdown Reference Notes should be set');
        //system.assertEquals(spRec.First_Sent_to_Bank_Date__c.date(), dd[0].Date__c, 'Drawdown date should be set');

        spRec = spRecs[1];
        dd = [
            Select
                Id,
                Scheduled_Payment__c,
                Amount__c,
                Opportunity__c,
                CHQ__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            FROM Drawdown__c
            Where Scheduled_Payment__c = :spRec.Id
        ];
        // ensure drawdown was created correctly
        system.assert(!dd.isEmpty(), 'Drawdown should have been created');
        system.assertEquals(spRec.Id, dd[0].Scheduled_Payment__c, 'Drawdown should be associated with Scheduled Payment');
        system.assertEquals(spRec.Amount__c, dd[0].Amount__c, 'Drawdown Amount should be set');
        system.assertEquals(spRec.Opportunity__c, dd[0].Opportunity__c, 'Drawdown Opporunity should be set');
        system.assertEquals(chqNum, dd[0].CHQ__c, 'Drawdown CHQ # should be set');
        system.assertEquals('Cheque', dd[0].Payment_Method__c, 'Drawdown payment method should be set');
        system.assertEquals('Payment to Client', dd[0].Reference_Notes__c, 'Drawdown Reference Notes should be set');
        //system.assertEquals(spRec.First_Sent_to_Bank_Date__c.date(), dd[0].Date__c, 'Drawdown date should be set');

        // ensure admin fee drawdown was created
        Drawdown__c[] adminDD = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            From Drawdown__c
            Where
                Payment_Method__c = 'Admin Fee'];
        System.debug(adminDD);
        system.assert(!adminDD.isEmpty(), 'Admin Fee drawdown should have been created');
        system.assertEquals(1, adminDD.size(), 'Only one admin fee Drawdown should have been created');
        system.assertEquals(oppRec.Admin_Fee__c, adminDD[0].Amount__c, 'Amount should have been set');
        system.assertEquals(oppRec.Id, adminDD[0].Opportunity__c, 'Opporunity should have been set');
        system.assertEquals('Admin Fee', adminDD[0].Reference_Notes__c, 'Reference notes should have been set');
        system.assertEquals(DateUtil.today(), adminDD[0].Date__c, 'Date should have been set');

        //oppRec = [Select Id, Funding_Details_Status__c from Opportunity Where Id = :oppRec.Id][0];
        //System.assertEquals('Loan Setup Check', oppRec.Funding_Details_Status__c, 'Opportunity Funding Details Status should have been set');
    }

    @isTest
    static void test_assessment_fee() {
        // Test with no account set on SP
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        FObject opp = new FObject('Opportunity', 1);
        opp.setDefinition('Amount', 'static value(5000)');
        opp.setDefinition('Admin_Fee__c', 'static value(175)');
        opp.setDefinition('StageName', 'static value(Loan Approved)');
        opp.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        opp.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        opp.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        opp.setDefinition('Interest_Rate__c', 'static value(0.245)');
        opp.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        opp.setDefinition('Type_of_Loan__c', 'static value(Assessment)');
        opp.insertRecords(true);
        Opportunity oppRec = ((List<Opportunity>)opp.getRecords())[0];

        FObject sp = new Fobject('Scheduled_Payment__c', 1);
        sp.setDefinition('Amount__c', 'static value(1000)');
        sp.setDefinition('Status__c', 'static value(Sent to Bank)');
        sp.setDefinition('Payment_Type__c', 'static value(Assessment)');
        //sp.setDefinition('Sent_to_Bank_Date__c', 'random type(datetime) from(2010-1-1) to(2015-12-31 15:13:00)');
        sp.setDefinition('EFT_Number__c', 'static value(123)');
        sp.insertRecords(true);
        Scheduled_Payment__c spRec = ((List<Scheduled_Payment__c>)sp.getRecords())[0];

        String eftNum = '123';
        test.startTest();
        Id[] spIds = new Id[]{spRec.Id};
        ScheduledPaymentHelper.generateDrawdowns(spIds);
        test.stopTest();

        spRec = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                First_Sent_to_Bank_Date__c
            From Scheduled_Payment__c
            Where Id = :spRec.Id
        ];

        Drawdown__c[] dd = [
            Select
                Id,
                Scheduled_Payment__c,
                Amount__c,
                Opportunity__c,
                EFT__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            FROM Drawdown__c
            Where Scheduled_Payment__c = :spRec.Id
        ];
        // ensure drawdown was created correctly
        system.assert(!dd.isEmpty(), 'Drawdown should have been created');
        system.assertEquals(spRec.Id, dd[0].Scheduled_Payment__c, 'Drawdown should be associated with Scheduled Payment');
        system.assertEquals(spRec.Amount__c, dd[0].Amount__c, 'Drawdown Amount should be set');
        system.assertEquals(spRec.Opportunity__c, dd[0].Opportunity__c, 'Drawdown Opporunity should be set');
        system.assertEquals(eftNum, dd[0].EFT__c, 'Drawdown EFT # should be set');
        system.assertEquals('e-Transfer', dd[0].Payment_Method__c, 'Drawdown payment method should be set');
        system.assertEquals('Payment to Assessment Provider', dd[0].Reference_Notes__c, 'Drawdown Reference Notes should be set');
        //system.assertEquals(spRec.First_Sent_to_Bank_Date__c.date(), dd[0].Date__c, 'Drawdown date should be set');

        // ensure admin fee drawdown was created
        Drawdown__c[] adminDD = [
            Select
                Id,
                Amount__c,
                Opportunity__c,
                Payment_Method__c,
                Reference_Notes__c,
                Date__c
            From Drawdown__c
            Where
                Payment_Method__c = 'Admin Fee'];
        System.debug(adminDD);
        system.assert(!adminDD.isEmpty(), 'Admin Fee drawdown should have been created');
        system.assertEquals(oppRec.Admin_Fee__c, adminDD[0].Amount__c, 'Amount should have been set');
        system.assertEquals(oppRec.Id, adminDD[0].Opportunity__c, 'Opporunity should have been set');
        system.assertEquals('Assessment Fee', adminDD[0].Reference_Notes__c, 'Reference notes should have been set');
        system.assertEquals(DateUtil.today(), adminDD[0].Date__c, 'Date should have been set');

        //oppRec = [Select Id, Funding_Details_Status__c from Opportunity Where Id = :oppRec.Id][0];
        //System.assertEquals('Loan Setup Check', oppRec.Funding_Details_Status__c, 'Opportunity Funding Details Status should have been set');
    }

    
    @isTest
    static void test_deletePayment() {
        // Test with multiple scheduled payments per opp
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 1475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 1000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c sp = [Select Id From Scheduled_Payment__c Limit 1];
        sp.Status__c = 'Approved to Send';
        sp.Current_Opportunity_Schedule_Version_Val__c = true;
        sp.Drawdown_Created__c = true;
        update sp;
        /*
        new Scheduled_Payment__c(
            Opportunity__c = opp.Id,
            Payment_Type__c = 'Scheduled Facility',
            Amount__c = 0,
            Status__c = 'Approved to Send',
            Current_Opportunity_Schedule_Version_Val__c = true,
            Drawdown_Created__c = true
        );
        insert sp;
        */

        AuraHandledException exc = null;
        test.startTest();
        try {
            ScheduledPaymentHelper.deletePayment(sp.Id, false);
        } catch (AuraHandledException thrownExc) {
            system.debug(thrownExc.getMessage());
            exc = thrownExc;
        }

        System.assertNotEquals(null, exc, 'An exception should have been thrown');
        String message = exc.getMessage();
        System.debug(LoggingLevel.ERROR, message);
        System.debug(LoggingLevel.ERROR, message.contains('Payment is currently being processed'));

        /*
        Payment is currently being processed
        Payment is part of of an active payment schedule
        Payment has already been processed to drawdown
        */

        System.assert(message.contains('Payment is currently being processed'), 'Exception should contain message about being processed');
        System.assert(message.contains('Payment is part of of an active payment schedule'), 'Exception should contain message about being part of active schedule');
        System.assert(message.contains('Payment has already been processed to drawdown'), 'Exception should contain message Payment has already been processed to drawdown');

        // Try force
        exc = null;
        try {
            ScheduledPaymentHelper.deletePayment(sp.Id, true);
        } catch (AuraHandledException thrownExc) {
            system.debug(thrownExc.getMessage());
            exc = thrownExc;
        }
        System.assertEquals(null, exc, 'An exception should not have been thrown');
        Scheduled_Payment__c[] spList = [Select Id From Scheduled_Payment__c Where Id = :new Id[]{sp.Id}];
        System.assertEquals(0, spList.size(), 'Scheduled Payment should have been deleted');
        test.stopTest();
    }

    public static void clearTestData(String[] fileNos) {
        // Method used to clear out test data from orgs
        /*
        String[] fileNos = new String[]{
            '9865 test',
            '9866 test',
            '9864 test',
            'Nicole Popovich-Account #1',
            'test',
            '3352 test',
            '3289 test',
            '9875 test',
            '9898 test'
        };

        Map<Id, Account> accs = new Map<Id, Account>();
        Map<Id, Contact> contacts = new Map<Id, Contact>();
        List<Scheduled_Payment__c> sps = new List<Scheduled_Payment__c>();
        List<Previous_Loan__c> pls = new List<Previous_Loan__c>();
        List<Drawdown__c> dds = new List<Drawdown__c>();
        List<Opportunity_Service_Provider__c> osps = new List<Opportunity_Service_Provider__c>();
        Set<Id> ospIds = new set<Id>();
        Lead[] leads = [Select Id from Lead Where ELF_File_No__c in :fileNos];

        Opportunity[] opps = [
            Select 
                Id,
                AccountId,
                Account.Name,
                ContactId,
                (Select Id From Scheduled_Payments__r),
                (Select Id From Drawdowns__r Order By Date__c DESC),
                (Select Id From Opportunity_Service_Providers__r),
                (Select Id From Previous_Loans__r)
            From Opportunity Where File_No__c in :fileNos];

        for (Opportunity opp : opps) {
            if (opp.AccountId != null)
                accs.put(opp.AccountId, new Account(Id=opp.AccountId));
            if (opp.ContactId != null)
                contacts.put(opp.ContactId, new Contact(Id=opp.ContactId));
            if (opp.Scheduled_Payments__r != null) {
                sps.addAll(opp.Scheduled_Payments__r);
            }
            if (opp.Drawdowns__r != null) {
                dds.addAll(opp.Drawdowns__r);
            }
            if (opp.Previous_Loans__r != null) {
                pls.addAll(opp.Previous_Loans__r);
            }
            if (opp.Opportunity_Service_Providers__r != null) {
                osps.addAll(opp.Opportunity_Service_Providers__r);
            }
        }

        for (opportunity_service_provider__c osp : osps) {
            ospids.add(osp.id);
        }
        //opportunity_service_provider_invoice__c invoice = new opportunity_service_provider_invoice__c();
        opportunity_service_provider_invoice__c[] ospis = [select id from opportunity_service_provider_invoice__c where opportunity_service_provider__c in :ospids];
        delete sps;
        delete ospis;
        delete osps;
        delete pls;
        for (drawdown__c dd : dds) {
            delete dd;
        }
        //delete dds;
        delete opps;
        delete accs.values();
        //delete contacts.values();
        delete leads;
        

        /*

        system.debug(accs);
        system.debug(contacts);
        system.debug(leads);
        system.debug(opps.size());
        system.debug(sps);
        system.debug(dds);
        system.debug(osps);

        Opportunity opp = new Opportunity();
        opp.File_No__c;
        opp.Name;
        opp.Contact.ELF_File_No__c
        Drawdown__c dd = new Drawdown__c();
        */
    }

}
