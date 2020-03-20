public with sharing class FirmHandler {
	
	public static void createActivityHistory(Map<Id,Opportunity> newMap){
        
        List<Firm__c> lstFirm = new List<Firm__c>();

        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([SELECT Id, (SELECT Id FROM Firms__r) FROM Opportunity WHERE Id IN: newMap.keySet() LIMIT 200]);
        
        for(Opportunity opp : newMap.values()){
            Opportunity oppr = (Opportunity)Trigger.oldMap.get(opp.Id);
            
            if(opp.Law_Firm__c != oppr.Law_Firm__c ||
               opp.Lawyer__c != oppr.Lawyer__c 
               ){
                Firm__c firm = new Firm__c();
                firm.Law_Firm__c = opp.Law_Firm__c;
                firm.Lawyer__c = opp.Lawyer__c;
                firm.Date_of_Update__c = Date.today();
                firm.Opportunity__c = opp.Id;

                if(opportunitiesMap.get(opp.Id).Firms__r.isEmpty()){
                    Firm__c oldFirm = new Firm__c();
                    oldFirm.Law_Firm__c = oppr.Law_Firm__c;
                    oldFirm.Lawyer__c = oppr.Lawyer__c;
                    oldFirm.Date_of_Update__c = Date.today();
                    oldFirm.Opportunity__c = oppr.Id;
                    lstFirm.add(oldFirm);
                }

                lstFirm.add(firm);
            }
        }

        if(lstFirm.size() > 0){
            insert lstFirm; 
        }
    }
}