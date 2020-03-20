@isTest
public class ApprovelProcessUnlockTest {
    
    @TestSetup
    public static void initailizeTestData(){
        List<Account> accountList = new List<Account>();
        List<Contact> contactList = new List<Contact>();
        
        accountList.add( new Account(Name = 'Test Client Account', Authorization_Clause__c = 'No', Business_unit__c='ELFI',
                                     Projected_Loan_Value__c = 0,
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId()));
        accountList.add( new Account(Name = 'Test LawFirm Account', Authorization_Clause__c = 'No', 
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId()));
        accountList.add( new Account(Name = 'Firm Account', Account_Type__c = 'Treatment Provider Firm',
                                     RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId()));
        
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
        attach.parentId= contactList[1].Id;
        insert attach;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        opp.Date_Applied__c = Date.today();
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Active';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Assessment';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        Opp.amount = 2500;
        insert Opp;
        
        insertDrawdowns(Opp.Id);
        
        Opp.Stage_Status__c = 'Bad Debt';
        
        insertDrawdowns(Opp.Id);
        
        insert new Assessment_Summary_Report__c(SetupOwnerId=UserInfo.getUserId(),
                                                Conga_Conductor_Id__c = '');
        
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
    
    public static testMethod void test_method1(){
        Test.startTest();
        Account clientAccount = [SELECT Id, Projected_Loan_Value__c, Loan_To_Value__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Projected_Loan_Value__c = 3000;
        update clientAccount;
        
        clientAccount.Projected_Loan_Value__c = 25000;
        update clientAccount;
        
        RecallApprovalProcess.recallPendingApprovals(new List<Id>{clientAccount.Id});
        Test.stopTest();
    }
    public static testMethod void test_method2(){
        
        Account clientAccount = [SELECT Id, Projected_Loan_Value__c, Loan_To_Value__c FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        clientAccount.Projected_Loan_Value__c = 3000;
        update clientAccount;
        
        RecallApprovalProcess.recallPendingApprovals(new List<Id>{clientAccount.Id});
        
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		app.setObjectId(clientAccount.id);
		Approval.ProcessResult result = Approval.process(app);
        
        Test.startTest();
        
        ApprovelProcessUnlock.createCustomApprovalHistoryRecords(new List<Id>{clientAccount.Id});
        RecallApprovalProcess.recallPendingApprovals(new List<Id>{clientAccount.Id});
        Test.stopTest();
    }
}