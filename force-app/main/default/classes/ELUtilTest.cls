public with sharing class ELUtilTest {
    public ELUtilTest() {
        
    }
public static Account createAccount(){
        Account account1 = new Account();
            account1.Name='Jackie';
            account1.BillingStreet = 'Test';
            account1.BillingState = 'CA';
            account1.BillingCity = 'City';
            account1.BillingPostalCode = '92630';
            account1.Billingcountry='America';
            account1.ShippingStreet = 'Test';
            account1.ShippingState = 'California';
            account1.ShippingCountry = 'UNITED STATES';
            account1.ShippingPostalCode = '92630';
            account1.ShippingCity = 'Lake Forest';
            account1.Shippingcountry='England';
            account1.Account_Type__c = 'Treatment Provider Firm';
        insert account1;
        return account1;
    }
    public static Contact createContact(Id accId){

        Contact res = new Contact(
            AccountId = accId,
            LastName = 'Test',
            FirstName = 'Test',
            Phone = '(91) 4010 0000',
            Email = 'test@test.com',
            MailingStreet = '123 Test.',
            MailingCity = 'Test',
            MailingState = 'CA',
            MailingCountry = 'UNITED STATES',
            MailingPostalCode = '92630'
        );
        insert res;
        return res;
    }
}