@isTest(seeAllData=false)
private class PaymentRejectionTriggerHandlerTest {
    @TestSetup
    static void setup(){
        FObject.seed = 1234;

        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];
        u.EFT_Originator_Id__c = 'TWELF10201';
        update u;

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
        String eftNum = 'abc123';
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        Opportunity opp = TestDataFactory.getOpportunityObjects(TestDataFactory.getOpportunityConfig(1), false)[0];
        opp.Payment_Schedule__c = 'Yes';
        opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        opp.Payment_Use_Primary_Bank_Account__c = true;
        opp.Payment_Schedule_Allotted_Amount__c = 1000.00;
        opp.Day_of_Month__c = 'Last';
        opp.Start_Date__c = DateUtil.today();
        opp.Payment_Schedule_Send_First_Immediately__c = false;
        opp.Drawdown_Amount__c = 1000.00;
        opp.Lawyer__c = contactList[1].Id;
        opp.CloseDate = DateUtil.today().addDays(14);
        opp.StageName = 'Closed With Loan';
        opp.Law_Firm__c = accountList[1].Id;        
        opp.Stage_Status__c = 'Approved';
        opp.Amount = 5375.00;
        opp.Admin_Fee__c = 375.00;
        opp.Payout_Date__c = DateUtil.today();
        opp.Type_of_Loan__c = 'Facility Loan';
        opp.Primary_Contact__c = contactList[0].Id;
        opp.Minimum_Interest_Period__c = '0 months';
        opp.Compounding_Interest__c = 'Monthly';
        opp.Interest_Compounding_Period__c = 'Compounding Interest';
        opp.Interest_Rate__c = 15.0;
        insert opp;

        Scheduled_Payment__c sp = [Select Id, Amount__c, Opportunity__c From Scheduled_Payment__c Limit 1];
        sp.Banking_Verified__c = true;
        sp.BIA_PPSA_LL_Verified__c = true;
        sp.Credit_Verified__c = true;
        sp.Documents_Verified__c = true;
        sp.Send_Cheque__c = true;
        sp.Cheque_Number__c = eftNum;
        sp.Status__c = 'Processed by Bank';
        sp.First_Sent_to_Bank_Date__c = Datetime.Now();

        Drawdown__c dd = new Drawdown__c(
            Scheduled_Payment__c=sp.Id,
            Amount__c=sp.Amount__c,
            Date__c=sp.First_Sent_to_Bank_Date__c.Date(),
            Opportunity__c=sp.Opportunity__c,
            Payment_Method__c='Cheque',
            CHQ__c=eftNum,
            Reference_Notes__c='Payment to Client'
        );
        insert dd;

        sp.Drawdown__c = dd.Id;

        update sp;
    }

    @isTest
    static void test_facility_rejection() {

        //ScheduledPaymentHelper.generateDrawdowns(spIds);
        Scheduled_Payment__c[] spList = [
            Select
                Id,
                Drawdown__c,
                Notes__c, 
                Banking_Verified__c,
                BIA_PPSA_LL_Verified__c,
                Credit_Verified__c,
                Documents_Verified__c,
                Status__c
            From Scheduled_Payment__c
        ];

        Test.startTest();
        Payment_Rejection__c pr = new Payment_Rejection__c(
            Scheduled_Payment__c=spList[0].Id,
            Scheduled_Payment_Action__c='Set to Rejected',
            Reason__c='Rejected'
        );
        insert pr;
        Test.stopTest();

        Drawdown__c[] ddList = [
            Select 
                Id,
                Opportunity__c,
                Scheduled_Payment__c,
                Amount__c,
                CHQ__c,
                Date__c,
                EFT__c,
                Opportunity_Service_Provider__c,
                Payment_Method__c,
                Reference_Notes__c
            From Drawdown__c
            Order By CreatedDate
        ];

        System.assertEquals(ddList[0].Opportunity__c, ddList[1].Opportunity__c);
        System.assertEquals(ddList[0].Scheduled_Payment__c, ddList[1].Scheduled_Payment__c);
        System.assertEquals(0 - ddList[0].Amount__c, ddList[1].Amount__c);
        System.assertEquals(ddList[0].CHQ__c, ddList[1].CHQ__c);
        System.assertEquals(ddList[0].Date__c, ddList[1].Date__c);
        System.assertEquals(ddList[0].EFT__c, ddList[1].EFT__c);
        System.assertEquals(ddList[0].Opportunity_Service_Provider__c, ddList[1].Opportunity_Service_Provider__c);
        System.assertEquals('Payment Rejected', ddList[1].Reference_Notes__c);

        spList = [
            Select
                Id,
                Drawdown__c,
                Notes__c, 
                Banking_Verified__c,
                BIA_PPSA_LL_Verified__c,
                Credit_Verified__c,
                Documents_Verified__c,
                Status__c
            From Scheduled_Payment__c
        ];

        System.assertEquals(1, spList.size(), 'There should only be one scheduled payment');
        System.assertEquals(false, spList[0].Banking_Verified__c);
        System.assertEquals(false, spList[0].BIA_PPSA_LL_Verified__c);
        System.assertEquals(false, spList[0].Credit_Verified__c);
        System.assertEquals(false, spList[0].Documents_Verified__c);
        System.assertEquals(null, spList[0].Drawdown__c);
        System.assert(spList[0].Notes__c.startsWith('Rejected'));
        System.assertEquals('Rejected', spList[0].Status__c);
    }
}
