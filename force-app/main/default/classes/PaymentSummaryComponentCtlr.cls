public with sharing class PaymentSummaryComponentCtlr {
    public class wrapperClass{
        @AuraEnabled
        public String prov{get;set;}
        @AuraEnabled
        public String businessUnit{get;set;}
        @AuraEnabled
        public Decimal amountRhino{get;set;}
        @AuraEnabled
        public Decimal amountELFI{get;set;}
        @AuraEnabled
        public Integer numAccountsRhino{get;set;}
        @AuraEnabled
        public Integer numOpptiesRhino{get;set;}
        @AuraEnabled
        public Integer numAccountsELFI{get;set;}
        @AuraEnabled
        public Integer numOpptiesELFI{get;set;}
        
        public wrapperClass(){
            prov = '';
            businessUnit = '';
            amountRhino = 0;
            amountELFI = 0;
            
            numAccountsRhino = 0;
            numAccountsELFI = 0;
            
            numOpptiesRhino = 0;
            numOpptiesELFI = 0;
        }
    }
    @AuraEnabled
    public static wrapperClass[] getPaymentsGroupByProvince(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            
            strQuery = 'Select Opportunity__r.Account.ProvinceResidency__c prov, Opportunity__r.Account.Business_Unit__c bunit, COUNT_DISTINCT(Opportunity__r.AccountId) file,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) opptyCount, SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c, Opportunity__r.Account.Business_Unit__c ';
            strQuery += ' Order by SUM(Amount__c) desc NULLS LAST';
            
              

            List<AggregateResult> aggResult = Database.query(strQuery);
            if(!aggResult.isEmpty()){
                List<wrapperClass> result = new List<wrapperClass>();
                List<String> provs = new List<String>();
                Set<String> provSet = new Set<String>();
                Map<String, wrapperClass> resultMap = new Map<String, wrapperClass>();
                for(AggregateResult ar : aggResult)
                {
                    String prov = (String)ar.get('prov');
                    String bunit = (String)ar.get('bunit');
                    if(!provSet.contains(prov))
                    {
                        provSet.add(prov);
                        provs.add(prov);
                    }
                    
                    if(!resultMap.containsKey(prov))	resultMap.put(prov, new wrapperClass());
                    wrapperClass r = resultMap.get(prov);
                    r.prov = prov;
                    if(bunit == 'ELFI')		r.numAccountsELFI = (Integer)ar.get('file');
                    if(bunit == 'ELFI')		r.numOpptiesELFI = (Integer)ar.get('opptyCount');
                    if(bunit == 'ELFI')		r.amountELFI = (Double)ar.get('amt');
                    if(bunit == 'Rhino')		r.numAccountsRhino = (Integer)ar.get('file');
                    if(bunit == 'Rhino')		r.numOpptiesRhino = (Integer)ar.get('opptyCount');
                    if(bunit == 'Rhino')		r.amountRhino = (Double)ar.get('amt');
                }
                for(String p : provs)
                {
                    if(resultMap.containsKey(p))
                    {
                        result.add(resultMap.get(p));
                    }
                }
                return result;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static PartialPaymentsWrapper getPartialPayments(String startDate, String endDate, String businessUnit){
        PartialPaymentsWrapper partialPaymentsW = new PartialPaymentsWrapper();
        //List<AggregateResult> aggResult = new List<AggregateResult>();
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = ''; 
            
            // total payouts
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String PartialPayment = 'Partial Payment';
            String LoanPayout = 'Loan Payout';
            
            strQuery = 'Select'; 
            strQuery += ' COUNT(Opportunity__c) payouts, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultPayouts = Database.query(strQuery); 
            
            // Average number of days outstanding
            strQuery = ''; 
            
            strQuery = 'Select'; 
            strQuery += ' AVG(Outstanding_Days__c) outstanding, Account.Business_Unit__c unit ';
            strQuery += ' FROM Opportunity WHERE id in ( Select Opportunity__c from Drawdown__c where Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout))';
            strQuery += ' group by Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultOutstanding = Database.query(strQuery);
            
            // total principal paid
            strQuery = '';
            
            String Cheque = 'Cheque';
            String eTransfer = 'e-Transfer';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) principalPaid, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:eTransfer OR Payment_Method__c =:Cheque)';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            //strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultPrincipal = Database.query(strQuery);
            
            // total interest paid
               // yet to be decided, question marks added
            
			// total admin fee
            strQuery = '';
            
            String AdminFee = 'Admin Fee';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) adminFee, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:AdminFee)';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            //strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultAdminfee = Database.query(strQuery); 
            
            // total other changes
            strQuery = '';
            
            String Other = 'Other';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) other, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND (Payment_Method__c =:Other)';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            // strQuery += ' AND (Reference_Notes__c =:PartialPayment OR Reference_Notes__c =:LoanPayout)';
            
            List<AggregateResult> aggResultOther = Database.query(strQuery); 
            
            // total shortfall paid
            strQuery = '';
            
            String Shortfall = 'Payment Shortfall';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) shortfall, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Shortfall';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultShortfall = Database.query(strQuery); 
            
            // total surplus paid
            strQuery = '';

            String Surplus = 'Payment Surplus';

            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) surplus, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Surplus';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultSurplus = Database.query(strQuery);
            
            // total misc paid
            strQuery = '';
            
            String Misc = 'Miscellaneous Payment';
            
            strQuery = 'Select'; 
            strQuery += ' SUM(Amount__c) misc, Opportunity__r.Account.Business_Unit__c unit ';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += businessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :businessUnit ';
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            strQuery += ' AND Reference_Notes__c =:Misc';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' group by Opportunity__r.Account.Business_Unit__c ';
            
            List<AggregateResult> aggResultMisc = Database.query(strQuery);

            if(!aggResultPayouts.isEmpty()){
                for(AggregateResult aggResult : aggResultPayouts)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.noOfPayoutsELFI = aggResult.get('payouts') != null? (Integer)aggResult.get('payouts') : 0;
                    if(unit == 'Rhino')	partialPaymentsW.noOfPayoutsRhino = aggResult.get('payouts') != null? (Integer)aggResult.get('payouts') : 0;
                }
                
            }
            
            if(!aggResultoutstanding.isEmpty()){
                for(AggregateResult aggResult : aggResultoutstanding)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.avgNoOfDaysOutstandingELFI = aggResult.get('outstanding') != null? (Decimal)aggResult.get('outstanding') : 0;
                    if(unit == 'Rhino')	partialPaymentsW.avgNoOfDaysOutstandingRhino = aggResult.get('outstanding') != null? (Decimal)aggResult.get('outstanding') : 0;
                }
                
            }
            if(!aggResultPrincipal.isEmpty()){
                for(AggregateResult aggResult : aggResultPrincipal)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalPrincipalPaidELFI = aggResult.get('principalPaid') != null? (Decimal)aggResult.get('principalPaid') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalPrincipalPaidRhino = aggResult.get('principalPaid') != null? (Decimal)aggResult.get('principalPaid') : 0.00;
                }
                
            }
            if(!aggResultAdminfee.isEmpty()){
                for(AggregateResult aggResult : aggResultAdminfee)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalAdminFeePaidELFI = aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalAdminFeePaidRhino = aggResult.get('adminFee') != null? (Decimal)aggResult.get('adminFee') : 0.00;
                }
                
            }
            if(!aggResultOther.isEmpty()){
                for(AggregateResult aggResult : aggResultOther)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalOtherELFI = aggResult.get('other') != null? (Decimal)aggResult.get('other') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalOtherRhino = aggResult.get('other') != null? (Decimal)aggResult.get('other') : 0.00;
                }
                
            }
            if(!aggResultShortfall.isEmpty()){
                for(AggregateResult aggResult : aggResultShortfall)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalShortfallELFI = aggResult.get('shortfall') != null? (Decimal)aggResult.get('shortfall') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalShortfallRhino = aggResult.get('shortfall') != null? (Decimal)aggResult.get('shortfall') : 0.00;
                }
                
            }
            if(!aggResultSurplus.isEmpty()){
                for(AggregateResult aggResult : aggResultSurplus)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalSurplusELFI = aggResult.get('surplus') != null? (Decimal)aggResult.get('surplus') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalSurplusRhino = aggResult.get('surplus') != null? (Decimal)aggResult.get('surplus') : 0.00;
                }
                
            }
            if(!aggResultMisc.isEmpty()){
                for(AggregateResult aggResult : aggResultMisc)
                {
                    String unit = (string)aggResult.get('unit');
                    if(unit == 'ELFI')	partialPaymentsW.totalMiscELFI = aggResult.get('misc') != null? (Decimal)aggResult.get('misc') : 0.00;
                    if(unit == 'Rhino')	partialPaymentsW.totalMiscRhino = aggResult.get('misc') != null? (Decimal)aggResult.get('misc') : 0.00;
                }
                
            }
            partialPaymentsW.totalPaymentsELFI = partialPaymentsW.totalPrincipalPaidELFI + partialPaymentsW.totalAdminFeePaidELFI + 
                partialPaymentsW.totalOtherELFI;
            
            partialPaymentsW.totalPaymentsRhino = partialPaymentsW.totalPrincipalPaidRhino + partialPaymentsW.totalAdminFeePaidRhino + 
                partialPaymentsW.totalOtherRhino;
            
            //if(!aggResult.isEmpty()){
                
                
                // partialPaymentsW.totalInterestPaid = aggResult[3].get('interestPaid') != null? (Decimal)aggResult[3].get('interestPaid') : 0.00;
                
                
                
                
                
                //partialPaymentsW.totalPayments = partialPaymentsW.totalPrincipalPaid + partialPaymentsW.totalInterestPaid + 
                    //partialPaymentsW.totalAdminFeePaid + partialPaymentsW.totalOther;
                
                
            //}
            
            // get the conga url
            List<Drawdown__c> congaUrlHolder = [Select Conga_Payment_Summary_Report_Print_All__c,
                                                Conga_Payment_Summary_Report_Print_All_2__c,
                                                Conga_Payment_Summary_Report_Print_All_3__c,
                                                Conga_Payment_Summary_Report_Print_All_4__c,
                                                Conga_Payment_Summary_Report_Print_All_5__c,
                                                Conga_Payment_Summary_Report_Print_All_6__c,
                                                Conga_Payment_Summary_Report_View_All__c 
                                            from Drawdown__c limit 1];
        	partialPaymentsW.congaViewAllURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_View_All__c;
        	partialPaymentsW.congaPrintReportURL = congaUrlHolder.isEmpty() ? '' 
                : congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All__c + 
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_2__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_3__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_4__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_5__c +
                    congaUrlHolder[0].Conga_Payment_Summary_Report_Print_All_6__c ;
            
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()+e.getStackTraceString());
        }
        return partialPaymentsW;
    }
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Payment_Summary_Report__c psr = Payment_Summary_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = businessUnit;
            update psr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }
    
    @AuraEnabled
    public static Payment_Summary_Report__c getCustomSetting(){
        Payment_Summary_Report__c pSR = Payment_Summary_Report__c.getOrgDefaults();
        return pSR;
    }
    
    public class PartialPaymentsWrapper{
        
        @AuraEnabled
        public Integer noOfPayoutsRhino {get;set;}
        
        @AuraEnabled
        public Integer noOfPayoutsELFI {get;set;}
        
        @AuraEnabled
        public Decimal avgNoOfDaysOutstandingRhino {get;set;}
        
        @AuraEnabled
        public Decimal avgNoOfDaysOutstandingELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalPrincipalPaidRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalPrincipalPaidELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalInterestPaidRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalInterestPaidELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalAdminFeePaidRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalAdminFeePaidELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalPaymentsRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalPaymentsELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalSurplusRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalSurplusELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalShortfallRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalShortfallELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalMiscRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalMiscELFI {get;set;}
        
        @AuraEnabled
        public Decimal totalOtherRhino {get;set;}
        
        @AuraEnabled
        public Decimal totalOtherELFI {get;set;}
        
        @AuraEnabled
        public String congaViewAllURL {get;set;}
        
        @AuraEnabled
        public String congaPrintReportURL {get;set;}
        
        public PartialPaymentsWrapper(){
            noOfPayoutsRhino = 0;
            avgNoOfDaysOutstandingRhino = 0;
            totalPrincipalPaidRhino = 0.0;
            totalInterestPaidRhino = 0.0;
            totalAdminFeePaidRhino = 0.0;
            totalPaymentsRhino = 0.0;
            totalOtherRhino = 0.00;
            totalSurplusRhino = 0.0;
            totalShortfallRhino = 0.0;
            totalMiscRhino = 0.0;
            
            noOfPayoutsELFI = 0;
            avgNoOfDaysOutstandingELFI = 0;
            totalPrincipalPaidELFI = 0.0;
            totalInterestPaidELFI = 0.0;
            totalAdminFeePaidELFI = 0.0;
            totalPaymentsELFI = 0.0;
            totalOtherELFI = 0.00;
            totalSurplusELFI = 0.0;
            totalShortfallELFI = 0.0;
            totalMiscELFI = 0.0;
            
            
            congaViewAllURL = null;
            congaPrintReportURL = null;
        }
    }
}