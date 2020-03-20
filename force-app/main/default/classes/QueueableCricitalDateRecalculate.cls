public class QueueableCricitalDateRecalculate implements queueable {
    SEt<Id> critDateIds;
    List<Critical_Date__c> criticalDateList;
    Map<Id, List<Drawdown__c>> accToDrawdowns;
    Boolean doDML;
    public QueueableCricitalDateRecalculate(List<Critical_Date__c> criticalDateList, Map<Id, List<Drawdown__c>> accToDrawdowns, boolean doDML)
    {
        this.criticalDateList = criticalDateList;
        this.accToDrawdowns = accToDrawdowns;
        this.doDML = doDML;
    }
	public void execute(System.QueueableContext qc)
    {
        for(Critical_Date__c cd : criticalDateList){            
            if(accToDrawdowns.get(cd.Account__c) != null ){
                PortfolioReportCalculateData.calculateDataInStatic(accToDrawdowns.get(cd.Account__c), true, null, cd.Date__c);
                AggregateResult agResult = [SELECT SUM(Outstanding_Balance_as_of_To_Date__c) outstandingBalance FROM Drawdown__c WHERE id in: accToDrawdowns.get(cd.Account__c)];
                cd.Outstanding_Balance_as_of_To_Date__c = (Decimal) agResult.get('outstandingBalance');
                cd.Account_Name__c = cd.Account_Name_Formula__c;
            }            
        }
        if(doDML)	update criticalDateList;
    }
}