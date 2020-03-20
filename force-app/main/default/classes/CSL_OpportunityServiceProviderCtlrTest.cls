@isTest
public class CSL_OpportunityServiceProviderCtlrTest {
    
    static testMethod void ServiceProviderTest(){
        Account acc = ELUtilTest.createAccount();
        Contact con = ELUtilTest.createContact(acc.Id);
        
        Opportunity o = new Opportunity(
            Name = 'Test',
            AccountId = acc.Id,
            Lawyer__c = con.id,
            CloseDate = Date.today(),
            StageName = 'ENTERED',
            Amount = 120.00,
            Minimum_Interest_Period__c = '0 months',
            Compounding_Interest__c = 'Monthly',
            Interest_Compounding_Period__c = 'Simple Interest',
            Interest_Deferral_Period__c = '0',
            Interest_Rate__c = 15.0
        );
        insert o;

        // Create contact for lookup
        // Account serviceAcc = ELUtilTest.createAccount();
        
        Id RecordTypeIdAccount = 
            Schema.SObjectType.Account.getRecordTypeInfosByName().get('General Business').getRecordTypeId();
        
        Account serviceAcc = new Account();
        serviceAcc.Name='Sparrow';
        serviceAcc.BillingStreet = 'Testtest';
        serviceAcc.BillingState = 'AK';
        serviceAcc.BillingCity = 'City';
        serviceAcc.BillingPostalCode = '10001';
        serviceAcc.Billingcountry='Canada';
        serviceAcc.ShippingStreet = 'Test';
        serviceAcc.ShippingState = 'New York';
        serviceAcc.ShippingCountry = 'UNITED STATES';
        serviceAcc.ShippingPostalCode = '10001';
        serviceAcc.ShippingCity = 'Lake Trees';
        serviceAcc.Account_Type__c = 'Treatment Provider Firm';
        serviceAcc.RecordTypeId = RecordTypeIdAccount;
        insert serviceAcc;
        
        Contact c = new Contact(
            FirstName = 'Super',
            LastName = 'Mario',
            AccountId = serviceAcc.Id
        );
        insert c;

        Opportunity_Service_Provider__c sp = new Opportunity_Service_Provider__c();
        
        sp.Allowance__c = 1;
        sp.Opportunity__c = o.id;
        sp.Status__c = 'Waiting To Send Schedule';
        sp.Service_Provider_Facility__c = serviceAcc.id;
        
        insert sp;

        PageReference pageRef = Page.CSL_OpportunityServiceProvider;
        Test.setCurrentPage(pageRef); 
        System.assertNotEquals(null,pageRef);

        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(sp); 
        ApexPages.currentPage().getParameters().put('oppId', o.Id);

        CSL_OpportunityServiceProviderCtlr osp = new CSL_OpportunityServiceProviderCtlr(sc);
        System.assertEquals(1, osp.providers.size());
        System.assertNotEquals(null, osp.oppId);


        // add new
        osp.provider.Service_Provider_Facility__c = acc.Id;
        osp.createNew();
        osp.init();
        

        // check the provider count
        System.assertEquals(1, osp.providers.size());


        // update the service prodider allowance
        osp.providers.get(0).Allowance__c = 1000;
        osp.saveProviderList();
        osp.init();

        //System.assertEquals(1000, osp.providers.get(0).Allowance__c);

        // add drawdown
        ApexPages.currentPage().getParameters().put('pId', osp.providers.get(0).Id);
        osp.addDrawdown();
        osp.init();

        // check the drawdown count for the first prodider
        //System.assertEquals(1, osp.providers.get(0).Drawdowns__r.size());

        // change drawdown ammount
        osp.providers.get(0).Drawdowns__r.get(0).Amount__c = 500;
        osp.saveProviderList();
        osp.init();

        //System.assertEquals(500, osp.providers.get(0).Drawdowns__r.get(0).Amount__c);

        // delete drawdown
        ApexPages.currentPage().getParameters().put('dId', osp.providers.get(0).Drawdowns__r.get(0).Id);
        osp.deleteDrawdown();
        osp.init();        

        //System.assertEquals(0, osp.providers.get(0).Drawdowns__r.size());

        // delete proivder
        ApexPages.currentPage().getParameters().put('pId', osp.providers.get(0).Id);
        osp.deleteProvider();
        osp.init();

        //System.assertEquals(0, osp.providers.size());
    }
}