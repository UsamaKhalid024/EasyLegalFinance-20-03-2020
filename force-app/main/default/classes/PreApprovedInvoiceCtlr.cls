public with sharing class PreApprovedInvoiceCtlr {
    
    public String businessUnit{get;set;}
    public String searchText{get;set;}
    public String contentType{get;set;}
    public String renderAs{get;set;}
    
    public class PreApprovedInvoiceWrapper{
        @AuraEnabled
        public string lawyer {get; set;}
        @AuraEnabled
        public string lawyerId {get; set;}
        @AuraEnabled
        public string firm {get; set;}
        @AuraEnabled
        public string firmId {get; set;}        
        @AuraEnabled
        public string assessmentProvider {get; set;}
        @AuraEnabled
        public string assessmentProviderId {get; set;}
        @AuraEnabled
        public Date preApprovedDate{get;set;}
        
        @AuraEnabled
        public Decimal amountElfi{get;set;}
        @AuraEnabled
        public Decimal amountRhino{get;set;}
        
        @AuraEnabled
        public Decimal availableCredit{get;set;}
        
        @AuraEnabled
        public Boolean checked {get; set;}
       
        
        public PreApprovedInvoiceWrapper(){
            lawyer = '';
            lawyerId = '';
            firm = '';
            firmId = '';  
            assessmentProvider = '';
            assessmentProviderId = '';
            preApprovedDate = null;
            amountElfi = 0;
            amountRhino = 0;
            availableCredit = 0;
            checked = false;
        }
    }
    
    public PreApprovedInvoiceCtlr(){
        contentType = '';
        renderAs = '';
        string businessUnitParam = Apexpages.currentPage().getParameters().get('businessUnit');
        searchText = Apexpages.currentPage().getParameters().get('searchByName');        
        this.businessUnit = businessUnitParam != null && !String.isEmpty(businessUnitParam)? businessUnitParam : 'ELFI';
        
        String paramContentType = ApexPages.currentPage().getParameters().get('ContentType');
        
        if(paramContentType == 'PDF'){
            renderAs = 'PDF';
        }else{
            contentType = 'application/x-excel#Pre-ApprovedInvoices.xls';
        }
        
    }
    
    @AuraEnabled
    public static List < String > getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    public List<PreApprovedInvoiceWrapper> getPreApprovedInvoicesVF(){
        return getPreApprovedInvoices(this.searchText, this.businessUnit, 'Opportunity__r.Lawyer__r.Name','ASC');
    }
    
    @AuraEnabled
    public static List<PreApprovedInvoiceWrapper> getPreApprovedInvoices(String searchByName, String BusinessUnit, String field, String direction){
        
        Map<String, PreApprovedInvoiceWrapper>  preApprovedInvoicesMap = new Map<String, PreApprovedInvoiceWrapper>();
        
        try{
            String filterByBusinessUnit = '';
            string Rhino = 'Rhino';
            string Elfi = 'ELFI';
            String assessment = 'Assessment';
            
            if(BusinessUnit == 'ELFI'){                
                filterByBusinessUnit = 'ELFI';
            }else if(BusinessUnit == 'Rhino'){                
                filterByBusinessUnit = 'Rhino';
            }else if(BusinessUnit == 'Consolidated'){                
                filterByBusinessUnit = 'Consolidated';
            }
            
            String strQuery = '';
            strQuery += 'SELECT Opportunity__r.Lawyer__c lawyerId, Opportunity__r.Lawyer__r.Name lawyerName,';
            strQuery += ' Opportunity__r.Law_Firm__c lawfirmId, Opportunity__r.Law_Firm__r.Name lawfirm,';
            strQuery += ' Opportunity__r.Assessment_Provider__c assessmentProviderId, Opportunity__r.Assessment_Provider__r.Name assessmentProvider,';
            strQuery += ' Opportunity__r.Account.Business_Unit__c businessUnit, Max(Date__c) preApprovedDate,';
            strQuery += ' Sum(Amount__c) amt FROM Drawdown__c';
            strQuery += ' WHERE Opportunity__r.Stage_Status__c = \'Invoice Pre-Approved\'';
            strQuery += ' AND Opportunity__r.Type_of_Loan__c = \'Assessment\'';
            strQuery += ' AND Is_Rejected__c = false AND Reference_Notes__c != \'Payment Rejected\'';
            strQuery += (filterByBusinessUnit == 'Consolidated') ? 
                ' AND (Opportunity__r.Account.Business_Unit__c =:Elfi OR Opportunity__r.Account.Business_Unit__c =:Rhino)':
            ' AND Opportunity__r.Account.Business_Unit__c =:filterByBusinessUnit';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' AND (Opportunity__r.Lawyer__r.Name_Formula__c LIKE \'%' + searchByName + '%\''  : '';
            strQuery += !String.isEmpty(searchByName) && searchByName != null ? ' OR Opportunity__r.Law_Firm__r.Name LIKE \'%' + searchByName + '%\')'  : '';
            strQuery += ' GROUP BY Opportunity__r.Lawyer__c, Opportunity__r.Lawyer__r.Name, Opportunity__r.Law_Firm__c,';
            strQuery += ' Opportunity__r.Law_Firm__r.Name, Opportunity__r.Assessment_Provider__c, Opportunity__r.Assessment_Provider__r.Name, Opportunity__r.Account.Business_Unit__c';
            strQuery += ' ORDER BY ' + field + ' ' + direction + ' NULLS LAST';
            
            List<AggregateResult> aggrResult = Database.query(strQuery);
            
            Set<Id> lawyerIds = new Set<Id>();
            for(AggregateResult aggResult : aggrResult){
                lawyerIds.add((Id)aggResult.get('lawyerId'));
            }
            
            Map<Id, Contact> LawyersMap = new Map<Id, Contact>([
                SELECT Id, Available_Credit__c
                FROM Contact
                WHERE Id in :lawyerIds
            ]);
            
            PreApprovedInvoiceWrapper preApprovedInvoice = null;
            for(AggregateResult aggResult : aggrResult){
                
                String lawyerId = (String) aggResult.get('lawyerId');
                String lawfirmId = (String) aggResult.get('lawfirmId');
                String assessmentProviderId = (String) aggResult.get('assessmentProviderId');
                String key = lawyerId + '-' + lawfirmId + '-' + assessmentProviderId;
                
                preApprovedInvoice = new PreApprovedInvoiceWrapper();
                if(preApprovedInvoicesMap.containsKey(key))
                    preApprovedInvoice = preApprovedInvoicesMap.get(key);
                
                preApprovedInvoice.lawyerId = lawyerId;
                preApprovedInvoice.lawyer = (String) aggResult.get('lawyerName');
                preApprovedInvoice.firmId = lawfirmId;
                preApprovedInvoice.firm = (String) aggResult.get('lawfirm');
                preApprovedInvoice.assessmentProviderId = assessmentProviderId;
                preApprovedInvoice.assessmentProvider = (String) aggResult.get('assessmentProvider');
                
                preApprovedInvoice.preApprovedDate = aggResult.get('preApprovedDate') != null? Date.valueOf(aggResult.get('preApprovedDate')) : null;
                
                preApprovedInvoice.availableCredit = LawyersMap.ContainsKey(lawyerId)? LawyersMap.get(lawyerId).Available_Credit__c != null? LawyersMap.get(lawyerId).Available_Credit__c : 0 : 0;
                
                preApprovedInvoice.amountElfi += aggResult.get('businessUnit') == 'ELFI'? aggResult.get('amt') != null? (Decimal)aggResult.get('amt') : 0 : 0;
                preApprovedInvoice.amountRhino += aggResult.get('businessUnit') == 'Rhino'? aggResult.get('amt') != null? (Decimal)aggResult.get('amt') : 0 : 0;
                
                preApprovedInvoicesMap.put(key, preApprovedInvoice);
            }
            
           
            
        }catch(Exception e){
            system.System.debug(e.getMessage() + ' ' + e.getLineNumber());
            system.System.debug(e.getStackTraceString());
            throw new AuraHandledException(e.getMessage() + ' ' + e.getLineNumber());
        }
        
        return preApprovedInvoicesMap.values();
    }
}