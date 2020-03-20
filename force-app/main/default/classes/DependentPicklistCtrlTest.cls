@isTest
public class DependentPicklistCtrlTest {
    
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
    }
    
    public static testMethod void mainTest(){
        
        Test.startTest();
        Opportunity Opp = [SELECT Id, Name FROM Opportunity limit 1];
        
        
        DependentPicklistCtrl.getDependentMap(Opp, '', 'Stage_Status__c');
        
        try{
            DependentPicklistCtrl.getDependentMap(null, 'StageName', 'Stage_Status__c');
        }catch(Exception e){
            
        }
        
        DependentPicklistCtrl.getDependentMap(Opp, 'StageName', 'Stage_Status__c');
        
        DependentPicklistCtrl.PicklistEntryWrapper depPicklistEntryWrapper = new DependentPicklistCtrl.PicklistEntryWrapper();
        depPicklistEntryWrapper.active = 'Active';
        depPicklistEntryWrapper.value = depPicklistEntryWrapper.defaultValue;
        depPicklistEntryWrapper.validFor = 'All';
        
        Test.stopTest();
        
    }
}