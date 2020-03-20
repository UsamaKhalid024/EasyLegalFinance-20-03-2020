public with sharing class CSL_OpportunityServiceProviderCtlr {
    /**
     * Parent Opportunity ID
     */
    public String oppId {get; private set;}
    
    public Opportunity_Service_Provider__c provider {get; private set;}

    public List<Opportunity_Service_Provider__c> providers {get; set;}

    /**
     * Constructor
     */
    public CSL_OpportunityServiceProviderCtlr(ApexPages.StandardController controller) {
        init();    

        provider = new Opportunity_Service_Provider__c();
    }

    /**
     * Initialize page
     */
    public void init() {

        oppId = ApexPages.currentPage().getParameters().get('oppId');


        // load the the list of service providers
        if (oppId != null){
            providers = (List<Opportunity_Service_Provider__c>)Database.query(
                ' SELECT Id, Primary_Contact__c, Allowance__c, Allowance_Balance__c, Service_Provider_Facility__r.Name, Service_Provider_Facility__c, Service_Provider_Email__c, Service_Provider_Phone__c, Total_Paid__c, Status__c, Send_Schedule__c, Generate_Schedule_PDF__c, CreatedDate,  '+
                ' (SELECT Id, Amount__c, Date__c, CreatedDate, Payment_Method__c, Reference_Notes__c '+
                ' FROM Drawdowns__r '+
                ' ORDER BY Date__c DESC) '+
                ' FROM Opportunity_Service_Provider__c '+
                ' WHERE Opportunity__c = :oppId '+
                ' ORDER BY CreatedDate DESC ');

        }

    }


    public PageReference createNew() {
        
        try {
            provider.Opportunity__c = oppId;

            insert(provider);
        } catch(System.DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        
        // go back to the same page
        return getCurrentPage();
    }

    public PageReference deleteProvider() {

        String pId = ApexPages.currentPage().getParameters().get('pId');
        System.debug('deletee pid = '+pId);

        List<Opportunity_Service_Provider__c> delProviders = [SELECT Id FROM Opportunity_Service_Provider__c WHERE Id=:pid LIMIT 1];
        if (delProviders.size() > 0) {
            try {
                delete delProviders[0];
            } catch (DMLException e) {
                ApexPages.addMessages(e);
            }
        }


        // go back to the same page
        return getCurrentPage();
    }

    public PageReference addDrawdown() {

        String pId = ApexPages.currentPage().getParameters().get('pId');

        if (!String.isBlank(pId) && pId != null) {

            // create a blank drawdown item at the current date
            Drawdown__c newDrawdown = new Drawdown__c(
                Opportunity_Service_Provider__c = pId,
                Opportunity__c = oppId,
                Type__c = 'Treatment Loan',
                Amount__c = 0,
                Date__c= Date.today()
            );

            try {
                insert newDrawdown;
            } catch (DMLException e) {
                ApexPages.addMessages(e);
            }
        }   

        // go back to the same page
        return getCurrentPage();
    }

    public PageReference deleteDrawdown() {

        String dId = ApexPages.currentPage().getParameters().get('dId');
        System.debug('delete dId = '+dId);

        List<Drawdown__c> delDrawdown = [SELECT Id FROM Drawdown__c WHERE Id=:dId LIMIT 1];
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


    public PageReference saveProviderList() {

        System.debug('providers list = ' + providers);
        
        // collect drawdowns
        List<Drawdown__c> updateDrawdowns = new List<Drawdown__c>();
        for(Opportunity_Service_Provider__c sp: providers){
            if (sp.Drawdowns__r.size() > 0) {
                updateDrawdowns.addAll(sp.Drawdowns__r);
            }
        }
            
        System.debug(updateDrawdowns);
    
        try {
            
            if (updateDrawdowns.size() > 0) {
                System.debug('here = ' + updateDrawdowns);
                update updateDrawdowns;
            }
            system.debug('blahblah');
            
            Map<id,Opportunity_Service_Provider__c> pmap = new Map<id,Opportunity_Service_Provider__c>(providers);
            Map<id,Opportunity_Service_Provider__c> updatedProviders = new Map<id,Opportunity_Service_Provider__c>([select Total_Paid__c,id,name from Opportunity_Service_Provider__c where id in: pmap.keySet()]); 
            for(Opportunity_Service_Provider__c p: providers){
                p.Total_Paid__c = updatedProviders.get(p.id).Total_Paid__c;
            }
            update providers;
        
        } catch (DMLException e) {
            ApexPages.addMessages(e);
            return null;
        }
        

        return getCurrentPage();
    }

    public PageReference getCurrentPage() {
        PageReference pg = new PageReference('/apex/CSL_OpportunityServiceProvider?oppId=' + oppId);
        pg.setRedirect(true);
        
        return pg;
    }
}