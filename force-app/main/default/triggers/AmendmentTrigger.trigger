trigger AmendmentTrigger on Opportunity (after update) {

    if(trigger.isAfter && trigger.isUpdate && !TriggerHelper.runOnce('AmendmentTrigger')){
        TriggerHelper.add('AmendmentTrigger');
        AmendmentTriggerHandler.createActivityHistory(trigger.newMap);
    }
}