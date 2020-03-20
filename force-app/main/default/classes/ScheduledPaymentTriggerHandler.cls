/**
 * @File Name          : ScheduledPaymentTriggerHandler.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/10/2019, 12:45:27 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    5/10/2019, 9:33:03 AM   Seth Boyd     Initial Version
**/
public class ScheduledPaymentTriggerHandler extends TriggerHandler {
    private Map<Id, Scheduled_Payment__c> newSPMap;
    private Map<Id, Scheduled_Payment__c> oldSPMap;
    private Set<Id> oppIdsCheckFirstPayment = new Set<Id>();
    private Map<Id, Scheduled_Payment__c> otherUpdatedSPs = new Map<Id, Scheduled_Payment__c>();
    private Map<Id, Opportunity_Service_Provider__c> ospMap = new Map<Id, Opportunity_Service_Provider__c>();
    private Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    //private Opportunity_Service_Provider__c[] ospList = new Opportunity_Service_Provider__c[]{};
    //private Map<Id, Scheduled_Payment__c> otherUpdatedSPs = new Map<Id, Scheduled_Payment__c>();
    //private Map<Id, Scheduled_Payment__c> oppToFirstSPMap = new Map<Id, Scheduled_Payment__c>();
    //private Set<Id> otherRequiredSPs = new Map<Id, Scheduled_Payment__c>();

    public ScheduledPaymentTriggerHandler() {
        System.debug('In ScheduledPaymentTriggerHandler Constructor');
        this.newSPMap = (Map<Id, Scheduled_Payment__c>) Trigger.newMap;
        this.oldSPMap = (Map<Id, Scheduled_Payment__c>) Trigger.oldMap;
    }
    
    public override void beforeInsert() {        
        validateSPs();
    }
    
    public void validateSPs(){
        List<Scheduled_Payment__c> spList = Trigger.new;
        for (Scheduled_Payment__c sp : spList) {
            if (sp.Calculated_Payment_Type__c == null || sp.Calculated_Payment_Type__c == 'None'){
                sp.addError('Loan type is not specified or incorrect');
            }
        }        
    }

    public override void afterInsert() {
        System.debug('In After Insert');
        Previous_Loan__c[] plList = new Previous_Loan__c[]{};

        for (Scheduled_Payment__c sp : this.newSPMap.values()) {
            if (sp.Scheduled_Date__c != null) {
                // Just inserted a new payment with a Scheduled Date, so we need refresh the First scheduled payment status
                this.oppIdsCheckFirstPayment.add(sp.Opportunity__c);
            }
            if (String.isNotBlank(sp.Opportunity_Service_Provider__c)){
                if (!this.ospMap.containsKey(sp.Opportunity_Service_Provider__c)) {
                    // Set to Roll up to 0 because it won't get reset if this was the only payment included
                    this.ospMap.put(sp.Opportunity_Service_Provider__c, new Opportunity_Service_Provider__c(Id=(Id)sp.Opportunity_Service_Provider__c, Total_Scheduled_Payments__c=0, Opportunity__c=(Id)sp.Opportunity__c));
                }
            }
            if (String.isNotBlank(sp.Previous_Loan__c)){
                plList.add(new Previous_Loan__c(id=sp.Previous_Loan__c, Scheduled_Payment__c=sp.Id, Scheduled__c=true));
            }
            if (sp.Current_Opportunity_Schedule_Version_Val__c == true && sp.Drawdown_Created__c == true) {
                if (this.oppMap.containsKey(sp.Opportunity__c)) {
                    this.oppMap.get(sp.Opportunity__c).Amount_sent_from_current_Schedule__c -= sp.Amount__c;
                } else {
                    this.oppMap.put(sp.Opportunity__c, new Opportunity(Id=sp.Opportunity__c, Amount_sent_from_current_Schedule__c = 0-sp.Amount__c));
                }
            }
        }

        if (!plList.isEmpty()) {
            update plList;
        }

        setFirstOccuringPayment();

        updateOtherSPs();

        updateOpportunityServiceProviderRollup();

        updateOpportunities();
    }
    
