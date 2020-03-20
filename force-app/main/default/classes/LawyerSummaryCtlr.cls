public class LawyerSummaryCtlr {
    /******************* Method to return all lawyers *********************/
    @AuraEnabled
    public static List<ContactInfo> getLawyersContacts(String strQuery, String LoanFilter, String businessUnitFilter) {
        try{
            LoanFilter = String.isEmpty(LoanFilter) ? 'All' : LoanFilter;
            businessUnitFilter = String.isEmpty(businessUnitFilter) ? 'ELFI' :businessUnitFilter;
            system.debug('LoanFilter ' + LoanFilter);
            
            // Initializing the contact variable
            List<ContactInfo> contactInfo = new List<ContactInfo>();
            List<Contact> contacts = new List<Contact>();
            
             system.debug(strQuery);           
            // *** Still need to handle exceptions ***
            // Executing the query to retrieve the account information
            contacts = Database.query(strQuery);        
            
            
            Set<Id> contactIds = new Map<Id,Contact>(contacts).keySet();
            for(contact con : contacts)
            {
                System.debug('## getLawyersContacts - RESULT: ' + con.Id);
            }
            
            strQuery = 'Select Law_Firm_Lawyer__c, Lawyer__c, AccountId, Loan_Available_to_Drawdown__c from Opportunity where Lawyer__c in :contactIds ';
            strQuery += LoanFilter == 'Active'? ' AND isClosed = true AND isWon = true AND Stage_Status__c != \'Paid Off\'' : '';
            strQuery += (businessUnitFilter == '' || businessUnitFilter == null) ? ' AND Account.Business_Unit__c = \'ELFI\'' : ' AND Account.Business_Unit__c = :businessUnitFilter';
            List<Opportunity> oppties = new List<Opportunity>();
            oppties = Database.query(strQuery);
            System.debug('Oppty: Query: '+strQuery);
            Map<Id,Set<Id>> lawyerToClients = new Map<Id,Set<Id>>();
            
            for(Opportunity opp : oppties)
            {
                if(!lawyerToClients.containsKey(opp.Lawyer__c))
                {
                    lawyerToClients.put(opp.Lawyer__c, new Set<Id>());
                }
                lawyerToClients.get(opp.Lawyer__c).add(opp.AccountId);
            }
            
            for(contact c : contacts)
            {
                ContactInfo info = new ContactInfo();
                info.contact = c;
                info.noOfFiles = lawyerToClients.containsKey(c.Id) ? lawyerToClients.get(c.Id).size() : 0;
                if(info.noOfFiles > 0)
                {
                    contactInfo.add(info);
                }
            }
            return contactInfo;
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage());
        }
    }  
    /******************* Method to get all picklists values for Account *********************/  
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    @AuraEnabled
    public static Id send(String query, List<String> selectedIds, String payoutDate, String reportDate, String emailBody, String LoanFilter, String businessUnitFilter){       
        try{
            system.debug('-Here in Send function -');
            system.debug(selectedIds);
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            
            if(String.isEmpty(query) || query == null) {
                ids = String.Join(selectedIds,',');
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }
            
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date_Lawyer_Summary_Report__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date_Lawyer_Summary_Report__c;
            customSettings.Report_Date_Lawyer_Summary_Report__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date_Lawyer_Summary_Report__c;
            customSettings.Business_Unit_Lawyer_Summary__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            customSettings.Email_Additional_Notes_Lawyer_Summary__c = emailBody;
            customSettings.Query_Selector_Lawyer_Summary_Report__c = LoanFilter;        
            
            if(String.isEmpty(customSettings.Conductor_Id_Lawyer_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Lawyer summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of lawyer summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Lawyer Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary_Send_Email__c');
                insert conductor;            
                customSettings.Conductor_Id_Lawyer_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Lawyer_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary_Send_Email__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;
        }
        catch(Exception e){
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
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }
            
            Conga_batch_setting__c customSettings = Conga_batch_setting__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date_Lawyer_Summary_Report__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date_Lawyer_Summary_Report__c;
            customSettings.Report_Date_Lawyer_Summary_Report__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date_Lawyer_Summary_Report__c;
            customSettings.Business_Unit_Lawyer_Summary__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
            customSettings.Query_Selector_Lawyer_Summary_Report__c = LoanFilter;
            
            if(String.isEmpty(customSettings.Conductor_Id_Lawyer_Summary_Report__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Lawyer summary conductor query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of lawyer summary custom report for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Lawyer Summary - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary__c');
                insert conductor;            
                customSettings.Conductor_Id_Lawyer_Summary_Report__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conductor_Id_Lawyer_Summary_Report__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Lawyer_Summary__c';
                update conductor;
                congaQuery.APXTConga4__Query__c = query;
                update congaQuery;
            }
            upsert customSettings;
            return conductor.id;	
        }
        catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    public class ContactInfo{
        @AuraEnabled
        public Contact contact{get;set;}
        
        @AuraEnabled
        public Integer noOfFiles{get;set;} 
        
        @AuraEnabled
        public Boolean checked{get;set;} 
    }
}