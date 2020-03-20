public class SystemMonitoring_DrawdownsAdminFee {
    
    
    public void SystemMonitoring_DrawdownsAdminFee(){
        
    }
    
    public static void getListOfIssuesWithAdminFees(){
        List<AggregateResult> sumAdminFeeField = [Select Opportunity__c, Sum(Admin_Fee__c) AdminFee from Drawdown__c group by Opportunity__c];
        system.debug(sumAdminFeeField.size());
        
        List<AggregateResult> sumAdminFeeTransactions = [Select Opportunity__c, SUM(Amount__c) Amount from Drawdown__c where Reference_Notes__c = 'Admin Fee' group by Opportunity__c ];
        system.debug(sumAdminFeeTransactions.size());
        
        Map<Id, Decimal> sumMap = new Map<Id, Decimal>();
        
        for(AggregateResult a : sumAdminFeeField){
            sumMap.put((Id)a.get('Opportunity__c' ), (Decimal)a.get('AdminFee'));
        }
        
        system.debug(sumMap.size());
        
		List<Details> incorrectDrawdowns = new List<Details>();
        for(AggregateResult a : sumAdminFeeTransactions){
            
            Id oppId = (Id)a.get('Opportunity__c');
            Decimal amount = (Decimal)a.get('Amount');
            
            if(sumMap.containsKey(oppId)){
                if(sumMap.get(oppId) != amount){
                    Details d = new Details();
                    d.oppId = oppId;
                    d.FieldAdminFeeSum = sumMap.get(oppId);
                    d.DrawdownsAdminFeeSum = amount;
                    incorrectDrawdowns.add(d);
                    system.debug(' This opportunity has incorrect admin fee drawdowns >>  ' + oppId);
                }
            }
        }
        
        Map<ID, Opportunity> oppMap = new Map<ID, Opportunity>([Select Id, Loan_Requests__c, Name from Opportunity where id IN: sumMap.keyset()]);
        
        System_Monitoring__c sysMon = new System_Monitoring__c();
        sysMon.Status__c = 'New';
        sysMon.Monitoring_Type__c = 'Drawdowns - Admin Fee';
        
        String detailsText = '';
        for(Details d : incorrectDrawdowns){
          detailsText = detailsText + 'This opportunity <a href="/lightning/r/Opportunity/' + d.oppId + '/view" target="_self">' +
              oppMap.get(d.oppId).Name + ' (' + oppMap.get(d.oppId).Loan_Requests__c + ')' + '</a> has incorrect admin fee drawdowns. The sum of the admin fee field is: ' + 
              			d.FieldAdminFeeSum + ' and the sum of admin drawdowns is: ' + d.DrawdownsAdminFeeSum + '. <br/>'; 
        }
        
        sysMon.Report_Result_Summary__c = detailsText;
        insert sysMon;
        
    }
    
    public class Details{
        public String oppId {get;set;}
        public Decimal FieldAdminFeeSum {get;set;}
        public Decimal DrawdownsAdminFeeSum {get;set;}
    }

}