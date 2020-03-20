/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Drawdown_Payment_AllocationTrigger on Drawdown_Payment_Allocation__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Drawdown_Payment_Allocation__c.SObjectType);
}