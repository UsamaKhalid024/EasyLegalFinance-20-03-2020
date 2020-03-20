public with sharing class CSL_AssessmentOpportunityCtlr {
    /**
     * Parent Opportunity ID
     */
    public String oppId {get; private set;}
    
    public Opportunity assessment {get; private set;}
    
    public List<Opportunity> assessments {get; set;}
    
    /**
     * Constructor
     */
    public CSL_AssessmentOpportunityCtlr(ApexPages.StandardController controller) {
        init();    

        assessment = new Opportunity();
    }

    /**
     * Initialize page
     */
    public void init() {

        oppId = ApexPages.currentPage().getParameters().get('oppId');

        // load the the list of re-assessment opportunities
        if (oppId != null){
            assessments = [SELECT Id, Name, Amount, CloseDate, StageName,Funding_Requested__c, NextStep
                         FROM Opportunity
                         WHERE Re_Assessed_Loan__c = :this.oppId
                         ORDER BY CloseDate DESC];

        }

    }
    
    public PageReference deleteassessments() {

        String pId = ApexPages.currentPage().getParameters().get('pId');
        System.debug('delete aid = '+pId);

        List<Opportunity> delopp = [SELECT Id FROM Opportunity WHERE Id=:pid LIMIT 1];
        if (delopp.size() > 0) {
            try {
                delete delopp[0];
            } catch (DMLException e) {
                ApexPages.addMessages(e);
            }
        }


        // go back to the same page
        return getCurrentPage();
    }
    
    public PageReference savereassessments() {

        try {
            
            if (assessments.size() > 0) {
                System.debug('here = ' + assessments);
                update assessments;
            } 

        } catch (DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        

        return getCurrentPage();
    }

    public PageReference getCurrentPage() {
        PageReference pg = new PageReference('/apex/CSL_Re_Assessments?oppId=' + oppId);
        pg.setRedirect(true);
        
        return pg;
    }
}