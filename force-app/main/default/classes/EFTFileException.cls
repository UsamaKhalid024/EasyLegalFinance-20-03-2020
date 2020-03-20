/**
 * @File Name          : EFTFileException.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/22/2019, 12:39:49 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/22/2019, 12:38:44 PM   Seth Boyd     Initial Version
**/
public class EFTFileException extends Exception {
    public Id id {get; set;}
    public String field {get; set;}
    public String message {get; set;}

    public EFTFileException(Id id, String field, String message) {
        this.id = id;
        this.field = field;
        this.message = message;
    }
}