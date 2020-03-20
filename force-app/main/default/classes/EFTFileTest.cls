/**
HTWELF10201C351010519EasyLegalFinana00041020206905521363 0001                   
 * @File Name          : EFTFileTest.cls
 * @Description        : 
 * @Author             : Seth Boyd
 * @Group              : 
 * @Last Modified By   : Seth Boyd
 * @Last Modified On   : 5/13/2019, 6:58:21 AM
 * @Modification Log   : 
 *==============================================================================
 * Ver         Date                     Author      		      Modification
 *==============================================================================
 * 1.0    4/22/2019, 1:39:32 PM   Seth Boyd     Initial Version
**/
@isTest(seeAllData=false)
public class EFTFileTest {
    @TestSetup
    static void setup(){
        FObject.seed = 1234;

        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];
        u.EFT_Originator_Id__c = 'TWELF10201';
        update u;
    }

    @isTest
    static void test_exact_copy_of_test_file() {
        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];

        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        FObject accConfig = TestDataFactory.getAccountConfig(1);
        Account acc = TestDataFactory.getAccountObjects(accConfig, false)[0];
        acc.Name = 'Larry Sample Facility';
        acc.AccountNumber = '123';
        acc = TestDataFactory.getAccountObjects(accConfig, true)[0];

        FObject baConfig = TestDataFactory.getBankAccountConfig(1);
        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(baConfig, false)[0];
        bankRec.Name = 'Seth Boyd';
        bankRec.Client__c = acc.Id;
        bankRec.Account__c = '466313001';
        bankRec.Bank__c = '0016';
        bankRec.Transit__c = '10329';
        //bankRec.Mark_as_Primary__c = true;
        bankRec = TestDataFactory.getBankAccountObjects(baConfig, true)[0];
        acc.Primary_Bank_Account__c = bankRec.Id;
        update acc;

        Opportunity oppRec = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        Scheduled_Payment__c spRec = TestDataFactory.getScheduledPaymentObjects(spConfig, false)[0];
        spRec.Account__c = acc.Id;
        spRec.Amount__c = 2000;
        spRec.Payment_Type__c = 'Ad-Hoc';
        spRec.Status__c = 'Scheduled';
        spRec = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];

        test.startTest();
        Date dueDate = Date.newInstance(2019, 4, 30);
        String fileText;
        Id[] ids = new Id[]{spRec.Id};
        EFTFile eft = new EFTFile(ids, dueDate);
        fileText = eft.generateFileText();
        test.stopTest();

        // EFT File object should have been created
        spRec = [Select Id, Transaction_Reference_Number__c, Name From Scheduled_Payment__c Where Id = :spRec.Id];
        EFT_File__c[] eftFileObjs = [Select Id, File_Number__c From EFT_File__c];
        System.assertEquals(1, eftFileObjs.size(), 'Should have created one EFT File Object');
        // Had to do some string manipulation since we refer to Scheduled Payment Names and File Number which are Auto-Numbers
        String compareTo = 'HTWELF10201C351300419EasyLegalFinana00041020206905521363 {0}                   \r\nDSeth Boyd              300419{1}001610329466313001   0000200000\r\nT0000000100000000200000                                                         \r\n';
        String spacedName = EFTHelper.formatString(spRec.Transaction_Reference_Number__c, '', 19, 'left');
        compareTo = String.format(compareTo, new List<Object>{eftFileObjs[0].File_Number__c, spacedName});

        System.assertEquals(compareTo, fileText, 'These files should be identical');

        validateFileFormat(fileText, u, eftSettings);
    }

    @isTest
    static void test_pull_account_from_opp() {
        // Test with no account set on SP

        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];

        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];
        Account acc = new Account(Id=bankRec.Client__c);
        acc.Primary_Bank_Account__c = bankRec.Id;
        update acc;

        Opportunity oppRec = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(1000)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        Scheduled_Payment__c spRec = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];
        spRec.Account__c = acc.Id;
        update spRec;

        test.startTest();
        String fileText;
        Id[] ids = new Id[]{spRec.Id};
        EFTFile eft = new EFTFile(ids);
        fileText = eft.generateFileText();
        test.stopTest();

        acc = [Select Id, Name From Account Where Id = :bankRec.Client__c];

        validateFileFormat(fileText, u, eftSettings);

        system.assertEquals(3, fileText.countMatches('\r\n'), 'Generated text should 3 carriage returns "\\r\n":\r\n' + fileText); // Should contain two newline chars
        if (bankRec.Name.length() > 23) {
            system.assertEquals(1, fileText.countMatches(bankRec.Name.substring(0, 23)), 'Generated text should include account name truncated to 23 digits: ' + bankRec.Name + '\r\n' + fileText);
        } else {
            system.assertEquals(1, fileText.countMatches(bankRec.Name), 'Generated text should include account name: ' + bankRec.Name + '\r\n' + fileText);
        }
    }

    @isTest
    static void test_pull_account_from_sp() {
        // test with account set on SP
        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];

        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Account[] accRecs = TestDataFactory.getAccountObjects(2);

        FObject baConfig = TestDataFactory.getBankAccountConfig(2);
        Bank_Account__c[] bankRecs = TestDataFactory.getBankAccountObjects(baConfig, false);
        // Ensure we're using different accounts
        bankRecs[0].Client__c = accRecs[0].Id;
        bankRecs[1].Client__c = accRecs[1].Id;
        TestDataFactory.getBankAccountObjects(baConfig, true);
        accRecs[0].Primary_Bank_Account__c = bankRecs[0].Id;
        accRecs[1].Primary_Bank_Account__c = bankRecs[1].Id;
        update accRecs;

        FObject oppConfig = TestDataFactory.getOpportunityConfig(1);
        Opportunity[] oppRecs = TestDataFactory.getOpportunityObjects(oppConfig, false);
        oppRecs[0].AccountId = accRecs[0].Id;
        oppRecs = TestDataFactory.getOpportunityObjects(oppConfig, true);

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(1000)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        Scheduled_Payment__c[] spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, false);
        spRecs[0].Account__c = accRecs[1].Id;
        spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, true);

        test.startTest();
        Id[] ids = new Id[]{spRecs[0].Id};
        EFTFile eft = new EFTFile(ids);
        String fileText;
        fileText = eft.generateFileText();
        test.stopTest();

        validateFileFormat(fileText, u, eftSettings);

        if (bankRecs[1].Name.length() > 23) {
            system.assertEquals(1, fileText.countMatches(bankRecs[1].Name.substring(0, 23)), 'Generated text should include account name from Scheduled Payment truncated to 23 digits: ' + bankRecs[1].Name + '\r\n' + fileText);
        } else {
            system.assertEquals(1, fileText.countMatches(bankRecs[1].Name), 'Generated text should include account name from Scheduled Payment: ' + bankRecs[1].Name + '\r\n' + fileText);
        }
    }

    /*
    @isTest
    static void test_status_exception() {
        // test with wrong status (should throw exception)
        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];

        Opportunity oppRec = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        spConfig.setDefinition('Amount__c', 'static value(1000)');
        spConfig.setDefinition('Status__c', 'static value(Sent to Bank)');
        Scheduled_Payment__c spRec = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];

        Boolean exceptionThrown = false;
        test.startTest();
        Id[] ids = new Id[]{spRec.Id};
        EFTFile eft = new EFTFile(ids);
        String fileText;
        try {
            fileText = eft.generateFileText();
        } catch (EFTFileErrorListException eList) {
            EFTFileException e = eList.eftExceptions[0];
            exceptionThrown = true;
            system.assertEquals(spRec.Id, e.id, 'Id should have been set on exception');
            system.assertEquals('Status__c', e.field, 'Exception should be related to Status__c');
        }
        test.stopTest();

        system.assert(exceptionThrown == true, 'An exception should have been thrown indicating the Status was wrong');
    }
    */
 
    @isTest
    static void test_bank_account_exception() {
        // test with no bank account set
        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Opportunity oppRec = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(1);
        //spConfig.setDefinition('Account__c', 'static value(' + acc.Id + ')');
        spConfig.setDefinition('Amount__c', 'static value(1000)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        Scheduled_Payment__c spRec = TestDataFactory.getScheduledPaymentObjects(spConfig, true)[0];

        Boolean exceptionThrown = false;
        test.startTest();
        Id[] ids = new Id[]{spRec.Id};
        EFTFile eft = new EFTFile(ids);
        String fileText;
        try {
            fileText = eft.generateFileText();
        } catch (EFTFileErrorListException eList) {
            EFTFileException e = eList.eftExceptions[0];
            exceptionThrown = true;
            system.assertEquals(spRec.Id, e.id, 'Id should have been set on exception');
            system.assertEquals('Current_Bank_Account_URL__c', e.field, 'Id should have been set on exception');
        }
        test.stopTest();

        system.assert(exceptionThrown == true, 'An exception should have been thrown indicating a bank account was needed');
    }

    @isTest
    static void test_multiple_scheduled_payments() {
        // Test with no account set on SP
        User u = [Select Id, EFT_Originator_Id__c From User Where Id = :UserInfo.getUserId()][0];

        EFT_File_Setting__c eftSettings = TestDataFactory.getEFTFileSettings();

        Bank_Account__c bankRec = TestDataFactory.getBankAccountObjects(1)[0];
        Account acc = new Account(Id=bankRec.Client__c);
        acc.Primary_Bank_Account__c = bankRec.Id;
        update acc;

        Opportunity oppRec = TestDataFactory.getOpportunityObjects(1)[0];

        FObject spConfig = TestDataFactory.getScheduledPaymentConfig(2);
        spConfig.setDefinition('Account__c', 'random lookup(Account) source(forceea)');
        spConfig.setDefinition('Amount__c', 'static value(123.45)');
        spConfig.setDefinition('Status__c', 'static value(Scheduled)');
        Scheduled_Payment__c[] spRecs = TestDataFactory.getScheduledPaymentObjects(spConfig, true);

        test.startTest();
        Id[] ids = new Id[]{spRecs[0].Id, spRecs[1].Id};
        EFTFile eft = new EFTFile(ids);
        String fileText;
        fileText = eft.generateFileText();
        test.stopTest();

        acc = [Select Id, Name From Account Where Id = :bankRec.Client__c];

        validateFileFormat(fileText, u, eftSettings);

        system.assertEquals(3, fileText.countMatches('\r\n'), 'Generated text should be 4 lines:' + fileText); // Should contain 3 newline chars
        system.assertEquals(0, fileText.countMatches('12345'), 'Generated text should not include amount for individual Scheduled Payments:' + fileText);
        system.assertEquals(2, fileText.countMatches('24690'), 'Generated text should include total amount for all grouped Scheduled Payments:' + fileText);
        system.assertEquals(1, fileText.countMatches(bankRec.Name), 'Generated text should include account name for the grouped Scheduled Payments:' + fileText);
    }

    static void validateFileFormat(String fileText, User u, EFT_File_Setting__c eftSettings) {
        String[] lines = fileText.split('\r\n');
        // confirm that all lines are 80 chars long (81 with carriage return)
        for (String line : lines) {
            System.debug(line);
            System.assertEquals(80, line.length(), 'All generated lines must be 80 characters long:"' + line + '"');
        }

        Integer ti = lines.size() - 1;

        for (Integer i = 0; i < lines.size(); i++) {
            String line = lines[i];
            if (i == 0) {
                System.assertEquals('H', String.fromCharArray(new List<Integer> {line.charAt(0)}), 'Header lines must start with an "H":"' + line + '"');
                System.assertEquals(1, line.indexOf(u.EFT_Originator_Id__c), 'User\'s EFT Originator Id must appear starting at character 1 (0 index):"' + line + '"');
                System.assertEquals('C', String.fromCharArray(new List<Integer> {line.charAt(11)}), 'Transaction Type must by "C" at char 11 (0 index):"' + line + '"');
            } else if (i == ti) {
                System.assertEquals('T', String.fromCharArray(new List<Integer> {line.charAt(0)}), 'Trailer lines must start with a "T":"' + line + '"');
            } else {
                System.assertEquals('D', String.fromCharArray(new List<Integer> {line.charAt(0)}), 'Detail lines must start with a "D":"' + line + '"');
            }
        }
    }
}