public with sharing class PaymentAllocator {

/*------------------------------------------------------------
Author: Basil Dobek
Company: Deloitte
Description: A utility class to allocate a payment type Drawdown to an Advance type Drawdown.
             This clase creates "Drawdown Payment Allocation" objects to accomplish this.
			 Class is invokable so it can be called from Process Builder.
			 
			 NOTE: This class assumes that the Payout Date on all Drawdowns will match
			 the Payment Transaction Date.  This is critical as this controls the amount of interest shown 
			 on each Drawdown and would impact the amount which should be allocated if it were inconsistent.
			 An exception is thrown if this assumption proves invalid. 

Inputs: 
	- List of Payment Ids
History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/

	// Define custom exception
	public class PayoutDateInconsistentException extends Exception {} // Throws this if Payout date on Drawdown not consistent with Transaction Date on Payment. 
    public class PaymentToReverseIsNotSetException extends Exception {}     

	@InvocableMethod(label='Allocate Payments' description='Create Drawdown Payment Allocation records to associate Payment Drawdown with Advance Drawdown')
	public static void AllocatePayments (List<ID> paymentIds) {
		// Get the Payments
		list<Drawdown__c> pmts = [select name, Outstanding_Balance_as_of_Payout_Date__c,Date__c,Reference_Notes__c, Id,Opportunity__c,Opportunity__r.Payout_Date__c 
									  from Drawdown__c where id in :paymentIds];
        list<Drawdown__c> payments = new list<Drawdown__c>();
        for (Drawdown__c p : pmts){
            if (p.Reference_Notes__c != 'Payment Rejected' && p.Reference_Notes__c != 'Payment Halted')
                payments.add(p);
		}

		// Get all Opportunities
		list<ID> opportunityIds = new List<ID>();
		for (Drawdown__c p:payments){
			opportunityIds.add(p.Opportunity__c);
		}

		// Get all drawdowns which are not payments but are under the same Opportunity - calling them customer "advances"
		list<Drawdown__c> advances = [select Name,date__c,Outstanding_Balance_as_of_Payout_Date__c,Id, Opportunity__c, Payout_Date__c, Temp_Payout_Date__c, 
									  Interest_End_Date__c, Accrued_Interest_as_of_Payout_Date__c,Amount__c, Interest_repaid__c, Principal_repaid__c
									  from Drawdown__c
									  where Opportunity__c in :opportunityIds AND Outstanding_Balance_as_of_Payout_Date__c > 0 and Payment_Method__c <> 'Payment' order by Opportunity__c,Date__c ASC];


		list<Drawdown_Payment_Allocation__c> allocations = new list<Drawdown_Payment_Allocation__c> ();  // list of allocations to be inserted

		// saving the balance of each advance so I can decrement as I allocate it
		map<id,Decimal> advanceBalance = new map<id,Decimal>();  
		for (drawdown__c a : advances){
			advanceBalance.put(a.id,a.Outstanding_Balance_as_of_Payout_Date__c);
		}

		// go through each payment and allocate it - there is unlikely to be more than 1 but trying to bulkify ...
		Decimal SumPrincipalRepaymentsAux = 0;
		for (Drawdown__c p:payments){            
			Decimal paymentBalance = 0.00 - p.Outstanding_Balance_as_of_Payout_Date__c;  //change sign            
                 
			for (drawdown__c a : advances){
                
                Drawdown__c singleAdvance = [select Name,date__c,Outstanding_Balance_as_of_Payout_Date__c,Id, Opportunity__c, Payout_Date__c, Temp_Payout_Date__c, 
									  				Interest_End_Date__c, Accrued_Interest_as_of_Payout_Date__c,Amount__c, Interest_repaid__c, Principal_repaid__c, 
                                             		Opportunity__r.Interest_Accrued_as_of_Payout_Date__c, Opportunity__r.Drawdown_Total_wo_Payment__c, 
                                             		Opportunity__r.Sum_of_Principal_Repayments__c, Opportunity__r.Interest_Reversed__c
									  		from Drawdown__c
									  		where Id = : a.Id ];
                
				if (a.Payout_Date__c <> p.date__c && a.opportunity__c == p.opportunity__c){
					throw new PayoutDateInconsistentException('Drawdown ' + a.name + ', with a Payout Date of:' + a.Payout_Date__c + ' is not consistent with Payment date on ' + p.name+ ' of '+ p.date__c +'. Payments cannot be allocated.');
				}
				
				if (a.opportunity__c == p.opportunity__c && paymentBalance > 0 && advanceBalance.get(a.id)> 0  ){
                	
					Decimal AllocationAmount = 0.00;                    
					if (advanceBalance.get(a.id)>= paymentBalance){
						AllocationAmount += paymentBalance;
						advanceBalance.put(a.id,advanceBalance.get(a.id)-paymentBalance);
						paymentBalance = 0;
						
					} else {
						AllocationAmount += advanceBalance.get(a.id);
						paymentBalance -= advanceBalance.get(a.id);
						advanceBalance.put(a.id,0);
						
					}
					Drawdown_Payment_Allocation__c newAllocation = 
					    new Drawdown_Payment_Allocation__c (Amount__c=AllocationAmount, drawdown__c=a.id,payment__c=p.id, 
															payout_date__c=a.payout_date__c, temp_payout_date__c=singleAdvance.temp_payout_date__c, 
															Transaction_Date__c=p.date__c, opportunity__c=p.opportunity__c,
															Interest_Accrued_to_Transaction_Date__c = singleAdvance.Accrued_Interest_as_of_Payout_Date__c,
															Interest_End_Date__c = singleAdvance.Interest_End_Date__c);
                    
                    if(SumPrincipalRepaymentsAux == 0 && singleAdvance.Opportunity__r.Sum_of_Principal_Repayments__c != null){
                    	SumPrincipalRepaymentsAux = singleAdvance.Opportunity__r.Sum_of_Principal_Repayments__c;
                        if (singleAdvance.Opportunity__r.Interest_Reversed__c != null)
                            SumPrincipalRepaymentsAux -= singleAdvance.Opportunity__r.Interest_Reversed__c;
                    } else if (SumPrincipalRepaymentsAux == 0 && singleAdvance.Opportunity__r.Sum_of_Principal_Repayments__c == null){
                        SumPrincipalRepaymentsAux = 0;
                    }
                    
                    system.debug(' SumPrincipalRepaymentsAux >> '+ SumPrincipalRepaymentsAux);
                    system.debug(' AllocationAmount >> ' + AllocationAmount );
                    system.debug(' singleAdvance.Opportunity__r.Sum_of_Principal_Repayments__c >> ' + singleAdvance.Principal_repaid__c);
                    system.debug(' singleAdvance.Opportunity__r.Drawdown_Total_wo_Payment__c >> ' + singleAdvance.Opportunity__r.Drawdown_Total_wo_Payment__c);
                    
                    // calculate principal repaid                    
                    If (SumPrincipalRepaymentsAux >= singleAdvance.Opportunity__r.Drawdown_Total_wo_Payment__c){
                        //set to zero as principal is already fully paid
                        newAllocation.Principal_repaid__c = 0.00;
                    } else{
                        If((AllocationAmount + SumPrincipalRepaymentsAux)<= singleAdvance.Opportunity__r.Drawdown_Total_wo_Payment__c){
                            //set to full repayment as principal outstanding is less than repayment
                            newAllocation.Principal_repaid__c = AllocationAmount;
                            SumPrincipalRepaymentsAux = SumPrincipalRepaymentsAux + newAllocation.Principal_repaid__c;
                        } else {
                            //set to the difference between the principal outstanding and the amount paid so far
                            newAllocation.Principal_repaid__c = singleAdvance.Opportunity__r.Drawdown_Total_wo_Payment__c - SumPrincipalRepaymentsAux;
                            SumPrincipalRepaymentsAux = SumPrincipalRepaymentsAux + newAllocation.Principal_repaid__c;
                        }
                    }
                    
                    system.debug(' newAllocation.Principal_repaid__c >> ' + newAllocation.Principal_repaid__c);
                    
                    // calculate interest repaid                    
                    If (newAllocation.Principal_repaid__c >= AllocationAmount){
                        // all of the repayment went to principal to set interest repaid to zero
                        newAllocation.Interest_repaid__c = 0.00;
                    } else {
                        // Interest repaid is set to the leftover amount after the principal is repaid
                        newAllocation.Interest_repaid__c = AllocationAmount - newAllocation.Principal_repaid__c;
                    }
                    
                    system.debug(' newAllocation.Interest_repaid__c >> ' + newAllocation.Interest_repaid__c );
                    
                    //insert newAllocation;
                    allocations.add(newAllocation);					
				}
			}

		}
		insert allocations;
		//system.debug('xxxxxxxxxxxxxxxxxx Payments Allocations created=>'+allocations.size());
		//system.debug('xxxxxxxxxxxxxxxxxx END Allocate Payments xxxxxxxxxxxxxxxxxx');
		return;
	}     
    
    public static void allocateRejectionDrawdowns(List<Id> rejectionDrawdownIds){
        List<Drawdown__c> rejectionDrawdowns = [select name, Payment_To_Reverse__c, Amount__c, Principal_Reversed__c, Outstanding_Balance_as_of_Payout_Date__c, Date__c,Id, Opportunity__c,Opportunity__r.Payout_Date__c 
									  from Drawdown__c where id in :rejectionDrawdownIds];
        List<Id> drawdownToReverseIds = new List<Id>();
        for (Drawdown__c rejectionDrawdown : rejectionDrawdowns){
			drawdownToReverseIds.add(rejectionDrawdown.Payment_To_Reverse__c);            
        }
        List<Drawdown__c> drawdownsToReverse = [select Id, Name, Payout_Date__c, temp_payout_date__c, Opportunity__c, Outstanding_Balance_as_of_Payout_Date__c,
                                                Accrued_Interest_as_of_Payout_Date__c, Interest_End_Date__c
                                                from Drawdown__c where Id in :drawdownToReverseIds];
        List<Drawdown_Payment_Allocation__c> allocations = new List<Drawdown_Payment_Allocation__c>();
        for (Drawdown__c rejectionDrawdown : rejectionDrawdowns){
            Decimal paymentBalance = 0.00 - rejectionDrawdown.Outstanding_Balance_as_of_Payout_Date__c;  
            if (paymentBalance > 0){
                Drawdown__c drawdownToReverse = null;            
                for (Drawdown__c d : drawdownsToReverse){
                    if (rejectionDrawdown.Payment_To_Reverse__c == d.Id)
                        drawdownToReverse = d;
                }
                if (drawdownToReverse == null){
                    throw new PaymentToReverseIsNotSetException('Payment to reverse is not set');
                }
                if (drawdownToReverse.Payout_Date__c <> rejectionDrawdown.date__c && drawdownToReverse.opportunity__c == rejectionDrawdown.opportunity__c){
                    throw new PayoutDateInconsistentException('Drawdown ' + drawdownToReverse.name + ', with a Payout Date of:' + drawdownToReverse.Payout_Date__c + ' is not consistent with Payment date on ' + rejectionDrawdown.name+ ' of '+ rejectionDrawdown.date__c +'. Payments cannot be allocated.');
                }
                Drawdown_Payment_Allocation__c newAllocation = 
                            new Drawdown_Payment_Allocation__c (Amount__c=rejectionDrawdown.Amount__c, drawdown__c=drawdownToReverse.id,payment__c=rejectionDrawdown.id, 
                                                                payout_date__c=drawdownToReverse.payout_date__c, temp_payout_date__c=drawdownToReverse.temp_payout_date__c, 
                                                                Transaction_Date__c=rejectionDrawdown.date__c, opportunity__c=rejectionDrawdown.opportunity__c,
                                                                Interest_Accrued_to_Transaction_Date__c = drawdownToReverse.Accrued_Interest_as_of_Payout_Date__c,
                                                                Interest_End_Date__c = drawdownToReverse.Interest_End_Date__c);
                //System.debug('allocateRejectionDrawdowns ' + newAllocation.Amount__c  + ' ' + drawdownToReverse.Outstanding_Balance_as_of_Payout_Date__c + ' ' + rejectionDrawdown.Principal_Reversed__c);
                if (newAllocation.Amount__c < drawdownToReverse.Outstanding_Balance_as_of_Payout_Date__c ){
                    newAllocation.Principal_Repaid__c = newAllocation.Amount__c;
                    newAllocation.Interest_Repaid__c = 0.0;                    
                }
                else{
                    newAllocation.Principal_Repaid__c = rejectionDrawdown.Principal_Reversed__c;
					newAllocation.Interest_Repaid__c = drawdownToReverse.Outstanding_Balance_as_of_Payout_Date__c - rejectionDrawdown.Principal_Reversed__c;                    
                }
                allocations.add(newAllocation);
            }
        }
        insert allocations;
    }
}
