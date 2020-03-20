public class AC_ScenarioTool {
    @InvocableMethod(label='Assign Scenarios' description='Assigns Scenario to Opportunities')
    public static void assignScenarios(Opportunity[] opps){
        // This can be invoked from a Process Builder; have to extract IDs as a result
        Set<ID> ids = new Map<ID, Opportunity>(opps).keySet();
         
        Scenario__c[] scenarios = [SELECT Id, LoanType__c, Business_Unit__c, Region__c, Region__r.Provinces__c FROM Scenario__c];
        Opportunity[] allOpps = [SELECT Id, Type_of_Loan__c, Account.Business_Unit__c, Account.ProvinceResidency__c,
                                 Scenario__r.LoanType__c, Scenario__r.Region__c, Scenario__r.Region__r.Provinces__c, Scenario__r.Business_Unit__c
                                   FROM Opportunity
                                   WHERE Id IN :ids];
        Opportunity[] targetOpps = (new Opportunity[]{});
        
        // try to match Opportunities to Scenarios
        for (Opportunity o : allOpps){
            // get existing scenario
            Scenario__c os = o.Scenario__r;
            // coalesce nulls
            String sProvinces = (os == null ? '' : o.Scenario__r.Region__r.Provinces__c);
            String sBusinessUnit = (os == null ? '' : o.Scenario__r.Business_Unit__c);
            system.debug('Business Unit ; ' + sBusinessUnit);
            String sLoanType = (os == null ? '' : o.Scenario__r.LoanType__c);
            // Avoid false positive
            String oProvince = 'zzzzzz';
            String oBusinessUnit = 'zzzzzz';
            if (o.AccountId != null && !String.isBlank(o.Account.ProvinceResidency__c) && !String.isBlank(o.Account.Business_Unit__c) && o.Account.Business_Unit__c != null){
                oProvince = o.Account.ProvinceResidency__c;
                oBusinessUnit = o.Account.Business_Unit__c;
                system.debug(oBusinessUnit);
            }
                
            // skip if already matches
            if (o.Type_of_Loan__c == sLoanType && sProvinces.contains(oProvince) && sBusinessUnit.contains(oBusinessUnit)){ continue; }
            // otherwise null it and then search for a match
            o.Scenario__c = null;
            targetOpps.add(o);
            // find matching scenario if exists
            for (Scenario__c s : scenarios){
                if (o.Type_of_Loan__c == s.LoanType__c && s.Region__r.Provinces__c != null && s.Region__r.Provinces__c.contains(oProvince) &&
                   s.Business_Unit__c == o.Account.Business_Unit__c){
                    o.Scenario__c = s.Id;

                    // exit inner loop when a match is found
                    break;
                }
            }
        }
        
        // update identified Opportunities
        if (targetOpps.size() > 0)
        	update targetOpps;
    }
}
/*
public class AC_ScenarioTool {
    @InvocableMethod(label='Assign Scenarios' description='Assigns Scenario to Opportunities')
    public static void assignScenarios(Opportunity[] opps){
        // This can be invoked from a Process Builder; have to extract IDs as a result
        Set<ID> ids = new Map<ID, Opportunity>(opps).keySet();
         
        Scenario__c[] scenarios = [SELECT Id, LoanType__c, Region__c, Region__r.Provinces__c FROM Scenario__c];
        Opportunity[] allOpps = [SELECT Id, Type_of_Loan__c, Account.ProvinceResidency__c
                                 , Scenario__r.LoanType__c, Scenario__r.Region__c, Scenario__r.Region__r.Provinces__c
                                   FROM Opportunity
                                   WHERE Id IN :ids];
        Opportunity[] targetOpps = (new Opportunity[]{});
        
        // try to match Opportunities to Scenarios
        for (Opportunity o : allOpps){
            // get existing scenario
            Scenario__c os = o.Scenario__r;
            // coalesce nulls
            String sProvinces = (os == null ? '' : o.Scenario__r.Region__r.Provinces__c);
            String sLoanType = (os == null ? '' : o.Scenario__r.LoanType__c);
            // Avoid false positive
            String oProvince = 'zzzzzz';
            if (o.AccountId != null && !String.isBlank(o.Account.ProvinceResidency__c))
                oProvince = o.Account.ProvinceResidency__c;
            // skip if already matches
            if (o.Type_of_Loan__c == sLoanType && sProvinces.contains(oProvince)){ continue; }
            // otherwise null it and then search for a match
            o.Scenario__c = null;
            targetOpps.add(o);
            // find matching scenario if exists
            for (Scenario__c s : scenarios){
                if (o.Type_of_Loan__c == s.LoanType__c && s.Region__r.Provinces__c != null && s.Region__r.Provinces__c.contains(oProvince)){
                    o.Scenario__c = s.Id;

                    // exit inner loop when a match is found
                    break;
                }
            }
        }
        
        // update identified Opportunities
        if (targetOpps.size() > 0)
        	update targetOpps;
    }
}*/