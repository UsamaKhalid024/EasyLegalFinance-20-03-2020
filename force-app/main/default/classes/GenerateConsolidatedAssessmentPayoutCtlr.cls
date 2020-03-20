public with sharing class GenerateConsolidatedAssessmentPayoutCtlr {
    
    public String businessUnit{get; set;}
    private String lawyerId{get;set;} 
    public Date payoutDate{get;set;}
    public Date today{get;set;}
    public Contact lawyer{get;set;}
    List<PayoutWrapper> clientPayouts;
    
    public GenerateConsolidatedAssessmentPayoutCtlr(){
        string businessUnitParam = Apexpages.currentPage().getParameters().get('businessUnit');
        lawyerId = Apexpages.currentPage().getParameters().get('lawyerId');        
        this.businessUnit = businessUnitParam != null && !String.isEmpty(businessUnitParam)? businessUnitParam : 'ELFI';
        
        //lawyer and lawfirm info
        lawyer = [SELECT Id, Name, Account.Id, Account.Name 
                  FROM Contact 
                  WHERE Id =:lawyerId];
        
        Assessment_Summary_Report__c customSettings = Assessment_Summary_Report__c.getInstance(UserInfo.getUserId());        
        payoutDate = customSettings.Payout_Date__c;
        today = Date.today();
    }
    
    public List<PayoutWrapper> getPayOutData(){
        
        clientPayouts = new List<PayoutWrapper>();
        
        //get clients
        Map<Id, Account> clientAccounts = new Map<Id, Account>(
            [SELECT Id, Name, Name_Formula__c, BillingStreet, 
             BillingCity, BillingState, BillingPostalCode,
             Total_Outstanding__c, Total_Rebate_Discount__c
             FROM Account
             WHERE Selected_for_Assessment_Payout__c = true 
             AND Id In (SELECT AccountId FROM Opportunity WHERE Lawyer__c =:lawyerId 
                        AND isClosed = true AND isWon = true 
                        AND Stage_Status__c != 'Paid Off' 
                        AND Account.Business_Unit__c = 'ELFI' 
                        AND Type_of_Loan__c = 'Assessment')]
        );
        
        Map<Id, List<Drawdown__c>> accountToDrawdownMap = new Map<Id, List<Drawdown__c>>();
        for(Drawdown__c drawdown : [SELECT Id, date__c, Conga_Formula_Amount__c,
                                    Opportunity__r.Interest_Rate_Formula__c,
                                    Conga_Formula_Interest__c, Conga_Formula_Outstanding__c, 
                                    Conga_Formula_Per_Diem__c, Opportunity__r.Loan_Requests__c,
                                    Opportunity__r.AccountId
                                    FROM Drawdown__c
                                    WHERE reference_notes__c != 'Referral Fee'
                                    AND reference_notes__c != 'Admin Fee'
                                    AND reference_notes__c != 'Assessment Fee'
                                    AND Opportunity__r.AccountId IN :clientAccounts.keySet()
                                    ORDER BY Opportunity__r.Loan_Requests__c asc, Date__c asc]){
                                        if(!accountToDrawdownMap.containsKey(drawdown.Opportunity__r.AccountId))
                                            accountToDrawdownMap.put(drawdown.Opportunity__r.AccountId, new List<Drawdown__c>());
                                        accountToDrawdownMap.get(drawdown.Opportunity__r.AccountId).add(drawdown);
                                    }
        
        for(Id accId : clientAccounts.keySet()){
            
            if(accountToDrawdownMap.containsKey(accId)){
                
                Decimal tPrincipal = 0.0, 
                    tAccruedInterest = 0.0,
                    tOutstanding = 0.0, 
                    tPerDiem = 0.0;
                
                for(Drawdown__c drawdown :accountToDrawdownMap.get(accId)){
                    tPrincipal += drawdown.Conga_Formula_Amount__c;
                    tAccruedInterest += drawdown.Conga_Formula_Interest__c;
                    tOutstanding += drawdown.Conga_Formula_Outstanding__c;
                    tPerDiem += drawdown.Conga_Formula_Per_Diem__c;
                }
                
                clientPayouts.add(new PayoutWrapper(
                    clientAccounts.get(accId),
                    payoutDate,
                    accountToDrawdownMap.get(accId),
                    tPrincipal,
                    tAccruedInterest,
                    tOutstanding,
                    tPerDiem
                ));
            }
        }
        
        return clientPayouts;
        
    }
    
    public Integer getClientPayoutsSize(){
        return this.clientPayouts.size();
    }
    
    public class PayoutWrapper{
        
        public Account account{get;set;}
        public Date payoutDate{get;set;}
        public List<Drawdown__c> drawdowns{get;set;}
        public Decimal totalPrincipalBorrowed{get;set;}
        public Decimal totalAccruedInterest{get;set;}
        public Decimal totalOutstandingBalance{get;set;}
        public Decimal totalPerDiem{get;set;}
        
        PayoutWrapper(Account acc, Date pDate, List<Drawdown__c> dd, Decimal tPrincipal, Decimal tAccruedInterest, Decimal tOutstanding, Decimal tPerDiem){
            account = acc;
            payoutDate = pDate;
            drawdowns = dd;
            totalPrincipalBorrowed = tPrincipal;
            totalAccruedInterest = tAccruedInterest;
            totalOutstandingBalance = tOutstanding;
            totalPerDiem = tPerDiem;
        }
    }
}