    public override void afterUpdate() {
        Previous_Loan__c[] plList = new Previous_Loan__c[]{};

        for (Scheduled_Payment__c sp : this.newSPMap.values()) {
            if (sp.Scheduled_Date__c != this.oldSPMap.get(sp.Id).Scheduled_Date__c) {
                // Just edited the Scheduled Date, so we need refresh the First scheduled payment status
                this.oppIdsCheckFirstPayment.add(sp.Opportunity__c);
            }
            if (String.isNotBlank(sp.Opportunity_Service_Provider__c)){
                if (!this.ospMap.containsKey(sp.Opportunity_Service_Provider__c)) {
                    // Set to Roll up to 0 because it won't get reset if this was the only payment included
                    this.ospMap.put(sp.Opportunity_Service_Provider__c, new Opportunity_Service_Provider__c(Id=(Id)sp.Opportunity_Service_Provider__c, Total_Scheduled_Payments__c=0, Opportunity__c=(Id)sp.Opportunity__c));
                }
            }
            if (String.isNotBlank(sp.Previous_Loan__c)){
                plList.add(new Previous_Loan__c(id=sp.Previous_Loan__c, Scheduled_Payment__c=sp.Id, Scheduled__c=true));
            }
            if (sp.Current_Opportunity_Schedule_Version_Val__c == true && sp.Drawdown_Created__c != this.oldSPMap.get(sp.Id).Drawdown_Created__c) {
                Integer negator = 1;
                if (sp.Drawdown_Created__c == false) {
                    // Reversed
                    negator = -1;
                }
                if (this.oppMap.containsKey(sp.Opportunity__c)) {
                    this.oppMap.get(sp.Opportunity__c).Amount_sent_from_current_Schedule__c += sp.Amount__c * negator;
                } else {
                    this.oppMap.put(sp.Opportunity__c, new Opportunity(Id=sp.Opportunity__c, Amount_sent_from_current_Schedule__c = sp.Amount__c * negator));
                }
            }
        }

        if (!plList.isEmpty()) {
            update plList;
        }

        setFirstOccuringPayment();

        updateOtherSPs();

        updateOpportunityServiceProviderRollup();
        
        updateOpportunities();
    }

    public override void afterDelete() {
        Previous_Loan__c[] plList = new Previous_Loan__c[]{};
        for (Scheduled_Payment__c sp : this.oldSPMap.values()) {
            if (sp.First_Scheduled_Payment__c == true) {
                // Just deleted First payment, so we need to find a new one
                this.oppIdsCheckFirstPayment.add(sp.Opportunity__c);
            }
            if (String.isNotBlank(sp.Opportunity_Service_Provider__c)){
                if (!this.ospMap.containsKey(sp.Opportunity_Service_Provider__c)) {
                    // Set to Roll up to 0 because it won't get reset if this was the only payment included
                    this.ospMap.put(sp.Opportunity_Service_Provider__c, new Opportunity_Service_Provider__c(Id=(Id)sp.Opportunity_Service_Provider__c, Total_Scheduled_Payments__c=0));
                }
            }
            if (String.isNotBlank(sp.Previous_Loan__c)){
                plList.add(new Previous_Loan__c(id=sp.Previous_Loan__c, Scheduled_Payment__c=null, Scheduled__c=false));
            }
            if (sp.Current_Opportunity_Schedule_Version_Val__c == true && sp.Drawdown_Created__c == true) {
                if (this.oppMap.containsKey(sp.Opportunity__c)) {
                    this.oppMap.get(sp.Opportunity__c).Amount_sent_from_current_Schedule__c += sp.Amount__c;
                } else {
                    this.oppMap.put(sp.Opportunity__c, new Opportunity(Id=sp.Opportunity__c, Amount_sent_from_current_Schedule__c = sp.Amount__c));
                }
            }
        }

        if (!plList.isEmpty()) {
            update plList;
        }

        setFirstOccuringPayment();

        updateOtherSPs();

        updateOpportunityServiceProviderRollup();

        updateOpportunities();
    }

