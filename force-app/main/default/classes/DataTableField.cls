/**
* @description 	Represenation of a Lightning Data Table column. Used to map system data to lightning data table column.
**/
global with sharing virtual class DataTableField {

	@AuraEnabled
	global String label;

	@AuraEnabled
	global String fieldName;

	@AuraEnabled
	global String type;

	@AuraEnabled
	global Boolean sortable;

	@AuraEnabled
	global Boolean editable;

	@AuraEnabled
	global Map<String,Object> typeAttributes;

	@AuraEnabled
	global Map<String,Object> cellAttributes;



	/**
	* @description Constructor to be used when the schema is required to retrieve the paramters
	* @param		fieldsInfoMap - to retrieve field schema details
	* @param		fieldName - field api name
	* @param		sortable - is the field sortable or not
	**/
	global DataTableField(Schema.DescribeFieldResult fieldDescribe, Boolean sortable, Boolean editable) {
		this.sortable = sortable;
		if(fieldDescribe != null){
			this.label = fieldDescribe.getLabel();
			this.fieldName = fieldDescribe.getName();
			this.formatType(fieldDescribe.getType().name());
			this.editable = editable;
			this.setTypeAttributes(fieldDescribe.getType().name());
			this.setCellAttributes(fieldDescribe.getType().name());
		}
	}

	/**
	* @description Method to set the type attributes based on the field data type
	* @param		type - type of the field
	**/
	@testVisible
	private void setTypeAttributes(String type){
		if(type.toLowerCase() == 'date'){
			this.typeAttributes = new Map<String, Object>{'day'=>'numeric','month'=>'short','year'=>'numeric'};
		}else if(type.toLowerCase() == 'datetime'){
			this.typeAttributes = new Map<String, Object>{'day'=>'numeric','month'=>'short','year'=>'numeric','hour'=>'numeric','minute'=>'numeric'};
		}
	}

	/**
	* @description Method to set the cell attributes based on the field data type
	* @param		type - type of the field
	**/
	@testVisible
	private void setCellAttributes(String type){
		if(type.toLowerCase() == 'currency'){
			this.cellAttributes = new Map<String, Object>{'alignment'=>'left'};
		}
	}

	/**
	* @description Method to format lightning datatable supported field type depends on the type
	* 			   Formating the field value due to data type restrictions on the lightning datatable (spring'18)
	* @param	   type - type of the field
	**/
	@testVisible
	private void formatType(String type){
		if(type.toLowerCase() == 'datetime'){
			this.type = 'date';
		}else if(type.toLowerCase() == 'date'){
            this.type = 'date-local';
        }else if(type.toLowerCase() == 'double'){
            this.type = 'number';
        }else if(type.toLowerCase() == 'picklist'){
            this.type = 'string';
        }else{
			this.type = type.toLowerCase();
		}
	}
}