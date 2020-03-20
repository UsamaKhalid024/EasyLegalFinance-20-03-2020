trigger criticalDateTrigger on Critical_Date__c (before insert, before update) {
        
    if(trigger.isBefore && ( trigger.isUpdate || Trigger.isInsert)){
        criticalDateTriggerHandler.calculatePayout(trigger.new, trigger.oldMap, Trigger.isInsert, false);
    }
    
}