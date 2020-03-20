@isTest
public with sharing class RDS_LeadEditCtlrTest {
	public RDS_LeadEditCtlrTest() {
		
	}
	static testMethod void LeadEditTest() {

		Account acc = ELUtilTest.createAccount();
		Contact con = ELUtilTest.createContact(acc.Id);

		Lead l = new lead( FirstName='New Lead',LastName = 'Hussy',Title ='Developer',Company = 'Wipro',Status = 'New',Marital_Status__c = 'Single',Any_SpousalChild_support_payment__c ='Yes',Have_you_ever_been_in_arrears_on_payment__c = 'No',Have_you_ever_declared_bankruptcy__c = 'Yes',Existing_Litigation_Loans__c = 'Yes',Employment_status_at_time_of_accident__c = 'Full-time',Lawyer_Name_new__c = con.id);
		insert l; 
		PageReference pageRef = Page.RDS_LeadEdit;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(l); 
		ApexPages.currentPage().getParameters().put('Id',l.id);
    
		
		RDS_LeadEditCtlr Le = new RDS_LeadEditCtlr(sc);
		Le.leadObj = l;

		System.debug('leadid'+l.id);

		
        System.assertNotEquals(null,pageRef);
		
		List<selectOption> spousalSupportPayments_options = Le.getSpousalSupportPayments();
		System.AssertNotEquals(0, spousalSupportPayments_options.size());
		
		List<selectOption> arrearsPayments_options = Le.getArrearsPayments();
		System.AssertNotEquals(0, arrearsPayments_options.size());
		
		List<selectOption> bankruptcies_options = Le.getbankruptcies();
		System.AssertNotEquals(0, bankruptcies_options.size());
		
		List<selectOption> litigations_options = Le.getLitigations();
		System.AssertNotEquals(0, litigations_options.size());
		
		List<selectOption> employment_options = Le.getEmployments();
		System.AssertNotEquals(0, employment_options.size());

		List<selectOption> maritalStatus_options = Le.getMaritalStatuss();
        System.AssertNotEquals(0, maritalStatus_options.size());

		string search = Le.getsearchCategory();
		Le.setsearchCategory(search);
		String nextPage = Le.saveLead().getUrl();
		System.debug('Next'+nextPage);
		//Le.cloneLead();
		Le.cancelLead();
		Le.deleteLead();
		Le.ConvertLead();
        Le.findDuplicates();

        
        RDS_LeadEditCtlr.getCreatableFieldsSOQL('lead','Id=' + '\'' + l.id + '\'');
		
		System.assertEquals('/apex/RDS_LeadView?id='+l.id,nextPage);
	}
	static testMethod void LeadEditTestForNull() {

		Account acc = ELUtilTest.createAccount();
		Contact con = ELUtilTest.createContact(acc.Id);

		Lead l = new lead( FirstName='New Lead',LastName = 'Hussy',Title ='Developer',Company = 'Wipro',Status = 'New',Marital_Status__c = 'Single',Any_SpousalChild_support_payment__c ='Yes',Have_you_ever_been_in_arrears_on_payment__c = 'No',Have_you_ever_declared_bankruptcy__c = 'Yes',Existing_Litigation_Loans__c = 'Yes',Employment_status_at_time_of_accident__c = 'Full-time',Lawyer_Name_new__c = con.id);
		insert l; 
		PageReference pageRef = Page.RDS_LeadEdit;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(l); 
		
		RDS_LeadEditCtlr Le = new RDS_LeadEditCtlr(sc);
		Le.leadObj = l;
		
		System.assertNotEquals(null,pageRef);
	}
	static testMethod void LeadEditTestClone() {

		Account acc = ELUtilTest.createAccount();
		Contact con = ELUtilTest.createContact(acc.Id);

		Lead l = new lead( FirstName='New Lead',LastName = 'Hussy',Title ='Developer',Company = 'Wipro',Status = 'New',Marital_Status__c = 'Single',Any_SpousalChild_support_payment__c ='Yes',Have_you_ever_been_in_arrears_on_payment__c = 'No',Have_you_ever_declared_bankruptcy__c = 'Yes',Existing_Litigation_Loans__c = 'Yes',Employment_status_at_time_of_accident__c = 'Full-time',Lawyer_Name_new__c = con.id);
		insert l; 
		PageReference pageRef = Page.RDS_LeadEdit;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(l); 
		ApexPages.currentPage().getParameters().put('Id',l.id);
    
		
		RDS_LeadEditCtlr Le = new RDS_LeadEditCtlr(sc);
		Le.leadObj = l;

		System.debug('leadid'+l.id);

		
        System.assertNotEquals(null,pageRef);
		
		List<selectOption> spousalSupportPayments_options = Le.getSpousalSupportPayments();
		System.AssertNotEquals(0, spousalSupportPayments_options.size());
		
		List<selectOption> arrearsPayments_options = Le.getArrearsPayments();
		System.AssertNotEquals(0, arrearsPayments_options.size());
		
		List<selectOption> bankruptcies_options = Le.getbankruptcies();
		System.AssertNotEquals(0, bankruptcies_options.size());
		
		List<selectOption> litigations_options = Le.getLitigations();
		System.AssertNotEquals(0, litigations_options.size());
		
		List<selectOption> employment_options = Le.getEmployments();
		System.AssertNotEquals(0, employment_options.size());

		List<selectOption> maritalStatus_options = Le.getMaritalStatuss();
        System.AssertNotEquals(0, maritalStatus_options.size());

		string search = Le.getsearchCategory();
		Le.setsearchCategory(search);
		String nextPage = Le.saveLead().getUrl();
		System.debug('Next'+nextPage);
		Le.cloneLead();
		
		RDS_LeadEditCtlr.getCreatableFieldsSOQL('lead','Id=' + '\'' + l.id + '\'');
		
		System.assertEquals('/apex/RDS_LeadView?id='+l.id,nextPage);
	}
}