public with sharing class LawyerSalesSummaryComponentCtrl {
    @AuraEnabled
    public static list<Wrapper> getAmountGroupByLawyer(String startDate, String endDate, String field, String direction, string BusinessUnit, String searchByName){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            String strQuery = '';            
            
            String payment = 'Payment';
            String loanPayout = 'Loan Payout';
            String partialPayment = 'Partial Payment';
            String paymentShortfall = 'Payment Shortfall';
            String paymentSurplus = 'Payment Surplus';
            string eTransfer = 'e-Transfer';
            string Cheque = 'Cheque';
            string AdminFee = 'Admin Fee';
            String ClosedWithLoan = 'Closed With Loan';
            String closedPaid = 'Closed - Paid';
            String closedShortfall = 'Closed - Shortfall';
            String closedSurplus = 'Closed - Surplus';
            
            // for sorting 
            if(field == 'Lawyer'){
                field = 'Opportunity__r.Lawyer__r.name';
            }else if(field == 'Firm'){
                field = 'Opportunity__r.Law_firm__r.name';
            }else if(field == 'Files'){
                field = 'COUNT_DISTINCT(Opportunity__r.AccountId)'; 
            }else if(field == 'opptyCount'){
                field = 'COUNT_DISTINCT(Opportunity__c)';
            }else if(field == 'Amount'){
                field = 'SUM(Amount__c)'; 
            }
            string filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            
            // Business Unit Filter

            if(BusinessUnit == 'ELFI'){
                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){
                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){
                
                filterByBusinessUnit = 'Consolidated';
            }

            
            strQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer,  Opportunity__r.Law_firm__r.name firm, Opportunity__r.Law_firm__c firmId, '; 
            strQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount, ';
            strQuery += ' SUM(Amount__c) amt';
            strQuery += ' FROM Drawdown__c WHERE Date__c >= :startDt'; 
            strQuery += ' AND Date__c <= :endDt'; 
            strQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan AND ((Payment_Method__c =:eTransfer)';
            strQuery += ' OR (Payment_Method__c =:Cheque)';
            strQuery += ' OR (Payment_Method__c =:AdminFee))';
            strQuery += ' AND Is_Rejected__c = false AND';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
            ' Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += ' AND Opportunity__r.Lawyer__c != \'\'';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Law_firm__r.name LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Lawyer__r.Name LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' Group by Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name, Opportunity__r.Law_firm__c, Opportunity__r.Account.Business_Unit__c';
            strQuery += ' order by ' + field + ' ' + direction + ' NULLS LAST';

            List<AggregateResult> aggResult = Database.query(strQuery);
            
            if(!aggResult.isEmpty()){
                
                Set<String> lawyerIdsSet = new Set<String>();
                for(AggregateResult agr : aggResult){
                    lawyerIdsSet.add(String.ValueOf(agr.get('lawyerId')));
                }

                map<string, wrapper> agrMap = new map<string, wrapper>();
                
                for(AggregateResult agr : aggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                       // if province exists 
                       wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoFileCount += Integer.valueof(agr.get('file'));
                            w.rhinoOpptyCount += Integer.valueof(agr.get('opptyCount'));
                            w.rhinoAmount += Double.valueof(agr.get('amt'));
                            w.rhinoClosedAmount = 0;                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiFileCount += Integer.valueof(agr.get('file'));
                            w.elfiOpptyCount += Integer.valueof(agr.get('opptyCount'));
                            w.elfiAmount += Double.valueof(agr.get('amt'));
                            w.elfiClosedAmount = 0;
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }else{
                        // new province
                        wrapper w;
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){                            
                            w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                            String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')),
                                            Integer.valueof(agr.get('file')),
                                            0,
                                            Integer.valueof(agr.get('opptyCount')),                                            
                                            Double.valueof(agr.get('amt')),0,0,0,0.00);
                            
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){                            
                            w = new wrapper(String.ValueOf(agr.get('lawyer')), String.ValueOf(agr.get('lawyerId')),
                                            String.ValueOf(agr.get('firm')), String.ValueOf(agr.get('firmId')),
                                            0,0,0,0.00,Integer.valueof(agr.get('file')),
                                            0,
                                            Integer.valueof(agr.get('opptyCount')),                                            
                                            Double.valueof(agr.get('amt')));
                        }
                        w.rhinoClosedAmount = 0;
                        w.elfiClosedAmount = 0;
                        agrMap.put(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                    }
                }
                
                String closedOppQuery = 'Select Opportunity__r.Account.Business_Unit__c businessunit, Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyer, Opportunity__r.Law_firm__r.name firm,';
                closedOppQuery += ' COUNT_DISTINCT(Opportunity__r.AccountId) file, COUNT_DISTINCT(Opportunity__c) opptyCount,';
                closedOppQuery += ' SUM(Amount__c) amt';
                closedOppQuery += ' FROM Drawdown__c WHERE Opportunity__r.Opportunity_Closed_Date__c >= :startDt';
                closedOppQuery += ' AND Opportunity__r.Opportunity_Closed_Date__c <= :endDt';
                closedOppQuery += ' AND Opportunity__r.StageName =:ClosedWithLoan';
                closedOppQuery += ' AND Payment_Method__c =:payment';  
                closedOppQuery += ' AND (Reference_Notes__c =:loanPayout OR Reference_Notes__c =:partialPayment'; 
                closedOppQuery += ' OR Reference_Notes__c =:paymentShortfall OR Reference_Notes__c =:paymentSurplus)'; 
                closedOppQuery += ' AND (Opportunity__r.Stage_Status__c =:closedPaid';
                closedOppQuery += ' OR Opportunity__r.Stage_Status__c =:closedShortfall';
                closedOppQuery += ' OR Opportunity__r.Stage_Status__c =:closedSurplus)';
                closedOppQuery += ' AND Opportunity__r.Lawyer__c in :lawyerIdsSet';
                closedOppQuery += BusinessUnit == 'Consolidated' ? '' : ' AND Opportunity__r.Account.Business_Unit__c = :BusinessUnit';
                closedOppQuery += ' Group by Opportunity__r.Account.Business_Unit__c, Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_firm__r.name';
                
                 
                
            	List<AggregateResult> closedOppAggResult = Database.query(closedOppQuery);
                
                for(AggregateResult agr : closedOppAggResult){
                    
                    if(agrMap.containsKey(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')))){
                        // if province exists 
                        wrapper w = agrMap.get(String.ValueOf(agr.get('lawyerId')) + '-' + String.ValueOf(agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')));
                        
                        if(String.valueof(agr.get('businessunit')) == 'Rhino'){
                            
                            w.rhinoClosedAmount += Double.valueof(agr.get('amt'));
                            w.rhinoClosedFileCount += integer.valueof(agr.get('file'));
                        }else if(String.valueof(agr.get('businessunit')) == 'ELFI'){
                            
                            w.elfiClosedAmount += Double.valueof(agr.get('amt'));
                            w.elfiClosedFileCount += integer.valueof(agr.get('file'));
                        }
                        
                        agrMap.put(String.ValueOf(String.ValueOf(agr.get('lawyerId')) + '-' + agr.get('lawyer')) +'-'+String.ValueOf(agr.get('firm')), w);
                        
                    }
                }
                
                
				list<Wrapper> finalWrapper = new list<Wrapper>(agrMap.values());
				/* 
				list<Wrapper> finalWrapper = new list<Wrapper>(); 
                
                for(string key : agrMap.keyset()){

					// split the key to get lawyer and firm
					string lawyer = key.split('-')[0];
					string firm = key.split('-')[1];
                    
                    Wrapper w = agrMap.get(key);
                    
                    if(w == null) continue;
                    
                    finalWrapper.add(new Wrapper(lawyer,firm, w.rhinoCount, w.rhinoAmount, w.elfiCount, w.elfiAmount));
                    
                    
                }
                */
                
                system.debug('Wrapper records are:');
                system.debug(finalWrapper);
                
                return finalWrapper;

                //return aggResult;
            }
            return null;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownLawyerSalesCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Lawyer_Sales_Summary_View_All__c,Conga_Lawyer_Sales_Summary_Print_All__c from Drawdown__c limit 1];
    	return drawdown_conga_url;
    }

    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Lawyer_Sales_Summary_Report__c lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
            
            lsr.End_date__c = endDt;
            lsr.Start_Date__c = startDt;
            
            update lsr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
           // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            Lawyer_Sales_Summary_Report__c lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
            
            lsr.BusinessUnit__C = BusinessUnit;
            
            upsert lsr;

        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Lawyer_Sales_Summary_Report__c getCustomSetting(){
        Lawyer_Sales_Summary_Report__c Lsr = Lawyer_Sales_Summary_Report__c.getOrgDefaults();
        return Lsr;
    }
    
    public class Wrapper {
        @AuraEnabled
        string lawyer {get; set;}
        @AuraEnabled
        string lawyerId {get; set;}
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
        decimal rhinoClosedAmount {get; set;}
        @AuraEnabled
        decimal rhinoAmount {get; set;}
        @AuraEnabled
        integer elfiFileCount {get; set;}
        @AuraEnabled
        integer elfiClosedFileCount {get; set;}
        @AuraEnabled        
        integer elfiOpptyCount {get; set;}
        @AuraEnabled
        decimal elfiClosedAmount{get; set;}
        @AuraEnabled
        decimal elfiAmount {get; set;}
        
        wrapper(string l, string lawrId, string f, string frmId, integer rc, integer rcc, integer roc, decimal ra, integer ec, integer ecc, integer eoc, decimal ea){
            
            lawyer = l;
            lawyerId = lawrId;
            firm = f;
            firmId = frmId;
            
            rhinoFileCount = rc;
            rhinoClosedFileCount = rcc;
            rhinoOpptyCount = roc;
            rhinoAmount = ra;
            
            elfiFileCount = ec;
            elfiClosedFileCount = ecc;
            elfiOpptyCount = eoc;
            elfiAmount = ea;
        }
        
    }
}