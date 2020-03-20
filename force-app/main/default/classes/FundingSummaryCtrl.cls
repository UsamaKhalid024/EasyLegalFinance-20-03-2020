public class FundingSummaryCtrl {
	
    @AuraEnabled
    public static String getFirstBoxCtrl(){
        //Using report id for example purpose
        Report reportRec = [SELECT
                Id
        FROM Report
        WHERE Id = '00O19000000iDABEA2'];
    
        Reports.ReportResults reportResult =
                Reports.ReportManager.runReport(reportRec.Id, true);
        
        /* --- get summary --- */
        	//get the reports factmap fro the report ID and select the top level fact map - (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_analytics_fact_map.htm)
    	Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)reportResult.getFactMap().get('T!T');

    	//get the aggregate values in the report, this includes the RowCount (Grand Total) and any columns that have been summarized.
    	List<Reports.SummaryValue> summaryDate = factDetails.getAggregates();

    	//The row count will be the last aggregate in the list, any summaries will come first and you can loop through them in the method below.
    	//Decimal grandTotal =  (Decimal)profileCounts.get(profileCounts.size()-1).getValue(); 

        return JSON.serialize(summaryDate);
    }
    @AuraEnabled
    public static String getSecondBoxCtrl(){
        //Using report id for example purpose
        Report reportRec = [SELECT
                Id
        FROM Report
        WHERE Id = '00O19000000iDh0EAE'];
    
        Reports.ReportResults reportResult =
                Reports.ReportManager.runReport(reportRec.Id, true);
        
         /* --- get summary --- */
    	Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)reportResult.getFactMap().get('T!T');

    	List<Reports.SummaryValue> summaryDate = factDetails.getAggregates();

        return JSON.serialize(summaryDate);
    }
    @AuraEnabled
    public static String getFourthBoxClosedWithLoanCtrl(){
        //Using report id for example purpose
        Report reportRec = [SELECT
                Id
        FROM Report
        WHERE Id = '00O19000000iDh5EAE'];
    
        Reports.ReportResults reportResult =
                Reports.ReportManager.runReport(reportRec.Id, true);
        
         /* --- get summary --- */
    	Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)reportResult.getFactMap().get('T!T');

    	List<Reports.SummaryValue> summaryDate = factDetails.getAggregates();

        return JSON.serialize(summaryDate);
    }
    @AuraEnabled
    public static String getFourthBoxPaidOffCtrl(){
        //Using report id for example purpose
        Report reportRec = [SELECT
                Id
        FROM Report
        WHERE Id = '00O19000000iDhAEAU'];
    
        Reports.ReportResults reportResult =
                Reports.ReportManager.runReport(reportRec.Id, true);
        
         /* --- get summary --- */
    	Reports.ReportFactWithDetails factDetails = (Reports.ReportFactWithDetails)reportResult.getFactMap().get('T!T');

    	List<Reports.SummaryValue> summaryDate = factDetails.getAggregates();

        return JSON.serialize(summaryDate);
    }
    
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            Funding_summary__c fs = Funding_summary__c.getOrgDefaults();
            
            fs.End_date__c = endDt;
            fs.Start_Date__c = startDt;
            
            update fs;
            
            
            
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        } 
    }
    
    @AuraEnabled
    public static Funding_summary__c getCustomSetting(){
        Funding_summary__c fs = Funding_summary__c.getOrgDefaults();
        return fs;
    }
}