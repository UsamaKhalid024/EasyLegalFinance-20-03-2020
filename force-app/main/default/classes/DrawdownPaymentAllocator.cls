public class DrawdownPaymentAllocator {
    public static Set<Id> processedAdvancesIds = new Set<Id>();    
    public static void allocate(Boolean isInsert, Map<Id, Drawdown__c> oldDrawdownsMap, List<Drawdown__c> newDrawdowns){
        updatePayoutDate(isInsert, oldDrawdownsMap, newDrawdowns);        
        deletePaymentAllocations(isInsert, newDrawdowns, oldDrawdownsMap);        
        removeLoanSetup(newDrawdowns);
        allocatePayments(isInsert, newDrawdowns, oldDrawdownsMap);
        clearPaymentAllocationFlag(newDrawdowns);
        allocateAnotherPayments(isInsert, oldDrawdownsMap, newDrawdowns);
    }
        
    public static void updatePayoutDate(Boolean isInsert,  Map<Id, Drawdown__c> oldDrawdownsMap, List<Drawdown__c> newDrawdowns){
        Map<Id, Drawdown__c> selectedOppToDrawdownMap = new Map<Id, Drawdown__c>();
        for (Drawdown__c newDrawdown : newDrawdowns){
            Drawdown__c oldDrawdown = null;
            if (!isInsert)
                oldDrawdown = oldDrawdownsMap.get(newDrawdown.Id);
            if (checkDrawdown(isInsert, newDrawdown, oldDrawdown)){
                selectedOppToDrawdownMap.put(newDrawdown.Opportunity__c, newDrawdown);
            }
        }
        if (!selectedOppToDrawdownMap.isEmpty()){
            List<Opportunity> oppsToUpdate = [select Id, Payout_Date__c from Opportunity where Id in :selectedOppToDrawdownMap.keySet()];
            for (Opportunity opp : oppsToUpdate){
                opp.Payout_Date__c = selectedOppToDrawdownMap.get(opp.Id).Date__c;
            }
            update oppsToUpdate;
        }
    }
    
    public static Boolean checkDrawdown(Boolean isInsert, Drawdown__c newDrawdown, Drawdown__c oldDrawdown){
        if (newDrawdown.Payment_Method__c == 'Payment' &&
           (isInsert || checkDrawdown(newDrawdown, oldDrawdown) )){
                return true;
            }
        
        return false;
    }
    
    public static Boolean checkDrawdown(Drawdown__c newDrawdown, Drawdown__c oldDrawdown){
        if (newDrawdown.Allocate_Payment__c)
            return true;
        if (oldDrawdown == null)
            return false;
        return (oldDrawdown.Payment_Method__c != 'Payment') || (newDrawdown.Amount__c != oldDrawdown.Amount__c) || 
            (newDrawdown.Date__c != oldDrawdown.Date__c);
    }
    
    public static void deletePaymentAllocations(Boolean isInsert, List<Drawdown__c> newDrawdowns, Map<Id, Drawdown__c> oldDrawdownsMap){
        List<Id> selectedDrawdownIds = new List<Id>();
        for (Drawdown__c newDrawdown : newDrawdowns){
            if (isInsert){
                if (newDrawdown.Payment_Method__c == 'Payment' && newDrawdown.Allocate_Payment__c)
                    selectedDrawdownIds.add(newDrawdown.Id);
            }
            else{
                Drawdown__c oldDrawdown = oldDrawdownsMap.get(newDrawdown.Id);  
                if (newDrawdown.Payment_Method__c != 'Payment' && oldDrawdown.Payment_Method__c == 'Payment'
                   || ( newDrawdown.Payment_Method__c == 'Payment' && checkDrawdown(newDrawdown, oldDrawdown) ) ) {
                        selectedDrawdownIds.add(newDrawdown.Id);                                                                
                   }
            }
        }
        if (!selectedDrawdownIds.isEmpty()){
            DeletePaymentAllocations.DeletePaymentAllocationsFromPayment(selectedDrawdownIds);
        }
    }
    
    public static void removeLoanSetup(List<Drawdown__c> drawdowns){
        List<Id> selectedDrawdownIds = new List<Id>();
        for (Drawdown__c drawdown : drawdowns){
            if (drawdown.Payment_Method__c == 'Payment' && (drawdown.Interest_Rate__c != null) &&
               (drawdown.Compounding_Frequency__c != null || drawdown.Interest_Deferral_Period__c != null ||
                drawdown.Minimum_Interest_Period__c != null || drawdown.Payout_Date__c != null) ){
                    selectedDrawdownIds.add(drawdown.Id);
                }
        }        
        if (!selectedDrawdownIds.isEmpty()){
            List<Drawdown__c> selectedDrawdowns = [select Id, Compounding_Frequency__c, Compounding_Interest__c, Interest_Deferral_Period__c, Interest_Rate__c,
                                                  Minimum_Interest_Period__c, Payout_Date__c, Temp_Payout_Date__c from Drawdown__c where Id in : selectedDrawdownIds];
            for (Drawdown__c drawdown : selectedDrawdowns){
                drawdown.Compounding_Frequency__c = null;
                drawdown.Compounding_Interest__c = false;
                drawdown.Interest_Deferral_Period__c = null;
                drawdown.Interest_Rate__c = null;
                drawdown.Minimum_Interest_Period__c = null;
                drawdown.Payout_Date__c = null;
                drawdown.Temp_Payout_Date__c = null;
            }
            update selectedDrawdowns;
        }
    }
    
    public static void allocatePayments(Boolean isInsert, List<Drawdown__c> newDrawdowns, Map<Id, Drawdown__c> oldDrawdownsMap){
        List<Id> selectedDrawdownIds = new List<Id>();
        List<Id> rejectionDrawdownIds = new List<Id>();
        for (Drawdown__c newDrawdown : newDrawdowns){
            Drawdown__c oldDrawdown = null;
            if (!isInsert)
                oldDrawdown = oldDrawdownsMap.get(newDrawdown.Id);                
            if (checkDrawdown(isInsert, newDrawdown, oldDrawdown)){            
                if (newDrawdown.Reference_Notes__c == 'Payment Rejected' || newDrawdown.Reference_Notes__c == 'Payment Halted')
                    rejectionDrawdownIds.add(newDrawdown.Id);
                else
                    selectedDrawdownIds.add(newDrawdown.Id);
            }            
        }
        if (!rejectionDrawdownIds.isEmpty()){
            PaymentAllocator.allocateRejectionDrawdowns(rejectionDrawdownIds);
        }
        if (!selectedDrawdownIds.isEmpty()){
            PaymentAllocator.AllocatePayments(selectedDrawdownIds);        
        }
    }
    
    public static void clearPaymentAllocationFlag(List<Drawdown__c> drawdowns){
        List<Id> selectedDrawdownIds = new List<Id>();
        for (Drawdown__c drawdown : drawdowns){
            if (drawdown.Allocate_Payment__c)
                selectedDrawdownIds.add(drawdown.Id);
        }
        if (!selectedDrawdownIds.isEmpty()){
            List<Drawdown__c> selectedDrawdowns = [select Id, Allocate_Payment__c from Drawdown__c where Id in :selectedDrawdownIds];
            for (Drawdown__c drawdown : selectedDrawdowns){
                if (drawdown.Allocate_Payment__c)
                    drawdown.Allocate_Payment__c = false;
            }
            update selectedDrawdowns;
        }
    }    
    
    public static void allocateAnotherPayments(Boolean isInsert, Map<Id, Drawdown__c> oldDrawdownsMap, List<Drawdown__c> newDrawdowns){
        List<Id> oppIds = new List<Id>();
        for (Drawdown__c newDrawdown : newDrawdowns){
            if (!processedAdvancesIds.contains(newDrawdown.Id) && newDrawdown.Payment_Method__c != 'Payment' && newDrawdown.Outstanding_Balance_as_of_Payout_Date__c > 0){
                oppIds.add(newDrawdown.Opportunity__c);
                //prevents recursive calls
                processedAdvancesIds.add(newDrawdown.Id);
            }
        }
        if (!oppIds.isEmpty()){           
            List<Id> unallocatedPaymentIds = new List<Id>();
            List<Opportunity> opps = [select Id, Payout_Date__c, Oldest_Unallocated_Payment__c, Oldest_Unallocated_Payment__r.Date__c from Opportunity where Id in :oppIds and Oldest_Unallocated_Payment__c != null];
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            Map<Id, Date> oppsDates = new Map<Id, Date>();
            Map<Id, Date> oppsOldDates = new Map<Id, Date>();
            oppIds.clear();
            for (Opportunity opp : opps){
                if (opp.Payout_Date__c != opp.Oldest_Unallocated_Payment__r.Date__c){ 
                    oppsOldDates.put(opp.Id, opp.Payout_Date__c);
                    opp.Payout_Date__c = opp.Oldest_Unallocated_Payment__r.Date__c;
                    oppsToUpdate.add(opp);                       
                    oppIds.add(opp.Id);
                }                
                oppsDates.put(opp.Id, opp.Payout_Date__c);
                unallocatedPaymentIds.add(opp.Oldest_Unallocated_Payment__c);                       
            }                    
            if (!oppsToUpdate.isEmpty())
                update oppsToUpdate;
            Boolean replicationFailed = false;
            if (!oppIds.isEmpty()){
                //Checks that Opportunity - Replicate Loan Setup Info to Drawdown process replicated Payout_Date__c from opp to drawdowns
                List<Drawdown__c> advances = [select Id, Payout_Date__c, Replicated_Payout_Date__c, Opportunity__c from Drawdown__c where Opportunity__c in :oppIds and Payment_Method__c != 'Payment'];            
                for (Drawdown__c advance : advances){                   
                    if (oppsDates.get(advance.Opportunity__c) != advance.Replicated_Payout_Date__c && oppsDates.get(advance.Opportunity__c) != advance.Payout_Date__c)
                        replicationFailed = true;
                }            
            }
            if (replicationFailed){
                for (Opportunity opp : oppsToUpdate){
                    opp.Payout_Date__c = oppsOldDates.get(opp.Id);
                }
                update oppsToUpdate;
            }
            else               
                PaymentAllocator.AllocatePayments(unallocatedPaymentIds);  
        }
    }    
}
