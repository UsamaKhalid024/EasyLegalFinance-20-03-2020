@isTest
private with sharing class LawSocietyReviewControllerTest {
    
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
        
        insert accountList;
        
        contactList.add( new Contact(LastName = 'Test Client Contact', AccountId = accountList[0].Id,
                                            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client Contact').getRecordTypeId()));
        contactList.add( new Contact(LastName = 'Test Lawyer Contact', 
                                     AccountId = accountList[1].Id,
                                     RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId(),
                                     Upcoming_Hearings__c='No'));
        insert contactList;
        
        Opportunity Opp = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                          AccountId = accountList[0].Id);
        Opp.Lawyer__c = contactList[1].Id;
        Opp.CloseDate = Date.today().addDays(14);
        opp.Date_Applied__c = Date.today();
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = accountList[1].Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Payout_Date__c = Date.today();
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        insert Opp;
        
        insertDrawdowns(Opp.Id);
               
        Opp.Stage_Status__c = 'Bad Debt';
        
        insertDrawdowns(Opp.Id);

    }
    
    public static void insertDrawdowns(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();

            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (1 * 50), Payment_Method__c ='Cheque', Payout_Date__c = Date.today(),
                                            Reference_Notes__c = 'Loan Payout',Interest_Rate__c = 10));

        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    static testMethod void test_getLawyersList(){
        Test.startTest();
        User currentUser = [SELECT Id, Law_Society_Review__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        currentUser.Law_Society_Review__c = false;
        update currentUser;
        System.assertEquals(false,(Boolean)LawSocietyReviewController.getLawyersList(Date.today().addYears(-3)+'',Date.today()+'','ELFI', '', 'SUM(Amount__c)','ASC','','','',null,null, 'All').get('isCurrentUserSeeLawSocietyReviewReport'));
        Test.stopTest();
    }

    static testMethod void test_ContentNotes(){
        Test.startTest();
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals(0,LawSocietyReviewController.getContentNotes(contact.Id).size());
        LawSocietyReviewController.saveNewNote('Test',contact.Id);
        System.assertEquals(1,LawSocietyReviewController.getContentNotes(contact.Id).size());
        Test.stopTest();
    }

    static testMethod void test_saveContacts(){
        Test.startTest();
        Contact contact = [SELECT Id, Upcoming_Hearings__c FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals('No',contact.Upcoming_Hearings__c);
        contact.Upcoming_Hearings__c = 'Yes';
        List<LawSocietyReviewController.Lawyer> lawyersList = new List<LawSocietyReviewController.Lawyer>();
        lawyersList.add(new LawSocietyReviewController.Lawyer(contact,0,0));
        LawSocietyReviewController.saveContacts(JSON.serialize(lawyersList));
        contact = [SELECT Id, Upcoming_Hearings__c FROM Contact WHERE LastName = 'Test Lawyer Contact' LIMIT 1];
        System.assertEquals('Yes',contact.Upcoming_Hearings__c);
        Test.stopTest();
    }
    
    public static testmethod void test_vfPage(){
        Test.startTest();
        Date endDate = Date.today();
        Date startDate = endDate.addDays(-30);
        PageReference pageRef = Page.FundingDashboardViewAll;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('startDate', startDate.year() + '-' + startDate.month() + '-' + startDate.day());
        ApexPages.currentPage().getParameters().put('endDate', '' + endDate.year() + '-' + endDate.month() + '-' + endDate.day());
        ApexPages.currentPage().getParameters().put('businessUnit', 'ELFI');
        ApexPages.currentPage().getParameters().put('searchByName', '');
        ApexPages.currentPage().getParameters().put('upcomingHearings', '');
        ApexPages.currentPage().getParameters().put('currentProceedings', '');
        ApexPages.currentPage().getParameters().put('orders', '');
        ApexPages.currentPage().getParameters().put('dateReviewed', '');
        ApexPages.currentPage().getParameters().put('nextReviewDate', '');
        LawSocietyReviewController ctlr = new LawSocietyReviewController();
        ctlr.getLawyers();

        
        Test.stopTest();
    }
}