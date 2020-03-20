@isTest
public class LeadsPerMonthReportPrintControllerTest {
    @TestSetup 
    public static void createTestData(){
        LeadsPerMonthReportCtlrTest.createTestData();
    }
	public static testmethod void testrun()
    {
        LeadsPerMonthReportPrintController cont = new LeadsPerMonthReportPrintController();
    }
}