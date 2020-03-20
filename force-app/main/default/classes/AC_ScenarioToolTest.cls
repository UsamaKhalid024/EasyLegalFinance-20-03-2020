@isTest
private class AC_ScenarioToolTest {
    static testMethod void testScenario(){
        // fetch allowed values for these fields
        String province = Scenario_Region__c.Provinces__c.getDescribe().getPicklistValues()[0].Value;
        String loanType = Scenario__c.LoanType__c.getDescribe().getPicklistValues()[0].Value;
        String oStage = Opportunity.StageName.getDescribe().getPicklistValues()[0].Value;
        
        // set up bare bones sample data
        Scenario_Region__c region = new Scenario_Region__c(Name = 'test', Provinces__c = province);
        Account a = new Account(Name = 'test Account name', ProvinceResidency__c = province, Business_Unit__c = 'ELFI');
        insert (new SObject[]{region, a});
        Scenario__c s = new Scenario__c(LoanType__c = loanType, Region__c = region.Id, Business_Unit__c = 'ELFI');
        Opportunity o = new Opportunity(Name = 'test name', Type_of_Loan__c = loanType, Accident_Location_from_W2L__c = province
                           , StageName = oStage, CloseDate = Date.today(), AccountId = a.id);
        insert (new SObject[]{s, o});
        
        AC_ScenarioTool.assignScenarios(new Opportunity[]{o});
        
        // the appropriate Scenario should end up being assigned
        System.assertEquals(s.id, [SELECT Scenario__c FROM Opportunity Limit 1].Scenario__c);
    }
}