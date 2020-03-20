public class OpportunityTriggerScheduleHandler extends TriggerHandler {
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;
    private Opportunity[] newList;
    private Opportunity[] oldList;
    String[] paymentVersionChangeFields = new String[]{
        'Payment_Schedule_Mode__c',
        'Payment_Use_Primary_Bank_Account__c',
        'Payment_Default_Bank_Account__c',
        'Day_of_Month__c',
        'Start_Date__c',
        'End_Date__c',
        'Drawdown_Amount__c',
        'Payment_Schedule_Allotted_Amount__c',
        'Payment_Schedule_Send_First_Immediately__c'
    };
    private Id[] updatePaymentVersion = new Id[]{};
    private Id[] needsPaymentsCalculated = new Id[]{};

    public OpportunityTriggerScheduleHandler() {
        this.newMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        if (this.oldMap == null) {
            this.oldMap = new Map<Id, Opportunity>();
        }
        this.newList = (Opportunity[]) Trigger.new;
        this.oldList = (Opportunity[]) Trigger.old;
    }

    public override void beforeInsert() {
        for (Opportunity opp : this.newList) {
            if (opp.Payment_Schedule__c == 'Yes') {
                opp.Payment_Schedule_Version_Number__c = 1;
            }
        }
    }

    public override void beforeUpdate() {
        for (Opportunity newOpp : this.newMap.values()) {
            Opportunity oldOpp = this.oldMap.get(newOpp.Id);
            System.debug(newOpp);
            System.debug(newOpp.Payment_Schedule__c);
            if (newOpp.Payment_Schedule__c == 'Yes') {
                this.detectScheduleVersionChange(oldOpp, newOpp);
            }
        }
    }

    public override void afterInsert() {
        handlePaymentSchedule();
    }

    public override void afterUpdate() {
        setOutOfDatePayments();
        handlePaymentSchedule();
    }

    private void detectScheduleVersionChange(Opportunity oldOpp, Opportunity newOpp) {
        if (oldOpp.Payment_Schedule__c == 'No') {
            if (newOpp.Payment_Schedule_Version_Number__c == null) {
                newOpp.Payment_Schedule_Version_Number__c = 1;
            } else {
                newOpp.Payment_Schedule_Version_Number__c += 1;
            }
            newOpp.Amount_sent_from_current_Schedule__c = 0.00; // reset Sent Amount
            return;
        }
        for (String field : this.paymentVersionChangeFields) {
            if (oldOpp.get(field) != newOpp.get(field)) {
                if (newOpp.Payment_Schedule_Version_Number__c == null) {
                    newOpp.Payment_Schedule_Version_Number__c = 1;
                } else {
                    newOpp.Payment_Schedule_Version_Number__c += 1;
                }
                newOpp.Amount_sent_from_current_Schedule__c = 0.00; // reset Sent Amount
                // If this works I can stop watching Current Version manually
                if (oldOpp.Payment_Schedule__c == 'Yes') // Only update SPs if there was an active schedule to begin with
                    this.updatePaymentVersion.add(newOpp.Id);
                return;
            }
        }
    }

    private void setOutOfDatePayments() {        
        if (this.updatePaymentVersion.isEmpty())
            return;
        Scheduled_Payment__c[] spList = [Select Id From Scheduled_Payment__c Where Opportunity__c in :this.updatePaymentVersion and Current_Opportunity_Schedule_Version_Val__c = true and Status__c not in :Constants.PAYMENT_SCHEDULE_MODIFIABLE_STATUSES];
        System.debug(spList);
        for (Scheduled_Payment__c sp : spList) {
            sp.Current_Opportunity_Schedule_Version_Val__c = false;
        }
        if (!spList.isEmpty()) {
            update spList;
        }
    }


    private void handlePaymentSchedule() {
        // Need to update version on Scheduled Payments. Do I need to do this? Won't recalculate get them?
        Id[] needsRecalculated = new Id[]{};
        Map<Id, Opportunity> testMap = new Map<Id, Opportunity>();
        Opportunity oldOpp = null;
        for (Opportunity newOpp : this.newMap.values()) {
            if (newOpp.Payment_Schedule__c == 'Yes') {
                if (this.oldMap.containsKey(newOpp.Id)) {
                    oldOpp = this.oldMap.get(newOpp.Id);
                    if (oldOpp.Payment_Schedule_Version_Number__c != newOpp.Payment_Schedule_Version_Number__c) {
                        this.updatePaymentVersion.add(newOpp.Id);
                    }
                    if (oldOpp.Payment_Schedule__c == 'No' || 
                        oldOpp.Payment_Schedule_Version_Number__c != newOpp.Payment_Schedule_Version_Number__c ||
                        oldOpp.Payment_Scheduled_Allotment_Remaining__c != newOpp.Payment_Scheduled_Allotment_Remaining__c
                        ) {
                        this.needsPaymentsCalculated.add(newOpp.Id);
                    }
                } else {
                    // Insert
                    this.needsPaymentsCalculated.add(newOpp.Id);
                }
            }
        }
        setOutOfDatePayments();
        recalculatePayments();
    }

    private void recalculatePayments() {
        if (!this.needsPaymentsCalculated.isEmpty()) {
            PaymentHelper.recalculatePayments(this.needsPaymentsCalculated);
        }
    }
}
