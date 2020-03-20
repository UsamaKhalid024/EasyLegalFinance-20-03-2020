@isTest
public class CustomerViewComponentCtlrTest {
    
    @TestSetup
    static void initailizeTestData(){
        // Account
        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        
        
        Account generalBusinessAcc = new Account();
        generalBusinessAcc.Name='account';
        generalBusinessAcc.BillingStreet = 'Testtest';
        generalBusinessAcc.BillingState = 'CA';
        generalBusinessAcc.BillingCity = 'City';
        generalBusinessAcc.BillingPostalCode = '10001';
        generalBusinessAcc.Billingcountry='Canada';
        generalBusinessAcc.ShippingStreet = 'Test';
        generalBusinessAcc.ShippingState = 'New York';
        generalBusinessAcc.ShippingCountry = 'UNITED STATES';
        generalBusinessAcc.ShippingPostalCode = '10001';
        generalBusinessAcc.ShippingCity = 'Lake Trees';
        generalBusinessAcc.Account_Type__c = 'Treatment Provider Firm';
        generalBusinessAcc.RecordTypeId = RecordTypeIdAccount;
        //insert generalBusinessAcc;
        
        // Account # 2
        Id RecordTypeIdAccount2 = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId();
        
        
        Account lawfirm = new Account();
        lawfirm.Name='Test Lawfirm';
        lawfirm.BillingStreet = 'sample';
        lawfirm.BillingState = 'AK';
        lawfirm.BillingCity = 'City1';
        lawfirm.BillingPostalCode = '987654';
        lawfirm.Billingcountry='Uganda';
        lawfirm.ShippingStreet = 'Test1';
        lawfirm.ShippingState = 'Los Angeles';
        lawfirm.ShippingPostalCode = '123456';
        lawfirm.ShippingCity = 'Lake View';
        lawfirm.Account_Type__c = 'Treatment Provider Firm';
        lawfirm.RecordTypeId = RecordTypeIdAccount2;
        //insert lawfirm;
        
        Account lawfirm2 = new Account();
        lawfirm2.Name='example account';
        lawfirm2.BillingStreet = 'example';
        lawfirm2.BillingState = 'SC';
        lawfirm2.BillingCity = 'example city';
        lawfirm2.BillingPostalCode = '012457';
        lawfirm2.Billingcountry='Pakistan';
        lawfirm2.ShippingStreet = 'Test1';
        lawfirm2.ShippingState = 'New Jersey';
        lawfirm2.ShippingPostalCode = '654321';
        lawfirm2.ShippingCity = 'Lake View Park';
        lawfirm2.Account_Type__c = 'Treatment Provider Firm';
        lawfirm2.RecordTypeId = RecordTypeIdAccount2;
        //insert lawfirm2;
        
        insert (new SObject[]{generalBusinessAcc, lawfirm, lawfirm2});
        
        // Contact
        Id RecordTypeIdContact = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('General Contact').getRecordTypeId();
        
        Contact primaryContct = new Contact();
        
        primaryContct.lastname = 'testtest';
        primaryContct.email = 'testtest@testtest.com';
        primaryContct.AccountId = generalBusinessAcc.id;
        primaryContct.RecordTypeId = RecordTypeIdContact;
        
        //insert primaryContct;
        
        // Contact # 2
        Id RecordTypeIdContact2 = 
            Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Lawyers').getRecordTypeId();
        
        Contact lawyerContact = new Contact();
        
        lawyerContact.lastname = 'test';
        lawyerContact.email = 'test@test.com';
        lawyerContact.AccountId = lawfirm.id;
        lawyerContact.RecordTypeId = RecordTypeIdContact2;
        
        //insert lawyerContact;
        
        Contact lawyerContact2 = new Contact();
        
        lawyerContact2.lastname = 'testt';
        lawyerContact2.email = 'testt@testt.com';
        lawyerContact2.AccountId = lawfirm2.id;
        lawyerContact2.RecordTypeId = RecordTypeIdContact2;
        
        //insert lawyerContact2;
        
        insert (new SObject[]{primaryContct, lawyerContact, lawyerContact2});
        
        
        // Opportunity 
        Opportunity Opp = new Opportunity();
        Opp.Name = 'Test Opportunity';
        Opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Opp.AccountId = generalBusinessAcc.Id;
        Opp.Lawyer__c = lawyerContact.Id;
        Opp.CloseDate = Date.today().addDays(14);
        Opp.StageName = 'Closed With Loan';
        Opp.Law_Firm__c = lawfirm.Id;        
        Opp.Stage_Status__c = 'Approved';
        Opp.Type_of_Loan__c = 'Facility Loan';
        Opp.Primary_Contact__c = primaryContct.Id;
        Opp.Interest_Rate__c = 1.0;
        Opp.Minimum_Interest_Period__c = '12 months';
        Opp.Compounding_Interest__c = 'Annual';
        Opp.Interest_Compounding_Period__c = 'Simple Interest';
        Opp.Interest_Deferral_Period__c = '0';
        Opp.Re_Assessed_Loan__c = null;
        Opp.Amount = 5.0;
        //insert Opp; 
        
        // Opportunity 
        Opportunity Opp2 = new Opportunity();
        Opp2.Name = 'Test Opportunity 2';
        Opp2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
        Opp2.AccountId = generalBusinessAcc.Id;
        Opp2.Lawyer__c = lawyerContact.Id;
        Opp2.CloseDate = Date.today().addDays(20);
        Opp2.StageName = 'Closed With Loan';
        Opp2.Law_Firm__c = lawfirm.Id;        
        Opp2.Stage_Status__c = 'Approved';
        Opp2.Type_of_Loan__c = 'Facility Loan';
        Opp2.Primary_Contact__c = primaryContct.Id;
        Opp2.Interest_Rate__c = 24.0;
        Opp2.Minimum_Interest_Period__c = '6 months';
        Opp2.Compounding_Interest__c = 'Semi-Annual';
        Opp2.Interest_Deferral_Period__c = '0';
        Opp2.Interest_Compounding_Period__c = 'Compounding Interest';
        Opp2.Re_Assessed_Loan__c = null;
        
        insert (new SObject[]{Opp, Opp2});
                
        // Drawdown
        Drawdown__c drw = new Drawdown__c();
        
        drw.Opportunity__c = Opp.id;
        drw.Amount__c = 1000;
        drw.Date__c = Date.today().addDays(-30);
        drw.Payment_Method__c = 'e-Transfer';
        drw.Reference_Notes__c = 'Payment to Client';
        
        //insert drw;
        
        Drawdown__c drw2 = new Drawdown__c();
        
        drw2.Opportunity__c = Opp2.id;
        drw2.Amount__c = 1000;
        drw2.Date__c = Date.today().addDays(-30);
        drw2.Payment_Method__c = 'e-Transfer';
        drw2.Reference_Notes__c = 'Payment to Client';
        
        //insert drw2;
        insert (new SObject[]{drw, drw2});
        
        Opportunity_Service_Provider__c sp = new Opportunity_Service_Provider__c();
        
        sp.Allowance__c = 1;
        sp.Opportunity__c = Opp.id;
        sp.Status__c = 'Waiting To Send Schedule';
        sp.Service_Provider_Facility__c = generalBusinessAcc.id;
        
        insert sp;
        
        Service_Provider_Drawdown__c spd = new Service_Provider_Drawdown__c();
        
        spd.Amount__c = 1;
        spd.Drawdown_Date__c = date.today();
        spd.Opportunity_Service_Provider_MD__c = sp.id;
        spd.Payment_Method__c = 'Payment';
        
        insert spd;
        
        Amendment__c amnd = new Amendment__c();
        
        //amnd.name = 'test amendment';
        amnd.Opportunity__c = Opp.id;
        amnd.Amount__c = 1;
        
        insert amnd;
        
        Firm__c frm = new Firm__c();
        
        //frm.Name = 'test firm';
        frm.Law_Firm__c = lawfirm.id;
        frm.Lawyer__c = lawyerContact.id;
        frm.Opportunity__c = Opp.id;
        
        insert frm;
    }
    
