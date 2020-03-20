@isTest
public with sharing class DrawdownTriggerHandlerTest {
    
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
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        Date dt = Date.today();
        Critical_Date__c cd = new Critical_Date__c(Date__c = dt.addDays(1), Account__c = accountList[0].Id, Name__c = 'Examination');
        insert cd;        
    }
    
    public static void insertDrawdown(){
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        String OppId = clientOpportunity.Id;
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 2; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    public static testMethod void validatePaymentChangeInsertTest(){
        insertDrawdown();        
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        insertDrawdown();
        Test.stopTest();
    }
    
    public static testMethod void validatePaymentChangeUpdateTest(){
        insertDrawdown();
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Drawdown__c> dlist = [SELECT Id, Date__c, Amount__c, Payment_Method__c FROM Drawdown__c];
        dlist[0].Amount__c = 3851;
        dlist[1].Payment_Method__c = 'Admin Fee';
        dlist[1].Reference_Notes__c = 'Admin Fee';
        //dlist[2].Date__c = Date.today();
        update dlist;
        Test.stopTest();
    }

    public static testMethod void validatePaymentDeleteTest(){
        insertDrawdown();
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Drawdown__c> dlistOriginal = new List<Drawdown__c>();
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 2000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client'));
        insert dlistOriginal;
        List<Drawdown__c> dlistUpdated = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where id =: dlistOriginal[0].id];
        system.assertEquals(2000, dlistUpdated[0].Sum_of_Repayments__c,'Payments should be fully allocated to Drawdown');

        // delete the payment with an allocation
        List<Drawdown__c> dlistPayment = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Payment_Allocations__c  FROM Drawdown__c where Payment_Method__c = 'Payment' AND Sum_of_Payment_Allocations__c > 0];
        delete dlistPayment;   

        dlistUpdated = [SELECT Id, Date__c, Amount__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where id =: dlistOriginal[0].id];
        system.assertEquals(0, dlistUpdated[0].Sum_of_Repayments__c,'Payments Allocated should again be zero.');

        delete dlistUpdated; // for good measure make sure the original drawdown can be deleted too.

        Test.stopTest();
    }
    
    public static testMethod void createAdminFeeRejectionsTest(){
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Drawdown__c> dlistOriginal = new List<Drawdown__c>();
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 2000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client'));
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 475, Payment_Method__c ='Admin Fee', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Admin Fee'));
        
        insert dlistOriginal;        
        Test.startTest();        
        List<Drawdown__c> dlistUpdated = [SELECT Id, Date__c, Amount__c, Admin_Fee__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where Admin_Fee__c != NULL];
        System.debug('Updated ' + dlistUpdated.get(0).Id + ' ' + dlistUpdated.get(0).Amount__c + ' ' + dlistUpdated.get(0).Admin_Fee__c);
        Drawdown__c rejectionDrawdown = new Drawdown__c();
        rejectionDrawdown.Opportunity__c = dlistOriginal.get(0).Opportunity__c;        
        rejectionDrawdown.Payment_Method__c = 'Payment';  
        rejectionDrawdown.Reference_Notes__c = 'Payment Rejected';
        rejectionDrawdown.Reason_to_Reverse_Payment__c = 'Client Error';
        rejectionDrawdown.Amount__c = dlistOriginal.get(0).Amount__c;
        rejectionDrawdown.Principal_Reversed__c = dlistOriginal.get(0).Amount__c;
        rejectionDrawdown.Date__c = dlistOriginal.get(0).Date__c;
        rejectionDrawdown.Payment_To_Reverse__c = dlistUpdated.get(0).Id;
        insert rejectionDrawdown;        
        List<Drawdown__c> adminFeeRejections = [SELECT Id, Date__c, Amount__c, Payment_Method__c, Payment_To_Reverse__c  FROM Drawdown__c where Reference_Notes__c='Payment Rejected' and Payment_To_Reverse__c=:dlistOriginal.get(1).Id];        
        System.assertEquals(1, adminFeeRejections.size());
        System.assertEquals(dlistOriginal.get(1).Amount__c, adminFeeRejections.get(0).Amount__c);

        Test.stopTest();
    }
}
