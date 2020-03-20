public with sharing class RDS_AccountPrintableViewCtlr {
    ApexPages.StandardController controller;

    RDS_SObject accRSObj;
    public Account accSObj {get; set;}
    
    RDS_SObject contactRSObj;
    public Contact conSObj {get; set;}
    
    RDS_SObject oppRSObj;
    public Opportunity oppSObj {get; set;}
    String sObjId{get;set;}

    public List<Contact_History__c> lstConHistory {get;set;}

    // Begin: Code added by AppCentrica to allow parity with Lead printable view
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
    
    // End: Code added by AppCentrica to allow parity with Lead printable view
    
    public RDS_AccountPrintableViewCtlr(ApexPages.StandardController controller) {
        /**
         * initialize on page load
         */
        this.controller = controller;
        sObjId = this.controller.getRecord().id;

        initAccountTab();
    }

    public void initAccountTab() {
        SObject sObj = controller.getRecord(); 
        List<Contact> lstcont = new List<Contact>();       
        if(sObj.id != null) {
            accRSObj = new RDS_SObject(sObj);
            accRSObj.initFromDb(null);
            accRSObj.initFromDb('(Select id from Opportunities order by createddate asc limit 1),(Select id from Contacts order by createddate asc limit 1)');
            accSObj = (Account) accRSObj.sObj;
            system.debug('1111'+accSObj);

            /**
            * query related Contact
            */
            if(accSObj.Contacts.size() > 0) {
                contactRSObj = new RDS_SObject(accSObj.Contacts[0]);
            }
            contactRSObj.initFromDb('');
            conSObj = (Contact) contactRSObj.sObj;
            system.debug('2222'+accSObj);

            /**
             * query related opportunity
             */
            // AC 2017-02-01: reversed order of && arguments to avoid list index out of bounds
            if(accSObj.Opportunities.size() > 0 && accSObj.Opportunities[0] != null) {
                oppRSObj = new RDS_SObject(accSObj.Opportunities[0]);
                // AC 2017-02-01: Brought the following two lines into the if block
                // to avoid null exceptions when no Opportunity attached
                oppRSObj.initFromDb(null);
                oppSObj = (Opportunity)oppRSObj.sObj;
            }
            //oppRSObj.initFromDb('(Select id from Opportunities order by createddate desc limit 1)');
            system.debug('3333'+accSObj);
        }
        /**
         *feedback changes 19/08/16
         */
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
                                    Email__c,
                                    Phone__c,
                                    Contact__c
                                    from Contact_History__c 
                                    where Contact__c =:lstcont[0].Id order by lastmodifieddate desc];
        }
    }
}