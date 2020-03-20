@isTest
public class PortfolioReportSchedulerTest {
	public static testMethod void testSchedule() {
		Test.startTest();
        List<Portfolio_Report__c> portfolioReports = [select Id from Portfolio_Report__c];
        System.assertEquals(true, portfolioReports.isEmpty());
        PortfolioReportScheduler portfolioReportScheduler = new PortfolioReportScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Create Portfolio Report', sch, portfolioReportScheduler); 
        Test.stopTest();
        portfolioReports = [select Id from Portfolio_Report__c];
        System.assertEquals(false, portfolioReports.isEmpty());
    }
}