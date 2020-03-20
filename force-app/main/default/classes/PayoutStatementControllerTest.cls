/**
*    @description : Test class for Payout Statement Controller
**/
@isTest(seeAllData=false)
private with sharing class PayoutStatementControllerTest {

	/**
	*    @description : Method to create contact map
	**/
    private static String createContactMap(){
    	return JSON.serialize(new Map<String, String>{'FirstName' => 'Test', 'LastName' => 'Test'});
    }

    /**
	*    @description : Method to create opportunity map
	**/
    private static String createOpportunityMap(){
    	return JSON.serialize(new Map<String, Object>{'Name' => 'Test', 'CloseDate' => System.today(), 'Payout_Date__c' => System.today()});
    }

    /**
	*    @description : Method to create drawdown map
	**/
    private static String createDrawdownMap(){
    	return JSON.serialize(new List<Drawdown__c>{new Drawdown__c(Amount__c=0.50),new Drawdown__c(Amount__c=0.80)});
    }
	
	/**
	*    @description : Test PayoutStatementController constructor
	**/
	@isTest
    static void test_PayoutStatementController(){
    	Test.startTest();
    	Test.setCurrentPage(new PageReference('/apex/x?contact='+createContactMap()+'&lawFirm=TestLawFirm&lawyer=SampleLawyer&principal=123.00&interest=45.00&balance=987.00&opportunity='+createOpportunityMap()+'&drawdowns='+createDrawdownMap())); 
    	PayoutStatementController cls = new PayoutStatementController();
    	System.assertEquals(2,cls.contactMap.size());
    	System.assertEquals('TestLawFirm',cls.lawFirm);
    	System.assertEquals('SampleLawyer',cls.lawyer);
    	System.assertEquals(3,cls.opportunityMap.size());
    	System.assertEquals(System.today(),cls.payoutDate);
    	System.assertEquals(2,cls.drawdownsList.size());
    	System.assertEquals(123.00,cls.principalDrawdown.Amount__c);
    	System.assertEquals(45.00,cls.accruedInterestDrawdown.Amount__c);
    	System.assertEquals(987.00,cls.outstandingBalanceDrawdown.Amount__c);
    	Test.stopTest();
    }
}