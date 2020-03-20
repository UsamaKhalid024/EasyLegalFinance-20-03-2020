public with sharing class CSL_FacilityDrawdownCtlr {
    /**
     * Parent Opportunity ID
     */
    public String oppId {get; private set;}
    
    public Drawdown__c drawdown {get; private set;}

    public List<Drawdown__c> drawdowns {get; set;}

    /**
     * Constructor
     */
    public CSL_FacilityDrawdownCtlr(ApexPages.StandardController controller) {
        init();    

        drawdown = new Drawdown__c();
    }

    /**
     * Initialize page
     */
    public void init() {

        oppId = ApexPages.currentPage().getParameters().get('oppId');

        // load the the list of drawdowns
        if (oppId != null){
            Id thisOppId = this.oppId;
            drawdowns = (List<Drawdown__c>)database.query(
                'SELECT Id, Name, Amount__c, Date__c, Opportunity__c, Payment_Method__c, Reference_Notes__c, Type__c   '+
                'FROM Drawdown__c '+
                'WHERE Opportunity__c = :thisOppId '+
                'ORDER BY Date__c DESC ');

        }

    }

    public PageReference createNew() {
        
        try {
            drawdown.Opportunity__c = oppId;

            insert(drawdown);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        
        // go back to the same page
        return getCurrentPage();
    }

    public PageReference deleteDrawdown() {

        String pId = ApexPages.currentPage().getParameters().get('pId');
        System.debug('delete pid = '+pId);

        List<Drawdown__c> delDrawdown = [SELECT Id FROM Drawdown__c WHERE Id=:pid LIMIT 1];
        if (delDrawdown.size() > 0) {
            try {
                delete delDrawdown[0];
            } catch (DMLException e) {
                ApexPages.addMessages(e);
            }
        }


        // go back to the same page
        return getCurrentPage();
    }

    public PageReference savedrawdownList() {

        try {
            
            if (drawdowns.size() > 0) {
                System.debug('here = ' + drawdowns);
                update drawdowns;
            } 

        } catch (DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        

        return getCurrentPage();
    }
 

    public PageReference getCurrentPage() {
        PageReference pg = new PageReference('/apex/CSL_FacilityDrawdown?oppId=' + oppId);
        pg.setRedirect(true);
        
        return pg;
    }
}