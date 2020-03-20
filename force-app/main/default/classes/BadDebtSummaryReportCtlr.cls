public with sharing class BadDebtSummaryReportCtlr {
    @AuraEnabled
    public static list<Wrapper> getPaymentsGroupByProvince(String startDate, String endDate, string BusinessUnit){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
            string payment = 'Payment';
            string ClosedWithLoan = 'Closed With Loan';
            String badDebt = 'Bad Debt';
            String paymentShortfall = 'Payment Shortfall';
            
            string filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            
            if(BusinessUnit == 'ELFI'){
                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){
                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){
                
                filterByBusinessUnit = 'Consolidated';
            }
            
            strQuery = 'Select Opportunity__r.Account.ProvinceResidency__c province,Opportunity__r.Account.Business_Unit__c businessunit, COUNT_DISTINCT(Opportunity__r.AccountId) file,'; 
            strQuery += ' COUNT_DISTINCT(Opportunity__c) opptyCount, SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            //strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
            //strQuery += ' AND Payment_Method__c =:payment';
            strQuery += ' AND';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
            ' Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Reference_Notes__c =:badDebt';
            strQuery += ' AND Is_Rejected__c = false';
            strQuery += ' Group by Opportunity__r.Account.ProvinceResidency__c,Opportunity__r.Account.Business_Unit__c';
            strQuery += ' Order by SUM(Amount__c) desc NULLS LAST';
            
            List<AggregateResult> aggResult = Database.query(strQuery);
            if(!aggResult.isEmpty()){
                map<string, wrapper> agrMap = new map<string, wrapper>();
                
                for(AggregateResult agr : aggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('province')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('province')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoAccountCount = Integer.valueof(agr.get('file'));
                            w.rhinoOpptyCount = Integer.valueof(agr.get('opptyCount'));
                            w.rhinoAmount = Double.valueof(agr.get('amt'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiAccountCount = Integer.valueof(agr.get('file'));
                            w.elfiOpptyCount = Integer.valueof(agr.get('opptyCount'));
                            w.elfiAmount = Double.valueof(agr.get('amt'));
                        }
                        
                        agrMap.put(String.ValueOf(agr.get('province')), w);
                        
                    }else{
                        // new province
                        wrapper w;
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w = new wrapper(String.ValueOf(agr.get('province')),
                                            Integer.valueof(agr.get('file')),
                                            Integer.valueof(agr.get('opptyCount')),
                                            Double.valueof(agr.get('amt')),0,0,0.00);
                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w = new wrapper(String.ValueOf(agr.get('province')),0,0,0.00,
                                            Integer.valueof(agr.get('file')),
                                            Integer.valueof(agr.get('opptyCount')),
                                            Double.valueof(agr.get('amt')));
                        }
                        agrMap.put(String.ValueOf(agr.get('province')), w);
                    }
                }
                
                
                list<Wrapper> finalWrapper = new list<Wrapper>(); 
                
                for(string key : agrMap.keyset()){
                    
                    Wrapper w = agrMap.get(key);
                    
                    if(w == null) continue;
                    
                    finalWrapper.add(new Wrapper(w.province, 
                                                 w.rhinoAccountCount, w.rhinoOpptyCount, w.rhinoAmount, 
                                                 w.elfiAccountCount, w.elfiOpptyCount, w.elfiAmount));
                    
                    
                }
                
                //system.debug('Wrapper records are:');
                //system.debug(finalWrapper);
                
                return finalWrapper;
                //return aggResult;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled 
    public static Drawdown__c getDrawdown(){
        List<Drawdown__c> congaUrlHolder = [Select Conga_Bad_Debt_Summary_Report_Print_All__c,
                                            Conga_Bad_Debt_Summary_Report_View_All__c 
                                            from Drawdown__c limit 1];
        return congaUrlHolder[0];
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getOrgDefaults();
            
            bdr.End_Date__c = endDt;
            bdr.Start_Date__c = startDt;
            
            upsert bdr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }
    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
            // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getOrgDefaults();
            
            bdr.BusinessUnit__C = BusinessUnit;
            
            upsert bdr;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
        
        
    }
    @AuraEnabled
    public static Bad_Debt_Summary_Report__c getCustomSetting(){
        // Bad_Debt_Summary_Report__c bDSR = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
        Bad_Debt_Summary_Report__c bDSR = Bad_Debt_Summary_Report__c.getOrgDefaults();
        return bDSR;
    }
    
    public class Wrapper {
        @AuraEnabled
        string province {get; set;}
        @AuraEnabled
        integer rhinoAccountCount {get; set;}
        @AuraEnabled
        integer rhinoOpptyCount {get; set;}
        @AuraEnabled
        decimal rhinoAmount {get; set;}
        @AuraEnabled
        integer elfiAccountCount {get; set;}
        @AuraEnabled
        integer elfiOpptyCount {get; set;}
        @AuraEnabled
        decimal elfiAmount {get; set;}
        
        wrapper(string p, integer rc, integer roc, decimal ra, integer ec, integer eoc, decimal ea){
            
            province = p;
            
            rhinoAccountCount = rc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            
            elfiAccountCount = ec;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
        }
        
    }
}