@isTest
public class PaymentAllocatorTest {
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
                                        //Payout_Date__c = Date.newInstance(2018,01,01),
                                        Payout_Date__c = Date.today().addDays(30),
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
    }
    public static void insertDrawdowns(List<Opportunity> oppList){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Opportunity opp : oppList){
            
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2018,01,01), Opportunity__c = opp.Id,
                                             Amount__c = 2000, Payment_Method__c ='Payment', Payout_Date__c = Date.newInstance(2018,01,01),
                                             Reference_Notes__c = 'Partial Payment'));            
            
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.newInstance(2018,01,01), Opportunity__c = opp.Id,
                                             Amount__c = 475, Payment_Method__c ='Admin Fee', Payout_Date__c = Date.newInstance(2018,01,01),
                                             Reference_Notes__c = 'Admin Fee'));        
            
        }
        
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    public static testMethod void batchMergeAdminFeeWithOpptyDrawdownTest(){
        List<Opportunity> opps = [select Id from Opportunity];
        insertDrawdowns(opps);
        Test.startTest();        
        List<Id> drawdownIds = new List<Id>();
        for(Drawdown__c d :[select Id from Drawdown__c]){
            drawdownIds.add(d.Id);
        }
        PaymentAllocator.AllocatePayments(drawdownIds);
        
        Test.stopTest();                
    }
    
    public static testMethod void allocateRejectionsClientErrorTest(){
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity 0' LIMIT 1];
        List<Drawdown__c> dlistOriginal = new List<Drawdown__c>();
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 2000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.today().addDays(30),
                                            Reference_Notes__c = 'Payment to Client'));
        insert dlistOriginal;        
        Test.startTest();        
        List<Drawdown__c> dlistUpdated = [SELECT Id, Date__c, Amount__c, Admin_Fee__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c];
        //System.debug('Updated ' + dlistUpdated.get(0).Id + ' ' + dlistUpdated.get(0).Amount__c + ' ' + dlistUpdated.get(0).Admin_Fee__c);
        Drawdown__c rejectionDrawdown = new Drawdown__c();
        rejectionDrawdown.Opportunity__c = dlistOriginal.get(0).Opportunity__c;        
        rejectionDrawdown.Payment_Method__c = 'Payment';  
        rejectionDrawdown.Reference_Notes__c = 'Payment Rejected';
        rejectionDrawdown.Reason_to_Reverse_Payment__c = 'Client Error';
        rejectionDrawdown.Amount__c = dlistOriginal.get(0).Amount__c;
        rejectionDrawdown.Principal_Reversed__c = dlistOriginal.get(0).Amount__c;
        rejectionDrawdown.Date__c = dlistOriginal.get(0).Payout_Date__c;
        rejectionDrawdown.Payment_To_Reverse__c = dlistUpdated.get(0).Id;
        insert rejectionDrawdown;        
        List<Drawdown__c> rejections = [SELECT Id, Date__c, Amount__c, Payment_Method__c, Principal_Repaid__c, Interest_Repaid__c  FROM Drawdown__c where Reference_Notes__c='Payment Rejected' and Payment_To_Reverse__c=:dlistOriginal.get(0).Id];        
        System.assertEquals(1, rejections.size());
        System.assertEquals(dlistUpdated.get(0).Amount__c, rejections.get(0).Principal_Repaid__c);
        System.assertEquals(0.0, rejections.get(0).Interest_Repaid__c);
        List<Drawdown__c> advanceDrawdown = [SELECT Id, Date__c, Amount__c, Admin_Fee__c, Payment_Method__c,Sum_of_Repayments__c  FROM Drawdown__c where Payment_Method__c ='e-Transfer'];
		System.assertEquals(advanceDrawdown.get(0).Sum_of_Repayments__c, rejections.get(0).Principal_Repaid__c);                                             
        //System.assertEquals(dlistOriginal.get(1).Amount__c, adminFeeRejections.get(0).Amount__c);

        Test.stopTest();
    }

    public static testMethod void allocateRejectionsELFIErrorTest(){
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity 0' LIMIT 1];
        List<Drawdown__c> dlistOriginal = new List<Drawdown__c>();
        dlistOriginal.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = clientOpportunity.id,
                                            Amount__c = 2000, Payment_Method__c ='e-Transfer', Payout_Date__c = Date.today().addDays(30),
                                            Reference_Notes__c = 'Payment to Client'));
        insert dlistOriginal;        
        Test.startTest();        
        List<Drawdown__c> dlistUpdated = [SELECT Id, Date__c, Amount__c, Admin_Fee__c, Payment_Method__c,Sum_of_Repayments__c, Payout_Date__c, Outstanding_Balance_as_of_Payout_Date__c  FROM Drawdown__c];
        System.debug('Updated ' + dlistUpdated.get(0).Id + ' ' + dlistUpdated.get(0).Amount__c + ' ' + dlistUpdated.get(0).Outstanding_Balance_as_of_Payout_Date__c);
        Drawdown__c rejectionDrawdown = new Drawdown__c();
        rejectionDrawdown.Opportunity__c = dlistOriginal.get(0).Opportunity__c;        
        rejectionDrawdown.Payment_Method__c = 'Payment';  
        rejectionDrawdown.Reference_Notes__c = 'Payment Rejected';
        rejectionDrawdown.Reason_to_Reverse_Payment__c = 'ELFI Error';
        rejectionDrawdown.Amount__c = dlistUpdated.get(0).Outstanding_Balance_as_of_Payout_Date__c;
        rejectionDrawdown.Principal_Reversed__c = dlistOriginal.get(0).Amount__c;
        rejectionDrawdown.Date__c = dlistOriginal.get(0).Payout_Date__c;
        rejectionDrawdown.Payment_To_Reverse__c = dlistUpdated.get(0).Id;
        insert rejectionDrawdown;        
        List<Drawdown__c> rejections = [SELECT Id, Date__c, Amount__c, Payment_Method__c, Principal_Repaid__c, Interest_Repaid__c  FROM Drawdown__c where Reference_Notes__c='Payment Rejected' and Payment_To_Reverse__c=:dlistOriginal.get(0).Id];        
        System.assertEquals(1, rejections.size());
        System.assertEquals(dlistUpdated.get(0).Amount__c, rejections.get(0).Principal_Repaid__c);        
        List<Drawdown__c> advanceDrawdown = [SELECT Id, Date__c, Amount__c, Admin_Fee__c, Payment_Method__c,Sum_of_Repayments__c, Outstanding_Balance_as_of_Payout_Date__c  FROM Drawdown__c where Payment_Method__c ='e-Transfer'];
		System.assertEquals(advanceDrawdown.get(0).Sum_of_Repayments__c, rejections.get(0).Principal_Repaid__c + rejections.get(0).Interest_Repaid__c);                                             
        System.assertEquals(0.0, advanceDrawdown.get(0).Outstanding_Balance_as_of_Payout_Date__c);                                             
        //System.assertEquals(dlistOriginal.get(1).Amount__c, adminFeeRejections.get(0).Amount__c);

        Test.stopTest();
    }
    
}
