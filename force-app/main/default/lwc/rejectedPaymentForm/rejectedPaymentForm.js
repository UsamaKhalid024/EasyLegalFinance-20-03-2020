import { LightningElement, api, track } from 'lwc';
import getDrawdown from '@salesforce/apex/DrawdownHelper.getDrawdown';
import updateOpportunityPayoutDate from '@salesforce/apex/DrawdownHelper.updateOpportunityPayoutDate';

export default class RejectedPaymentForm extends LightningElement {
    @api recordId;
    @api drawdownToReverseId;
    @track opportunityId;
    @track drawdown;
    @track drawdownToReverseDate;
    @track drawdownDate = new Date().toISOString();

    @track loading = false;

    connectedCallback() {        
        getDrawdown({drawdownId: this.drawdownToReverseId})
            .then(result => {
                this.opportunityId = result.Opportunity__c;
                this.drawdownToReverseDate = result.Date__c;
                this.drawdown = result;                                
            }
        );            
    }

    onUsePaymentDate(event){        
        var drawdownDateInput = this.template.querySelector(".drawdown-date-input");
        if (event.target.checked){
            this.drawdownDate = this.drawdownToReverseDate;            
            drawdownDateInput.disabled = true;
        }
        else
            drawdownDateInput.disabled = false;
    }

    handleCancel(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    alreadyLoaded = false;
    handleLoad(event){
        //this.loading = false;
        if (!this.alreadyLoaded && this.recordId) {
            this.alreadyLoaded = true;
        }
    }

    updateAndSubmitFields(fields){               
        fields.Opportunity__c = this.drawdown.Opportunity__c;        
        fields.CHQ__c = this.drawdown.CHQ__c;        
        fields.EFT__c = this.drawdown.EFT__c;        
        fields.Payment_Method__c = 'Payment';        
        if (fields.Reason_to_Reverse_Payment__c === 'Payment Halted')
            fields.Reference_Notes__c = 'Payment Halted';        
        else
            fields.Reference_Notes__c = 'Payment Rejected'; 
        if (fields.Reason_to_Reverse_Payment__c === 'Client Error'){
            fields.Amount__c = this.drawdown.Amount__c;
        }                   
        else
            fields.Amount__c = this.drawdown.Outstanding_Balance_as_of_Payout_Date__c;
        fields.Principal_Reversed__c = this.drawdown.Amount__c;
        var drawdownDateInput = this.template.querySelector(".drawdown-date-input");
        fields.Date__c = drawdownDateInput.value;
        var rejectionNotesInput = this.template.querySelector(".rejection-notes-input");
        fields.Rejection_Notes__c = rejectionNotesInput.value;
        fields.Opportunity_Service_Provider__c = this.drawdown.Opportunity_Service_Provider__c;        
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSubmit(event){
        this.loading = true;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        var drawdownDateInput = this.template.querySelector(".drawdown-date-input");
        updateOpportunityPayoutDate({opportunityId: this.drawdown.Opportunity__c, payoutDate: drawdownDateInput.value})
            .then(result => {             
                getDrawdown({drawdownId: this.drawdownToReverseId})
                    .then(res=> {
                        this.opportunityId = res.Opportunity__c;
                        this.drawdownToReverseDate = res.Date__c;
                        this.drawdown = res;                                
                        this.updateAndSubmitFields(fields);
                    }
                );                  
            }
        );         
    }

    handleSuccess(event) {
        this.loading = false;
        event.preventDefault();
        event.stopImmediatePropagation();
        updateOpportunityPayoutDate({opportunityId: this.drawdown.Opportunity__c, payoutDate: null});

        this.dispatchEvent(
            new CustomEvent(
                'success',
                {detail: {...event.detail}}
            ));
    }

    handleError() {
        this.loading = false;
        updateOpportunityPayoutDate({opportunityId: this.drawdown.Opportunity__c, payoutDate: null});
    }
}
