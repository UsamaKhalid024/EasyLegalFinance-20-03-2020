public class PaymentRejectionTriggerHandler extends TriggerHandler {
    private Map<Id, Payment_Rejection__c> newPRMap;
    private Map<Id, Payment_Rejection__c> oldPRMap;

    public PaymentRejectionTriggerHandler() {
        System.debug('In PaymentRejectionTriggerHandler Constructor');
        this.newPRMap = (Map<Id, Payment_Rejection__c>) Trigger.newMap;
        this.oldPRMap = (Map<Id, Payment_Rejection__c>) Trigger.oldMap;
    }

    public override void afterInsert() {
        Id[] spIds = new Id[]{};
        Map<Id, Scheduled_Payment__c> spMap;
        SObject[] insertList = new SObject[]{}; // Used to store Drawdowns and Scheduled Payments that need updated in one transaction
        SObject[] updateList = new SObject[]{}; // Used to store Drawdowns and Scheduled Payments that need updated in one transaction
        //Drawdown__c[] ddList = new Drawdown__c[]{};
        //Scheduled_Payment__c[] spList = new Scheduled

        for (Payment_Rejection__c pr : this.newPRMap.values()) {
            spIds.add(pr.Scheduled_Payment__c);
        }

        // Fetch scheduled payments and drawdowns
        spMap = new Map<Id, Scheduled_Payment__c>([
            Select 
                Id, Drawdown__c, Opportunity__c, First_Sent_to_Bank_Date__c, Notes__c,
                Drawdown__r.Amount__c,
                Drawdown__r.CHQ__c,
                Drawdown__r.Date__c,
                Drawdown__r.EFT__c,
                Drawdown__r.Opportunity_Service_Provider__c,
                Drawdown__r.Payment_Method__c
            From Scheduled_Payment__c
            Where Id in :spIds
        ]);

        SObject[] result;
        for (Payment_Rejection__c pr : this.newPRMap.values()) {
            result = calculateModifications(pr, spMap.get(pr.Scheduled_Payment__c));
            if (result[0] != null) {
                updateList.add(result[0]);
            }
            if (result[1] != null) {
                insertList.add(result[1]);
            }
        }

        if (!updateList.isEmpty()) {
            update updateList;
        }
        if (!insertList.isEmpty()) {
            insert insertList;
        }
    }

    private SObject[] calculateModifications(Payment_Rejection__c pr, Scheduled_Payment__c sp) {
        SOBject[] result = new SOBject[]{sp, null};

        // Create new Drawdown if necessary
        if (String.isNotBlank(sp.Drawdown__c)) {
            Drawdown__c dd = new Drawdown__c();
            dd.Opportunity__c = sp.Opportunity__c;
            dd.Amount__c = 0 - sp.Drawdown__r.Amount__c;
            dd.CHQ__c = sp.Drawdown__r.CHQ__c;
            dd.Date__c = sp.Drawdown__r.Date__c;
            dd.EFT__c = sp.Drawdown__r.EFT__c;
            dd.Opportunity_Service_Provider__c = sp.Drawdown__r.Opportunity_Service_Provider__c;
            dd.Payment_Method__c = sp.Drawdown__r.Payment_Method__c;
            dd.Reference_Notes__c = 'Payment Rejected';
            dd.Scheduled_Payment__c = sp.Id;
            sp.Has_Been_Rejected__c = true;
            result[1] = dd;
        }

        // Update Scheduled Payment
        sp.Banking_Verified__c = false;
        sp.BIA_PPSA_LL_Verified__c = false;
        sp.Credit_Verified__c = false;
        sp.Documents_Verified__c = false;
        sp.Drawdown__c = null;
        sp.Drawdown_Created__c = false;
        if (!pr.Use_Original_Sent_Date_for_Interest__c) {
            sp.First_Sent_to_Bank_Date__c = null;
        }
        if (String.isNotBlank(sp.Drawdown__c)) {
            sp.Has_Been_Rejected__c = true;
        }
        if (pr.Scheduled_Payment_Action__c == 'Set to Rejected') {
            sp.Hold__c = true;
        }
        if (String.isNotBlank(pr.Reason__c)) {
            if (String.isBlank(sp.Notes__c)){
                sp.Notes__c = pr.Reason__c;
            } else {
                sp.Notes__c = pr.Reason__c + '\r\n\r\n' + sp.Notes__c;
            }
        }
        sp.Sent_to_Bank_Date__c = null;
        sp.Status__c = pr.Scheduled_Payment_Action__c.remove('Set to ');
        result[0] = sp;

        return result;
    }
}
