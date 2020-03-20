public with sharing class LeadViewComponentCtlr {
    public static Lead leadInfo {get;set;}
    
    @AuraEnabled
    public static List<String> getPickListValues(String objectType, String field)
    {
        return OpportunityViewComponentCtlr.getPickListValues(objectType, field);
    }
    
    @AuraEnabled
    public static Lead getLeadInfo(String leadId) {
        leadInfo = new Lead();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Lead.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Lawyer_Name_new__r.Name');
        lstFields.add('Law_Firm_Name_new__r.Name');
        lstFields.add('Law_Firm_Name_new__r.BillingCity');
        lstFields.add('Law_Firm_Name_new__r.BillingState');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Lead WHERE Id =: leadId';
        
        // Still need to handle exceptions
        leadInfo = Database.query(strQuery);
        
        system.debug('## leadInfo: ' + leadInfo);
        
        return leadInfo;
    }  
    
    @AuraEnabled
    public static Map<String,List<String>> getLeadPicklistData() {        
        Map<String,List<String>> picklistMap = new Map<String,List<String>>();
        Map<String,Schema.SObjectField> fMap = Lead.sObjectType.getDescribe().fields.getMap(); 
        for(SObjectField field:fMap.values()){
            Schema.DescribeFieldResult des = field.getDescribe();
            if(des.getType() == Schema.DisplayType.PICKLIST)
            {
                List<Schema.PicklistEntry> ple = des.getPicklistValues();
                List<String> picklistvals = new List<String>();
                for( Schema.PicklistEntry pickListVal : ple)
                {
                    picklistvals.add(pickListVal.getValue());
                }
                picklistMap.put(des.getName(),picklistvals);
            }
        }
        System.debug('FM: '+picklistMap);
        return picklistMap;
    } 
    
    @AuraEnabled
    public static String cloneLead(String leadId) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Lead.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Lead WHERE Id =: leadId';
        
        // Still need to handle exceptions
        Lead led = Database.query(strQuery);
        Lead clonedLead = led.clone(false, true, true, true);
        clonedLead.LastName += ' (clone)';
        insert clonedLead;
        return clonedLead.Id;
    } 
    
    @AuraEnabled
    public static void deleteLead(String leadId){
        if(leadId != null){
            Lead lead = new Lead(Id=leadId);
            delete lead;
        }
    }
    
    @AuraEnabled
    public static Map<String,String> getLeadFieldsMap(String leadId){
        
        Map<String,String> fieldsMap = new Map<String,String>();
        Map<String,Schema.SObjectField> fMap = Lead.sObjectType.getDescribe().fields.getMap(); 
        for(SObjectField field:fMap.values()){
            fieldsMap.put(field.getDescribe().getName(), field.getDescribe().getLabel());
        }
        
        System.debug('FM: fieldsMap'+fieldsMap);
        return fieldsMap;
    }

    @AuraEnabled
    public static Lead saveLead(Lead lead) {
        update lead;
        return lead;
    }    
}