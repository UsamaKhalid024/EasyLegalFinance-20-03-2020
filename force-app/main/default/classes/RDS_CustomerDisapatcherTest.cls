@isTest
public with sharing class RDS_CustomerDisapatcherTest {
	public RDS_CustomerDisapatcherTest() {
		
	}
	static testMethod void CustomerDispatcherForLawFirm(){

		Account account1 = new Account();
       
        account1.Name='Jackie';
       
        account1.billingcountry='America';
        account1.shippingcountry='England';
        account1.Account_Type__c = 'Law Firm';
        insert account1;

        PageReference pageRef = Page.RDS_CustomerDispatcher;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(account1); 
		ApexPages.currentPage().getParameters().put('Id',account1.Id);
		RDS_CustomerDispatcher Le = new RDS_CustomerDispatcher(sc);

		System.assertNotEquals(null,pageRef);

		String nextPage = Le.dispatch().getUrl();
	}
	static testMethod void CustomerDispatcherForClient(){

		Account account1 = new Account();
       
        account1.Name='Jackie';
       
        account1.billingcountry='America';
        account1.shippingcountry='England';
        account1.Account_Type__c = 'Client';
        insert account1;

        PageReference pageRef = Page.RDS_CustomerDispatcher;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(account1); 
		ApexPages.currentPage().getParameters().put('Id',account1.Id);
		RDS_CustomerDispatcher Le = new RDS_CustomerDispatcher(sc);

		System.assertNotEquals(null,pageRef);

		String nextPage = Le.dispatch().getUrl();
	}

	static testMethod void CustomerDispatcherForContact(){

		Account account1 = new Account();

       
        account1.Name='Jackie';
       
        account1.billingcountry='America';
        account1.shippingcountry='England';
        account1.Account_Type__c = 'Client';
        insert account1;

        Contact con = ELUtilTest.createContact(account1.Id);

        PageReference pageRef = Page.RDS_CustomerDispatcher;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(con); 
		ApexPages.currentPage().getParameters().put('Id',con.Id);
		RDS_CustomerDispatcher Le = new RDS_CustomerDispatcher(sc);

		System.assertNotEquals(null,pageRef);

		String nextPage = Le.dispatch().getUrl();
	}

	static testMethod void CustomerDispatcherForOpportunity(){

		Account acc = new Account();

       
        acc.Name='Jackie';
       
        acc.billingcountry='America';
        acc.shippingcountry='England';
        acc.Account_Type__c = 'Client';
        insert acc;

        Contact con = ELUtilTest.createContact(acc.Id);

        Opportunity o = new Opportunity(
          
        Name = 'Test',
        AccountId = acc.Id,
        Lawyer__c = con.id,
        CloseDate = Date.today(),
        StageName = 'ENTERED',
        Amount = 120.00,
        Subsequent_Drawdowns__c = 12.00   
        );
           
        insert o;

        PageReference pageRef = Page.RDS_CustomerDispatcher;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(o); 
		ApexPages.currentPage().getParameters().put('Id',o.Id);
		RDS_CustomerDispatcher Le = new RDS_CustomerDispatcher(sc);

		System.assertNotEquals(null,pageRef);

		String nextPage = Le.dispatch().getUrl();
	}
	/*static testMethod void CustomerDispatcherForOther(){

		Account account1 = new Account();
       
        account1.Name='Jackie';
      
        account1.billingcountry='Russia';
        account1.shippingcountry='England';
        account1.Account_Type__c = 'Client';
        insert account1;

        PageReference pageRef = Page.RDS_CustomerDispatcher;
		Test.setCurrentPage(pageRef); 
		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(account1); 
		ApexPages.currentPage().getParameters().put('Id',account1.Id);
		RDS_CustomerDispatcher Le = new RDS_CustomerDispatcher(sc);

		System.assertNotEquals(null,pageRef);


		String nextPage = Le.dispatch().getUrl();
	}*/

}