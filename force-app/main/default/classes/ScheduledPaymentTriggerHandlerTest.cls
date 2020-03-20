/**
 * @File Name          : ScheduledPaymentTriggerHandlerTest.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/10/2019, 1:06:14 PM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    5/10/2019, 10:46:16 AM   Seth Boyd     Initial Version
**/
@isTest
public with sharing class ScheduledPaymentTriggerHandlerTest {

    @isTest
    static void validateFirstSetOnInsert() {
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        Opportunity opp = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(0)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        spConfig.setDefinition('Scheduled_Date__c', 'static value(2018-01-01)');
        Scheduled_Payment__c sp1 = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];
        sp1 = [Select First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp1.Id];

        System.assertEquals(true, sp1.First_Scheduled_Payment__c, 'Inserted payment should be marked as first');

        spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(0)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        spConfig.setDefinition('Scheduled_Date__c', 'static value(2018-01-02)');
        Scheduled_Payment__c sp2 = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];
        sp1 = [Select First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp1.Id];
        sp2 = [Select First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp2.Id];

        System.assertEquals(true, sp1.First_Scheduled_Payment__c, 'First inserted payment should be marked as first');
        System.assertEquals(false, sp2.First_Scheduled_Payment__c, 'Second inserted payment should not be marked as first');

        spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(0)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        spConfig.setDefinition('Scheduled_Date__c', 'static value(2017-01-02)');
        Scheduled_Payment__c sp3 = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];
        sp1 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp1.Id];
        sp2 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp2.Id];
        sp3 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp3.Id];

        System.assertEquals(false, sp1.First_Scheduled_Payment__c, 'First inserted payment should no longer be marked as first');
        System.assertEquals(false, sp2.First_Scheduled_Payment__c, 'Second inserted payment should not be marked as first');
        System.assertEquals(true, sp3.First_Scheduled_Payment__c, 'Third inserted payment should be marked as first');

        sp1.Scheduled_Date__c = sp3.Scheduled_Date__c.addDays(-1);
        update sp1;

        sp1 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp1.Id];
        sp2 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp2.Id];
        sp3 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp3.Id];

        System.assertEquals(true, sp1.First_Scheduled_Payment__c, 'First inserted payment should once again be marked as first');
        System.assertEquals(false, sp2.First_Scheduled_Payment__c, 'Second inserted payment should not be marked as first');
        System.assertEquals(false, sp3.First_Scheduled_Payment__c, 'Third inserted payment should no longer be marked as first');

        delete sp1;

        sp2 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp2.Id];
        sp3 = [Select Scheduled_Date__c, First_Scheduled_Payment__c From Scheduled_Payment__c Where Id = :sp3.Id];

        System.assertEquals(false, sp2.First_Scheduled_Payment__c, 'Second inserted payment should not be marked as first');
        System.assertEquals(true, sp3.First_Scheduled_Payment__c, 'Third inserted payment should once again be marked as first');

    }

    @isTest
    static void validateOppServiceProviderRollup() {

        Opportunity opp = TestDataFactory.getOpportunityObjects(1)[0];

        FObject accConfig = TestDataFactory.getAccountConfig(1);
        accConfig.setDefinition('Name', 'static value("Treatment Firm ")');
        accConfig.setDefinition('Name', 'serial type(number) from(1) step(1) scale(0)');
        accConfig.setDefinition('ShippingStreet', 'random type(street) group(shipping)');
        accConfig.setDefinition('ShippingPostalCode', 'random type(postalcode) group(shipping)');
        accConfig.setDefinition('ShippingCity', 'random type(city) group(shipping)');
        accConfig.setDefinition('ShippingState', 'random type(state) group(shipping)');
        accConfig.setDefinition('ShippingCountry', 'random type(country) group(shipping)');
        accConfig.setDefinition('RecordTypeId', 'static value(General_Business)');
        accConfig.setDefinition('Account_Type__c', 'static value(Treatment Provider Firm)');
        Account acc = TestDataFactory.getAccountObjects(accConfig, true)[0];

        FObject ospConfig = TestDataFactory.getOpportunityServiceProviderConfig(1);
        ospConfig.setDefinition('Allowance__c', 'static value(1000)');
        //ospConfig.setDefinition('Service_Provider_Facility__c', 'random lookup(Opportunity) source(forceea)');
        ospConfig.setDefinition('Opportunity__c', 'random lookup(Opportunity) source(forceea)');
        Opportunity_Service_Provider__c osp = TestDataFactory.getOpportunityServiceProviderObjects(ospConfig, false)[0];
        osp.Service_Provider_Facility__c = acc.Id;
        osp = TestDataFactory.getOpportunityServiceProviderObjects(ospConfig, true)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(500)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        spConfig.setDefinition('Scheduled_Date__c', 'static value(2018-01-01)');
        spConfig.setDefinition('Opportunity_Service_Provider__c', 'random lookup(Opportunity_Service_Provider__c) source(forceea)');
        Scheduled_Payment__c sp = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];

        osp = [Select Total_Scheduled_Payments__c From Opportunity_Service_Provider__c Where Id = :osp.Id];
        System.assertEquals(500, osp.Total_Scheduled_Payments__c, 'Total Scheduled Payments should be set on creation');

        /*
        sp.Drawdown_Created__c = true;
        update sp;
        osp = [Select Total_Scheduled_Payments__c From Opportunity_Service_Provider__c Where Id = :osp.Id];
        System.assertEquals(0, osp.Total_Scheduled_Payments__c, 'Scheduled Payments should not be included after DrawdownsCreated__c is set to true');

        sp.Drawdown_Created__c = false;
        */
        sp.Amount__c = 400;
        update sp;
        osp = [Select Total_Scheduled_Payments__c From Opportunity_Service_Provider__c Where Id = :osp.Id];
        System.assertEquals(400, osp.Total_Scheduled_Payments__c, 'Total Scheduled Payments should be recalculated on edit');

        delete sp;
        osp = [Select Total_Scheduled_Payments__c From Opportunity_Service_Provider__c Where Id = :osp.Id];
        System.assertEquals(0, osp.Total_Scheduled_Payments__c, 'Total Scheduled Payments should be recalculated on delete');
    }
}