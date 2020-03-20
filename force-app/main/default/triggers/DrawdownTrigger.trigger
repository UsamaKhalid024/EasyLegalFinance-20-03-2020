/**
 * @File Name          : DrawdownTrigger.trigger
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/17/2019, 9:01:25 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author                    Modification
 *==============================================================================
 * 1.0    4/17/2019, 9:01:25 AM   Seth Boyd     Initial Version
**/
trigger DrawdownTrigger on Drawdown__c (before insert , before update, after insert , after update, before delete, after delete) {

    if (trigger.isBefore && trigger.isInsert && !TriggerHelper.runOnce('DrawdownTrigger')) {
        TriggerHelper.add('DrawdownTrigger');
        // send with empty "old map" as this isn't available in insert trigger
        Map <Id,Drawdown__c> dummyMap = new Map<Id,Drawdown__c> ();
        DrawdownTriggerHandler.validatePaymentChange( dummyMap,trigger.new);            
    }  
    if (trigger.isBefore && trigger.isUpdate && !TriggerHelper.runOnce('DrawdownTrigger')) {
        TriggerHelper.add('DrawdownTrigger');
        DrawdownTriggerHandler.validatePaymentChange(trigger.oldMap,trigger.new);           
    }
    if(trigger.isBefore && trigger.isDelete){
        DrawdownTriggerHandler.validatePaymentDelete(trigger.old);
        // Deleting a Master object will cascade-delete the Detail objects, but Apex wont
        // run delete triggers for the cascade-deleted records.  That prevents the DLRS
        // summaries from running,
        // see https://github.com/afawcett/declarative-lookup-rollup-summaries/issues/257
        //
        // As a work around, we will delete the Detail records directly
        List <ID> toDel = New List<ID>{};
        toDel.addAll(trigger.oldMap.keySet());
        DeletePaymentAllocations.DeletePaymentAllocationsFromPayment(toDel);
    }
    if(trigger.isAfter && (Trigger.isInsert || trigger.isUpdate || trigger.isDelete) /*&& !TriggerHelper.runOnce('DrawdownTrigger')*/ ){
        //TriggerHelper.add('DrawdownTrigger');
		//TriggerHelper.runOnce.. removed, because outstanding balance was not calculted correctly on payment applying
        ///*
        DrawdownTriggerHandler.updateAdminFeeOnFirstDrawdown(Trigger.isDelete ? Trigger.old : Trigger.new,
                                                             Trigger.oldMap,
                                                             Trigger.isInsert || Trigger.isDelete);
        
        // DrawdownTriggerHandler.reCalculateCriticalDatePayout(Trigger.isDelete ? Trigger.old : Trigger.new, 
                                                             // Trigger.oldMap, Trigger.isInsert || Trigger.isDelete);        
        //*/
    }
    
    /*
    // Replaced with process and InvocableMethod callout to consolidate work
    if(trigger.isAfter && (Trigger.isInsert || trigger.isUpdate)){
        DrawdownHelper.updatePaymentScheduleForFacilityLoan((List<Drawdown__c>)Trigger.new);
    }
    */
    if (trigger.isAfter && Trigger.isInsert){
        DrawdownTriggerHandler.createAdminFeeRejections(Trigger.new);
    } 
    if (trigger.isAfter && (Trigger.isInsert || trigger.isUpdate)){
        DrawdownPaymentAllocator.allocate(Trigger.isInsert, Trigger.oldMap, Trigger.new);
    }  
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert || Trigger.isDelete)){
        dlrs.RollupService.rollup(Trigger.oldMap, Trigger.newMap, Drawdown__c.SObjectType);
    }
}
