/**
 * RA, 06/11/2016
 * Utility class for common functions
 */
public with sharing class RDS_Util {
    public RDS_Util() {
        
    }

    public static String getQueryStringForSObject(String objName){
        //Get spec file related to above specification
        SObjectType objTokenFile = Schema.getGlobalDescribe().get(objName);
        DescribeSObjectResult objDeffile = objTokenFile.getDescribe();
        
        //Get fields of sObject
        Map<String, SObjectField> fieldsFile = objDeffile.fields.getMap();
        string fieldLstFile='';
        Set<String> fieldSetFiles = fieldsFile.keySet();
        for(String s:fieldSetFiles)
        {
            SObjectField fieldToken = fieldsFile.get(s);
            DescribeFieldResult selectedField = fieldToken.getDescribe();
            fieldLstFile=fieldLstFile+selectedField.getName()+',';
        }
        fieldLstFile= fieldLstFile.removeEnd(',');
        return fieldLstFile;
    }

    public static List<String> getPicklistOptions(Schema.DescribeFieldResult fldResult) 
    {           
        list<String> options = new list<String>();            
        try 
        {               
            //Product Name is a MultiSelect Picklist               
            Schema.DescribeFieldResult fieldResult = fldResult;

            list<schema.picklistentry> values = fieldResult.getPickListValues();               
            for (Schema.PicklistEntry a : values){                  
                options.add(a.getValue());
            }           
        }  
        catch (Exception e){             
            ApexPages.addMessages(e);           
        }
        system.debug('## Options'+ options);          
        return options; 
    }
}