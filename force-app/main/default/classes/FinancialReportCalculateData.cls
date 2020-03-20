global class FinancialReportCalculateData implements Database.Batchable<sObject> {
    
    String query;
	public Date fromDate;  // date we are calcuating from
	public Date toDate;    // date we are calculating to
	public Boolean sinceInception;  // use this to indicate calculation since the drawdown date
    
    global FinancialReportCalculateData(Date fromDt, Date toDt, Boolean inception){
        fromDate = (fromDt != null) ? fromDt : null;
		toDate = (toDt != null) ? toDt : null;    
		sinceInception = (inception == null) ? false : inception;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        String closedWithLoan = 'Closed With Loan';
        String none = '';
        String partialPayment = 'Partial Payment';
                
        query='SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c,' +
            'Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c,'+
            'Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, '+
            'Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Opportunity__r.StageName =:closedWithLoan' +
            ' AND (Opportunity__r.Stage_Status__c =:none OR Opportunity__r.Stage_Status__c =:partialPayment)'+
            ' AND Interest_Rate__c > 0 AND Payment_Method__c != \'Payment\' ';
        system.debug(query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        try{
			PortfolioReportCalculateData.calculateDataInStatic(scope, sinceInception, fromDate, toDate);
		}
		catch (Exception e){
			
		}
    }
    global void finish(Database.BatchableContext BC){
        
    }
}