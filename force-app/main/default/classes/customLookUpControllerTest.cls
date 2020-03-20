@isTest
public class customLookUpControllerTest {
    
    @TestSetup
    static void initailizeTestData(){
        RecordType lawFirmRTAccount = [SELECT Id FROM RecordType Where SobjectType = 'Account' AND Name = 'Law Firm'];
        RecordType lawyerRTContact = [SELECT Id FROM RecordType Where SobjectType = 'Contact' AND Name = 'Lawyers'];
        Account LawFirmAccount = new Account(Name = 'Test Lawfirm Account', Authorization_Clause__c = 'No', 
                                             RecordTypeId = lawFirmRTAccount.Id);
        insert LawFirmAccount;
        
        List<Contact> contactList = new List<Contact>();
        for(Integer i=0; i<5; i++){
            contactList.add(new Contact(
                LastName = 'Test Lawyer Contact ' + i, 
                AccountId = LawFirmAccount.Id,
                RecordTypeId = lawyerRTContact.Id
            ));
        }
        insert contactList;
    }
    
     public static testMethod void mainTest(){
        
         Test.startTest();
         
         List < sObject > lookupConList = customLookUpController.fetchLookUpValues('Test', 'Contact', '', '', '');
         
         system.assertEquals(5, lookupConList.size());
         
         Test.stopTest();
     }
}