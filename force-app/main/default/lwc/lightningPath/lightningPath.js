import { LightningElement, api, track } from 'lwc';

export default class LightningPath extends LightningElement {
    @track _pathOptions;
    @api
    get pathOptions() {
        return this._pathOptions;
    }
    set pathOptions(value) {
        this._pathOptions = JSON.parse(JSON.stringify(value));
        this.initOptions();
    }
    /*
    [{
        label: "Label",
        value: "value",
        current: false
    }]
    */

    @track currentStage;

    @api initOptions() {
        // Marks options as complete that occur before the option marked as current
        let foundCurrent = false;
        for (let i = this.pathOptions.length - 1; i >= 0; i--) {
            let option = this.pathOptions[i];
            if (option.current) {
                // Current
                foundCurrent = true;
                this.currentStage = option.label;
                option.cssClasses = 'slds-path__item slds-is-complete';
                option.altText = 'Stage Complete';
            } else if (foundCurrent) {
                // Already Complete
                option.current = false;
                option.complete = true;
                option.cssClasses = 'slds-path__item slds-is-current slds-is-active';
                option.altText = 'Stage Complete';
            } else {
                // Incomplete
                option.current = false;
                option.complete = true;
                option.cssClasses = 'slds-path__item slds-is-incomplete';
                option.altText = 'Select Stage';
            }
        }
    }

    handleStageSelected(event) {
        // Get stage from current event and send it up to the parent component
        let elem = event.target.closest('li');
        if (elem) {
            const evt = new CustomEvent("markstageselected", {
                detail: {stage: this.pathOptions[elem.getAttribute('data-index')].value}
            });
            this.dispatchEvent(evt);
        }
    }
    
    fireStageComplete() {
        const evt = new CustomEvent("markstagecomplete");
        this.dispatchEvent(evt);
    }

}