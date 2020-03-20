public class UserTriggerHandler extends TriggerHandler {
    private Map<Id, User> newMap;
    private Map<Id, User> oldMap;
    /*
    private Set<Id> oppIdsCheckFirstPayment = new Set<Id>();
    private Map<Id, Scheduled_Payment__c> otherUpdatedSPs = new Map<Id, Scheduled_Payment__c>();
    private Map<Id, Opportunity_Service_Provider__c> ospMap = new Map<Id, Opportunity_Service_Provider__c>();
    */
    //private Opportunity_Service_Provider__c[] ospList = new Opportunity_Service_Provider__c[]{};
    //private Map<Id, Scheduled_Payment__c> otherUpdatedSPs = new Map<Id, Scheduled_Payment__c>();
    //private Map<Id, Scheduled_Payment__c> oppToFirstSPMap = new Map<Id, Scheduled_Payment__c>();
    //private Set<Id> otherRequiredSPs = new Map<Id, Scheduled_Payment__c>();
    public UserTriggerHandler() {
        System.debug('In UserTriggerHandler Constructor');
        this.newMap = (Map<Id, User>) Trigger.newMap;
        this.oldMap = (Map<Id, User>) Trigger.oldMap;
    }

    public override void afterInsert() {
        PermissionAssigner pa = new PermissionAssigner(this.oldMap, this.newMap);
        pa.applyPermissionsChanges();
    }

    public override void afterUpdate() {
        PermissionAssigner pa = new PermissionAssigner(this.oldMap, this.newMap);
        pa.applyPermissionsChanges();
    }
}