    private void updateOpportunities() {
        /*
        fetch opps in map (if any)
            go through fetched opps
            update fetched opp values with oppMap values
            update fetched opps
        */
        if (!this.oppMap.isEmpty()) {
            Opportunity[] oppList = [Select Id, Amount_sent_from_current_Schedule__c From Opportunity Where Id in :this.oppMap.keySet()];
            for (Opportunity opp : oppList) {
                system.debug(opp);
                if (opp.Amount_sent_from_current_Schedule__c == null) {
                    opp.Amount_sent_from_current_Schedule__c = this.oppMap.get(opp.Id).Amount_sent_from_current_Schedule__c;
                } else {
                    opp.Amount_sent_from_current_Schedule__c += this.oppMap.get(opp.Id).Amount_sent_from_current_Schedule__c;
                }
                system.debug(opp);
            }
            update oppList;
        }
    }

    public void updateOpportunityServiceProviderRollup() {
        AggregateResult[] arList = [
            Select
                Opportunity_Service_Provider__c,
                SUM(Amount__c) total
            From Scheduled_Payment__c
            Where
                Opportunity_Service_Provider__c in :this.ospMap.keySet()
                AND Drawdown_Created__c = false
            Group By Opportunity_Service_Provider__c
        ];

        Map<Id, Decimal> arMap = new Map<Id, Decimal>();

        for (AggregateResult ar : arList) {
            arMap.put((Id)ar.get('Opportunity_Service_Provider__c'), (Decimal)ar.get('total'));
        }

        for (Opportunity_Service_Provider__c osp : this.ospMap.values()) {
            if (arMap.containsKey(osp.Id)) {
                osp.Total_Scheduled_Payments__c = arMap.get(osp.Id);
            } else {
                osp.Total_Scheduled_Payments__c = 0;
            }
        }

        if (!this.ospMap.isEmpty()) update this.ospMap.values();
    }

    public void updateOtherSPs() {
        if (!this.otherUpdatedSPs.values().isEmpty()) {
            upsert this.otherUpdatedSPs.values();
        }
    }


