public with sharing class leadHelper {

    public static void convertToContact(List<Lead> lstLead, Map<Id, Lead> oldMap) {

       if(trigger.isUpdate) {
            RecordType customerType = [Select Id FROM RecordType WHERE SObjectType = 'Lead' AND DeveloperName LIKE '%Customer%' LIMIT 1];
            Map<Id, Lead> mapLead = new Map<Id, Lead>();
            Map<Id, Lead> mapForLeadToOpp = new Map<Id, Lead>();
            Map<Id, Lead> mapForLeadToAccount = new Map<Id, Lead>();

            for(Lead ld : lstLead) {
                // AppCentrica 2017-04-05 - If Lead Record Type is not Customer or blank, skip it!
                // AppCentrica 2017-04-05 - Also restrict to only just-converted Leads
                Boolean justConverted = ld.IsConverted && !oldmap.get(ld.id).IsConverted;
                Boolean rightType = ld.RecordTypeId == null || ld.RecordTypeId == customerType.Id;
                if (!justConverted || !rightType) continue;
                
                mapLead.put(ld.ConvertedContactId,ld);  
                mapForLeadToOpp.put(ld.ConvertedOpportunityId,ld);
                mapForLeadToAccount.put(ld.ConvertedAccountId,ld);              
            }
           
            // AppCentrica 2017-04-05 - if no Leads were retained, quit
            if (mapLead.size() == 0) return;
           
            List<Contact> lstCon = new List<Contact>();         
            List<Contact> lstCont = [select Id, Birthdate,
                                            Phone,
                                            Company__c,
                                            OtherPhone,
                                            How_did_you_hear_about_us__c,
                                            Web_To_Lead_From__c,
                                            Status__c
                                            from Contact 
                                            where Id IN : mapLead.keySet()];

            List<Opportunity> lstOp = new List<Opportunity>();          
            List<Opportunity> lstOpp = [select Id, 
                                               Amount, 
                                               Funding_Requested__c 
                                               from Opportunity 
                                               where Id IN : mapForLeadToOpp.keySet()];

            List<Account> lstAc = new List<Account>();          
            List<Account> lstAcc = [select Id, 
                                           Account_Type__c 
                                           from Account 
                                           where Id IN : mapForLeadToAccount.keySet()];
            
            if(lstCont.size() > 0){
                for(Contact cn : lstCont) {
                    cn.Birthdate = mapLead.get(cn.Id).DOB__c;
                    cn.Phone = mapLead.get(cn.Id).Phone;
                    cn.Company__c = mapLead.get(cn.Id).Company;
                    cn.OtherPhone = mapLead.get(cn.Id).MobilePhone;
                    cn.How_did_you_hear_about_us__c = mapLead.get(cn.Id).How_did_you_hear_about_us__c;
                    cn.Web_To_Lead_From__c = mapLead.get(cn.Id).Web_To_Lead_From__c;
                    cn.Status__c = mapLead.get(cn.Id).Status;
                    lstCon.add(cn);
                }
            }           
            update lstcon;

            if(lstOpp.size() > 0){
                for(Opportunity op : lstOpp) {
                    op.Amount = mapForLeadToOpp.get(op.Id).Loan_Amount__c;
                    op.Funding_Requested__c = mapForLeadToOpp.get(op.Id).Funding_Requested__c;
                    //op.Primary_Contact__c = mapForLeadToOpp.get(op.Id).Primary_Contact__c;                    
                    /**
                     * Wendy's feedback on 7/26
                     */
                    op.Primary_Contact__c = lstcon[0].Id;
                    op.Amount= 0;
                    lstOp.add(op);
                }
            }           
            update lstOp;

            if(lstAcc.size() > 0){
                for(Account ac : lstAcc) {
                    ac.Account_Type__c = mapForLeadToAccount.get(ac.Id).Account_Type__c;
                    ac.Related_Law_Firm__c = mapForLeadToAccount.get(ac.Id).Law_Firm_Name_new__c;
                    lstAc.add(ac);
                }
            }           
            update lstAc;
        }
    }
}