/**
*    @description : Test class for LoanSimulatorController
**/
@isTest(seeAllData=false)
private with sharing class LoanSimulatorControllerTest {
	
	/**
	*    @description : Set up Opportunity
	**/
    private static Opportunity setUpOpportynity(){
        Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId());
        opportunity.CloseDate = Date.today().addDays(14);
        opportunity.StageName = 'Closed With Loan';
        opportunity.Stage_Status__c = 'Approved';
        opportunity.Amount = 5000.00;
        opportunity.Payout_Date__c = Date.today();
        opportunity.Type_of_Loan__c = 'Facility Loan';
        opportunity.Minimum_Interest_Period__c = '0 months';
        opportunity.Compounding_Interest__c = 'Monthly';
        opportunity.Interest_Compounding_Period__c = 'Compounding Interest';
        opportunity.Interest_Rate__c = 15.0;
        opportunity.Payout_Date__c = System.today().addMonths(15);
        return opportunity;
    }

    /**
	*    @description : Setup Opportunity
	**/
    private static List<Drawdown__c> setUpDrawdowns(){
        List<Drawdown__c> drawdownsList = new List<Drawdown__c>();
        drawdownsList.add(new Drawdown__c(Payment_Method__c='e-Transfer',Reference_Notes__c='Payment to Client',Amount__c=5000.00,Date__c=System.today()));
        return drawdownsList;
    }


    /**
	*    @description : Test Loan Simulator 
	**/
	@isTest
	static void test_calculateLoanInterestAndBalance(){
		Test.startTest();
		Map<String, Object> objectsMap = LoanSimulatorController.calculateLoanInterestAndBalance(setUpOpportynity(),setUpDrawdowns());
		System.assertEquals(4,objectsMap.size());
		Test.stopTest();
	}
}