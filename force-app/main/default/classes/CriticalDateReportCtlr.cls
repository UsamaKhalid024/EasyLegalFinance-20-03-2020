public with sharing class CriticalDateReportCtlr {

    // Batch Job
    @AuraEnabled
    public static Boolean validateReport(String startDate, String endDate){
        
        /*
        try{
            Critical_Dates_Report__c csg = getCustomSetting();
            
            List<Drawdown__c> dList = new List<Drawdown__c>();
            
            if(csg.Start_Date__c != csg.Job_Start_Date__c ||
               csg.End_Date__c != csg.Job_End_Date__c){
                   
                   return true;
               }else{
                   
                   string closedPaid = 'Closed - Paid';
                   string closedBadDebt = 'Closed - Bad Debt';
                   string closedBadDebtMakingPayments = 'Closed - Bad Debt - Making Payments';
                   
                   map<id, opportunity> oppIdMap = new map<id, opportunity>([Select Id From Opportunity WHERE 
                                                                              Loan_Status__c !=:closedPaid AND 
                                                Loan_Status__c !=:closedBadDebt AND 
                                                Loan_Status__c !=:closedBadDebtMakingPayments]);

                   set<id> IdStr = new set<id>(oppIdMap.keyset());
                   
                   Datetime reportdate = csg.report_date__c;
                   // check if a new drawdown has been inserted after the report date
                   String query='SELECT id from drawdown__c where lastmodifieddate >:reportdate and opportunity__c in:IdStr';
                   dList = Database.query(query);
                   if(!dList.isEmpty()){
                       return true;
                   }else{
                       
                       list<critical_date__c> cdlist = new list<critical_date__c>();
                       
                       set<id> accountsId = new set<id>();
                   
                       for(Opportunity opp : [Select AccountId From Opportunity WHERE 
                                                                                  Loan_Status__c !=:closedPaid AND 
                                                    Loan_Status__c !=:closedBadDebt AND 
                                                    Loan_Status__c !=:closedBadDebtMakingPayments]){
                           
                           accountsId.add(opp.AccountId);
                       }
                       
                       // lookout for any modified critical items And Dates
                       String cdquery='SELECT id from critical_date__c where lastmodifieddate >:reportdate and '+ 
                           'Account__c in:accountsId';
                       cdlist = Database.query(cdquery);
                       if(!cdlist.isEmpty()){
                           return true;
                       } 
                   }
               }
            
        }catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        */
        return false;
    }
    
    @AuraEnabled 
    public static void abortBatchJobs(){
        for(AsyncApexJob aJob : [SELECT id FROM AsyncApexJob WHERE Status!='Aborted' AND Status!='Completed'
                                 AND ApexClass.Name = 'BatchCriticalDatesPayoutRecalculation'] ){                                     
                                     System.AbortJob(aJob.Id);                                     
                                 }
    }
    
    @AuraEnabled 
    public static Id executeBatchJob(String startDate, String endDate){
        try{
            abortBatchJobs();
            Critical_Dates_Report__c c = Critical_Dates_Report__c.getOrgDefaults();
            c.Start_Date__c = !String.isEmpty(startDate) && startDate != null? Date.valueOf(startDate) : c.Start_Date__c;
            c.End_Date__c = !String.isEmpty(endDate) && endDate != null? Date.valueOf(endDate) : c.End_Date__c;
            c.Job_Start_Date__c = c.Start_Date__c;
            c.Job_End_Date__c = c.End_Date__c;
            c.Report_Date__c = system.now();
            upsert c;
            return Database.executeBatch(new BatchCriticalDatesPayoutRecalculation(Date.valueOf(startDate),
                                                                                   Date.valueOf(endDate)),1);
        }catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    } 
    
    @AuraEnabled
    public static AsyncApexJob getBatchJobStatus(){
        List<AsyncApexJob> aaj = null;
        try{
            aaj = [SELECT Id, ApexClassId, Status, NumberOfErrors, TotalJobItems, JobItemsProcessed, createdDate FROM 
                   AsyncApexJob
                   WHERE ApexClass.Name = 'BatchCriticalDatesPayoutRecalculation' order by CreatedDate DESC LIMIT 1];
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
        return (aaj.size() > 0 )? aaj[0] : null;
    }
    // Batch Job ends
    
    @AuraEnabled
    Public static List<Critical_Date__c> getCriticalDateList(String startDate, String endDate, String businessUnit){
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        string filterByBusinessUnit = '';
        string Elfi = 'ELFI';
        string Rhino = 'Rhino';
        
        if(businessUnit == 'ELFI'){            
            filterByBusinessUnit = 'ELFI';
        }else if(businessUnit == 'Rhino'){            
            filterByBusinessUnit = 'Rhino';
        }else if(businessUnit == 'Consolidated'){            
            filterByBusinessUnit = 'Consolidated';
        }
        
        String strQuery = 'Select Account__c, Name__c, Account__r.Business_Unit__c businessUnit,'+
            'Account__r.AccountNumber accountNumber, Account__r.Name accountName, SUM(Outstanding_Balance_as_of_To_Date__c) '+ 
            'total_payout, Date__c';
        strQuery += ' FROM Critical_Date__c WHERE Account__c in (Select AccountId From Opportunity WHERE '+
            'Loan_Status__c != \'Closed - Paid\' AND Loan_Status__c != \'Closed - Bad Debt\' AND '+
            'Loan_Status__c != \'Closed - Bad Debt - Making Payments\')'; 
        strQuery += ' AND Date__c >= :startDt AND Date__c <= :endDt';
        strQuery += (filterByBusinessUnit == 'Consolidated') ? 
            ' AND (Account__r.Business_Unit__c =:Elfi OR Account__r.Business_Unit__c =:Rhino)':
        ' AND Account__r.Business_Unit__c =:filterByBusinessUnit';
        strQuery += ' Group by Account__c, Name__c, Account__r.Business_Unit__c, Account__r.AccountNumber,'+ 
            'Account__r.Name, Date__c';
        return Database.query(strQuery);
    }
    
    @AuraEnabled
    Public static List<String> getCriticalDateNames(String startDate, String endDate, String businessUnit){
        
        List<String> values = new List<String>();
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        string filterByBusinessUnit = '';
        string Elfi = 'ELFI';
        string Rhino = 'Rhino';
        
        if(businessUnit == 'ELFI'){            
            filterByBusinessUnit = 'ELFI';
        }else if(businessUnit == 'Rhino'){            
            filterByBusinessUnit = 'Rhino';
        }else if(businessUnit == 'Consolidated'){            
            filterByBusinessUnit = 'Consolidated';
        }
        
        String strQuery = 'SELECT Name__c FROM Critical_Date__c WHERE Date__c >= :startDt AND Date__c <= :endDt';
        strQuery += ' AND Account__c in (Select AccountId From Opportunity WHERE Loan_Status__c != \'Closed - Paid\' AND Loan_Status__c != \'Closed - Bad Debt\' AND Loan_Status__c != \'Closed - Bad Debt - Making Payments\')';
        strQuery += (filterByBusinessUnit == 'Consolidated') ? 
            ' AND (Account__r.Business_Unit__c =:Elfi OR Account__r.Business_Unit__c =:Rhino)':
        ' AND Account__r.Business_Unit__c =:filterByBusinessUnit';
        strQuery += ' Group by Name__c Order by Name__c';
        List<AggregateResult> aggResultList = Database.query(strQuery);
        
        for (AggregateResult aggResult: aggResultList) {
            values.add((String)aggResult.get('Name__c'));
        }
        return values;
    }
    
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Critical_Dates_Report__c fsr = Critical_Dates_Report__c.getOrgDefaults();
            
            fsr.End_date__c = endDt;
            fsr.Start_Date__c = startDt;
            
            update fsr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
           // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            Critical_Dates_Report__c fsr = Critical_Dates_Report__c.getOrgDefaults();
            
            fsr.Business_Unit__C = BusinessUnit;
            
            upsert fsr;

        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Critical_Dates_Report__c getCustomSetting(){
        Critical_Dates_Report__c cdReport = Critical_Dates_Report__c.getOrgDefaults();
        return cdReport;
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Critical_Date__c printReport(String stDate, String  edDate, String businessUnit){
        Critical_Dates_Report__c cdReport = Critical_Dates_Report__c.getOrgDefaults();
        cdReport.Start_Date__c = (!String.isEmpty(stDate) && stDate != null) ? Date.valueOf(stDate) : cdReport.Start_Date__c;
        cdReport.End_Date__c = (!String.isEmpty(edDate) && edDate != null) ? Date.valueOf(edDate) : cdReport.End_Date__c;
        cdReport.Business_Unit__c = (!String.isEmpty(businessUnit) && businessUnit != null) ? businessUnit : 'ELFI';        
        upsert cdReport;
        Critical_Date__c cd = [SELECT id, Conga_Generate_Report__c FROM Critical_Date__c LIMIT 1];
        
        return cd;        
    }
    
    @AuraEnabled
    Public static void createNewNote(String accountId, String note){
        try{
            if(note != null){
                ContentNote cn = new ContentNote();  
                cn.Title = 'N/A';
                cn.Content = Blob.valueOf(note.escapeHtml4());
                insert cn;
                ContentDocument cd=[select id from ContentDocument where id=:cn.Id];
                ContentDocumentLink cdl=new ContentDocumentLink();
                cdl.ContentDocumentId=cd.id;
                cdl.LinkedEntityId=accountId;
                cdl.ShareType='V';
                cdl.Visibility='AllUsers';
                insert cdl;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
    }
}