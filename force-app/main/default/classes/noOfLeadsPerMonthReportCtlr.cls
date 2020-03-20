public with sharing class noOfLeadsPerMonthReportCtlr {
    
    public Decimal totalfAmountPaidtoClient{get;set;}
    public Integer totalConverted{get;set;}
    public Integer totalRecords{get;set;}
    
    public noOfLeadsPerMonthReportCtlr(){
        totalfAmountPaidtoClient = 0.00;
        totalConverted = 0;
        totalRecords = 0;
    }
    
    public List<wrapperClass> getLeadsByMonth() {
        
        List<wrapperClass> result = new List<wrapperClass>();
        Set<String> months = new Set<String>();
        
        List<Lead> leads = Database.query(
            'SELECT Created_Month__c, IsConverted, Id FROM Lead'
        );
        
        Map<String, List<Lead>> leadsByMonth = new Map<String, List<Lead>>();
        Map<String, List<Lead>> convertedLeadsByMonth = new Map<String, List<Lead>>();
        for(lead ld : leads){
            months.add(ld.Created_Month__c);
            if(ld.IsConverted){
                if(!convertedLeadsByMonth.containsKey(ld.Created_Month__c)){
                    convertedLeadsByMonth.put(ld.Created_Month__c, new List<Lead>());
                }
                convertedLeadsByMonth.get(ld.Created_Month__c).add(ld);
            }else{
                if(!leadsByMonth.containsKey(ld.Created_Month__c)){
                    leadsByMonth.put(ld.Created_Month__c, new List<Lead>());
                }
                leadsByMonth.get(ld.Created_Month__c).add(ld);
            }
        }
        system.debug('Lead size ' + leads.size());
        system.debug(leads);
        
        List<Opportunity> opportunities = Database.query(
            'SELECT Created_Month__c, Amount_Paid_to_Client__c, Id FROM Opportunity'
        );
        system.debug('Oppo size ' + opportunities.size());
        system.debug(opportunities);
        
        Map<String, List<Opportunity>> OpportunitiesByMonth = new Map<String, List<Opportunity>>();
        for(Opportunity opp : opportunities){
            if(!OpportunitiesByMonth.containsKey(opp.Created_Month__c)){
                OpportunitiesByMonth.put(opp.Created_Month__c, new List<Opportunity>());
                months.add(opp.Created_Month__c);
            }
            OpportunitiesByMonth.get(opp.Created_Month__c).add(opp);            
        }
        
        system.debug('months ' + months.size());
        system.debug(months);
        
        //sorting months in asc order
        List<String> sortedMonths = new List<String>(months);
        sortedMonths.sort();
        
        system.debug('S months ' + sortedMonths.size());
        system.debug(sortedMonths);
        
        wrapperClass wrr;
        //loop on months in des order
        for(Integer i = sortedMonths.size() - 1; i > 0; i--){
            String key = sortedMonths[i];
            wrr = new wrapperClass();
            wrr.CreatedDate = key;
            if(OpportunitiesByMonth.containsKey(key)){
                wrr.SumofAmountPaidtoClient = calculateSumOfAmount(OpportunitiesByMonth.get(key));
            }
            if(convertedLeadsByMonth.containsKey(key)){
                wrr.SumofConvertedLeads = convertedLeadsByMonth.get(key).size();
                this.totalConverted += wrr.SumofConvertedLeads;
            }
            wrr.RecordCount = wrr.SumofConvertedLeads + (leadsByMonth.containsKey(key) ? leadsByMonth.get(key).size() :  0);
            this.totalRecords += wrr.RecordCount;
            result.add(wrr);
        }
        
        return result;
    }
    
    public Decimal calculateSumOfAmount(List<Opportunity> oppList){
        Decimal totalAmount = 0.00;
        if(!oppList.isEmpty()){
            for(Opportunity opp : oppList){
                totalAmount += opp.Amount_Paid_to_Client__c;
            }
        }
        this.totalfAmountPaidtoClient += totalAmount;
        return totalAmount;
    }
    
    public class wrapperClass{
        public String CreatedDate{get;set;}
        public Decimal SumofAmountPaidtoClient{get;set;}
        public Integer SumofConvertedLeads{get;set;}
        public Integer RecordCount{get;set;}
        
        public wrapperClass(){
            CreatedDate = '';
            SumofAmountPaidtoClient = 0.00;
            SumofConvertedLeads = 0;
            RecordCount = 0;
        }
    }
}