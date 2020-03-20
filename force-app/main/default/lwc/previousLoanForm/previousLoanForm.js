import { LightningElement, api, track } from 'lwc';

export default class PreviousLoanForm extends LightningElement {
    @api recordId;
    @api disabledFields = [];
    @api opportunity;
    @track account;
    @track loading = false;

    alreadyLoaded = false;
    handleLoad(event){
        // Seems to be a bug with lightning-record forms and Lookups. The Lender__c is incorrectly being set to null when editing
        //this.loading = false;
        if (!this.alreadyLoaded && this.recordId) {
            this.alreadyLoaded = true;
            try {
                // Seems to be a bug when I try to get the field value without cloning the object first
                const fields = JSON.parse(JSON.stringify(event.detail.records[this.recordId])).fields
                this.account = fields.Lender__c.value;
            } catch (error) {
                this.account = undefined;
            }
        }
    }


    handleCancel(event) {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleSubmit(event){
        this.loading = true;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }


    handleSuccess(event) {
        event.preventDefault();
        event.stopImmediatePropagation();

        this.dispatchEvent(
            new CustomEvent(
                'success',
                {detail: {...event.detail}}
            ));
    }

    handleError() {
        this.loading = false;
    }
}