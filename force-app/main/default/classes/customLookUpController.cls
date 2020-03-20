public class customLookUpController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String filter, String additionalFields, String fieldtoSearchIn) {
        system.debug('ObjectName-->' + ObjectName);
        
        if(String.isEmpty(fieldtoSearchIn))		fieldtoSearchIn = 'Name';
        String searchKey = '%' + searchKeyWord + '%';
        
        List < sObject > returnList = new List < sObject > ();
        String filterString = String.isEmpty(filter) ? '' : ' and '+filter;
        Set<String> uniquefields = new Set<String>();
        uniquefields.add('id');
        uniquefields.add('Name');
        
        if(!String.isEmpty(additionalFields)) uniquefields.addAll(additionalFields.split(','));
        
        List<String> fields = new List<String>();
        fields.addAll(uniquefields);
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5   
        String sQuery =  'select '+String.join(fields, ',')+' from ' +ObjectName + ' where '+fieldtoSearchIn+' LIKE: searchKey '+filterString+' order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
}