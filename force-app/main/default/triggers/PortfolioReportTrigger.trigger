trigger PortfolioReportTrigger on Portfolio_Report__c (before insert, after insert) {
		/*------------------------------------------------------------
		Author: Basil Dobek
		Company: Deloitte
		Description:  Launch a batch job to calculate the from and to date interest accrued and balance.	   
		Inputs:   
			
		History
		June 19th 2019 Victoria Ventura - Needed to change the batch scope size
		------------------------------------------------------------*/
    if (trigger.isBefore && trigger.isInsert){
        list <Portfolio_Report__c> pr = [select id,name from portfolio_report__c where id not in: Trigger.new AND status__c = 'In Progress' ];

        if (pr.size() >0 ){
            trigger.new[0].addError('A Portfolio report is already in progress.  Please submit one report at a time.');
        }else{
            trigger.new[0].status__c='In Progress';
        }
    }
    if (Trigger.isAfter && trigger.isInsert){
        PortfolioReportCalculateData prcd = new PortfolioReportCalculateData();
        prcd.fromDate = trigger.new[0].from_date__c;
        prcd.sinceInception = trigger.new[0].since_inception__c;       
        prcd.toDate = trigger.new[0].to_date__c;
        prcd.portfolioReportId = trigger.new[0].id;

        system.debug('prcd.portfolioReportId = '+prcd.portfolioReportId );
        // In test this batch started to fail (cpu time exceeded) with batches sizes over 700.  
        // I set at 100 to be conservative as there may be more payment allocations in prod.
        // Victoria changed it to 5 because we were receiving CPU TIME EXCEEDED in prod.
        id batchInstanceId = database.executeBatch(prcd,5);  
    } 
}