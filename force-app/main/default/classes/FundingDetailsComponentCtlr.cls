/**
 * @File Name          : FundingDetailsComponentCtlr.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/11/2019, 5:36:17 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/9/2019, 6:04:59 AM   Seth Boyd     Initial Version
**/
public with sharing class FundingDetailsComponentCtlr {

    /*
	@InvocableMethod(label='Delete Drawdowns' description='Delete Drawdowns')
    public static void invocableDeleteDrawdowns(Id[] rejectionIds){
        Payment_Rejection__c[] rejectionList = [
            Select
                Id,
                Scheduled_Payment__c
            From
                Payment_Rejection__c
            Where
                Id in :rejectionIds
        ];

        Id[] spIds = new Id[]{};
        for (Payment_Rejection__c pr : rejectionList) {
            spIds.add(pr.Scheduled_Payment__c);
        }

        Drawdown__c[] ddList = [Select Id From Drawdown__c Where Scheduled_Payment__c in :spIds];
        if (!ddList.isEmpty()) {
            delete ddList;
        }
    }
    */

    @AuraEnabled(cacheable=False)
    public static Opportunity[] getOpportunitiesWithScheduledPayments(Date startDate, Date endDate){
        String[] allowedStatuses = new String[]{'Loan Setup Check', 'Process Drawdowns', 'Populate PPSA', 'Final Review'};
        String[] spStasuses = new String[]{'Processed by Bank', 'Drawdown Created'};

        Opportunity[] oppList = [
            SELECT
                Id,
                /* Table Fields */
                Loan_Requests__c, Type_of_Loan__c, Admin_Fee__c, Amount, Amount_Paid_to_Borrower__c, Loan_Available_to_Drawdown__c,
                Funding_Details_Status__c, Drawdown_Total__c,
                Account.AccountNumber, Account.Name, Account.Id,
                /* Table Fields */
                /* Loan Details Fields */
                Interest_Rate__c, Interest_Compounding_Period__c, Compounding_Interest__c, Fee_Calculation_Method__c, Fixed_Amount__c,
                Percent_Amount__c, Custommized_Amount__c, Minimum_Interest_Period__c, Interest_Deferral_Period__c, 
                /* Loan Details Fields */
                /* PPSA Fields */
                Date_Financing_Statement_Done__c, Renewal_Date__c, Date_Financing_Statement_Expires__c, Registration_Number__c,
                /* PPSA Fields */
                /* Child Scheduled Payments */
                (
                    SELECT 
                        Id,
                        Notes__c,
                        Hold__c,
                        Current_Bank_Account_Name__c,
                        Current_Bank_Account_Display__c,
                        Current_Bank_Account_URL__c,
                        Triggered_Admin_Fee_Amount__c,
                        Expected_Admin_Fee_Amount__c ,
                        Name,
                        File_Number__c,
                        Opportunity__c,
                        Status__c,
                        Payment_Type__c,
                        Amount__c,
                        Scheduled_Date__c,
                        Send_Cheque__c,
                        Sent_to_Bank_Date__c,
                        Sent_to_Bank_By__r.Name,
                        Account__r.Id,
                        Account__r.Name,
                        Verified_By__r.Name,
                        Verified_Date__c,
                        Current_Account_Id__c,
                        Current_Account_Name__c,
                        Current_Account_URL__c,
                        Transaction_Reference_Number__c,
                        Drawdown_Created__c
                    FROM Scheduled_Payments__r
                    WHERE Status__c in :spStasuses
                    ORDER BY Sent_to_Bank_Date__c ASC
                )
                /* Child Scheduled Payments */
            FROM Opportunity
            WHERE Funding_Details_Status__c In :allowedStatuses // Filter by Id until I can clear out bad data
            ORDER BY Name ASC, Loan_Requests__c ASC
        ];

        return filterOpportunitiesByScheduledPaymentDate(oppList, startDate, endDate);
    }

    @testVisible
    private static Opportunity[] filterOpportunitiesByScheduledPaymentDate(Opportunity[] oppList, Date startDate, Date endDate) {
        // Should return all opportunities and their child payments if any payment meets the filter criteria
        Datetime compareStart = null;
        if (startDate != null) {
            compareStart = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
        }
        Datetime compareEnd = null;
        if (endDate != null) {
            compareEnd = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);
        }

        if (compareStart != null || compareEnd != null) {
            Opportunity[] filteredOpps = new Opportunity[]{};
            for (Opportunity opp : oppList) {
                Boolean keep = false;
                for (Scheduled_Payment__c sp : opp.Scheduled_Payments__r) {
                    if (compareStart != null) {
                        if (compareEnd != null) {
                            if (sp.Sent_to_Bank_Date__c >= compareStart && sp.Sent_to_Bank_Date__c <= compareEnd) {
                                keep = true;
                            }
                        } else {
                            if (sp.Sent_to_Bank_Date__c >= compareStart) {
                                keep = true;
                            }
                        }
                    } else if (compareEnd != null) {
                        if (sp.Sent_to_Bank_Date__c <= compareEnd) {
                            keep = true;
                        }
                    }
                }
                if (keep) {
                    filteredOpps.add(opp);
                }
            }
            return filteredOpps;
        } else {
            return oppList;
        }
    }

    /*
    public static void clearBadTestData() {
        delete [Select Id From Previous_Loan__c Where Scheduled_Payment__c  = 'a1W190000037ktHEAQ'];
        Scheduled_Payment__c spList = [Select Opportunity__c, Payment_Type__c, Previous_Loan__r.Id From Scheduled_Payment__c Where Id = 'a1W190000037ktHEAQ' Limit 1];
        delete spList;
        system.debug(spList);
        for (Scheduled_Payment__c sp : spList) {
            sp.Payment_Type__c = 'Payment to Other Lender';
            update sp;
        }
        //update spList;

        Opportunity[] oppList = FundingDetailsComponentCtlr.getOpportunitiesWithScheduledPayments();
        Opportunity[] updateOpps = new Opportunity[]{};
        for (Opportunity opp : oppList) {
            if (opp.Scheduled_Payments__r.isEmpty()) {
                opp.Funding_Details_Status__c = null;
                updateOpps.add(opp);
            }
        }
        if (!updateOpps.isEmpty()) {
            update updateOpps;
        }
    }
    // FundingDetailsComponentCtlr.clearBadTestData
    */

    @AuraEnabled(cacheable=False)
    public static Map<String, Object> getScheduledPaymentsWithOpportunities(Date startDate, Date endDate, String workflowStage, String dateField) {
        //endDate = Date.valueOf(endDate);
        List<Scheduled_Payment__c> spList;
        String[] statuses;
        String extraWhere = '';

        switch on workflowStage {
            when 'staging'{
                statuses = new String[]{'Scheduled'};
                extraWhere += ' AND Hold__c = false';
            }
            when 'validateEft'{
                statuses = new String[]{'Pre Send Validation'};
                extraWhere += ' AND Send_Cheque__c = false';
            }
            when 'generateBankingSheet' {
                statuses = new String[]{'Approved to Send'};
                extraWhere += ' AND Send_Cheque__c = false';
            }
            when 'validateCheque'{
                statuses = new String[]{'Pre Send Validation'};
                extraWhere += ' AND Send_Cheque__c = true';
            }
            when 'sendCheques' {
                statuses = new String[]{'Approved to Send'};
                extraWhere += ' AND Send_Cheque__c = true';
            }
            when 'updateEFTInfo' {
                statuses = new String[]{'Sent to Bank'};
                extraWhere += ' AND Send_Cheque__c = false';
            }
            when 'processAndValidateLoan' {
                statuses = new String[]{'Processed by Bank', 'Drawdown Created'};
            }
            when 'reviewClosedPayments' {
                statuses = new String[]{'Drawdown Created', 'Closed'};
            }
            when else {
                statuses = new String[]{};//{'Rejected', 'Scheduled', 'Pre Send Validation', 'Approved to Send', 'Sent to Bank', 'Processed by Bank', 'Drawdown Created'};
            }
        }
        Boolean useDateTime = true;
        if (dateField == null || dateField == 'Scheduled_Date__c') {
            dateField = 'Scheduled_Date__c';
            useDateTime = false;
        }
        Datetime compareStart = null;
        if (startDate != null) {
            if ( useDateTime ) {
                compareStart = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day(), 0, 0, 0);
                extraWhere += ' AND ' + String.escapeSingleQuotes(dateField) + ' <= :compareEnd';
            } else {
                extraWhere += ' AND ' + String.escapeSingleQuotes(dateField) + ' <= :endDate';
            }
        }
        Datetime compareEnd = null;
        if (endDate != null) {
            if ( useDateTime ) {
                compareEnd = Datetime.newInstance(endDate.year(), endDate.month(), endDate.day(), 23, 59, 59);
                extraWhere += ' AND ' + String.escapeSingleQuotes(dateField) + ' >= :compareStart';
            } else {
                extraWhere += ' AND ' + String.escapeSingleQuotes(dateField) + ' >= :startDate';
            }
        }
        String query = 
            'SELECT ' +
                'Id, Current_Bank_Account_Name__c, Current_Bank_Account_Display__c, Current_Bank_Account_URL__c, Triggered_Admin_Fee_Amount__c, Expected_Admin_Fee_Amount__c' +
                ', Notes__c, Hold__c' +
                ', Banking_Verified__c, Credit_Verified__c, Documents_Verified__c, BIA_PPSA_LL_Verified__c, Verified_By__c, Verified_By__r.Name, Verified_Date__c' +
                ', Can_Send_to_Bank__c' +
                ', Name, File_Number__c, Opportunity__c, Status__c, Payment_Type__c, Amount__c, Scheduled_Date__c, Send_Cheque__c' +
                ', Sent_to_Bank_Date__c, Sent_to_Bank_By__r.Name, Account__r.Id, Account__r.Name' +
                ', Current_Account_Id__c, Current_Account_Name__c, Current_Account_URL__c, Transaction_Reference_Number__c' +
                ', Drawdown_Date__c, Can_Be_Reversed__c, Drawdown__c' +
            ' FROM Scheduled_Payment__c';
        if(statuses != null) {
            query = query + ' WHERE Status__c in :statuses ';
        }
        query = query + ' {0} ORDER BY Verified_Date__c DESC, Scheduled_Date__c ASC LIMIT 10000';
        query = String.format(query, new List<String>{extraWhere});
        spList = Database.query(query);
        /*
        spList = [
            SELECT 
                Id,
                Name,
                File_Number__c,
                Opportunity__c,
                Status__c,
                Payment_Type__c,
                Amount__c,
                Scheduled_Date__c,
                Sent_to_Bank_Date__c,
                Sent_to_Bank_By__r.Name,
                Account__r.Id,
                Account__r.Name,
                Verified_By__r.Name,
                Verified_Date__c
            FROM Scheduled_Payment__c
            WHERE Scheduled_Date__c <= :filterDate AND Status__c in :statuses
            ORDER BY Verified_Date__c DESC, Scheduled_Date__c ASC
            LIMIT 10000 
        */

        Set<Id> accIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        for (Scheduled_Payment__c sp : spList) {
            accIds.add(sp.Current_Account_Id__c);
            oppIds.add(sp.Opportunity__c);
        }

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT
                Id, Name,
                /* Table Fields */
                Loan_Requests__c, Type_of_Loan__c, Admin_Fee__c, Amount, Amount_Paid_to_Borrower__c, Loan_Available_to_Drawdown__c, 
                Account.AccountNumber, Account.Name, Account.Id,
                /* Table Fields */
                /* Loan Details Fields */
                Interest_Rate__c, Interest_Compounding_Period__c, Compounding_Interest__c, Fee_Calculation_Method__c, Fixed_Amount__c,
                Percent_Amount__c, Custommized_Amount__c, Minimum_Interest_Period__c, Interest_Deferral_Period__c, 
                /* Loan Details Fields */
                /* PPSA Fields */
                Date_Financing_Statement_Done__c, Renewal_Date__c, Date_Financing_Statement_Expires__c, Registration_Number__c
                /* PPSA Fields */
            FROM Opportunity
            WHERE Id in :oppIds
        ]);

        Map<Id, Account> accMap = new Map<Id, Account>([
            SELECT
                Id, Name, BillingAddress, 
                Primary_Contact__r.Name, Primary_Contact__r.MailingAddress
            FROM Account
            WHERE Id in :accIds
        ]);

        Map<String, Object> data = new Map<String, Object>();
        data.put('scheduled_payments', spList);
        data.put('opportunities', oppMap);
        data.put('accounts', accMap);
        return data;
    }
    
    /******************* Method to return all active opportunities *********************/
    /*
    @AuraEnabled
    public static List<Opportunity> getOpportunities(Date endDate, String workflowStage){

        // Initializing the list variable
        List<Opportunity> oppList = new List<Opportunity>();
                  
        return oppList;        
    }
    */
    
    /******************* Method to return a single opportunity *********************/
    /*
    @AuraEnabled
    public static Opportunity getSingleOpportunity(String oppId){
        // Initializing the list variable
        List<Opportunity> oppList = new List<Opportunity>();
        
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
        strQuery += ' FROM Opportunity WHERE Id =: oppId ';

        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        oppList = Database.query(strQuery);
                  system.debug('## oppList[0] ' + oppList[0]);
        return oppList.isEmpty() ? null : oppList[0];       
    }
    */

    /******************* Method to return drawdowns for a single opportunity *********************/
    @AuraEnabled(cacheable=false)
    public static Scheduled_Payment__c[] getScheduledPaymentsByOpp(String oppId, String[] statuses){
        // Initializing the list variable
        Scheduled_Payment__c[] spList = new Scheduled_Payment__c[]{};
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Scheduled_Payment__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Scheduled_Payment__c WHERE Opportunity__c =: oppId';
        if (!statuses.isEmpty()) {
            strQuery += ' AND Status__c in :statuses';
        }

        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        spList = Database.query(strQuery);
        
        return spList;     
    }     

    /******************* Method to return drawdowns for a single opportunity *********************/
    /*
    @AuraEnabled(cacheable=true)
    public static List<Drawdown__c> getDrawdownsByOpp(String oppId){
        // Initializing the list variable
        List<Drawdown__c> ddList = new List<Drawdown__c>();
        
        // Adding all opportunity fields to the query
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Drawdown__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Drawdown__c WHERE Opportunity__c =: oppId ';

        // *** Still need to handle exceptions ***
        // Executing the query to retrieve the opportunities list
        ddList = Database.query(strQuery);
        
        return ddList;     
    }     
    */
    
    /******************* Method to return a single opportunity *********************/
    /*
    @AuraEnabled
    public static Opportunity changeFundingStatus(String oppId, String nextStage){    
     
        Opportunity opp = new Opportunity();
        opp.Id = oppId;
        opp.Funding_Details_Status__c = nextStage;
        update opp;
        
        return getSingleOpportunity(oppId);
    }
    */
    
    /******************* Method to return picklist values *********************/    
    /*
    @AuraEnabled(cacheable=true)
    public static List < String > getPickListValues(String objectType, String field)
    {
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
            allOpts.add( a.getLabel() +'===SEPERATOR==='+ a.getValue());
            //allOpts.add( a.getValue());
        }
        system.debug('allOpts ---->' + allOpts);
        //allOpts.sort();
        return allOpts;
    }    
    */


    /******************* Method to insert a new drawdown *********************/
    /*
    @AuraEnabled
    public static void insertNewDrawdown(String oppId){
        // Copied from OpportunityViewComponentController
        // TODO - Move Drawdown Table functionality to it's own component so we don't have to copy code around
        try {
            Drawdown__c drawdown = new Drawdown__c(Opportunity__c=oppId);            
            insert drawdown;
            DrawdownTriggerHandler.mergeAdminFeeWithFirstDrawdown(new Set<Id>{oppId});
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    */


    /******************* Method to insert a new drawdown *********************/
    @AuraEnabled
    public static Opportunity updateOpportunity(Opportunity opp){
        try {
            update opp;
            return opp;
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }

    @AuraEnabled
    public static Scheduled_Payment__c[] updateScheduledPayments(Scheduled_Payment__c[] scheduledPayments){
        List<Database.SaveResult> updateResults = Database.update(scheduledPayments, false);
        DatabaseErrorAuraHandledExceptionHelper errorHelper = new DatabaseErrorAuraHandledExceptionHelper(scheduledPayments, updateResults);
        if (errorHelper.hasError()) {
            errorHelper.throwException();
        }

        return scheduledPayments;
    }


    @AuraEnabled
    public static Scheduled_Payment__c[] moveToProcessStep(Scheduled_Payment__c[] scheduledPayments){
        // Update Scheduled Payments
        Id[] spIds = new Id[]{};
        for (Scheduled_Payment__c sp : scheduledPayments) {
            sp.Status__c = 'Processed by Bank'; // Set status to next step
            spIds.add(sp.Id);
        }
        List<Database.SaveResult> updateResults = Database.update(scheduledPayments, false);
        DatabaseErrorAuraHandledExceptionHelper errorHelper = new DatabaseErrorAuraHandledExceptionHelper(scheduledPayments, updateResults);
        if (errorHelper.hasError()) {
            errorHelper.throwException();
        }

        // Get list of Opps
        scheduledPayments = [Select Id, Opportunity__c From Scheduled_Payment__c Where Id in :spIds];

        Set<Id> oppIds = new Set<Id>();
        for (Scheduled_Payment__c sp : scheduledPayments) {
            oppIds.add(sp.Opportunity__c);
        }

        // Update Opps Funding_Details_Status__c
        Opportunity[] oppList = new Opportunity[]{};

        for (Id oppId : oppIds) {
            oppList.add(new Opportunity(Id=oppId, Funding_Details_Status__c='Loan Setup Check'));
        }

        updateResults = Database.update(oppList, false);
        errorHelper = new DatabaseErrorAuraHandledExceptionHelper(scheduledPayments, updateResults);
        if (errorHelper.hasError()) {
            errorHelper.throwException();
        }

        return scheduledPayments;
    }

    @AuraEnabled
    public static string generateBankingSheet(Id[] spIds){
        try {
            EFTFile eft = new EFTFile(spIds);
            String fileText;
            fileText = eft.generateFileText();
            return fileText;
        } catch (EFTFileErrorListException e) {
            throw e.generateAuraHandledException();
        } catch (DMLException e){
            throw new AuraHandledException('Error: '+e.getDmlMessage(0));
        } catch (Exception e){
            system.debug(e);
            throw new AuraHandledException('Error: '+e.getMessage());
        }
    }

}
