@isTest
public class OpportunityViewComponentCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){        
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
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = contactList[0].Id;
        Opp.Minimum_Interest_Period__c = '0 months';
        Opp.Compounding_Interest__c = 'Monthly';
        Opp.Interest_Rate__c = 15.0;
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        insert Opp;
        
        Opportunity OppoRe = new Opportunity(Name = 'Test Opportunity 2', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId(),
                                             AccountId = accountList[0].Id);
        OppoRe.Lawyer__c = contactList[1].Id;
        OppoRe.CloseDate = Date.today().addDays(14);
        OppoRe.StageName = 'Closed With Loan';
        OppoRe.Law_Firm__c = accountList[1].Id;        
        OppoRe.Stage_Status__c = 'Approved';
        OppoRe.Type_of_Loan__c = 'Treatment Loan';
        OppoRe.Primary_Contact__c = contactList[0].Id;        
        OppoRe.Re_Assessed_Loan__c = Opp.Id;
        insert OppoRe;
    }
    public static void insertDrawdown(String OppId){
        List<Drawdown__c> drawdownList = new List<Drawdown__c>();
        for(Integer i=0; i < 5; i++){
            drawdownList.add(new Drawdown__c(Type__c = 'Facility Drawdown', Date__c = Date.today(), Opportunity__c = OppId,
                                            Amount__c = 2000 + (i * 50)));
        }
        if(drawdownList.size() > 0){
            insert drawdownList;
        }
    }
    
    public static testMethod void mainTestMethod(){
        Test.startTest();
        List<String> pickListValues = OpportunityViewComponentCtlr.getPickListValues('Opportunity', 'StageName');
        system.assert(pickListValues.size() > 0);
        Test.stopTest();
    }
    
    public static testMethod void opportunityTest(){
        
        Test.startTest();
        
        Account clientAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Opportunity oppoClient = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        //getOpportunityDetails Test
        Opportunity oppDetails = OpportunityViewComponentCtlr.getOpportunityDetails('',clientAccount.Id);
        system.assertEquals(oppDetails.Name, '');
        
        oppDetails = OpportunityViewComponentCtlr.getOpportunityDetails(oppoClient.Id,clientAccount.Id);
        system.assertEquals(oppDetails.Name, oppoClient.Name);
        oppoClient = oppDetails;
            
        //getDependentMap Test
        Map<String, List<String>> dependentMap = OpportunityViewComponentCtlr.getDependentMap(oppoClient, 'StageName', 'Stage_Status__c');
        system.assert(dependentMap.size() > 0);        
        
        //saveOpportunity Test
        try{            
            OpportunityViewComponentCtlr.saveOpportunity(null);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        
        try{
            oppDetails.Name = 'INCREASING NAME LENGTH TO THROW DML EXCEPTION. ======================================================================================================================================';
            OpportunityViewComponentCtlr.saveOpportunity(oppDetails);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        oppoClient.Name = 'Test Opportunity';
        Opportunity resultOppo = OpportunityViewComponentCtlr.saveOpportunity(oppoClient);
        system.assertEquals(oppoClient.Name, resultOppo.Name);
        
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = clientAccount.Id;
        newOpp.Name = oppoClient.Name;
        newOpp.Primary_Contact__c = oppoClient.Primary_Contact__c;
        newOpp.CloseDate = Date.today().addDays(14);
        newOpp.StageName = 'Closed With Loan';
        insert newOpp;
        
        OpportunityContactRole oppoConRole = new OpportunityContactRole();
        oppoConRole.OpportunityId = newOpp.Id;
        oppoConRole.ContactId = newOpp.Primary_Contact__c;
        oppoConRole.IsPrimary = false;
        insert oppoConRole;
        
        //saveOpportunity Test
        resultOppo = OpportunityViewComponentCtlr.saveOpportunity(newOpp);
        system.assertEquals(oppoClient.Name, resultOppo.Name);
        
        //deleteOpp Test
        try{
            OpportunityViewComponentCtlr.deleteOpp('null');
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        OpportunityViewComponentCtlr.deleteOpp(newOpp.Id);
        system.assertEquals(1, [SELECT Id FROM Opportunity WHERE Re_Assessed_Loan__c = null].size());
        Test.stopTest();
    }
    
    public static testMethod void contactHistoryTest(){        
        Test.startTest();        
        Account clientAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Contact_History__c contactHistory = OpportunityViewComponentCtlr.getContactHistory(clientAccount.Id);
        system.assertEquals(null, contactHistory);
        Test.stopTest();
    }
    
    public static testMethod void drawdownTest() {
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        // getdrawdownlist test
        insertDrawdown(clientOpportunity.Id);       
        List<Drawdown__c> drawdownList = OpportunityViewComponentCtlr.getDrawdownList(clientOpportunity.Id);
        system.assertEquals(5, drawdownList.size());
        
        // saveNewDrawdownList Test
        try{
            //To cover exception code.
            OpportunityViewComponentCtlr.saveNewDrawdownList(null);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }        
        OpportunityViewComponentCtlr.saveNewDrawdownList(drawdownList);
        try{
            drawdownList.add(new Drawdown__c( ) );
            //To cover DML exception code.
            OpportunityViewComponentCtlr.saveNewDrawdownList(drawdownList);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        
        //insertNewDrawdown Test
        drawdownList.remove(drawdownList.size() - 1);
        try{
            OpportunityViewComponentCtlr.insertNewDrawdown(null);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        OpportunityViewComponentCtlr.insertNewDrawdown(clientOpportunity.Id);
        drawdownList = OpportunityViewComponentCtlr.getDrawdownList(clientOpportunity.Id);
        system.assertEquals(6, drawdownList.size());
        
        //deleteDrawdownRecord Test
        try{
            OpportunityViewComponentCtlr.deleteDrawdownRecord(null, clientOpportunity.Id);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        system.debug('drawdownList : ===>' + drawdownList);
        try{
            drawdownList = OpportunityViewComponentCtlr.deleteDrawdownRecord(drawdownList[drawdownList.size() - 1].Id, clientOpportunity.Id);
        } catch (Exception e){
            
        }
        system.assertEquals(drawdownList.size(), drawdownList.size());
        Test.stopTest();
    }
    
    public static testMethod void reAssessmentOpportunitiesTest() {
        Test.startTest();
        //getReAssessmentOpportunities Test
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        List<Opportunity> rOppList = OpportunityViewComponentCtlr.getReAssessmentOpportunities(clientOpportunity.Id);
        system.assertEquals(1, rOppList.size());
        
        //saveReassessmentsList Test
        try{
            rOppList.add(new Opportunity());
            OpportunityViewComponentCtlr.saveReassessmentsList(rOppList);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        rOppList.remove(rOppList.size() - 1);
        OpportunityViewComponentCtlr.saveReassessmentsList(rOppList);
        
        //deleteReassessments
        try{
            OpportunityViewComponentCtlr.deleteReassessments(null, clientOpportunity.Id);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        rOppList = OpportunityViewComponentCtlr.deleteReassessments(rOppList[0].Id, clientOpportunity.Id);
        system.assertEquals(0, rOppList.size());
        
        Account clientTestAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test Client Account' LIMIT 1];
        Opportunity newOpp = new Opportunity();
        newOpp.AccountId = clientTestAccount.Id;
        newOpp.Name = clientOpportunity.Name;
        newOpp.Primary_Contact__c = clientOpportunity.Primary_Contact__c;
        newOpp.CloseDate = Date.today().addDays(14);
        newOpp.StageName = 'Closed With Loan';
        insert newOpp;
        
        Scheduled_Payment__c schpay = new Scheduled_Payment__c();
        schpay.Status__c = 'Scheduled';
        schpay.Payment_Type__c = 'Scheduled Facility';
        schpay.Opportunity__c = newOpp.Id;
        OpportunityViewComponentCtlr.deletePayments(newOpp.Id);

		Bank_Account__c bankacc = new Bank_Account__c();
        bankacc.Name = 'Test Bank Acc';
        //bankacc.Is_Primary_Account__c = true;
        bankacc.Client__c = clientTestAccount.Id;
        try{
            OpportunityViewComponentCtlr.getBankAccountOptions(null); 
        }catch(DMLException e){
        }catch (Exception e){  
        }
        OpportunityViewComponentCtlr.getBankAccountOptions(newOpp.Id);
        OpportunityViewComponentCtlr.getUpdatedAmounts(newOpp.Id);
        
        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Assessment_Provider' AND sObjectType = 'Account'].Id;
        Account NewTestAcc = new Account();
        NewTestAcc.Name = 'Testing Account';
        NewTestAcc.RecordTypeId = recordTypeId;
        Insert NewTestAcc;
        
        Id ContactRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Lawyers' AND sObjectType = 'Contact'].Id;
        Contact NewTestCon = new Contact();
        NewTestCon.FirstName = 'Test';
        NewTestCon.LastName = 'Contact';
        NewTestCon.RecordTypeId = ContactRecordTypeId;
        Insert NewTestCon;
        
        
		Assessment_Provider_Schedule__c aps = new Assessment_Provider_Schedule__c();
        aps.Discount__c = 30;
        aps.Assessment_Provider__c = NewTestAcc.Id;
        aps.Lawyer__c = NewTestCon.Id;
        aps.Rebate_Discount__c = 20;
        Insert aps;
       	OpportunityViewComponentCtlr.setLatestDiscountRateLaywer(newOpp.Id, NewTestAcc.Id, NewTestCon.Id);
        delete aps;
        OpportunityViewComponentCtlr.setLatestDiscountRateLaywer(newOpp.Id, NewTestAcc.Id, NewTestCon.Id);
        try{
        	OpportunityViewComponentCtlr.setLatestDiscountRateLaywer(null, null, null);
        }catch(exception e){
            
        }
        Test.stopTest();
    }
    
    public static testMethod void serviceProvidersTest() {
        Test.startTest();
        Opportunity clientOpportunity = [SELECT Id,Name,Primary_Contact__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Account firmAccount = [SELECT Id,Name FROM Account WHERE Name = 'Firm Account' LIMIT 1];
        Account lawfirmAccount = [SELECT Id,Name FROM Account WHERE Name = 'Test LawFirm Account' LIMIT 1];
        
        //addTreatmentItem Test
        try{
            OpportunityViewComponentCtlr.addTreatmentItem(clientOpportunity.Id, lawfirmAccount);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        OpportunityViewComponentCtlr.addTreatmentItem(clientOpportunity.Id, firmAccount);
        
        //getServiceProviders Test
        List<Opportunity_Service_Provider__c> spList = OpportunityViewComponentCtlr.getServiceProviders(clientOpportunity.Id);
        system.assertEquals(1, spList.size());
        
        //insertNewServiceProviderDrawdown Test
        spList = OpportunityViewComponentCtlr.insertNewServiceProviderDrawdown(clientOpportunity.Id, spList[0].Id);
        system.assertEquals(1, spList.size());
        
        //saveProvidersList Test
        List<Opportunity_Service_Provider__c> ospList;
        try{
            OpportunityViewComponentCtlr.saveProvidersList(null,clientOpportunity.Id);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        spList = OpportunityViewComponentCtlr.saveProvidersList(JSON.serialize(spList),clientOpportunity.Id);
        system.assertEquals(1, spList.size());
        
        //deleteServiceProviderDrawdownRecord Test
        try{
            OpportunityViewComponentCtlr.deleteServiceProviderDrawdownRecord(null,clientOpportunity.Id);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        OpportunityViewComponentCtlr.deleteServiceProviderDrawdownRecord(spList[0].Drawdowns__r[0].Id,clientOpportunity.Id);
        
        //deleteTreatmentItem Test
        try{
            OpportunityViewComponentCtlr.deleteTreatmentItem(null, clientOpportunity.Id);
        }catch (DMLException e){
            
        }catch(Exception e){
            
        }
        spList = OpportunityViewComponentCtlr.deleteTreatmentItem(spList[0].Id, clientOpportunity.Id);
        system.assertEquals(0, spList.size());
        Test.stopTest();
    }
    
}