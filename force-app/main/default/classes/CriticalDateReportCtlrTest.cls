@isTest
public with sharing class CriticalDateReportCtlrTest {
    
    //@TestSetup
    static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', Business_Unit__c = 'ELFI',
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
        Date dt = Date.today();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = dt.addDays(i), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Partial Payment'));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    public static void insertCriticalDates(String accountId){
        List<Critical_Date__c> criticalDateList = new List<Critical_Date__c>();
        Date dt = Date.today();
        for(Integer i=0; i < 5; i++){
            criticalDateList.add(new Critical_Date__c(Date__c = dt.addDays(i), Account__c = accountId, Name__c = 'Examination'));
        }
        if(criticalDateList.size() > 0){
            insert criticalDateList;
        }
    }
    
    @isTest
    static void startTestProcess(){
        Test.setMock(HttpCalloutMock.class, new SendCustomerDataToBirdEyeMock());
        initailizeTestData();
        Test.startTest();
        system.assertEquals(1, CriticalDateReportCtlr.getCriticalDateList(''+Date.today(), ''+Date.today(), 'ELFI').size()) ;
        CriticalDateReportCtlr.getCriticalDateList(''+Date.today(), ''+Date.today(), 'ELFI');
        CriticalDateReportCtlr.getCriticalDateList(''+Date.today(), ''+Date.today(), 'Rhino');
        CriticalDateReportCtlr.getCriticalDateList(''+Date.today(), ''+Date.today(), 'Consolidated');
        CriticalDateReportCtlr.getCriticalDateNames(''+Date.today(), ''+Date.today().addDays(6), 'ELFI');
        CriticalDateReportCtlr.getCriticalDateNames(''+Date.today(), ''+Date.today().addDays(6), 'Rhino');
        CriticalDateReportCtlr.getCriticalDateNames(''+Date.today(), ''+Date.today().addDays(6), 'Consolidated');
        CriticalDateReportCtlr.getCustomSetting();
        
        CriticalDateReportCtlr.getPickListValues('Account', 'Business_Unit__c');
        
        CriticalDateReportCtlr.saveBusinessUnitCustomSettings('ELFI');
        
        Date dt = Date.today();
        try{
            CriticalDateReportCtlr.saveDateCustomSettings('' + dt, '' + dt);
        }catch(exception e){
            system.debug(e.getMessage() + ' -- ' + e.getStackTraceString() );
        }
        
        Account acc = [Select Id FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        CriticalDateReportCtlr.createNewNote(acc.Id, 'Text');
        Critical_Date__c cd = CriticalDateReportCtlr.printReport(''+Date.today(), ''+Date.today().addDays(6), 'ELFI');
        system.assertNotEquals(null, cd);
        
        CriticalDateReportCtlr.executeBatchJob(String.valueOf(Date.today()), String.valueOf(Date.today()));
        CriticalDateReportCtlr.getBatchJobStatus();
        CriticalDateReportCtlr.validateReport(String.valueOf(Date.today()), String.valueOf(Date.today()));
        
        Test.stopTest();
    }
}