    public static testmethod void test_Process1(){
        
        Account acc = [select id from account where name = 'Test Lawfirm' limit 1];        
        test.startTest();
        ContentNote cnote = new ContentNote();
        cnote.Title = 'testt';
        cnote.Content = Blob.valueOf('Helloworld'.escapeHTML4());
        insert(cnote);
        
        String cnoteId = cnote.Id;        
        CustomerViewComponentCtlr.updateContentNote(cnoteId, 'UpdatedNote');
            
        ContentDocumentLink cdl = new ContentDocumentLink();
        
        cdl.ContentDocumentId = cnote.id;
        cdl.LinkedEntityId = acc.Id;
        cdl.ShareType = 'v';
        cdl.Visibility = 'AllUsers';
        
        insert cdl;
        
        CustomerViewComponentCtlr.getAccountInfo(acc.Id);
        
        system.assertEquals(null, CustomerViewComponentCtlr.oppInfo);
        system.assertEquals(null, CustomerViewComponentCtlr.oppList);
        
        CustomerViewComponentCtlr.getEnhancedNotes(acc.Id);
        CustomerViewComponentCtlr.delContentNote(cnoteId);
        
        //exception coverage
        try{
            string cId = 'Invalid Id';
            CustomerViewComponentCtlr.updateContentNote(cId, 'UpdatedNote');
        }catch(exception e){
            
        }
        
        try{
            string cId = 'Invalid Id';
            CustomerViewComponentCtlr.delContentNote(cId);
        }catch(exception e){
            
        }
        
        //update account
        CustomerViewComponentCtlr.saveAccount(acc);
        
        try{
            CustomerViewComponentCtlr.saveAccount(new Account());
        }catch(exception e){
            
        }
        Account testAcc = new Account();
        testAcc.Name = 'Test Acc del';
        insert testAcc;
        CustomerViewComponentCtlr.deleteAccount(testAcc.Id);
        test.stopTest();
    }
    
