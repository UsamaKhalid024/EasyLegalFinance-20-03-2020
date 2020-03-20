/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Opportunity_Service_ProviderTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Opportunity_Service_ProviderTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Opportunity_Service_Provider__c());
    }
}