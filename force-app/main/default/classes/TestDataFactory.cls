/**
 * @File Name          : TestDataFactory.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/13/2019, 6:51:51 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    5/1/2019, 1:05:57 PM   Seth Boyd     Initial Version
**/
@isTest
public class TestDataFactory {
    private static EFT_File_Setting__c eftSettings;

    public static EFT_File_Setting__c getEFTFileSettings() {
        if (eftSettings == null) {
            eftSettings = new EFT_File_Setting__c();
            eftSettings.Account_Number_For_Returns__c = '06905521363';
            eftSettings.Transit_Number_For_Returns__c = '000410202';
            eftSettings.Originator_Short_Name__c = 'EasyLegalFinana';
            insert eftSettings;
        }
        return eftSettings;
    }

    public static FObject getUserConfig(Integer count) {
        FObject userConfig = new Fobject('User', count);
        return userConfig;
    }

    public static User[] getUserObjects(FObject userConfig, Boolean doInsert) {
        if (doInsert) {
            userConfig.insertRecords(true);
        }
        return (List<User>)userConfig.getRecords();
    }

    public static User[] getUserObjects(Integer count) {
        return getUserObjects(getUserConfig(count), true);
    }

    public static FObject getContactConfig(Integer count) {
        FObject conConfig = new Fobject('Contact', count);
        Contact acc = new Contact();
        conConfig.setDefinition('ELF_File_No__c', 'random type(string) minlength(4) maxlength(5) startwith(digit) include(digit)');
        conConfig.setDefinition('MailingStreet', 'random type(street) group(mailing)');
        conConfig.setDefinition('MailingPostalCode', 'random type(postalcode) group(mailing)');
        conConfig.setDefinition('MailingCity', 'random type(city) group(mailing)');
        conConfig.setDefinition('MailingState', 'random type(state) group(mailing)');
        conConfig.setDefinition('MailingCountry', 'random type(country) group(mailing)');
        return conConfig;
    }

    public static Contact[] getContactObjects(FObject conConfig, Boolean doInsert) {
        if (doInsert) {
            conConfig.insertRecords(true);
        }
        return (List<Contact>)conConfig.getRecords();
    }

    public static Contact[] getContactObjects(Integer count) {
        return getContactObjects(getContactConfig(count), true);
    }

    public static FObject getAccountConfig(Integer count) {
        FObject accConfig = new Fobject('Account', count);
        Account acc = new Account();
        accConfig.setDefinition('Business_Unit__c', 'static value(Elfi)');
        accConfig.setDefinition('ShippingStreet', 'random type(street) group(shipping)');
        accConfig.setDefinition('ShippingPostalCode', 'random type(postalcode) group(shipping)');
        accConfig.setDefinition('ShippingCity', 'random type(city) group(shipping)');
        accConfig.setDefinition('ShippingState', 'random type(state) group(shipping)');
        accConfig.setDefinition('ShippingCountry', 'random type(country) group(shipping)');
        accConfig.setDefinition('BillingStreet', 'random type(street) group(billing)');
        accConfig.setDefinition('BillingPostalCode', 'random type(postalcode) group(billing)');
        accConfig.setDefinition('BillingCity', 'random type(city) group(billing)');
        accConfig.setDefinition('BillingState', 'random type(state) group(billing)');
        accConfig.setDefinition('BillingCountry', 'random type(country) group(billing)');
        //accConfig.setDefinition('Primary_Contact__c', 'random lookup(Contact) source(forceea)');
        return accConfig;
    }

    public static Account[] getAccountObjects(FObject accConfig, Boolean doInsert) {
        if (doInsert) {
            accConfig.insertRecords(true);
        }
        return (List<Account>)accConfig.getRecords();
    }

    public static Account[] getAccountObjects(Integer count) {
        return getAccountObjects(getAccountConfig(count), true);
    }

    public static FObject getBankAccountConfig(Integer count) {
        FObject baConfig = new Fobject('Bank_Account__c', count);
        baConfig.setDefinition('Name', 'static value(First Last)');
        baConfig.setDefinition('Account__c', 'static value(222-222-222)');
        baConfig.setDefinition('Bank__c', 'static value(0333)');
        baConfig.setDefinition('Transit__c', 'static value(44444)');
        baConfig.setDefinition('Mark_as_Primary__c', 'static value(true)');
        return baConfig;
    }

