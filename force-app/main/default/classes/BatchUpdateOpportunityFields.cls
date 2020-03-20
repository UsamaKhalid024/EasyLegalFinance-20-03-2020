/**
 * @File Name          : BatchUpdateOpportunityFields.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 4/26/2019, 1:54:42 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/26/2019, 1:52:02 PM   Seth Boyd     Initial Version
**/
global class BatchUpdateOpportunityFields implements Database.Batchable<sObject>{
    global final String Query;
    global final String Entity;
    global final String Field;
    global final String Value;

    global BatchUpdateOpportunityFields(String q, String e, String f, String v){
        Query=q; Entity=e; Field=f;Value=v;
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        for(Sobject s : scope){
            s.put(Field,Value); 
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC){

    }
}