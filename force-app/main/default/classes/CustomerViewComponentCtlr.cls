public class CustomerViewComponentCtlr {
    
    public static Account accInfo {get;set;}
    public static Opportunity oppInfo {get;set;}
    public static List<Opportunity> oppList {get;set;}
    
    /******************* Method to return all details from the account *********************/
    @AuraEnabled
    public static Account getAccountInfo(String accountId) {
        // Initializing the account variable
        accInfo = new Account();
        
        // Adding all account fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Account.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Owner.Name');        
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Account WHERE Id =: accountId';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the account information
        accInfo = Database.query(strQuery);        
        System.debug('## getAccountInfo - RESULT: ' + accInfo); 
        return accInfo;
    } 
    
    public class NoteWrapper{
        @AuraEnabled public String body{get;set;}
        @AuraEnabled public ContentNote note{get;set;}
    }
    
    @AuraEnabled
    public static void updateContentNote(String cnoteId, String body){
        ContentNote n = new ContentNote();
        try{
            if(!String.isEmpty(cnoteId)){
                n.Id = cnoteId;
                n.Title = 'N/A';
                n.Content = Blob.valueOf(body.escapeJava().escapeHtml3().escapeHTML4());
                update n;  
            }
            
        }catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static void delContentNote(String cnoteId){
        ContentNote n = new ContentNote();
        try{
            n.Id = cnoteId;
            delete n;
        }catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }
    }
    
    /******************* Method to return all notes for the account *********************/
    @AuraEnabled
    public static List<NoteWrapper> getEnhancedNotes(String accountId) {
        Set<Id> noteIds = new SEt<Id>();
        List<Account> acc = [Select id ,
                             (Select id from AttachedContentNotes)
                             from account
                             where id = :accountId];
        for(AttachedContentNote n : acc[0].AttachedContentNotes)
        {
            noteIds.add(n.Id);
        }
        List<NoteWrapper> notes = new List<NoteWrapper>();
        for(ContentNote n : [Select id, Title, content, createddate, lastmodifiedbyId, LastModifiedBy.Name, createdbyId, createdBy.Name, TextPreview 
                             from ContentNote
                             where id in:noteIds order by createdDate desc])
        {
            NoteWrapper w = new NoteWrapper();
            //21 august 2019: 
            //Fahad: 
            //removed escapeUnicode() because " was being replaced by \"
            w.body = n.content.toString().unescapeHtml4().unescapeHtml3().unescapeJava();
            w.note = n;
            notes.add(w);
        }
        
        
        return notes;
    }
    
    /******************* Method to return all related opportunities for the account *********************/
    @AuraEnabled
    public static List<Opportunity> getOpportunities(String accountId){
        // Initializing the list variable
        oppList = new List<Opportunity>();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Account.AccountNumber'); 
        lstFields.add('Account.Name');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE AccountId =: accountId AND Re_Assessed_Loan__c = null order by Loan_Requests__c DESC';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        oppList = Database.query(strQuery);
        
        //Opportunity lastOppty = oppList.isEmpty() ? null : oppList[oppList.size()-1];
        String lastOpptyId = oppList.isEmpty() ? null : oppList[oppList.size()-1].Id;
        System.debug('## getOpportunities - RESULT: ' + oppList);      
        Opportunity newOppTab = new Opportunity(Name = '', 
                                                StageName='Prospecting', 
                                                closeDate = Date.today(), 
                                                AccountId=accountId,
                                                Id=lastOpptyId/*,
ownerId = userinfo.getUserId(),
Lawyer__c = (lastOppty == null ? null : lastOppty.Lawyer__c),
Law_Firm__c = (lastOppty == null ? null : lastOppty.Law_Firm__c),
Date_Financing_Statement_Done__c = (lastOppty == null ? null : lastOppty.Date_Financing_Statement_Done__c),
Date_Financing_Statement_Expires__c = (lastOppty == null ? null : lastOppty.Date_Financing_Statement_Expires__c)*/);
        //oppList.add(newOppTab);
        return oppList;        
    }
    
    /******************* Method to return all related opportunities to generate the payout *********************/
    @AuraEnabled
    public static List<Opportunity> getOpportunitiesToGeneratePayout(String accountId){
        // Initializing the list variable
        oppList = new List<Opportunity>();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE AccountId =: accountId AND StageName != \'Closed No Loan\' AND Stage_Status__c NOT IN (\'Closed - Paid\', \'Closed - Surplus\', \'Closed - Shortfall\', \'Closed - BadDebt\') order by Loan_Requests__c DESC';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        oppList = Database.query(strQuery);
        
        return oppList;        
    }    
    
    /******************* Method to return all related opportunities for the account ASC ORDER*********************/
    @AuraEnabled
    public static List<Opportunity> getOpportunitiesOrderedByDate(String accountId){
        // Initializing the list variable
        oppList = new List<Opportunity>();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Account.AccountNumber'); 
        lstFields.add('Account.Name');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE AccountId =: accountId AND Re_Assessed_Loan__c = null order by Date_of_advance__c ASC, Loan_Requests__c ASC';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        oppList = Database.query(strQuery);    
        Opportunity lastOppty = oppList.isEmpty() ? null : oppList[oppList.size()-1];
        System.debug('## getOpportunities - RESULT: ' + oppList);      
        Opportunity newOppTab = new Opportunity(Name = '', 
                                                StageName='Prospecting', 
                                                closeDate = Date.today(), 
                                                AccountId=accountId,
                                                Id=lastOppty.Id/*,
ownerId = userinfo.getUserId(),
Lawyer__c = (lastOppty == null ? null : lastOppty.Lawyer__c),
Law_Firm__c = (lastOppty == null ? null : lastOppty.Law_Firm__c),
Date_Financing_Statement_Done__c = (lastOppty == null ? null : lastOppty.Date_Financing_Statement_Done__c),
Date_Financing_Statement_Expires__c = (lastOppty == null ? null : lastOppty.Date_Financing_Statement_Expires__c)*/);
        //oppList.add(newOppTab);
        return oppList;        
    }    
    
    /******************* Method to return a single opportunity related to the account *********************/
    @AuraEnabled
    public static Opportunity getSingleOpportunity(String oppId){
        // Initializing the list variable
        Opportunity opp = new Opportunity();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE Id =: oppId limit 1';    
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        opp = Database.query(strQuery);          
        
        return opp;
    }    
    
    /******************* Method to receive payments *********************/
    @AuraEnabled
    public static List<Opportunity> calculatePayments(String accountId, Decimal amount, String searchType){    
        cleanTempPayments(accountId);        
        
        List<Opportunity> optsList = getOpportunitiesOrderedByDate(accountId);        
        List<Opportunity> openOpsList = new List<Opportunity>();
        for(Opportunity opp : optsList){
            System.debug(searchType + ' '  + opp.Stage_Status__c);
            if ((searchType == 'Payout' && opp.Stage_Status__c != 'Paid Off') ||
                (searchType == 'Misc Income Payment' && opp.StageName == 'Closed With Loan' && (opp.Stage_Status__c == 'Closed - Paid' || opp.Stage_Status__c == 'Closed - Surplus' || opp.Stage_Status__c == 'Closed - Shortfall' || opp.Stage_Status__c == 'Closed - Bad Debt')) ||
                (searchType == 'Refund')){
                    openOpsList.add(opp);
                }
        }
        
        system.debug('## openOpsList.size() ' + openOpsList.size());
        
        if (searchType == 'Refund'){
            if (openOpsList.size() > 0){
                Opportunity opp = openOpsList.get(openOpsList.size() - 1);
                opp.Temp_Payment_Received__c = -amount;
                update opp;
            }
            return getOpportunities(accountId);
        }        
        Integer helper = 0;
        Decimal amountRemaining = amount;
        for(Opportunity opp : openOpsList){
            helper = helper + 1;
            
            system.debug('## helper.size() ' + helper);    
            
            system.debug('AMOUNT REMAINING BEFORE PAYMENT >> ' + amountRemaining);
            system.debug('TOTAL PAYOUT BEFORE PAYMENT >> ' + opp.Total_Payout__c);
            
            
            
            // This for the last opty in case we have more payment than expected
            if(amountRemaining > 0 && helper == openOpsList.size()){
                opp.Temp_Payment_Received__c = amountRemaining;
                amountRemaining = 0;
            } else 
                // This is the full payment, when we have enough for the payout
                if(amountRemaining > 0 && opp.Total_Payout__c > 0 && amountRemaining >= opp.Total_Payout__c){
                    opp.Temp_Payment_Received__c = opp.Total_Payout__c;    
                    amountRemaining = amountRemaining - opp.Total_Payout__c;
                } else 
                    // This is the partial payment, when we don't have enough for the payout
                    if(amountRemaining > 0 && amountRemaining < opp.Total_Payout__c) {
                        opp.Temp_Payment_Received__c = amountRemaining;    
                        amountRemaining = amountRemaining - opp.Total_Payout__c;                    
                    }           
            
            system.debug('AMOUNT REMAINING AFTER PAYMENT >> ' + amountRemaining);            
        }
        
        update optsList;        
        return getOpportunities(accountId);
    }
    
    /******************* Method to change an opportunity to bad debt *********************/
    @AuraEnabled
    public static void changeToBadDebtStage(String oppId, String accountId, String payoutDate){                
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = opp.Total_Payout__c;
        dd.Payment_Method__c = 'Payment';
        dd.Reference_Notes__c = 'Bad Debt';
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;   
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;
        opp.Stage_Status__c = 'Closed - Bad Debt';
        opp.Loan_Status__c = 'Closed - Bad Debt';
        update opp;
        
        
    }
    
    /******************* Method to change an opportunity to surplus stage *********************/
    @AuraEnabled
    public static void changeToSurplusStage(String oppId, String accountId, String payoutDate){                
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = opp.Surplus__c;
        //dd.Interest_Repaid__c = opp.Surplus__c;
        dd.Payment_Method__c = 'Payment';
        dd.Reference_Notes__c = 'Payment Surplus';
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        insert dd;
        List<Drawdown__c> drawdownList = [Select id, Surplus__c from Drawdown__c where Opportunity__c = :oppId and Payment_Method__c = 'Payment'];
        for (Drawdown__c d : drawdownList ){
            d.Surplus__c = 0;
        }
        update drawdownList;
        
        opp.Temp_Payment_Received__c = 0;
        opp.Stage_Status__c = 'Closed - Surplus';
        opp.Loan_Status__c = 'Closed - Surplus';
        update opp;        
    }
    
    /******************* Method to change an opportunity to shortfall stage *********************/
    @AuraEnabled
    public static void changeToShortfallStage(String oppId, String accountId, String payoutDate){                
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = opp.Total_Payout__c;
        dd.Payment_Method__c = 'Payment';
        dd.Reference_Notes__c = 'Payment Shortfall';
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;
        opp.Stage_Status__c = 'Closed - Shortfall';
        opp.Loan_Status__c = 'Closed - Shortfall';
        update opp;
        
    }    
    
    /******************* Method to save a partial payment *********************/
    @AuraEnabled
    public static void applyPartialPayments(String oppId, String accountId, String payoutDate, String eft, String chq){            
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        if(opp.Temp_Payment_Received__c > opp.Total_Payout__c){
            dd.Amount__c = opp.Total_Payout__c;
            dd.Surplus__c = opp.Temp_Payment_Received__c - opp.Total_Payout__c;
        } else {
            dd.Amount__c = opp.Temp_Payment_Received__c;        
        }
        dd.Payment_Method__c = 'Payment';
        dd.Reference_Notes__c = 'Partial Payment';
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        dd.EFT__c = eft;
        dd.CHQ__c = chq;
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;   
        opp.Stage_Status__c = 'Active - Partial Payment';
        opp.Loan_Status__c = 'Active - Partial Payment';
        update opp;
        
    }
    
    /******************* Method to save a full payment *********************/
    @AuraEnabled
    public static void applyFullPayments(String oppId, String accountId, String searchType, String payoutDate, String eft, String chq){            
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = opp.Temp_Payment_Received__c;
        dd.Payment_Method__c = 'Payment';        
        dd.Reference_Notes__c = searchType == 'Payout' ? 'Loan Payout' : (searchType == 'Misc Income Payment' ? 'Miscellaneous Payment' : null);        
            dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        dd.EFT__c = eft;
        dd.CHQ__c = chq;        
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;
        opp.Stage_Status__c = 'Closed - Paid';
        opp.Total_Service_Providers_Allowance__c = 0;
        opp.Loan_Status__c = 'Closed - Paid';
        update opp;
        
    }    
    
    @AuraEnabled
    public static void applyMiscPayments(String oppId, String accountId, String payoutDate, String eft, String chq){            
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = opp.Temp_Payment_Received__c;
        dd.Payment_Method__c = 'Payment';        
        dd.Reference_Notes__c = 'Miscellaneous Payment';        
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        dd.EFT__c = eft;
        dd.CHQ__c = chq;        
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;
        update opp;
        
    }    
    
    @AuraEnabled
    public static void applyRefund(String oppId, String accountId, String payoutDate, String eft, String chq){            
        Opportunity opp = getSingleOpportunity(oppId);
        Drawdown__c dd = new Drawdown__c();
        
        dd.Amount__c = -opp.Temp_Payment_Received__c;
        dd.Payment_Method__c = 'Other';        
        dd.Reference_Notes__c = 'Refund';        
        dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
        dd.Opportunity__c = oppId;        
        dd.EFT__c = eft;
        dd.CHQ__c = chq;        
        insert dd;
        
        opp.Temp_Payment_Received__c = 0;
        update opp;
        
    }    
    
    
    @AuraEnabled
    public static List<Opportunity> closeMultipleLoans(List<Opportunity> opportunitiesList, String accountId, String searchType, String payoutDate){    
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();  
        List<Drawdown__c> drawdownsToCreate = new List<Drawdown__c>();      
        
        
        // Loop through opportunities
        for(Opportunity opportunity : opportunitiesList){
            if(opportunity.Temp_Payment_Received__c == opportunity.Total_Payout__c && opportunity.Stage_Status__c != 'Paid Off'){
                // create drawdown
                Drawdown__c dd = new Drawdown__c();
                dd.Amount__c = opportunity.Temp_Payment_Received__c;
                dd.Payment_Method__c = 'Payment';        
                dd.Reference_Notes__c = searchType == 'Payout' ? 'Loan Payout' : (searchType == 'Misc Income Payment' ? 'Miscellaneous Payment' : null);        
                    dd.Date__c = !String.isBlank(payoutDate) ? Date.valueOf(payoutDate) : System.today();
                dd.Opportunity__c = opportunity.Id;   
                drawdownsToCreate.add(dd);
                
                // update opportunity
                opportunitiesToUpdate.add(new Opportunity(Id=opportunity.Id,Temp_Payment_Received__c=0,Stage_Status__c='Closed - Paid',Total_Service_Providers_Allowance__c=0,Loan_Status__c='Closed - Paid'));
            }
        }
        
        if(!drawdownsToCreate.isEmpty()) insert drawdownsToCreate;
        if(!opportunitiesToUpdate.isEmpty()) update opportunitiesToUpdate;
        
        return  getOpportunities(accountId);
    }    
    
    /******************* Method to get transactions list *********************/
    @AuraEnabled
    public static List<TransactionsWrapper> getTransactions(String accountId) {
        // Grab opps list of the account and convert it to a set
        List<Opportunity> oppsList = getOpportunities(accountId);
        Map<Id, Opportunity> oppsIds = new Map<Id, Opportunity>();
        for(Opportunity o : oppsList){
            oppsIds.put(o.Id,o);
        }
        Set<Id> oppSet = oppsIds.keyset();
        
        // Building the query
        String strQuery = 'SELECT EFT__c, CHQ__c, Amount__c, Reference_Notes__c, Date__c, Opportunity__r.Interest_Rate__c, Opportunity__r.Amount, Opportunity__r.Loan_Requests__c,';
        strQuery += ' Accrued_Interest_as_of_Payout_Date__c, Outstanding_Balance_as_of_Payout_Date__c, Per_Diem_as_of_Payout_Date__c, Payment_Method__c, Payout_Date__c';
        strQuery += ' FROM Drawdown__c where Opportunity__r.AccountId =: accountId order by Opportunity__r.Loan_Requests__c asc, Date__c asc ';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the list
        List<Drawdown__c> drawDownList = Database.query(strQuery);        
        system.debug('## getTransactionsList - RESULT: ' + drawDownList);  
        
        // Building the query for treatment drawdowns
        String strQueryTreatment = 'SELECT Id, Name, Opportunity_Service_Provider_MD__c, Amount__c, Drawdown_Date__c, ';
        strQueryTreatment += 'Payment_Method__c, Reference_Notes__c, Service_Provider_Allowed_Balance__c, Opportunity_Service_Provider_MD__r.Opportunity__c';
        strQueryTreatment += ' FROM Service_Provider_Drawdown__c where Opportunity_Service_Provider_MD__r.Opportunity__c IN :oppSet order by Opportunity_Service_Provider_MD__r.Opportunity__r.Loan_Requests__c asc, Drawdown_Date__c asc ';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the list
        List<Service_Provider_Drawdown__c> treatmentDDs = Database.query(strQueryTreatment);        
        system.debug('## getTransactionsList - RESULT: ' + drawDownList);        
        
        List<TransactionsWrapper> trans = new List<TransactionsWrapper>();
        integer lineAux = 1;
        
        for(Drawdown__c d : drawDownList){
            TransactionsWrapper t = new TransactionsWrapper();
            t.Id = d.Id;
            t.line = lineAux;
            t.eft = d.EFT__c;
            t.chq = d.CHQ__c;
            t.interestRate = d.Opportunity__r.Interest_Rate__c;
            t.description = d.Reference_Notes__c;
            t.opportunityNumber = d.Opportunity__r.Loan_Requests__c;
            if(d.Payment_Method__c != 'Admin Fee'){
                t.paymentAmount = d.Amount__c;
            } else {
                t.adminFee =  d.Amount__c;
            }
            t.totalPerOpportunity = d.Opportunity__r.Amount;
            t.paymentDate = d.Date__c;
            t.accruedInterest = d.Accrued_Interest_as_of_Payout_Date__c;
            t.outstandingBalance = d.Outstanding_Balance_as_of_Payout_Date__c;
            t.perDiem = d.Per_Diem_as_of_Payout_Date__c;
            t.payoutDate = d.Payout_Date__c;
            trans.add(t);
            lineAux++;
        }
        
        return trans;        
    }   
    
    public class OpportunityTransaction{
        @AuraEnabled
        public String Name{get;set;}
        @AuraEnabled
        public String opportunityNumber{get;set;}
        @AuraEnabled
        public List<TransactionsWrapper> transactions{get;set;}
        @AuraEnabled
        public Double paymentAmountSubtotal{get;set;}
        @AuraEnabled
        public Double advanceSubtotal{get;set;}
        @AuraEnabled
        public Double accruedInterestSubtotal{get;set;}
        @AuraEnabled
        public Double outstandingBalanceSubtotal{get;set;}
        @AuraEnabled
        public Double perDiemSubtotal{get;set;}
        
    }
    
    /******************* Method to get transactions list for each oppty *********************/
    @AuraEnabled
    public static List<OpportunityTransaction> getOpptyTransactions(String accountId) {
        try{
            // Grab opps list of the account and convert it to a set
            List<Opportunity> allOppties = getOpportunities(accountId);
            List<Opportunity> oppsList = new List<Opportunity>();
            for(integer i = allOppties.size() - 1 ; i>=0 ; i--)
            {
                oppsList.add(allOppties[i]);
            }
            Map<Id, Opportunity> oppsIds = new Map<Id, Opportunity>();
            Map<Id, List<TransactionsWrapper>> oppToTrans = new Map<Id, List<TransactionsWrapper>>();
            for(Opportunity o : oppsList){
                oppsIds.put(o.Id,o);
                oppToTrans.put(o.Id, new List<TransactionsWrapper>());
            }
            Set<Id> oppSet = oppsIds.keyset();
            
            // Building the query
            String strQuery = 'SELECT Name, EFT__c, CHQ__c, Amount__c, Total_Amount__c, Admin_Fee__c, Reference_Notes__c, Date__c, Opportunity__c, Opportunity__r.Interest_Rate__c, Opportunity__r.Amount, Opportunity__r.Loan_Requests__c,';
            strQuery += ' Total_Outstanding_Balance__c, Total_Accrued_Interest__c, Total_Per_Diem__c, Admin_Outstanding_Balance__c, Admin_Accrued_Interest__c, Admin_Per_Diem__c, Accrued_Interest_as_of_Payout_Date__c,';
            strQuery += ' Outstanding_Balance_as_of_Payout_Date__c, Per_Diem_as_of_Payout_Date__c, Payment_Method__c, Principal_Repaid__c, Payout_Date__c, Formula_Amount__c, Interest_Repaid__c, Principal_Reversed__c, Payment_To_Reverse__r.Payment_Method__c'; 
            strQuery += ' FROM Drawdown__c where reference_notes__c!=\'Referral Fee\' and reference_notes__c!=\'Assessment Fee\' and reference_notes__c!=\'Admin Fee\' and Opportunity__r.AccountId =: accountId order by Opportunity__r.Loan_Requests__c asc, Date__c asc, Name asc ';
            // and reference_notes__c!=\'Admin Fee\'
            // *** Still need to handle exceptions ***
            // Executing the query to retrieve the list
            List<Drawdown__c> drawDownList = Database.query(strQuery);        
            system.debug('## getTransactionsList - RESULT: ' + drawDownList);  
            
            List<TransactionsWrapper> trans = new List<TransactionsWrapper>();
            integer lineAux = 1;
            
            for(Drawdown__c d : drawDownList){
                TransactionsWrapper t = new TransactionsWrapper();
                t.Id = d.Id;
                t.line = lineAux;
                t.eft = d.EFT__c;
                t.chq = d.CHQ__c;
                t.interestRate = d.Opportunity__r.Interest_Rate__c;
                t.description = d.Reference_Notes__c;
                t.opportunityNumber = d.Opportunity__r.Loan_Requests__c;
                //Larry requested to not show admin fee drawdown on transaction table so thefollowing code 
                //is not needed and we can simply pull paymentAmount in all cases
                /*
if(d.Payment_Method__c != 'Admin Fee'){
t.paymentAmount = d.Amount__c;
} else {
t.adminFee =  d.Amount__c;
}
*/
                
                
                t.adminFee =  d.Admin_Fee__c;
                t.paymentMethod = d.Payment_Method__c;
                t.referenceNotes = d.Reference_Notes__c;
                t.totalPerOpportunity = d.Opportunity__r.Amount;
                t.paymentDate = d.Date__c;
                
                if(t.paymentMethod != 'Payment'){
                    if(t.referenceNotes == 'Refund'){                        
                        t.paymentAmount = 0;    
                        t.accruedInterest = -d.Total_Amount__c;
                    } 
                    else{
                        t.paymentAmount = d.Formula_Amount__c;
                        t.accruedInterest = d.Total_Accrued_Interest__c;
                    }
                    t.outstandingBalance = d.Total_Outstanding_Balance__c;
                    t.perDiem = d.Total_Per_Diem__c;
                } else {                    
                    if(t.referenceNotes == 'Payment Surplus' || t.referenceNotes == 'Miscellaneous Payment'){                        
                        t.paymentAmount = 0;    
                        t.accruedInterest = d.Total_Amount__c;
                    } 
                    else if(t.referenceNotes == 'Payment Rejected' || t.referenceNotes == 'Payment Halted' ){
                        if (d.Payment_To_Reverse__r.Payment_Method__c != null && d.Payment_To_Reverse__r.Payment_Method__c == 'Admin Fee'){
                            t.paymentAmount = 0 - ( d.Principal_Repaid__c != null ? d.Principal_Repaid__c : 0 );
                            t.adminFee = 0 - ( d.Principal_Repaid__c != null ? d.Principal_Repaid__c : 0 );
                        }
                        else
                            t.paymentAmount = 0 - ( d.Principal_Repaid__c != null ? d.Principal_Repaid__c : 0 );
                        t.accruedInterest = 0 - ( d.Interest_Repaid__c != null ? d.Interest_Repaid__c : 0 );
                    }
                    else{                    
                        t.paymentAmount = 0 - ( d.Principal_Repaid__c != null ? d.Principal_Repaid__c : 0 );
                        t.accruedInterest = 0 - ( d.Interest_Repaid__c != null ? d.Interest_Repaid__c : 0 );
                    }                    
                    t.outstandingBalance = 0;
                    t.perDiem = 0;
                }
                t.payoutDate = d.Payout_Date__c;
                trans.add(t);
                oppToTrans.get(d.Opportunity__c).add(t);
                lineAux++;
            }
            List<OpportunityTransaction> oppTrans = new List<OpportunityTransaction>();
            for(Opportunity o : oppsList){
                OpportunityTransaction opt = new OpportunityTransaction();
                opt.Name = o.Name;
                opt.opportunityNumber = o.Loan_Requests__c;
                opt.advanceSubtotal = o.Amount;
                opt.transactions = oppToTrans.get(o.Id);
                oppTrans.add(opt);
            }
            for(OpportunityTransaction ot : oppTrans)
            {
                double paymentSubtotal = 0.0;
                //double advanceSubtotal = 0.0;
                double accruedInterestSubtotal = 0.0;
                double outstandingBalanceSubtotal = 0.0;
                double perDiemSubtotal = 0.0;
                for(TransactionsWrapper w : ot.transactions){
                    //if(w.paymentMethod != 'Admin Fee')
                    {
                        paymentSubtotal += w.paymentAmount;
                    }
                    //advanceSubtotal += w.totalPerOpportunity;
                    accruedInterestSubtotal += w.accruedInterest;
                    outstandingBalanceSubtotal += w.outstandingBalance;
                    perDiemSubtotal += w.perDiem;
                }
                ot.paymentAmountSubtotal = paymentSubtotal;
                //ot.advanceSubtotal = advanceSubtotal;
                ot.accruedInterestSubtotal = accruedInterestSubtotal;
                ot.outstandingBalanceSubtotal = outstandingBalanceSubtotal;
                ot.perDiemSubtotal = perDiemSubtotal;
            }
            return oppTrans;
        }
        catch(Exception e){
            throw new AurahandledException(e.getMessage());
        }        
    } 
    
    /******************* Method to get the most recent opportunity in the account *********************/
    @AuraEnabled
    public static Opportunity getRecentOpportunity(String accountId){
        // Initializing the opportunity variable
        oppInfo = new Opportunity();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }        
        
        // Adding some extra related field information
        lstFields.add('Lawyer__r.Name');        
        lstFields.add('Lawyer__r.Phone');
        lstFields.add('Lawyer__r.Email');
        lstFields.add('Law_Firm__r.Name');  
        lstFields.add('Law_Firm__r.BillingCity'); 
        lstFields.add('Law_Firm__r.BillingState'); 
        lstFields.add('Owner.Name');
        lstFields.add('Account.All_Payout_Balance__c');
        lstFields.add('Account.All_Payout_Interest__c');
        lstFields.add('Primary_Contact__r.Email');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE AccountId =: accountId and RecordTypeDev__c != \'Loan_Re_Assessment_Opportunity\' order by Loan_Requests__c DESC limit 1';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the latest opportunity
        List<Opportunity> oppList = Database.query(strQuery);
        if(oppList.size() > 0){
            oppInfo = oppList[0];
        }
        
        System.debug('## getRecentOpportunity - RESULT: ' + oppInfo);
        
        return oppInfo;        
    }
    
    /******************* Method to get the most recent opportunity in the account *********************/
    @AuraEnabled
    public static Opportunity getLastOpportunity(String accountId){
        // Initializing the opportunity variable
        oppInfo = new Opportunity();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }        
        
        // Adding some extra related field information
        lstFields.add('Lawyer__r.Name');        
        lstFields.add('Lawyer__r.Phone');
        lstFields.add('Lawyer__r.Email');
        lstFields.add('Law_Firm__r.Name');  
        lstFields.add('Law_Firm__r.BillingCity'); 
        lstFields.add('Law_Firm__r.BillingState'); 
        lstFields.add('Owner.Name');
        lstFields.add('Account.All_Payout_Balance__c');
        lstFields.add('Account.All_Payout_Interest__c');
        lstFields.add('Account.Total_Rebate_Discount__c');
        
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Opportunity WHERE AccountId =: accountId and RecordTypeDev__c != \'Loan_Re_Assessment_Opportunity\' and (StageName = \'Closed With Loan\' OR StageName = \'Re-Assessment\') order by StageName ASC, Loan_Requests__c DESC limit 1';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the latest opportunity
        List<Opportunity> oppList = Database.query(strQuery);
        if(oppList.size() > 0){
            oppInfo = oppList[0];
        }
        
        System.debug('## getLastOpportunity - RESULT: ' + oppInfo);
        
        return oppInfo;        
    }
    
    /******************* Method to get the Lawyer information *********************/
    @AuraEnabled
    public static Contact getLawyerInfo(String contactId){               
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Contact.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }                
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Contact WHERE Id =: contactId limit 1';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the latest opportunity
        List<Contact> contactsList = Database.query(strQuery); 
        System.debug('## getLawyerInfo - RESULT: ' + contactsList);
        
        if(contactsList.size() > 0){
            return contactsList[0];
        } else {
            return null;        
        }
    }     
    
    /******************* Method to get the most recent contact in the account *********************/
    @AuraEnabled
    public static Contact getLastContact(String accountId){
        // Initializing the opportunity variable
        Contact contact = new Contact();
        
        // Adding all contact fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Contact.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }        
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Contact WHERE AccountId =: accountId order by CreatedDate DESC limit 1';
        
        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the latest contact
        List<contact> conList =  Database.query(strQuery);
        if(conList.size() > 0){
            contact = conList[0];
        }
        
        System.debug('## getLastContact - RESULT: ' + contact);
        
        return contact;        
    }              
    
    /******************* Method to get financing statement history of the account *********************/
    @AuraEnabled
    public static List<Amendment__c> getFinancingStatementHistory(String accountId){    
        
        List<Amendment__c> lstamendent = [Select id,createddate,
                                          Amount__c,
                                          Renewal_date__c,
                                          Renewal_Date_New__c,
                                          Opportunity__c,
                                          Date_Financing_Statement_Done__c,
                                          Date_Financing_Statement_Expires__c,
                                          Opportunity__r.Opportunity_Long_Name__c
                                          from Amendment__c 
                                          where Opportunity__r.accountId=:accountId order by createddate desc];    
        
        return lstamendent;
    }
    
    /******************* Method to get firm history of the account *********************/
    @AuraEnabled
    public static List<Firm__c> getFirmHistory(String accountId){    
        
        Opportunity opp = getLastOpportunity(accountId);
        
        if(opp != null){        
            List<Firm__c> firmList = [Select  id,createddate,
                                      lastmodifieddate,
                                      Law_Firm__c, 
                                      Lawyer__c,
                                      Phone__c,
                                      Email__c,
                                      Date_of_Update__c,
                                      Law_Firm__r.Name,
                                      Lawyer__r.Name
                                      from Firm__c
                                      where Opportunity__c =: opp.Id order by lastmodifieddate DESC];   
            
            return firmList;
        } else {
            return null;
        }
    }    
    
    /******************* Method to get a specific contact history *********************/    
    @AuraEnabled
    public static Contact_History__c getContactHistorySingle(String contactId) {    
        List<Contact_History__c> contactHistory = [Select id,
                                                   lastmodifieddate,
                                                   Address__c,
                                                   Contact__c
                                                   from Contact_History__c 
                                                   where Contact__c=:contactId 
                                                   order by lastmodifieddate desc limit 1];    
        if(contactHistory.size() > 0){
            return contactHistory[0];
        } else {
            return null;
        }
    }    
    
    /******************* Method to get the all contact history of the account *********************/
    @AuraEnabled
    public static List<Contact_History__c> getContactHistory(String accountId){    
        
        List<Contact_History__c> lstConHistory = [Select id,lastmodifieddate,
                                                  Address__c,
                                                  Alternate_Phone__c,
                                                  Date_of_update__c,
                                                  Email__c,Phone__c,
                                                  Contact__c
                                                  from Contact_History__c 
                                                  where Contact__r.AccountId =:accountId 
                                                  order by lastmodifieddate desc];   
        
        return lstConHistory;
    }        
    
    /******************* Method to run payout for all opportunities *********************/    
    @AuraEnabled
    public static List<Opportunity> runPayoutForAllOpps(String accountId, String payoutDate){    
        
        if(payoutDate != null){
            // Grab the list of opportunities for this account
            List<Opportunity> oppsList = getOpportunities(accountId);
            
            for(Opportunity o : oppsList){
                o.Payout_Date__c = Date.valueOf(payoutDate);
                o.Temp_Payment_Received__c = 0;
            }
            
            update oppsList;
        } else {
            throw new AuraHandledException('Date of payment needs to be populated');
        }        
        
        return getOpportunities(accountId);
    }
    
    /******************* Method to clean the temp payment field for all opportunities *********************/    
    @AuraEnabled
    public static void cleanTempPayments(String accountId){        
        
        // Grab the list of opportunities for this account
        List<Opportunity> oppsList = getOpportunities(accountId);
        
        for(Opportunity o : oppsList){
            o.Temp_Payment_Received__c = 0;
        }
        
        if(oppsList.size() != 0){
            update oppsList;
        }
    }    
    
    /******************* Method to get the Loan Summary Information *********************/    
    @AuraEnabled
    public static LoanSummaryWrapper getLoanSummary(String accountId){
        // Initializing the Loan Summary variable
        LoanSummaryWrapper loanSummary = new LoanSummaryWrapper();        
        
        // Grab the most recent opportunity for this account
        Opportunity opp = getLastOpportunity(accountId);
        
        try{
            // Grab opps list of the account and convert it to a set
            List<Opportunity> oppsList = getOpportunities(accountId);
            Set<Id> oppsIds = new Set<Id>();
            for(Opportunity o : oppsList){
                oppsIds.add(o.Id);
            }
            
            system.debug('##### Payout_Interest__c ' + opp.Payout_Interest__c);
            system.debug('##### Payout_Balance__c ' + opp.Payout_Balance__c);
            system.debug('##### Payout_Date__c ' + opp.Payout_Date__c);
            system.debug('##### All_Payout_Balance__c ' + opp.Account.All_Payout_Balance__c);
            system.debug('##### Total_Rebate_Discount__c ' + opp.Account.Total_Rebate_Discount__c);
            
            
            
            // Populating loan summary information
            loanSummary.loanType = opp.Type_of_Loan__c;
            loanSummary.interestRate = opp.Interest_Rate__c;
            loanSummary.minimumInterest = opp.Minimum_Interest_Period__c;
            loanSummary.interestCompoundingPeriod = opp.Interest_Compounding_Period__c;
            loanSummary.compounding = opp.Compounding_Interest__c;
            loanSummary.balanceInterest = opp.Account.All_Payout_Interest__c;
            //loanSummary.balanceOtherFees = opp.Simulation_Payout_Other_Fees__c;
            loanSummary.balance = opp.Account.All_Payout_Balance__c;
            loanSummary.payoutDate = opp.Payout_Date__c;
            loanSummary.rebateDiscount = opp.Account.Total_Rebate_Discount__c;
            
            AggregateResult[] groupedResults = new AggregateResult[]{};
                //if(opp.Type_of_Loan__c == 'Lump-Sum' || opp.Type_of_Loan__c == 'Facility Loan'){
                // Grab loan start date and last payment date from drawdowns
                groupedResults = [Select MAX(Date__c) lastPaymentDate, MIN(Date__c) loanStartDate from Drawdown__c where Opportunity__c =:opp.Id];
            system.debug('### groupedResults: ' + groupedResults[0]);     
            /*}
else {
// Grab loan start date and last payment date from service provider drawdowns
groupedResults = [Select MAX(Drawdown_Date__c) lastPaymentDate, MIN(Drawdown_Date__c) loanStartDate from Service_Provider_Drawdown__c 
where Opportunity_Service_Provider_MD__r.Opportunity__c =:opp.Id];
system.debug('### groupedResults: ' + groupedResults[0]);               
}*/
            // Grab total fees and amount from all oppts
            AggregateResult[] sumOppts = [Select SUM(Admin_Fee__c) totalFees, SUM(Amount) maxLoan from Opportunity where AccountId =:accountId];
            system.debug('### sumOppts: ' + sumOppts[0]);
            
            // Grab total amount of all drawdowns from all oppts
            AggregateResult[] totalDD = [Select sum(Formula_Amount__c) totalAmount, sum(Total_Accrued_Interest__c) totalInterest from Drawdown__c 
                                         WHERE Opportunity__r.AccountId =: accountId 
                                         AND Reference_Notes__c NOT IN ('Admin Fee', 'Assessment Fee', 'Payment Shortfall', 'Bad Debt', 'Surplus', 'Shortfall', 'Partial Payment', 'Loan Payout')
                                         AND (Opportunity__r.Stage_Status__c LIKE 'Active%'
                                              OR Opportunity__r.Stage_Status__c LIKE 'In Progress')];
            system.debug('### totalDD: ' + totalDD[0]);
            
            AggregateResult[] totalReversed = [Select sum(Interest_Reversed__c) interestReversed from Opportunity
                                               WHERE AccountId =: accountId 
                                               AND (Stage_Status__c LIKE 'Active%'
                                                    OR Stage_Status__c LIKE 'In Progress')];
            
            // Grab total amount of all drawdowns from all oppts
            //AggregateResult[] totalDDtreatment = [    Select sum(Amount__c) totalAmount from Service_Provider_Drawdown__c 
            //                                          where Opportunity_Service_Provider_MD__r.Opportunity__c IN :oppsIds];
            
            // Verifying if the drawdowns list is not empty
            if(groupedResults[0] != null){
                // Populating the loan start date and last payment date
                loanSummary.loanStartDate = Date.valueOf(groupedResults[0].get('loanStartDate'));
                loanSummary.lastPaymentDate = Date.valueOf(groupedResults[0].get('lastPaymentDate'));
            }
            
            // Verifying if the opts list is not empty
            if(sumOppts[0] != null){
                //Populating the total amount and total fees
                if(sumOppts[0].get('maxLoan') != null){
                    loanSummary.maxLoanApproved = Decimal.valueOf(String.valueOf(sumOppts[0].get('maxLoan')));
                } else {
                    loanSummary.maxLoanApproved = 0;
                }            
                
                if(sumOppts[0].get('totalFees') != null){
                    loanSummary.balanceFees = Decimal.valueOf(String.valueOf(sumOppts[0].get('totalFees')));
                } else {
                    loanSummary.balanceFees = 0;
                }
            }
            
            // Verifying if the totalDD list is not empty
            if(totalDD[0] != null){
                if(totalDD[0].get('totalAmount') != null){
                    loanSummary.balancePrincipal = Decimal.valueOf(String.valueOf(totalDD[0].get('totalAmount')));
                } else {
                    loanSummary.balancePrincipal = 0;
                }
            }
            
            if(totalReversed[0] != null){
                if(totalReversed[0].get('interestReversed') != null){
                    loanSummary.balancePrincipal += Decimal.valueOf(String.valueOf(totalReversed[0].get('interestReversed')));
                    loanSummary.balanceInterest -= Decimal.valueOf(String.valueOf(totalReversed[0].get('interestReversed')));
                }        
            }
            
            
            /* Verifying if the totalDDtreatment list is not empty
if(totalDDtreatment[0] != null){
if(totalDDtreatment[0].get('totalAmount') != null){
loanSummary.balancePrincipal += Decimal.valueOf(String.valueOf(totalDDtreatment[0].get('totalAmount')));
}        
}*/
            
            system.debug('@@ loanSummary.maxLoanApproved ' + loanSummary.maxLoanApproved);
            system.debug('@@ loanSummary.balancePrincipal ' + loanSummary.balancePrincipal);
            if(loanSummary.maxLoanApproved != null && loanSummary.balancePrincipal != null && loanSummary.balancePrincipal != 0){
                loanSummary.availableCredit = loanSummary.maxLoanApproved - loanSummary.balancePrincipal;
                
                if(loanSummary.availableCredit < 0){
                    loanSummary.availableCredit = 0.0;
                }
            } else {
                loanSummary.availableCredit = 0;
            }
            
            // fetch opportutnities 
            loanSummary.oppsList = [SELECT Id, Name, StageName, Opportunity_Long_Name__c, Stage_Status__c, Loan_Status__c FROM Opportunity WHERE (StageName = 'Closed With Loan' OR StageName = 'Re-Assessment') AND AccountId =: accountId ORDER BY Loan_Requests__c DESC LIMIT 30000];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage() + ' - ' + e.getStackTraceString());
        }
        return loanSummary;
    }
    
    /******************* Method to generate the payout balance *********************/    
    @AuraEnabled
    public static LoanSummaryWrapper generatePayoutBalance(String accountId, String payoutDate){
        
        LoanSummaryWrapper existingLoanSummary = getLoanSummary(accountId);
        List<Opportunity> oppties = getOpportunitiesToGeneratePayout(accountId);
        if(payoutDate != null){
            if(oppties.size() != 0){
                if(existingLoanSummary.interestRate != null && existingLoanSummary.minimumInterest != null && (existingLoanSummary.interestCompoundingPeriod == 'Simple Interest' || 
                                                                                                               (existingLoanSummary.interestCompoundingPeriod == 'Compounding Interest'  && existingLoanSummary.compounding != null))){
                                                                                                                   try{
                                                                                                                       for(Opportunity opp : oppties){
                                                                                                                           opp.Payout_Date__c = Date.valueOf(payoutDate); 
                                                                                                                       }
                                                                                                                       update oppties;
                                                                                                                   }
                                                                                                                   catch (DMLException e){
                                                                                                                       throw new AuraHandledException(e.getDmlMessage(0));
                                                                                                                   } 
                                                                                                               } else {
                                                                                                                   throw new AuraHandledException('Payout generation is not available when the account set up is not complete.'); 
                                                                                                               }
            } else {
                throw new AuraHandledException('You can only generate payout for active opportunities.');    
            }
        } else {
            throw new AuraHandledException('Payout date needs to be populated');
        }
        
        LoanSummaryWrapper updatedLoanSummaryWrapper = getLoanSummary(accountId);
        return updatedLoanSummaryWrapper;
    }    
    
    /******************* Method to get all labels for Account *********************/    
    @AuraEnabled
    public static Map<String,String> getAccountLabelsMap(){
        
        Map<String,String> labelsMap = new Map<String,String>();
        Map<String,Schema.SObjectField> fMap = Account.sObjectType.getDescribe().fields.getMap(); 
        for(SObjectField field:fMap.values()){
            labelsMap.put(field.getDescribe().getName(), field.getDescribe().getLabel());
        }
        
        System.debug('FM: labelsMap'+labelsMap);
        return labelsMap;
    }   
    
    /******************* Method to get all picklists values for Account *********************/  
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
        /*
List < String > allOpts = new List < String > ();
// Get the object type of the SObject.
Schema.sObjectType objType = Schema.getGlobalDescribe().get(objectType);

// Describe the SObject using its object type.
Schema.DescribeSObjectResult objDescribe = objType.getDescribe();

// Get a map of fields for the SObject
map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();

// Get the list of picklist values for this field.
list < Schema.PicklistEntry > values =
fieldMap.get(field).getDescribe().getPickListValues();

// Add these values to the selectoption list.
for (Schema.PicklistEntry a: values) {
allOpts.add( a.getValue());
}
system.debug('allOpts ---->' + allOpts);
//allOpts.sort();
return allOpts;*/
    }       
    
    /******************* Method to save the Account Information *********************/        
    @AuraEnabled
    public static void saveAccount(Account account){
        system.debug('## saveAccount ' + account);
        try{
            update account;
        } catch (DMLException e){
            throw new AuraHandledException(e.getDmlMessage(0));
        }     
    }
    
    /******************* Method to save the Opportunity Information *********************/        
    @AuraEnabled
    public static void saveOppty(Opportunity opp){
        try {
            RDS_CustomerCtlr.runFirstTime = true;
            upsert opp; 
            RDS_CustomerCtlr.runFirstTime = false;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }       
    }    
    
    /******************* Method to save the Contact Information *********************/        
    @AuraEnabled
    public static void saveContact(Contact contact){
        system.debug('## saveContact ' + contact);
        try{
            upsert contact;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    /******************* Method to delete the Account record *********************/ 
    @AuraEnabled
    public static void deleteAccount(String accountId){
        if(accountId != null){
            Account acc = new Account(Id=accountId);
            delete acc;
        }
    }
    
    /******************* Wrapper Class for Loan Summary *********************/    
    public class LoanSummaryWrapper{
        @AuraEnabled
        public string loanType {get;set;}
        @AuraEnabled
        public Date loanStartDate {get;set;}
        @AuraEnabled
        public Date lastPaymentDate {get;set;}
        @AuraEnabled
        public decimal maxLoanApproved {get;set;}
        @AuraEnabled
        public decimal interestRate {get;set;}        
        @AuraEnabled
        public string minimumInterest {get;set;}
        @AuraEnabled
        public string compounding {get;set;} 
        @AuraEnabled 
        public String interestCompoundingPeriod {get; set;}
        @AuraEnabled
        public decimal balancePrincipal {get;set;}          
        @AuraEnabled
        public decimal balanceInterest {get;set;}          
        @AuraEnabled
        public decimal balanceFees {get;set;}          
        @AuraEnabled
        public decimal balanceOtherFees {get;set;}    
        @AuraEnabled
        public decimal balance {get;set;}     
        @AuraEnabled
        public decimal availableCredit {get;set;} 
        @AuraEnabled
        public Date payoutDate {get;set;} 
        @AuraEnabled
        public List<Opportunity> oppsList {get; set;}
        @AuraEnabled
        public decimal rebateDiscount {get;set;}
    }
    
    /******************* Wrapper Class for Transactions *********************/    
    public class TransactionsWrapper{
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public integer line {get;set;}
        @AuraEnabled
        public string description {get;set;}
        @AuraEnabled
        public string opportunityNumber {get;set;}        
        @AuraEnabled
        public Date paymentDate {get;set;} 
        @AuraEnabled
        public Date payoutDate {get;set;}         
        @AuraEnabled
        public decimal paymentAmount {get;set;}    
        @AuraEnabled
        public decimal adminFee {get;set;}
        @AuraEnabled
        public decimal totalPerOpportunity {get;set;}      
        @AuraEnabled
        public decimal interestRate {get;set;} 
        @AuraEnabled
        public string eft {get;set;}
        @AuraEnabled
        public string chq {get;set;}
        @AuraEnabled
        public decimal accruedInterest {get;set;}
        @AuraEnabled
        public decimal outstandingBalance {get;set;}
        @AuraEnabled
        public decimal perDiem {get;set;}  
        @AuraEnabled
        public string paymentMethod {get;set;}   
        @AuraEnabled
        public string referenceNotes {get;set;}          
    }  
    /*******************get Latest oppty orderd by Loan request*******************/
    @AuraEnabled
    public static Opportunity getLatestOppty(String accId)
    {
        List<Opportunity> oppties = [Select Id, Primary_Contact__c from Opportunity where AccountId = :accId order by Loan_Requests__c DESC limit 1];
        return oppties.isEmpty() ? null : oppties[0];
    }
    
    @AuraEnabled
    public static void createRecord (String nt, id PrentId){
        
        nt = nt.escapeJava();
        nt = nt.escapeHtml3();
        nt = nt.escapeHtml4();
        //nt = String.escapeSingleQuotes(nt).escapeHtml3().escapeHtml4().escapeUnicode().escapeJava();
        system.debug(nt);
        try{
            if(nt != null){
                ContentNote cn = new ContentNote();  
                cn.Title = 'N/A';
                cn.Content = Blob.valueOf(nt);
                insert cn;
                ContentDocument cd=[select id from ContentDocument where id=:cn.Id];
                ContentDocumentLink cdl=new ContentDocumentLink();
                cdl.ContentDocumentId=cd.id;
                cdl.LinkedEntityId=PrentId;
                cdl.ShareType='V';
                cdl.Visibility='AllUsers';
                insert cdl;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static User getCurrentUserInfo(){
        User currentUser = [SELECT Id,isActive,ProfileId, Custom_Reports__c, Drawdowns__c, Loan_Overview_Edit__c,
                            Financing_Statement_Details__c, Loan_Set_up__c, Lump_Sum_drawdowns__c, 
                            Treatment_Providers__c,Payments_tab__c, Schedule_Payments__c,
                            Modify_Notes__c, Payout_Details__c, Can_Send_for_Google_Review__c
                            FROM User Where Id = :UserInfo.getUserId()];
        return currentUser;
    } 
    
    /******************* Method to get the critical dates list *********************/
    @AuraEnabled
    public static List<Critical_Date__c> getCriticalDatesList(String accountId) {
        List<Critical_Date__c> criticalDateList = new List<Critical_Date__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Critical_Date__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Critical_Date__c WHERE Account__c =: accountId order by Date__c';
        criticalDateList = Database.query(strQuery);         
        return criticalDateList;        
    }
    
    /******************* Method to save CriticalDates list *********************/
    @AuraEnabled
    public static void saveCriticalDateList(List<Critical_Date__c> criticalDateList){
        try{
            upsert criticalDateList;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    /******************* Method to delete Critical Date *********************/
    @AuraEnabled
    public static void deleteCriticalDate(String recordId){
        Critical_Date__c cd = new Critical_Date__c();
        cd.Id = recordId;        
        try{
            delete cd;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }    
    
    @AuraEnabled
    public static List<Opportunity> applyPayment(String accountId, String payoutDate, String searchType, String eft, String chq, String oppId, String action, Boolean isLastPayment){   
        Savepoint sp = null;
        try{
            sp = Database.setSavepoint();
            System.debug('AP: '+ oppId + ' ' + action + ' ' + Limits.getQueries() ); 
            if (action == 'Partial Payment'){
                applyPartialPayments(oppId, accountId, payoutDate, eft, chq);
            }
            else if (action == 'Misc Income Payment'){
                applyMiscPayments(oppId, accountId, payoutDate, eft, chq);
            }
            else if (action == 'Refund'){
                applyRefund(oppId, accountId, payoutDate, eft, chq);
            }   
            else if (action == 'Bad Debt'){
                changeToBadDebtStage(oppId, accountId, payoutDate);
            }
            else if (action == 'Closed Paid'){
                applyFullPayments(oppId, accountId, searchType, payoutDate, eft, chq);
            }
            else if (action == 'Surplus'){
                changeToSurplusStage(oppId, accountId, payoutDate);
            }
            else if (action == 'Shortfall'){
                changeToShortfallStage(oppId, accountId, payoutDate);
            }
            if (isLastPayment)   
                deletePaymentTasks(accountId);
            deletePaymentApplyingErrorTasks(accountId, oppId);
            System.debug('AP1: '+ oppId + ' ' + action + ' ' + Limits.getQueries() ); 
        }
        catch (DMLException e){
            if (sp != null)
                Database.rollback(sp);
            System.debug('DML Exception ' +e.getMessage());            
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            if (sp != null)
                Database.rollback(sp);            
            System.debug('Exception ' + e.getMessage());            
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        if (isLastPayment)
            return getOpportunities(accountId);
        else
            return new List<Opportunity>();
    }   
    
    @AuraEnabled
    public static void createPaymentTask(String accountId, Decimal amount, String eft, String chq){
        Account account = [select Id, Name from Account where Id=:accountId];
        Task task = new Task();        
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.WhatId = accountId;
        task.Subject = 'Complete posting payment of $' + formatAsCurrency(amount) + ' for ' + account.Name;
        String comment = 'Payment of $' + formatAsCurrency(amount);
        if (eft != null)
            comment += ' with EFT # of ' + eft;       
        if (chq != null)
            comment += ' and CHQ # of ' + chq;
        comment += ' was calculated but not applied to ' + account.Name;
        System.debug(task.Subject);
        System.debug(comment);
        task.Description = comment;
        insert task;
    }    
    
    @AuraEnabled
    public static List<Opportunity> calculatePayments(String accountId, Decimal amount, String eft, String chq, String searchType){
        try{
            List<Opportunity>  opps = calculatePayments(accountId, amount, searchType);
            if (amount == 0.0)
                deletePaymentTasks(accountId);
            else
                createPaymentTask(accountId, amount, eft, chq);
            return opps;
        }  
        catch (DMLException e){
            System.debug('DML Exception ' +e.getMessage());
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        }        
        catch (Exception e){
            System.debug('Exception ' + e.getMessage());
            throw new AuraHandledException('Error:'+e.getMessage());
        }   
    }
    @AuraEnabled
    public static void deletePaymentTasks(String accountId){
        System.debug('deletePaymentTasks ' + accountId);
        Task[] tasks = [select Id from Task where accountId=:accountId and Subject Like 'Complete posting payment of%'];
        delete tasks;
    }
    
    private static String formatAsCurrency(Decimal x){
        String y = String.valueOf(x);
        String delimiter = '.';
        if (y.contains(',')) delimiter = ',';
        if (y.contains(delimiter)){
            y = y.substring(0, y.indexOf(delimiter));
            if(x - Decimal.valueOf(y) == 0)
                return String.valueOf(x.format()) + delimiter + '00';
            else return String.valueOf(x.format());            
        }
        return String.valueOf(x.format()) + delimiter + '00';
        
    }
    
    @AuraEnabled
    public static void createPaymentApplyingErrorTask(String accountId, String oppId){ 
        Account account = [select Id, Name from Account where Id=:accountId];
        Opportunity opp = [select Id, Name, Loan_Requests__c from Opportunity where Id=:oppId];
        Task task = new Task();        
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.WhatId = accountId;
        task.Subject = 'Payment allocation failed';
        task.Description = 'Payment was not applied to: ' + opp.Name + ' ' + opp.Loan_Requests__c + '.';
        insert task;
    }    
    
    @AuraEnabled
    public static void deletePaymentApplyingErrorTasks(String accountId, String oppId){
        Opportunity opp = [select Id, Name, Loan_Requests__c from Opportunity where Id=:oppId];        
        Task[] tasks = [select Id,Subject, Description from Task where accountId=:accountId and Subject Like 'Payment allocation failed%'];
        List<Task> tasksToDelete = new List<Task>();
        String description = 'Payment was not applied to: ' + opp.Name + ' ' + opp.Loan_Requests__c + '.';
        for (Task task : tasks){
            if (task.Description == description)
                tasksToDelete.add(task);
        }
        if (!tasksToDelete.isEmpty())
            delete tasksToDelete;
    }
	
    @AuraEnabled
    public static List<ApprovalHistoryWrapper> getApprovalProcessHistoryInfo(String recordId){
        
        List<ApprovalHistoryWrapper> result = new List<ApprovalHistoryWrapper>();
        Map<Id,Custom_Approval_History__c> processInstanceToCustApprovalMap = new Map<Id,Custom_Approval_History__c>();
        Map<Id, ProcessInstance> processInstanceMap = new Map<Id, ProcessInstance>([SELECT Id, Status, CompletedDate, 
                                                                                    LastActor.Name, SubmittedById 
                                                                                    FROM ProcessInstance 
                                                                                    Where TargetObjectId =:recordId
                                                                                    AND Status != 'Removed'
                                                                                    order by LastModifiedDate desc]);
        
        
        for(Custom_Approval_History__c cah : [SELECT Id, Process_Instance_Id__c, Owner.Name,
                                              Value_to_Approve__c, Account__c, Loan_To_Value__c
                                              FROM Custom_Approval_History__c
                                              WHERE Process_Instance_Id__c in :processInstanceMap.keySet()]){
                                                  processInstanceToCustApprovalMap.put(cah.Process_Instance_Id__c, cah);
                                              }
        
        for(ProcessInstance pi : processInstanceMap.values()){
            result.add(
                new ApprovalHistoryWrapper(
                    pi.Status, 
                    pi.LastActor.Name, 
                    processInstanceToCustApprovalMap.containsKey(pi.Id)? processInstanceToCustApprovalMap.get(pi.id).Value_to_Approve__c : '',
                    pi.CompletedDate,
                    processInstanceToCustApprovalMap.containsKey(pi.Id)? processInstanceToCustApprovalMap.get(pi.id).Loan_To_Value__c : 0,
                    processInstanceToCustApprovalMap.containsKey(pi.Id)? processInstanceToCustApprovalMap.get(pi.id). Owner.Name : ''
                )
            );
        }
        system.debug('--------');
        system.debug(result);
        return result;
    }
	
    public Class ApprovalHistoryWrapper{
        
        @AuraEnabled
        public String Status;
        
        @AuraEnabled
        public DateTime CompletedDate;
        
        @AuraEnabled
        public String LastActorName;
        
        @AuraEnabled
        public String ValueToApprove;
        
        @AuraEnabled
        public Decimal LTV;
        
        @AuraEnabled
        Public String RequestedBy;
        
        public ApprovalHistoryWrapper(String statusParam, String actorName, String value, DateTime completedDateParam, Decimal loanToValue, String reqBy){
            Status = statusParam;
            LastActorName = actorName;
            ValueToApprove = value;
            CompletedDate = completedDateParam;
            LTV = loanToValue/100;
            RequestedBy = reqBy;
            
        }
        
    }    
}