/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Scheduled_PaymentTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Scheduled_PaymentTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Scheduled_Payment__c());
    }
}