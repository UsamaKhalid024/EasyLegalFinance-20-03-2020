/**
*    @description : Apex class to create payout statement
**/
public with sharing class PayoutStatementController {

	public Map<String, String> contactMap {get; private set;}
	public String lawFirm {get; private set;}
	public String lawyer {get; private set;}
	public Map<String, String> opportunityMap {get; private set;}
	public Date payoutDate {get; private set;}
	public List<Drawdown__c> drawdownsList {get; private set;}
	public Drawdown__c principalDrawdown {get; private set;}
	public Drawdown__c accruedInterestDrawdown {get; private set;}
	public Drawdown__c outstandingBalanceDrawdown {get; private set;}
	public Drawdown__c totalDiemDrawdown {get; private set;}
	public String businessUnit {get; private set;}

	/**
	* @description Constructor
	**/
	public PayoutStatementController() {
		this.contactMap = (Map<String, String>)JSON.deserialize(ApexPages.currentPage().getParameters().get('contact'),Map<String,String>.class);
		this.lawFirm =  ApexPages.currentPage().getParameters().get('lawFirm');
		this.lawyer =  ApexPages.currentPage().getParameters().get('lawyer');
		this.businessUnit = ApexPages.currentPage().getParameters().get('businessunit');
		this.opportunityMap = (Map<String, String>)JSON.deserialize(ApexPages.currentPage().getParameters().get('opportunity'),Map<String,String>.class);
		this.payoutDate = Date.valueOf(this.opportunityMap.get('Payout_Date__c'));
		this.drawdownsList = (List<Drawdown__c>)JSON.deserialize(ApexPages.currentPage().getParameters().get('drawdowns'),List<Drawdown__c>.class);
		this.principalDrawdown = new Drawdown__c(Amount__c=Decimal.valueOf(ApexPages.currentPage().getParameters().get('principal')));
		this.accruedInterestDrawdown = new Drawdown__c(Amount__c=Decimal.valueOf(ApexPages.currentPage().getParameters().get('interest')));
		this.outstandingBalanceDrawdown = new Drawdown__c(Amount__c=Decimal.valueOf(ApexPages.currentPage().getParameters().get('balance')));
		this.totalDiemDrawdown = new Drawdown__c(Amount__c=0.00);

		// loop through all the drawdowns and add Per_Diem_as_of_Payout_Date__c 
		for(Drawdown__c drawdown : this.drawdownsList){
			if(drawdown.Per_Diem_as_of_Payout_Date__c != null) this.totalDiemDrawdown.Amount__c += drawdown.Per_Diem_as_of_Payout_Date__c;
		}
	}
}