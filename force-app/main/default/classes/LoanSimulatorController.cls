/**
*    @description : Apex class to calculate the interest and balance for the loan simualtor
**/
public with sharing class LoanSimulatorController {
	
	/**
	* @description Method to calculate the interest and balance for the loan simulator
	* @param opportunity Loan inforamtion
	* @param drawdownsList List of drawdowns 
	* @return List<Payment__c> List of payments to create
	**/
	@AuraEnabled
	public static Map<String, Object> calculateLoanInterestAndBalance(Opportunity opportunity, List<Drawdown__c> drawdownsList){
		Map<String, Object> objectMap = new Map<String, Object>();
		Decimal principal = 0.00;
		Savepoint savePointInstance = Database.setSavePoint();

		try{

			// calculate Amount 
			for(Drawdown__c drawdown : drawdownsList){
				principal += drawdown.Amount__c;
			}	

			// Create account 
			Account clientAccount = createAccount(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Client').getRecordTypeId(),'Test Company');
			Account lawFirmAccount = createAccount(Schema.SObjectType.Account.getRecordTypeInfosByName().get('Law Firm').getRecordTypeId(),'Test Company Lawyer');

			// Create Opporutunity
			opportunity.Name = 'Test Opportunity';
			opportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Client Opportunity Record Type').getRecordTypeId();
			opportunity.StageName = 'Loan Approved';
			opportunity.CloseDate = Date.today().addDays(14);
			opportunity.AccountId = clientAccount.Id;
			opportunity.Amount = principal;
			//opportunity.Law_Firm__c = lawFirmAccount.Id;  
			opportunity.Type_of_Loan__c = 'Facility Loan';
			insert opportunity; 

			// create drawdowns 
			for(Drawdown__c drawdown : drawdownsList){
				drawdown.Opportunity__c = opportunity.Id;
				drawdown.Payout_Date__c = opportunity.Payout_Date__c;
			}	
			insert drawdownsList;

			drawdownsList = [SELECT Id, Amount__c, Interest_Rate__c, Date__c, Accrued_Interest_as_of_Payout_Date__c, Per_Diem_as_of_Payout_Date__c, Total_Per_Diem__c, Outstanding_Balance_as_of_Payout_Date__c FROM Drawdown__c WHERE Id IN: drawdownsList];

			// fetch account 
			List<Account> accountList = [SELECT Id, All_Payout_Balance__c FROM Account WHERE Id =: clientAccount.Id LIMIT 1];
			return new Map<String, Object>{	'principal' => principal,
											'interest' => accountList[0].All_Payout_Balance__c - principal,
											'balance'	=> accountList[0].All_Payout_Balance__c,
											'drawdowns' => drawdownsList
										};
		}catch(Exception ex){

		}finally{
			Database.rollback(savePointInstance);
		}

		return null;
	}

	/**
	* @description Method to create dummy account
	* @return List<Payment__c> List of payments to create
	**/
	private static Account createAccount(Id recordTypeId,String accountName){
		Account account  =  new Account(Name = accountName, Authorization_Clause__c = 'No', RecordTypeId = recordTypeId,Phone='123456789');
		insert account;
		return account;
	}
}