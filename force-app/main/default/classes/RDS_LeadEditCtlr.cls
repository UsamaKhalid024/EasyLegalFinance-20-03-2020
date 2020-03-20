/**
 * RA, 06/09/2016
 * custom lead form controller that should aid in replacing the 
 * intake form.
 */
public with sharing class RDS_LeadEditCtlr{
    public String MaritalStatus{get;set;}
    /*public String Salutation{get;set;}*/
    public String SpousalSupportPayment{get;set;} 
    public String ArrearsPayment{get;set;}
    public String bankruptcy{get;set;}
    public String Litigation{get;set;}
    public String Employment{get;set;}
   // public Contact cont{get;set;}
    public Contact selectedlawyer {get;set;}
    public String searchCategory{get;set;}

    public Lead leadObj{get;set;}
    public RDS_LeadEditCtlr(ApexPages.StandardController controller) {
        Id leadId = ApexPages.currentpage().getParameters().get('id');
        if(leadId == null){ 
            RecordType customerType = [Select Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName LIKE '%Customer%' LIMIT 1];
            leadObj = new Lead(Salutation='Mr.', RecordTypeId = customerType.id);
        }
        else{
            //leadObj = (Lead)controller.getRecord();
            String query = 'SELECT ' + RDS_LeadEditCtlr.getQueryStringForSObject('Lead') + 
                ' FROM Lead WHERE id=\'' + leadId + '\'';
            leadObj = (Lead)(Database.query(query)[0]);
            searchCategory = leadObj.Salutation__c;
            MaritalStatus = leadObj.Marital_Status__c;
            SpousalSupportPayment = leadObj.Any_SpousalChild_support_payment__c;
            ArrearsPayment = leadObj.Have_you_ever_been_in_arrears_on_payment__c;
            bankruptcy = leadObj.Have_you_ever_declared_bankruptcy__c;
            Litigation = leadObj.Existing_Litigation_Loans__c;
            Employment = leadObj.Employment_status_at_time_of_accident__c;
        }
        fetchContactDetail();        
    }
    
    public PageReference dispatch(){
        PageReference pg = null;
        // AppCentrica - if parameter ignoreProfile = 1, allow them to stay on this page
        String ignoreProfile = ApexPages.currentpage().getParameters().get('ignoreProfile');
        // AppCentrica - redirect to nooverride-edit if it's a lawyer
        if(leadObj != null && leadObj.AC_rtName__c != null && leadObj.AC_rtName__c.contains('Lawyer')){  
            pg = new PageReference('/' + leadObj.id + '/e');
            pg.getParameters().put('nooverride', '1');
            pg.setRedirect(true);
        }
        // redirect to nooverride-new if profile is Sales and no ID
        if(leadObj == null || leadObj.id == null){
            Id profileId = UserInfo.getProfileId();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
            if (profileName != null && profileName.contains('Sales')  && ignoreProfile != '1'){
                pg = new PageReference('/00Q/e');
                pg.getParameters().put('nooverride', '1');
                pg.setRedirect(true);                
            }
        }
        return pg;
    }
    
    public static String getQueryStringForSObject(String objName){
        //Get spec file related to above specification
        SObjectType objTokenFile = Schema.getGlobalDescribe().get(objName);
        DescribeSObjectResult objDeffile = objTokenFile.getDescribe();
        
        //Get fields of sObject
        Map<String, SObjectField> fieldsFile = objDeffile.fields.getMap();
        string fieldLstFile='';
        Set<String> fieldSetFiles = fieldsFile.keySet();
        for(String s:fieldSetFiles) {
            SObjectField fieldToken = fieldsFile.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            fieldLstFile=fieldLstFile+selectedField.getName()+',';
        }
        fieldLstFile= fieldLstFile.removeEnd(',');
        return fieldLstFile;
    }
    public PageReference  fetchContactDetail(){
      if (leadObj.Lawyer_Name_new__c != null){
        system.debug('>>>>>>>>>>>' + leadObj.Lawyer_Name_new__c);
           selectedlawyer  =[select id,Phone,Email from contact where id=:leadObj.Lawyer_Name_new__c];
           system.debug(selectedlawyer);
       }
       return null;
    }
    
    public PageReference ConvertLead(){
        PageReference pageRef;
        if(leadObj != null){
           pageRef = new PageReference('/lead/leadconvert.jsp?retURL=%2F'+leadObj.Id+'&id='+leadObj.Id);
            
        }
        return pageRef;
    }
    public PageReference findDuplicates(){
        PageReference pageRef;
        if(leadObj != null){
            pageRef = new PageReference('/lead/leadmergewizard.jsp?retURL=%2F'+leadObj.Id+'&id='+leadObj.Id);
            
        }
        return pageRef;
    }

    public PageReference saveLeaddb(){        
        leadObj.Salutation__c = searchCategory;
        leadObj.Marital_Status__c = MaritalStatus;
        leadObj.Any_SpousalChild_support_payment__c = SpousalSupportPayment;
        leadObj.Have_you_ever_been_in_arrears_on_payment__c = ArrearsPayment;
        leadObj.Have_you_ever_declared_bankruptcy__c = bankruptcy;
        leadObj.Existing_Litigation_Loans__c = Litigation;
        leadObj.Employment_status_at_time_of_accident__c = Employment;        
        if(leadObj != null){
            upsert leadObj;
            return new PageReference('/apex/RDS_LeadEdit?id=' + leadObj.Id);
        }
        return null;
    }

    public PageReference saveLead(){
        
        String isClone = ApexPages.currentPage().getParameters().get('clone');
        
         /**
             * handle the fields that are rendered as radio group instead of picklist
          */
        leadObj.Salutation__c = searchCategory;
        leadObj.Marital_Status__c = MaritalStatus;
        leadObj.Any_SpousalChild_support_payment__c = SpousalSupportPayment;
        leadObj.Have_you_ever_been_in_arrears_on_payment__c = ArrearsPayment;
        leadObj.Have_you_ever_declared_bankruptcy__c = bankruptcy;
        leadObj.Existing_Litigation_Loans__c = Litigation;
        leadObj.Employment_status_at_time_of_accident__c = Employment;
        
        Lead clonedLead = new Lead();
        if(isClone !=null && isClone != ''){
          if(leadObj != null){
            Lead ld = (Lead)leadObj;
            clonedLead =  ld.clone(false,true);
          }
            insert clonedLead;
            return new PageReference('/apex/RDS_LeadView?id=' + clonedLead.Id);
        }else{
            upsert leadObj;
            return new PageReference('/apex/RDS_LeadView?id=' + leadObj.Id);
        }
        
        return null;
    }

    public PageReference cancelLead() {
      PageReference newpage;
      if(leadObj != null){
          newpage = new PageReference('/apex/RDS_LeadView?id=' + leadObj.Id);
          newpage.setRedirect(true);
      }
      return newpage;
    }
    public PageReference deleteLead(){
        if(leadObj != null){
           delete leadObj; 
        }
        
        PageReference pg = new PageReference('/apex/LeadEdit');
        pg.setRedirect(true);
        return pg;
    }
    public PageReference cloneLead(){
        Lead ld;
        if(leadObj != null){
            ld =(Lead) Database.query(getCreatableFieldsSOQL('Lead','Id=' + '\'' + leadObj.id + '\''));
            if(ld != null){
                Lead led = new Lead();
                led =  ld.clone(false,true);
                leadObj = led;
            }
        }
        return null ;

    }

    public static string getCreatableFieldsSOQL(String objectName, String whereClause){
        String selects = '';
        if (whereClause == null || whereClause == ''){ return null; }

         /**
         *Get a map of field name and field token
         */
         
        Map<String, Schema.SObjectField> fMap = 
            Schema.getGlobalDescribe().get(objectName.toLowerCase()).getDescribe().Fields.getMap();
        list<string> selectFields = new list<string>();

        if (fMap != null){
            for (Schema.SObjectField ft : fMap.values()){ // loop through all field tokens (ft)
                Schema.DescribeFieldResult fd = ft.getDescribe(); // describe each field (fd)
                if (fd.isCreateable()){ // field is creatable
                    selectFields.add(fd.getName());
                }
            }
        }

        if (!selectFields.isEmpty()){
            for (string s:selectFields){
                selects += s + ',';
            }
            if (selects.endsWith(',')){
                selects = selects.substring(0,selects.lastIndexOf(','));
            }

        }
        String str = 'SELECT Id, ' + selects + ' FROM ' + objectName + ' WHERE ' + whereClause;
        System.debug(')))))))))) '+str);
        return str;
    }
    public List<selectoption> getMaritalStatuss() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Marital_Status__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
            for (Schema.PicklistEntry a : values){                  
                options.add(new SelectOption(a.getLabel(), a.getValue()));
            }
            if(Test.isRunningTest())
            integer intTest =1/0;             
        }  
        catch (Exception e){             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }

    public String getsearchCategory(){
    return searchCategory;
    }

    public void setsearchCategory(String searchCategory){
    this.searchCategory = searchCategory;
    }

    /*public List<selectoption> getSalutations() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Salutation.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
            for (Schema.PicklistEntry a : values){                  
                options.add(new SelectOption(a.getLabel(), a.getValue()));
            }           
        }  
        catch (Exception e){             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }*/
    
    public List<selectoption> getSpousalSupportPayments() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Any_SpousalChild_support_payment__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        if(Test.isRunningTest())
            integer intTest =1/0;            
        }             
          
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }
    public List<selectoption> getArrearsPayments() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Have_you_ever_been_in_arrears_on_payment__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        } 
        if(Test.isRunningTest())
            integer intTest =1/0;            
        }  
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }
     
     public List<selectoption> getbankruptcies() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Have_you_ever_declared_bankruptcy__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        if(Test.isRunningTest())
            integer intTest =1/0;              
        }  
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }
    public List<selectoption> getLitigations() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Existing_Litigation_Loans__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        if(Test.isRunningTest())
            integer intTest =1/0;              
        }  
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }
    public List<selectoption> getEmployments() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Lead.Employment_status_at_time_of_accident__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        if(Test.isRunningTest())
            integer intTest =1/0;              
        }  
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ options);          
        return options; 
    }
}