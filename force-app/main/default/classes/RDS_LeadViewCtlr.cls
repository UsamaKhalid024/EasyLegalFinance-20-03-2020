/**
 * RA, 06/09/2016
 * controller extension for Lead View page
 */
public with sharing class RDS_LeadViewCtlr{

    private final RDS_SObject rdsObject;
    public Lead leadObj {get; set;}
    public String ownerName {get; set;}
    public String address {get; set;}
    Id recId {get; set;}    

    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public RDS_LeadViewCtlr(ApexPages.StandardController stdController) {
        this.rdsObject= new RDS_SObject((SObject)stdController.getRecord());
        
        // read from database to make sure all fields are queried
        this.rdsObject.initFromDb(null);
        leadObj = (Lead)this.rdsObject.sObj;
        
        if(leadObj != null && leadObj.ownerId != null){
            ownerName = [Select name from User where id=:leadObj.ownerId][0].name;
            address = leadObj.Street + ' ' + leadObj.City + ' ' + leadObj.State + ' ' + leadObj.PostalCode;
        }
    }
    
    public PageReference dispatch(){
        // redirect to nooverride if it's a lawyer
        if(leadObj != null && leadObj.AC_rtName__c != null && leadObj.AC_rtName__c.contains('Lawyer')){  
            PageReference pg = new PageReference('/' + leadObj.id);
            pg.getParameters().put('nooverride', '1');
            pg.setRedirect(true);
            return pg;
        }
        return null;
    }

    public List<String> getMartialStatusOptions() {
        return RDS_Util.getPicklistOptions(Lead.Marital_Status__c.getDescribe());
    }
    public List<String> getSpousalChildPaymentOptions() {
        return RDS_Util.getPicklistOptions(Lead.Any_SpousalChild_support_payment__c.getDescribe());
    }
    public List<String> getArrearsPaymentOptions() {
        return RDS_Util.getPicklistOptions(Lead.Have_you_ever_been_in_arrears_on_payment__c.getDescribe());
    }
    public List<String> getDependentOptions() {
        return RDS_Util.getPicklistOptions(Lead.Do_you_have_any_dependants__c.getDescribe());
    }
    public List<String> getBankruptcyOptions() {
        return RDS_Util.getPicklistOptions(Lead.Have_you_ever_declared_bankruptcy__c.getDescribe());
    }
    public List<String> getEmploymentOptions() {
        return RDS_Util.getPicklistOptions(Lead.Employment_status_at_time_of_accident__c.getDescribe());
    }
    public List<String> getLitigationOptions() {
        return RDS_Util.getPicklistOptions(Lead.Existing_Litigation_Loans__c.getDescribe());
    }
    public PageReference deleteLead(){
        if(leadObj != null){
           delete leadObj; 
        }
        
        PageReference pg = new PageReference('/apex/RDS_LeadEdit');
        pg.setRedirect(true);
        return pg;
    }
    public PageReference convert() {
        return new PageReference('/lead/leadconvert.jsp?id=' + leadObj.Id + '&retURL=%2F' + leadObj.Id );
    }
    public PageReference printableView() {
        return new PageReference('/apex/RDS_LeadPrintableView?id=' + leadObj.Id);
    }
    public PageReference standardView() {
        return new PageReference('/' + leadObj.Id + '?nooverride=1');
    }
    public PageReference CancelLead() {
        return new PageReference('/00Q/o');
    }
    public PageReference cloneLead(){
        recId = ApexPages.currentPage().getParameters().get('id');
         Lead ld;
        if(leadObj != null){
            ld =(Lead)leadObj;
            Lead led = new Lead();
            led =  ld.clone(true,false);
            leadObj = led;
        }
        system.debug('>>>>>>>>>leadObj'+leadObj);
        if(recId == null) return null;
        system.debug('>>>>>>>recId '+recId);
        Pagereference targetClonePg = Page.RDS_LeadEdit;
        targetClonePg.getParameters().put('clone', '1');
        targetClonePg.getParameters().put('id', leadObj.id);
        targetClonePg.getParameters().put('retURL', recId);
        system.debug('>>>>>>>targetClonePg '+targetClonePg);
        return targetClonePg;
    }
}