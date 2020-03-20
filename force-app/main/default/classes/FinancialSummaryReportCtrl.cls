public with sharing class FinancialSummaryReportCtrl {
     @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Financial_Summary_Report__c fsr = Financial_Summary_Report__c.getOrgDefaults();
            
            fsr.End_date__c = endDt;
            fsr.Start_Date__c = startDt;
            
            update fsr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }
    @AuraEnabled
    public static list<Wrapper> getReportDataByProvince(String startDate, String endDate, string BusinessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            string filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            
            // Business Unit Filter

            if(BusinessUnit == 'ELFI'){
                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){
                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){
                
                filterByBusinessUnit = 'Consolidated';
            }
            
            String strQuery = '';
            
            string cheque = 'Cheque';
            string eTransfer = 'e-Transfer';
            string adminFee = 'Admin Fee';
            string otherFee = 'Other Fee';
            string activePartialPayment = 'Active - Partial Payment';
        	String closedWithLoan = 'Closed With Loan';
        	String statusActive = 'Active';
            
            strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Account.ProvinceResidency__c province,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt';
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:statusActive OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND (Payment_Method__c =:cheque or Payment_Method__c =:eTransfer)'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += (filterByBusinessUnit == 'Consolidated') ?
                ' AND (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
            ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            //strQuery += ' (Reference_Notes__c !=:adminFee and Reference_Notes__c !=:otherFee)';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c, Opportunity__r.Account.Business_Unit__c';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            
            list<Wrapper> finalWrapper = new List<Wrapper>();
            if(!aggResult.isEmpty()){
                
                map<string, wrapper> agrMap = new map<string, wrapper>();
                
                for(AggregateResult agr : aggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('province')))){
                       // if province exists 
                       wrapper w = agrMap.get(String.ValueOf(agr.get('province')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoFileCount = Integer.valueof(agr.get('file'));
                            w.rhinoOpptyCount = Integer.valueof(agr.get('opptyCount'));
                            w.rhinoAmount = Double.valueof(agr.get('amt'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiFileCount = Integer.valueof(agr.get('file'));
                            w.elfiOpptyCount = Integer.valueof(agr.get('opptyCount'));
                            w.elfiAmount = Double.valueof(agr.get('amt'));
                        }
                        
                        agrMap.put(String.ValueOf(agr.get('province')), w);
                        
                    }else{
                        // new province
                        wrapper w;
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w = new wrapper(String.ValueOf(agr.get('province')),
                                            Integer.valueof(agr.get('file')),
                                            Integer.valueof(agr.get('opptyCount')),
                                                   Double.valueof(agr.get('amt')),0,0, 0.00);
                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w = new wrapper(String.ValueOf(agr.get('province')),0,0,0.00,
                                            Integer.valueof(agr.get('file')),
                                            Integer.valueof(agr.get('opptyCount')),
                                                   Double.valueof(agr.get('amt')));
                        }
                        agrMap.put(String.ValueOf(agr.get('province')), w);
                    }
                }
                finalWrapper = new list<Wrapper>(agrMap.values());
                return finalWrapper;                
            }
            return finalWrapper;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static Boolean validateReport(String startDate, String endDate){
        String strQuery = '';
        String closedWithLoan = 'Closed With Loan';
        String active = '';
        String activePartialPayment = 'Active - Partial Payment';
        List<Drawdown__c> dList = new List<Drawdown__c>();
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            strQuery = 'Select Id'; 
            strQuery += ' FROM Drawdown__c';
            strQuery += ' WHERE (temp_payout_date__c != :endDt)';
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan'; 
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            dList = Database.query(strQuery);
            if(!dList.isEmpty()){
                return false;
            }
            
        }catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return true;
    }
    
    @AuraEnabled 
    public static void abortBatchJobs(){
        for(AsyncApexJob aJob : [SELECT id FROM AsyncApexJob WHERE Status!='Aborted' AND Status!='Completed'
                                 AND ApexClass.Name = 'FinancialReportCalculateData'] ){                                     
                                     System.AbortJob(aJob.Id);                                     
                                 }
    }
    
    @AuraEnabled 
    public static Id executeBatchJob(Boolean sinceInception, String startDate, String endDate){
        try{
            abortBatchJobs();
            Financial_Summary_Report__c fSR_CustomSetting = Financial_Summary_Report__c.getOrgDefaults();
            fSR_CustomSetting.Start_Date__c = !String.isEmpty(startDate) && startDate != null? Date.valueOf(startDate) : fSR_CustomSetting.Start_Date__c;
            fSR_CustomSetting.End_Date__c = !String.isEmpty(endDate) && endDate != null? Date.valueOf(endDate) : fSR_CustomSetting.End_Date__c;
            fSR_CustomSetting.Report_Date__c = Date.today();
            fSR_CustomSetting.Since_Inception__c = sinceInception;
            upsert fSR_CustomSetting;
            return Database.executeBatch(new FinancialReportCalculateData(Date.valueOf(startDate),
                                                                          Date.valueOf(endDate), sinceInception));
        }catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static FinancialReportDataWrapper getFinancialReportData(String startDate, String endDate, String BusinessUnit){
        
        FinancialReportDataWrapper fReportDataW = new FinancialReportDataWrapper();
        String strQuery = '';
        string cheque = 'Cheque';
        string eTransfer = 'e-Transfer';
        string adminFee = 'Admin Fee';
        string otherFee = 'Other Fee';
        string payment = 'Payment';
        string activePartialPayment = 'Active - Partial Payment';
        String partialPayment = 'Partial Payment';
        String closedWithLoan = 'Closed With Loan';
        String active = 'Active';
        
        BusinessUnit = (!String.isEmpty(BusinessUnit) && BusinessUnit != null)? BusinessUnit : 'ELFI';
        
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            strQuery = 'Select COUNT_DISTINCT(Opportunity__r.AccountId) noOfFiles, COUNT_DISTINCT(Opportunity__c) noOfOppties,'; 
            strQuery += ' SUM(Amount__c) amt,';
            strQuery += ' SUM(Accrued_Interest_In_Reporting_Period__c) accruedInterest,';
            strQuery += ' SUM(Admin_Fee__c) adminFee';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND (Payment_Method__c =:cheque or Payment_Method__c =:eTransfer)'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' AND (Opportunity__r.Account.Business_Unit__c =:BusinessUnit)'; 
            
            //strQuery += ' AND (Reference_Notes__c !=:adminFee and Reference_Notes__c !=:otherFee)';			
            AggregateResult aggResult = Database.query(strQuery); 
            
            if(aggResult != null){
                fReportDataW.noOfFiles = aggResult.get('noOfFiles') != null? (Integer)aggResult.get('noOfFiles') : 0;
                fReportDataW.amountOfAdvances = aggResult.get('amt') != null? (Decimal)aggResult.get('amt') : 0.0;
                //fReportDataW.accruedInterest = aggResult.get('accruedInterest') !=null? (Decimal)aggResult.get('accruedInterest') : 0.0;
                fReportDataW.adminFee = aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.0;                
            }            
            strQuery = 'SELECT SUM(Amount__c) amount';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt';
            strQuery += ' AND Opportunity__r.StageName =:closedWithLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartialPayment)';
            strQuery += ' AND (Payment_Method__c =:payment AND Reference_Notes__c =:partialPayment)'; 
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' AND (Opportunity__r.Account.Business_Unit__c =:BusinessUnit)';            
            
            aggResult = Database.query(strQuery); 
            system.debug(aggResult);
            if(aggResult != null){
                fReportDataW.partialPayment = aggResult.get('amount') != null? (Decimal)aggResult.get('amount') : 0.0;
            }            
            
            strQuery = 'SELECT SUM(Accrued_Interest_In_Reporting_Period__c) accruedInterest';
            strQuery += ' FROM Drawdown__c'; 
            strQuery += ' WHERE Opportunity__r.StageName =:closedWithLoan';
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:active OR Opportunity__r.Stage_Status__c =:activePartialPayment)'; 
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' AND (Opportunity__r.Account.Business_Unit__c =:BusinessUnit)';
            
            aggResult = Database.query(strQuery);
            if(aggResult != null){
                fReportDataW.accruedInterest = aggResult.get('accruedInterest') != null? (Decimal)aggResult.get('accruedInterest') : 0.0;
            }
            
            fReportDataW.total = fReportDataW.amountOfAdvances;
            fReportDataW.total += fReportDataW.accruedInterest;
            fReportDataW.total += fReportDataW.adminFee;            
            fReportDataW.total -= fReportDataW.partialPayment;
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        List<Drawdown__c> congaUrlHolder = [Select Conga_Financial_Summary_Report_Print__c, Conga_Financial_Summary_Report_Print_2__c,Conga_Financial_Summary_Report_View_All__c 
                                            from Drawdown__c limit 1];
        fReportDataW.congaViewAllURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_Financial_Summary_Report_View_All__c;
        fReportDataW.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' : congaUrlHolder[0].Conga_Financial_Summary_Report_Print__c + congaUrlHolder[0].Conga_Financial_Summary_Report_Print_2__c;
        return fReportDataW;        
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
           // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            Financial_Summary_Report__c fsr = Financial_Summary_Report__c.getOrgDefaults();
            
            fsr.BusinessUnit__C = BusinessUnit;
            
            upsert fsr;

        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(){
        List<AsyncApexJob> aaj = null;
        try{
            aaj = [SELECT Id, ApexClassId, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, createdDate FROM AsyncApexJob
                   WHERE ApexClass.Name = 'FinancialReportCalculateData' order by CreatedDate DESC LIMIT 1];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
        return (aaj.size() > 0 )? aaj[0] : null;
    }
    
    @AuraEnabled
    public static Financial_Summary_Report__c getCustomSetting(){
        Financial_Summary_Report__c fSR_CustomSetting = Financial_Summary_Report__c.getOrgDefaults();
        return fSR_CustomSetting;
    }
    
    public class Wrapper {
        @AuraEnabled
        string province {get; set;}
        @AuraEnabled
        integer rhinoFileCount {get; set;}
        @AuraEnabled
        integer rhinoOpptyCount {get; set;}
        @AuraEnabled
        decimal rhinoAmount {get; set;}
        @AuraEnabled
        integer elfiFileCount {get; set;}
        @AuraEnabled
        integer elfiOpptyCount {get; set;}
        @AuraEnabled
        decimal elfiAmount {get; set;}
        
        wrapper(string p, integer rc, integer roc, decimal ra, integer ec, integer eoc, decimal ea){
            
            province = p;
            
            rhinoFileCount = rc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            
            elfiFileCount = ec;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
        }
        
    }
    
    /******************* Wrapper Class for Financial Report Data *********************/
    public Class FinancialReportDataWrapper {
        
        @AuraEnabled
        public Integer noOfFiles{get;set;}
        @AuraEnabled
        public Decimal amountOfAdvances{get;set;}
        @AuraEnabled
        public Decimal adminFee{get;set;}
        @AuraEnabled
        public Decimal accruedInterest{get;set;}
        @AuraEnabled
        public Decimal partialPayment{get;set;}
        @AuraEnabled
        public Decimal total{get;set;}
        @AuraEnabled
        public String congaViewAllURL{get;set;}
        @AuraEnabled
        public String congaPrintReportURL{get;set;}
        
        public FinancialReportDataWrapper(){
            noOfFiles = 0;
            amountOfAdvances = 0.0;
            adminFee = 0.0;
            accruedInterest = 0.0;
            partialPayment = 0.0;
        }
    }    
}