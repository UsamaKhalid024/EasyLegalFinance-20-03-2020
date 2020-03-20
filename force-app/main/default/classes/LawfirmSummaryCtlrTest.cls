@isTest 
public class LawfirmSummaryCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        
        RecordType lawFirmRTAccount = [SELECT Id FROM RecordType Where SobjectType = 'Account' AND Name = 'Law Firm'];
        RecordType lawyerRTContact = [SELECT Id FROM RecordType Where SobjectType = 'Contact' AND Name = 'Lawyers'];
        RecordType clientOppoRT = [SELECT Id FROM RecordType Where SobjectType = 'Opportunity' AND Name = 'Client Opportunity Record Type'];
        
        Account LawFirmAccount = new Account(Name = 'Test Lawfirm Account', Authorization_Clause__c = 'No', RecordTypeId = lawFirmRTAccount.Id);
        insert LawFirmAccount;
        
        Contact LawyerContact = new Contact(LastName = 'Test Lawyer Contact', AccountId = LawFirmAccount.Id, RecordTypeId = lawyerRTContact.Id);
        insert LawyerContact;
        
        Opportunity clientOpp = new Opportunity(Name = 'Test Client Opportunity', RecordTypeId = clientOppoRT.Id, AccountId = LawFirmAccount.Id);
        clientOpp.CloseDate = Date.today().addDays(14);
        clientOpp.StageName = 'Closed With Loan';
        clientOpp.Law_Firm__c = LawFirmAccount.Id;        
        clientOpp.Stage_Status__c = 'Approved';
        insert clientOpp; 
        
        insert new Conga_batch_setting__c(SetupOwnerId=UserInfo.getUserId(), Payout_Date_Law_Firm_Report__c = Date.today(),
                                          Report_Date_Law_Firm_Report__c = Date.today().addDays(5), Email_To_Id_Law_Firm_Summary__c = '',
                                  		  Email_Additional_Notes_Law_Firm_Report__c = '', Query_Selector_Law_Firm_Report__c = '',
                                          Conductor_Id_Law_Firm_Summary_Report__c = '');
    }
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'All', 'ELFI');
        LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'Active', 'ELFI');
        LawfirmSummaryCtlr.getPickListValues('Account', 'Business_Unit__c');
        
        LawfirmSummaryCtlr.AccountInfo accInfo = new LawfirmSummaryCtlr.AccountInfo();
        accInfo.checked = true;
        
        //throwing exception to cover cath block
        strQuery = 'SELECT Id Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        try{
            LawfirmSummaryCtlr.getLawfirmAccounts(strQuery, 'All', 'ELFI');
        }catch(Exception e){
            System.debug('success');
        }
        
        Test.stopTest();
    }
    public static testMethod void sendMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id from Contact limit 1];
        List<String> selId = new List<String>{cc.Id};
        LawfirmSummaryCtlr.send(strQuery, selId, Date.today() + '' , Date.today() + '', '', 'Email body', 'All', 'ELFI');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Law_Firm_Summary_Report__c, null);
        
        LawfirmSummaryCtlr.send('', selId, Date.today() + '' , Date.today() + '', '', 'Email body', 'All', 'ELFI');
        
        Test.stopTest();
    }
    
    public static testMethod void generateMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Law Firm\' AND Id in (SELECT Law_Firm__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id from Contact limit 1];
        List<String> selId = new List<String>{cc.Id};
            
        LawfirmSummaryCtlr.generate(strQuery, selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Law_Firm_Summary_Report__c, null);
        
        LawfirmSummaryCtlr.generate('', selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI');
        
        Test.stopTest();
    }
}