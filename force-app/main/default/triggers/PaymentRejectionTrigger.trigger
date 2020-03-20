trigger PaymentRejectionTrigger on Payment_Rejection__c (before delete, before insert, before update, after delete, after insert, after undelete, after update) {
    new PaymentRejectionTriggerHandler().run();
}