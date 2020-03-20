public class FundingDashboardCtrl {
    
    @AuraEnabled
    public static List<LoanProgressionData> getData(String startDate, String endDate, string BusinessUnit){
        
        if(BusinessUnit == 'Consolidated'){
            BusinessUnit = '%%';
        }
        
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            Set<Id> accountIds = new Set<Id>();
            Map<Id,LoanProgressionData> accountsData = new Map<Id,LoanProgressionData>();
            Map<Id,AggregateResult> activeLoans = new Map<Id,AggregateResult>();
            for(AggregateResult res : [Select AccountId,  
                                       sum(Amount) LoanApproved, sum(Admin_Fee__c) adminFee
                                       From Opportunity
                                       where Date_Applied__c >= :startDt
                                       and Date_Applied__c <= :endDt
                                       AND StageName = 'Closed With Loan'
                                       AND (Stage_Status__C like '%Active%' OR Stage_Status__c = null)
                                       And Account.business_unit__c like:Businessunit
                                       Group by AccountId])
            {
                activeLoans.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            
            
            Map<Id,AggregateResult> Principals = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> OpptyCountMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> TotalPaidAmountMap = new Map<Id,AggregateResult>();
            
            Map<Id,AggregateResult> ClosedFundingsMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> PayoutsTotalPrincipalReceivedMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> TotalPayoutsAdminFeeMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> TotalInterestReceivedMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> TotalPayoutsReceivedMap = new Map<Id,AggregateResult>();
            
            
            Map<Id,AggregateResult> BadDebtOpptyCountMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> BadDebtTotalPrincipalReceivedMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> BadDebtTotalAdminFeeMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> BadDebtTotalInterestReceivedMap = new Map<Id,AggregateResult>();
            Map<Id,AggregateResult> BadDebtTotalPayoutsReceivedMap = new Map<Id,AggregateResult>();
            
            // Open Opportunities Count
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Amount__C) Amount, count_distinct(Opportunity__c) OpptyCount
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt
                                       AND Opportunity__r.StageName = 'Closed With Loan'
                                       AND (Payment_Method__c = 'e-Transfer' OR Payment_Method__c = 'Cheque')
                                       AND Is_Rejected__c = false
                                       AND (Opportunity__r.Stage_Status__C like '%Active%' OR 
                                            Opportunity__r.Stage_Status__c = null)
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                Principals.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // All Opportunities
            for(AggregateResult countRes : [Select AccountId,  
                                            count_distinct(Id) AllOpptyCount
                                            From Opportunity
                                            where Date_Applied__c >= :startDt
                                            and Date_Applied__c <= :endDt
                                            AND StageName = 'Closed With Loan'
                                            And Account.business_unit__c like:Businessunit
                                            Group by AccountId])
            {
                OpptyCountMap.put((Id)countRes.get('AccountId'), countRes);
                accountIds.add((Id)countRes.get('AccountId'));
            }
            
            //----------------------------Payouts-----------------------------------------//
            
            // Closed Fundings
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       count_distinct(Opportunity__c) ClosedFundings
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt
                                       AND Opportunity__r.StageName = 'Closed With Loan'
                                       AND (Payment_Method__c = 'e-Transfer' OR Payment_Method__c = 'Cheque')
                                       AND (Opportunity__r.Stage_Status__C = 'Closed - Paid' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Shortfall' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Surplus')
                                       AND Is_Rejected__c = false
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                ClosedFundingsMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // Total Payouts Principal Received
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Principal_Repaid__c) PayoutsTotalPrincipalReceived
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt and
                                       Opportunity__r.StageName = 'Closed With Loan'
                                       AND Payment_Method__c = 'Payment' AND
                                       Reference_Notes__c != 'Bad Debt'
                                       AND Reference_Notes__c != 'Payment Rejected'
                                       AND (Opportunity__r.Stage_Status__C = 'Closed - Paid' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Shortfall' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Surplus')
                                       AND Is_Rejected__c = false
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                PayoutsTotalPrincipalReceivedMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // Total Payouts Admin Fee
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Sum_of_Repayments__c) SumRepayments,
                                       SUM(Interest_up_to_Last_Repayment__c) LastRepayments
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt and
                                       Opportunity__r.StageName = 'Closed With Loan'
                                       AND Payment_Method__c = 'Admin Fee'
                                       AND (reference_notes__c = 'Admin Fee' OR reference_notes__c = 'Assessment Fee')
                                       AND Is_Rejected__c = false
                                       AND (Opportunity__r.Stage_Status__C = 'Closed - Paid' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Shortfall' OR 
                                            Opportunity__r.Stage_Status__c = 'Closed - Surplus')
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                TotalPayoutsAdminFeeMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // Total Interest Received
            for(AggregateResult interestReceivedRes : [Select opportunity__r.AccountId AccountId,  
                                                       SUM(Interest_Repaid__c) TotalInterestReceived
                                                       From Drawdown__c
                                                       where Opportunity__r.Date_Applied__c >= :startDt
                                                       and Opportunity__r.Date_Applied__c <= :endDt and 
                                                       Opportunity__r.StageName = 'Closed With Loan'
                                                       AND Interest_Repaid__c != null
                                                       AND Payment_Method__c = 'Payment' 
                                                       AND Payment_Method__c != 'Bad Debt'
                                                       AND Reference_Notes__c != 'Payment Rejected'
                                                       AND Is_Rejected__c = false
                                                       AND Opportunity__r.Stage_Status__c like '%Closed%'
                                                       AND Opportunity__r.Stage_Status__c != 'Closed - Bad Debt'
                                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                                       Group by opportunity__r.AccountId])
            {
                TotalInterestReceivedMap.put((Id)interestReceivedRes.get('AccountId'), interestReceivedRes);
                accountIds.add((Id)interestReceivedRes.get('AccountId'));
            }
            
            // Total Payouts Received
            for(AggregateResult payoutsReceivedRes : [Select opportunity__r.AccountId AccountId,  
                                                      SUM(Amount__c) TotalPayoutsReceived
                                                      From Drawdown__c
                                                      where Opportunity__r.Date_Applied__c >= :startDt
                                                      and Opportunity__r.Date_Applied__c <= :endDt and 
                                                      Opportunity__r.StageName = 'Closed With Loan'
                                                      AND Payment_Method__c = 'Payment'
                                                      AND Reference_Notes__c != 'Bad Debt'
                                                      AND Reference_Notes__c != 'Payment Rejected'
                                                      AND Is_Rejected__c = false
                                                      AND (Opportunity__r.Stage_Status__C = 'Closed - Paid' OR 
                                                           Opportunity__r.Stage_Status__c = 'Closed - Shortfall' OR 
                                                           Opportunity__r.Stage_Status__c = 'Closed - Surplus')
                                                      And Opportunity__r.Account.business_unit__c like:Businessunit
                                                      Group by opportunity__r.AccountId])
            {
                TotalPayoutsReceivedMap.put((Id)payoutsReceivedRes.get('AccountId'), payoutsReceivedRes);
                accountIds.add((Id)payoutsReceivedRes.get('AccountId'));
            }
            
            //---------------------------Bad-Debts--------------------------------//
            // Bad Debt Opportunity Count
            for(AggregateResult badDebtOpptyRes : [Select count_distinct(id) OpptyBadDebt, 
                                                   AccountId
                                                   From opportunity
                                                   where Date_Applied__c >= :startDt
                                                   and Date_Applied__c <= :endDt and 
                                                   StageName = 'Closed With Loan'
                                                   AND Stage_Status__C ='Closed - Bad Debt'
                                                   And Account.business_unit__c like:Businessunit
                                                   Group by AccountId])
            {
                badDebtOpptyCountMap.put((Id)badDebtOpptyRes.get('AccountId'), badDebtOpptyRes);
                accountIds.add((Id)badDebtOpptyRes.get('AccountId'));
            }
            
            // Bad Debt Total Principal Received
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Principal_Repaid__c) BadDebtTotalPrincipalReceived
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt and
                                       Opportunity__r.StageName = 'Closed With Loan'
                                       AND Payment_Method__c = 'Payment' AND
                                       Reference_Notes__c = 'Bad Debt'
                                       AND Is_Rejected__c = false
                                       //AND Opportunity__r.Stage_Status__C ='Closed - Bad Debt'
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                BadDebtTotalPrincipalReceivedMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // Bad Debt - Total Admin Fee
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Sum_of_Repayments__c) SumRepayments,
                                       SUM(Interest_up_to_Last_Repayment__c) LastRepayments
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt and
                                       Opportunity__r.StageName = 'Closed With Loan'
                                       AND Payment_Method__c = 'Admin Fee'
                                       AND (reference_notes__c = 'Admin Fee' OR reference_notes__c = 'Assessment Fee')
                                       AND Is_Rejected__c = false
                                       AND Opportunity__r.Stage_Status__C ='Closed - Bad Debt'
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                BadDebtTotalAdminFeeMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            
            // Bad Debt Total Payouts Received
            for(AggregateResult BadDebtpayoutsReceivedRes : [Select opportunity__r.AccountId AccountId,  
                                                             SUM(Amount__c) BadDebtTotalPayoutsReceived
                                                             From Drawdown__c
                                                             where Opportunity__r.Date_Applied__c >= :startDt
                                                             and Opportunity__r.Date_Applied__c <= :endDt and 
                                                             Opportunity__r.StageName = 'Closed With Loan'
                                                             AND Payment_Method__c = 'Payment'
                                                             AND Reference_Notes__c != 'Payment Rejected'
                                                             AND Is_Rejected__c = false
                                                             //AND Reference_Notes__c = 'Bad Debt'
                                                             AND Opportunity__r.Stage_Status__C ='Closed - Bad Debt'
                                                             And Opportunity__r.Account.business_unit__c like:Businessunit
                                                             Group by opportunity__r.AccountId])
            {
                BadDebtTotalPayoutsReceivedMap.put((Id)BadDebtpayoutsReceivedRes.get('AccountId'), 
                                                   BadDebtpayoutsReceivedRes);
                accountIds.add((Id)BadDebtpayoutsReceivedRes.get('AccountId'));
            }
            
            // Bad Debt Total Interest Received
            for(AggregateResult res : [Select opportunity__r.AccountId AccountId,  
                                       SUM(Interest_Repaid__c) TotalInterestReceived
                                       From Drawdown__c
                                       where Opportunity__r.Date_Applied__c >= :startDt
                                       and Opportunity__r.Date_Applied__c <= :endDt and 
                                       Opportunity__r.StageName = 'Closed With Loan'
                                       AND Interest_Repaid__c != null
                                       AND Payment_Method__c = 'Payment' 
                                       AND Reference_Notes__c != 'Payment Rejected'
                                       AND Is_Rejected__c = false
                                       //AND Payment_Method__c = 'Bad Debt'
                                       AND Opportunity__r.Stage_Status__C ='Closed - Bad Debt'
                                       And Opportunity__r.Account.business_unit__c like:Businessunit
                                       Group by opportunity__r.AccountId])
            {
                BadDebtTotalInterestReceivedMap.put((Id)res.get('AccountId'), res);
                accountIds.add((Id)res.get('AccountId'));
            }
            /*
            // Total Amount Paid by Firm
            for(AggregateResult amountPaidRes : [Select opportunity__r.AccountId AccountId,  
                                                 SUM(Amount__C) AmountPaidByFirm
                                                 From Drawdown__c
                                                 where Opportunity__r.StageName = 'Closed With Loan'
                                                 AND (Payment_Method__c = 'e-Transfer' OR Payment_Method__c = 'Cheque')
                                                 and opportunity__r.AccountId in:accountIds
                                                 And Opportunity__r.Account.business_unit__c like:Businessunit
                                                 Group by opportunity__r.AccountId ])
            {
                TotalPaidAmountMap.put((Id)amountPaidRes.get('AccountId'), amountPaidRes);
                //accountIds.add((Id)amountPaidRes.get('AccountId'));
            }
*/
  
            // Total Amount Paid by Firm
            for(AggregateResult amountPaidRes : [Select Id AccountId,  
                                                 SUM(Amount_Paid_to_Client__c) AmountPaidByFirm
                                                 From Account
                                                 where Id in (Select AccountId 
                                                              From Opportunity
                                                              Where StageName = 'Closed With Loan'
                                                              AND Date_Applied__c >= :startDt
                                                              and Date_Applied__c <= :endDt
                                                             AND Stage_Status__c In ('Active',
                                                                                    'Active - Partial Payment',
                                                                                    'Closed - Paid',
                                                                                    'Closed - Surplus',
                                                                                    'Closed - Shortfall',
                                                                                    'Active')) 
                                                 And Account.business_unit__c like:Businessunit
                                                 Group by Id ])
            {
                TotalPaidAmountMap.put((Id)amountPaidRes.get('AccountId'), amountPaidRes);
                accountIds.add((Id)amountPaidRes.get('AccountId'));
            }
            
            
            
            LoanProgressionData dataTotal = new LoanProgressionData();
            
            dataTotal.TotalAmountPaidOnActiveLoans = 0.00;
            dataTotal.TotalAvailableCredit = 0.00;
            dataTotal.TotalOfOpptyCount = 0;
            dataTotal.TotalOfTotalOpptyCount = 0;
            dataTotal.TotalOfTotalAmountPaidByFirm = 0.00;

            
            dataTotal.TotalClosedFundings = 0;
            dataTotal.TotalPayoutsTotalPrincipalReceived = 0.00;
            dataTotal.TotalPayoutsTotalInterestReceived = 0.00;
            dataTotal.TotalPayoutsTotalAdminFee = 0.00;
            dataTotal.TotalPayoutsTotalReceived = 0.00;
            
            dataTotal.TotalBadDebtOpportunitiesCount = 0;
            dataTotal.TotalBadDebtTotalPrincipalReceived = 0.00;
            dataTotal.TotalBadDebtTotalInterestReceived = 0.00;
            dataTotal.TotalBadDebtTotalAdminFee = 0.00;
            dataTotal.TotalBadDebtTotalPayoutsReceived = 0.00;
            
            Map<Id,Account> AccountsMAp = new Map<Id,Account>([select id, Name , AccountNumber, Business_Unit__c from 
                                                               account where id in :accountIds]);
            for(Id accId : accountIds)
            {
                LoanProgressionData data = new LoanProgressionData();
                data.AccountId = AccountsMAp.get(accId).Id;
                data.AccountName = AccountsMAp.get(accId).AccountNumber + '-' + accountsMAp.get(accId).Name;
                
                data.AmountPaidOnActiveLoans = 0.00;
                data.AvailableCredit = 0.00;
                data.OpptyCount = 0;
                data.TotalOpptyCount = 0;
                data.TotalAmountPaidByFirm = 0.00;
                
                data.ClosedFundings = 0;
                data.PayoutsTotalPrincipalReceived = 0.00;
                data.PayoutsTotalAdminFee = 0.00;
                data.PayoutsTotalInterestReceived = 0.00;
                data.PayoutsTotalReceived = 0.00;
                
                data.BadDebtOpportunitiesCount = 0;
                data.BadDebtTotalPrincipalReceived = 0.00;
                data.BadDebtTotalAdminFee = 0.00;
                data.BadDebtTotalInterestReceived = 0.00;
                data.BadDebtTotalPayoutsReceived = 0.00;
                
                
                data.AmountPaidOnActiveLoans = !principals.containsKey(accId) ? data.AmountPaidOnActiveLoans : 
                principals.get(accId).get('amount') == null ? 0 : Double.valueOf(principals.get(accId).get('Amount'));
                dataTotal.TotalAmountPaidOnActiveLoans += data.AmountPaidOnActiveLoans == null ||
                    String.isBlank(data.AmountPaidOnActiveLoans.toPlainString())?0:
                data.AmountPaidOnActiveLoans;
                
                
                Double LoanApproved = 0;
                LoanApproved = !activeLoans.containsKey(accId) ? LoanApproved : 
                Double.valueOf(activeLoans.get(accId).get('LoanApproved'));
                LoanApproved = LoanApproved == null ? 0 : LoanApproved;
                
                Double adminFee = 0;
                adminFee = !activeLoans.containsKey(accId) ? adminFee : 
                Double.valueOf(activeLoans.get(accId).get('adminFee'));
                adminFee = adminFee == null ? 0 : adminFee;
                
                Double principalPaid = 0;
                principalPaid = !Principals.containsKey(accId) ? principalPaid : 
                Double.valueOf(Principals.get(accId).get('Amount'));
                principalPaid = principalPaid == null ? 0 : principalPaid;
                
                data.AvailableCredit = LoanApproved - adminFee - principalPaid;
                data.AvailableCredit = data.AvailableCredit < 0 ? 0 : data.AvailableCredit;
                dataTotal.TotalAvailableCredit += data.AvailableCredit == null ||
                    String.isBlank(data.AvailableCredit.toPlainString()) ? 0 : data.AvailableCredit;
                
                data.OpptyCount = !principals.containsKey(accId) ? data.OpptyCount : 
                Integer.valueOf(principals.get(accId).get('OpptyCount'));
                dataTotal.TotalOfOpptyCount += data.OpptyCount == null ||
                    String.isBlank(data.opptyCount.format())?0:data.opptyCount;
                
                data.TotalOpptyCount = !OpptyCountMap.containsKey(accId)?data.TotalOpptyCount:
                Integer.valueOf(OpptyCountMap.get(accId).get('AllopptyCount'));
                dataTotal.TotalOfTotalOpptyCount += data.TotalOpptyCount == null ||
                    String.isBlank(data.TotalOpptyCount.format())?0:data.TotalOpptyCount;
                
                data.TotalAmountPaidByFirm = !TotalPaidAmountMap.containsKey(accId)?data.TotalAmountPaidByFirm:
                Double.valueOf(TotalPaidAmountMap.get(accId).get('AmountPaidByFirm'));
                dataTotal.TotalOfTotalAmountPaidByFirm += data.TotalAmountPaidByFirm == null ||
                    String.isBlank(data.TotalAmountPaidByFirm.toPlainString())?0:data.TotalAmountPaidByFirm;
                
                //---------------------- Payouts-------------------------//
                
                data.ClosedFundings = 
                    !ClosedFundingsMap.containsKey(accId)?data.ClosedFundings:
                Integer.valueOf(ClosedFundingsMap.get(accId).get('ClosedFundings'));
                dataTotal.TotalClosedFundings += data.ClosedFundings == null ||
                    String.isBlank(data.ClosedFundings.format())?0:
                data.ClosedFundings;
                
                data.PayoutsTotalPrincipalReceived = 
                    !PayoutsTotalPrincipalReceivedMap.containsKey(accId)?data.PayoutsTotalPrincipalReceived:
                Double.valueOf(PayoutsTotalPrincipalReceivedMap.get(accId).get('PayoutsTotalPrincipalReceived'));
                dataTotal.TotalPayoutsTotalPrincipalReceived += data.PayoutsTotalPrincipalReceived == null ||
                    String.isBlank(data.PayoutsTotalPrincipalReceived.toPlainString())? 0:
                data.PayoutsTotalPrincipalReceived;
                
                data.PayoutsTotalInterestReceived = !TotalInterestReceivedMap.containsKey(accId) ? 
                    data.PayoutsTotalInterestReceived:
                Double.valueOf(TotalInterestReceivedMap.get(accId).get('TotalInterestReceived'));
                dataTotal.TotalPayoutsTotalInterestReceived += data.PayoutsTotalInterestReceived == null ||
                    String.isBlank(data.PayoutsTotalInterestReceived.toPlainString())?0:data.PayoutsTotalInterestReceived;
                
                data.PayoutsTotalAdminFee = 
                    !TotalPayoutsAdminFeeMap.containsKey(accId)?data.PayoutsTotalAdminFee:
                Double.valueOf((TotalPayoutsAdminFeeMap.get(accId).get('SumRepayments') == null ? 0 
                                 : TotalPayoutsAdminFeeMap.get(accId).get('SumRepayments'))) - 
                    Double.valueOf((TotalPayoutsAdminFeeMap.get(accId).get('LastRepayments') == null ? 0 
                                     : TotalPayoutsAdminFeeMap.get(accId).get('LastRepayments')));
                dataTotal.TotalPayoutsTotalAdminFee += data.PayoutsTotalAdminFee == null ||
                    String.isBlank(data.PayoutsTotalAdminFee.toPlainString())?0:
                data.PayoutsTotalAdminFee;
                
                data.PayoutsTotalReceived = !TotalPayoutsReceivedMap.containsKey(accId)?data.PayoutsTotalReceived:
                Double.valueOf(TotalPayoutsReceivedMap.get(accId).get('TotalPayoutsReceived'));
                dataTotal.TotalPayoutsTotalReceived += data.PayoutsTotalReceived == null ||
                    String.isBlank(data.PayoutsTotalReceived.toPlainString())?0:data.PayoutsTotalReceived;
                
                // ------------------------Bad Debt--------------------------//
                
                data.BadDebtOpportunitiesCount = !BadDebtOpptyCountMap.containsKey(accId)?data.BadDebtOpportunitiesCount:
                Integer.valueOf(BadDebtOpptyCountMap.get(accId).get('opptyBadDebt'));
                dataTotal.TotalBadDebtOpportunitiesCount += data.BadDebtOpportunitiesCount == null ||
                    String.isBlank(data.BadDebtOpportunitiesCount.format())?0:
                data.BadDebtOpportunitiesCount;
                
                data.BadDebtTotalPrincipalReceived = 
                    !BadDebtTotalPrincipalReceivedMap.containsKey(accId)?data.BadDebtTotalPrincipalReceived:
                Double.valueOf(BadDebtTotalPrincipalReceivedMap.get(accId).get('BadDebtTotalPrincipalReceived'));
                dataTotal.TotalBadDebtTotalPrincipalReceived += data.BadDebtTotalPrincipalReceived == null ||
                    String.isBlank(data.BadDebtTotalPrincipalReceived.toPlainString())? 0:
                data.BadDebtTotalPrincipalReceived;
                
                data.BadDebttotalInterestReceived = !BadDebtTotalInterestReceivedMap.containsKey(accId) ? 
                    data.BadDebttotalInterestReceived:
                Double.valueOf(BadDebtTotalInterestReceivedMap.get(accId).get('TotalInterestReceived'));
                dataTotal.TotalBadDebtTotalInterestReceived += data.BadDebttotalInterestReceived == null ||
                    String.isBlank(data.BadDebttotalInterestReceived.toPlainString())?0:data.BadDebttotalInterestReceived;
                
                data.BadDebtTotalAdminFee = 
                    !BadDebtTotalAdminFeeMap.containsKey(accId)?data.BadDebtTotalAdminFee:
                Double.valueOf((BadDebtTotalAdminFeeMap.get(accId).get('SumRepayments') == null ? 0 
                                 : BadDebtTotalAdminFeeMap.get(accId).get('SumRepayments'))) - 
                    Double.valueOf((BadDebtTotalAdminFeeMap.get(accId).get('LastRepayments') == null ? 0 
                                     : BadDebtTotalAdminFeeMap.get(accId).get('LastRepayments')));
                dataTotal.TotalBadDebtTotalAdminFee += data.BadDebtTotalAdminFee == null ||
                    String.isBlank(data.BadDebtTotalAdminFee.toPlainString())?0:
                data.BadDebtTotalAdminFee;
                
                data.BadDebtTotalPayoutsReceived = 
                    !BadDebtTotalPayoutsReceivedMap.containsKey(accId)?data.BadDebtTotalPayoutsReceived:
                Double.valueOf(BadDebtTotalPayoutsReceivedMap.get(accId).get('BadDebtTotalPayoutsReceived'));
                dataTotal.TotalBadDebtTotalPayoutsReceived += data.BadDebtTotalPayoutsReceived == null ||
                    String.isBlank(data.BadDebtTotalPayoutsReceived.toPlainString())?0:
                data.BadDebtTotalPayoutsReceived;
                
                data.BusinessUnit = AccountsMap.get(accId).Business_Unit__c;
                
                accountsData.put(accId, data);
            }
            
            for(loanprogressiondata lp : accountsData.values()){
                lp.TotalAmountPaidOnActiveLoans = dataTotal.TotalAmountPaidOnActiveLoans;
                lp.TotalAvailableCredit = dataTotal.TotalAvailableCredit;
                lp.TotalOfOpptyCount = dataTotal.TotalOfOpptyCount;
                lp.TotalOfTotalOpptyCount = dataTotal.TotalOfTotalOpptyCount;
                lp.TotalOfTotalAmountPaidByFirm = dataTotal.TotalOfTotalAmountPaidByFirm;
                
                lp.TotalClosedFundings = dataTotal.TotalClosedFundings;
                lp.TotalPayoutsTotalPrincipalReceived = dataTotal.TotalPayoutsTotalPrincipalReceived;
                lp.TotalPayoutsTotalInterestReceived = dataTotal.TotalPayoutsTotalInterestReceived;
                lp.TotalPayoutsTotalAdminFee = dataTotal.TotalPayoutsTotalAdminFee;
                lp.TotalPayoutsTotalReceived = dataTotal.TotalPayoutsTotalReceived;
                
                lp.TotalBadDebtOpportunitiesCount = dataTotal.TotalBadDebtOpportunitiesCount;
                lp.TotalBadDebtTotalPrincipalReceived = dataTotal.TotalBadDebtTotalPrincipalReceived;
                lp.TotalBadDebtTotalInterestReceived = dataTotal.TotalBadDebtTotalInterestReceived;
                lp.TotalBadDebtTotalAdminFee = dataTotal.TotalBadDebtTotalAdminFee;
                lp.TotalBadDebtTotalPayoutsReceived = dataTotal.TotalBadDebtTotalPayoutsReceived;
            }
            
            return accountsData.values();
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()+e.getStackTraceString());
        }
    }
    
    public class LoanProgressionData{
        @AuraEnabled
        public String AccountId;
        @AuraEnabled
        public String AccountName{get;set;}
        @AuraEnabled
        public string BusinessUnit{get;set;}
        @AuraEnabled
        public Decimal AmountPaidOnActiveLoans{get;set;}
        @AuraEnabled
        public Decimal TotalAmountPaidOnActiveLoans{get;set;}
        @AuraEnabled
        public Decimal AvailableCredit{get;set;}
        @AuraEnabled
        public Decimal TotalAvailableCredit{get;set;}
        
        @AuraEnabled
        public Integer OpptyCount{get;set;}
        @AuraEnabled
        public Integer TotalOpptyCount{get;set;}
        @AuraEnabled
        public Integer TotalOfOpptyCount{get;set;}
        @AuraEnabled
        public Integer TotalOfTotalOpptyCount{get;set;}
        @AuraEnabled
        public Decimal TotalAmountPaidByFirm{get;set;}
        @AuraEnabled
        public Decimal TotalOfTotalAmountPaidByFirm{get;set;}
        
        // Payouts
        
        @AuraEnabled
        public Integer ClosedFundings{get;set;}
        @AuraEnabled
        public Integer TotalClosedFundings{get;set;}
        @AuraEnabled
        public Decimal PayoutsTotalPrincipalReceived{get;set;}
        @AuraEnabled
        public Decimal TotalPayoutsTotalPrincipalReceived{get;set;}
        @AuraEnabled
        public Decimal PayoutsTotalInterestReceived{get;set;}
        @AuraEnabled
        public Decimal TotalPayoutsTotalInterestReceived{get;set;}
        @AuraEnabled
        public Decimal PayoutsTotalAdminFee{get;set;}
        @AuraEnabled
        public Decimal TotalPayoutsTotalAdminFee{get;set;}
        @AuraEnabled
        public Decimal PayoutsTotalReceived{get;set;}
        @AuraEnabled
        public Decimal TotalPayoutsTotalReceived{get;set;}
        
        // Bad-Debt
        
        @AuraEnabled
        public Integer BadDebtOpportunitiesCount{get;set;}
        @AuraEnabled
        public Integer TotalBadDebtOpportunitiesCount{get;set;}
        @AuraEnabled
        public Decimal BadDebtTotalPrincipalReceived{get;set;}
        @AuraEnabled
        public Decimal TotalBadDebtTotalPrincipalReceived{get;set;}
        @AuraEnabled
        public Decimal BadDebtTotalInterestReceived{get;set;}
        @AuraEnabled
        public Decimal TotalBadDebtTotalInterestReceived{get;set;}
        @AuraEnabled
        public Decimal BadDebtTotalAdminFee{get;set;}
        @AuraEnabled
        public Decimal TotalBadDebtTotalAdminFee{get;set;}
        @AuraEnabled
        public Decimal BadDebtTotalPayoutsReceived{get;set;}
        @AuraEnabled
        public Decimal TotalBadDebtTotalPayoutsReceived{get;set;}
        
    }
    @AuraEnabled
    public static list<Drawdown__c> getDrawdownCongaURLs(){
        
        list<Drawdown__c> drawdown_conga_url = [select id, Conga_Finance_Loan_Progression_View_All__c,
                                                Conga_Finance_Loan_Progression_Print_All__c from Drawdown__c limit 1];
        return drawdown_conga_url;
    }
    
    @AuraEnabled
    public static void saveDateCustomSettings(String startDate, String endDate){
        try{
            Date startDt = Date.valueOf(startDate);
            Date endDt = Date.valueOf(endDate);
            
            FundingDashboard__c lsr = FundingDashboard__c.getOrgDefaults();
            
            lsr.End_date__c = endDt;
            lsr.Start_Date__c = startDt;
            
            update lsr; 
        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveBusinessUnitCustomSettings(String BusinessUnit){
        try{
            
           // Bad_Debt_Summary_Report__c bdr = Bad_Debt_Summary_Report__c.getInstance(UserInfo.getUserId());
            FundingDashboard__c flp = FundingDashboard__c.getOrgDefaults();
            
            flp.Business_Unit__C = BusinessUnit;
            
            upsert flp;

        }catch(Exception ex){
            
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static FundingDashboard__c getCustomSetting(){
        FundingDashboard__c Lsr = FundingDashboard__c.getOrgDefaults();
        return Lsr;
    }

    
}