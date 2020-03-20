public with sharing class RDS_CustomerDispatcher {
    public String  CustId {get;set;}
    public RDS_CustomerDispatcher(ApexPages.StandardController controller) {

        CustId = ApexPages.CurrentPage().getParameters().get('id');
    }

    public PageReference dispatch(){
        /**
         * check the type of record based on Id
         */
        List<SObject> sObjList;
        String accType = 'Law Firm'; // default view for standard view
        
        // for sObject id, should always be account Id on the custom VF page
        String sObjId; 
        if(CustId != null) {
            if(CustId.startsWith('001')) {
                sObjList = [Select id, Account_Type__c from Account where id=:CustId];                    
                if(sObjList.size() > 0) {
                    Account acc = (Account)sObjList[0];
                    accType = acc.Account_Type__c;
                    sObjId = acc.id;
                }
            }
            if(CustId.startsWith('003')) {
                sObjList = [Select id, AccountId, Account.Account_Type__c from Contact where id=:CustId];    
                if(sObjList.size() > 0) {
                    Contact c = (Contact)sObjList[0];
                    if(c.Account != null && c.Account.Account_Type__c != null) {
                        accType = c.account.Account_Type__c;
                    }
                    sObjId = c.Accountid;
                }
            }
            if(CustId.startsWith('006')) {
                sObjList = [Select id, AccountId, Account.Account_Type__c from Opportunity where id=:CustId];    
                if(sObjList.size() > 0) {
                    Opportunity opp = (Opportunity)sObjList[0];
                    if(opp.Account != null && opp.Account.Account_Type__c != null) {
                        accType = opp.Account.Account_Type__c;
                    }
                    sObjId = opp.Accountid;
                }
            }            
        }
        //List<Account> acc = new List<Account>();
        
        PageReference pg;

        if(accType == 'Client'){
            pg = new PageReference('/apex/RDS_Customer?id='+ String.escapeSingleQuotes(sObjId));
        }
        else{
            pg = new PageReference('/' + String.escapeSingleQuotes(CustId));
            pg.getParameters().put('nooverride', '1');
        }         
        pg.setRedirect(true);
        return pg;
    }
}