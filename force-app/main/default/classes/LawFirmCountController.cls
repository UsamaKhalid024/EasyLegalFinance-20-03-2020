public with sharing class LawFirmCountController {
	
	 /******************* Method to get all picklists values for Account *********************/  
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    /******************* Method to return all lawyers *********************/
    @AuraEnabled
    public static List<AccountInfo> getLawfirmAccounts(String strQuery, String LoanFilter, String businessUnitFilter, String startDate, String endDate) {
        try{
            system.debug('Query ' + strQuery);
            LoanFilter = String.isEmpty(LoanFilter) ? 'All' : LoanFilter;
            businessUnitFilter = String.isEmpty(businessUnitFilter) ? 'ELFI' :businessUnitFilter;
            system.debug('LoanFilter ' + LoanFilter);
            
            // Initializing the Account variable
            List<AccountInfo> accountInfo = new List<AccountInfo>();
            List<Account> accounts = new List<Account>();

            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);

            Report_Settings__c reportSettings = Report_Settings__c.getOrgDefaults();
            reportSettings.Start_Date__c=startDt;
            reportSettings.End_Date__c=endDt;
            upsert reportSettings;
            
                        
            // *** Still need to handle exceptions ***
            // Executing the query to retrieve the account information
            accounts = Database.query(strQuery);        
            system.debug('Size = ' + accounts.size());
            
            Set<Id> accountIds = new Map<Id,Account>(accounts).keySet();
            for(account acc : accounts)
            {
                System.debug('## getLawfirmAccounts - RESULT: ' + acc.Id);
            }
            
            strQuery = 'Select Law_firm__c, Law_Firm_Lawyer__c, Lawyer__c, AccountId, Loan_Available_to_Drawdown__c from Opportunity where Law_firm__c in :accountIds ';
            strQuery += LoanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c != \'Paid Off\'' : '';
            strQuery += (businessUnitFilter == '' || businessUnitFilter == null) ? ' AND Account.Business_Unit__c = \'ELFI\'' : (businessUnitFilter == 'Consolidated' ? ' AND (Account.Business_Unit__c = \'ELFI\' OR Account.Business_Unit__c = \'Rhino\')' : ' AND Account.Business_Unit__c = :businessUnitFilter');
            
            List<Opportunity> oppties = new List<Opportunity>();
            oppties = Database.query(strQuery);
            Map<Id,Set<Id>> lawfirmToClients = new Map<Id,Set<Id>>();
            
            for(Opportunity opp : oppties)
            {
                if(!lawfirmToClients.containsKey(opp.Law_firm__c))
                {
                    lawfirmToClients.put(opp.Law_firm__c, new Set<Id>());
                }
                lawfirmToClients.get(opp.Law_firm__c).add(opp.AccountId);
            }
            
            for(account a : accounts)
            {
                AccountInfo info = new AccountInfo();
                info.account = a;
                info.noOfFiles = lawfirmToClients.containsKey(a.Id) ? lawfirmToClients.get(a.Id).size() : 0;
                if(info.noOfFiles > 0)
                {
                    accountInfo.add(info);
                }
            }
            return accountInfo;
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage());
        }
    }    
    @AuraEnabled
    public static Id send(String query, List<String> selectedIds, String payoutDate, String reportDate, String emailRecipientId, String emailBody, String LoanFilter, String businessUnitFilter){       
        try{
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'SELECT Id FROM Account WHERE Id in ('+ ids +')';
            }        
            
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date_Law_Firm_Report__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date_Law_Firm_Report__c;
            customSettings.Report_Date_Law_Firm_Report__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date_Law_Firm_Report__c;
            customSettings.Email_Additional_Notes_Law_Firm_Report__c = emailBody;
            customSettings.Email_To_Id_Law_Firm_Summary__c = (!String.isEmpty(emailRecipientId) && emailRecipientId != null) ? emailRecipientId : '';
            customSettings.Query_Selector_Law_Firm_Report__c = LoanFilter;
            customSettings.Business_Unit_Lawfirm_Summary__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            
            if(String.isEmpty(customSettings.Conductor_Id_Law_Firm_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Law firm summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of law firm summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Law Firm Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Law_Firm_Summary_Send_Email__c');
                insert conductor;            
                customSettings.Conductor_Id_Law_Firm_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Law_Firm_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Law_Firm_Summary_Send_Email__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;
        }
        catch(exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Id generate(String query, List<String> selectedIds, String payoutDate, String reportDate, String LoanFilter, String businessUnitFilter){
		
        try{
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'SELECT Id FROM Account WHERE Id in ('+ ids +')';
            }
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date_Law_Firm_Report__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date_Law_Firm_Report__c;
            customSettings.Report_Date_Law_Firm_Report__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date_Law_Firm_Report__c;
            //customSettings.Email_To_Id_Law_Firm_Summary__c = (!String.isEmpty(emailRecipientId) && emailRecipientId != null) ? emailRecipientId : '';
            customSettings.Query_Selector_Law_Firm_Report__c = LoanFilter;
            customSettings.Business_Unit_Lawfirm_Summary__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            
            if(String.isEmpty(customSettings.Conductor_Id_Law_Firm_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Law firm summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of law firm summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Law Firm Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Law_Firm_Summary__c');
                insert conductor;            
                customSettings.Conductor_Id_Law_Firm_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Law_Firm_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Law_Firm_Summary__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;
        }
        catch(exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    public class AccountInfo{
        @AuraEnabled
        public Account account{get;set;}
        
        @AuraEnabled
        public Integer noOfFiles{get;set;} 
        
        @AuraEnabled
        public Boolean checked{get;set;} 
    }
}