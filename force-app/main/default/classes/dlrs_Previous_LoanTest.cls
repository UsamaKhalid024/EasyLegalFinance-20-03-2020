/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Previous_LoanTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Previous_LoanTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Previous_Loan__c());
    }
}