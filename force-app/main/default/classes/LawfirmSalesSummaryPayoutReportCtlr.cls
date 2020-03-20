public with sharing class LawfirmSalesSummaryPayoutReportCtlr {
    public Date startDate{get;set;}
    public Date endDate{get;set;}
    public String businessUnit{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}
    
    public LawfirmSalesSummaryPayoutReportCtlr(){
        Date dt = Date.today();
        contentType = '';
        renderAs = '';
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        if(paramContentType == 'PDF'){
            renderAs = 'PDF';
        }else{
            contentType = 'application/x-excel#LawfirmSalesSummaryPayoutViewAll.xls';
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
        
        String strQuery = 'SELECT Opportunity__r.Law_Firm__c';
        strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDate'; 
        strQuery += ' AND Date__c <= :endDate'; 
        strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
        strQuery += ' OR (Payment_Method__c =:Cheque)';
        strQuery += ' OR (Payment_Method__c =:AdminFee))';
        strQuery += ' AND Is_Rejected__c = false';
        strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
        strQuery += ' AND Opportunity__r.Law_firm__c != \'\''; 
        
        drawdowns = Database.query(strQuery);
        
        Set<Id> lawfirmIdsSet = new Set<Id>();
        
        for(Drawdown__c drawdown: drawdowns){
            lawfirmIdsSet.add(drawdown.Opportunity__r.Law_Firm__c);
        }
        
        
        if(!lawfirmIdsSet.isEmpty()){
            
            strQuery = 'SELECT Id, Name, Opportunity__r.Account.Name,';
            strQuery += ' Opportunity__r.Account.Business_Unit__c, Opportunity__r.Law_Firm__c,';
            strQuery += ' Opportunity__r.Law_Firm__r.Name, Date__c, Amount__c,Payment_Method__c';
            strQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDate'; 
            strQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDate'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';  
            strQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
            strQuery += ' OR Reference_Notes__c =:paymentShortfall OR Reference_Notes__c =:paymentSurplus)'; 
            strQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall';
            strQuery += ' OR Opportunity__r.Stage_Status__c =:closedSurplus)';
            strQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
            strQuery += ' AND Is_Rejected__c = false';   
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit';
            strQuery += ' order by Opportunity__r.Law_Firm__r.Name asc NULLS LAST, Opportunity__r.Account.Business_Unit__c NULLS LAST , Date__c desc, Opportunity__r.Account.Name asc';
            
            drawdowns.clear();
            drawdowns = Database.query(strQuery);
            
            Map<String,List<Drawdown__c>> lawfirmDrawdownsMap = new Map<String,List<Drawdown__c>>();
            for(Drawdown__c drawdown : drawdowns){
                if(!lawfirmDrawdownsMap.containsKey(drawdown.Opportunity__r.Law_Firm__r.Name))
                    lawfirmDrawdownsMap.put(drawdown.Opportunity__r.Law_Firm__r.Name, new List<Drawdown__c>());
				lawfirmDrawdownsMap.get(drawdown.Opportunity__r.Law_Firm__r.Name).add(drawdown);                
            }
            
            if(!lawfirmDrawdownsMap.isEmpty()){
                for(String firmName : lawfirmDrawdownsMap.keySet()){
                    result.add(new Wrapper(firmName, lawfirmDrawdownsMap.get(firmName)));
                }
            }
            
        }
        
        return result;
        
    }
    
    public class Wrapper {
        public String Lawfirm {get;set;}
        public List<Drawdown__c> drawdowns{get;set;}
        
        public Wrapper(string lawfirmName, List<Drawdown__c> drawdownList){
            Lawfirm = lawfirmName;
            drawdowns = drawdownList;
        }
    }
}