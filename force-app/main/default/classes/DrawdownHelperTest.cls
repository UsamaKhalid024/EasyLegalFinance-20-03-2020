/**
*    @description : Test class for PaymentController
**/
@isTest(seeAllData=false)
private with sharing class DrawdownHelperTest {
    

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
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Amount = 5000.00;
        Opp.Payout_Date__c = Date.today();
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
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 1500, Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }

    @isTest
    static void test_getDrawdowns(){
        Test.startTest();
        DrawdownHelper.getDrawdowns('all', null, null);
        Test.stopTest();
    }
    public static testMethod void getDrawdownTest(){
        List<Opportunity> opps = [select Id from Opportunity];
        insertDrawdown(opps.get(0).Id, 1);
        List<Drawdown__c> drs = [select Id from Drawdown__c];
        Test.startTest();
        Drawdown__c d = DrawdownHelper.getDrawdown(drs.get(0).Id);
        System.assertEquals(drs.get(0).Id, d.Id);
        Test.stopTest();
    }
    
    public static testMethod void updateOpportunityPayoutDateTest(){        
        Test.startTest();
		List<Opportunity> opps = [select Id, Payout_Date__c from Opportunity];
        Date dt = opps.get(0).Payout_Date__c.addDays(30);
        DrawdownHelper.updateOpportunityPayoutDate(opps.get(0).Id, dt);
        opps = [select Id, Payout_Date__c from Opportunity];
        System.assertEquals(dt, opps.get(0).Payout_Date__c);        
        Test.stopTest();
    }

     /**
    *    @description : Test recalculate payments 
	// Replaced with process and InvocableMethod callout to consolidate work
    @isTest
    static void test_updatePaymentScheduleForFacilityLoan(){
        Test.startTest();
        // get opportunity 
        List<Opportunity> opportunityList = [SELECT Id, Payment_Schedule_Mode__c, Drawdown_Amount__c, Start_Date__c, End_Date__c, Day_of_Month__c FROM Opportunity];

        // see payment schedule 
        System.assertEquals(0,[SELECT count() FROM Scheduled_Payment__c]);

        // create schedule 
        opportunityList[0].Payment_Schedule_Mode__c = Constants.PAYMENT_MODE_AMOUNT;
        opportunityList[0].Day_of_Month__c = 'Last';
        opportunityList[0].Drawdown_Amount__c = 1000.00;
        opportunityList[0].Start_Date__c = System.today();
        update opportunityList;
        List<Scheduled_Payment__c> paymentsList = PaymentController.calculatePayments(opportunityList[0].Id);
        insert paymentsList;

        System.assertEquals(5,paymentsList.size());

        // create drawdwon for adhoc payment
        insertDrawdown(opportunityList[0].Id,1);
        update [SELECT Id FROM Drawdown__c];
        System.assertEquals(4,[SELECT count() FROM Scheduled_Payment__c]);
        Test.stopTest();
    }
    **/
}
