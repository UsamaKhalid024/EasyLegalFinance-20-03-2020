public class LeadsPerMonthReportPrintController {
    public List<LeadsPerMonthReportCtlr.wrapperClass> data{get; private set;}
    public Actual_Sales_by_Month_Report__c LFSR{get;set;}
    public integer rhinocount{get;set;}
    public integer elficount{get;set;}
    
    public integer rhinoConvertedcount{get;set;}
    public integer elfiConvertedcount{get;set;}
    
    public double rhinoAmount{get;set;}
    public double elfiAmount{get;set;}
	public LeadsPerMonthReportPrintController()
    {
        LFSR = Actual_Sales_by_Month_Report__c.getOrgDefaults();
        data = LeadsPerMonthReportCtlr.getLeadsByMonth(LFSR.start_Date__c+'',LFSR.End_Date__c+'',LFSR.Business_Unit__c);
        rhinocount = 0;
        elficount = 0;
        
        rhinoConvertedcount = 0;
        elfiConvertedcount = 0;
        
        rhinoAmount = 0;
        elfiAmount = 0;
        for(LeadsPerMonthReportCtlr.wrapperClass d: data)
        {
            rhinocount += d.RecordCountRhino;
            elficount += d.RecordCountELFI;
            
            rhinoConvertedcount += d.SumofConvertedLeadsRhino;
            elfiConvertedcount += d.SumofConvertedLeadsELFI;
            
            rhinoAmount += d.SumofAmountPaidtoClientRhino;
            elfiAmount += d.SumofAmountPaidtoClientELFI;
        }
    }
}