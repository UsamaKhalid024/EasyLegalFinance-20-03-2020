public with sharing class LawyerSalesSummaryPayoutReportCtlr {
    
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String businessUnit{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}
    
    public LawyerSalesSummaryPayoutReportCtlr(){
        contentType = '';
        renderAs = '';
        Date dt = Date.today();
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        if(paramContentType == 'PDF'){
            renderAs = 'PDF';
        }else{
            contentType = 'application/x-excel#LawyerSalesSummaryPayoutViewAll.xls';
        }
        
        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? Date.valueOf(paramStartDate) : dt.addDays(-30);
        this.endDate = !String.isEmpty(paramEndDate)? Date.valueOf(paramEndDate) : dt;
    }
    
    public List<Wrapper> getPayoutDrawdowns(){
        
        List<Drawdown__c> drawdowns = new List<Drawdown__c>();
        List<Wrapper> result = new List<Wrapper>();
        
        string eTransfer = 'e-Transfer';
        String payment = 'Payment';
        String loanPayout = 'Loan Payout';
        String partialPayment = 'Partial Payment';
        String paymentShortfall = 'Payment Shortfall';
        String paymentSurplus = 'Payment Surplus';
        string Cheque = 'Cheque';
        string AdminFee = 'Admin Fee';
        String ClosedWithLoan = 'Closed With Loan';
        String closedPaid = 'Closed - Paid';
        String closedShortfall = 'Closed - Shortfall';
        String closedSurplus = 'Closed - Surplus';
        
        String strQuery = 'SELECT Opportunity__r.Lawyer__c';
        strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate'; 
        strQuery += ' AND Date__c <= :endDate'; 
        strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
        strQuery += ' OR (Payment_Method__c =:Cheque)';
        strQuery += ' OR (Payment_Method__c =:AdminFee))';
        strQuery += ' AND Is_Rejected__c = false';
        strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        strQuery += ' AND Opportunity__r.Lawyer__c != \'\''; 
        
        drawdowns = Database.query(strQuery);
        
        Set<Id> lawyerIds = new Set<Id>();
        
        for(Drawdown__c drawdown: drawdowns){
            lawyerIds.add(drawdown.Opportunity__r.Lawyer__c);
        }
        
        if(!lawyerIds.isEmpty()){
            strQuery = 'SELECT id, Name, Opportunity__r.Lawyer__r.name,';
            strQuery += ' Opportunity__r.Account.Name, Opportunity__r.Law_Firm__r.Name,';
            strQuery += ' Opportunity__r.Account.Business_Unit__c, Date__c, Amount__c,Payment_Method__c ';
            strQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDate'; 
            strQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDate'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';  
            strQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
            strQuery += ' OR Reference_Notes__c =:paymentShortfall OR Reference_Notes__c =:paymentSurplus)'; 
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedSurplus)';
            strQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIds';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
            strQuery += ' order by Opportunity__r.Lawyer__r.Name asc NULLS LAST,  Opportunity__r.Law_Firm__r.Name asc, Date__c desc, Opportunity__r.Account.Name asc';
            
            drawdowns.clear();
            drawdowns = Database.query(strQuery);
            
            Map<String,List<Drawdown__c>> lawyerDrawdownsMap = new Map<String,List<Drawdown__c>>();
            for(Drawdown__c drawdown : drawdowns){
                string key = drawdown.Opportunity__r.Lawyer__r.name + '-' + drawdown.Opportunity__r.Law_Firm__r.Name;
                if(!lawyerDrawdownsMap.containsKey(key))
                    lawyerDrawdownsMap.put(key, new List<Drawdown__c>());
                lawyerDrawdownsMap.get(key).add(drawdown);                
            }
            
            if(!lawyerDrawdownsMap.isEmpty()){
                for(String key : lawyerDrawdownsMap.keySet()){
                    String[] splitArr = key.split('-');
                    result.add(new Wrapper(splitArr[0], lawyerDrawdownsMap.get(key)));
                }
            }
        }
        return result;
        
    }
    
    public class Wrapper {
        public String Lawyer {get;set;}
        public List<Drawdown__c> drawdowns{get;set;}
        
        public Wrapper(string lawyerName, List<Drawdown__c> drawdownList){
            Lawyer = lawyerName;
            drawdowns = drawdownList;
        }
    }

}