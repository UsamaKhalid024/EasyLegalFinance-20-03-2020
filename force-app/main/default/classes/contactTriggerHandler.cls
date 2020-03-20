public without sharing class contactTriggerHandler {
    
    public static void createActivityHistory(Map<Id,Contact> newMap){
        
        List<Contact_History__c> lstActivity = new List<Contact_History__c>();
        
        for(Contact con : newMap.values()){

            contact cnt = (Contact)Trigger.oldMap.get(con.Id);
            
            if(con.Email != cnt.Email ||
               con.Phone != cnt.Phone ||
               con.OtherPhone != cnt.OtherPhone ||
               con.MailingCity != cnt.MailingCity ||
               con.MailingState != cnt.MailingState ||
               con.MailingStreet != cnt.MailingStreet ||
               con.MailingPostalCode != cnt.MailingPostalCode
               ){

                Contact_History__c activity = new Contact_History__c();
                //activity.Address__c =con.MailingCity + ', ' + con.MailingCountry + ', ' + con.MailingState + ', ' + con.MailingStreet + ', ' +con.MailingPostalCode;
                activity.Address__c = con.MailingStreet + '<br/>' + con.MailingCity + ', ' + con.MailingState + '<br/>' + con.MailingPostalCode;
                activity.Email__c = con.Email;
                activity.Alternate_Phone__c = con.OtherPhone;
                activity.Phone__c = con.Phone;
                activity.Date_of_update__c = Date.today();
                activity.Contact__c = con.Id;

                lstActivity.add(activity);
            }
        }

        if(lstActivity.size() > 0){
            insert lstActivity; 
        }
    }
}