    private void setFirstOccuringPayment() {
        for (Opportunity opp : [
                Select Id,
                    (Select Id, Scheduled_Date__c, First_Scheduled_Payment__c
                    From Scheduled_Payments__r
                    Where ( First_Scheduled_Payment__c = true or Scheduled_Date__c != null )
                    Order By First_Scheduled_Payment__c DESC NULLS LAST, Scheduled_Date__c ASC NULLS LAST LIMIT 2)
                From Opportunity Where Id in : this.oppIdsCheckFirstPayment]) {
            
            if (opp.Scheduled_Payments__r.size() == 2) {
                if (opp.Scheduled_Payments__r[0].First_Scheduled_Payment__c == true) {
                    if (opp.Scheduled_Payments__r[0].Scheduled_Date__c > opp.Scheduled_Payments__r[1].Scheduled_Date__c) {
                        // Payments have changed such that First_Scheduled_Payment__c needs to be marked on a different payment 
                        if (!this.otherUpdatedSPs.containsKey(opp.Scheduled_Payments__r[0].Id)) {
                            this.otherUpdatedSPs.put(opp.Scheduled_Payments__r[0].Id, opp.Scheduled_Payments__r[0]);
                        }
                        this.otherUpdatedSPs.get(opp.Scheduled_Payments__r[0].Id).First_Scheduled_Payment__c = false;

                        if (!this.otherUpdatedSPs.containsKey(opp.Scheduled_Payments__r[1].Id)) {
                            this.otherUpdatedSPs.put(opp.Scheduled_Payments__r[1].Id, opp.Scheduled_Payments__r[1]);
                        }
                        this.otherUpdatedSPs.get(opp.Scheduled_Payments__r[1].Id).First_Scheduled_Payment__c = true;
                    }
                } else {
                    // Set first.First_Scheduled_Payment__c to true
                    if (!this.otherUpdatedSPs.containsKey(opp.Scheduled_Payments__r[0].Id)) {
                        this.otherUpdatedSPs.put(opp.Scheduled_Payments__r[0].Id, opp.Scheduled_Payments__r[0]);
                    }
                    this.otherUpdatedSPs.get(opp.Scheduled_Payments__r[0].Id).First_Scheduled_Payment__c = true;
                }
            } else if (opp.Scheduled_Payments__r.size() == 1 && opp.Scheduled_Payments__r[0].First_Scheduled_Payment__c == false) {
                // Only one payment and it should be marked as the First
                if (!this.otherUpdatedSPs.containsKey(opp.Scheduled_Payments__r[0].Id)) {
                    this.otherUpdatedSPs.put(opp.Scheduled_Payments__r[0].Id, opp.Scheduled_Payments__r[0]);
                }
                this.otherUpdatedSPs.get(opp.Scheduled_Payments__r[0].Id).First_Scheduled_Payment__c = true;
            }
        }
    }
    /*

    public void setFirstPaymentInContext(Scheduled_Payment__c sp) {
        // Check if SP is the first found in this context
        // Later on in trigger check agains the current first (if there is one)
        if (sp.Scheduled_Date__c != null) {
            if (this.oppToFirstSPMap.containsKey(sp.Opportunity__c)) {
                if (this.oppToFirstSPMap.get(sp.Opportunity__c).Scheduled_Date__c > sp.Scheduled_Date__c) {
                    this.oppToFirstSPMap.get(sp.Opportunity__c).First_Scheduled_Payment__c = false;
                    sp.First_Scheduled_Payment__c = true;
                    this.oppToFirstSPMap.put(sp.Opportunity__c, sp);
                } else {
                    sp.First_Scheduled_Payment__c = false;
                }
            } else {
                sp.First_Scheduled_Payment__c = true;
                this.oppToFirstSPMap.put(sp.Opportunity__c, sp);
            }
        } else {
            sp.First_Scheduled_Payment__c = false;
        }
    }

    public void compareFirstInTriggerToDB() {
        // This looks at the current first
        // What do I do if there isn't one set?
        // loop over ops with a subquery containing the lowest date and currently selected


        // Seperate out update/insert function and delete function
        // delete needs to 
        for (Opportunity opp : [
                Select Id,
                    (Select Id, Scheduled_Date__c
                    From Scheduled_Payments
                    Where ( First_Scheduled_Payment__c = true or Scheduled_Payment__c != null ) and Id not in :this.newSPMap.keySet()
                    Order By Scheduled_Payment__c ASC NULLS LAST LIMIT 2)
                From Opportunity Where Id in : this.oppToFirstSPMap.keySet()]) {
            
            if (!opp.Scheduled_Payments__r.isEmpty()) {

                if (Trigger.isDelete) {
                    // set to first found Scheduled Date if one exists
                    if (!this.otherUpdatedSPs.containsKey(opp.Scheduled_Payments__r[0].Id)) {
                        this.otherUpdatedSPs.put(opp.Scheduled_Payments__r[0].Id, opp.Scheduled_Payments__r[0]);
                    }
                    this.otherUpdatedSPs.get(opp.Scheduled_Payments__r[0].Id).First_Scheduled_Payment__c = false;
                } else {
                    // Check first returned SP

                    // Check second returned SP if it exists
                }
            }
            
            
            
            if (sp.Scheduled_Date__c > this.oppToFirstSPMap.get(sp.Opportunity__c).Scheduled_Date__c) {
                if (!this.otherUpdatedSPs.containsKey(sp.Id)) {
                    this.otherUpdatedSPs.put(sp.Id, sp);
                }
                this.otherUpdatedSPs.get(sp.Id).First_Scheduled_Payment__c = false;
            } else {
                this.oppToFirstSPMap.get(sp.Opportunity__c).First_Scheduled_Payment__c = false;
            }
        }
    }
    */
}
