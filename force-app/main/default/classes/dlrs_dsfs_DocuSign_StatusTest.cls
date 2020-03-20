/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_dsfs_DocuSign_StatusTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_dsfs_DocuSign_StatusTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new dsfs__DocuSign_Status__c());
    }
}