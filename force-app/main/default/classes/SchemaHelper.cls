/**
* @description This utility class provides a collection of Schema methods to get object/field related information.
**/
public with sharing class SchemaHelper {
	
	/**
	* @description This method provides a list of field names for a given object by the field set.
	* @param	   String fieldName
	* @return	   List<String> - Object fieldSetName
	**/
	public static List<String> getFieldsFromFieldsSet(String objectName, String fieldSet){
        List<String> fieldsList = new List<String>();
        
        // Loop through fields list and get the field path 
        if (!String.isBlank(objectName) && !String.isBlank(fieldSet) && Schema.getGlobalDescribe().get(objectName).getDescribe().fieldsets.getMap().containsKey(fieldSet)){
            for (Schema.FieldSetMember field : Schema.getGlobalDescribe().get(objectName).getDescribe().fieldsets.getMap().get(fieldSet).getFields()){
                fieldsList.add(field.getFieldPath());
            }
        }
        return fieldsList;
    }

    /**
	* @description This method provides list of DataTableFields for a given list of fields.
	* @param	   List<String> field api names
	* @return	   String - JSON serialsed list of DatatableFields. If no field is defined, provides name as the default.
	**/
	public static List<DataTableField> getDataTableFields(String objectName, List<String> fieldsList) {
        List<DataTableField> dataTableFieldsList = new List<DataTableField>();
        if(fieldsList != null && fieldsList.size() > 0 && String.isNotEmpty(objectName)) {
			for(String field : fieldsList) {
                if (field.contains('.')) {
                    // Split field by '.'
                    String[] splitField = field.split('\\.');
                    system.debug(field);
                    system.debug(splitField);

                    Schema.SObjectType referenceTo = Schema.getGlobalDescribe().get(objectName);
                    // Iterate over split field getting referenceTo each time
                    for (Integer i = 0; i < splitField.size() - 1; i++) {
                        system.debug(referenceTo.getDescribe().fields.getMap());
                        system.debug(splitField[i]);
                        referenceTo = referenceTo.getDescribe().fields.getMap().get(splitField[i].replace('__r', '__c')).getDescribe().referenceTo[0];
                        system.debug(referenceTo);
                    }

                    // getDescribe for actual field
                    DataTableField dtf = new DataTableField(referenceTo.getDescribe().fields.getMap().get(splitField[splitField.size() - 1]).getDescribe(), true, false);
                    system.debug(dtf);

                    // Set field name to full path
                    dtf.fieldName = field;
                    system.debug(dtf);

                    // Add DataTableField to list
                    dataTableFieldsList.add(dtf);
                } else {
                    dataTableFieldsList.add(new DataTableField(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(field).getDescribe(), true, false));
                }
            }
        } else {
			//if no field is available, add name as the default.
            dataTableFieldsList.add(new DataTableField(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get('Name').getDescribe(), true, true));
        }
        return dataTableFieldsList;
	}

}