public class DrawdownTriggerHandler {
    
    public static void validatePaymentChange(Map<Id,Drawdown__c> oldMap, List<Drawdown__c> newDrawdowns){
        /*------------------------------------------------------------
Author: Basil Dobek
Company: Deloitte
Description: Validate that updates to payment dates do not change order of payments.  Changing order of payments is not supported. 
Also amount changes when later payments exist is not supported. 
And finally changing from or to a payment when later payments exist is not supported.
This class works in before update and before insert.
Inputs: Trigger.OldMap and Trigger.new context variables. 

History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/
        
        List <ID> OpportunityIds = new List <ID>();  // hold list of opportunities for which we have payments we need to validate date change on
        list <Drawdown__c> Payments = new List <Drawdown__c>();  // Will hold list of payments with potential issues
        
        for (Drawdown__c newDrawdown : newDrawdowns){
            Date OldDate = Date.newInstance(1900,01,01);
            Decimal OldAmount = 0;
            String OldPaymentMethod = '';
            if (trigger.isUpdate){
                OldDate = oldMap.get(newDrawdown.id).Date__c;
                OldAmount = oldMap.get(newDrawdown.id).Amount__c;
                OldPaymentMethod = oldMap.get(newDrawdown.id).Payment_Method__c;
            }
            
            if( (newDrawdown.Payment_Method__c =='Payment' && OldDate != newDrawdown.Date__c ) || 
               (newDrawdown.Payment_Method__c =='Payment' && newDrawdown.Amount__c != OldAmount) ||
               (newDrawdown.Payment_Method__c =='Payment' && OldPaymentMethod != 'Payment' ) ||
               (newDrawdown.Payment_Method__c !='Payment' && OldPaymentMethod == 'Payment' )) {
                   // save opportunity id in set
                   // save payment in map
                   OpportunityIds.Add(newDrawdown.Opportunity__c);
                   Payments.Add(newDrawdown);	
               }
        }
        if(!Payments.isEmpty() && !OpportunityIds.isEmpty()){
            // query for all payments under the opportunities where we have payments with changed dates
            List <Drawdown__c> allPayments = [Select id,date__c from Drawdown__c where Opportunity__c in : OpportunityIds and Payment_Method__c = 'Payment'];
            
            // Cycle throuh every payment in our map of payments which are a potential issue and verify id doesn't violate one of the other payments
            for (drawdown__c newPayment : Payments){
                for (drawdown__c otherPayment : allPayments){
                    if (Trigger.isUpdate){
                        if ((newPayment.id != otherPayment.id) && (newPayment.date__c < otherPayment.Date__c || oldMap.get(newPayment.id).date__c < otherPayment.Date__c )){
                            // throw an error as an invalid date change has occurred
                            newPayment.addError('Invalid change due to conflicting payment.  Payments dated after this record must be removed first.');
                        }
                    }
                    if (Trigger.isInsert){
                        // on insert, don't check the to date
                        if ((newPayment.id != otherPayment.id) && (newPayment.date__c < otherPayment.Date__c )){
                            // throw an error as an invalid date change has occurred
                            newPayment.addError('Invalid change due to conflicting payment.  Payments dated after this record must be removed first.');
                        }
                    }
                }
            }
        }
    }
    
    public static void validatePaymentDelete(List<Drawdown__c> Payments){
        /*------------------------------------------------------------
Author: Basil Dobek
Company: Deloitte
Description: Validate that payment deletions only occur on the last payment as changing order of payments via deletion is not supported. 
Also verify the loan is still open.   
Inputs: Trigger.OldMap context variable. 

History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/
        
        List <ID> OpportunityIds = new List <ID>();  // hold list of opportunities for which we have payments we need to validate deletion of
        
        for (Drawdown__c p : Payments){
            OpportunityIds.Add(p.Opportunity__c);
        }
        
        // query for all payments under the opportunities where we have payments with changed dates
        List <Drawdown__c> allPayments = [Select id,date__c,Opportunity__c,Opportunity__r.Stage_Status__c from Drawdown__c where Opportunity__c in : OpportunityIds and Payment_Method__c = 'Payment'];
        
        // Cycle throuh every payment in our map of payments which are a potential issue and verify id doesn't violate one of the other payments
        for (drawdown__c paymentToDelete : Payments){
            for (drawdown__c otherPayment : allPayments){
                if (paymentToDelete.Opportunity__c==otherPayment.Opportunity__c) {
                    if ((paymentToDelete.id != otherPayment.id)  && (paymentToDelete.date__c < otherPayment.Date__c )){
                        // throw an error as an invalid date change has occurred
                        paymentToDelete.addError('Invalid payment deletion due to later payments.  Payments dated after this record must be removed first.');
                    }  
                    if (paymentToDelete.Opportunity__r.Stage_Status__c == 'Paid Off'){
                        // throw an error as an Loan cannot be closed
                        paymentToDelete.addError('Cannot delete payments from close Loans.  Please re-open first.');                        
                    }
                }
            }
        }
    }
    
    public static void updateAdminFeeOnFirstDrawdown(List<Drawdown__c> newDrawdowns, Map<Id,Drawdown__c> oldMap, Boolean isInsert){
        /*------------------------------------------------------------
Author: Fahad Khan
Company: Toptal
Description: update first drawdown of opportunity to house both admin fee and its amount

History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/
        
        Set<Id> oppties = new Set<Id>();
        for(Drawdown__c d : newDrawdowns)
        {
            if(d.Opportunity__c != null &&
               (isInsert || (!isInsert && 
                             (/*(d.Reference_Notes__c == 'Admin Fee' ||
oldMap.get(d.Id).Reference_Notes__c == 'Admin Fee') && */
                                 (d.Per_Diem_as_of_Payout_Date__c != oldMap.get(d.Id).Per_Diem_as_of_Payout_Date__c ||
                                  d.Amount__c != oldMap.get(d.Id).Amount__c || 
                                  d.Reference_Notes__c != oldMap.get(d.Id).Reference_Notes__c || 
                                  d.Date__c != oldMap.get(d.Id).Date__c ||
                                  d.Accrued_Interest_as_of_Payout_Date__c != oldMap.get(d.Id).Accrued_Interest_as_of_Payout_Date__c ||
                                  d.Outstanding_Balance_as_of_Payout_Date__c != oldMap.get(d.Id).Outstanding_Balance_as_of_Payout_Date__c) )) ))
            {
                oppties.add( d.Opportunity__c);
            }
        }
        if(!oppties.isEmpty())
        {
            mergeAdminFees(oppties);
        }
    }
    public static void mergeAdminFees(Set<Id> opptyIds){
        system.debug('In mergeAdminFees Function');
        List<Opportunity> oppties = [Select id , Stage_Status__c,
                                     (Select Amount__c, Reference_Notes__c , Payment_Method__c,
                                      Accrued_Interest_as_of_Payout_Date__c, Admin_Accrued_Interest__c,
                                      Admin_Outstanding_Balance__c, Outstanding_Balance_as_of_Payout_Date__c,
                                      Admin_Per_Diem__c, Per_Diem_as_of_Payout_Date__c From Drawdowns__r
                                      Order by Date__c asc, Name asc)
                                     from Opportunity where id in :opptyIds];
        List<Drawdown__c> drawdownsToUpdate = new List<Drawdown__c>();
        for(Opportunity op : oppties)
        {
            if(!op.Drawdowns__r.isEmpty())
            {
				List<Drawdown__c> drawdownsRange = new List<Drawdown__c>();
                //Splitting drawdowns by Rejected Payments. Merge admin fee separately in each range
                for(Drawdown__c d : op.Drawdowns__r)
                {
                    if (d.Reference_Notes__c == 'Payment Rejected' || d.Reference_Notes__c == 'Payment Halted'){
                        if (!drawdownsRange.isEmpty()){
                            List<Drawdown__c> drawdownsToUpdateInRange = mergeAdminFeesWithDrawdown(drawdownsRange);
                            drawdownsToUpdate.addAll(drawdownsToUpdateInRange);
                            drawdownsRange.clear();
                        }
                    }
                    else{
                        drawdownsRange.add(d);
                    }
                }
                if (!drawdownsRange.isEmpty()){
                    List<Drawdown__c> drawdownsToUpdateInRange = mergeAdminFeesWithDrawdown(drawdownsRange);
                    drawdownsToUpdate.addAll(drawdownsToUpdateInRange);
                }
            }
        }
        if(!drawdownsToUpdate.isEmpty())
        {
            update drawdownsToUpdate;
        }
    }
    public static List<Drawdown__c> mergeAdminFeesWithDrawdown(List<Drawdown__c> drawdowns){
        List<Drawdown__c> drawdownsToUpdate = new List<Drawdown__c>();
        double adminFee = 0.0;
        double adminAccuredInterest = 0.0;
        double adminOutstandingBalance = 0.0;
        double adminPerDiem = 0.0;
        Drawdown__c firstDrawdown = null;
        for(Drawdown__c d : drawdowns)
        {
            if(d.Reference_Notes__c == 'Admin Fee' || d.Reference_Notes__c == 'Assessment Fee')
            {
                //system.debug('Reference Notes == Admin Fee ' + d.Id);
                adminFee += d.Amount__c;
                adminAccuredInterest += d.Accrued_Interest_as_of_Payout_Date__c;
                adminOutstandingBalance +=d.Outstanding_Balance_as_of_Payout_Date__c;
                adminPerDiem += d.Per_Diem_as_of_Payout_Date__c;
                //system.debug('sel drawdown Admin Fee ' + d.Amount__c);
                //ystem.debug('Total Admin Fee ' + adminFee);
                //system.debug('Total Admin Accrued Interest ' + adminAccuredInterest);
            }
            else if (d.Reference_Notes__c != 'Referral Fee' && firstDrawdown == null)
            {
                //system.debug('Reference Notes != Referral Fee and FDd == null ' + d.Id);
                firstDrawdown = d;
                //System.debug('firstDrawdown'+firstDrawdown);
                
            }else if (firstDrawdown != null){
                d.Admin_Fee__c = null;
                d.Admin_Accrued_Interest__c = null;
                d.Admin_Outstanding_Balance__c = null;
                d.Admin_Per_Diem__c = null;
                drawdownsToUpdate.add(d);
            }
        }
        //if(firstDrawdown != null && adminFee > 0)
        if(firstDrawdown != null)
        {
            system.debug('FDd != null admin fee ++ ' + firstDrawdown.Id);
            system.debug('Admin Fee to be assigned ' + adminFee);
            firstDrawdown.Admin_Fee__c = adminFee > 0 ? adminFee : null;
            firstDrawdown.Admin_Accrued_Interest__c = adminAccuredInterest > 0 ? adminAccuredInterest : null;
            firstDrawdown.Admin_Outstanding_Balance__c = adminOutstandingBalance > 0 ? adminOutstandingBalance : null;
            firstDrawdown.Admin_Per_Diem__c = adminPerDiem > 0 ? adminPerDiem : null;
            drawdownsToUpdate.add(firstDrawdown);
        }
        
        return drawdownsToUpdate;
    }

    public static void createAdminFeeRejections(List<Drawdown__c> newDrawdowns){
        List<Drawdown__c> rejections = new List<Drawdown__c>();
        for (Drawdown__c d : newDrawdowns){
            if (d.Payment_To_Reverse__c != null){
                rejections.add(d);
            }
        }
        if (!rejections.isEmpty()){            
            List<Id> drawdownsToReverseIds = new List<Id>();
            List<Id> oppIds = new List<Id>();
            for (Drawdown__c rejectionDrawdown : rejections){
                drawdownsToReverseIds.add(rejectionDrawdown.Payment_To_Reverse__c);
                oppIds.add(rejectionDrawdown.Opportunity__c);
            }
            List<Drawdown__c> drawdownsToReverse = [select Id, Date__c, Admin_Fee__c, Admin_Outstanding_Balance__c, Admin_Accrued_Interest__c from Drawdown__c where Id in :drawdownsToReverseIds];
            Map<Id, Drawdown__c> drawdownsToReverseMap = new Map<Id, Drawdown__c>();
            for (Drawdown__c d : drawdownsToReverse){
                drawdownsToReverseMap.put(d.Id, d);
            }
            List<Drawdown__c> adminFeeDrawdowns = [select Id, Opportunity__c, Date__c, CHQ__c, EFT__c, Opportunity_Service_Provider__c, Payment_Method__c, Amount__c,Outstanding_Balance_as_of_Payout_Date__c,Rejections_Count__c   from Drawdown__c where (Reference_Notes__c = 'Admin Fee' OR Reference_Notes__c = 'Assessment Fee') and Opportunity__c in :oppIds and (Rejections_Count__c=NULL OR Rejections_Count__c=0)];            
            Map<Id, List<Drawdown__c>> oppToAdminFeeDrawdownsMap = new Map<Id, List<Drawdown__c>>();
            for (Id oppId : oppIds){
                oppToAdminFeeDrawdownsMap.put(oppId, new List<Drawdown__c>());
            }
            for (Drawdown__c adminFeeDrawdown : adminFeeDrawdowns){
                System.debug('AF ' + adminFeeDrawdown.Id + ' ' + adminFeeDrawdown.Rejections_Count__c);
                oppToAdminFeeDrawdownsMap.get(adminFeeDrawdown.Opportunity__c).add(adminFeeDrawdown);
			}
            List<Drawdown__c> adminFeeRejectionDrawdowns = new List<Drawdown__c>();
            for (Drawdown__c rejectionDrawdown : rejections){
                Drawdown__c drawdownToReverse = drawdownsToReverseMap.get(rejectionDrawdown.Payment_To_Reverse__c);                
                if (drawdownToReverse.Admin_Fee__c != null){
                    List<Drawdown__c> adminFees = oppToAdminFeeDrawdownsMap.get(rejectionDrawdown.Opportunity__c);                    
                    for (Drawdown__c adminFeeDrawdown : adminFees){
                        if (adminFeeDrawdown.Date__c > rejectionDrawdown.Date__c)
                            continue;
                        Drawdown__c adminFeeRejectionDrawdown = new Drawdown__c();                        
                        adminFeeRejectionDrawdown.Opportunity__c = rejectionDrawdown.Opportunity__c;        
                        adminFeeRejectionDrawdown.CHQ__c = adminFeeDrawdown.CHQ__c;        
                        adminFeeRejectionDrawdown.EFT__c = adminFeeDrawdown.EFT__c;        
                        adminFeeRejectionDrawdown.Payment_Method__c = 'Payment';  
                        adminFeeRejectionDrawdown.Reference_Notes__c = rejectionDrawdown.Reference_Notes__c;
                        adminFeeRejectionDrawdown.Reason_to_Reverse_Payment__c = rejectionDrawdown.Reason_to_Reverse_Payment__c;
                        if (rejectionDrawdown.Reason_to_Reverse_Payment__c == 'Client Error'){
                            adminFeeRejectionDrawdown.Amount__c = adminFeeDrawdown.Amount__c;
                        }                   
                        else
                            adminFeeRejectionDrawdown.Amount__c = adminFeeDrawdown.Outstanding_Balance_as_of_Payout_Date__c;
                        adminFeeRejectionDrawdown.Principal_Reversed__c = adminFeeDrawdown.Amount__c;
                        adminFeeRejectionDrawdown.Date__c = rejectionDrawdown.Date__c;
                        adminFeeRejectionDrawdown.Rejection_Notes__c = rejectionDrawdown.Rejection_Notes__c;
                        adminFeeRejectionDrawdown.Payment_To_Reverse__c = adminFeeDrawdown.Id;
                        adminFeeRejectionDrawdown.Opportunity_Service_Provider__c = adminFeeDrawdown.Opportunity_Service_Provider__c;
                        adminFeeRejectionDrawdowns.add(adminFeeRejectionDrawdown);
                    }
                }
            }
            if (!adminFeeRejectionDrawdowns.isEmpty())
            	insert adminFeeRejectionDrawdowns;
        }
	}
    
    /*
    public static void reCalculateCriticalDatePayout(List<Drawdown__c> newDrawdowns, Map<Id,Drawdown__c> oldMap, Boolean isInsert){
        
        Set<Id> drawdownIds = new Set<Id>();
        for(Drawdown__c dd :newDrawdowns){        
            if((dd.Payment_Method__c != 'Payment' && dd.Interest_Rate__c > 0 && (dd.Compounding_Interest__c == false || dd.Compounding_Frequency__c > 0) ) && 
               ((isInsert && dd.Amount__c > 0) || (!isInsert && (dd.Payment_Method__c != oldMap.get(dd.Id).Payment_Method__c || 
                                                                 dd.Interest_Rate__c != oldMap.get(dd.Id).Interest_Rate__c ||
                                                                 dd.Compounding_Interest__c != oldMap.get(dd.Id).Compounding_Interest__c || 
                                                                 dd.Compounding_Frequency__c != oldMap.get(dd.Id).Compounding_Frequency__c ||
                                                                 dd.Amount__c != oldMap.get(dd.Id).Amount__c || 
                                                                 dd.Date__c != oldMap.get(dd.Id).Date__c)))){
                                                                     drawdownIds.add(dd.Id);
                                                                 }
        }
        Set<Id> accountIds = new Set<Id>();
        if(!drawdownIds.isEmpty()){
            List<Drawdown__c> ddList;
            if(Trigger.isDelete){
                ddList = [SELECT Opportunity__r.AccountId FROM Drawdown__c Where id in: drawdownIds AND IsDeleted = true ALL ROWS];
            }else{
                ddList = [SELECT Opportunity__r.AccountId FROM Drawdown__c Where id in: drawdownIds];
            }
            for(Drawdown__c dd : ddList){
                accountIds.add(dd.Opportunity__r.AccountId);
            }
        }
        
        if(!accountIds.isEmpty()){
            // Adding all critical date fields to the query
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Critical_Date__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }       
            
            // Building the query
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ' FROM Critical_Date__c WHERE Account__c in: accountIds';  
            
            List<Critical_Date__c> criticalDatesList = Database.query(strQuery); 
            if(criticalDatesList.size() > 0){
                criticalDateTriggerHandler.calculatePayout(criticalDatesList, null, true, true);
            }
        }  
    }
    */
}
