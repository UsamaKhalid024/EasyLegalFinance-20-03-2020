@isTest
public with sharing class RDS_AccountPrintableViewCtlrTest {

	static testmethod void testRDS_AccountPrintableViewCtlr() {
	
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);

		Opportunity opp = new Opportunity(
        AccountId = acc.Id,
        Lawyer__c = con.Id,
      	Name = 'Test1',
        CloseDate = Date.today().addDays(1),
        StageName = 'ENTERED',
        Law_Firm__c = acc.id
        );
        insert opp;

        PageReference pageRef = Page.RDS_AccountPrintableView;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(acc);

        RDS_AccountPrintableViewCtlr pv = new RDS_AccountPrintableViewCtlr(sc);
        
        List<String[]> lls = new List<String[]>{pv.getArrearsPaymentOptions(), pv.getBankruptcyOptions()
            ,pv.getDependentOptions(),pv.getEmploymentOptions(),pv.getLitigationOptions()
            ,pv.getMartialStatusOptions(),pv.getSpousalChildPaymentOptions()};

	}
}