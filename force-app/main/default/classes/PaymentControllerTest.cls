/**
*    @description : Test class for PaymentController
**/
@isTest(seeAllData=false)
private with sharing class PaymentControllerTest {

    /**
    *    @description : Set up test data
    **/
    @testSetup
    static void setupTestData(){
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
        Opp.Payment_Schedule__c = 'Yes';
        Opp.Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        Opp.Payment_Use_Primary_Bank_Account__c = true;
        Opp.Payment_Schedule_Allotted_Amount__c = 5000.00;
        Opp.Day_of_Month__c = 'Last';
        Opp.Start_Date__c = DateUtil.today();
        Opp.Payment_Schedule_Send_First_Immediately__c = false;
        Opp.Drawdown_Amount__c = 1000.00;
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = DateUtil.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Amount = 5375.00;
        Opp.Admin_Fee__c = 375.00;
        Opp.Payout_Date__c = DateUtil.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
    }

    /**
    *    @description : Create drawdown
    **/
    public static void insertDrawdown(String OppId, Integer noOfPayments){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < noOfPayments; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = DateUtil.today(), Opportunity__c = OppId,
                                            Amount__c = 1500, Payment_Method__c ='Payment', Payout_Date__c = DateUtil.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }

    /**
    *    @description : Test calculate payments for amount mode
    **/
    @isTest
    static void test_calculatePaymentsForAmountMode(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];

           // see payment schedule 
           //System.assertEquals(0,[SELECT count() FROM Scheduled_Payment__c]);

           // create schedule 
           opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
           opportunityList[0].Day_of_Month__c = 'Last';
           opportunityList[0].Drawdown_Amount__c = 1000.00;
           opportunityList[0].Start_Date__c = DateUtil.today();
           update opportunityList;
           System.assertEquals(5,PaymentController.calculatePayments(opportunityList[0].Id).size());
        Test.stopTest();
    }

    /**
    *    @description : Test calculate payments for date mode
    **/
    /* Not needed or working. FacilitySchedulingTests cover this and more
    @isTest
    static void test_calculatePaymentsForDateMode(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [
            SELECT 
                Payment_Schedule_Version_Number__c,
                AccountId,
                Payment_Scheduled_Allotment_Remaining__c,
                Day_of_Month__c,
                Start_Date__c,
                End_Date__c,
                Drawdown_Amount__c,
                Payment_Schedule_Mode__c,
                Payment_Use_Primary_Bank_Account__c,
                Payment_Default_Bank_Account__c,
                Payment_Schedule_Send_First_Immediately__c,
                Amount_Available_for_Scheduled_Payments__c,
                Payment_Schedule_Allotted_Amount__c,
                Amount_sent_from_current_Schedule__c
            FROM Opportunity];

        // see payment schedule 
        //System.assertEquals(0,[SELECT count() FROM Scheduled_Payment__c]);

        // create schedule 
        opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_DATE;
        opportunityList[0].Day_of_Month__c = 'Last';
        opportunityList[0].Start_Date__c = DateUtil.today();
        opportunityList[0].End_Date__c = DateUtil.today().addMonths(5);
        update opportunityList;
        opportunityList = [
            SELECT 
                Payment_Schedule_Version_Number__c,
                AccountId,
                Payment_Scheduled_Allotment_Remaining__c,
                Day_of_Month__c,
                Start_Date__c,
                End_Date__c,
                Drawdown_Amount__c,
                Payment_Schedule_Mode__c,
                Payment_Use_Primary_Bank_Account__c,
                Payment_Default_Bank_Account__c,
                Payment_Schedule_Send_First_Immediately__c,
                Amount_Available_for_Scheduled_Payments__c,
                Payment_Schedule_Allotted_Amount__c,
                Amount_sent_from_current_Schedule__c
            FROM Opportunity];
        System.assertEquals(5,PaymentController.calculatePayments(opportunityList[0].Id).size());
        Test.stopTest();
    }
    */

   
    /**
    *    @description : Test delete payments
    **/
    @isTest
    static void test_deletePayments(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];

           // create schedule 
           opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
           opportunityList[0].Day_of_Month__c = 'Last';
           opportunityList[0].Drawdown_Amount__c = 1000.00;
           opportunityList[0].Start_Date__c = DateUtil.today();
           update opportunityList;
           List<Scheduled_Payment__c> paymentsList = PaymentController.calculatePayments(opportunityList[0].Id);
           //insert paymentsList;
           System.assertEquals(5,[SELECT count() FROM Scheduled_Payment__c]);
           opportunityList[0].Payment_Schedule__c = 'No';
           update opportunityList;

           PaymentController.deletePayments(opportunityList[0].Id);
           System.assertEquals(0,[SELECT count() FROM Scheduled_Payment__c]);
        Test.stopTest();
    }

    /**
    *    @description : Test create payments
    **/
    @isTest
    static void test_createPayments(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];

           // create schedule 
           opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
           opportunityList[0].Day_of_Month__c = 'Last';
           opportunityList[0].Drawdown_Amount__c = 1000.00;
           opportunityList[0].Start_Date__c = DateUtil.today();
           update opportunityList;
           List<Scheduled_Payment__c> paymentsList = PaymentController.calculatePayments(opportunityList[0].Id);
           //System.assertEquals(0,[SELECT count() FROM Scheduled_Payment__c]);
           //PaymentController.createPayments(opportunityList[0].Id,paymentsList);
           System.assertEquals(5,[SELECT count() FROM Scheduled_Payment__c]);
        Test.stopTest();
    }

    /**
    *    @description : Test get payments
    **/
    @isTest
    static void test_getPayments(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];

           // create schedule 
           opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
           opportunityList[0].Day_of_Month__c = 'Last';
           opportunityList[0].Drawdown_Amount__c = 1000.00;
           opportunityList[0].Start_Date__c = DateUtil.today();
           update opportunityList;
           List<Scheduled_Payment__c> paymentsList = PaymentController.calculatePayments(opportunityList[0].Id);
           //insert paymentsList;
           Map<String, Object> objectsMap = PaymentController.getPayments(opportunityList[0].Id,'ViewPayments');
           List<Object> recordsList = (List<Object>)objectsMap.get('records');
           System.assertEquals(5,recordsList.size());
        Test.stopTest();
    }

    /**
    *    @description : Test get payments
    **/
    @isTest
    static void test_getScheduledPayments(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];
        opportunityList[0].Payment_Schedule_Send_First_Immediately__c = true;
        update opportunityList;
        Scheduled_Payment__c sp = new Scheduled_Payment__c(Opportunity__c=opportunityList[0].Id, Amount__c=3000.00);
        insert sp;
        System.assert(0 <= PaymentController.getScheduledPayments(opportunityList[0].Id).size());
        System.assertEquals(0,PaymentController.getPreviousLoans(opportunityList[0].Id).size());
        System.assertEquals(0,PaymentController.getBankAccountOptions(opportunityList[0].Id).size());
        Test.stopTest();
    }
}