/**
 * @File Name          : LawFirmSalesSummaryComponentCtrl.cls
 * @Description        : 
 * @Author             : fahad.khan@toptal.com
 * @Group              : 
 * @Last Modified By   : fahad.khan@toptal.com
 * @Last Modified On   : 3/6/2020, 5:42:35 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    3/6/2020   fahad.khan@toptal.com     Initial Version
**/
public with sharing class LawFirmSalesSummaryComponentCtrl {
    public class Wrapper {
        @AuraEnabled
        string firm {get; set;}
        @AuraEnabled
        string firmId {get; set;}
        @AuraEnabled
        integer rhinoFileCount {get; set;}
        @AuraEnabled
        integer rhinoClosedFileCount {get; set;}
        @AuraEnabled
        integer rhinoOpptyCount {get; set;}
        @AuraEnabled
        decimal rhinoAmount {get; set;}
        @AuraEnabled
        decimal rhinoClosedAmount {get; set;}
        @AuraEnabled
        integer elfiFileCount {get; set;}
        @AuraEnabled
        integer elfiClosedFileCount {get; set;}
        @AuraEnabled
        integer elfiOpptyCount {get; set;}
        @AuraEnabled
        decimal elfiAmount {get; set;}
        @AuraEnabled
        decimal elfiClosedAmount {get; set;}
        @AuraEnabled
        integer totalFileCount {get; set;}
        @AuraEnabled
        integer totalClosedFileCount {get; set;}
        @AuraEnabled
        integer totalOpptyCount {get; set;}
        @AuraEnabled
        decimal totalAmount {get; set;}
        @AuraEnabled
        decimal totalClosedAmount {get; set;}
        
        public wrapper(string f, string frmId, integer rc,integer rcc, integer roc, decimal ra, decimal rca, integer ec, integer ecc, integer eoc, decimal ea, decimal eca, integer tc, integer tcc, integer toc, decimal ta,decimal tca){
            
            firm = f;
            firmId = frmId;
            
            rhinoFileCount = rc;
            rhinoClosedFileCount = rcc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            rhinoClosedAmount = rca;
            
            elfiFileCount = ec;
            elfiClosedFileCount = ecc;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
            elfiClosedAmount = eca;
            
            totalFileCount = tc;
            totalClosedFileCount = tcc;
            totalOpptyCount = toc;
            totalAmount = ta;
            totalClosedAmount = tca;
        }
    }
    @AuraEnabled
    public static Wrapper[] getAmountGroupByLawFirm(String startDate, String endDate, String field, String direction, string BusinessUnit, String searchByName){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
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
            
            // for sorting 
            
            if(field == 'Firm'){
                field = 'Opportunity__r.Law_firm__r.name';
            }else if(field == 'Files'){
                field = 'COUNT_Distinct(Opportunity__r.AccountId)';  
            }else if(field == 'opptyCount'){
                field = 'COUNT_Distinct(Opportunity__c)';  
            }else if(field == 'Amount'){
                field = 'SUM(Amount__c)'; 
            }
            
            
            
            strQuery = 'Select Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, '; 
            strQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += ' AND Is_Rejected__c = false';            
            strQuery += ' AND Opportunity__r.Law_firm__c != \'\''; 
            strQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';            
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += ' Group by Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';

            List<AggregateResult> aggResult = Database.query(strQuery);
            List<Wrapper> wrapers = new List<Wrapper>();
            if(!aggResult.isEmpty()){
                Map<String, AggregateResult> result = new Map<String, AggregateResult>();
                List<String> lawfirms = new List<String>();
                Set<String> lawfirmSet = new Set<String>();
                Set<String> lawfirmIdsSet = new Set<String>();
                for(AggregateResult res : aggResult)
                {
                    String key = res.get('firm')+'-'+res.get('unit');
                    result.put(key,res);
                    lawfirmIdsSet.add((String)res.get('firmId'));
                    if(!lawfirmSet.contains((String)res.get('firm')))		lawfirms.add((String)res.get('firm'));
                    lawfirmSet.add((String)res.get('firm'));
                }
                
                // Closed with loan
                
                String closedWLoanQuery = 'Select Opportunity__r.Law_firm__r.name firm,'; 
                closedWLoanQuery += ' COUNT_Distinct(Opportunity__r.AccountId) file, COUNT_Distinct(Opportunity__c) opptyCount, ';
                closedWLoanQuery += ' SUM(Amount__c) amt, Opportunity__r.Account.Business_Unit__c unit';
                closedWLoanQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                closedWLoanQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                closedWLoanQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedWLoanQuery += ' AND Payment_Method__c =:payment';  
                closedWLoanQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
                closedWLoanQuery += ' OR Reference_Notes__c =:paymentShortfall OR Reference_Notes__c =:paymentSurplus)'; 
                closedWLoanQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid';
                closedWLoanQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall';
                closedWLoanQuery += ' OR Opportunity__r.Stage_Status__c =:closedSurplus)';
                closedWLoanQuery += ' AND Opportunity__r.Law_firm__c in :lawfirmIdsSet';
                closedWLoanQuery += ' AND Is_Rejected__c = false'; 
                closedWLoanQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                closedWLoanQuery += ' Group by Opportunity__r.Law_firm__r.name, Opportunity__r.Account.Business_Unit__c';
                //lawfirm in set of lawfirm
                List<AggregateResult> closedOppAggResult = Database.query(closedWLoanQuery);
                
                Map<String, AggregateResult> closedOppResultMap = new Map<String, AggregateResult>();
                if(!closedOppAggResult.isEmpty()){
                    for(AggregateResult res : closedOppAggResult)
                    {
                        String key = res.get('firm')+'-'+res.get('unit');
                        closedOppResultMap.put(key,res);
                    }
                }
                for(String f : lawfirms)
                {
                    String rhinokey = f+'-Rhino';
                    String elfikey = f+'-ELFI';
                    String emptyKey = f+'-';
                    Wrapper w = new Wrapper(f,
                                            result.containsKey(rhinokey) ? (String)result.get(rhinokey).get('firmId') : '',
                                            result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('file') : 0,
                                            closedOppResultMap.containsKey(rhinokey) ? (Integer)closedOppResultMap.get(rhinokey).get('file') : 0,
                                            result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('opptyCount') : 0,
                                            result.containsKey(rhinokey) ? (decimal)result.get(rhinokey).get('amt') : 0,
                                            closedOppResultMap.containsKey(rhinokey) ? (decimal)closedOppResultMap.get(rhinokey).get('amt') : 0,
                                            result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('file') : 0,
                                            closedOppResultMap.containsKey(elfikey) ? (Integer)closedOppResultMap.get(elfikey).get('file') : 0,
                                            result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('opptyCount') : 0,                                            
                                            result.containsKey(elfikey) ? (decimal)result.get(elfikey).get('amt') : 0,
                                            closedOppResultMap.containsKey(elfikey) ? (decimal)closedOppResultMap.get(elfikey).get('amt') : 0,
                                            
                                            (result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('file') : 0) +
                                            (result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('file') : 0) +
                                            (result.containsKey(emptyKey) ? (Integer)result.get(emptyKey).get('file') : 0) ,
                                            
                                            (closedOppResultMap.containsKey(rhinokey) ? (Integer)closedOppResultMap.get(rhinokey).get('file') : 0) +
                                            (closedOppResultMap.containsKey(elfikey) ? (Integer)closedOppResultMap.get(elfikey).get('file') : 0) +
                                            (closedOppResultMap.containsKey(emptyKey) ? (Integer)closedOppResultMap.get(emptyKey).get('file') : 0),
                                            
                                            (result.containsKey(rhinokey) ? (Integer)result.get(rhinokey).get('opptyCount') : 0) +
                                            (result.containsKey(elfikey) ? (Integer)result.get(elfikey).get('opptyCount') : 0) +
                                            (result.containsKey(emptyKey) ? (Integer)result.get(emptyKey).get('opptyCount') : 0) ,
                                            
                                            (result.containsKey(rhinokey) ? (decimal)result.get(rhinokey).get('amt') : 0) +
                                            (result.containsKey(elfikey) ? (decimal)result.get(elfikey).get('amt') : 0) +
                                            (result.containsKey(emptyKey) ? (decimal)result.get(emptyKey).get('amt') : 0),
                                            
                                            (closedOppResultMap.containsKey(rhinokey) ? (decimal)closedOppResultMap.get(rhinokey).get('amt') : 0) +
                                            (closedOppResultMap.containsKey(elfikey) ? (decimal)closedOppResultMap.get(elfikey).get('amt') : 0) +
                                            (closedOppResultMap.containsKey(emptyKey) ? (decimal)closedOppResultMap.get(emptyKey).get('amt') : 0));
                    wrapers.add(w);
                }
                return wrapers;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownLawFirmSalesCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Law_Firm_Sales_Summary_View_All__c,Conga_Law_Firm_Sales_Summary_Print_All__c from Drawdown__c limit 1];
    	return drawdown_conga_url;
    }

    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Law_Firm_Sales_Summary_Report__c psr = Law_Firm_Sales_Summary_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = businessUnit;
            
            update psr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Law_Firm_Sales_Summary_Report__c getCustomSetting(){
        Law_Firm_Sales_Summary_Report__c LFSR = Law_Firm_Sales_Summary_Report__c.getOrgDefaults();
        return LFSR;
    }
}