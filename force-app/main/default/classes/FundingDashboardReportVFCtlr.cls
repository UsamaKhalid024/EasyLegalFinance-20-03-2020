public with sharing class FundingDashboardReportVFCtlr {
    public String startDate{get;set;}
    public String endDate{get;set;}
    public String businessUnit{get;set;}

    public FundingDashboardReportVFCtlr() {
        Date dt = Date.today();
        String paramBusinessUnit = ApexPages.currentPage().getParameters().get('BusinessUnit');
        String paramStartDate = ApexPages.currentPage().getParameters().get('StartDate');
        String paramEndDate = ApexPages.currentPage().getParameters().get('EndDate');

        this.businessUnit = !String.isEmpty(paramBusinessUnit) ? paramBusinessUnit : 'ELFI';
        this.startDate = !String.isEmpty(paramStartDate)? paramStartDate : (dt.addDays(-30) + '');
        this.endDate = !String.isEmpty(paramEndDate)? paramEndDate : (dt + '');

    }

    public List<FundingDashboardCtrl.LoanProgressionData> getData(){
        return FundingDashboardCtrl.getData(this.startDate, this.endDate, this.businessUnit);
    }
}