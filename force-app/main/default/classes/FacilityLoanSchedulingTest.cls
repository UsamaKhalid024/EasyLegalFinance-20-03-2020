@isTest(seeAllData=false)
public class FacilityLoanSchedulingTest {

    @isTest
    static void test_full_process_amount() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }
        test.stopTest();
        /*

        Scheduled_Payment__c sp2 = spList[1];
        sp2.Status__c = 'Approved to Send';
        sp2.Banking_Verified__c = true;
        sp2.BIA_PPSA_LL_Verified__c = true;
        sp2.Credit_Verified__c = true;
        sp2.Documents_Verified__c = true;
        update sp2;

        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp2.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp2 = spList[1];
        System.assertEquals(opp.Id, sp2.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp2.Amount__c, sp2.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp2.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp2.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        dt = DateUtil.today();
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }
        */

    }

    @isTest
    static void test_full_process_amount_with_immediate() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

    }

    @isTest
    static void test_process_amount_with_partial_and_immediate() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }
    }

    @isTest
    static void test_process_amount_version_before_in_process() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        opp.Drawdown_Amount__c = 1000.00;
        update opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        test.stopTest();

        system.debug(opp);
        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }
    }

    @isTest
    static void test_process_amount_version_after_in_process() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        update opp;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(6, spList.size(), 'Should be 6 payments'); // One in process and
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                if (i == 0) {
                    System.assertEquals(2000.00, sp.Amount__c, 'Should be same amount');
                    System.assertEquals(false, sp.Current_Opportunity_Schedule_Version__c, 'Should not be current schedule');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                    System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
                }
            }
        }
    }

    @isTest
    static void test_process_amount_version_after_drawdowns() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }


        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        update opp;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(6, spList.size(), 'Should be 6 payments'); // One in process and
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                if (i == 0) {
                    System.assertEquals(2000.00, sp.Amount__c, 'Should be same amount');
                    System.assertEquals(false, sp.Current_Opportunity_Schedule_Version__c, 'Should not be current schedule');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                    System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
                }
            }
        }
    }

    @isTest
    static void test_process_amount_version_after_drawdowns_with_reversal() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        Payment_Rejection__c pr = New Payment_Rejection__c(
            Scheduled_Payment__c = spList[0].Id,
            Scheduled_Payment_Action__c = 'Set to Rejected'
        );
        insert pr;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Drawdown__c, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(3, spList.size(), 'Should be 3 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 2) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
    }

    @isTest
    static void test_full_amount_create_delete_adhoc() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test adding Drawdown
        Scheduled_Payment__c ah = New Scheduled_Payment__c(
            Opportunity__c=opp.Id,
            Amount__c = 8000
        );
        insert ah;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(2, spList.size(), 'Should be 2 payments');
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            delete ah;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(3, spList.size(), 'Should be 3 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 2) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
    }

    @isTest
    static void test_full_amount_create_delete_drawdowns() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
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
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            if (i == 2) {
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            } else {
                System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            }
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test adding Drawdown
        Drawdown__c dd = New Drawdown__c(
            Opportunity__c=opp.Id,
            Amount__c = 8000, 
            Payment_Method__c = 'e-Transfer',
            Reference_Notes__c = 'Payment to Client',
            EFT__c = '123' 
        );
        insert dd;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(1, spList.size(), 'Should be 1 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 2) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }

        dd.Amount__c = 0;
        system.runAs(new User(Id=UserInfo.getUserId())) {
            update dd;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(3, spList.size(), 'Should be 3 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 2) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                } else {
                    System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
    }


    @isTest
    static void test_full_process_date() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(5);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }
        test.stopTest();
        /*

        Scheduled_Payment__c sp2 = spList[1];
        sp2.Status__c = 'Approved to Send';
        sp2.Banking_Verified__c = true;
        sp2.BIA_PPSA_LL_Verified__c = true;
        sp2.Credit_Verified__c = true;
        sp2.Documents_Verified__c = true;
        update sp2;

        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp2.Id});

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp2 = spList[1];
        System.assertEquals(opp.Id, sp2.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp2.Amount__c, sp2.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp2.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp2.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        dt = DateUtil.today();
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt.month(), sp.Scheduled_Date__c.month(), 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            dt = dt.addMonths(1);
        }
        */

    }

    @isTest
    static void test_full_process_date_with_immediate() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c, EFT_Number__c,
                Drawdown__r.Amount__c,
                Drawdown__r.Opportunity__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Payment_Method__c,
                Drawdown__r.Reference_Notes__c,
                Drawdown__r.Date__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);
        for (Scheduled_Payment__c sp : spList) {
            System.debug(System.LoggingLevel.ERROR, sp);
        }

        sp1 = spList[0];
        System.assertEquals(opp.Id, sp1.Drawdown__r.Opportunity__c, 'Opp Should be set on Drawdown');
        System.assertEquals(sp1.Amount__c, sp1.Drawdown__r.Amount__c, 'Amounts should be the same');
        System.assertEquals('e-Transfer', sp1.Drawdown__r.Payment_Method__c, 'Payment Method');
        System.assertEquals('Payment to Client', sp1.Drawdown__r.Reference_Notes__c, 'Reference Notes');

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(opp.Drawdown_Amount__c, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

    }

    @isTest
    static void test_process_date_version_before_in_process() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        opp = [Select Id, End_Date__c, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        opp.End_Date__c = opp.End_Date__c.addMonths(1);
        opp.Payment_Schedule_Allotted_Amount__c = 6000.00;
        update opp;
        opp = [Select Id, Drawdown_Amount__c, Payment_Schedule__c, Payment_Schedule_Version_Number__c from Opportunity Where Id = :opp.Id];
        test.stopTest();

        system.debug(opp);
        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(6, spList.size(), 'Should be 6 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }
    }

    @isTest
    static void test_process_date_version_after_in_process() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        opp.End_Date__c = opp.End_Date__c.addMonths(1);
        opp.Payment_Schedule_Allotted_Amount__c = 6000.00;
        update opp;
        dtList = new Date[]{
            Dateutil.today(),
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC, CreatedDate ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(7, spList.size(), 'Should be 7 payments'); // One in process and
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                if (i == 0) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
                    System.assertEquals(false, sp.Current_Opportunity_Schedule_Version__c, 'Should not be current schedule');
                } else {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
                    System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
                }
            }
        }
    }

    @isTest
    static void test_process_date_version_after_drawdowns() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }


        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        opp.End_Date__c = opp.End_Date__c.addMonths(2);
        opp.Payment_Schedule_Allotted_Amount__c = 6000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        update opp;
        dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC, CreatedDate ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(7, spList.size(), 'Should be 7 payments'); // One in process and
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                if (i == 0) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
                    System.assertEquals(false, sp.Current_Opportunity_Schedule_Version__c, 'Should not be current schedule');
                } else {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be same amount');
                    System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
                }
            }
        }
    }

    @isTest
    static void test_process_date_version_after_drawdowns_with_reversal() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        test.startTest();
        ScheduledPaymentHelper.generateDrawdowns(new Id[]{sp1.Id});
        test.stopTest();

        Payment_Rejection__c pr = New Payment_Rejection__c(
            Scheduled_Payment__c = spList[0].Id,
            Scheduled_Payment_Action__c = 'Set to Rejected'
        );
        insert pr;

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Drawdown__c, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(5, spList.size(), 'Should be 5 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
    }

    @isTest
    static void test_full_date_create_delete_adhoc() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(4);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(5, spList.size(), 'Should be 5 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        Scheduled_Payment__c ah = New Scheduled_Payment__c(
            Opportunity__c=opp.Id,
            Amount__c = 8000 
        );
        // Test adding Ad Hoc
        system.runAs(new User(Id=UserInfo.getUserId())) {
            insert ah;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Where Current_Opportunity_Schedule_Version__c = true
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(5, spList.size(), 'Should be 5 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 0) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a the same');
                } else {
                    System.assertEquals(250.00, sp.Amount__c, 'Should be a smaller');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            }
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            delete ah;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(5, spList.size(), 'Should be 5 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
    }

    @isTest
    static void test_full_date_create_delete_drawdowns() {
        // Test with no account set on SP
        Integer year = 2019;
        Integer month = 1;
        Integer day = 1;
        DateUtil.today = Date.newInstance(year, month, day);
        DateUtil.now = Datetime.newInstance(year, month, day);

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(TestDataFactory.getBankAccountConfig(1), false)[0];
        bankRec.Mark_as_Primary__c = true;
        insert bankRec;

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.StageName = 'Closed With Loan';
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 10475.00;
        opp.Admin_Fee__c = 475.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 24.5;

        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opp.End_Date__c = DateUtil.today().addMonths(2);
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Default_Bank_Account__c = bankRec.Id;
        opp.Start_Date__c = DateUtil.today();
        opp.Day_of_Month__c = 'Last';
        opp.Payment_Schedule_Allotted_Amount__c = 3000.00;
        opp.Drawdown_Amount__c = 2000.00;
        opp.Payment_Schedule_Send_First_Immediately__c = true;
        opp.CloseDate = DateUtil.today();
        insert opp;
        system.debug(opp);

        Scheduled_Payment__c[] spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        Date[] dtList = new Date[]{
            Dateutil.today(),
            Date.newInstance(year, month, Date.daysInMonth(year, month)),
            Date.newInstance(year, month+1, Date.daysInMonth(year, month+1)),
            Date.newInstance(year, month+2, Date.daysInMonth(year, month+2)),
            Date.newInstance(year, month+3, Date.daysInMonth(year, month+3)),
            Date.newInstance(year, month+4, Date.daysInMonth(year, month+4)),
            Date.newInstance(year, month+5, Date.daysInMonth(year, month+5))
        };
        System.debug(System.LoggingLevel.ERROR, spList);
        System.debug(System.LoggingLevel.ERROR, dtList);
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test In Process
        Scheduled_Payment__c sp1 = spList[0];
        sp1.Status__c = 'Approved to Send';
        sp1.Banking_Verified__c = true;
        sp1.BIA_PPSA_LL_Verified__c = true;
        sp1.Credit_Verified__c = true;
        sp1.Documents_Verified__c = true;
        sp1.EFT_Number__c = '123';
        update sp1;

        spList = [
            Select
                Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
            From Scheduled_Payment__c
            Where Opportunity__c = :opp.Id
            Order By Scheduled_Date__c ASC
        ];
        System.debug(System.LoggingLevel.ERROR, spList);

        System.assertEquals(3, spList.size(), 'Should be 3 payments');
        for (Integer i = 0; i < spList.size(); i++) {
            Scheduled_Payment__c sp = spList[i];
            Date dt = dtList[i];
            System.debug(System.LoggingLevel.ERROR, sp);
            System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
            System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
        }

        // Test adding Drawdown
        Drawdown__c dd = New Drawdown__c(
            Opportunity__c=opp.Id,
            Amount__c = 8000, 
            Payment_Method__c = 'e-Transfer',
            Reference_Notes__c = 'Payment to Client',
            EFT__c = '123' 
        );
        // Test adding Ad Hoc
        system.runAs(new User(Id=UserInfo.getUserId())) {
            insert dd;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Where Current_Opportunity_Schedule_Version__c = true
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(3, spList.size(), 'Should be 3 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                if (i == 0) {
                    System.assertEquals(1000.00, sp.Amount__c, 'Should be a the same');
                } else {
                    System.assertEquals(500.00, sp.Amount__c, 'Should be a smaller');
                }
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
            }
        }

        /*
        // Hitting SOQL limits
        system.runAs(new User(Id=UserInfo.getUserId())) {
            dd.Amount__c = 0.00;
            update dd;
        }

        system.runAs(new User(Id=UserInfo.getUserId())) {
            spList = [
                Select
                    Id, Status__c, Scheduled_Date__c, Amount__c, Current_Opportunity_Schedule_Version__c
                From Scheduled_Payment__c
                Order By Scheduled_Date__c ASC
            ];
            // First payment is in process

            System.debug(System.LoggingLevel.ERROR, spList);
            System.assertEquals(5, spList.size(), 'Should be 5 payments');
            for (Integer i = 0; i < spList.size(); i++) {
                Scheduled_Payment__c sp = spList[i];
                Date dt = dtList[i];
                System.debug(System.LoggingLevel.ERROR, sp);
                System.assertEquals(1000.00, sp.Amount__c, 'Should be a smaller');
                System.assertEquals(dt, sp.Scheduled_Date__c, 'Date should increment through months: ' + sp.Scheduled_Date__c.format());
                System.assert(sp.Current_Opportunity_Schedule_Version__c, 'Should be current schedule');
            }
        }
        */
    }

}