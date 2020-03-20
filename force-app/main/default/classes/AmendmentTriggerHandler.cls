public with sharing class AmendmentTriggerHandler {

    public static void createActivityHistory(Map<Id,Opportunity> newMap){
        
        List<Amendment__c> lstAmendment = new List<Amendment__c>();
        
        for(Opportunity opp : newMap.values()){

            Opportunity oppr = (Opportunity)Trigger.oldMap.get(opp.Id);
            
            if(opp.Date_Financing_Statement_Done__c != oppr.Date_Financing_Statement_Done__c ||
               opp.Date_Financing_Statement_Expires__c != oppr.Date_Financing_Statement_Expires__c ||
               opp.Amount != oppr.Amount ||
               opp.Renewal_Date__c != oppr.Renewal_Date__c 
               ){
                Amendment__c Amendment = new Amendment__c();
                Amendment.Date_Financing_Statement_Done__c = opp.Date_Financing_Statement_Done__c;
                Amendment.Date_Financing_Statement_Expires__c = opp.Date_Financing_Statement_Expires__c;
                Amendment.Amount__c = opp.Amount;
                Amendment.Opportunity__c = opp.Id;
                Amendment.Renewal_Date_New__c = opp.Renewal_Date__c;
                lstAmendment.add(Amendment);
            }
        }

        if(lstAmendment.size() > 0){
            insert lstAmendment; 
        }
    }
}