    public static testmethod void test_Process2(){
        
        String acct = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity' limit 1].id;
        test.startTest();        
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunities(acct);
        CustomerViewComponentCtlr.getOpportunitiesOrderedByDate(acct);        
        Opportunity opp = CustomerViewComponentCtlr.getSingleOpportunity(oppId);
        
        CustomerViewComponentCtlr.getRecentOpportunity(acct);
        CustomerViewComponentCtlr.getLatestOppty(acct);
        
        CustomerViewComponentCtlr.saveOppty(opp);
        try{
            CustomerViewComponentCtlr.saveOppty(new Opportunity());
        }catch(exception e){
            
        }
        test.stopTest();
    }
    
    public static testmethod void test_Process3(){
        
        String accId = [select id from account where name = 'account' limit 1].id;         
        test.startTest();        
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunitiesToGeneratePayout(accId);        
        system.assert(!opps.isEmpty());
        test.stopTest();
    }
    
    public static testmethod void test_Process4(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();        
        decimal amount = 1;
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(accId, amount, 'Payout');        
        system.assert(!opps.isEmpty());
        amount = 5;
        CustomerViewComponentCtlr.calculatePayments(accId, amount, 'Payout');
        test.stopTest();
    }
    
    public static testmethod void test_Process5(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToBadDebtStage(OppId, accId, '2018-01-01');
        test.stopTest();
    }
    public static testmethod void test_Process6(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToSurplusStage(OppId, accId, '2018-01-01');
        
        CustomerViewComponentCtlr.getTransactions(accId);
        
        CustomerViewComponentCtlr.OpportunityTransaction optr = new CustomerViewComponentCtlr.OpportunityTransaction();
        
        system.assertEquals(null, optr.Name);
        system.assertEquals(null, optr.opportunityNumber);
        system.assertEquals(null, optr.transactions);
        system.assertEquals(null, optr.paymentAmountSubtotal);
        system.assertEquals(null, optr.advanceSubtotal);
        system.assertEquals(null, optr.accruedInterestSubtotal);
        system.assertEquals(null, optr.outstandingBalanceSubtotal);
        system.assertEquals(null, optr.perDiemSubtotal);
        
        test.stopTest();
    }
    public static testmethod void test_Process7(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.changeToShortfallStage(OppId, accId, '2018-01-01');
        test.stopTest();
    }
    
    public static testmethod void test_Process8(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyPartialPayments(OppId, accId, '2018-01-01', 'eft', 'chq');
        test.stopTest();
    }
    public static testmethod void test_Process9(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyFullPayments(OppId, accId, null, '2018-01-01', 'eft', 'chq');
        test.stopTest();
    }
    public static testmethod void test_Process10(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.applyMiscPayments(OppId, accId, '2018-01-01', 'eft', 'chq');
        CustomerViewComponentCtlr.getTransactions(accId);
        test.stopTest();
    }
    
