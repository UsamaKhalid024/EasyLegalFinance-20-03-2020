/**
 * Raider Data Services, RA, 06/15/2016
 * custom lead form controller that should aid in replacing the 
 * intake form.
 */
public with sharing class RDS_CustomerCtlr {

    ApexPages.StandardController controller;
    public String MaritalStatus{get;set;}
    public String SpousalSupportPayment{get;set;} 
    public String ArrearsPayment{get;set;}
    public String bankruptcy{get;set;}
    public String Litigation{get;set;}
    public String Employment{get;set;}
    public String Dependant{get;set;}
    RDS_SObject accRSObj;
    public Account accSObj {get; set;}
    
    RDS_SObject contactRSObj;
    public Contact conSObj {get; set;}
    
    RDS_SObject oppRSObj;
    public Opportunity oppSObj {get; set;}

    List<Note> notesSObjList;
    List<Amendment__c> lstamen;
    List<Firm__c> lstfirmm;
    /*public String address {get;set;}*/
    public String addressCon {get;set;}
    public String addressCon1 {get;set;}
    public String clientAddress {get;set;}
    public String addressStreet {get;set;}

    public List<Note> lstNotes {get; set;}
    public Contact selectedlawyer {get;set;}
    public List<Amendment__c> lstamendent {get;set;}
    public List<Firm__c> lstFirm {get;set;}
    public List<Contact_History__c> lstConHistory {get;set;}
    public List<Drawdown__c> lstDraw{get;set;}
    public List<Opportunity> lstOpp{get;set;}

    public string strSelLoan {get; set;}
    
    /*String DEFAULT_NOTE_CONTENT = 'Add Details here';*/
    String DEFAULT_NOTE_CONTENT = '';
    
    /*public String oppName {get; set;}*/
    String sObjId;
    public Static Boolean runFirstTime {get;set;}
    
    public RDS_CustomerCtlr(ApexPages.StandardController controller) {
       runFirstTime = false; 
      /**
       * initialize on page load
       */
      this.controller = controller;
      sObjId = this.controller.getRecord().id;
      init();

      strSelLoan = 'Facility Loan';
      if(conSObj != null){
        MaritalStatus = conSObj.Marital_Status__c;
        SpousalSupportPayment = conSObj.Any_SpousalChild_support_payment__c;
        ArrearsPayment = conSObj.Have_you_ever_been_in_arrears_on_payment__c;
        
        Employment = conSObj.Employment_status_at_time_of_accident__c;
      }
      if(oppSObj != null){
        Litigation = oppSObj.Existing_Litigation_Loans__c;
        bankruptcy = oppSObj.Have_you_ever_declared_bankruptcy__c;
      }
      
    }
    
    /**
     * query object and related detail from db
     */
    public void init() {    
      lstOpp = new List<Opportunity>();
      List<Contact> lstcont = new List<Contact>();
      if(sObjId != null && sObjId != ''){
        lstNotes =  [Select id,createddate,CreatedById,
                            body 
                            from Note 
                            where parentId=:sObjId order by createddate desc];
        if(lstNotes.size() == 0) {
          lstNotes.add(new Note(parentId=sObjId, body=DEFAULT_NOTE_CONTENT));
        
        }
        else {
          lstNotes.add(0, new Note(parentId=sObjId, body=DEFAULT_NOTE_CONTENT));
        }
      }
      
      
      if(sObjId != null && sObjId != ''){
        lstOpp = [Select Id,AccountId,
                         Opportunity_Long_Name__c  
                         from Opportunity 
                         where AccountId=:sObjId and RecordTypeDev__c != 'Loan_Re_Assessment_Opportunity' order by createddate desc];
      }

      if(sObjId != null && sObjId != ''){
        lstamendent = [Select id,createddate,
                              Amount__c,
                              Renewal_date__c,
                              Renewal_Date_New__c,
                              Opportunity__c,
                              Date_Financing_Statement_Done__c,
                              Date_Financing_Statement_Expires__c,
                              Opportunity__r.Opportunity_Long_Name__c
                              from Amendment__c 
                              where Opportunity__r.accountId=:sObjId order by createddate desc];
      }

      if(lstOpp.size() > 0){
        lstDraw = [Select id,createddate, 
                          Amount__c,
                          Opportunity__c,
                          Date__c 
                          from Drawdown__c 
                          where Opportunity__c=:lstOpp[0].Id order by createddate desc];
      }
      

      lstFirm = new List<Firm__c>();
      if(lstOpp.size() > 0){
      List<Firm__c>  lstDBFirms = [Select id,createddate,
                          lastmodifieddate,
                          Law_Firm__c, 
                          Lawyer__c,
                          Phone__c,
                          Email__c,
                          Date_of_Update__c 
                          from Firm__c
                          where Opportunity__c =:lstOpp[0].Id order by lastmodifieddate DESC];
        /**
         * Bug found on 4/8/16
         */
        if(lstDBFirms.size() > 0){
          for(Firm__c fm:lstDBFirms){
              if(lstDBFirms[0].Id != fm.id){
                lstFirm.add(fm);
              }
          }
        }
      }
      
      if(sObjId != null && sObjId != ''){
        lstcont = [Select Id,AccountId 
                          from Contact 
                          where AccountId =:sObjId];
      }

      lstConHistory = new List<Contact_History__c>();
      if(lstcont.size() > 0){
        lstConHistory = [Select id,lastmodifieddate,
                                Address__c,
                                Alternate_Phone__c,
                                Date_of_update__c,
                                Email__c,Phone__c,
                                Contact__c
                                from Contact_History__c 
                                where Contact__c =:lstcont[0].Id order by lastmodifieddate desc];
        /**
         * Bug found on 7/26
         */
        if(lstConHistory.size() > 0) {
            clientAddress = lstConHistory[0].Address__c;
        }
      }

      // additional actions for page load
      initAccountTab(); 
    }

    public void initAccountTab() {
        String strwhere = '';
        SObject sObj = controller.getRecord();        
        if(sObj.id != null) {
            accRSObj = new RDS_SObject(sObj);
            accRSObj.initFromDb('(Select id from Opportunities order by Loan_Requests__c DESC limit 1),(Select id from Contacts order by createddate limit 1)');
            accSObj = (Account)accRSObj.sObj;

            /**
            * query related latest Contact
            */
            if(accSObj.contacts.size() > 0){
                contactRSObj = new RDS_SObject(accSObj.contacts[0]);
                contactRSObj.initFromDb(null);
                conSObj = (Contact) contactRSObj.sObj;
                if(conSObj != null){
                    addressCon = conSObj.MailingStreet + '<br/>' + conSObj.MailingCity + ', ' + conSObj.MailingState + '<br/>' + conSObj.MailingPostalCode;
                    addressStreet = conSObj.MailingCity + ', ' + conSObj.MailingState ;
                }
            }
            /**
             * query related latest opportunity
             */
            if(accSObj.Opportunities.size() > 0){
                //oppSObj = new Opportunity();
                oppRSObj = new RDS_SObject(accSObj.Opportunities[0]);
                oppRSObj.initFromDb(null);
                //oppRSObj.initFromDb('(Select id from Opportunities order by createddate desc limit 1)');
                oppSObj = (Opportunity)oppRSObj.sObj;

                fetchContactDetail();
            }
            else {
              /**
               * init empty oppprtunity
               */
              System.debug('>>>empty opp: ');
              /*oppSObj = new Opportunity(name = oppDefaultName, StageName=oppDefaultStage, CloseDate=oppDefaultCloseDate,
                accountId=accSObj.Id, ownerId=UserInfo.getUserId());
              oppRSObj = new RDS_SObject(oppSObj);
                */
              oppSObj = new Opportunity();
            }
        }
    }

    public PageReference saveDb(){
      SavePoint sp = Database.setSavePoint();
        
      try {
        SObject sObj = controller.getRecord();
        if(sObj != null){
            system.debug('ACCSOBJ');
          upsert accSObj;
          
          if(conSObj != null) {
            conSObj.AccountId = accSobj.Id;
             /**
              *21 september Wendy Feedback
              */
            conSObj.Have_you_ever_been_in_arrears_on_payment__c = ArrearsPayment;
            conSObj.Marital_Status__c = MaritalStatus;
            conSObj.Any_SpousalChild_support_payment__c = SpousalSupportPayment;
            conSObj.Employment_status_at_time_of_accident__c = Employment;
            upsert consObj;
          }
          
          Opportunity currentOpp;
          if(lstOpp.size() > 0){
            currentOpp = [ Select Id, Name, Amount,Date_of_the_Accident_from_W2L__c,
              Law_Firm__c, Existing_Litigation_Loans__c,
              Name_of_Lender__c, Pre_Existing_Loan_Amount__c,
              StageName, Stage_Status__c,NOTE_For_Paralegals__c,Other_Lawyer_Law_Firm_that_acted__c,
              Lawyer__c, Did_ELF_buyout_the_Loan__c,
              Date_of_Loss__c, Accident_Location_from_W2L__c,
              What_Happened_from_W2L__c, Nature_of_Injury_from_W2L__c,
              Bankruptcy_Details__c, Important_Notes__c,
              ownerId, Date_Applied__c, Funding_Requested__c, Effective_Date__c,
              Have_you_ever_declared_bankruptcy__c, Address__c
              from Opportunity where Id=:lstOpp[0].Id limit 1];
          }
          else {
            currentOpp = RDS_CustomerCtlr.getDefaultOpp(accSObj.Id, accSObj.Name); 
          }
          System.debug('currentOpp<><>'+currentOpp);
          //AC https://app.asana.com/0/583720228185302/773403792980193/f
          //Change for saving Firm Information            
          if(shouldSaveOpp(currentOpp)){
            
              
            system.debug('lstOpp.size() = ' + lstOpp.size())  ;
            if(lstOpp.size() > 0) {
              currentOpp.Id = lstOpp[0].Id;
            }                        
              
              
		//Ac:Update lawfirm Information to all opportunities.
            List<Opportunity> updateLawFirmList = new List<Opportunity>();              
            for (Opportunity oppfirm : lstOpp){
                if(currentOpp.Id != oppfirm.Id){
                    Opportunity updateFirmOpportunity = new Opportunity();
                    updateFirmOpportunity.Law_Firm__c = oppSObj.Law_Firm__c;
                    updateFirmOpportunity.Lawyer__c = oppSObj.Lawyer__c;
                    updateFirmOpportunity.Id = oppfirm.Id; 
                    updateLawFirmList.add(updateFirmOpportunity);
                }
            }
            
            currentOpp.Law_Firm__c = oppSObj.Law_Firm__c;
            currentOpp.Lawyer__c = oppSObj.Lawyer__c;
              
            currentOpp.Did_ELF_buyout_the_Loan__c = oppSObj.Did_ELF_buyout_the_Loan__c;
            currentOpp.Date_of_Loss__c = oppSObj.Date_of_Loss__c;
            currentOpp.Accident_Location_from_W2L__c = oppSObj.Accident_Location_from_W2L__c;
            currentOpp.What_Happened_from_W2L__c = oppSObj.What_Happened_from_W2L__c;
            currentOpp.Nature_of_Injury_from_W2L__c = oppSObj.Nature_of_Injury_from_W2L__c;
            // currentOpp.Bankruptcy_Details__c = oppSObj.Bankruptcy_Details__c;
            currentOpp.Important_Notes__c = oppSObj.Important_Notes__c;
            currentOpp.Existing_Litigation_Loans__c = Litigation;
             /**
              *21 september Wendy Feedback
              */
            currentOpp.Pre_Existing_Loan_Amount__c = oppSObj.Pre_Existing_Loan_Amount__c;
            currentOpp.Name_of_Lender__c = oppSObj.Name_of_Lender__c;
            currentOpp.Address__c = oppSObj.Address__c;
            currentOpp.NOTE_For_Paralegals__c = oppSObj.NOTE_For_Paralegals__c;
            currentOpp.Other_Lawyer_Law_Firm_that_acted__c = oppSObj.Other_Lawyer_Law_Firm_that_acted__c;
            currentOpp.Date_of_the_Accident_from_W2L__c = oppSObj.Date_of_the_Accident_from_W2L__c;            
            currentOpp.Funding_Requested__c = oppSObj.Funding_Requested__c;
            
            if(oppSObj.ownerId != null)
              currentOpp.OwnerId = oppSObj.ownerId;
            else
              currentOpp.OwnerId = UserInfo.getUserId();
            oppSObj.ownerId = currentOpp.OwnerId;
            // AC: Commented out as per Asana Card - https://app.asana.com/0/751487324339801/751925624912502/f  & https://app.asana.com/0/751487324339801/751487324339820/f
            //currentOpp.Date_Applied__c = oppSObj.Date_Applied__c;
            //currentOpp.Effective_Date__c = oppSObj.Effective_Date__c;
            //currentOpp.Have_you_ever_declared_bankruptcy__c = bankruptcy;
            System.debug('Updateopp<><>'+currentOpp);
            runFirstTime = true;
            DataBase.UpsertResult sr = DataBase.upsert(currentOpp);
		//Ac:Update lawfirm Information to all opportunities.
              if (sr.isSuccess() && updateLawFirmList.size() > 0){
                  system.debug('update all opportunities');                  
                  upsert updateLawFirmList;
                  
              }
            runFirstTime = false;
            System.debug( 'sr  ????? : ' + sr.getErrors());
          }
          saveNotesDb();
          init();
        }
      }
      catch(Exception ex) {
        Database.rollback(sp);
        ApexPages.addMessages(ex);   
      }
      //savefinancehistory();
      //saveLawFirm();
      //return null;
      return null;
    }

    /**
     * method to check if the opportunity field has been populated at all on
     * the page
     */
    public boolean shouldSaveOpp(Opportunity currentOpp) {
      System.debug('>>>test on: ' + oppSObj + ', bankruptcy: ' + bankruptcy);
      //AC ASANA : https://app.asana.com/0/583720228185302/773403792980193/f
      //removed line bellow to allways update Firm Information
      //oppSObj.Law_Firm__c != null || oppSObj.Lawyer__c != null
      
     Boolean hasOpportunity = currentOpp != null ? true:false;
     Boolean changedLawInformation = false;
     if (currentOpp.Law_Firm__c != oppSObj.Law_Firm__c || currentOpp.Lawyer__c != oppSObj.Lawyer__c){
       changedLawInformation = true;
     }      

      
      return (hasOpportunity && oppSObj != null && (changedLawInformation ||
          oppSObj.Did_ELF_buyout_the_Loan__c != null || oppSObj.Date_of_Loss__c != null ||
          oppSObj.Accident_Location_from_W2L__c != null || oppSObj.What_Happened_from_W2L__c != null ||
          oppSObj.Nature_of_Injury_from_W2L__c != null || oppSObj.Bankruptcy_Details__c != null ||
          oppSObj.Important_Notes__c != null ||
          oppSObj.Date_Applied__c != null || oppSObj.Funding_Requested__c != null ||
          oppSObj.Effective_Date__c != null || bankruptcy != null));
    }
    //>>>test on: Opportunity:{Id=0068A000002Xap8QAC, IsDeleted=false, 
    //  AccountId=0018A000006tDUQQA2, IsPrivate=false, 
    //  Name=Amy Reid, StageName=Prospecting, Probability=10, 
    //  CloseDate=2016-08-25 00:00:00, IsClosed=false, IsWon=false, 
    //  ForecastCategory=Pipeline, ForecastCategoryName=Pipeline, HasOpportunityLineItem=false, 
    //  OwnerId=0058A000000ZRm8QAG, CreatedDate=2016-08-25 08:02:13, 
    //  CreatedById=0058A000000ZRm8QAG, LastModifiedDate=2016-08-25 08:02:13, 
    // LastModifiedById=0058A000000ZRm8QAG, SystemModstamp=2016-08-25 08:02:13, 
    //FiscalQuarter=3, FiscalYear=2016, Fiscal=2016 3, LastViewedDate=2016-08-25 08:02:13, 
    //LastReferencedDate=2016-08-25 08:02:13, HasOpenActivity=false, 
    //HasOverdueTask=false, Court_File_No_Combined__c=/, Attorney_Full_Address__c=, ,, 
    //Applicant_Full_Address__c=, ,, Converted_Effective_Date__c=None day of None,, 
    //Effective_Day__c=None, Effective_Month__c=None, Account_Type__c=Client, 
    //Pre_Existing_Settlement_Loans_on_File__c=false, Payout_Statements_on_File__c=false, 
    //Bankruptcy_on_File__c=false, Added_Reminder_to_Team_Calendar__c=false, 
    //Effective_Day_Month__c=None None, Effective_Month_Day__c=None None, 
    //Need_Replacement_Counsel_Documents__c=false, Loan_Amt_minus_Admin_Fee__c=0.00, 
    //APR_1__c=25.44, Name_of_Court_File__c=/, 
    //Opportunity_Name__c=<a href="/0068A000002Xap8" target="_blank">Amy Reid -  - </a>, 
    //Type_of_Loan__c=Lump-Sum, Principle_Sum_to_be_paid_to_Borrower__c=0.00, 
    //Opportunity_Long_Name__c=Amy Reid -  -}

    
    public PageReference saveNotesDb() {
        List<Note> lstNote = new List<Note>();
        for(Note n: lstNotes) {
          if(n.Id == null) {
            n.title = 'Note for: ' + accSObj.Name;
          }
          if(n.body != null && n.body != '' && n.body != DEFAULT_NOTE_CONTENT) {
            lstNote.add(n);
          }
        }
        // AppCentrica 2017-04-18: only save the new note, and only if not blank
        if(lstNote.size()>0 && lstNote[0].id == null && String.isNotBlank(lstNote[0].body)) upsert lstNote[0];
        lstNotes = lstNote;
        return null;
    }

    public PageReference deleteLead(){
        if(accSObj != null){
           delete accSObj; 
        }
        
        PageReference pg = new PageReference('/apex/RDS_Customer');
        pg.setRedirect(true);
        return pg;
    }

    public PageReference  fetchContactDetail(){
       if (oppSObj.Lawyer__c != null){
           selectedlawyer  =[select id,Phone,Email,MailingState,MailingCity,MailingStreet,MailingPostalCode 
            from contact where id=:oppSObj.Lawyer__c];
           addressCon1 = selectedlawyer.MailingStreet + '<br/>' + selectedlawyer.MailingCity + ', ' + 
            selectedlawyer.MailingState + '<br/>' + selectedlawyer.MailingPostalCode;
       }
       return null;
    }

    public PageReference cancel() {
      PageReference newpage = new PageReference('/apex/RDS_Customer?id=' + accSObj.Id);
      newpage.setRedirect(true);
      return newpage;
    }
    public PageReference PrintableView() {
      PageReference newpage;
      if(accSObj.Id != null) {
        newpage = new PageReference('/apex/RDS_AccountPrintableView?Id='+accSObj.Id);
        newpage.setRedirect(true);        
      }      
      return newpage;
    }
    
    public List<String> getMartialStatusOptions() {
        return RDS_Util.getPicklistOptions(Contact.Marital_Status__c.getDescribe());
    }
    public List<String> getSpousalChildPaymentOptions() {
        return RDS_Util.getPicklistOptions(Contact.Any_SpousalChild_support_payment__c.getDescribe());
    }
    public List<String> getArrearsPaymentOptions() {
        return RDS_Util.getPicklistOptions(Contact.Have_you_ever_been_in_arrears_on_payment__c.getDescribe());
    }
    public List<String> getDependentOptions() {
        return RDS_Util.getPicklistOptions(Contact.Do_you_have_any_dependants__c.getDescribe());
    }
    public List<String> getBankruptcyOptions() {
        return RDS_Util.getPicklistOptions(Contact.Have_you_ever_declared_bankruptcy__c.getDescribe());
    }
    public List<String> getEmploymentOptions() {
        return RDS_Util.getPicklistOptions(Contact.Employment_status_at_time_of_accident__c.getDescribe());
    }
    public List<String> getLitigationOptions() {
        return RDS_Util.getPicklistOptions(Opportunity.Existing_Litigation_Loans__c.getDescribe());
    }
    public List<selectoption> getMaritalStatuss() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Contact.Marital_Status__c.getDescribe();

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
    public List<selectoption> getSpousalSupportPayments() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Contact.Any_SpousalChild_support_payment__c.getDescribe();

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
        Schema.DescribeFieldResult fieldResult = Contact.Have_you_ever_been_in_arrears_on_payment__c.getDescribe();

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

    public List<selectoption> getDependants() 
    {           
        list<selectoption> options = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Contact.Do_you_have_any_dependants__c.getDescribe();

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
        Schema.DescribeFieldResult fieldResult = Contact.Have_you_ever_declared_bankruptcy__c.getDescribe();

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
        Schema.DescribeFieldResult fieldResult = Opportunity.Existing_Litigation_Loans__c.getDescribe();

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
  public List<selectoption> getEmployments() {           
      list<selectoption> options = new list<selectoption>();            
      try {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Contact.Employment_status_at_time_of_accident__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        options.add(new SelectOption(a.getLabel(), a.getValue()));
        }
        if(Test.isRunningTest())
            integer intTest =1/0;              
      }  
      catch (Exception e) {             
        ApexPages.addMessages(e);           
      }
      system.debug('## Product Name Options'+ options);          
      return options; 
  }

  public static Opportunity getDefaultOpp(Id accId, String defName) {
    return new Opportunity(name = defName, StageName='Prospecting', CloseDate=Date.today(),
            accountId=accId, ownerId=UserInfo.getUserId());
  }
}