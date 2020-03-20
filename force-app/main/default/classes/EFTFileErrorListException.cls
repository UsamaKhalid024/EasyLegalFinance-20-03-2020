/**
 * @File Name          : EFTFileErrorListException.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/23/2019, 8:31:53 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/23/2019, 7:51:13 AM   Seth Boyd     Initial Version
**/
public class EFTFileErrorListException extends Exception {
    public EFTFileException[] eftExceptions {public get; private set;}
    private List<DatabaseErrorAuraHandledExceptionHelper.dbErrorRecord> errorRecords;

    public EFTFileErrorListException(EFTFileException[] exceptions) {
        this.eftExceptions = exceptions;
        this.errorRecords = new List<DatabaseErrorAuraHandledExceptionHelper.dbErrorRecord>();

        
        // Build map of spId -> [errorMessages...]
        Map<Id, List<DatabaseErrorAuraHandledExceptionHelper.dbErrorMessage>> messagesMap = new Map<Id, List<DatabaseErrorAuraHandledExceptionHelper.dbErrorMessage>>();
        for (EFTFileException e : this.eftExceptions) {
            DatabaseErrorAuraHandledExceptionHelper.dbErrorMessage message = new DatabaseErrorAuraHandledExceptionHelper.dbErrorMessage();
            message.message = e.message;
            message.fields = new String[]{e.field};
            if (messagesMap.containsKey(e.id)) {
                messagesMap.get(e.id).add(message);
            } else {
                messagesMap.put(e.id, new DatabaseErrorAuraHandledExceptionHelper.dbErrorMessage[]{message});
            }
        }

        // build errorRecord list from map
        for (Id key : messagesMap.keySet()) {
            DatabaseErrorAuraHandledExceptionHelper.dbErrorRecord errorRecord = new DatabaseErrorAuraHandledExceptionHelper.dbErrorRecord();
            errorRecord.Id = key;
            errorRecord.errors = messagesMap.get(key);
            this.errorRecords.add(errorRecord);
        }
    }

    public void addException(EFTFileException e) {
        this.eftExceptions.add(e);
    }

    public Boolean hasErrors() {
        return this.eftExceptions.isEmpty() == false;
    }

    public AuraHandledException generateAuraHandledException() {
        return new AuraHandledException(JSON.serialize(this.errorRecords));
    }

    public void throwException() {
        if (!this.errorRecords.isEmpty()) {
            throw new AuraHandledException(JSON.serialize(this.errorRecords));
        }
    }
}