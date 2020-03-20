trigger AssessmentProviderScheduleTrigger on Assessment_Provider_Schedule__c (after insert, after update) {
    
    if(trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
        AssessmentProviderScheduleTriggerHandler.updateAssessmentScheduleOnOpportunities(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}