/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_DrawdownTrigger on Drawdown__c(before delete, before insert, before update, after delete, after insert, after undelete, after update){
    if(!TriggerHelper.runOnce('dlrs_DrawdownTrigger')){
        TriggerHelper.add('dlrs_DrawdownTrigger');
        dlrs.RollupService.triggerHandler(Drawdown__c.SObjectType);
    }
    
}