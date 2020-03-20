/**
 * @File Name          : DatabaseErrorAuraHandledExceptionHelper.cls
 * @Description        : Detects if a SaveResult has an error, and creates a JSON encoded error message that can be parsed client-side for more information
                        [
                            {
                                Id: 'record_id',
                                errors: [
                                    {
                                        fields: ['field_name1', 'field_name2'],
                                        message: 'error message...'
                                    }
                                    ...
                                ]
                            }
                            ...
                        ]
                        Intended to be used with ldsUtils.generateDataTableErrors function
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/23/2019, 8:28:45 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/19/2019, 12:23:48 PM   Seth Boyd     Initial Version
**/
public with sharing class DatabaseErrorAuraHandledExceptionHelper {

    private List<dbErrorRecord> errorRecords;
    private Boolean hasError = false;

    public class dbErrorRecord {
        public Id Id;
        public List<dbErrorMessage> errors = new List<dbErrorMessage>();
    }

    public class dbErrorMessage {
        public String message;
        public List<String> fields = new List<String>();
    }

    public DatabaseErrorAuraHandledExceptionHelper(List<SObject> updatedObjects, List<Database.SaveResult> updateResults) {
        this.hasError = false;
        this.errorRecords = new List<dbErrorRecord>();
        for(Integer i=0;i<updateResults.size();i++){
            if (!updateResults.get(i).isSuccess()){
                this.hasError = true;
                // DML operation failed
                List<Database.Error> dbErrors = updateResults.get(i).getErrors();
                dbErrorRecord errorRecord = new dbErrorRecord();
                errorRecord.Id = updatedObjects.get(i).Id;
                for (Database.error error : dbErrors) {
                    dbErrorMessage message = new dbErrorMessage();
                    message.message = error.getMessage();
                    message.fields = error.getFields();
                    errorRecord.errors.add(message);
                }
                this.errorRecords.add(errorRecord);
            }
        }
    }

    public void throwException() {
        if (!this.errorRecords.isEmpty()) {
            throw new AuraHandledException(JSON.serialize(this.errorRecords));
        }
    }

    public Boolean hasError() {
        return this.hasError;
    }
}