    public static Bank_Account__c[] getBankAccountObjects(FObject baConfig, Boolean doInsert) {
        if (doInsert) {
            baConfig.insertRecords(true);
        }
        return (List<Bank_Account__c>)baConfig.getRecords();
    }

    public static Bank_Account__c[] getBankAccountObjects(Integer count) {
        return getBankAccountObjects(getBankAccountConfig(count), true);
    }

    public static FObject getOpportunityConfig(Integer count) {
        FObject oppConfig = new Fobject('Opportunity', count);
        oppConfig.setDefinition('Amount', 'random type(number) from(10000) to(50000) scale(0)');
        oppConfig.setDefinition('Admin_Fee__c', 'static value(475)');
        oppConfig.setDefinition('StageName', 'static value(Loan Approved)');
        oppConfig.setDefinition('Stage_Status__c', 'static value(File Sent for EFT)');
        oppConfig.setDefinition('AccountId', 'random lookup(Account) source(forceea)');
        //accConfig.setDefinition('Primary_Contact__c', 'random lookup(Contact) source(forceea)');
        oppConfig.setDefinition('Minimum_Interest_Period__c', 'random type(picklist)');
        oppConfig.setDefinition('Interest_Deferral_Period__c', 'random type(picklist)');
        oppConfig.setDefinition('Interest_Rate__c', 'static value(0.245)');
        oppConfig.setDefinition('Interest_Compounding_Period__c', 'static value(Simple Interest)');
        return oppConfig;
    }

    public static Opportunity[] getOpportunityObjects(FObject oppConfig, Boolean doInsert) {
        if (doInsert) {
            oppConfig.insertRecords(true);
        }
        return (List<Opportunity>)oppConfig.getRecords();
    }

    public static Opportunity[] getOpportunityObjects(Integer count) {
        return getOpportunityObjects(getOpportunityConfig(count), true);
    }

    public static FObject getScheduledPaymentConfig(Integer count) {
        FObject spConfig = new Fobject('Scheduled_Payment__c', count);
        return spConfig;
    }

    public static Scheduled_Payment__c[] getScheduledPaymentObjects(FObject spConfig, Boolean doInsert) {
        if (doInsert) {
            spConfig.insertRecords(true);
        }
        return (List<Scheduled_Payment__c>)spConfig.getRecords();
    }

    public static Scheduled_Payment__c[] getScheduledPaymentObjects(Integer count) {
        return getScheduledPaymentObjects(getScheduledPaymentConfig(count), true);
    }

    public static FObject getOpportunityServiceProviderConfig(Integer count) {
        FObject ospConfig = new Fobject('Opportunity_Service_Provider__c', count);
        return ospConfig;
    }

    public static Opportunity_Service_Provider__c[] getOpportunityServiceProviderObjects(FObject ospConfig, Boolean doInsert) {
        if (doInsert) {
            ospConfig.insertRecords(true);
        }
        return (List<Opportunity_Service_Provider__c>)ospConfig.getRecords();
    }

    public static Opportunity_Service_Provider__c[] getOpportunityServiceProviderObjects(Integer count) {
        return getOpportunityServiceProviderObjects(getOpportunityServiceProviderConfig(count), true);
    }

    public static FObject getDrawdownDrawdownConfig(Integer count) {
        FObject ddConfig = new Fobject('Drawdown__c', count);
        return ddConfig;
    }

    public static Drawdown__c[] getDrawdownDrawdownObjects(FObject ddConfig, Boolean doInsert) {
        if (doInsert) {
            ddConfig.insertRecords(true);
        }
        return (List<Drawdown__c>)ddConfig.getRecords();
    }

    public static Drawdown__c[] getDrawdownDrawdownObjects(Integer count) {
        return getDrawdownDrawdownObjects(getDrawdownDrawdownConfig(count), true);
    }
}
/*
BankAccountsControllerTest,CSL_OpportunityServiceProviderCtlrTest,CustomerViewComponentCtlrTest,DrawdownHelperTest,EFTFileTest,FundingDetailsComponentCtlrTest,OpportunityViewComponentCtlrTest,PaymentControllerTest,ScheduledPaymentHelperTest,ScheduledPaymentTriggerHandlerTest,TriggerHandler_Test,dlrs_OpportunityTest,dlrs_Opportunity_Service_ProviderTest,dlrs_Scheduled_PaymentTest
*/