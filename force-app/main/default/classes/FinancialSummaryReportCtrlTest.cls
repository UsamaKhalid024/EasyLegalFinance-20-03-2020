@isTest
public class FinancialSummaryReportCtrlTest {
	
   // @TestSetup
    static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', Business_Unit__c = 'ELFI',ProvinceResidency__c = 'Ontario',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', Business_Unit__c = 'ELFI',ProvinceResidency__c = 'Ontario',
                                             RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm', Business_Unit__c = 'ELFI',
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
        Opp.Stage_Status__c = 'Active';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        
        insertDrawdowns(Opp.Id);
    }
    
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 4; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50), Payment_Method__c ='Cheque', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Payment to Client',Interest_Rate__c = 10));
        }
        if(drawdownList.size() > 0){
            insert (new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 1500, Payment_Method__c ='Payment',
                                            Reference_Notes__c = 'Partial Payment'));
            insert drawdownList;
            insertDrawdownPaymentAllocations(drawdownList, OppId);
        }
    }
    public static void insertDrawdownPaymentAllocations(List<Drawdown__c> drawdownList, String OppId){
        List<Drawdown_Payment_Allocation__c> drawdownPAList = new List<Drawdown_Payment_Allocation__c>();
        
        for(Drawdown__c dd : drawdownList){
            drawdownPAList.add(new Drawdown_Payment_Allocation__c(Drawdown__c = dd.Id, Opportunity__c = OppId,
                                                                 Transaction_Date__c = Date.today(), Payment__c = dd.Id));
        }
        insert drawdownPAList;
    }
    
    public static testmethod void mainTest(){
        
        Test.setMock(HttpCalloutMock.class, new SendCustomerDataToBirdEyeMock());
        initailizeTestData();
        Test.startTest();
        list<FinancialSummaryReportCtrl.Wrapper> result = FinancialSummaryReportCtrl.getReportDataByProvince(String.valueOf(Date.today()), String.valueOf(Date.today()), 'ELFI');
        system.assertEquals(1, result.size());
        
        FinancialSummaryReportCtrl.FinancialReportDataWrapper financials = FinancialSummaryReportCtrl.getFinancialReportData(String.valueOf(Date.today()), String.valueOf(Date.today()), 'ELFI');
        FinancialSummaryReportCtrl.getCustomSetting();
        FinancialSummaryReportCtrl.getPickListValues('Account', 'Business_Unit__c');
        FinancialSummaryReportCtrl.saveBusinessUnitCustomSettings('ELFI');
        
        Date dt = Date.today();
        try{
            FinancialSummaryReportCtrl.saveDateCustomSettings('' + dt, '' + dt);
        }catch(exception e){
            system.debug(e.getMessage() + ' -- ' + e.getStackTraceString() );
        }
        
        
        
        FinancialSummaryReportCtrl.executeBatchJob(true,String.valueOf(Date.today()), String.valueOf(Date.today()));
        FinancialSummaryReportCtrl.getBatchJobStatus();
        FinancialSummaryReportCtrl.validateReport(String.valueOf(Date.today()), String.valueOf(Date.today()));
        
        
        Test.stopTest();
    }
}