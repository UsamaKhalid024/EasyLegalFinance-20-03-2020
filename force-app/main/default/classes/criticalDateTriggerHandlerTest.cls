@isTest
public with sharing class criticalDateTriggerHandlerTest {
	
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
        
        insertDrawdown(Opp.Id);
        insertCriticalDates(accountList[0].Id); 
    }
    
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId, Compounding_Interest__c = false,
                                            Amount__c = 2000 + (i * 50), Interest_Rate__c = 24.5, Compounding_Frequency__c = 2, Payment_Method__c ='e-Transfer', 
                                            Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    public static void insertCriticalDates(String accountId){
        List<Critical_Date__c> criticalDateList = new List<Critical_Date__c>();
        Date dt = Date.today();
        for(Integer i=0; i < 2; i++){
            criticalDateList.add(new Critical_Date__c(Date__c = dt.addDays(i), Account__c = accountId, Name__c = 'Examination'));
        }
        if(criticalDateList.size() > 0){
            insert criticalDateList;
        }
    }
    
    @isTest
    static void startTestProcess(){
        Test.startTest();
        Account acc = [Select Id FROM Account WHERE Name = 'Test Client Account' LIMIT 1];               
        List<Critical_Date__c> cdList = [Select Id FROM Critical_Date__c WHERE Account__c =: acc.Id];
        system.assertEquals(2, cdList.size());
        
        Date dt = Date.today();
        Critical_Date__c cd = cdList[0];
        cd.Date__c = dt.addDays(11); 
              
        upsert cd;
        
        Test.stopTest();
    }
}