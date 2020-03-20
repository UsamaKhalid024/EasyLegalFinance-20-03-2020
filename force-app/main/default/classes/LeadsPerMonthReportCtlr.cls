public with sharing class LeadsPerMonthReportCtlr {
    @AuraEnabled
    public static Lead getSampleLead()
    {
        return [Select id, Conga_Actual_Sale_By_Month_Rpt_View_All__c from Lead limit 1];
    }
    @AuraEnabled
    public static Actual_Sales_by_Month_Report__c getCustomSetting(){
        Actual_Sales_by_Month_Report__c LFSR = Actual_Sales_by_Month_Report__c.getOrgDefaults();
        return LFSR;
    }    
    @AuraEnabled
    public static void saveCustomSettings(String startDate, String endDate, String businessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Actual_Sales_by_Month_Report__c psr = Actual_Sales_by_Month_Report__c.getOrgDefaults();
            
            psr.End_date__c = endDt;
            psr.Start_Date__c = startDt;
            psr.Business_Unit__c = businessUnit;
            
            upsert psr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static List<wrapperClass> getLeadsByMonth(String startDate, String endDate, String businessUnit) {
        
        Date startDt = Date.valueOf(startDate);
        Date endDt = Date.valueOf(endDate);
        
        List<wrapperClass> result = new List<wrapperClass>();
        Set<String> months = new Set<String>();
        
        List<Lead> leads = Database.query(
            ' SELECT Created_Month__c, IsConverted, Id, Business_Unit__c FROM Lead Where Business_Unit__c LIKE \'%'+(businessUnit == 'Consolidated' ? '' : businessUnit)+'%\''+
            ' AND CreatedDate >= :startDt and CreatedDate<= :endDt '
        );        
        Map<String, List<Lead>> leadsByMonth = new Map<String, List<Lead>>();
        Map<String, List<Lead>> convertedLeadsByMonth = new Map<String, List<Lead>>();
        for(lead ld : leads){
            months.add(ld.Created_Month__c);
            String key = ld.Created_Month__c + '-' + ld.Business_Unit__c;
            if(ld.IsConverted){
                if(!convertedLeadsByMonth.containsKey(key)){
                    convertedLeadsByMonth.put(key, new List<Lead>());
                }
                convertedLeadsByMonth.get(key).add(ld);
            }else{
                if(!leadsByMonth.containsKey(key)){
                    leadsByMonth.put(key, new List<Lead>());
                }
                leadsByMonth.get(key).add(ld);
            }
        }
        
        List<Drawdown__c> drawdowns = Database.query(
            'SELECT Created_Month__c, Amount__c, Opportunity__r.Account.Business_Unit__c FROM Drawdown__c WHERE ' +
            '( Payment_Method__c = \'Cheque\' OR Payment_Method__c =\'e-Transfer\' OR '+
            'Payment_Method__c = \'Admin Fee\' OR Reference_Notes__c = \'Admin Fee\' OR Reference_Notes__c = \'Assessment Fee\') '+
            ' AND Is_Rejected__c = false' +
            ' AND Opportunity__r.Account.Business_Unit__c LIKE \'%'+(businessUnit == 'Consolidated' ? '' : businessUnit)+'%\' '+
            ' AND Date__c >= :startDt and Date__c<= :endDt and Opportunity__r.StageName = \'Closed with Loan\' '
        );        
        
        Map<String, List<Drawdown__c>> drawdownsByMonth = new Map<String, List<Drawdown__c>>();        
        for(Drawdown__c dd : drawdowns){
            String key = dd.Created_Month__c + '-' + dd.Opportunity__r.Account.Business_Unit__c;
            if(!drawdownsByMonth.containsKey(key)){
                drawdownsByMonth.put(key, new List<Drawdown__c>());
            }
            months.add(dd.Created_Month__c);
            drawdownsByMonth.get(key).add(dd);
        }
        
        //sorting months in asc order
        List<String> sortedMonths = new List<String>(months);
        sortedMonths.sort();
        
        wrapperClass wrr;
        //loop on months in des order
        for(Integer i = sortedMonths.size() - 1; i >= 0; i--){
            String rhinokey = sortedMonths[i]+'-Rhino';
            String elfikey = sortedMonths[i]+'-ELFI';
            wrr = new wrapperClass();
            wrr.CreatedDate = sortedMonths[i];
            if(drawdownsByMonth.containsKey(rhinokey)){
                wrr.SumofAmountPaidtoClientRhino = calculateSumOfAmount(drawdownsByMonth.get(rhinokey));
            }
            if(drawdownsByMonth.containsKey(elfikey)){
                wrr.SumofAmountPaidtoClientELFI = calculateSumOfAmount(drawdownsByMonth.get(elfikey));
            }
            
            if(convertedLeadsByMonth.containsKey(rhinokey)){
                wrr.SumofConvertedLeadsRhino = convertedLeadsByMonth.get(rhinokey).size();
            }
            if(convertedLeadsByMonth.containsKey(elfikey)){
                wrr.SumofConvertedLeadsELFI = convertedLeadsByMonth.get(elfikey).size();
            }
            wrr.RecordCountRhino = wrr.SumofConvertedLeadsRhino + (leadsByMonth.containsKey(rhinokey) ? leadsByMonth.get(rhinokey).size() :  0);
            wrr.RecordCountELFI = wrr.SumofConvertedLeadsELFI + (leadsByMonth.containsKey(elfikey) ? leadsByMonth.get(elfikey).size() :  0);
            result.add(wrr);
        }
        
        return result;
    }
    
    
    public static Decimal calculateSumOfAmount(List<Drawdown__c> ddList){
        Decimal totalAmount = 0.00;
        if(!ddList.isEmpty()){
            for(Drawdown__c dd : ddList){
                
                totalAmount += dd.Amount__c != null ? dd.Amount__c : 0.00;
            }
        }
        return totalAmount;
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    public class wrapperClass{
        @AuraEnabled
        public String CreatedDate{get;set;}
        @AuraEnabled
        public String businessUnit{get;set;}
        @AuraEnabled
        public Decimal SumofAmountPaidtoClientRhino{get;set;}
        @AuraEnabled
        public Decimal SumofAmountPaidtoClientELFI{get;set;}
        @AuraEnabled
        public Integer SumofConvertedLeadsRhino{get;set;}
        @AuraEnabled
        public Integer SumofConvertedLeadsELFI{get;set;}
        @AuraEnabled
        public Integer RecordCountRhino{get;set;}
        @AuraEnabled
        public Integer RecordCountELFI{get;set;}
        
        public wrapperClass(){
            CreatedDate = '';
            SumofAmountPaidtoClientRhino = 0.00;
            SumofConvertedLeadsRhino = 0;
            RecordCountRhino = 0;
            
            SumofAmountPaidtoClientELFI = 0.00;
            SumofConvertedLeadsELFI = 0;
            RecordCountELFI = 0;
        }
    }
}