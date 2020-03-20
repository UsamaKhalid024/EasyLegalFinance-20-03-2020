import { LightningElement, api } from 'lwc';

export default class LightningPathOption extends LightningElement {
    @api option;

    get cssClasses() {
        if (this.option.complete) {
            return 'slds-path__item slds-is-complete';
        } else if (this.option.current) {
            return 'slds-path__item slds-is-current slds-is-active';
        }
        return 'slds-path__item slds-is-incomplete';
    }

    get altText() {
        if (this.option.complete) {
            return 'Stage Complete';
        } else if (this.option.current) {
            return 'Current Stage:';
        }
        return 'Select Stage';
    }

    get isSelected() {
        return this.current === true;
    }

    handleClick() {
        const evt = new CustomEvent("markstageselected", {
            selectedStage: this.option.value
        });
        this.dispatchEvent(evt);
    }
}