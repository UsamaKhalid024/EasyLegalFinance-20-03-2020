@isTest
public with sharing class Batch_MergeAdminFeeWithOpptyDrawdownTest {
    
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
        for(Integer i=0; i < 3; i++){
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
                                        Interest_Compounding_Period__c = 'Simple Interest',
                                        Interest_Deferral_Period__c = '0',
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
        Test.startTest();
        Batch_MergeAdminFeeWithOpptyDrawdown.ProcessAll(2000);
        
        List<Opportunity> oppties = [Select id ,
                                     (Select Amount__c,Admin_Fee__c, Reference_Notes__c , Payment_Method__c
                                      From Drawdowns__r
                                      Order by Date__c asc)
                                     from Opportunity];
        for(Opportunity opp : oppties){
            for(Drawdown__c d : opp.Drawdowns__r){
                if(d.Reference_Notes__c != 'Admin Fee'){
                    system.assertEquals(475.00, d.Admin_Fee__c);
                }
            }
        }
                
        Test.stopTest();
        
        
    }
}