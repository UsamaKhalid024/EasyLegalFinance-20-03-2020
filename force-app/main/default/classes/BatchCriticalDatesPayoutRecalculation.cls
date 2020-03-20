global class BatchCriticalDatesPayoutRecalculation implements Database.Batchable<sObject> {
    
    public Set<Id> accIds;
    String query;
    public Date fromDate;  // date we are calcuating from
    public Date toDate;    // date we are calculating to
    
    global BatchCriticalDatesPayoutRecalculation(Date fromDt, Date toDt){
        fromDate = (fromDt != null) ? fromDt : null;
        toDate = (toDt != null) ? toDt : null;
        accIds = new Set<Id>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        // get the critical dates in this range
        query = 'SELECT Id, Name, Date__c, Name__c, Account_Name_Formula__c,'+ 
            +'Outstanding_Balance_as_of_To_Date__c, Accrued_Interest_as_of_To_Date__c,'+ 
            'Report_Start_Date__c, Report_End_Date__c, Account__c FROM Critical_Date__c where date__c >=:fromDate and '+
            'date__c <=:toDate';
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<Critical_Date__c> scope){
        try{
            
            for(Critical_Date__c cd : scope){
                accIds.add(cd.Account__c);
            }
            
            if(!accIds.IsEmpty()){
                
                // get the drawdowns
                String query='SELECT id,Opportunity__c,Opportunity__r.AccountId,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c,' +
                    'Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c,'+
                    'Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, '+
                    'Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Payment_Method__c != \'Payment\' AND ' +
                    '(Interest_Rate__c > 0) AND (Compounding_Interest__c = false OR Compounding_Frequency__c >0) AND Opportunity__r.AccountId in :accIds';            
                List<Drawdown__c> drawdowns = Database.query(query);
                
                Map<Id, List<Drawdown__c>> accToDrawdowns = new Map<Id, List<Drawdown__c>>();
                for(Drawdown__c dd : drawdowns){            
                    if(!accToDrawdowns.containsKey(dd.Opportunity__r.AccountId)){
                        accToDrawdowns.put(dd.Opportunity__r.AccountId, new List<Drawdown__c>());
                    }
                    accToDrawdowns.get(dd.Opportunity__r.AccountId).add(dd);
                }
                
                for(Critical_Date__c cd : scope){            
                    if(accToDrawdowns.get(cd.Account__c) != null ){
                        PortfolioReportCalculateData.calculateDataInStatic(accToDrawdowns.get(cd.Account__c), true, null, cd.Date__c);
                        AggregateResult agResult = [SELECT SUM(Outstanding_Balance_as_of_To_Date__c) outstandingBalance 
                                                    FROM Drawdown__c 
                                                    WHERE id in: accToDrawdowns.get(cd.Account__c)];
                        cd.Outstanding_Balance_as_of_To_Date__c = (Decimal) agResult.get('outstandingBalance');
                        cd.Account_Name__c = cd.Account_Name_Formula__c;
                    }            
                }
                update scope;
            }
        }
        catch (Exception e){
            
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }
}