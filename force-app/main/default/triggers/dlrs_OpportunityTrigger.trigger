/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_OpportunityTrigger on Opportunity(before delete, before insert, before update, after delete, after insert, after undelete, after update){
    new OpportunityTriggerScheduleHandler().run();
    if(!TriggerHelper.runOnce('dlrs_OpportunityTrigger')){
        TriggerHelper.add('dlrs_OpportunityTrigger');
        dlrs.RollupService.triggerHandler();
    }
    
    /*if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete)){
        dlrs.RollupService.rollup(Trigger.oldMap, Trigger.newMap, Opportunity.SObjectType);
    }*/
}