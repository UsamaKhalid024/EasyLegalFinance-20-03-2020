import { LightningElement, api, track } from 'lwc';

const CSS_CLASS = 'modal-hidden';

export default class Modal extends LightningElement {
    @api
    set header(value) {
        this.hasHeaderString = value !== '';
        this._headerPrivate = value;
    }
    get header() {
        return this._headerPrivate;
    }

    @track showModal = false;
    @track hasHeaderString = false;
    _headerPrivate;

    @api show() {
        this.showModal = true;
        //const outerDivEl = this.template.querySelector('div');
        //outerDivEl.classList.remove(CSS_CLASS);
    }

    @api hide() {
        this.showModal = false;
        //const outerDivEl = this.template.querySelector('div');
        //outerDivEl.classList.add(CSS_CLASS);
    }

    handleDialogClose() {
        this.hide();
    }

    handleSlotTaglineChange() {
        const taglineEl = this.template.querySelector('p');
        taglineEl.classList.remove(CSS_CLASS);
    }

    @api showFooter = false;
}