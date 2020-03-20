global class PortfolioReportCalculateData implements Database.Batchable<sObject> {
        /*------------------------------------------------------------
        Author: Basil Dobek
        Company: Deloitte
        Description:  Calculate the interest accrued on all drawdowns as of the From date and To Date.
                      These values are saved in From and To fields.
                      Steps are:
                           1) update "Temp_Payout_Date__c" on all Drawdown ALlocations to the From Date
                           2) Update "Temp_Payout_Date__c" on all Drawdowns to the From Date
                           3) Save the interest and balance in the from date fields
                           4) update "Temp_Payout_Date__c" on all Drawdown ALlocations to the TO Date
                           5) Update "Temp_Payout_Date__c" on all Drawdowns to TO From Date     
                           6) Save the interest and balance in the from date fields     
                    I update the Drawdown allocations before the Drawdowns as the DLRS will update the Drawdowns based on the Drawdown Allocation information.         
        Inputs:   
            
        History
        <Date> <Authors Name> <Brief Description of Change>
        ------------------------------------------------------------*/  
    String query;
    public Date fromDate;  // date we are calcuating from
    public Date toDate;    // date we are calculating to
    public Boolean sinceInception;  // use this to indicate calculation since the drawdown date 
    public id portfolioReportId;  // id of the portfolio report object used to launch job
    
    global PortfolioReportCalculateData() {
    
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query='SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c,' +
                     'Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c,'+
                     'Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, '+
                     'Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Payment_Method__c != \'Payment\' AND ' +
                     '(Interest_Rate__c > 0) AND (Compounding_Interest__c = false or Compounding_Frequency__c >0)';


        //set the batch instance id on the portfolio report.
        portfolio_report__c pr = [select id,Business_Unit__c, status__c, errors__c,batch_Instance_id__c from portfolio_report__c where id =:portfolioReportId ];
        pr.batch_Instance_id__c=bc.getJobId();  
        pr.errors__c = 'Batch started at:' + dateTime.now().formatLong() + ',   ';
        update pr;
        List<Opportunity> oppList;
        System.debug('Business Unit: ' + pr.Business_Unit__c);
        if (pr.Business_Unit__c != 'All'){
            oppList = [select Id from Opportunity where AccountId in (select Id from Account where Business_Unit__c=:pr.Business_Unit__c)];
            System.debug('Opps: ' + oppList.size());
            return Database.getQueryLocator([select id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Payment_Method__c != 'Payment' AND  (Interest_Rate__c > 0) AND (Compounding_Interest__c = false or Compounding_Frequency__c >0) and (Opportunity__c in: oppList)]);
        }
        else return Database.getQueryLocator([select id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c, Accrued_Interest_as_of_Temp_Date__c from drawdown__c where Payment_Method__c != 'Payment' AND  (Interest_Rate__c > 0) AND (Compounding_Interest__c = false or Compounding_Frequency__c >0)]);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        try{
            /*
                Fahad: Whole lagic is packed into a static method
                this logic needs to be executed for each opportunit while adding criticl dates to them
                instead of replicating the code, this static method would be called from 
                critical date trigger to get the fresh value of balance and accrued interest from opportunity. 
            */
            calculateDataInStatic(scope, sinceInception, fromDate, toDate);
        }
        catch (Exception e){
            portfolio_report__c pr = [select id,status__c, errors__c from portfolio_report__c where id =:portfolioReportId ];
            pr.errors__c+='The following error occurred in batch ' +BC.getJobId()+', : '+e.getMessage()+',    ';        
            update pr;  
        }
    }
    global static void calculateDataInStatic(List<Sobject> scope, boolean sinceInception, Date fromDate, Date toDate)
    {
        List<drawdown__c> dScope = (list <Drawdown__c>)scope;
        Map<Id,Drawdown__c> dMap= new Map<Id,Drawdown__c>(dScope);
        
        // get all of the drawdown allocations associated with the scope record and update Temp_Payout_Date on them first
        // this will trigger the DLRS to update the Drawdown records
        List<Drawdown_Payment_Allocation__c> allocations = [Select id,temp_payout_date__c,Reporting_To_Date__c,drawdown__r.date__c from Drawdown_Payment_Allocation__c where drawdown__c in: dmap.keySet()];
        list<Drawdown_Payment_Allocation__c> updatedAllocations = new List <Drawdown_Payment_Allocation__c> (); 
        for (Drawdown_Payment_Allocation__c a : allocations){
            if (sinceInception){
                a.Temp_payout_date__c = a.drawdown__r.date__c;
            }else{
                a.temp_payout_date__c = fromDate;
            }
            updatedAllocations.add(a);
        }
        //system.debug('xxxxxxxx update allocations with from date. updatedAllocations='+updatedAllocations);
        update updatedAllocations;
        
        // update drawdowns with from date
        list<drawdown__c> updatedDrawdowns = new List <Drawdown__c>();
        for (drawdown__c d : dscope){
            if (sinceInception){
                d.temp_Payout_date__c = d.date__c;
                d.Reporting_From_Date__c = d.date__c;
            }else{
                d.temp_payout_date__c = fromDate;
                d.Reporting_From_Date__c = fromDate;
            }
            updatedDrawdowns.add(d);
        }
        //system.debug('xxxxxxxx update drawdowns with from date. updatedDrawdowns='+updatedDrawdowns);
        update updatedDrawdowns;
        
        updatedDrawdowns = [SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, 
                            Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, 
                            Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c,  
                            Accrued_Interest_as_of_Temp_Date__c from drawdown__c where id in:updatedDrawdowns];
        
        // save results for from date
        for (drawdown__c d : updatedDrawdowns){
            if (sinceInception || d.date__c> fromDate ){  //cannot be accrued interest before the drawdown or at inception
                d.Outstanding_Balance_as_of_From_Date__c = 0.00;
                d.Accrued_Interest_as_of_From_Date__c = 0.00;
            }else {
                d.Outstanding_Balance_as_of_From_Date__c = d.Outstanding_Balance_as_of_Temp_Date__c;
                d.Accrued_Interest_as_of_From_Date__c = d.Accrued_Interest_as_of_Temp_Date__c;
            }
        }
        //system.debug('xxxxxxxx update drawdowns with interest and balance at from date. updatedDrawdowns='+updatedDrawdowns);
        update updatedDrawdowns;
        
        // update temp date on allocations with to date
        for (Drawdown_Payment_Allocation__c a : allocations){
            a.temp_payout_date__c = toDate;
            a.Reporting_To_Date__c = toDate;
        }
        //system.debug('xxxxxxxx update allocations with to date. updatedAllocations='+updatedAllocations);
        update updatedAllocations;
        
        // update drawdown with to date
        for (drawdown__c d : updatedDrawdowns){
            d.temp_payout_date__c = toDate;
            d.Reporting_To_Date__c = toDate;
        }
        //system.debug('xxxxxxxx update drawdowns with to date. updatedDrawdowns='+updatedDrawdowns);
        update updatedDrawdowns;    
        
        updatedDrawdowns = [SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, 
                            Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, 
                            Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c,  
                            Date_of_Last_Repayment_b4_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c from drawdown__c where id in:updatedDrawdowns];
        
        // save results for TO date
        for (drawdown__c d : updatedDrawdowns){
            if (d.date__c > toDate ){  //cannot be accrued interest after the toDate
                d.Outstanding_Balance_as_of_To_Date__c = 0.00;
                d.Accrued_Interest_as_of_To_Date__c = 0.00;
            }else {
                d.Outstanding_Balance_as_of_To_Date__c = d.Outstanding_Balance_as_of_Temp_Date__c;
                d.Accrued_Interest_as_of_To_Date__c = d.Accrued_Interest_as_of_Temp_Date__c;
                if ((d.Accrued_Interest_as_of_From_Date__c<d.Accrued_Interest_as_of_To_Date__c ) && d.Outstanding_Balance_as_of_To_Date__c == 0){
                    // In this condition interest was accrued in the reporting period but the balance at the end is $0
                    // This can only happen when the Drawdown was paid off in the period.   
                    // Therefore record the TO date as the date of last repayment
                    d.Reporting_To_Date__c = d.Date_of_Last_Repayment_b4_Temp_Date__c;
                }
            }
        }
        //system.debug('xxxxxxxx update drawdowns with interest and balance at to date. updatedDrawdowns='+updatedDrawdowns);
        update updatedDrawdowns;
    }
    /*
    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        try{

            List<drawdown__c> dScope = (list <Drawdown__c>)scope;
            Map<Id,Drawdown__c> dMap= new Map<Id,Drawdown__c>(dScope);

            // get all of the drawdown allocations associated with the scope record and update Temp_Payout_Date on them first
            // this will trigger the DLRS to update the Drawdown records
            List<Drawdown_Payment_Allocation__c> allocations = [Select id,temp_payout_date__c,drawdown__r.date__c from Drawdown_Payment_Allocation__c where drawdown__c in: dmap.keySet()];
            list<Drawdown_Payment_Allocation__c> updatedAllocations = new List <Drawdown_Payment_Allocation__c> (); 
            for (Drawdown_Payment_Allocation__c a : allocations){
                if (sinceInception){
                    a.Temp_payout_date__c = a.drawdown__r.date__c;
                }else{
                    a.temp_payout_date__c = fromDate;
                }
                updatedAllocations.add(a);
            }
            //system.debug('xxxxxxxx update allocations with from date. updatedAllocations='+updatedAllocations);
            update updatedAllocations;

            // update drawdowns with from date
            list<drawdown__c> updatedDrawdowns = new List <Drawdown__c>();
            for (drawdown__c d : dscope){
                if (sinceInception){
                    d.temp_Payout_date__c = d.date__c;
                    d.Reporting_From_Date__c = d.date__c;
                }else{
                    d.temp_payout_date__c = fromDate;
                    d.Reporting_From_Date__c = fromDate;
                }
                updatedDrawdowns.add(d);
            }
            //system.debug('xxxxxxxx update drawdowns with from date. updatedDrawdowns='+updatedDrawdowns);
            update updatedDrawdowns;

            updatedDrawdowns = [SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, 
                     Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, 
                     Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c,  
                     Accrued_Interest_as_of_Temp_Date__c from drawdown__c where id in:updatedDrawdowns];

            // save results for from date
            for (drawdown__c d : updatedDrawdowns){
                if (sinceInception || d.date__c<= fromDate ){  //cannot be accrued interest before the drawdown or at inception
                    d.Outstanding_Balance_as_of_From_Date__c = 0.00;
                    d.Accrued_Interest_as_of_From_Date__c = 0.00;
                }else {
                    d.Outstanding_Balance_as_of_From_Date__c = d.Outstanding_Balance_as_of_Temp_Date__c;
                    d.Accrued_Interest_as_of_From_Date__c = d.Accrued_Interest_as_of_Temp_Date__c;
                }
            }
            //system.debug('xxxxxxxx update drawdowns with interest and balance at from date. updatedDrawdowns='+updatedDrawdowns);
            update updatedDrawdowns;

            // update temp date on allocations with to date
            for (Drawdown_Payment_Allocation__c a : allocations){
                a.temp_payout_date__c = toDate;
            }
            //system.debug('xxxxxxxx update allocations with to date. updatedAllocations='+updatedAllocations);
            update updatedAllocations;

            // update drawdown with to date
            for (drawdown__c d : updatedDrawdowns){
                d.temp_payout_date__c = toDate;
                d.Reporting_To_Date__c = toDate;
            }
            //system.debug('xxxxxxxx update drawdowns with to date. updatedDrawdowns='+updatedDrawdowns);
            update updatedDrawdowns;    

            updatedDrawdowns = [SELECT id,date__c,Reporting_From_Date__c,Outstanding_Balance_as_of_From_Date__c,Accrued_Interest_as_of_From_Date__c, 
                     Reporting_To_Date__c,Outstanding_Balance_as_of_To_Date__c,Accrued_Interest_as_of_To_Date__c, 
                     Balance_Change_In_Reporting_Period__c,Accrued_Interest_In_Reporting_Period__c,Outstanding_Balance_as_of_Temp_Date__c,  
                     Date_of_Last_Repayment_b4_Temp_Date__c,Accrued_Interest_as_of_Temp_Date__c from drawdown__c where id in:updatedDrawdowns];

            // save results for TO date
            for (drawdown__c d : updatedDrawdowns){
                if (d.date__c > toDate ){  //cannot be accrued interest after the toDate
                    d.Outstanding_Balance_as_of_To_Date__c = 0.00;
                    d.Accrued_Interest_as_of_To_Date__c = 0.00;
                }else {
                    d.Outstanding_Balance_as_of_To_Date__c = d.Outstanding_Balance_as_of_Temp_Date__c;
                    d.Accrued_Interest_as_of_To_Date__c = d.Accrued_Interest_as_of_Temp_Date__c;
                    if ((d.Accrued_Interest_as_of_From_Date__c<d.Accrued_Interest_as_of_To_Date__c ) && d.Outstanding_Balance_as_of_To_Date__c == 0){
                        // In this condition interest was accrued in the reporting period but the balance at the end is $0
                        // This can only happen when the Drawdown was paid off in the period.   
                        // Therefore record the TO date as the date of last repayment
                        d.Reporting_To_Date__c = d.Date_of_Last_Repayment_b4_Temp_Date__c;
                    }
                }
            }
            //system.debug('xxxxxxxx update drawdowns with interest and balance at to date. updatedDrawdowns='+updatedDrawdowns);
            update updatedDrawdowns;    
        }
        catch (Exception e){
            portfolio_report__c pr = [select id,status__c, errors__c from portfolio_report__c where id =:portfolioReportId ];
            pr.errors__c+='The following error occurred in batch ' +BC.getJobId()+', : '+e.getMessage()+',    ';        
            update pr;  
        }
    }
    */
    
    global void finish(Database.BatchableContext BC) {
        portfolio_report__c pr = [select id,status__c, errors__c from portfolio_report__c where id =:portfolioReportId ];
        pr.status__c='Complete';
        pr.errors__c += 'Batch ended at:' + dateTime.now().formatLong();
        update pr;
    }
    
}
