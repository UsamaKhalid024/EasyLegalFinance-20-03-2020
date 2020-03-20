public with sharing class SendCustomerDataToBirdEye {
	
	/**
	* @description Method to send the data
	**/
	@InvocableMethod(label='Send Data to Bird Eye' description='This method is used to create customer data in bird eye')
	public static List<Id> sendDataToBirdEye(List<Id> opportunityIds){
		sendData(opportunityIds);
		return new List<Id>();
	}

	/**
	* @description Method to send the data
	**/
	@future(callout=true)
	private static void sendData(List<Id> opportunityIds){
        List<Integration_Log__c> logs = new List<Integration_Log__c>();
        List<Contact> contactsListToUpdate = new List<Contact>();
		Map<Id,Account> accountsMap = getAccountsMap(opportunityIds); 
		Bird_Eye_Settings__mdt birdEyeSettings = getBirdEyeSettings();
		if(birdEyeSettings != null){
			for(Account account : accountsMap.values()){
				for(Contact contact : account.Contacts){
                    if(contact.Review_Last_Sent__c == null || (contact.Review_Last_Sent__c != null && contact.Review_Last_Sent__c.addYears(1) >= System.today())){
                        
                        String requestBody = JSON.serialize(new BirdEyeData.CustomerCheckIn(contact,Integer.valueOf(birdEyeSettings.Campaign_Id__c)));
                        Integration_Log__c log = new Integration_Log__c(
                            Class__c = 'SendCustomerDataToBirdEye',
                            Identifier__c = 'BirdEye'                            
                        );
                        HttpResponse response = HttpRestClient.sendRequest(birdEyeSettings.Customer_Check_In_Base_Url__c+'bid='+(account.Business_Unit__c == Constants.RHINO_BUSINESS_UNIT ? birdEyeSettings.Rhino_Location_Id__c : birdEyeSettings.ELFI_Location_Id__c)+'&api_key='+birdEyeSettings.API_Key__c,
                                                                    requestBody,
                                                                    Constants.HTTP_POST,
                                                                    new Map<String, String>{'Content-Type' => 'application/json','Accept' => 'application/json'}
                                                                 );
                        
                        log.Body__c = String.format(
                            '{0}\n{1}\n{2}\n{3}\n{4}\n{5}',
                            new List<String>{
                                'Request Body:',
                                    '' + requestBody,
                                    ' ',
                                    'Response:',
                                    '' + response.toString(),
                                    '' + response.getBody()
                                    }
                        );
                        
                        logs.add(log);
                        contact.Review_Last_Sent__c = System.today();
                        contactsListToUpdate.add(contact);
                    }
				}
			}
            if(!logs.isEmpty()) insert logs;
            if(!contactsListToUpdate.isEmpty()) update contactsListToUpdate;
		}
	}

	/**
	* @description Method to get bird eye api settings
	**/
	private static Bird_Eye_Settings__mdt getBirdEyeSettings(){
		List<Bird_Eye_Settings__mdt> birdEyeSettingsList = [SELECT Id, API_Key__c, Business_Id__c, Campaign_Id__c, Customer_Check_In_Base_Url__c, ELFI_Location_Id__c, Rhino_Location_Id__c
																FROM Bird_Eye_Settings__mdt LIMIT 1];
		return !birdEyeSettingsList.isEmpty() ? birdEyeSettingsList[0] : new Bird_Eye_Settings__mdt();
	}

	/**
	* @description Method to set up accounts map
	**/
	private static Map<Id,Account> getAccountsMap(List<Id> opportunityIds){
		Set<Id> accountIds = new Set<Id>();
		// get account ids
		for(Opportunity opportunity : [SELECT AccountId FROM Opportunity WHERE Id IN: opportunityIds LIMIT 40000]){
			accountIds.add(opportunity.AccountId);
		}
		return new Map<Id,Account>([SELECT Id,Business_Unit__c, (SELECT Id, FirstName, LastName, Email, MobilePhone, Phone, Review_Last_Sent__c  FROM Contacts) FROM Account
										WHERE Id IN: accountIds LIMIT 40000]);
	}
}