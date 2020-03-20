/**
*    @description : Helper class for drawdowns
**/
public with sharing class DrawdownHelper {

    @AuraEnabled
    public static Drawdown__c[] getDrawdowns(String fields, String conditions, String extra) {
        if (String.isBlank(fields) || fields == 'all') {
            Map<String, Schema.SObjectField> allFields = Schema.SObjectType.Drawdown__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : allFields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            
            // Building the query
            fields = String.join(lstFields, ',');
        }
        String strQuery = 'SELECT ' + fields + ' FROM Drawdown__c';

        if (!String.isBlank(conditions)) {
            strQuery += ' WHERE ' + conditions;
        }

        if (!String.isBlank(extra)) {
            strQuery += ' ' + extra;
        }

        //strQuery = String.escapeSingleQuotes(strQuery); // Sanitize Single Quotes

        return Database.query(strQuery);
    }

    //public static List<Scheduled_Payment__c> paymentsToUpdate = new List<Scheduled_Payment__c>();
    //public static List<Scheduled_Payment__c> paymentsToDelete = new List<Scheduled_Payment__c>();
    
    /**
    * @description Method to re-calculate payment schedules
    * @param List<Drawdown__c> drawdownsList
    * @return void
	// Replaced with process and InvocableMethod callout to consolidate work
    public static void updatePaymentScheduleForFacilityLoan(List<Drawdown__c> drawdownsList){
        Set<Id> opportunityIds = new Set<Id>();

        // loop through drawdown list 
        for(Drawdown__c drawdown : drawdownsList){
            if(drawdown.Amount__c != null){
                opportunityIds.add(drawdown.Opportunity__c);
            }
        }
    
        if(!opportunityIds.isEmpty()) adjustPaymentSchedulesForFacilityLoan(opportunityIds);
    }

    /**
    * @description Method to adjust payment schedules
    * @param List<Drawdown__c> drawdownsList
    * @return void
	// Replaced with process and InvocableMethod callout to consolidate work
    public static void adjustPaymentSchedulesForFacilityLoan(Set<Id> opportunityIds){
        Map<Id, Opportunity> opportunitiesMap = new Map<Id, Opportunity>([SELECT Id, Amount_Available_for_Scheduled_Payments__c, Drawdown_Amount__c, 
                                                                            (SELECT Id, Amount__c, Scheduled_Date__c FROM Scheduled_Payments__r WHERE Status__c =: Constants.PAYMENT_SCHEDULED_STATUS ORDER BY Scheduled_Date__c),
                                                                              (SELECT Amount__c FROM Drawdowns__r)
                                                                                FROM Opportunity WHERE Id IN: opportunityIds AND Type_of_Loan__c =: Constants.FACILITY_LOAN LIMIT 45000]);

        if(!opportunitiesMap.isEmpty()){
            for(Opportunity opportunity : opportunitiesMap.values()){
                PaymentHelper.recalculatePayments(opportunity,opportunity.Scheduled_Payments__r);
            }
        }

        if(!paymentsToUpdate.isEmpty()) update paymentsToUpdate;
        if(!paymentsToDelete.isEmpty()) delete paymentsToDelete;
    }
    **/
    
    @AuraEnabled(cacheable=false)
    public static Drawdown__c getDrawdown(Id drawdownId) {
        return [Select Opportunity__c, Date__c, Amount__c, CHQ__c, EFT__c, Payment_Method__c, Outstanding_Balance_as_of_Payout_Date__c, Rejection_Notes__c, Opportunity_Service_Provider__c From Drawdown__c Where Id = :drawdownId];
    }
    
    @AuraEnabled(cacheable=false)
    public static void updateOpportunityPayoutDate(Id opportunityId, Date payoutDate) {
        Opportunity opp = [select Id, Payout_Date__c from Opportunity where Id=:opportunityId];
        opp.Payout_Date__c = payoutDate;
        opp.Temp_Payment_Received__c = 0;
        update opp;        
    }    
}
