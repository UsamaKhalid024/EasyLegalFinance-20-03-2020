public class FinanceLoanProgressionCtrl {
    
    @AuraEnabled
    public static list<FinancialYear> getData(String startDate, String endDate, String field, String direction){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            List<List<AggregateResult>> mainAggregate = new List<List<AggregateResult>>();
            
            String strQuery = '';            
            
            string eTransfer = 'e-Transfer';
            string Cheque = 'Cheque';
            string AdminFee = 'Admin Fee';
            String PaidOff = 'Paid Off';
            String BadDebt = 'Bad Debt';
            String Payment = 'Payment';
            String PaymentShortfall = 'Payment Shortfall';
            
            // for sorting 
            if(field == 'bydate'){
                field = 'CALENDAR_Year(Date__c)';
            }
            
            // for paid off stage status            
            strQuery = 'Select CALENDAR_QUARTER(Date__c) quarter,CALENDAR_YEAR(Date__c) year, '; 
            strQuery += ' COUNT(Opportunity__c) opportunities,Opportunity__r.Stage_Status__c stage,';
            strQuery += ' SUM(Amount__c) amount';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.Stage_Status__c =:PaidOff';
            strQuery += ' AND (Payment_Method__c =:Cheque';
            strQuery += ' OR Payment_Method__c =:AdminFee OR Payment_Method__c =:eTransfer)';
            strQuery += ' Group by CALENDAR_YEAR(Date__c),CALENDAR_QUARTER(Date__c),Opportunity__r.Stage_Status__c';
            strQuery += ' order by ' + field + ' ' + direction;
            
            List<AggregateResult> firstAggregate = Database.query(strQuery);
            
            mainAggregate.add(firstAggregate);
            
            strQuery = '';
            
            // for bad debt stage status            
            strQuery = 'Select CALENDAR_QUARTER(Date__c) quarter,CALENDAR_YEAR(Date__c) year, '; 
            strQuery += ' COUNT(Opportunity__c) opportunities,Opportunity__r.Stage_Status__c stage,';
            strQuery += ' SUM(Amount__c) amount';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            //strQuery += ' AND Opportunity__r.Stage_Status__c =:BadDebt';
            //strQuery += ' AND Payment_Method__c =:Payment';
            strQuery += ' AND (Reference_Notes__c =:PaymentShortfall OR Reference_Notes__c =:BadDebt)';
            strQuery += ' Group by CALENDAR_YEAR(Date__c),CALENDAR_QUARTER(Date__c),Opportunity__r.Stage_Status__c';
            strQuery += ' order by ' + field + ' ' + direction;
            
            List<AggregateResult> secondAggregate = Database.query(strQuery);
            
            mainAggregate.add(secondAggregate);
            
            map<String,map<String, object>> QuarterYearMap = new map<String,map<String, object>>();
            
            for(AggregateResult ars : mainAggregate[0]){
                
                String mainKey = ars.get('year') + '-' + ars.get('quarter'); 
                
                map<String, object> StageMap = new map<String, object>();
                
                String quarter = String.valueOf(ars.get('quarter'));
                String year = String.valueOf(ars.get('year'));
                String stage = String.valueOf(ars.get('stage'));
                
                Integer PaidOffCount = 0;
                Decimal PaidOffAmount = 0.00;
                String PaidOffStage = '';
                
                // Paid Off
                
                if(stage == 'Paid Off'){
                    PaidOffCount = Integer.ValueOf(ars.get('opportunities'));
                    PaidOffAmount = Double.ValueOf(ars.get('amount'));
                    PaidOffStage = stage;
                }else{ 
                    PaidOffCount = 0;
                    PaidOffAmount = 0.00;
                    PaidOffStage = 'Paid Off';
                }
                
                StageMap.put('PaidOffStage',PaidOffStage);
                StageMap.put('PaidOffCount', PaidOffCount);
                StageMap.put('PaidOffAmount', PaidOffAmount);
                
                StageMap.put('BadDebtStage', 'Bad Debt');
                StageMap.put('BadDebtAmount', 0.00);
                StageMap.put('BadDebtCount', 0);
                
                // set quarter and year
                StageMap.put('year', year);
                StageMap.put('quarter', quarter);
                
                QuarterYearMap.put(mainKey, StageMap);
            }
            
            for(AggregateResult ars : mainAggregate[1]){
                
                String mainKey = ars.get('year') + '-' + ars.get('quarter'); 
                
                // get the stage and update the amount and opportunities count
                
                map<String, object> exists = QuarterYearMap.get(mainKey);
                map<String, object> StageMap = new map<String, object>();
                
                StageMap = new map<String, object>();
                
                String stagep = String.ValueOf(exists.get('PaidOffStage'));
                Double amountp = Double.ValueOf(exists.get('PaidOffAmount'));
                Integer opportunitiesp = Integer.ValueOf(exists.get('PaidOffCount'));
                
                Double amountb = 0.00;
                Integer opportunitiesb = 0;
                
                amountb = Double.ValueOf(exists.get('BadDebtAmount'));
                opportunitiesb = Integer.ValueOf(exists.get('BadDebtCount'));                            
                
                String stageb = String.ValueOf(ars.get('stage'));
                opportunitiesb = opportunitiesb + Integer.ValueOf(ars.get('opportunities'));
                amountb = amountb + Double.ValueOf(ars.get('amount'));
                
                StageMap.put('PaidOffStage', stagep);
                StageMap.put('PaidOffAmount', amountp);
                StageMap.put('PaidOffCount', opportunitiesp);
                
                StageMap.put('BadDebtStage', stageb);
                StageMap.put('BadDebtAmount', amountb);
                StageMap.put('BadDebtCount', opportunitiesb);
                
                String year = String.ValueOf(exists.get('year'));
                String quarter = String.ValueOf(exists.get('quarter'));
                
                StageMap.put('year', year);
                StageMap.put('quarter', quarter);
                
                QuarterYearMap.put(mainKey, StageMap);
            }
            list<FinancialData> fdata = new list<FinancialData>();
            list<FinancialYear> fyear = new list<FinancialYear>();
            map<string, list<map<string, object>>> fdataMap = new map<string, list<map<string, object>>>();
            
            if(!mainAggregate.isEmpty()){
                for(String key : QuarterYearMap.keyset()){
                    
                    map<string, object> newValue = QuarterYearMap.get(key);
                    
                    // get the year
                    String[] yearArray = key.split('-');
                    
                    fdata.add(new FinancialData(key, yearArray[0],newValue));                    
                    
                }
                
                // create the main wrapper
                for(FinancialData tdata : fdata){
                    
                    list<map<string, object>> fdList = new list<Map<String,Object>>();
                    
                    if(fdataMap.containsKey(tdata.year)){
                        
                        fdList = fdataMap.get(tdata.year);
                        fdList.add(tdata.data);
                        fdataMap.put(tdata.year, fdList);
                    }else{
                        list<Map<String,Object>> dataList = new list<Map<String,Object>>();
                        dataList = new list<Map<String,Object>>();
                        dataList.add(tdata.data);
                        fdataMap.put(tdata.year, dataList);
                    }
                }
                
                for(string singleKey : fdataMap.keyset()){
                    list<map<string, object>> dlist = fdataMap.get(singleKey);
                    
                    Decimal paida = 0.00;
                    Integer paidc = 0;
                    
                    decimal debta = 0.00;
                    Integer debtc = 0;
                    
                    for(map<string, object> dl : dlist){
                        paida += Double.ValueOf(dl.get('PaidOffAmount'));
                        paidc += Integer.ValueOf(dl.get('PaidOffCount'));
                        Debta += Double.ValueOf(dl.get('BadDebtAmount'));
                        Debtc += Integer.ValueOf(dl.get('BadDebtCount'));
                    }
                    
                    fyear.add(new financialYear(singleKey, fdataMap.get(singleKey), paida, paidc, debta, debtc));
                    
                }
                
                return fyear;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class FinancialData
    {
        @AuraEnabled
        public String quarter;
        
        @AuraEnabled
        public String year;
        
        @AuraEnabled
        public Map<String,Object> data;
        
        public FinancialData(String q, String yr, Map<String,Object> d){
            
            quarter = q;
            year = yr;
            data = d;
            
        }
        
    }
    public class FinancialYear{
        
        @AuraEnabled
        public String year;
        
        @AuraEnabled
        public Decimal paidamount;
        
        @AuraEnabled
        public Integer paidcount;
        
        @AuraEnabled
        public Decimal debtamount;
        
        @AuraEnabled
        public Integer debtcount;
        
        @AuraEnabled
        public list<map<string, object>> fndata;
        
        public FinancialYear(String yr, list<map<string, object>> fd, Decimal pa, Integer pc, Decimal da, Integer dc){
            year = yr;
            fndata = fd;
            paidamount = pa;
            paidcount = pc;
            debtamount = da;
            debtcount = dc;
        }
        
    }
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Finance_Loan_Progression_View_All__c,
                                                Conga_Finance_Loan_Progression_Print_All__c from Drawdown__c limit 1];
        return drawdown_conga_url;
    }
    
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            FinanceLoanProgression__c lsr = FinanceLoanProgression__c.getOrgDefaults();
            
            lsr.End_date__c = endDt;
            lsr.Start_Date__c = startDt;
            
            update lsr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static FinanceLoanProgression__c getCustomSetting(){
        FinanceLoanProgression__c Lsr = FinanceLoanProgression__c.getOrgDefaults();
        return Lsr;
    }
    
}