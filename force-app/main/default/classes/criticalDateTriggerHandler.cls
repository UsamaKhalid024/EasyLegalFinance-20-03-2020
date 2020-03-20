public with sharing class criticalDateTriggerHandler {    
    
	public static void calculatePayout(List<Critical_Date__c> criticalDateList, Map<Id,Critical_Date__c> oldMap, Boolean isInsert, boolean doDML)
    {
        /*
        Set<Id> accIds = new Set<Id>(); 
        Set<Id> selectedCriticalDateIds = new Set<Id>(); 
        for(Critical_Date__c cd : criticalDateList){
            if(isInsert || (!isInsert && (cd.Date__c != oldMap.get(cd.Id).Date__c || cd.Account__c != oldMap.get(cd.Id).Account__c)))
            {
                selectedCriticalDateIds.add(cd.Id);
                accIds.add(cd.Account__c);
            }
        }
        if(!accIds.isEmpty()){            
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
			
            //August 21 2019
            //Fahad:
            //making the following logic to async future so that it doesn't hit soql/cpu limits
            /*
            for(Critical_Date__c cd : criticalDateList){            
                if(accToDrawdowns.get(cd.Account__c) != null && selectedCriticalDateIds.contains(cd.Id)){
                    PortfolioReportCalculateData.calculateDataInStatic(accToDrawdowns.get(cd.Account__c), true, null, cd.Date__c);
                    AggregateResult agResult = [SELECT SUM(Outstanding_Balance_as_of_To_Date__c) outstandingBalance FROM Drawdown__c WHERE id in: accToDrawdowns.get(cd.Account__c)];
                    cd.Outstanding_Balance_as_of_To_Date__c = (Decimal) agResult.get('outstandingBalance');
                    cd.Account_Name__c = cd.Account_Name_Formula__c;
                }            
            }
            update criticalDateList;
            List<Critical_Date__c> qualifiedCriticalDates = new List<Critical_Date__c>();
            for(Critical_Date__c cd : criticalDateList){            
                if(accToDrawdowns.get(cd.Account__c) != null && selectedCriticalDateIds.contains(cd.Id)){
                    qualifiedCriticalDates.add(cd);
                }
            }
            if(!qualifiedCriticalDates.isempty())
            {
                List<AsyncApexJob> existingJobs = [select id, Status, jobtype, apexclass.name 
                                                   from AsyncApexJob 
                                                   where jobtype='Queueable' 
                                                   and apexclass.name = 'QueueableCricitalDateRecalculate' 
                                                   and status in ('Holding', 'Queued', 'Preparing', 'Processing')];
                if(existingJobs.isEmpty())
                {
                    QueueableCricitalDateRecalculate que = new QueueableCricitalDateRecalculate(qualifiedCriticalDates, accToDrawdowns, doDML);
                    Id jobId = System.enqueueJob(que);
                    try{	FlexQueue.moveJobToFront(jobId); }catch(Exception e){}
                }
                else
                {
                    throw new CustomException ('Critical Dates payout calculation is already in progress');
                }
            }
        }
        */
    } 
    public class CustomException extends exception{}
}