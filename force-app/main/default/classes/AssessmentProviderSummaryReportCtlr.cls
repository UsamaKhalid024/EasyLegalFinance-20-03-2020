public with sharing class AssessmentProviderSummaryReportCtlr {
    
    public class AssessmentWrapper{
        @AuraEnabled
        public string assessmentProvider {get; set;}
        @AuraEnabled
        public string assessmentProviderId {get; set;}
        @AuraEnabled
        public List<DataWrapper> dataList{get;set;}
        @AuraEnabled
        public decimal totalApprovedCredit {get; set;}
        @AuraEnabled
        public decimal totalUtilizedCreditElfi {get; set;}
        @AuraEnabled
        public decimal totalUtilizedCreditRhino {get; set;}
        @AuraEnabled
        public decimal totalAvailableCredit {get; set;}
        @AuraEnabled
        public Boolean checked {get; set;}
        @AuraEnabled
        public String attachmentId{get; set;}
        @AuraEnabled
        public String excelAttachmentId{get; set;}        
        @AuraEnabled
        public decimal totalPreApprovedAmount{get;set;}

        public AssessmentWrapper(){
            assessmentProvider = '';
            assessmentProviderId = '';
            totalApprovedCredit = 0;
            totalUtilizedCreditElfi = 0;
            totalUtilizedCreditRhino = 0;
            totalAvailableCredit = 0;
            checked = false;
            attachmentId = '';
            excelAttachmentId = '';
            dataList = new List<dataWrapper>();
            totalPreApprovedAmount = 0;
        }
    }
    
    public class DataWrapper{
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
        public decimal discount {get; set;}
        @AuraEnabled
        public decimal preApprovedAmount{get;set;}
        
        public DataWrapper(){
            lawyer = '';
            lawyerId = '';
            firm = '';
            firmId = '';
            approvedCredit = 0;
            utilizedCreditElfi = 0;
            utilizedCreditRhino = 0;
            availableCredit = 0;
            discount = 0;
            preApprovedAmount = 0;
        }
    }
    
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Assessment_Provider_Summary_Report__c getCustomSetting(){
        Assessment_Provider_Summary_Report__c aProviderSR = Assessment_Provider_Summary_Report__c.getInstance(UserInfo.getUserId());
        return aProviderSR;
    }

    @AuraEnabled 
    public static Drawdown__c getDrawdown(){
        List<Drawdown__c> congaUrlHolder = [Select Conga_Assessment_Provider_Report_ViewAll__c,
                                            Conga_Assessment_Provider_Report_Print__c
                                            from Drawdown__c limit 1];
        return congaUrlHolder[0];
    }

    @AuraEnabled
    public static void setCustomSetting(List<String> selectedIds, String payoutDate, String reportDate, String businessUnitFilter){
        
        String ids = '';                 

        if(!selectedIds.isEmpty()) {
            ids = String.Join(selectedIds,',');
        }
        Assessment_Provider_Summary_Report__c customSettings = Assessment_Provider_Summary_Report__c.getInstance(UserInfo.getUserId());        
        customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
        customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
        customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';
        customSettings.Selected_Ids__c = (!String.isEmpty(ids) && ids != null) ? ids : ''; 
        upsert customSettings;
    }

    @AuraEnabled
    public static void setBusinessUnitCustomSetting(String BusinessUnit){
        Assessment_Provider_Summary_Report__c aProviderSR = Assessment_Provider_Summary_Report__c.getInstance(UserInfo.getUserId());
        aProviderSR.Business_Unit__c = !String.isEmpty(BusinessUnit) && BusinessUnit != null? BusinessUnit : 'ELFI';      
        upsert aProviderSR;
    }
    
    @AuraEnabled 
    public static List<AssessmentWrapper> getAssessmentData(String searchByName, String BusinessUnit, String field, String direction){
        
        List<AssessmentWrapper> result = new List<AssessmentWrapper>();
        List<AggregateResult> aggResultList = new List<AggregateResult>();
        Map<String, AssessmentWrapper> providerToAssessmentMap = new Map<String,AssessmentWrapper>();
        Set<Id> assessmentProviderIdSet = new Set<Id>();
        Set<Id> lawyerIdSet = new Set<Id>();
        
        Set<Id> lawyersIdSet = new Set<Id>();
        
        Map<String, DataWrapper> lawyerAssessmentMap = new Map<String, DataWrapper>();
        Map<String,String> providerAttachmentsMap = new Map<String,String>();
        Map<String,String> providerExcelAttachmentsMap = new Map<String,String>();
        Map<String,Decimal> providerLawyerDiscountMap = new Map<String,Decimal>();

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
            strQuery += 'SELECT Assessment_Provider__c providerId, Assessment_Provider__r.Name providerName,Account.Business_Unit__c businessUnit,';
            strQuery += ' Lawyer__c lawyerId, Lawyer__r.Name lawyerName, Law_Firm__c lawfirmId, Law_Firm__r.Name lawfirmName,';
            strQuery += ' Max(Lawyer__r.Approved_Credit_Limit__c) approvedCredit, Max(Lawyer__r.Available_Credit__c) availableCredit,';
            strQuery += ' Max(Lawyer__r.Pre_approved_Amount_Roll_Up__c) preApprovedAmount,';
            strQuery += ' Sum(Drawdown_Total_wo_Payment__c) invoice, Sum(Principal_Repaid_Roll_up__c) paid, Sum(Admin_Fee_Roll_up__c) adminFee';
            strQuery += ' FROM Opportunity';
            strQuery += ' WHERE Type_of_Loan__c =:assessment';
            strQuery += ' AND StageName != \'Closed No Loan\'';
            strQuery += ' AND Assessment_Provider__c !=null';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' AND (Account.Business_Unit__c =:Elfi OR Account.Business_Unit__c =:Rhino)':
            ' AND Account.Business_Unit__c =:filterByBusinessUnit';            
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Lawyer__r.Name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Law_Firm__r.Name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Assessment_Provider__r.Name LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' group by Assessment_Provider__c, Assessment_Provider__r.Name, Account.Business_Unit__c, Lawyer__c,Lawyer__r.Name,Law_Firm__c, Law_Firm__r.Name';
            strQuery += ' order by Assessment_Provider__r.Name, ' + field + ' ' + direction + ' NULLS LAST';
                      
            aggResultList = Database.query(strQuery);
            
            String key = '';
            for(AggregateResult ars : aggResultList){
                assessmentProviderIdSet.add((String)ars.get('providerId'));
                lawyerIdSet.add((String)ars.get('lawyerId'));
                key = ars.get('providerId') + '-' + ars.get('lawyerId') + '-' + ars.get('lawfirmId');
                DataWrapper wrapper = null;
                if(!lawyerAssessmentMap.containsKey(key))
                    lawyerAssessmentMap.put(key, new DataWrapper());
                
                wrapper = lawyerAssessmentMap.get(key);
                
                wrapper.lawyerId =  (String)ars.get('lawyerId');
                wrapper.lawyer = (String)ars.get('lawyerName');
                wrapper.firm = (String)ars.get('lawfirmName');
                wrapper.firmId = (String)ars.get('lawfirmId');
                wrapper.approvedCredit = ars.get('approvedCredit') != null? (Decimal)ars.get('approvedCredit') : 0;
                wrapper.preApprovedAmount = ars.get('preApprovedAmount') != null? (Decimal)ars.get('preApprovedAmount') : 0;
                
                Decimal principalRepaidAmnt = ars.get('paid') != null? (Decimal)ars.get('paid') : 0;
                Decimal drawdownTotalAmntWoPymnt = ars.get('invoice') != null? (Decimal)ars.get('invoice') : 0;
                
                wrapper.utilizedCreditElfi += (String)ars.get('businessUnit') == 'ELFI'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                wrapper.utilizedCreditElfi -= (String)ars.get('businessUnit') == 'ELFI'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                
                wrapper.utilizedCreditRhino += (String)ars.get('businessUnit') == 'Rhino'? drawdownTotalAmntWoPymnt != null? drawdownTotalAmntWoPymnt : 0  : 0;
                wrapper.utilizedCreditRhino -= (String)ars.get('businessUnit') == 'Rhino'? principalRepaidAmnt != null? principalRepaidAmnt : 0  : 0;
                
                wrapper.availableCredit = ars.get('availableCredit') != null? (Decimal)ars.get('availableCredit') : 0;
                
                lawyerAssessmentMap.put(key, wrapper);
            }
            
            //query to get discount rate
            if(!assessmentProviderIdSet.isEmpty()){
                String askey = '';
                for(Assessment_Provider_Schedule__c aProviderSchedule :[SELECT Id, Discount__c, Lawyer__c, Lawyer__r.AccountId, Assessment_Provider__c 
                                                                        FROM Assessment_Provider_Schedule__c WHERE Assessment_Provider__c in :assessmentProviderIdSet 
                                                                        AND lawyer__c in :lawyerIdSet order by CreatedDate desc]){
                                                                            askey = aProviderSchedule.Assessment_Provider__c + '-' + aProviderSchedule.Lawyer__c + '-' + aProviderSchedule.Lawyer__r.AccountId;
                                                                            if(!providerLawyerDiscountMap.containsKey(askey)){
                                                                                providerLawyerDiscountMap.put(askey, aProviderSchedule.Discount__c);
                                                                            }

                }
            }
            //query to retrive attached payout attachements
            if(!assessmentProviderIdSet.isEmpty()){
                for(Attachment attach : [SELECT Id, ParentId FROM Attachment Where ParentId In :assessmentProviderIdSet
                                        AND name like '%List of Clients [Assessment Provider] %pdf' 
                                        AND createddate = today order by createddate desc]){
                    if(!providerAttachmentsMap.containsKey(attach.ParentId))
                        providerAttachmentsMap.put(attach.ParentId, attach.Id);
                }
                
                for(Attachment attach : [SELECT Id, ParentId FROM Attachment Where ParentId In :assessmentProviderIdSet
                                        AND name like '%List of Clients [Assessment Provider] %xlsx' 
                                        AND createddate = today order by createddate desc]){
                    if(!providerExcelAttachmentsMap.containsKey(attach.ParentId))
                        providerExcelAttachmentsMap.put(attach.ParentId, attach.Id);
                }
            }
            AssessmentWrapper mainWrapper = null;
            DataWrapper dataWrapper = null;
            string dataMapKey = '';
            for(AggregateResult ars : aggResultList){
                dataMapKey = ars.get('providerId') + '-' + ars.get('lawyerId') + '-' + ars.get('lawfirmId');
                String aProviderId = (String)ars.get('providerId') != null? (String)ars.get('providerId') : '';
                if(!providerToAssessmentMap.containsKey(aProviderId)){
                    mainWrapper = new AssessmentWrapper();
                    mainWrapper.assessmentProviderId = aProviderId;
                    mainWrapper.assessmentProvider = (String)ars.get('providerName')!= null? (String)ars.get('providerName') : '';
                    providerToAssessmentMap.put(aProviderId, mainWrapper);
                } 
                
                mainWrapper = providerToAssessmentMap.get(aProviderId);
                if(lawyerAssessmentMap.ContainsKey(dataMapKey))
                    dataWrapper = lawyerAssessmentMap.get(dataMapKey);
                
                Decimal lawyerDiscount = 0;
                if(providerLawyerDiscountMap.ContainsKey(dataMapKey))
                    lawyerDiscount = providerLawyerDiscountMap.get(dataMapKey)/100;
                
                dataWrapper.discount = lawyerDiscount;
                mainWrapper.dataList.add(dataWrapper);
                
                mainWrapper.attachmentId = '';
                if(providerAttachmentsMap.containsKey(aProviderId))
                	mainWrapper.attachmentId = providerAttachmentsMap.get(aProviderId);
                
                mainWrapper.excelAttachmentId = '';
                if(providerExcelAttachmentsMap.containsKey(aProviderId))
                	mainWrapper.excelAttachmentId = providerExcelAttachmentsMap.get(aProviderId);
                
                
                mainWrapper.totalApprovedCredit += dataWrapper.approvedCredit;
                mainWrapper.totalUtilizedCreditElfi += dataWrapper.utilizedCreditElfi;
                
                mainWrapper.totalPreApprovedAmount +=  dataWrapper.preApprovedAmount;
                
                mainWrapper.totalUtilizedCreditRhino += dataWrapper.utilizedCreditRhino;
                mainWrapper.totalAvailableCredit += dataWrapper.availableCredit;
                providerToAssessmentMap.put(aProviderId, mainWrapper);
            }
            
            for(AggregateResult ars : aggResultList){
                key = (String)ars.get('providerId') != null? (String)ars.get('providerId') : '';
                if(providerToAssessmentMap.containsKey(key))
                    result.add(providerToAssessmentMap.remove(key));                	
            }
        }catch(Exception e){
            system.System.debug(e.getMessage() + ' ' + e.getLineNumber());
            system.System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getLineNumber());
        }

        setBusinessUnitCustomSetting(BusinessUnit);
        return result;
    }

     /******************* Method to generate the payout balance *********************/
    public static void generatePayoutBalance(Date payoutDate, String businessUnitFilter, String ids){
        try{

            String assessment = 'Assessment';
            String paidOff = 'Paid Off';

            String strQueryOpportunity = '';
            strQueryOpportunity = 'SELECT Id, Name, Payout_Date__c, Lawyer__c';
            strQueryOpportunity += ' FROM Opportunity';
            strQueryOpportunity += ' WHERE Type_of_Loan__c =:assessment';
            strQueryOpportunity += ' AND isClosed = true AND isWon = true';
            strQueryOpportunity += ' AND Stage_Status__c !=:paidOff';  
            strQueryOpportunity += ' AND Assessment_Provider__c !=null';
            strQueryOpportunity += (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? 
                ' AND Account.Business_Unit__c =:businessUnitFilter': '';
            if(!String.isEmpty(ids))
                strQueryOpportunity += ' AND Assessment_Provider__c in (' + ids +')';

            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>((List<Opportunity>)Database.query(strQueryOpportunity));

           /* for(Opportunity opp : opportunities){
                opp.Payout_Date__c = payoutDate;
            }
            
            if(!opportunities.isEmpty())
                update opportunities;*/
            Database.executeBatch(new Batch_UpdatePayoutDateOnOppty(opportunities.keySet(), payoutDate), 50);
        }catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Id generate(List<String> selectedIds, String payoutDate, String reportDate, String businessUnitFilter){
        try{
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
                query = 'select id from Account WHERE Id in ('+ ids +')';
            }else{
                query = 'SELECT Id FROM Account where id in (SELECT Assessment_Provider__c from opportunity WHERE Type_of_Loan__c = \'Assessment\'';
                query += (filterByBusinessUnit == 'ELFI') ? ' AND Account.Business_Unit__c =\'ELFI\')' : 
                (filterByBusinessUnit == 'Rhino') ? ' AND Account.Business_Unit__c =\'Rhino\')' : ')';
            }
            
            Assessment_Provider_Summary_Report__c customSettings = Assessment_Provider_Summary_Report__c.getInstance(UserInfo.getUserId());        
            customSettings.Payout_Date__c = (!String.isEmpty(payoutDate) && payoutDate != null) ? Date.valueOf(payoutDate) : customSettings.Payout_Date__c;
            customSettings.Report_Date__c = (!String.isEmpty(reportDate) && reportDate != null) ? Date.valueOf(reportDate) : customSettings.Report_Date__c;
            customSettings.Business_Unit__c = (!String.isEmpty(businessUnitFilter) && businessUnitFilter != null) ? businessUnitFilter : 'ELFI';

            generatePayoutBalance(customSettings.Payout_Date__c, customSettings.Business_Unit__c, ids);
            
            if(String.isEmpty(customSettings.Conga_Conductor_Id__c)){
                congaQuery = new APXTConga4__Conga_Merge_Query__c(APXTConga4__Name__c = 'Assessment Provider query - ' + UserInfo.getName(),
                                                                  APXTConga4__Description__c = 'Query of assessment Provider summary for conga conductor.',
                                                                  APXTConga4__Query__c = query);
                insert congaQuery;
                conductor = new APXT_BPM__Conductor__c(APXT_BPM__Title__c = 'Mass Assessment Provider - ' + UserInfo.getName(), APXT_BPM__Query_Id__c = congaQuery.Id,
                                                       APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Provider__c');
                insert conductor;            
                customSettings.Conga_Conductor_Id__c = conductor.Id;
            }else{
                conductor = [SELECT Id, APXT_BPM__Query_Id__c, APXT_BPM__URL_Field_Name__c FROM APXT_BPM__Conductor__c WHERE Id =:customSettings.Conga_Conductor_Id__c];
                congaQuery = [SELECT Id, APXTConga4__Query__c FROM APXTConga4__Conga_Merge_Query__c WHERE Id =:conductor.APXT_BPM__Query_Id__c];
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Provider__c';
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
            conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Provider__c';
            if(setPDFfield)
                conductor.APXT_BPM__URL_Field_Name__c = 'Conga_Batch_Assessment_Provider_PDF__c';
            
            update conductor;
            
        }catch(Exception e){
            throw new AuraHandledException('Error Message' + e.getMessage()+e.getStackTraceString());
        }
    }
    
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(){
        List<AsyncApexJob> aaj = null;
        try{
            aaj = [SELECT Id, ApexClassId, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, createdDate FROM AsyncApexJob
                   WHERE ApexClass.Name = 'Batch_UpdatePayoutDateOnOppty' order by CreatedDate DESC LIMIT 1];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
        return (aaj.size() > 0 )? aaj[0] : null;
    }
}