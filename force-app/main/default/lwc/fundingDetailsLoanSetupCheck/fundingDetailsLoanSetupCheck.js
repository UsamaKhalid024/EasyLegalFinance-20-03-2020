import { LightningElement, track, api, wire } from 'lwc';
import { fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';

const FIELDS = [
    'Interest_Rate__c',
    'Interest_Compounding_Period__c',
    'Compounding_Interest__c',
    'Fee_Calculation_Method__c',
    'Fixed_Amount__c',
    'Percent_Amount__c',
    'Custommized_Amount__c',
    'Minimum_Interest_Period__c',
    'Interest_Deferral_Period__c'
]

export default class FundingDetailsLoanSetupCheck extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    _readOnly = false;
    @api 
    get readOnly() {
        return this._readOnly
    }
    set readOnly(val) {
        this._readOnly = !!val;
        this.setDisabled();
    }


    @track _opp;
    @api
    get opp(){
        return this._opp;
    }
    set opp(value){
        this._opp = {...value}; // Make a mutable copy of the opp
        this.setDisabled();
        //this.calculationMethod = this.opp.Fee_Calculation_Method__c;
        // Delay rendering due to a bug in record-edit-form causing the form to render with stale values
        //this.loading = true;
        /*
        (function (_this) {
            _this.searchTimeout = setTimeout(() => {
                _this.loading = false;
                _this.fireStopLoadingEvent();
            }, 100);
        })(this);
        */
    }

    @track buttonText = "Save and Move to Next Step"; //"I confirm the data is accurate";
    @track confirmedAccurate = true;//false;

    @track calculationMethod;

    @track fields = FIELDS;
    @track disabled = {};
    @track loading = true;


    connectedCallback() {
        this.loading = true;
    }

    handleCalculationMethodChange(event) {
        this.calculationMethod = event.target.value;
    }

    setDisabled() {
        this.disabled = {};
        for (let i = 0; i < this.fields.length; i++) {
            // Allow edits when field value is blank, null, etc... otherwise mark as readonly
            // Removed conditional read-only as per Nicole's request on 5-2-2019
            // Put back in per Dom and Nicole's request on 7-18-2019
            this.disabled[this.fields[i]] = (!!this.opp.Drawdown_Total__c && !!this.opp[this.fields[i]]) || this.readOnly;//this.readOnly;
        }
    }

    get isFixedAmount() {
        return this.calculationMethod === 'Fixed Amount'
    }

    get isCaculatedPercent() {
        return this.calculationMethod === 'Amount calculated as % of loan amount'
    }

    get isNoCalculationMethod() {
        return !this.calculationMethod
    }

    get isOtherCalculationMethod() {
        return !(this.isFixedAmount || this.isCaculatedPercent || this.isNoCalculationMethod)
    }

    saveOpportunity(event) {
        // Save the opp...
        // Set the status
        event.preventDefault();       // stop the form from submitting
        if (this.confirmedAccurate) {
            const fields = event.detail.fields;
            fields.Funding_Details_Status__c = 'Process Drawdowns';
            this.fireStartLoadingEvent();
            this.template.querySelector("lightning-record-edit-form").submit(fields);
        } else {
            this.confirmedAccurate = true;
            this.buttonText = 'Save and Move to Next Step';
        }
    }

    fireStartLoadingEvent() {
        fireEvent(this.pageRef, 'startloading');
    }

    fireStopLoadingEvent() {
        fireEvent(this.pageRef, 'stoploading');
    }

    handleError(event) {
        // send event to update the opp
        this.fireStopLoadingEvent();
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
}