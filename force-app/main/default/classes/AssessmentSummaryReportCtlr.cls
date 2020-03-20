public with sharing class AssessmentSummaryReportCtlr {
    
    public class AssessmentWrapper{
        @AuraEnabled
        public string lawyer {get; set;}
        @AuraEnabled
        public string lawyerId {get; set;}
        @AuraEnabled
        public string firm {get; set;}
        @AuraEnabled
        public string firmId {get; set;}
        @AuraEnabled
        public decimal approvedCredit {get; set;}
        @AuraEnabled
        public decimal utilizedCreditElfi {get; set;}
        @AuraEnabled
        public decimal utilizedCreditRhino {get; set;}
        @AuraEnabled
        public decimal availableCredit {get; set;}
        @AuraEnabled
        public Boolean checked {get; set;}
        @AuraEnabled
        public String attachmentId{get; set;}
        @AuraEnabled
        public String excelAttachmentId{get; set;}   
        @AuraEnabled
        public decimal preApprovedAmountRhino{get;set;}
        @AuraEnabled
        public decimal preApprovedAmountElfi{get;set;}
        @AuraEnabled
        public decimal approvedLoanRhino{get;set;}
        @AuraEnabled
        public decimal approvedLoanElfi{get;set;}
        
        public AssessmentWrapper(){
            lawyer = '';
            lawyerId = '';
            firm = '';
            firmId = '';
            approvedCredit = 0;
            utilizedCreditElfi = 0;
            utilizedCreditRhino = 0;
            availableCredit = 0;
            preApprovedAmountRhino = 0;
            preApprovedAmountElfi = 0;
            approvedLoanRhino = 0;
            approvedLoanElfi = 0;
            checked = false;
            attachmentId = '';
            excelAttachmentId = '';
        }
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Assessment_Summary_Report__c getCustomSetting(){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());
        return aSR;
    }

    @AuraEnabled 
    public static Drawdown__c getDrawdown(){
        List<Drawdown__c> congaUrlHolder = [Select Conga_Assessment_Summary_Report_View_All__c,
                                            Conga_Assessment_Summary_Report_Print__c
                                            from Drawdown__c limit 1];
        return congaUrlHolder[0];
    }

    @AuraEnabled
    public static void setCustomSetting(List<String> selectedIds, String payoutDate, String reportDate, String businessUnitFilter){
        
        String ids = '';                 

        if(!selectedIds.isEmpty()) {
            ids = String.Join(selectedIds,',');
        }
        Assessment_Summary_Report__c customSettings = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());        
        customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
        customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
        customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
        customSettings.Selected_Ids__c = (!String.isEmpty(ids) && ids != null) ? ids : ''; 
        upsert customSettings;
    }

    @AuraEnabled
    public static void setBusinessUnitCustomSetting(String BusinessUnit){
        Assessment_Summary_Report__c aSR = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());
        aSR.Business_Unit__c = !String.isEmpty(BusinessUnit) && BusinessUnit != null? BusinessUnit : 'ELFI';      
        upsert aSR;
    }
    
    @AuraEnabled 
    public static List<AssessmentWrapper> getAssessmentData(String searchByName, String BusinessUnit, String field, String direction){
        
        List<Opportunity> assessmentOpps = new List<Opportunity>();
        Set<Id> lawyersIdSet = new Set<Id>();
        Map<String, AssessmentWrapper> lawyerAssessmentMap = new Map<String, AssessmentWrapper>();
        Map<String,String> lawyersAttachmentsMap = new Map<String,String>();
        Map<String,String> lawyersExcelAttachmentsMap = new Map<String,String>();        

        try{
            
            String filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            String assessment = 'Assessment';
            
            if(BusinessUnit == 'ELFI'){                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){                
                filterByBusinessUnit = 'Consolidated';
            }
            
            String strQuery = '';            
            strQuery = 'SELECT Id, Lawyer__c, Lawyer__r.Name, Law_Firm__c, Law_Firm__r.Name, Lawyer__r.Approved_Credit_Limit__c, Lawyer__r.Available_Credit__c, Lawyer__r.Utilized_Credit_Limit__c,';
            strQuery += ' Lawyer__r.Pre_approved_Amount_Roll_Up__c, Drawdown_Total_wo_Payment__c, Account.Business_Unit__c, Principal_Repaid_Roll_up__c, Admin_Fee_Roll_up__c, Stage_Status__c';
            strQuery += ' FROM Opportunity';
            strQuery += ' WHERE Type_of_Loan__c =:assessment';
            strQuery += ' AND ((StageName = \'Closed With Loan\'';
            strQuery += ' AND Stage_Status__c = \'Active\')';
            strQuery += ' OR Stage_Status__c = \'Invoice Pre-Approved\')';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' AND (Account.Business_Unit__c =:Elfi OR Account.Business_Unit__c =:Rhino)':
            ' AND Account.Business_Unit__c =:filterByBusinessUnit';            
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Lawyer__r.Name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Law_Firm__r.Name LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';
            
            system.debug('Query');
            system.debug(strQuery);
            
            assessmentOpps = Database.query(strQuery);

            for(Opportunity opp : assessmentOpps){
                lawyersIdSet.add(opp.lawyer__c);
            }

            //query to retrive attached payout attachements
            if(!lawyersIdSet.isEmpty()){
                for(Attachment attach : [SELECT Id, ParentId FROM Attachment Where ParentId In :lawyersIdSet
                                        AND name like '%List of Clients [Assessment Loans] %pdf' 
                                        AND createddate = today order by createddate desc]){
                    if(!lawyersAttachmentsMap.containsKey(attach.ParentId))
                        lawyersAttachmentsMap.put(attach.ParentId, attach.Id);
                }
                
                for(Attachment attach : [SELECT Id, ParentId, ContentType
                                         FROM Attachment 
                                         WHERE ParentId In :lawyersIdSet
                                         AND name like '%List of Clients [Assessment Loans] %xlsx' 
                                         AND createddate = today
                                         order by createdDate desc]){
                                             if(!lawyersExcelAttachmentsMap.containsKey(attach.ParentId))
                                                 lawyersExcelAttachmentsMap.put(attach.ParentId, attach.Id);
                                         }
            }            
            

            if(!assessmentOpps.isEmpty()){
                String key = '';
                
                for(Opportunity opp : assessmentOpps){
                    key = opp.Lawyer__c + '-' + opp.Law_Firm__c;
                    AssessmentWrapper wrapper = null;
                    if(!lawyerAssessmentMap.containsKey(key))
                        lawyerAssessmentMap.put(key, new AssessmentWrapper());
                    
                    
                    wrapper = lawyerAssessmentMap.get(key);

                    wrapper.attachmentId = '';
                    wrapper.excelAttachmentId = '';

                    if(lawyersAttachmentsMap.containsKey(opp.Lawyer__c))
                        wrapper.attachmentId = '' + lawyersAttachmentsMap.get(opp.Lawyer__c);
                    
                    if(lawyersExcelAttachmentsMap.containsKey(opp.Lawyer__c))
                        wrapper.excelAttachmentId = '' + lawyersExcelAttachmentsMap.get(opp.Lawyer__c);
                    
                    wrapper.lawyerId =  opp.Lawyer__c;
                    wrapper.lawyer = opp.Lawyer__r.Name;
                    wrapper.firm = opp.Law_Firm__r.Name;
                    wrapper.firmId = opp.Law_Firm__c;
                    wrapper.approvedCredit = opp.Lawyer__r.Approved_Credit_Limit__c != null? opp.Lawyer__r.Approved_Credit_Limit__c : 0;
                    
                    
                    
                    Decimal principalRepaidAmnt = opp.Principal_Repaid_Roll_up__c;
                    Decimal drawdownTotalAmntWoPymnt = opp.Drawdown_Total_wo_Payment__c;
                    //Drawdown_Total_wo_Payment__c
                    
                    wrapper.preApprovedAmountRhino += opp.Account.Business_Unit__c == 'Rhino' && opp.Stage_Status__c !=null && opp.Stage_Status__c == 'Invoice Pre-Approved'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0 : 0;
                    wrapper.preApprovedAmountElfi += opp.Account.Business_Unit__c == 'ELFI'  && opp.Stage_Status__c !=null && opp.Stage_Status__c == 'Invoice Pre-Approved'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0 : 0;
                    
                    wrapper.approvedLoanElfi += opp.Account.Business_Unit__c == 'ELFI' && opp.Stage_Status__c !=null && opp.Stage_Status__c != 'Invoice Pre-Approved'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                    wrapper.approvedLoanRhino += opp.Account.Business_Unit__c == 'Rhino' && opp.Stage_Status__c !=null && opp.Stage_Status__c != 'Invoice Pre-Approved'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                    
                    wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                    //wrapper.utilizedCreditElfi += opp.Account.Business_Unit__c == 'ELFI'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
                    wrapper.utilizedCreditElfi -= opp.Account.Business_Unit__c == 'ELFI'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                    
                    wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0 : 0;
                    //wrapper.utilizedCreditRhino += opp.Account.Business_Unit__c == 'Rhino'? opp.Admin_Fee_Roll_up__c !=null? opp.Admin_Fee_Roll_up__c :0 : 0;
                    
                    wrapper.utilizedCreditRhino -= opp.Account.Business_Unit__c == 'Rhino'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                    
                    wrapper.availableCredit = opp.Lawyer__r.Available_Credit__c != null? opp.Lawyer__r.Available_Credit__c : 0;

                    lawyerAssessmentMap.put(key, wrapper);
                }
            }
            
        }catch(Exception e){
            system.System.debug(e.getMessage() + ' ' + e.getLineNumber());
            system.System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getLineNumber());
        }

        setBusinessUnitCustomSetting(BusinessUnit);
        return lawyerAssessmentMap.values();
    }
    
    @AuraEnabled
    public static List<Account> getClientAccounts(String lawyerId, String businessUnitFilter){
        
        String filterByBusinessUnit = '';
        if(businessUnitFilter == 'ELFI'){                
            filterByBusinessUnit = 'ELFI';
        }else if(businessUnitFilter == 'Rhino'){                
            filterByBusinessUnit = 'Rhino';
        }else{
            filterByBusinessUnit = 'Consolidated';
        }
        
        String query = '';
        query += 'SELECT Id, AccountNumber, Name_Formula__c, Date_of_Advance__c, Total_Client_Rebate__c,';
        query += ' Total_Amount_Loaned__c, All_Payout_Balance__c, Total_Rebate_Discount__c';
        query += ' FROM Account';
        query += ' WHERE Id in (SELECT AccountId FROM Opportunity WHERE Lawyer__c = :lawyerId';
        query += ' AND isClosed = true AND isWon = true AND Stage_Status__c != \'Paid Off\'';
        query += filterByBusinessUnit != 'Consolidated'? ' AND Account.Business_Unit__c =:filterByBusinessUnit' : '';
        query += ' AND Type_of_Loan__c = \'Assessment\')';
        
        return Database.query(query);
    }
    
    public static void updateSelectedForAssessmentField(Set<Id> accIds){
        system.debug('accIds size ' + accIds.size());
        system.debug('accIds ' + accIds);
        
        if(!accIds.isEmpty()) Database.executeBatch(new Batch_UpdateSelectedForAssessmentPayout(accIds, false), 50);
        
        Database.executeBatch(new Batch_UpdateSelectedForAssessmentPayout(accIds, true), 50);
        
    }
    
    public static void abortExistingJobs(){
        for ( AsyncApexJob aJob : [ SELECT Id ,Status, ApexClass.Name 
                                   FROM AsyncApexJob
                                   WHERE Status!='Aborted'
                                   AND (ApexClass.Name = 'Batch_UpdatePayoutDateOnOppty'
                                        OR ApexClass.Name = 'Batch_UpdateSelectedForAssessmentPayout')
                                   and Status!='Completed' ] ){
                                       
                                       System.AbortJob(aJob.Id);
                                       
                                   }
    }
    
     /******************* Method to generate the payout balance *********************/
    public static void generatePayoutBalance(Date payoutDate, String businessUnitFilter, String ids, Set<Id> accountIds){
        try{

            String assessment = 'Assessment';
            String paidOff = 'Paid Off';

            String strQueryOpportunity = '';
            strQueryOpportunity = 'SELECT Id, Name, Payout_Date__c, Lawyer__c';
            strQueryOpportunity += ' FROM Opportunity';
            strQueryOpportunity += ' WHERE Type_of_Loan__c =:assessment';
            strQueryOpportunity += ' AND isClosed = true AND isWon = true';
            strQueryOpportunity += ' AND Stage_Status__c !=:paidOff';            
            strQueryOpportunity += (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? 
                ' AND Account.Business_Unit__c =:businessUnitFilter': '';
            if(!String.isEmpty(ids))
                strQueryOpportunity += ' AND Lawyer__c in (' + ids +')';
            strQueryOpportunity += !accountIds.isEmpty()? ' AND AccountId IN :accountIds' : '';

            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>((List<Opportunity>)Database.query(strQueryOpportunity));
            
            //Selected_for_Assessment_Payout__c
            /*
            for(Opportunity opp : opportunities){
                opp.Payout_Date__c = payoutDate;
            }
            
            if(!opportunities.isEmpty())
                update opportunities;
*/
            abortExistingJobs();
            updateSelectedForAssessmentField(accountIds);
            Database.executeBatch(new Batch_UpdatePayoutDateOnOppty(opportunities.keySet(), payoutDate), 50);
        }catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Id generate(List<String> selectedIds, String payoutDate, String reportDate, String businessUnitFilter, Map<String,List<Id>> selectedIdsMap){
        Set<Id> accountIds = new Set<Id>();
        try{            
            system.debug('selectedOppIdsMap ' + selectedIdsMap);
            system.debug(JSON.serialize(selectedIdsMap));
            
            for(String key : selectedIdsMap.keySet())
                accountIds.addAll(selectedIdsMap.get(key));
            
            String filterByBusinessUnit = '';
            if(businessUnitFilter == 'ELFI'){                
                filterByBusinessUnit = 'ELFI';
            }else if(businessUnitFilter == 'Rhino'){                
                filterByBusinessUnit = 'Rhino';
            }
            
            APXT_BPM__Conductor__c conductor;
            APXTConga4__Conga_Merge_Query__c congaQuery;        
            String ids = '';
            String query = '';
            String assessment = 'Assessment';            

            if(!selectedIds.isEmpty()) {
                ids = String.Join(selectedIds,',');
                query = 'select id from contact WHERE Id in ('+ ids +')';
            }else{
                query = 'SELECT Id FROM contact where id in (SELECT lawyer__c from opportunity WHERE Type_of_Loan__c = \'Assessment\'';
                query += (filterByBusinessUnit == 'ELFI') ? ' AND Account.Business_Unit__c =\'ELFI\')' : 
                (filterByBusinessUnit == 'Rhino') ? ' AND Account.Business_Unit__c =\'Rhino\')' : ')';
            }
            
            Assessment_Summary_Report__c customSettings = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
            customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
            customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';

            generatePayoutBalance(customSettings.Payout_Date__c, customSettings.Business_Unit__c, ids, accountIds);
            
            if(String.isEmpty(customSettings.Conga_Conductor_Id__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Assessment Lawyer query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of assessment loan summary for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Assessment Lawyer - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer__c');
                insert conductor;            
                customSettings.Conga_Conductor_Id__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conga_Conductor_Id__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer__c';
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
    public static void setConductorURLfield(Id conductorId, Boolean setPDFfield){
        try{
            APXT_BPM__Conductor__c conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:conductorId];
            conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer__c';
            if(setPDFfield)
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Loans_Lawyer_PDF__c';
            
            update conductor;
            
        }catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static Decimal getBatchJobStatus(){
        List<AsyncApexJob> aaj = null;
        Decimal batchJobProgress = 0.0;
        Decimal jobItemsProcessed = 0.0;
        Decimal totalJobItems = 0.0;
        Integer count = 0;
        
        try{
            //Batch_UpdateSelectedForAssessmentPayout
            for(AsyncApexJob apexBatchJob : [SELECT Id, ApexClassId, Status, NumberOfErrors, 
                                             TotalJobItems, JobItemsProcessed, createdDate 
                                             FROM AsyncApexJob
                                             WHERE ApexClass.Name = 'Batch_UpdateSelectedForAssessmentPayout'
                                             AND Status != 'Aborted'
                                             order by CreatedDate DESC LIMIT 2]){
                                                 if(apexBatchJob.Status == 'Processing' || apexBatchJob.Status == 'Completed' ||
                                                    apexBatchJob.Status == 'Holding'){
                                                     jobItemsProcessed += apexBatchJob.JobItemsProcessed;
                                                     totalJobItems += apexBatchJob.TotalJobItems;
                                                 }
                                                 count++;
                                             }
            
            aaj = [SELECT Id, ApexClassId, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, createdDate FROM AsyncApexJob
                   WHERE ApexClass.Name = 'Batch_UpdatePayoutDateOnOppty' AND Status != 'Aborted' order by CreatedDate DESC LIMIT 1];
            
            if(!aaj.isEmpty() && (aaj[0].Status == 'Processing' || aaj[0].Status == 'Completed' || aaj[0].Status == 'Holding')){
                jobItemsProcessed += aaj[0].JobItemsProcessed;
                totalJobItems += aaj[0].TotalJobItems;
                count++;
            }
            if(totalJobItems == 0)
                totalJobItems++;
            batchJobProgress = ((jobItemsProcessed/totalJobItems) * 100);
            
            if(count == 0)
                batchJobProgress = 100;
            
            
            system.debug('batchJobProgress ' + batchJobProgress);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
        return batchJobProgress;
    }
}