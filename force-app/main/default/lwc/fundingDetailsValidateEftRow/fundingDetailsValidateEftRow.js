import { LightningElement, api, track } from 'lwc';
import markPaymentValidated from '@salesforce/apex/ScheduledPaymentHelper.markPaymentValidated';
import updateScheduledPayments from '@salesforce/apex/FundingDetailsComponentCtlr.updateScheduledPayments';
import { showToast } from 'c/showToast';

export default class FundingDetailsValidateEftRow extends LightningElement {
    _value
    @api 
    get value() {
        return this._value;
    }
    set value(newValue) {
        this._value = {...newValue};
    }

    @api paymentType = 'eft';

    get isCheque() {
        return this.paymentType === 'cheque'
    }

    @track showButtons = true;
    @track showRejected = false;
    @track showApproved = false;

    renderedCallback() {
        this.setApproveDisabled();
    }

    get approveButton() {
        return this.template.querySelector('lightning-button.approve-button')
    }

    bankingChanged(event) {
        this.updateVerifiedStatus('Banking_Verified__c', event.target.checked)
    }

    creditChanged(event) {
        this.updateVerifiedStatus('Credit_Verified__c', event.target.checked)
    }

    documentsChanged(event) {
        this.updateVerifiedStatus('Documents_Verified__c', event.target.checked)
    }

    ppsaChanged(event) {
        this.updateVerifiedStatus('BIA_PPSA_LL_Verified__c', event.target.checked)
    }

    updateVerifiedStatus(fieldName, value) {
        const sp = {
            'sobjectType': 'Scheduled_Payment__c',
            'Id': this.value.Id,
        };
        sp[fieldName] = value;
        return updateScheduledPayments({scheduledPayments: [sp]})
            .then((result) => {
                this.value[fieldName] = value;
                this.setApproveDisabled();
            })
            .catch(error => {
                showToast(this, 
                    'There was an error',
                    JSON.stringify(error),
                    'error',
                    'sticky'
                );
            });
    }

    setApproveDisabled() {
        if (this.approveButton) {
            this.approveButton.disabled = !(this.value.Banking_Verified__c && this.value.Credit_Verified__c && this.value.Documents_Verified__c && this.value.BIA_PPSA_LL_Verified__c);
        }
    }

    disableCheckboxes() {
        this.template.querySelectorAll('lightning-input').forEach(element => {
            element.disabled = true;
        });
    }

    hideRejectModal() {
        this.template.querySelector('c-modal.rejectModal').hide();
    }

    showRejectModal() {
        this.template.querySelector('c-modal.rejectModal').show();
    }

    handleNotesChange(event) {
        this.value.Notes__c = event.target.value;
    }

    handleRejectSuccess() {
        this.hideRejectModal();
        this.disableCheckboxes();
        this.showButtons = false;
        this.showRejected = true;
    }

    approve() {
        markPaymentValidated({spId: this.value.Id})
            .then(() => {
                this.disableCheckboxes();
                this.showButtons = false;
                this.showApproved = true;
                // change display to approved
            })
            .catch(error => {
                showToast(this, 
                    'There was an error',
                    JSON.stringify(error),
                    'error',
                    'sticky'
                );
            });
    }

}