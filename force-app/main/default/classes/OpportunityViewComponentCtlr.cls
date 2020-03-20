/**
 * @File Name          : OpportunityViewComponentCtlr.cls
 * @Description        : 
 * @Author             : Victoria Ventura
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 6/8/2019, 10:31:14 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/12/2019, 10:07:44 AM   Seth Boyd     Initial Version
**/
public class OpportunityViewComponentCtlr {

    public static Opportunity oppInfo {get;set;}
    public static List<Drawdown__c> drawDownList {get;set;}
    
    /******************* Method to return all details from the opportunity *********************/
    @AuraEnabled
    public static Opportunity getOpportunityDetails(String oppId, String accId) {
       system.debug(oppid + '  '  + accId);
        oppInfo = new Opportunity();
        try{
        if(String.isEmpty(oppId))
        {
            List<Opportunity> lastOppty = [select id, Lawyer__c, Law_Firm__c, Date_Financing_Statement_Done__c ,
                                           Date_Financing_Statement_Expires__c, Assessment_Provider__c, Assessment_Provider__r.Name,
                                           Date_Applied__c, Have_you_ever_declared_bankruptcy__c, Bankruptcy_Details__c,
                                           Other_Lawyer_Law_Firm_that_acted__c, NOTE_For_Paralegals__c, Date_of_Loss__c,
                                           What_Happened_from_W2L__c, Nature_of_Injury_from_W2L__c, Existing_Litigation_Loans__c,
                                           Funding_Requested__c, Pre_Existing_Loan_Amount__c, Name_of_Lender__c
                                           from Opportunity
                                           where AccountId = :accId AND Loan_Requests__c != null AND Lawyer__c != null ORDER BY Loan_Requests__c DESC LIMIT 1];
            oppInfo.Name = ''; 
            oppInfo.StageName='Prospecting';
            oppInfo.closeDate = Date.today(); 
            oppInfo.AccountId=accId;
            oppInfo.Minimum_Interest_Period__c = '6 months';
            oppInfo.Fee_Calculation_Method__c = 'Fixed Amount';
            
            User currentUser = [Select Id, Name from User where id=:userinfo.getUserId()];
            oppInfo.Owner = currentUser;
            oppInfo.OwnerId = currentUser.Id;
            oppInfo.Lawyer__c = (lastOppty.isEmpty() ? null : lastOppty[0].Lawyer__c);
            oppInfo.Law_Firm__c = (lastOppty.isEmpty() ? null : lastOppty[0].Law_Firm__c);
            oppInfo.Assessment_Provider__c = null;
            oppInfo.Date_Financing_Statement_Done__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_Financing_Statement_Done__c);
            oppInfo.Date_Financing_Statement_Expires__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_Financing_Statement_Expires__c);
            
            oppInfo.Date_Applied__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_Applied__c);
            oppInfo.Have_you_ever_declared_bankruptcy__c = (lastOppty.isEmpty() ? null : lastOppty[0].Have_you_ever_declared_bankruptcy__c);
            oppInfo.Bankruptcy_Details__c = (lastOppty.isEmpty() ? '' : lastOppty[0].Bankruptcy_Details__c);
            oppInfo.Other_Lawyer_Law_Firm_that_acted__c = (lastOppty.isEmpty() ? '' : lastOppty[0].Other_Lawyer_Law_Firm_that_acted__c);
            oppInfo.NOTE_For_Paralegals__c = (lastOppty.isEmpty() ? '' : lastOppty[0].NOTE_For_Paralegals__c);
            oppInfo.Date_of_Loss__c = (lastOppty.isEmpty() ? null : lastOppty[0].Date_of_Loss__c);
            oppInfo.What_Happened_from_W2L__c = (lastOppty.isEmpty() ? '' : lastOppty[0].What_Happened_from_W2L__c);
            oppInfo.Nature_of_Injury_from_W2L__c = (lastOppty.isEmpty() ? '' : lastOppty[0].Nature_of_Injury_from_W2L__c);
            oppInfo.Existing_Litigation_Loans__c = (lastOppty.isEmpty() ? null : lastOppty[0].Existing_Litigation_Loans__c);
            oppInfo.Funding_Requested__c = (lastOppty.isEmpty() ? null : lastOppty[0].Funding_Requested__c);
            oppInfo.Pre_Existing_Loan_Amount__c = (lastOppty.isEmpty() ? null : lastOppty[0].Pre_Existing_Loan_Amount__c);
            oppInfo.Name_of_Lender__c = (lastOppty.isEmpty() ? '' : lastOppty[0].Name_of_Lender__c);
        }
        else
        {
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            
            // Adding some extra related field information
            lstFields.add('Assigned_To__r.Name');
            lstFields.add('Primary_Contact__r.Name');
            lstFields.add('Owner.Name');
            lstFields.add('Law_Firm__r.Name');
            lstFields.add('Lawyer__r.Name');
            lstFields.add('Scenario__r.Name');
            lstFields.add('Assessment_Provider__r.Name');
            
            // Building the query
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ' FROM Opportunity WHERE Id =: oppId';
            
            // Still need to handle exceptions
            oppInfo = Database.query(strQuery);   
        }
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            system.debug(e.getStackTraceString() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        system.debug('## oppInfo: ' + oppInfo);        
        return oppInfo;
    }
    
    /******************* Method to get dependent picklist values *********************/
    @AuraEnabled
    public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
        return DependentPicklistCtrl.getDependentMap(objDetail, contrfieldApiName, depfieldApiName);   
    }     
    
    /******************* Method to get contact history of the account *********************/
    @AuraEnabled
    public static Contact_History__c getContactHistory(String accountId) {
        Contact contact = CustomerViewComponentCtlr.getLastContact(accountId);        
        Contact_History__c contactHistory = new Contact_History__c();
        if(contact != null){
            contactHistory = CustomerViewComponentCtlr.getContactHistorySingle(contact.Id);
        }
        return contactHistory;
    }
    
    /******************* Method to get the critical dates list *********************/
    /*@AuraEnabled
    public static List<Critical_Date__c> getCriticalDatesList(String accountId) {
        List<Critical_Date__c> criticalDateList = new List<Critical_Date__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Critical_Date__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Critical_Date__c WHERE Account__c =: accountId order by Date__c';
        
        // Still need to handle exceptions
        criticalDateList = Database.query(strQuery);        
        system.debug('## criticalDateList: ' + criticalDateList);        
        return criticalDateList;        
    }*/ 
    
    
        /******************* Method to get the drawdowns list *********************/
        @AuraEnabled
        public static List<Drawdown__c> getDrawdownPaymentsList(String oppId) {
            drawDownList = new List<Drawdown__c>();
            
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Drawdown__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            
            // Building the query
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ' FROM Drawdown__c WHERE Opportunity__c =: oppId AND Payment_Method__c = \'Payment\' order by Date__c, CreatedDate';
            
            // Still need to handle exceptions
            drawDownList = Database.query(strQuery);        
            system.debug('## drawDownList: ' + drawDownList);        
            return drawDownList;        
        }    
        
    /******************* Method to get the drawdowns list *********************/
    @AuraEnabled
    public static List<Drawdown__c> getDrawdownList(String oppId) {
        drawDownList = new List<Drawdown__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Drawdown__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Drawdown__c WHERE Opportunity__c =: oppId order by Date__c ASC, Name ASC';
        
        // Still need to handle exceptions
        drawDownList = Database.query(strQuery);        
        system.debug('## drawDownList: ' + drawDownList);        
        return drawDownList;        
    }
    
    /******************* Method to save opportunity *********************/
    @AuraEnabled
    public static Opportunity saveOpportunity(Opportunity opportunity){
        try {
            System.debug('Opportunity is '+opportunity);
            system.debug('opportunity Compounding_Interest__c: ' + opportunity.Compounding_Interest__c);
            upsert opportunity;  
            
            List<OpportunityContactRole> roles = [Select id, OpportunityId, ContactId , isPrimary
                                                  FROM OpportunityContactRole
                                                  WHERE OpportunityId = :opportunity.Id AND
                                                  ContactId = :opportunity.Primary_Contact__c];
            OpportunityContactRole upsertable;
            if(!roles.isEmpty())		upsertable = roles[0];
            if(upsertable != null)
            {
                if(upsertable.IsPrimary == false)
                {
                    upsertable.IsPrimary = true;
                    upsert upsertable;
                }
            }
            else
            {
                upsertable = new OpportunityContactRole(OpportunityId = opportunity.Id, 
                                                        ContactId = opportunity.Primary_Contact__c,
                                                        isPrimary = true);
                upsert upsertable;
            }
            
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            system.debug(e.getStackTraceString() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('Error:'+e.getMessage());
        }
            
        return opportunity;
    }    
    
    /******************* Method to delete Critical Date *********************/
    /*@AuraEnabled
    public static void deleteCriticalDate(String recordId){
        Critical_Date__c cd = new Critical_Date__c();
        cd.Id = recordId;        
        try{
            delete cd;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }    */
    
    /******************* Method to save CriticalDates list *********************/
    /*@AuraEnabled
    public static void saveCriticalDateList(List<Critical_Date__c> criticalDateList){
        try{
            upsert criticalDateList;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }*/
    
    /******************* Method to save drawdowns list *********************/
    @AuraEnabled
    public static void saveNewDrawdownList(List<Drawdown__c> drawDownNewList){
        try{
            update drawDownNewList;
        }catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    
    /******************* Method to insert a new drawdown *********************/
    @AuraEnabled
    public static void insertNewDrawdown(String oppId){
        try{
            Drawdown__c drawdown = new Drawdown__c(Opportunity__c=oppId);            
            insert drawdown;
            DrawdownTriggerHandler.mergeAdminFees(new Set<Id>{oppId});
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    
    /******************* Method to insert a new payment drawdown *********************/
    @AuraEnabled
    public static void insertNewPaymentDrawdown(String oppId){
        try{
            Drawdown__c drawdown = new Drawdown__c(Opportunity__c=oppId, Payment_Method__c='Payment');            
            insert drawdown;
            DrawdownTriggerHandler.mergeAdminFees(new Set<Id>{oppId});
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }        
    
    /******************* Method to insert a new service provider drawdown *********************/
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> insertNewServiceProviderDrawdown(String oppId, String serviceId) {

        Drawdown__c newDrawdown = new Drawdown__c(
            Opportunity_Service_Provider__c = serviceId,
            Type__c = 'Treatment Loan',
            Amount__c = 0,
            Opportunity__c = oppId,
            Date__c= Date.today()
        );
        try{
            insert newDrawdown;
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }

        return getServiceProviders(oppId);
    }    
    
    /******************* Method to delete a drawdown item *********************/
    @AuraEnabled
    public static List<Drawdown__c> deleteDrawdownRecord(String drawdownId, String oppId){
        try{
            Drawdown__c dd = new Drawdown__c(Id=drawdownId);
            delete dd;
            return getDrawdownList(oppId);
        }
        catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> deleteServiceProviderDrawdownRecord(String drawdownId, String oppId){
        Drawdown__c dd = new Drawdown__c(Id=drawdownId);
        try{
            delete dd;        
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getServiceProviders(oppId);
    }    
    
    @AuraEnabled
    public static List<Opportunity> deleteReassessments(String reassessmentsId, String oppId){
        try{
            deleteOpp(reassessmentsId);   
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getReAssessmentOpportunities(oppId);
    }  
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> deleteTreatmentItem(String treatmentId, String oppId){
        Opportunity_Service_Provider__c svc = new Opportunity_Service_Provider__c(Id=treatmentId);  
        try{
            delete svc;
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        return getServiceProviders(oppId);
    } 

    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> addTreatmentItem(String oppId, Account firm){
        if(firm != null){
            system.debug('Opp Id ' + oppId + ' Firm Id ' + firm.Id);
            Opportunity_Service_Provider__c svc = new Opportunity_Service_Provider__c(Opportunity__c=oppId, Service_Provider_Facility__c=firm.Id);   
            try{
                insert svc;
            } catch (DMLException e){
                throw new AuraHandledException('Error:'+e.getDmlMessage(0));
            } catch (Exception e){
                throw new AuraHandledException('Error:'+e.getMessage());
            }            
        } else {
            throw new AuraHandledException('Please select the firm before adding a new service provider.'); 
        }
        
        return getServiceProviders(oppId);
    }    
    
    @AuraEnabled
    public static void saveReassessmentsList(List<Opportunity> reAssessmentList){
        try{
            update reAssessmentList;
        }
        catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }    
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> getServiceProviders(String oppId){                             
        List<Opportunity_Service_Provider__c> spList = new List<Opportunity_Service_Provider__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Opportunity_Service_Provider__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        // Adding some extra related field information
        lstFields.add('Service_Provider_Facility__r.Name');
        
        // Building the query
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        
        strQuery += ', (SELECT Id, Name, Amount__c, Date__c, CreatedDate, Payment_Method__c, Reference_Notes__c, CHQ__c, EFT__c, Scheduled_Payment__c, Can_Be_Reversed__c'+
                     ' FROM Drawdowns__r' +
                     ' ORDER BY Date__c ASC, Name ASC)';
        strQuery += ', (SELECT Id, Name, Date_Received__c, Provider_Invoice_Number__c, Amount__c, Amount_Paid__c, CreatedDate, Paid__c, Paid_Date__c, Payment_Amount_Available__c, Payment_Requested__c, Status__c, Scheduled_Payment__c'+
                     ' FROM Opportunity_Service_Provider_Invoices__r' +
                     ' ORDER BY Paid__c ASC, Paid_Date__c DESC, CreatedDate DESC)';
        strQuery += ' FROM Opportunity_Service_Provider__c WHERE Opportunity__c =: oppId ORDER BY CreatedDate DESC';
        system.debug('strQuery' + strQuery);
        // Still need to handle exceptions
        spList = Database.query(strQuery);        
        system.debug('## spList: ' + spList);        
        return spList;
                             
    }
    
    @AuraEnabled
    public static List<Opportunity> getReAssessmentOpportunities(String oppId){
        List<Opportunity> rOppList = new List<Opportunity>();      
        
        // Building the query
        String strQuery = 'SELECT Id, Name, Amount, CloseDate, StageName,Funding_Requested__c, NextStep';
        strQuery += ' FROM Opportunity WHERE Re_Assessed_Loan__c =: oppId ORDER BY CloseDate DESC';
        
        // Still need to handle exceptions
        rOppList = String.isEmpty(oppId) ? null : Database.query(strQuery);        
        system.debug('## rOppList: ' + rOppList);        
        return rOppList;                                     
    }
    
    @AuraEnabled
    public static void deleteOpp(String oppId){
        try{
            if(oppId != null){
                Opportunity opp = new Opportunity(Id=oppId);
                delete opp;
            }
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Opportunity_Service_Provider__c> saveProvidersList(String jsonStr, String oppId){
        try {
            List<Opportunity_Service_Provider__c> providers = (List<Opportunity_Service_Provider__c>)JSON.deserialize(jsonStr, List<Opportunity_Service_Provider__c>.class);
            for (Opportunity_Service_Provider__c prov : providers) {
                update prov;
            }
            //update providers;            
            system.debug('providers: ' + providers);
            
            // collect drawdowns
            List<Drawdown__c> updateDrawdowns = new List<Drawdown__c>();
            for(Opportunity_Service_Provider__c sp: providers){
                system.debug('sp.Drawdowns__r ' + sp.Drawdowns__r);
                if (sp.Drawdowns__r.size() > 0) {
                    updateDrawdowns.addAll(sp.Drawdowns__r);
                }
            }
            system.debug('@@ updateDrawdowns' + updateDrawdowns);
            
            if (updateDrawdowns.size() > 0) {
                update updateDrawdowns;
            }
        } catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        
        return getServiceProviders(oppId);
    }  
    
    @AuraEnabled(cacheable=true)
    public static List < String > getPickListValues(String objectType, String field)
    {
        system.debug('#### getPickListValues of field >>> ' +field);
        List < String > allOpts = new List < String > ();
        // Get the object type of the SObject.
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(objectType);
        
        // Describe the SObject using its object type.
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        
        // Get a map of fields for the SObject
        map < String, Schema.SObjectField > fieldMap = objDescribe.fields.getMap();
        
        // Get the list of picklist values for this field.
        list < Schema.PicklistEntry > values =
            fieldMap.get(field).getDescribe().getPickListValues();
        
        // Add these values to the selectoption list.
        for (Schema.PicklistEntry a: values) {
            allOpts.add( a.getLabel() +'===SEPERATOR==='+ a.getValue());
            //allOpts.add( a.getValue());
        }
        system.debug('allOpts ---->' + allOpts);
        //allOpts.sort();
        return allOpts;
    }

     /**
    * @description Method to delete payments on scheduled status
    * @param opportunityId Id of the opportunity record
    * @return void
    **/
    @AuraEnabled
    public static void deletePayments(Id opportunityId){
        if(opportunityId != null){
            delete [SELECT Id FROM Scheduled_Payment__c WHERE Opportunity__c =: opportunityId AND Status__c = 'Scheduled' AND Payment_Type__c = 'Scheduled Facility' LIMIT 30000];
        }
    }


    @AuraEnabled(cacheable=false)
    public static Bank_Account__c[] getBankAccountOptions(Id oppId) {
        Opportunity opp = new Opportunity();
        List<Bank_Account__c> bankAccounts = new List<Bank_Account__c>();
        try{
            if(!String.isEmpty(oppId) && oppId != null){
            opp = [Select AccountId From Opportunity Where Id = :oppId];
            bankAccounts = [Select Id, Name, Is_Primary_Account__c From Bank_Account__c Where Client__c = :opp.AccountId Order By Is_Primary_Account__c DESC, Name ASC];
            }
        }catch (DMLException e){
            system.debug(e.getStackTraceString() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (Exception e){
            system.debug(e.getStackTraceString() + ' - ' + e.getLineNumber());
            throw new AuraHandledException('Error:'+e.getMessage());
        }
        
        return bankAccounts;
    }

    @AuraEnabled(cacheable=false)
    public static Opportunity getUpdatedAmounts(Id oppId) {
        return [
            Select 
                Amount_Available_for_Scheduled_Payments__c,
                Amount_Currently_Allocated__c,
                Amount_Unallocated__c
            From Opportunity
            Where Id = :oppId
            Limit 1];
    }
    
    @AuraEnabled
    public static void setLatestDiscountRateLaywer(Id oppId, Id assessmentProviderId, Id lawyerId){
        try{
            If(oppId != null && assessmentProviderId != null && lawyerId != null){
                List<Assessment_Provider_Schedule__c> discountSchedule = [SELECT Id, Discount__c, Assessment_Provider__c, Lawyer__c, CreatedDate,
                                                                          Rebate_Discount__c, Rebate_Period__c
                                                                          FROM Assessment_Provider_Schedule__c
                                                                          WHERE Assessment_Provider__c = :assessmentProviderId
                                                                          AND Lawyer__c = :lawyerId order by CreatedDate desc];
                Opportunity opp = new Opportunity();
                opp.Id = oppId;
                if(!discountSchedule.isEmpty()){
                    opp.Discount_Rate__c = discountSchedule[0].Discount__c;
                    opp.Rebate_Discount__c = discountSchedule[0].Rebate_Discount__c;
                    string periodStr = discountSchedule[0].Rebate_Period__c;
                    List<String> splited = periodStr != null? periodStr.split(' ') : new List<String>();
                    opp.Rebate_Period__c = !splited.isEmpty()? Integer.valueOf(splited[0]): null;
                }else{
                    opp.Rebate_Discount__c = 0;
                    opp.Rebate_Period__c = null;
                    opp.Discount_Rate__c = 0;
                    Assessment_Provider_Schedule__c dSchedule = new Assessment_Provider_Schedule__c(
                        Discount__c = 0,
                        Rebate_Discount__c = 0,
                        Rebate_Period__c = null,
                        Assessment_Provider__c = assessmentProviderId,
                        Lawyer__c = lawyerId
                    );
                    
                    insert dSchedule;
                }
                update opp;
            }else{
                String message = '';
                message += oppId == null? 'Opportunity does not exit. Please save opportunity first.' : assessmentProviderId == null? 
                    'No Assessment Provider found. Please select Assessment provider first.' : lawyerId == null? 
                        'No Lawyer found. Please select lawyer first.' : 'Unknown Error.';
                AuraHandledException e = new AuraHandledException(message);
                e.setMessage(message);
                throw  e;
            }
        }catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }
}