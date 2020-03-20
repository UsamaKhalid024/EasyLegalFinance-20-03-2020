import { LightningElement, api, track } from 'lwc';

export default class TreatmentInvoiceForm extends LightningElement {
    @api recordId;
    //@api disabledFields = [];
    @api opportunityServiceProvider;
    @track loading = false;

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