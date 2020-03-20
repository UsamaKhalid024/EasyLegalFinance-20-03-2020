import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubsub';

export default class FundingDetailsLoanRegistration extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @api opp;
    @api readOnly = false;

    connectedCallback() {
        this.fireStopLoadingEvent();
    }

    saveOpportunity(event) {
        // Save the opp...
        // Set the status
        this.fireStartLoadingEvent();
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        fields.Funding_Details_Status__c = 'Final Review';
        this.template.querySelector("lightning-record-edit-form").submit(fields);
    }

    handleSuccess(event) {
        // send event to update the opp
        this.fireStopLoadingEvent();
        const evt = new CustomEvent("opportunitychanged", {
            detail: {Id: this.opp.Id, Funding_Details_Status__c: event.detail.fields.Funding_Details_Status__c.value},
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(evt);
    }

    handleError() {
        this.fireStopLoadingEvent();
    }

    fireStartLoadingEvent() {
        fireEvent(this.pageRef, 'startloading');
    }

    fireStopLoadingEvent() {
        fireEvent(this.pageRef, 'stoploading');
    }
}