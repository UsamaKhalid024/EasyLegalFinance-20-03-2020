/**
*    @description : Apex class to create payments for facility loans
**/
public with sharing class PaymentController {
    
    /**
    * @description Method to calculate payments for facility loans
    * @param opportunityId Id of the opportunity record
    * @return List<Scheduled_Payment__c> List of payments to create
    **/
    @AuraEnabled
    public static List<Scheduled_Payment__c> calculatePayments(Id opportunityId){
        if(opportunityId != null){
            List<Opportunity> opportunityList = [
                SELECT 
                    Id,
                    Payment_Schedule_Version_Number__c,
                    AccountId,
                    Payment_Scheduled_Allotment_Remaining__c,
                    Day_of_Month__c,
                    Start_Date__c,
                    End_Date__c,
                    Drawdown_Amount__c,
                    Payment_Schedule_Mode__c,
                    Payment_Use_Primary_Bank_Account__c,
                    Payment_Default_Bank_Account__c,
                    Payment_Schedule_Send_First_Immediately__c,
                    (SELECT Id FROM Scheduled_Payments__r Where Payment_Type__c = 'Scheduled Facility' AND Status__c not in :Constants.PAYMENT_SCHEDULE_MODIFIABLE_STATUSES)
                FROM Opportunity
                WHERE Id =: opportunityId LIMIT 1];
            if(!opportunityList.isEmpty()){
                if(opportunityList[0].Payment_Schedule_Mode__c == Constants.PAYMENT_MODE_AMOUNT){
                    if (opportunityList[0].Start_Date__c != null){
                        return PaymentHelper.calculatePaymentsForAmount(opportunityList[0], null, null);
                    }
                }else if(opportunityList[0].Payment_Schedule_Mode__c == Constants.PAYMENT_MODE_DATE){
                    if (opportunityList[0].Start_Date__c != null & opportunityList[0].End_Date__c != null){
                        return PaymentHelper.calculatePaymentsForDate(opportunityList[0], null, null);
                    }
                }
            }
        }
        return new List<Scheduled_Payment__c>();
    }

    /**
    * @description Method to delete payments on scheduled status
    * @param opportunityId Id of the opportunity record
    * @return void
    **/
    @AuraEnabled
    public static void deletePayments(Id opportunityId){
        if(opportunityId != null){
            delete [SELECT Id FROM Scheduled_Payment__c WHERE Opportunity__c =: opportunityId AND Status__c = 'Scheduled' AND Payment_Type__c = 'Scheduled Facility' LIMIT 30000];
        }
    }

    /**
    * @description Method to create payments
    * @param opportunityId Id of the opportunity record
    * @param paymentsList List of payments to create
    * @return Boolean returns true if payments created sucessfully
    **/
    @AuraEnabled
    public static Boolean createPayments(Id opportunityId, List<Scheduled_Payment__c> paymentsList){
        if(paymentsList != null && !paymentsList.isEmpty()){
            // update opportunity
            Opportunity opportunity = new Opportunity(Id=opportunityId,Payment_Schedule__c='Yes');
            update opportunity;
            insert paymentsList;
            return true;
        }
        return false;
    }

    /**
    * @description Method to create payments
    * @param opportunityId Id of the opportunity record
    * @return Boolean returns true if payments created sucessfully
    **/
    @AuraEnabled
    public static Map<String, Object> getPayments(Id opportunityId, String fieldSetName){
        // TODO filter based on Payment Type for Facility Payment Scheduler
        Map<String,Object> objectsMap = new Map<String,Object>();
        List<String> fieldsList = SchemaHelper.getFieldsFromFieldsSet(Scheduled_Payment__c.sObjectType.getDescribe().getName(),fieldSetName);
        // add datatable fields
        objectsMap.put('columns',SchemaHelper.getDataTableFields(Scheduled_Payment__c.sObjectType.getDescribe().getName(),fieldsList));
        // add records
        String soqlQuery = 'SELECT Id, '+String.join(fieldsList,',')+' FROM '+Scheduled_Payment__c.sObjectType.getDescribe().getName()+' WHERE '+Scheduled_Payment__c.Opportunity__c.getDescribe().getName()+' = \''+opportunityId+'\' AND Payment_Type__c = \'Scheduled Facility\' ORDER BY '+Scheduled_Payment__c.Scheduled_Date__c.getDescribe().getName()+' LIMIT 15000';
        objectsMap.put('records',(List<Scheduled_Payment__c>)Database.query(soqlQuery));
        return objectsMap;
    }


    @AuraEnabled(cacheable=true)
    public static List<Scheduled_Payment__c> getScheduledPayments(Id opportunityId) {//, String paymentType, List<String> statusChoices, Date filterDate){
        return [SELECT
                    Id,
                    Hold__c,
                    Notes__c,
                    Current_Bank_Account_Name__c,
                    Status__c,
                    Payment_Type__c,
                    Amount__c,
                    Scheduled_Date__c,
                    Sent_to_Bank_Date__c
                FROM Scheduled_Payment__c WHERE Opportunity__c = :opportunityId AND Status__c != 'Closed'];
    }

    @AuraEnabled(cacheable=true)
    public static List<Previous_Loan__c> getPreviousLoans(Id opportunityId) {//, String paymentType, List<String> statusChoices, Date filterDate){
        return [
            SELECT
                Id,
                Name,
                Amount__c,
                Lender__r.Id,
                Lender__r.Name,
                Status__c,
                Payout_Statement_on_File__c,
                Date_Payout_Valid_Until__c,
                Scheduled_Payment__c
            FROM Previous_Loan__c
            WHERE 
                (Opportunity__c = :opportunityId and Opportunity__c != NULL)
                //OR
                //(Lead__c = :leadId and Lead__c != NULL)
        ];
    }


    @AuraEnabled(cacheable=false)
    public static Bank_Account__c[] getBankAccountOptions(Id oppId) {
        Opportunity opp = [Select AccountId From Opportunity Where Id = :oppId];
        return [Select Id, Name, Is_Primary_Account__c From Bank_Account__c Where Client__c = :opp.AccountId Order By Is_Primary_Account__c DESC, Name ASC];
    }
}