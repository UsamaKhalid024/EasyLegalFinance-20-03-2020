@isTest
private class InterestCalculatorTests
{

    @isTest
    static void baseCalculationValidation0to4()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown0to4');
        system.assertEquals(2480.00, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2524.95, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2536.48, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2542.30, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2508.80, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(480.00, lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(524.95, lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(536.48, lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(542.30, lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(508.80, lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);      

        system.assertEquals(1.63, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.66, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.67, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.67, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.65, lstDraw[4].Per_Diem_as_of_Payout_Date__c);            

    }

    @isTest
    static void baseCalculationValidation5to9()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown5to9');

        system.assertEquals(2369.49, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1451.17, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(7867.60, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(7035.55, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(5591.31, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(369.49   , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(451.17   , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2867.60  , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2035.55  , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(591.31  , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);        

        system.assertEquals(1.56, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.95, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(5.17, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(4.63, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    
    }

    @isTest
    static void baseCalculationValidation10to14()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown10to14');
        system.assertEquals(6272.00, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(5608.70, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1595.60, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(7024.64, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);       
        system.assertEquals(5591.31, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(1272.00  , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(608.70   , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1595.60  , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2024.64  , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(591.31   , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);       

        system.assertEquals(4.12, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(3.69, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.05, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(4.62, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    

        //check the temp date formulas
        system.assertEquals(6272.00, lstDraw[0].Outstanding_Balance_as_of_Temp_Date__c);
        system.assertEquals(5608.70, lstDraw[1].Outstanding_Balance_as_of_Temp_Date__c);
        system.assertEquals(1595.60, lstDraw[2].Outstanding_Balance_as_of_Temp_Date__c);
        system.assertEquals(7024.64, lstDraw[3].Outstanding_Balance_as_of_Temp_Date__c);      
        system.assertEquals(5591.31, lstDraw[4].Outstanding_Balance_as_of_Temp_Date__c);

        system.assertEquals(1272.00  , lstDraw[0].Accrued_Interest_as_of_Temp_Date__c);
        system.assertEquals(608.70   , lstDraw[1].Accrued_Interest_as_of_Temp_Date__c);
        system.assertEquals(1595.60  , lstDraw[2].Accrued_Interest_as_of_Temp_Date__c);
        system.assertEquals(2024.64  , lstDraw[3].Accrued_Interest_as_of_Temp_Date__c);
        system.assertEquals(591.31   , lstDraw[4].Accrued_Interest_as_of_Temp_Date__c);     

    }


    @isTest
    static void baseCalculationValidation15to19()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown15to19');
        system.assertEquals(2000.00 , lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2000.00 , lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2000.00 , lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2480.00 , lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2403.73 , lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(0.00     , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(0.00     , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(0.00     , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(480.00   , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(403.73   , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);       

        system.assertEquals(0.00, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.63, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.58, lstDraw[4].Per_Diem_as_of_Payout_Date__c);            

    }
    
    @isTest
    static void baseCalculationValidation20to24()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown20to24');

system.debug('lstDraw - 20'+lstDraw[0]);            
        system.assertEquals(2481.46, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2510.36, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2526.57, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2538.14, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2543.97, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(481.46 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(510.36 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(526.57 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(538.14 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(543.97 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(1.63, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.65, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.66, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.67, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.67, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    

    }
    
    @isTest
    static void baseCalculationValidation25to29()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown25to29');
        
        system.assertEquals(3815.50, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(3950.10, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(4026.96, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(4082.43, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(4110.60, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(1815.50 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1950.10 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2026.96 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2082.43 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2110.60 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(2.51, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.60, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.65, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.68, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.70, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    

    }
        

    @isTest
    static void baseCalculationValidation30to34()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown30to34');
        system.assertEquals(0.00, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(13028.86, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(14309.66, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(6713.74, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(16191.87, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(2107.90 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1385.11 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1288.89 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(713.74 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1891.10 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(0.00, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(8.57, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(9.41, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(4.41, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
system.debug('lstDraw - 34'+lstDraw[0]);    
        system.assertEquals(10.65, lstDraw[4].Per_Diem_as_of_Payout_Date__c);   


    }
            
    @isTest
    static void baseCalculationValidation35to39()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown35to39');
        
        system.assertEquals(6793.43, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);      
        system.assertEquals(5360.28, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(8980.45, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(11374.43, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(7601.55, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(83.85 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(0.00 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(3620.17 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(4585.22 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(812.34 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(4.47, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(3.52, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(5.90, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(7.48, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(5.00, lstDraw[4].Per_Diem_as_of_Payout_Date__c);

    }


    @isTest
    static void baseCalculationValidation40to44()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown40to44');
        
        system.assertEquals(8521.68, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(9538.34, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(10689.59, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(11367.37, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2816.29, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        
        system.assertEquals(924.84 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1024.61 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(1160.12 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(684.42 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(0.00 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(5.60, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(6.27, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(7.03, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(7.47, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.85, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    


    }
        
        
    @isTest
    static void baseCalculationValidation45to50()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown45to50');
        
        system.assertEquals(2508.80, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2531.25, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2553.80, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2576.45, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2599.20, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2622.05, lstDraw[5].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);  

        system.assertEquals(508.80 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(531.25 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(553.80 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(576.45 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(599.20 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(622.05 , lstDraw[5].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(1.65, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.73, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.82, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.91, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(1.99, lstDraw[4].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.08, lstDraw[5].Per_Diem_as_of_Payout_Date__c);

    }
    
    @isTest
    static void baseCalculationValidation51to56()
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataDrawdown51to56');
        
        system.assertEquals(2645.00, lstDraw[0].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2668.05, lstDraw[1].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2497.19, lstDraw[2].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2570.74, lstDraw[3].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2656.59, lstDraw[4].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(2749.08, lstDraw[5].OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);

        system.assertEquals(645.00 , lstDraw[0].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(668.05 , lstDraw[1].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(497.19 , lstDraw[2].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(570.74 , lstDraw[3].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(656.59 , lstDraw[4].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
        system.assertEquals(749.08 , lstDraw[5].ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);     

        system.assertEquals(2.17, lstDraw[0].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(2.27, lstDraw[1].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[2].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[3].Per_Diem_as_of_Payout_Date__c);
        system.assertEquals(0.00, lstDraw[4].Per_Diem_as_of_Payout_Date__c);    
        system.assertEquals(0.00, lstDraw[5].Per_Diem_as_of_Payout_Date__c);
    }       

    @isTest
    static void PartialPaymentTest()
    //Instead of relying on loading data containing the paid amount, will load a partial payments as a new Drawdown and allow triggers and DLRS to load Paid Amount
    //Use data from 10-14 tests
    {
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataPartialPayment');

        Opportunity Opty = new Opportunity(Id=lstOpty[12].id, 
                                           PAYOUT_DATE__C=Date.newInstance(2018,12,31));
        update(Opty);

       	List<Drawdown__c> lstDraw2 = [Select Id,PAYOUT_DATE__C,Compounding_Interest__c,Sum_of_Repayments__c, Interest_up_to_Last_Repayment__c, Interest_Accrual_Years__c,Compounding_Frequency__c,Amount_Adjusted_for_Repayments__c,Interest_Rate__c,Interest_Accrual_Days__c,OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C, ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C, Per_Diem_as_of_Payout_Date__c,Outstanding_Balance_as_of_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c
									  from Drawdown__c where PAYMENT_METHOD__C <> 'Payment'];
        system.assertEquals(2, lstDraw2.size(), 'Drawdowns not found on query.');
        for (drawdown__c d : lstDraw2){
            if(d.id == lstDraw[0].id){
                system.assertEquals(1595.60, d.OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(1595.60, d.ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(1.05, d.Per_Diem_as_of_Payout_Date__c);
            }else if(d.id == lstDraw[1].id){
                system.assertEquals(7035.55, d.OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(2035.55, d.ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(4.63, d.Per_Diem_as_of_Payout_Date__c);
            }else {
                system.assertEquals(1, 2, 'Drawdowns are misaligned.');
            }
        }

        Opty = new Opportunity(Id=lstOpty[12].id, 
                                           PAYOUT_DATE__C=Date.newInstance(2017,12,31));
        update(Opty);

        lstDraw2 = [Select Id,PAYOUT_DATE__C,Compounding_Interest__c,Sum_of_Repayments__c, Interest_up_to_Last_Repayment__c, Interest_Accrual_Years__c,Compounding_Frequency__c,Amount_Adjusted_for_Repayments__c,Interest_Rate__c,Interest_Accrual_Days__c,OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C, ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C, Per_Diem_as_of_Payout_Date__c,Outstanding_Balance_as_of_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c
									  from Drawdown__c where PAYMENT_METHOD__C <> 'Payment'];

        for (drawdown__c d : lstDraw2){
            if(d.id == lstDraw[0].id){
                system.assertEquals(1272.00, d.OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(1272.00, d.ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(0.84, d.Per_Diem_as_of_Payout_Date__c);
            }
            if(d.id == lstDraw[1].id){
                system.assertEquals(5608.70, d.OUTSTANDING_BALANCE_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(608.70, d.ACCRUED_INTEREST_AS_OF_PAYOUT_DATE__C);
                system.assertEquals(3.69, d.Per_Diem_as_of_Payout_Date__c);
            }
        }
    }


    public static testmethod void sinceInceptionYr1(){
        //Use the Portfolio reports to set the TempDate and payment allocation temp dates
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataPartialPayment');
        Test.startTest();
        Portfolio_Report__c pr = new Portfolio_Report__c();
        pr.To_Date__c = Date.newInstance(2017,12,31);
        pr.Since_Inception__c = true;
        insert pr;
        
        system.assertEquals('In Progress', [SELECT status__c FROM Portfolio_Report__c LIMIT 1].status__c);
       
        Test.stopTest();
        List<Drawdown__c> lstDraw2 = [Select Id,Accrued_Interest_as_of_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Reporting_From_Date__c, Accrued_Interest_as_of_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Reporting_To_Date__c
                                      from Drawdown__c where PAYMENT_METHOD__C <> 'Payment'];
        system.assertEquals(2, lstDraw2.size(), 'Drawdowns not found on query.');
        for (drawdown__c d : lstDraw2){
            if(d.id == lstDraw[0].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,01,01));

                system.assert(d.Outstanding_Balance_as_of_To_Date__c==1272.00);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==1272.00);
                system.assert(d.Reporting_To_Date__c==Date.newInstance(2017,12,31));

            }else if(d.id == lstDraw[1].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,06,30));

//system.debug('draw - 11'+d);
                system.assert(d.Outstanding_Balance_as_of_To_Date__c==5608.70);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==608.70);
                system.assert(d.Reporting_To_Date__c==Date.newInstance(2017,12,31));
            }else {
                system.assertEquals(1, 2, 'Drawdowns are misaligned.');
            }
        }
    }


    public static testmethod void sinceInception2Yrs(){
        //Use the Portfolio reports to set the TempDate and payment allocation temp dates
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataPartialPayment');
        Test.startTest();
        Portfolio_Report__c pr = new Portfolio_Report__c();
        pr.To_Date__c = Date.newInstance(2018,12,31);
        pr.Since_Inception__c = true;
        insert pr;
        
        system.assertEquals('In Progress', [SELECT status__c FROM Portfolio_Report__c LIMIT 1].status__c);
       
        Test.stopTest();
        List<Drawdown__c> lstDraw2 = [Select Id,Accrued_Interest_as_of_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Reporting_From_Date__c, Accrued_Interest_as_of_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Reporting_To_Date__c,
                                        Outstanding_Balance_as_of_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c,Temp_Payout_Date__c,Date_of_Last_Repayment_b4_Temp_Date__c,Interest_End_Date_at_Last_Rpymnt_b4_Temp__c,Interest_up_to_Last_Repayment_b4_Temp_Dt__c,Sum_of_Repayments_b4_Temp_Date__c
                                      from Drawdown__c ];

        for (drawdown__c d : lstDraw2){
            if(d.id == lstDraw[0].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,01,01));
//system.debug('draw - 10'+d);
                system.assert(d.Outstanding_Balance_as_of_To_Date__c==1595.60);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==1595.60);
                system.assert(d.Reporting_To_Date__c==Date.newInstance(2018,12,31));


            }else if(d.id == lstDraw[1].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,06,30));

//system.debug('draw - 11'+d);
                system.assert(d.Outstanding_Balance_as_of_To_Date__c==7035.55);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==2035.55);
                system.assert(d.Reporting_To_Date__c==Date.newInstance(2018,12,31));
            }
        }
    }

    public static testmethod void sinceInception1YrLessDay(){
        //this test should exclude the payment
        List<Account> lstAcc = Test.loadData(Account.sObjectType,'TestDataAccount');
        List<Contact> lstCon = Test.loadData(Contact.sObjectType,'TestDataContact');
        List<Opportunity> lstOpty = Test.loadData(Opportunity.sObjectType,'TestDataOpportunity');
        List<Drawdown__c> lstDraw = Test.loadData(Drawdown__c.sObjectType,'TestDataPartialPayment');
        Test.startTest();
        Portfolio_Report__c pr = new Portfolio_Report__c();
        pr.To_Date__c = Date.newInstance(2017,12,30);
        pr.Since_Inception__c = true;
        insert pr;
        
        system.assertEquals('In Progress', [SELECT status__c FROM Portfolio_Report__c LIMIT 1].status__c);
       
        Test.stopTest();
        List<Drawdown__c> lstDraw2 = [Select Id,Accrued_Interest_as_of_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Reporting_From_Date__c, Accrued_Interest_as_of_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Reporting_To_Date__c,
                                        Outstanding_Balance_as_of_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c,Temp_Payout_Date__c,Date_of_Last_Repayment_b4_Temp_Date__c,Interest_End_Date_at_Last_Rpymnt_b4_Temp__c,Interest_up_to_Last_Repayment_b4_Temp_Dt__c,Sum_of_Repayments_b4_Temp_Date__c
                                      from Drawdown__c ];

        for (drawdown__c d : lstDraw2){
            if(d.id == lstDraw[0].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,01,01));
                system.assert(d.Outstanding_Balance_as_of_To_Date__c==6268.11);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==1268.11);
            }else if(d.id == lstDraw[1].id){
                system.assert(d.Outstanding_Balance_as_of_From_Date__c==0.00);
                system.assert(d.Accrued_Interest_as_of_From_Date__c==0.00);
                system.assert(d.Reporting_From_Date__c==Date.newInstance(2017,06,30));
                system.assert(d.Outstanding_Balance_as_of_To_Date__c==5605.22);
                system.assert(d.Accrued_Interest_as_of_To_Date__c==605.22);

            }
        }
    }
}