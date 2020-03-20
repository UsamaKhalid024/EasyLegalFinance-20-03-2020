global class PortfolioReportScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        Portfolio_Report__c report = new Portfolio_Report__c();
        report.Status__c = 'Not Submitted';
        report.since_inception__c = true;
        report.to_date__c = Date.today();
        report.Business_Unit__c = 'All';
        insert report;
    }
   
}