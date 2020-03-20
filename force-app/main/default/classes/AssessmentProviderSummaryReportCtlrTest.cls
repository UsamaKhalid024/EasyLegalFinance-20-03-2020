@isTest
public class AssessmentProviderSummaryReportCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', Business_unit__c='ELFI',
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', 
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm',
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test Assessment Provider Account', Authorization_Clause__c = 'No', 
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Assessment Provider').getRecordTypeId()));
        
        insert accountList;
        
        contactList.add( new Contact(LastName = 'Test Client Contact', AccountId = accountList[0].Id,
                                     RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId()));
        contactList.add( new Contact(LastName = 'Test Lawyer Contact', 
                                     AccountId = accountList[1].Id,
                                     RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId(),
                                     Upcoming_Hearings__c='No'));
        insert contactList;
 
        Attachment attach =new Attachment();   	
    	attach.Name='List of Clients';
    	attach.body= Blob.valueOf('Unit Test Attachment Body');
        attach.parentId= accountList[3].Id;
        insert attach;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        opp.Date_Applied__c = Date.today();
        Opp.StageName = 'Loan Approved';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'See Notes';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Assessment';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        Opp.Assessment_Provider__c = accountList[3].Id;
        insert Opp;
        
        insertDrawdowns(Opp.Id);
        
        Opp.Stage_Status__c = 'Bad Debt';
        
        insertDrawdowns(Opp.Id);
        
    }
    
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        
        drawdownList.add(new Drawdown__c(Type__c = 'Assessment', Date__c = Date.today(), Opportunity__c = OppId,
                                         Amount__c = 2000 + (1 * 50), Payment_Method__c ='Cheque', Payout_Date__c = Date.today(),
                                         Reference_Notes__c = 'Loan Payout',Interest_Rate__c = 10));
        
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    static testMethod void test_getAssessments(){
        Test.startTest();
        List<String> businessUnitList = AssessmentProviderSummaryReportCtlr.getPickListValues('Account', 'Business_Unit__c');
        system.assert(businessUnitList.size() > 0);
        
        List<AssessmentProviderSummaryReportCtlr.AssessmentWrapper> assessments = AssessmentProviderSummaryReportCtlr.getAssessmentData('', 'Consolidated', 'Lawyer__r.Name', 'ASC');
        system.assertEquals(1, assessments.size());
        
        Drawdown__c drawdown = AssessmentProviderSummaryReportCtlr.getDrawdown();
        
        Test.stopTest();
    }
    
    static testMethod void test_customSettings(){
        Test.startTest();
        Date dt = Date.today();
        String providerId = [SELECT Id FROM Account WHERE Name = 'Test Assessment Provider Account' LIMIT 1].Id;
        AssessmentProviderSummaryReportCtlr.setCustomSetting(new List<string>{providerId}, dt + '', dt.addDays(5) + '', 'Consolidated');
        Assessment_Provider_Summary_Report__c customSetting = AssessmentProviderSummaryReportCtlr.getCustomSetting();
        
        system.assertEquals(dt, customSetting.Payout_Date__c);
        system.assertEquals(providerId, customSetting.Selected_Ids__c);
        
        Test.stopTest();
    }
    
    static testMethod void test_generate(){
        
        Test.startTest();
        Date dt = Date.today();
        String providerId = [SELECT Id FROM Account WHERE Name = 'Test Assessment Provider Account' LIMIT 1].Id;
        Id conductorId = AssessmentProviderSummaryReportCtlr.generate(new List<string>{'\'' + providerId + '\''}, dt + '', dt.addDays(5) + '', 'Consolidated');
        
        system.assert(conductorId != null);
        
        Id condutorIDTest = AssessmentProviderSummaryReportCtlr.generate(new List<string>{'\'' + providerId + '\''}, dt + '', dt.addDays(5) + '', 'Consolidated');
        system.assertEquals(conductorId, condutorIDTest);
        AssessmentProviderSummaryReportCtlr.setConductorURLfield(conductorId, true);
        AssessmentProviderSummaryReportCtlr.getBatchJobStatus();
        
        Test.stopTest();
    }
}