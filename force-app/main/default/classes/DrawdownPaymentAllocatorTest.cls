@isTest
public class DrawdownPaymentAllocatorTest {
@TestSetup
    static void initailizeTestData(){        
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
        
        List<Opportunity> oppList = new List<Opportunity>();        
        for(Integer i=0; i < 1; i++){
            oppList.add(new Opportunity(AccountId = accountList[0].Id,
                                        Name = 'Test Opportunity ' + i,
                                        Lawyer__c = contactList[1].Id,
                                        CloseDate = Date.today().addDays(14),
                                        StageName = 'Closed With Loan',
                                        Law_Firm__c = accountList[1].Id,
                                        Stage_Status__c = 'Approved',
                                        Payout_Date__c = Date.newInstance(2018,01,01),
                                        Type_of_Loan__c = 'Facility Loan',
                                        Primary_Contact__c = contactList[0].Id,
                                        Minimum_Interest_Period__c = '0 months',
                                        Compounding_Interest__c = 'Monthly',
                                        Interest_Compounding_Period__c = 'Compounding Interest',
                                        Interest_Rate__c = 15.0,
                                        RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId()
                                       ));
            
        }                
        insert oppList;        
        insertDrawdowns(oppList);
    }
    public static void insertDrawdowns(List<Opportunity> oppList){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Opportunity opp : oppList){
            
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2018,01,01), Opportunity__c = opp.Id,
                                             Amount__c = 10000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.newInstance(2018,01,01),
                                             Reference_Notes__c = 'Payment to Client')); 
            
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2018,01,01), Opportunity__c = opp.Id,
                                             Amount__c = 2000, Payment_Method__c ='Payment', Payout_Date__c = Date.newInstance(2018,01,01),
                                             Reference_Notes__c = 'Partial Payment'));            
            
        }
        
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    public static testMethod void testUpdatePayoutDateOnInsert(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        Date dt = Date.newInstance(2019,01,01);
        Opportunity opp = opps[0];
        //for (Opportunity opp : opps)
        {
            Drawdown__c drawdown = new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = dt, Opportunity__c = opp.Id,
                                             Amount__c = 2000, Payment_Method__c ='Payment', Payout_Date__c = Date.newInstance(2018,01,01),
                                             Reference_Notes__c = 'Partial Payment');
            drawdowns.add(drawdown);
        }
        insert drawdowns;
        opps = [select Id, Payout_Date__c from Opportunity];        
        System.assertEquals(false, opps.isEmpty() );
    	opp = opps[0];
        //for (Opportunity opp : opps)
        {
            System.assertEquals(dt, opp.Payout_Date__c);
        }
        Test.stopTest();
    }
    public static testMethod void testUpdatePayoutDateOnUpdate(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = [select Id, Date__c, Opportunity__c from Drawdown__c where Payment_Method__c='Payment' LIMIT 2];
        List<Id> oppIds = new List<Id>();
        System.assertEquals(false, drawdowns.isEmpty() );
        Date dt = Date.newInstance(2019,01,01);
        for (Drawdown__c drawdown : drawdowns){
            drawdown.Date__c = dt;
            oppIds.add(drawdown.Opportunity__c);
        }        
        update drawdowns;
        opps = [select Id, Payout_Date__c from Opportunity where Id in :oppIds];        
        System.assertEquals(false, opps.isEmpty() );
        for (Opportunity opp : opps){
            System.assertEquals(dt, opp.Payout_Date__c);
        }
        Test.stopTest();
    }
    
    public static testMethod void testDeletePaymentAllocationsOnAmountChange(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = [select Id, Date__c, Amount__c from Drawdown__c where Payment_Method__c='Payment' LIMIT 1];
        System.assertEquals(false, drawdowns.isEmpty() );
        List<Drawdown_Payment_Allocation__c> paymentAllocations = [select Id, payment__c from Drawdown_Payment_Allocation__c];
        System.assertEquals(false, paymentAllocations.isEmpty() );
        drawdowns[0].Amount__c = drawdowns[0].Amount__c + 1;
        List<Id> updatedIDs = new List<Id>();
        updatedIDs.add(drawdowns[0].Id);
        paymentAllocations = [select Id from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];    
        System.assertEquals(false, paymentAllocations.isEmpty() );                
        update drawdowns;
        List<Drawdown_Payment_Allocation__c> paymentAllocationsAfterUpdate = [select Id, Payment__c from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];
    	System.assertEquals(false, paymentAllocationsAfterUpdate.isEmpty() );        
        System.assertNotEquals(paymentAllocationsAfterUpdate[0], paymentAllocations[0]);

        Test.stopTest();
    }
    
    public static testMethod void testDeletePaymentAllocationsOnPaymentMethodChange(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = [select Id, Date__c, Amount__c from Drawdown__c where Payment_Method__c='Payment' LIMIT 1];
        System.assertEquals(false, drawdowns.isEmpty() );
        List<Drawdown_Payment_Allocation__c> paymentAllocations = [select Id, payment__c from Drawdown_Payment_Allocation__c];
        System.assertEquals(false, paymentAllocations.isEmpty() );
        drawdowns[0].Payment_Method__c = 'e-Transfer';
        List<Id> updatedIDs = new List<Id>();
        updatedIDs.add(drawdowns[0].Id);
        paymentAllocations = [select Id from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];    
        System.assertEquals(false, paymentAllocations.isEmpty() );                
        update drawdowns;
        List<Drawdown_Payment_Allocation__c> paymentAllocationsAfterUpdate = [select Id, Payment__c from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];
    	System.assertEquals(true, paymentAllocationsAfterUpdate.isEmpty() );        
        Test.stopTest();
    }
    
    public static testMethod void testDeletePaymentAllocationsOnDateChange(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = [select Id, Date__c, Amount__c from Drawdown__c where Payment_Method__c='Payment' LIMIT 1];
        System.assertEquals(false, drawdowns.isEmpty() );
        List<Drawdown_Payment_Allocation__c> paymentAllocations = [select Id, payment__c from Drawdown_Payment_Allocation__c];
        System.assertEquals(false, paymentAllocations.isEmpty() );
        drawdowns[0].Date__c = Date.newInstance(2019, 1, 1);
        List<Id> updatedIDs = new List<Id>();
        updatedIDs.add(drawdowns[0].Id);
        paymentAllocations = [select Id from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];    
        System.assertEquals(false, paymentAllocations.isEmpty() );                
        update drawdowns;
        List<Drawdown_Payment_Allocation__c> paymentAllocationsAfterUpdate = [select Id, Payment__c from Drawdown_Payment_Allocation__c where payment__c in :updatedIDs];
    	System.assertEquals(false, paymentAllocationsAfterUpdate.isEmpty() );        
        System.assertNotEquals(paymentAllocationsAfterUpdate[0], paymentAllocations[0]);

        Test.stopTest();
    }

    
    public static testMethod void testRemoveLoanSetup(){
        Test.startTest();
        List<Opportunity> opps = [select Id from Opportunity];
        List<Drawdown__c> drawdowns = [select Id, Date__c, Amount__c from Drawdown__c where Payment_Method__c='Payment'];        
        for (Drawdown__c drawdown : drawdowns){
            drawdown.Interest_Rate__c = 24;
            drawdown.Compounding_Interest__c = true;
            drawdown.Compounding_Frequency__c = 2.0;
        }                
        update drawdowns;
        drawdowns = [select Id, Compounding_Frequency__c, Compounding_Interest__c, Interest_Deferral_Period__c, Interest_Rate__c, 
                     Minimum_Interest_Period__c, Payout_Date__c, Temp_Payout_Date__c from Drawdown__c where Payment_Method__c='Payment'];        
        for (Drawdown__c drawdown : drawdowns){
            System.assertEquals(null, drawdown.Compounding_Frequency__c);
            System.assertEquals(false, drawdown.Compounding_Interest__c);
            System.assertEquals(null, drawdown.Interest_Deferral_Period__c);            
            System.assertEquals(null, drawdown.Interest_Rate__c);            
            System.assertEquals(null, drawdown.Minimum_Interest_Period__c);            
            System.assertEquals(null, drawdown.Payout_Date__c);            
            System.assertEquals(null, drawdown.Temp_Payout_Date__c);
        }
        Test.stopTest();
    }
    
    public static testMethod void testAllocatePayments(){
        Test.startTest();
        List<Drawdown__c> drawdowns = [select Id from Drawdown__c where Payment_Method__c='Payment']; 
        List<Id> drawdownIds = new List<Id>();
        for (Drawdown__c d : drawdowns){
            drawdownIds.add(d.Id);
        }
        List<Drawdown_Payment_Allocation__c> paymentAllocations = [select Id, payment__c from Drawdown_Payment_Allocation__c where Payment__c in :drawdownIds];
        System.assertEquals(false, paymentAllocations.isEmpty());
        System.assertEquals(paymentAllocations.size(), drawdowns.size());
        Test.stopTest();
    }
    
    public static testMethod void testClearAllocationFlag(){
        Test.startTest();
        List<Drawdown__c> drawdowns = [select Id, Allocate_Payment__c from Drawdown__c where Payment_Method__c='Payment' LIMIT 2]; 
        List<Id> drawdownIds = new List<Id>();
        for (Drawdown__c d : drawdowns){
            d.Allocate_Payment__c = true;
            drawdownIds.add(d.Id);
        }
        update drawdowns;
        drawdowns = [select Id, Allocate_Payment__c from Drawdown__c where Payment_Method__c='Payment' and Id in :drawdownIds];
        for (Drawdown__c d : drawdowns){
            System.assertEquals(false, d.Allocate_Payment__c);
        }
        Test.stopTest();
    }

    
}
