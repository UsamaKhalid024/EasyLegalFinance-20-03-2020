@isTest
public class RDS_LeadViewCtlrTest {
    
    static testMethod void TestRDS_LeadView() {
        List<Lead> lstLead = new List<Lead>();
        Lead ld = new Lead();
        ld.FirstName='Jhon';
        ld.LastName='David';
        ld.Company='Wipro'; 
        lstLead.add(ld);

        insert lstLead;
        

        Lead l = [select ID from Lead limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(l);

        RDS_LeadViewCtlr lvc = new RDS_LeadViewCtlr(sc);

        lvc.getMartialStatusOptions();
        lvc.getSpousalChildPaymentOptions();
        lvc.getArrearsPaymentOptions();
        lvc.getDependentOptions();
        lvc.getBankruptcyOptions();
        lvc.getEmploymentOptions();
       // lvc.getPriorInjuryOptions();
        lvc.getLitigationOptions();

        PageReference pageRef = Page.RDS_LeadView;
        Test.setCurrentPage(pageRef);
        System.assertNotEquals(null,pageRef);
        
        String convert = lvc.convert().getUrl();
        System.assertEquals('/lead/leadconvert.jsp?id=' + l.Id + '&retURL=%2F' + l.Id,convert);
        
        String print = lvc.printableView().getUrl();
        System.assertEquals('/apex/RDS_LeadPrintableView?id=' + l.Id,print);
        
        lvc.deleteLead();
       // System.assertEquals()
        String cancel = lvc.CancelLead().getUrl();
        System.assertEquals('/00Q/o',cancel);
        
        lvc.cloneLead();
    }
}