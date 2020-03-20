@isTest
public class CSL_FacilityDrawdownCtlrTest {
    
    public static testMethod void mainTestMethod(){
        Test.startTest();
        
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
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        
        Drawdown__c drawdown = new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = Opp.Id,
                                               Amount__c = 2000, Payment_Method__c ='Payment', Payout_Date__c = Date.today(),
                                               Reference_Notes__c = 'Partial Payment');
        insert drawdown;
        
        PageReference pageRef = Page.CSL_FacilityDrawdown;
        Test.setCurrentPage(pageRef); 
        System.assertNotEquals(null,pageRef);        
        
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(drawdown); 
        ApexPages.currentPage().getParameters().put('oppId', opp.Id);
        
        CSL_FacilityDrawdownCtlr fdrawdownCtlr = new CSL_FacilityDrawdownCtlr(sc);        
        System.assertNotEquals(null, fdrawdownCtlr.oppId);
        System.assertEquals(1, fdrawdownCtlr.drawdowns.size());
        
        fdrawdownCtlr.createNew();
        system.assertNotEquals(null, fdrawdownCtlr.drawdown.Id);
        
        fdrawdownCtlr.savedrawdownList();
        fdrawdownCtlr.getCurrentPage();
        fdrawdownCtlr.deleteDrawdown();
        
        fdrawdownCtlr.drawdowns[0].Id = null;
        try{
            fdrawdownCtlr.savedrawdownList();
        }catch(Exception e){
            
        }
        
        try{
            ApexPages.currentPage().getParameters().put('oppId', null);
            
            CSL_FacilityDrawdownCtlr fdrawdownCtlrNew = new CSL_FacilityDrawdownCtlr(sc);        
            
            fdrawdownCtlrNew.createNew();
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
}