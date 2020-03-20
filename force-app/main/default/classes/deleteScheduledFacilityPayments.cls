public with sharing class deleteScheduledFacilityPayments {

     /**
    * @description Method to delete payments on scheduled status
    * @param opportunityId Id of the opportunity record
    * @return void
    **/
	@InvocableMethod(label='Delete Scheduled Facility Payments' description='Delete Scheduled Facility Payments')
    public static void deleteScheduledFacilityPayments(Id[] oppIds){
        delete [SELECT Id FROM Scheduled_Payment__c WHERE Opportunity__c in :oppIds AND Status__c = 'Scheduled' AND Payment_Type__c = 'Scheduled Facility' LIMIT 30000];
    }
}