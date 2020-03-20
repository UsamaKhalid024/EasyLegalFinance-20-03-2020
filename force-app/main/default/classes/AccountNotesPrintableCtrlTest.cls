@isTest
public class AccountNotesPrintableCtrlTest {
    
    @TestSetup
    static void initailizeTestData(){        
        RecordType lawFirmRTAccount = [SELECT Id FROM RecordType Where SobjectType = 'Account' AND Name = 'Law Firm'];
        Account LawFirmAccount = new Account(Name = 'Test Lawfirm Account', Authorization_Clause__c = 'No', RecordTypeId = lawFirmRTAccount.Id);
        insert LawFirmAccount;    
               
        
    }
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        Account acc = [SELECT id,Name FROM Account limit 1];
        
        ContentNote cn = new ContentNote();
        cn.Title = 'test2';
        String body = '<b>Hello World. Because this text is already formatted as HTML, it does not need to be escaped. Special characters such as &quot;, etc. must already use their HTML equivalents.</b>';
        cn.Content = blob.valueOf(body);
        insert(cn);
        
        
        ContentDocumentLink clnk = new ContentDocumentLink();
        clnk.LinkedEntityId = acc.Id;
        clnk.ContentDocumentId = cn.Id;
        clnk.ShareType = 'I';
        
        insert clnk;
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        AccountNotesPrintableCtrl accNotesPrintableCtrl = new AccountNotesPrintableCtrl(sc);
        Test.stopTest();
    }
}