    public static testmethod void test_Process11(){
        
        String accId = [select id from account where name = 'account' limit 1].id;  
        List<Opportunity> opps = CustomerViewComponentCtlr.getOpportunities(accId);
        test.startTest();
        CustomerViewComponentCtlr.closeMultipleLoans(opps, accId, null, '2018-01-01');
        CustomerViewComponentCtlr.getOpptyTransactions(accId);
        test.stopTest();
    }
    public static testmethod void test_Process12(){
        
        String accId = [select id from account where name = 'account' limit 1].id;
        String lawyerId = [select id from contact where lastname ='test' limit 1].Id;
        test.startTest();
        CustomerViewComponentCtlr.getLastOpportunity(accId);
        CustomerViewComponentCtlr.getLawyerInfo(lawyerId);
        Contact con = CustomerViewComponentCtlr.getLastContact(accId);
        
        CustomerViewComponentCtlr.saveContact(con);
        try{
            CustomerViewComponentCtlr.saveContact(con);
        }catch(exception e){
            CustomerViewComponentCtlr.saveContact(new Contact());
        }
        test.stopTest();
    }
    
    public static testmethod void test_Process13(){
        String acct2 = [select id from account where name = 'Test Lawfirm' limit 1].id;
        String contactId = [select id from contact where lastname = 'test' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.getFinancingStatementHistory(acct2);
        CustomerViewComponentCtlr.getFirmHistory(acct2);
        CustomerViewComponentCtlr.getContactHistorySingle(contactId);
        CustomerViewComponentCtlr.getContactHistory(acct2);
        test.stopTest();
    }
    
    public static testmethod void test_Process14(){
        String accId = [select id from account where name = 'account' limit 1].id;
        String acct2 = [select id from account where name = 'Test Lawfirm' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.runPayoutForAllOpps(accId,'2018-01-01');
        try{
            CustomerViewComponentCtlr.generatePayoutBalance(acct2,'2018-01-01');
        }catch(exception e){
        }
        CustomerViewComponentCtlr.getAccountLabelsMap();
        CustomerViewComponentCtlr.getPickListValues('Opportunity', 'Minimum_Interest_Period__c');
        
        CustomerViewComponentCtlr.getLoanSummary(accId);
        CustomerViewComponentCtlr.getLoanSummary(acct2);
        try{
             CustomerViewComponentCtlr.runPayoutForAllOpps(accId,null);
        }catch(exception e){
                   }
        test.stopTest();
    }
    
    public static testMethod void criticalDateTest() {
        
        Account acc = [SELECT Id FROM Account WHERE Name = 'account' LIMIT 1];
        List<Critical_Date__c> critcalDateList = new List<Critical_Date__c>();
        
        for(Integer i = 0; i<5; i++){
            critcalDateList.add(new Critical_Date__c(Name__c = 'Examination', Account__c = acc.Id, Date__c = Date.today()));
        }
        
        try{
            CustomerViewComponentCtlr.saveCriticalDateList(critcalDateList);
            Test.startTest();
            List<Critical_Date__c> result = CustomerViewComponentCtlr.getCriticalDatesList(acc.Id);
            system.assertEquals(5, result.size());
            CustomerViewComponentCtlr.deleteCriticalDate(critcalDateList[0].Id);
            Test.stopTest();
        }catch(exception e){
            
        }
    }
    
    public static testmethod void test_Process15(){
        String accId = [select id from account where name = 'account' limit 1].id;
        String OppId = [select id from opportunity where name = 'Test Opportunity'].id;
        test.startTest();
        CustomerViewComponentCtlr.getCurrentUserInfo();
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(accId, payoutDateStr, 'Payout', 'eft', 'chq', OppId, 'Bad Debt', false);
        test.stopTest();
    }
    
    public static testmethod void test_Process16(){
        String accId = [select id from account where name = 'account' limit 1].id;
        test.startTest();
        CustomerViewComponentCtlr.createPaymentTask(accId, 300.89, 'eft', 'chq');
        CustomerViewComponentCtlr.deletePaymentTasks(accId);
        //calculatePayments
        test.stopTest();
    }
    
    
    public static testMethod void testCalculatePayments(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];  
        List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        System.assertEquals(oppsAfterCalculation[0].Total_Payout__c, oppsAfterCalculation[0].Temp_Payment_Received__c);
        System.assertEquals(oppsAfterCalculation[1].Temp_Payment_Received__c, 1500.0-oppsAfterCalculation[0].Total_Payout__c);        
        Task task = [select Id, Subject, Description from Task LIMIT 1];
        System.assertEquals('Complete posting payment of $1,500.00 for account', task.Subject);
        System.assertEquals('Payment of $1,500.00 with EFT # of eft and CHQ # of chq was calculated but not applied to account', task.Description);
        Test.stopTest();
    }
    
    /*public static testMethod void testApplyPayments1(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Bad Debt', false);
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[1].Id, 'Shortfall', true);        
        System.assertEquals('Closed - Shortfall', oppsAfterApplying[0].Stage_Status__c);
        System.assertEquals('Closed - Bad Debt', oppsAfterApplying[1].Stage_Status__c); 
        Test.stopTest();
    }
    
    
    public static testMethod void testApplyPayments(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Closed Paid', false);
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[1].Id, 'Partial Payment', true);
        System.assertEquals('Active - Partial Payment', oppsAfterApplying[0].Stage_Status__c);
        System.assertEquals('Closed - Paid', oppsAfterApplying[1].Stage_Status__c); 
        List<Task> tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }*/
	public static testMethod void testApplyPayments2(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Surplus', true);
        //System.assertEquals('Closed - Surplus', oppsAfterApplying[0].Stage_Status__c);        
        Test.stopTest();
    }
    
    public static testMethod void testApplyMiscPayment(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        //List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1000.0, 'eft', 'chq');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Misc Income Payment', 'eft', 'chq', opps[0].Id, 'Misc Income Payment', true);
        List<Drawdown__c> drawdowns = [select Id, Reference_Notes__c from Drawdown__c where Payment_Method__c='Payment'];
        System.assertEquals('Miscellaneous Payment', drawdowns[0].Reference_Notes__c);
        Test.stopTest();
    }
	
    public static testMethod void testApplyRefund(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> oppsAfterCalculation = CustomerViewComponentCtlr.calculatePayments(account.Id, 1000.0, 'eft', 'chq', 'Refund');
        List<Opportunity> opps = [select Id from Opportunity where AccountId=:account.Id];                
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Refund', 'eft', 'chq', opps[0].Id, 'Refund', true);
        List<Drawdown__c> drawdowns = [select Id, Reference_Notes__c from Drawdown__c where Payment_Method__c='Other'];
        System.assertEquals('Refund', drawdowns[0].Reference_Notes__c);
        Test.stopTest();
    }    	
    
    /*public static testMethod void testTaskDeletion(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());        
        Date payoutDate = Date.today();
        String payoutDateStr = DateTime.newInstance(payoutDate.year(), payoutDate.month(), payoutDate.day()).format('yyyy-MM-dd');
        List<Opportunity> oppsAfterApplying = CustomerViewComponentCtlr.applyPayment(account.Id, payoutDateStr, 'Payout', 'eft', 'chq', opps[0].Id, 'Closed Paid', true);
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }*/
    
    public static testMethod void testTaskDeletionAmount0(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> opps = CustomerViewComponentCtlr.calculatePayments(account.Id, 1500.0, 'eft', 'chq', 'Payout');
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());        
        CustomerViewComponentCtlr.calculatePayments(account.Id, 0.0, 'eft', 'chq', 'Payout');
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
    
    public static testMethod void testCreateTaskOnPaymentApplyingError(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> opps = [select Id, Name, Loan_Requests__c from Opportunity];
        List<Task> tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty()); 
        CustomerViewComponentCtlr.createPaymentApplyingErrorTask(account.Id, opps[0].Id);
        tasks = [select Id, Subject, Description from Task];
        System.assertEquals(false, tasks.isEmpty());
        System.assertEquals('Payment allocation failed', tasks[0].Subject);
        System.assertEquals('Payment was not applied to: ' + opps[0].Name + ' ' + opps[0].Loan_Requests__c + '.', tasks[0].Description);
        Test.stopTest();
    }
    
    public static testMethod void testDeletePaymentApplyingErrorTasks(){
        Test.startTest();
        Account account = [select Id from Account where Name='account'];
        List<Opportunity> opps = [select Id, Name, Loan_Requests__c from Opportunity];
        CustomerViewComponentCtlr.createPaymentApplyingErrorTask(account.Id, opps[0].Id);
        List<Task> tasks = [select Id from Task];
        System.assertEquals(false, tasks.isEmpty());
        CustomerViewComponentCtlr.deletePaymentApplyingErrorTasks(account.Id, opps[0].Id);
        tasks = [select Id from Task];
        System.assertEquals(true, tasks.isEmpty());
        Test.stopTest();
    }
}