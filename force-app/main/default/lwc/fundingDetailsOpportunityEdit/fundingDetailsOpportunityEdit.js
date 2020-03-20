import { LightningElement, api, track, wire } from 'lwc';
import updateOpportunity from '@salesforce/apex/FundingDetailsComponentCtlr.updateOpportunity';
import { showToast } from 'c/showToast';
import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { CurrentPageReference } from 'lightning/navigation';
//import { updateRecord } from 'lightning/uiRecordApi';

const STAGE_CHOICES = [
    'Loan Setup Check',
    'Process Drawdowns',
    'Populate PPSA',
    'Final Review',
    'Closed'
]

export default class FundingDetailsOpportunityEdit extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    @track loading = true; // Show spinner
    @track reinit = true; // reinitilize actual edit components (they are getting stale sometimes)

    @track _opp;
    @api
    get opp(){
        return this._opp;
    }
    set opp(value){
        this.loading = true;
        this.reinit = false;
        this._opp = value;
        this.buildPathOptions();
        this.reinit = true;
        (function (_this) {
            _this.searchTimeout = setTimeout(() => {
                _this.reinit = false;
                _this.loading = false;
            }, 50);
        })(this);
    }

    @track pathOptions = []

    @api refresh() {
        console.log('OppEdit.refresh()');
        this.loading = true;
        this.buildPathOptions();
        //this.template.querySelector("c-lightning-path").initOptions();
        this.loading = false;
    }

    buildPathOptions () {
        let pathOptions = [];
        for (const stage of STAGE_CHOICES) {
            let option = {
                label: stage,
                value: stage,
                current: this.opp.Funding_Details_Status__c === stage
            };
            pathOptions.push(option);
        }
        this.pathOptions = pathOptions;
    }

    handleStageComplete(event) {
        // Move opp to next Funding_Details_Status__c
        const currIndex = STAGE_CHOICES.findIndex(option => {return option === this.opp.Funding_Details_Status__c});
        this.startLoading();
        if (currIndex < 0) {
            this.updateOpp({Id: this.opp.Id, Funding_Details_Status__c: STAGE_CHOICES[0]});
        } else if (currIndex < STAGE_CHOICES.length - 1) {
            this.updateOpp({Id: this.opp.Id, Funding_Details_Status__c: STAGE_CHOICES[currIndex + 1]});
        }
    }
    
    handleStageSelected(event) {
        // Move opp to specified Funding_Details_Status__c
        this.updateOpp({Funding_Details_Status__c: event.detail.stage});
    }

    get isLoanSetupCheck() {
        return this.opp.Funding_Details_Status__c === 'Loan Setup Check'
    }

    get isProcessDrawdowns() {
        return this.opp.Funding_Details_Status__c === 'Process Drawdowns'
    }

    get isPopulatePPSA() {
        return this.opp.Funding_Details_Status__c === 'Populate PPSA'
    }

    get isCloseTransaction() {
        return this.opp.Funding_Details_Status__c === 'Final Review'
    }

    updateOpp(payload) {
        // Ensure Id in payload
        payload.Id = this.opp.Id;
        payload.sobjectType = 'Opportunity';
        this.startLoading();
        updateOpportunity({opp: payload})
            .then(result => {
                if (result.Funding_Details_Status__c === 'Closed') {
                    this.fireRemoveOpportunity(result);
                } else {
                    this.fireOpportunityChanged(result);
                    //this.buildPathOptions();
                }
                this.stopLoading();
            })
            .catch(error => {
                this.stopLoading();
                let message;
                try {
                    message = error.body.message;
                } catch (e) {
                    message = JSON.stringify(error);
                }
                showToast(
                    this,
                    'Unable to update opportunity',
                    message,
                    'error',
                    'sticky'
                );
            })
    }

    fireOpportunityChanged(payload) {
        const evt = new CustomEvent("opportunitychanged", {
            detail: payload
        });
        this.dispatchEvent(evt);
    }

    fireRemoveOpportunity(payload) {
        const evt = new CustomEvent("opportunityremoved", {
            detail: payload
        });
        this.dispatchEvent(evt);
    }

    connectedCallback() {
        console.log('connected');
        registerListener('startloading', this.startLoading, this);
        registerListener('stoploading', this.stopLoading, this);
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    startLoading() {
        this.loading = true;
    }

    stopLoading() {
        this.loading = false;
    }

}