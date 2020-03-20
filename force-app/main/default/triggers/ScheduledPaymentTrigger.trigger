/**
 * @File Name          : ScheduledPaymentTrigger.trigger
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/10/2019, 12:30:53 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    5/10/2019, 12:30:18 PM   Seth Boyd     Initial Version
**/
trigger ScheduledPaymentTrigger on Scheduled_Payment__c (before delete, before insert, before update, after delete, after insert, after undelete, after update) {
    new ScheduledPaymentTriggerHandler().run();
    dlrs.RollupService.triggerHandler(Scheduled_Payment__c.SObjectType);
}