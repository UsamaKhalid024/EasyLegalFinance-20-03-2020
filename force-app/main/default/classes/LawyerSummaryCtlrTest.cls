@isTest
public class LawyerSummaryCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        
        RecordType lawFirmRTAccount = [SELECT Id FROM RecordType Where SobjectType = 'Account' AND Name = 'Law Firm'];
        RecordType lawyerRTContact = [SELECT Id FROM RecordType Where SobjectType = 'Contact' AND Name = 'Lawyers'];
        RecordType clientOppoRT = [SELECT Id FROM RecordType Where SobjectType = 'Opportunity' AND Name = 'Client Opportunity Record Type'];
        
        Account LawFirmAccount = new Account(Name = 'Test Lawfirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = lawFirmRTAccount.Id);
        insert LawFirmAccount;
        
        Contact LawyerContact = new Contact(LastName = 'Test Lawyer Contact', AccountId = LawFirmAccount.Id,
                                            RecordTypeId = lawyerRTContact.Id);
        insert LawyerContact;
        
        Opportunity clientOpp = new Opportunity(Name = 'Test Client Opportunity', RecordTypeId = clientOppoRT.Id, AccountId = LawFirmAccount.Id);
        clientOpp.Lawyer__c = LawyerContact.Id;
        clientOpp.CloseDate = Date.today().addDays(14);
        clientOpp.StageName = 'Closed With Loan';
        clientOpp.Law_Firm__c = LawFirmAccount.Id;        
        clientOpp.Stage_Status__c = 'Approved';
        insert clientOpp; 
        
        insert new Conga_batch_setting__c(SetupOwnerId=UserInfo.getUserId(), Payout_Date_Lawyer_Summary_Report__c = Date.today(),
                                          Report_Date_Lawyer_Summary_Report__c = Date.today().addDays(5),
                                          Email_Additional_Notes_Lawyer_Summary__c = '', Query_Selector_Lawyer_Summary_Report__c = '',
                                          Conductor_Id_Lawyer_Summary_Report__c = '');
    }
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name, Account.Name FROM Contact WHERE RecordType.Name = \'Lawyers\' AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null)';
        LawyerSummaryCtlr.getLawyersContacts(strQuery, 'All', 'ELFI');
        LawyerSummaryCtlr.getLawyersContacts(strQuery, 'Active', 'Rhino');
        LawyerSummaryCtlr.getPickListValues('Account', 'Business_Unit__c');
        
        LawyerSummaryCtlr.ContactInfo conInfo = new LawyerSummaryCtlr.ContactInfo();
        conInfo.checked = true;
        
        //throwing exception to cover cath block
        strQuery = 'SELECT Id, Name Account.Name FROM Contact WHERE RecordType.Name = \'Lawyers\' AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null)';
        
        try{
            LawyerSummaryCtlr.getLawyersContacts(strQuery, 'All', 'ELFI');
        }catch(Exception e){
            System.debug('success');
        }
        
        Test.stopTest();
    }
    public static testMethod void sendMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name, Account.Name FROM Contact WHERE RecordType.Name = \'Lawyers\' AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id from Contact limit 1];
        List<String> selId = new List<String>{cc.Id};
            LawyerSummaryCtlr.send(strQuery, selId, Date.today() + '', Date.today() + '', 'Email body', 'All', 'ELFI');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Lawyer_Summary_Report__c, null);
        
        LawyerSummaryCtlr.send('', selId, Date.today() + '', Date.today() + '', 'Email body', 'All', 'ELFI');
        
        Test.stopTest();
    }
    
    public static testMethod void generateMethodTest(){
        
        Test.startTest();
        
        String strQuery = 'SELECT Id, Name, Account.Name FROM Contact WHERE RecordType.Name = \'Lawyers\' AND Id in (SELECT Lawyer__c FROM Opportunity WHERE accountId !=null)';
        
        Contact cc = [SELECT Id from Contact limit 1];
        List<String> selId = new List<String>{cc.Id};
            
            LawyerSummaryCtlr.generate(strQuery, selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI');
        
        Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());
        system.assertNotEquals(customSettings.Conductor_Id_Lawyer_Summary_Report__c, null);
        
        LawyerSummaryCtlr.generate('', selId, Date.today() + '' , Date.today() + '', 'All', 'ELFI');
        
        Test.stopTest();
    }
    
}