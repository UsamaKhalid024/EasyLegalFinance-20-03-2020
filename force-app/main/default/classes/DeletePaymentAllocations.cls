public with sharing class DeletePaymentAllocations {
/*------------------------------------------------------------
Author: Basil Dobek
Company: Deloitte
Description: A utility class to allocate a payment type Drawdown to an Advance type Drawdown.
             This clase creates "Drawdown Payment Allocation" objects to accomplish this.
			 Class is invokable so it can be called from Process Builder.
Inputs: 
	- 
History
<Date> <Authors Name> <Brief Description of Change>
------------------------------------------------------------*/

	@InvocableMethod(label='Delete Payment Allocations From Payment' description='Given a Drawdown of type Payment, Delete all of the Payment Allocations.  Used if amounts, dates, or types are changing')
	public static void DeletePaymentAllocationsFromPayment (List<Id> paymentIds) {

		//system.debug('xxxxxxxxxxxxxxxxxx Start Delete Payment Allocations From Payment xxxxxxxxxxxxxxxxxx');		
		//system.debug('xxxxxxxxxxxxxxxxxx Payment ID => '+paymentIds);

        List<Drawdown_Payment_Allocation__c> Payment_Allocations =[select id from Drawdown_Payment_Allocation__c
                          where payment__c in :paymentIds];
        delete Payment_Allocations;	
		//system.debug('xxxxxxxxxxxxxxxxxx Payment Allocations Deleted => '+Payment_Allocations.size());
		//system.debug('xxxxxxxxxxxxxxxxxx END Delete Payment Allocations From Payment xxxxxxxxxxxxxxxxxx');
		return;
	}
}