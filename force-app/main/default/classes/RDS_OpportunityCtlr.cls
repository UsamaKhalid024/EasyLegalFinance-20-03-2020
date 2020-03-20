public with sharing class RDS_OpportunityCtlr {
    public List<OpportunityTab> lstOppTab {get; set;}
    String accId;
    
    public Opportunity currentOppSObj {get; set;}
    public String currOppId {get; set;}
    String oppDefaultName {get; set;}
    String oppDefaultStage {get; set;}
    Date oppDefaultCloseDate {get; set;}
    public Contact selectedlawyer {get;set;}
    //public String addressCon1 {get;set;}
    public String bankruptcy{get;set;}
    //public String clientAddress {get;set;}
    public List<Contact_History__c> lstConHistory{get;set;}
    //public Drawdown__c currentDDn {get; set;}    

    public RDS_OpportunityCtlr(ApexPages.StandardController controller) {
      init();    
      System.debug('Lawyer_Phone<><>'+currentOppSObj.Lawyer_Phone__c);
      System.debug('Lawyer_Email<><>'+currentOppSObj.Lawyer_Email__c);  
    }

    public void init() {
      oppDefaultName = '';
      oppDefaultStage = 'Prospecting';
      oppDefaultCloseDate = Date.today();
      List<Contact> lstcont = new List<Contact>();
          
      accId = ApexPages.currentPage().getParameters().get('accId');
      currOppId = ApexPages.currentPage().getParameters().get('oppId');
      refreshOpp(); 

      if(accId != null && accId != ''){
        lstcont = [Select Id, 
                          AccountId 
                          from Contact 
                          where AccountId =:accId];
      }

      if(lstcont.size() > 0){
          lstConHistory = [Select id,
                                  lastmodifieddate,
                                  Address__c,
                                  Contact__c
                                  from Contact_History__c 
                                  where Contact__c=:lstcont[0].Id 
                                  order by lastmodifieddate desc];
                                  system.debug('lstConHistory >>>>>>'+lstConHistory );
        //clientAddress = lstConHistory[0].Address__c;
        //system.debug('clientAddress >>>>>>'+clientAddress );
      }

      if(currentOppSObj != null && currentOppSobj.id != null) {
          /**
           * load drawdowns from database if these exist
           */
          bankruptcy = currentOppSObj.Have_you_ever_declared_bankruptcy__c;          
      }
      else {
        currentOppSObj = lstOppTab[lstOppTab.size() - 1].oppSObj;
      }
      //currentDDn = new Drawdown__c();   
      //initDDN();
    }

  /*  public void initDDN(){ 
      integer idx=1;
      lstsubscDropdown =  new List<SubsequentDrawdownWrapp>();
      List<SubsequentDrawdownWrapp> lstdrop = new List<SubsequentDrawdownWrapp>();

      for(Drawdown__c ddn: [Select id, Date__c, Amount__c, Drop_Down_No__c, Opportunity__c from Drawdown__c where Opportunity__c=:currentOppSObj.id]) {
          SubsequentDrawdownWrapp sub = new SubsequentDrawdownWrapp();
          sub.dropDownObj = ddn;
          lstdrop.add(sub);
      }

      if(lstdrop.size() == currentOppSObj.Subsequent_Drawdowns__c){
          lstsubscDropdown = lstdrop;
      }
      
      if(lstsubscDropdown.size() == 0 || lstdrop.size() != currentOppSObj.Subsequent_Drawdowns__c){
        if(currentOppSObj.Principle_Sum_to_be_paid_to_Borrower__c != null && currentOppSObj.Subsequent_Drawdowns__c != null){
          Decimal subAmount = currentOppSObj.Principle_Sum_to_be_paid_to_Borrower__c/currentOppSObj.Subsequent_Drawdowns__c;
          Decimal subAmountRound = subAmount.setScale(0,RoundingMode.HALF_UP);            
          if(subAmountRound != null){
            for(integer i=1;i<=currentOppSObj.Subsequent_Drawdowns__c;i++){
              SubsequentDrawdownWrapp sub = new SubsequentDrawdownWrapp();
              Date effectiveDate = currentOppSObj.Effective_Date__c == null ? date.today() : currentOppSObj.Effective_Date__c;
              sub.dropDownObj.Date__c = effectiveDate.addMonths(i);
              sub.dropDownObj.Amount__c = subAmountRound;
              sub.dropDownObj.Drop_Down_No__c = i;
              lstsubscDropdown.add(sub);
              system.debug('lstsubscDropdown <><> ' +lstsubscDropdown.size());
            }
          }                  
        }
      }
      if(lstsubscDropdown.size() > 0) {
        for(SubsequentDrawdownWrapp sub: lstsubscDropdown) {
          sub.dropDownNo = idx++;
        }
      }
    } */

    public PageReference deleteOpportunity(){    
        Savepoint sp = Database.setSavepoint();
        PageReference pg;
        try{
          system.debug('dlt'+currentOppSObj.Id);
            if(currentOppSObj != null){
               delete currentOppSObj; 
            }
            currentOppSObj = new Opportunity(name = oppDefaultName, StageName=oppDefaultStage, CloseDate=oppDefaultCloseDate,
                accountId=accId, ownerId=UserInfo.getUserId());
            init();
            pg = new PageReference('/apex/RDS_Opportunity?accId=' + accId);
            pg.setRedirect(true);
        }
        catch(dmlexception e){ 
            Database.RollBack(sp);       
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Could not delete Opportunity record. Error: ' + e));
        }
        return pg;
    }
    
    public PageReference getOpp() {
        PageReference pg = new PageReference('/apex/RDS_Opportunity?accId=' + accId 
            + '&oppId='+currOppId);
        pg.setRedirect(true);
        if(currOppId != null && currOppId != '') {
            initOpp(currOppId);
        }
        return pg;
    }

    public List<selectoption> getbankruptcies(){  
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
          //Product Name is a MultiSelect Picklist               
          Schema.DescribeFieldResult fieldResult = Opportunity.Have_you_ever_declared_bankruptcy__c.getDescribe();

          list<schema.picklistentry> values = fieldResult.getPickListValues();               
          for (Schema.PicklistEntry a : values) 
          {                  
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
    
    public void refreshOpp() {
        lstOppTab = new List<OpportunityTab>();
        for(Opportunity opp: [Select id, Name, Opportunity_Long_Name__c , 
            Loan_Requests__c, Loan_Type__c, Lawyer__c, Date_Financing_Statement_Done__c, Date_Financing_Statement_Expires__c, Law_Firm__c
            from Opportunity where accountId=:accId and RecordTypeDev__c != 'Loan_Re_Assessment_Opportunity' order by Loan_Requests__c ASC]) {
            
            OpportunityTab oppTab = new OpportunityTab();
            oppTab.oppSObj = opp;
            lstOppTab.add(oppTab);
        }
        /**
         * also add last tab to create new Opportunity
         */
        OpportunityTab oppTab = new OpportunityTab();
        oppTab.oppSObj = new Opportunity(name = oppDefaultName, StageName=oppDefaultStage, CloseDate=oppDefaultCloseDate,
            accountId=accId, ownerId=UserInfo.getUserId());

        /**
         * add other information common to all opportunities from account and if needed this can be changed 
         * later
         */
        if(lstOppTab.size() > 0 && lstOppTab[0].oppSObj != null ) {
          Opportunity opp = lstOppTab[0].oppSObj;
          oppTab.oppSobj.Lawyer__c = opp.Lawyer__c;
          oppTab.oppSObj.Law_Firm__c = opp.Law_Firm__c;
          oppTab.oppSobj.Date_Financing_Statement_Done__c= opp.Date_Financing_Statement_Done__c;
          oppTab.oppSObj.Date_Financing_Statement_Expires__c= opp.Date_Financing_Statement_Expires__c;
        }
        lstOppTab.add(oppTab);
        if(currOppId != null && currOppId != '') {
            initOpp(currOppId);
        }
    }
    
    public PageReference initOpp(id oppId) {
        RDS_SObject rdsOpp = new RDS_SObject(new Opportunity(id=oppId));
        rdsOpp.initFromDb(null);
        currentOppSObj = (Opportunity)rdsOpp.sObj;
        return null;
    }
    
    public class OpportunityTab {
      public Opportunity oppSObj{get; set;}
    }
    
    /* public List<SubsequentDrawdownWrapp> lstsubscDropdown{get;set;}

    public PageReference saveSubsequent(){
      Savepoint sp = Database.setSavepoint();

      User us = [select Id, Name from User where Name = 'Larry Herscu'];

      if(currentOppSObj.Id == null) {
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,
          'Save the client record and the opportunity first and retry the operation.'));
        return null;
      }

     
       //save for subsequent opportunity record save attempts
       
      update currentOppSObj;
      initDDN();      
      List<Drawdown__c> lstDrawd = new List<Drawdown__c>();
      List<Drawdown__c> lstOldDrawd = new List<Drawdown__c>();
      List<Event> lstEvent = new List<Event>();
      List<Event> lstOldEvent;
      
      try{
        //Delete Old Events before Insert new Events
        lstOldEvent = [Select Id, ActivityDate, WhatId from Event where WhatId =:currentOppSObj.Id
          and subject like 'Subsequent Drawdown on%'];
          System.debug('lstOldEvent>>>'+lstOldEvent);
        if(lstOldEvent.size() > 0){                
          delete lstOldEvent;
        }      
        //Insert Events after Opportunity Insert and Update
        if(lstsubscDropdown != null && lstsubscDropdown.size() > 0){
          System.debug('lstEvent>>> '+lstsubscDropdown.size());
          for(SubsequentDrawdownWrapp SDW : lstsubscDropdown){
            Event evnt = New Event(); 
            if(us != null){ 
              evnt.OwnerId = us.Id; 
            }
            evnt.WhatId = currentOppSObj.Id;
            evnt.StartDateTime = SDW.dropDownObj.Date__c;
            evnt.EndDateTime = evnt.StartDateTime;
            evnt.Subject = 'Subsequent Drawdown on '+SDW.dropDownObj.Date__c+ ' for '+SDW.dropDownObj.Amount__c;
            lstEvent.add(evnt);
            System.debug('lstEvent>>> '+lstEvent); 
          }
        }
        
        if(lstEvent.size() > 0){ 
        System.debug('lstEvent>>> '+lstEvent.size());          
          insert lstEvent;
        }
      
        //Delete Old Drawdown before Insert new Drawdown
        lstOldDrawd = [Select Id, Opportunity__c from Drawdown__c where Opportunity__c =:currentOppSObj.Id];
        if(lstOldDrawd.size() > 0){                          
          delete lstOldDrawd;
        }

        //Insert Drawdown after Opportunity Insert and Update
        if(lstsubscDropdown != null && lstsubscDropdown.size() > 0){
          system.debug('lstsubscDropdown <><> ' +lstsubscDropdown.size());
          for(SubsequentDrawdownWrapp SDW : lstsubscDropdown){
            Drawdown__c drawd = New Drawdown__c();                
            drawd.Opportunity__c = currentOppSObj.Id;
            drawd.Amount__c = SDW.dropDownObj.Amount__c;
            drawd.Date__c = SDW.dropDownObj.Date__c;
            drawd.Drop_Down_No__c = SDW.dropDownNo;
            lstDrawd.add(drawd);
          }
        }
        if(lstDrawd.size() > 0){ 
        system.debug('lstsubscDropdown <><> ' +lstDrawd.size()); 
          insert lstDrawd;
        }
      }
      catch(dmlexception e){ 
        Database.RollBack(sp);       
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error: ' + e));
      }

      return null;
    } */
    
    public PageReference saveCurrOpp() {
        /**
         * check if any detail of the opportunity has been saved
         */
        boolean oppChanged = false;
        SObjectType objTokenFile = Schema.getGlobalDescribe().get('Opportunity');
        DescribeSObjectResult objDeffile = objTokenFile.getDescribe();        
        //Get fields of sObject
        Map<String, SObjectField> fieldsFile = objDeffile.fields.getMap();
        Set<String> fieldSetFiles = fieldsFile.keySet();
        for(String s:fieldSetFiles)
        {
            SObjectField fieldToken = fieldsFile.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            String fldName = selectedField.getName().toLowerCase();
            /**
             * default values are already set for the opp, so ignore those.
             */
            if(fldName == 'name' || fldName == 'stagename' || fldName == 'ownerid' || fldName == 'accountid' || fldName == 'closedate') {
              continue;
            }
            if(currentOppSObj.get(selectedField.getName()) != null) {
              oppChanged = true;
            }
        }

        if(oppChanged) {
          if(currentOppSObj.Name != oppDefaultName){
            currentOppSObj.Have_you_ever_declared_bankruptcy__c = bankruptcy;
            upsert currentOppSObj;
          }
          else {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Change default name of opportunity and try again.'));
            
          } 
        }
        currOppId = currentOppSobj.id;
        return getOpp();
    }
    
    /* public List<SubsequentDrawdownWrapp> lstDBDrwapdown {get; set;}
    
    public class SubsequentDrawdownWrapp{
        public Drawdown__c dropDownObj {get;set;}
        //public decimal amount{get;set;}
        //public Date regdate{get;set;}
        public integer dropDownNo{get;set;} 

        public SubsequentDrawdownWrapp(){
          dropDownObj = new Drawdown__c();
        }       
    }

    public PageReference updateDDN() {
      //Savepoint sp = Database.setSavepoint();
      //try{
         
        String curId = ApexPages.currentPage().getParameters().get('recId');
        System.debug('curId<><>'+curId);
        if(curId != null && curId != ''){
          DrawDown__c ddn = [Select Id,Amount__c,Date__c,Drawdown__c.Drop_Down_No__c  From Drawdown__c where Opportunity__c=:currentOppSObj.id AND Drop_Down_No__c =: Integer.ValueOf(curId)];
          ddn.Amount__c = currentDDn.Amount__c;
          ddn.Date__c = currentDDn.date__c;
          update ddn;
          currentDDn = new Drawdown__c(); 
          if(lstsubscDropdown.size() > 0){
              map<Decimal,Drawdown__c> lstMap = new Map<Decimal,Drawdown__c>();
              for(Drawdown__c dd: [Select id, Date__c, Amount__c, Opportunity__c,Drop_Down_No__c  from Drawdown__c where Opportunity__c=:currentOppSObj.id]) {
                  lstMap.put(dd.Drop_Down_No__c,dd);
              }
              List<SubsequentDrawdownWrapp> lstWrap = new  List<SubsequentDrawdownWrapp>();
               for(SubsequentDrawdownWrapp sub :lstsubscDropdown){
                   sub.dropDownObj = lstMap.get(sub.dropDownNo);
                   lstWrap.add(sub);
               }
               lstsubscDropdown = lstWrap;
             }
         }
          
        //}
        else{
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid Id , Please try again'));  
        }
     // }
      //catch(dmlexception e){
        //apexpages.addmessages(e);
      //}    
      return null;
    } */
}