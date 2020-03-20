public with sharing class SumOfRepaymentsController {
    public List<RepaymentInfo> incorrectRepayments{get; set;}
    public SumOfRepaymentsController(){
        incorrectRepayments = getIncorrectSumOfRepayments();
    }
    public List<RepaymentInfo> getIncorrectSumOfRepayments(){
        List<RepaymentInfo> result = new List<RepaymentInfo>();
        List<Drawdown__c> drds = [select Id,Name,Opportunity__r.AccountId, Opportunity__r.Account.Business_Unit__c, Opportunity__r.Id, Opportunity__r.Name, Opportunity__r.Loan_Requests__c, Sum_Of_Repayments__c, (select Id, Amount__c from Payments_Allocated_to_this_Drawdown__r) from Drawdown__c where Payment_Method__c <> 'Payment' and Sum_Of_Repayments__c > 0.0];
        Integer count = 0;
        for (Drawdown__c d : drds){
            Double sm = 0.0;    
            if (d.Payments_Allocated_to_this_Drawdown__r.size() > 0){
                for (Drawdown_Payment_Allocation__c al : d.Payments_Allocated_to_this_Drawdown__r ){
                    sm += al.Amount__c;
                }
                if (sm != d.Sum_Of_Repayments__c){
                    count += 1;
                    System.debug('Incorrect ' + d.Id + ',' + d.Name + ', ' + d.Opportunity__r.AccountId + ',' + d.Opportunity__r.Name + ',' + d.Opportunity__r.Loan_Requests__c+ ',' + d.Sum_Of_Repayments__c);
                    //if (result.size() < 1000)
                    	result.add(new RepaymentInfo(d.Id, d.Name, d.Opportunity__r.AccountId, d.Opportunity__r.Id, d.Opportunity__r.Name, d.Opportunity__r.Loan_Requests__c, d.Sum_Of_Repayments__c, sm, d.Opportunity__r.Account.Business_Unit__c ));
                }
            }    
            else{
                count += 1;                
                System.debug(d.Id + ',' + d.Name + ', ' + d.Opportunity__r.AccountId + ',' + d.Opportunity__r.Name + ',' + d.Opportunity__r.Loan_Requests__c+ ',' + d.Sum_Of_Repayments__c);
                //if (result.size() < 1000)
                	result.add(new RepaymentInfo(d.Id, d.Name, d.Opportunity__r.AccountId, d.Opportunity__r.Id, d.Opportunity__r.Name, d.Opportunity__r.Loan_Requests__c, d.Sum_Of_Repayments__c, sm, d.Opportunity__r.Account.Business_Unit__c ));
            }
        }
        
        System.debug('Count ' + count);
        
        return result;
    }
    
    public class RepaymentInfo{
        public String id{ get; set; }
        public String drawdownName{ get; set; }
        public String accountId{ get; set; }
        public String oppName{ get; set; }
        public String oppId{ get; set; }
        public String loanRequests{ get; set; }
        public String businessUnit{ get; set; }
        public Decimal sumOfRepayments{ get; set; }
        public Decimal correctSumOfRepayments{ get; set; }
        
        public RepaymentInfo(String id, String drawdownName, String accountId, String oppId, String oppName, String loanRequests, Decimal sumOfRepayments, Decimal correctSumOfRepayments, String businessUnit ){
            this.id = id;
            this.drawdownName = drawdownName;
            this.accountId = accountId;
            this.oppId = oppId;
            this.oppName = oppName;
            this.loanRequests = loanRequests;
            this.sumOfRepayments = sumOfRepayments;
            this.correctSumOfRepayments = correctSumOfRepayments;
            this.businessUnit = businessUnit;
        }
    }
}