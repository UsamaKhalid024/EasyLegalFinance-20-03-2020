/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_Opportunity_Service_ProviderTrigger on Opportunity_Service_Provider__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(Opportunity_Service_Provider__c.SObjectType);
}