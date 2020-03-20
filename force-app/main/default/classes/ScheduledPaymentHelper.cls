/**
 * @File Name          : ScheduledPaymentHelper.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/13/2019, 11:40:43 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/25/2019, 10:05:30 AM   Seth Boyd     Initial Version

**/
public with sharing class ScheduledPaymentHelper {
    private static Drawdown__c generateDrawdown(Scheduled_Payment__c sp) {
        Drawdown__c drawdown = new Drawdown__c();
        drawdown.Scheduled_Payment__c = sp.Id;
        drawdown.Amount__c = sp.Amount__c;
        drawdown.Date__c = sp.Calculated_Drawdown_Date__c;
        drawdown.Opportunity__c = sp.Opportunity__c;
        if (sp.Send_Cheque__c) {
            drawdown.Payment_Method__c = 'Cheque';
            drawdown.CHQ__c = sp.Cheque_Number__c;
        } else {
            drawdown.Payment_Method__c = 'e-Transfer';
            drawdown.EFT__c = sp.EFT_Number__c;
        }

        if (sp.Opportunity_Service_Provider__c != null) {
            drawdown.Opportunity_Service_Provider__c = sp.Opportunity_Service_Provider__c;
            drawdown.Amount__c = (sp.Amount__c / sp.Opportunity_Service_Provider__r.Payment_Factor__c) * 100.0;
        }

        drawdown.Reference_Notes__c = sp.Calculated_Reference_Notes__c;
        /*
        if (sp.Has_Been_Rejected__c) {
            drawdown.Reference_Notes__c = 'Payment Re-processed';
        } else {
            switch on sp.Payment_Type__c {
                when 'Lump-Sum', 'Ad-Hoc', 'Scheduled Facility' {
                    // Check if account is opportunity's account
                    // TODO - Should I check if it is a law firm or have some other advanced way to figure this out?
                    if (sp.Opportunity__r.AccountId == sp.Current_Account_Id__c) {
                        if ()
                        drawdown.Reference_Notes__c = 'Payment to Client';
                    } else {
                        drawdown.Reference_Notes__c = 'Payment to Third-Party';
                    }
                }
                when 'Assessment' {
                    drawdown.Reference_Notes__c = 'Payment to Assessment Provider';
                }
                when 'Treatment' {
                    drawdown.Reference_Notes__c = 'Payment to Treatment - Service Provider';
                }
                when 'Payment to Other Lender' {
                    drawdown.Reference_Notes__c = 'Payment to other lender';
                }
                when else {
                    // Throw not yet implemented exception
                    throw new NotYetImplementedException('Code has not been written to generate drawdowns for this payment type: ' + sp.Payment_Type__c);
                }
            }
        }
        */


        return drawdown;
    }

    private static Map<Id,Drawdown__c> manageAdminDrawdowns(Map<Id,Drawdown__c> adminDrawdowns, Scheduled_Payment__c sp) {
        System.debug(adminDrawdowns);
        System.debug(sp);
        if (!(
            adminDrawdowns.containsKey(sp.Opportunity__c)
            || (sp.Opportunity__r.Admin_Fee_Roll_up__c > 0
                && sp.Opportunity__r.Admin_Fee__c > 0)))
            {
            System.debug('Creating new Admin Fee Drawdown');
            // Admin Fee Drawdown needs to be created
            String reference_note = 'Admin Fee';
            if (sp.Payment_Type__c == 'Assessment') {
                reference_note = 'Assessment Fee';
            }
            if (sp.Opportunity__r.Admin_Fee__c == 0) {
                reference_note = 'Waived Fee';
            }
            adminDrawdowns.put(
                sp.Opportunity__c,
                new Drawdown__c(
                    Amount__c = sp.Opportunity__r.Admin_Fee__c,
                    Date__c = sp.Sent_to_Bank_Date__c.date(),
                    Opportunity__c = sp.Opportunity__c,
                    Payment_Method__c = 'Admin Fee',
                    Reference_Notes__c = reference_note
                )
            );
            sp.Triggered_Admin_Fee__c = true;
            sp.Triggered_Admin_Fee_Amount__c = sp.Opportunity__r.Admin_Fee__c;
        } else if (adminDrawdowns.containsKey(sp.Opportunity__c)) {
            Drawdown__c adminDrawdown = adminDrawdowns.get(sp.Opportunity__c);
            if (adminDrawdown.Date__c > sp.Sent_to_Bank_Date__c.date()) {
                adminDrawdown.Date__c = sp.Sent_to_Bank_Date__c.date();
            }
        }
        System.debug(adminDrawdowns);
        return adminDrawdowns;
    }

    /*
    private static Map<Id, Opportunity> manageOpportunityFields(Map<Id, Opportunity> oppMap, Map<Id, Drawdown__c> adminDrawdowns, Scheduled_Payment__c sp) {
        System.debug(adminDrawdowns);
        System.debug(sp);
        if (oppMap.containsKey(sp.Opportunity__c)) {
            Opportunity opp = oppMap.get(sp.Opportunity__c);
            if (( opp.First_Drawdown_Amount__c == null || opp.First_Drawdown_Amount__c == 0 ) 
                    && ( opp.Amount_Paid_to_Borrower__c == null || opp.Amount_Paid_to_Borrower__c == 0 )) {
                opp.Amount_Paid_to_Borrower__c = sp.Amount__c;
                opp.First_Drawdown_Amount__c = sp.Amount__c;
                if (adminDrawdowns.containsKey(opp.Id)) {
                    opp.First_Drawdown_Amount__c += adminDrawdowns.get(opp.Id).Amount__c;
                } else {
                    opp.First_Drawdown_Amount__c += opp.Admin_Fee__c;
                }
            }
        }
        return oppMap;
    }
    */

    private static Scheduled_Payment__c[] generateDrawdowns(Scheduled_Payment__c[] spList){
        // Method to actually create drawdowns

        if (spList.isEmpty()) {
            // Don't bother processing an empty list
            return spList;
        }

        // Create drawdowns from Scheduled Payments
        Set<Id> oppIds = new Set<Id>();
        Drawdown__c[] drawdownList = new Drawdown__c[]{};
        Map<Id, Drawdown__c> adminDrawdownMap = new Map<Id, Drawdown__c>();
        Map<Id, Scheduled_Payment__c> spMap = new Map<Id, Scheduled_Payment__c>();
        for (Scheduled_Payment__c sp : spList) {
            spMap.put(sp.Id, sp);
        }
        for (Scheduled_Payment__c sp : spMap.values()) {
            if (sp.Sent_to_Bank_Date__c == null) {
                sp.Sent_to_Bank_Date__c = DateUtil.now();
                sp.Sent_to_Bank_By__c = UserInfo.getUserId();
            }
            if (sp.First_Sent_to_Bank_Date__c == null) {
                sp.First_Sent_to_Bank_Date__c = sp.Sent_to_Bank_Date__c;
            }

            oppIds.add(sp.Opportunity__c);
            Drawdown__c drawdown = generateDrawdown(sp);
            drawdownList.add(drawdown);
            adminDrawdownMap = manageAdminDrawdowns(adminDrawdownMap, sp);
            sp.Status__c = 'Drawdown Created';
            sp.Drawdown_Created__c = true;
        }
        Map<Id, Opportunity> oppMap = New Map<Id, Opportunity>([
            Select Id, Funding_Details_Status__c, Amount_Paid_to_Borrower__c, First_Drawdown_Amount__c
            From Opportunity
            Where Id in :oppIds
        ]);
        /*
        // Blocked out for now until I can talk with Larry more about the requirements
        for (Scheduled_Payment__c sp : spList) {
            manageOpportunityFields(oppMap, adminDrawdownMap, sp);
        }
        */
        setOpportunitiesFundingStatus(oppMap, 'Populate PPSA');

        // Combine Scheduled Payment Drawdowns and any created Admin Fee Drawdowns
        drawDownList.addAll(adminDrawdownMap.values());
        System.debug(drawdownList);

        insert drawdownList;
        /*
        for (Drawdown__c dd : drawdownList) {
            if (dd.Scheduled_Payment__c != null) {
                if (spMap.containsKey(dd.Scheduled_Payment__c)) {
                    spMap.get(dd.Scheduled_Payment__c).Drawdown__c = dd.Id;
                }
            }
        }
        //update spMap.values();
        //update oppMap.values();
        */

        DrawdownTriggerHandler.mergeAdminFees(oppIds);

        return spList;
    }

	@InvocableMethod(label='Generate Drawdowns' description='Create drawdowns from scheduled payments')
    public static void invocableGenerateDrawdowns(Id[] oppIds){
        Scheduled_Payment__c[] spList = [
            Select
                Id,
                Opportunity__c,
                Opportunity__r.Admin_Fee__c,
                Opportunity__r.Admin_Fee_Roll_up__c,
                Opportunity__r.AccountId,
                Opportunity_Service_Provider__c,
                Current_Account_Id__c,
                Payment_Type__c,
                Amount__c,
                Send_Cheque__c,
                Sent_to_Bank_Date__c,
                First_Sent_to_Bank_Date__c,
                Calculated_Drawdown_Date__c,
                Has_Been_Rejected__c,
                Sent_to_Bank_By__c,
                Cheque_Number__c,
                EFT_Number__c,
                Calculated_Reference_Notes__c
            From
                Scheduled_Payment__c
            Where
                Opportunity__c in :oppIds
                AND Status__c = 'Sent to Bank'
                AND Drawdown_Created__c = false
        ];
        generateDrawdowns(spList);
    }

    @AuraEnabled
    public static Scheduled_Payment__c[] generateDrawdowns(Id[] spIds){
        try {
            Scheduled_Payment__c[] spList = [
                Select
                    Id,
                    Opportunity__c,
                    Opportunity__r.Admin_Fee__c,
                    Opportunity__r.Admin_Fee_Roll_up__c,
                    Opportunity__r.AccountId,
                    Current_Account_Id__c,
                    Payment_Type__c,
                    Amount__c,
                    Send_Cheque__c,
                    Sent_to_Bank_Date__c,
                    First_Sent_to_Bank_Date__c,
                    Calculated_Drawdown_Date__c,
                    Has_Been_Rejected__c,
                    Sent_to_Bank_By__c,
                    Cheque_Number__c,
                    Opportunity_Service_Provider__c,
                	Opportunity_Service_Provider__r.Payment_Factor__c,
                    EFT_Number__c,
                    Calculated_Reference_Notes__c
                From
                    Scheduled_Payment__c
                Where
                    Id in :spIds
                    AND Drawdown_Created__c = false // Filter out Scheduled Payments that have already had their drawdowns created
            ];

            return generateDrawdowns(spList);
        } catch (Exception e){
            System.debug(e);
            System.debug(e.getMessage());
            throw new AuraHandledException('Error: '+e.getMessage());
        }
    }

    private static void setOpportunitiesFundingStatus(Map<Id, Opportunity> oppMap, String status) {
        for (Opportunity opp : oppMap.values()) {
            opp.Funding_Details_Status__c = status;
            opp.StageName = 'Closed With Loan';
            opp.Stage_Status__c = 'Active';
        }
    }

    @AuraEnabled(cacheable=false)
    public static Bank_Account__c[] getBankAccountOptions(Id accId) {
        return [Select Id, Name, Account__c, Is_Primary_Account__c From Bank_Account__c Where Client__c = :accId Order By Is_Primary_Account__c DESC, Name ASC];
    }

    @AuraEnabled
    public static void markPaymentValidated(Id spId){
        Scheduled_Payment__c sp = new Scheduled_Payment__c(
            Id=spId,
            Status__c='Approved to Send',
            Verified_By__c = UserInfo.getUserId(),
            Verified_Date__c = DateUtil.now()
        );
        update sp;
    }

    @AuraEnabled
    public static void deletePayment(Id spId, Boolean force){
        try{
            if (force == true) {
                delete new Scheduled_Payment__c(Id=spId);
            }  else {
                Scheduled_Payment__c sp = [
                    Select 
                        Id,
                        Status__c,
                        Current_Opportunity_Schedule_Version__c,
                        Drawdown_Created__c,
                        Opportunity__r.Payment_Schedule__c
                    From Scheduled_Payment__c Where Id = : spId
                ];
                String[] errorMessages = new String[]{};
                if (Constants.PAYMENT_SCHEDULE_IN_PROCESS_STATUSES.contains(sp.Status__c)) {
                    errorMessages.add('Payment is currently being processed');
                }
                if (sp.Current_Opportunity_Schedule_Version__c == true && sp.Opportunity__r.Payment_Schedule__c == 'Yes') {
                    errorMessages.add('Payment is part of of an active payment schedule');
                }
                if (sp.Drawdown_Created__c == true) {
                    errorMessages.add('Payment has already been processed to drawdown');
                }
                if (errorMessages.isEmpty()) {
                    delete sp;
                } else {
                    system.debug(errorMessages);
                    throw new DeleteWarningException(String.join(errorMessages, '\n'));
                }
            }
        }
        catch (DMLException e){
            throw new AuraHandledException('Error:'+e.getDmlMessage(0));
        } catch (DeleteWarningException e){
            AuraHandledException newExc = new AuraHandledException('Warning: '+e.getMessage());
            newExc.setMessage('Warning: '+e.getMessage());
            system.debug(newExc.getMessage());
            throw newExc;
        } catch (Exception e){
            throw new AuraHandledException('Error:'+e.getMessage());
        }
    }

    public class DeleteWarningException extends Exception {}

    @AuraEnabled(cacheable=false)
    public static Date getDrawdownDate(Id spId) {
        return [Select Drawdown_Date__c From Scheduled_Payment__c Where Id = :spId].Drawdown_Date__c;
    }

    /*
    @AuraEnabled
    public static void markPaymentRejected(Id spId, String notes){
        Scheduled_Payment__c sp = new Scheduled_Payment__c(
            Id=spId,
            Status__c='Rejected',
            Verified_By__c = UserInfo.getUserId(),
            Verified_Date__c = DateUtil.now(),
            Hold__c = true,
            Notes__c = notes
        );
        update sp;
    }
    */

    /*
    @AuraEnabled
    public static void resetTestInfo() {
        Set<Id> oppIds = new Set<Id>();
        Scheduled_Payment__c[] sps = [Select Id, Opportunity__c FROM Scheduled_Payment__c Where Status__c != 'Scheduled'];
        for (Scheduled_Payment__c sp : sps) {
            sp.Use_Primary_Bank_Account__c = true;
            sp.Status__c = 'Scheduled';
            oppIds.add(sp.Opportunity__c);
        }
        Drawdown__c[] dds = new Drawdown__c[]{};
        Opportunity[] opps = [Select Id, (Select Id From Drawdowns__r Order By Date__c desc Limit 1) From Opportunity Where Id in :oppIds];
        //for (Drawdown__c dd : dds) {
        //}
        Boolean deleteDrawdowns = true;
        while (deleteDrawdowns) {
            dds = new Drawdown__c[]{};
            for (Opportunity opp : opps) {
                opp.Funding_Details_Status__c = '';
                for (Drawdown__c dd : opp.Drawdowns__r) {
                    dds.add(dd);
                }
            }
            if (!dds.isEmpty()) {
                delete dds;
                opps = [Select Id, (Select Id From Drawdowns__r Order By Date__c desc Limit 1) From Opportunity Where Id in :oppIds];
            } else {
                deleteDrawdowns = false;
            }
        }

        update opps;
        update sps;

        //Opportunity[] opps = [Select Id From Opportunity Where Funding_Details_Status__c != null Limit 200]; for (Opportunity opp : opps) { opp.Funding_Details_Status__c = null; } update opps;
        /*
        Database.executeBatch(
            new BatchUpdateOpportunityFields(
                'Select Funding_Details_Status__c From Opportunity Where Funding_Details_Status__c != null LIMIT 5000',
                'Opportunity',
                'Funding_Details_Status__c',
                ''
            ), 20
        );
    }
    */
}

/*
ScheduledPaymentHelper.resetTestInfo();
System.debug([Select Opportunity__r.Name, Opportunity__r.AccountId From Scheduled_Payment__c Where Id = 'a1W190000032CyqEAE'].Opportunity__r);
Scheduled_Payment__c[] sps = [Select Id FROM Scheduled_Payment__c];
for (Scheduled_Payment__c sp : sps) {
    sp.Use_Primary_Bank_Account__c = true;
}
update sps;

*/
